// Portable textured triangle rasterizer for browsers without a WebGL context.
// Three.js still owns geometry, transforms, camera projection and skeletal animation.
class SoftwareRenderer {
  constructor(canvas){
    this.canvas=canvas;this.ctx=canvas.getContext('2d',{alpha:false});
    this.maps=new WeakMap();this.software=true;this.vertex=new THREE.Vector3();
  }
  setSize(w,h){
    this.canvas.width=this.w=w;this.canvas.height=this.h=h;
    this.image=this.ctx.createImageData(w,h);this.depth=new Float32Array(w*h);
    this.color=new Uint32Array(this.image.data.buffer);
  }
  pixels(map){
    if(!map)return null;
    if(this.maps.has(map))return this.maps.get(map);
    const source=map.image;if(!source||!(source.width&&source.height))return null;
    const c=document.createElement('canvas');c.width=source.width;c.height=source.height;
    const ctx=c.getContext('2d');ctx.drawImage(source,0,0);
    const result={w:c.width,h:c.height,data:ctx.getImageData(0,0,c.width,c.height).data};
    this.maps.set(map,result);return result;
  }
  render(scene,camera){
    if(!this.image)this.setSize(this.canvas.width,this.canvas.height);
    this.depth.fill(0);this.color.fill(0xff473b32);
    scene.updateMatrixWorld(true);camera.updateMatrixWorld(true);
    const focal=this.h/(2*Math.tan(camera.fov*Math.PI/360));
    scene.traverseVisible(mesh=>{
      if(!mesh.isMesh)return;
      const g=mesh.geometry,m=mesh.material;if(Array.isArray(m))return;
      const pos=g.attributes.position,uv=g.attributes.uv;
      const view=new THREE.Matrix4().multiplyMatrices(camera.matrixWorldInverse,mesh.matrixWorld);
      if(mesh.isSkinnedMesh)mesh.skeleton.update();
      const points=[];
      for(let i=0;i<pos.count;i++){
        const v=this.vertex.fromBufferAttribute(pos,i);
        if(mesh.isSkinnedMesh)mesh.boneTransform(i,v);
        v.applyMatrix4(view);
        points.push([v.x,v.y,-v.z,uv?uv.getX(i):0,uv?uv.getY(i):0]);
      }
      const idx=g.index?.array, count=idx?idx.length:points.length;
      const map=m.map,tex=this.pixels(map), repeat=map?.repeat||{x:1,y:1};
      const tint=m.color.clone().convertLinearToSRGB();
      const unlit=!!m.isMeshBasicMaterial;
      for(let i=0;i<count;i+=3){
        const a=points[idx?idx[i]:i],b=points[idx?idx[i+1]:i+1],c=points[idx?idx[i+2]:i+2];
        if(Math.max(a[2],b[2],c[2])<.12)continue;
        const ux=b[0]-a[0],uy=b[1]-a[1],uz=b[2]-a[2],vx=c[0]-a[0],vy=c[1]-a[1],vz=c[2]-a[2];
        const nx=uy*vz-uz*vy,ny=uz*vx-ux*vz,nz=ux*vy-uy*vx;
        const facing=nx*a[0]+ny*a[1]+nz*a[2];
        if(m.side===THREE.FrontSide&&facing<0||m.side===THREE.BackSide&&facing>0)continue;
        const length=Math.hypot(nx,ny,nz)||1;
        const light=unlit?1:.81+.26*(-ny+.45*nx+.25*nz)/length;
        const shade=[tint.r*light,tint.g*light,tint.b*light];
        let polygon=[a,b,c];
        if(Math.min(a[2],b[2],c[2])<.12){
          const clipped=[];let prev=c;
          for(const v of polygon){
            if((prev[2]>=.12)!==(v[2]>=.12)){
              const t=(.12-prev[2])/(v[2]-prev[2]);clipped.push(prev.map((n,k)=>n+t*(v[k]-n)));
            }
            if(v[2]>=.12)clipped.push(v);prev=v;
          }
          polygon=clipped;
        }
        const projected=polygon.map(v=>{
          const q=1/v[2];return [this.w*.5+v[0]*q*focal,this.h*.5-v[1]*q*focal,q,v[3]*q*repeat.x,v[4]*q*repeat.y];
        });
        for(let j=1;j<projected.length-1;j++)this.triangle(projected[0],projected[j],projected[j+1],tex,shade,map?.flipY);
      }
    });
    this.ctx.putImageData(this.image,0,0);
  }
  triangle(a,b,c,tex,shade,flip){
    const x0=Math.max(0,Math.floor(Math.min(a[0],b[0],c[0]))),x1=Math.min(this.w-1,Math.ceil(Math.max(a[0],b[0],c[0])));
    const y0=Math.max(0,Math.floor(Math.min(a[1],b[1],c[1]))),y1=Math.min(this.h-1,Math.ceil(Math.max(a[1],b[1],c[1])));
    if(x0>x1||y0>y1)return;
    const den=(b[1]-c[1])*(a[0]-c[0])+(c[0]-b[0])*(a[1]-c[1]);if(Math.abs(den)<.001)return;
    const dax=(b[1]-c[1])/den,dbx=(c[1]-a[1])/den;
    for(let y=y0;y<=y1;y++){
      let wa=dax*(x0+.5-c[0])+(c[0]-b[0])*(y+.5-c[1])/den;
      let wb=dbx*(x0+.5-c[0])+(a[0]-c[0])*(y+.5-c[1])/den;
      for(let x=x0,i=y*this.w+x0;x<=x1;x++,i++,wa+=dax,wb+=dbx){
        const wc=1-wa-wb;if(Math.min(wa,wb,wc)<-.00001)continue;
        const q=wa*a[2]+wb*b[2]+wc*c[2];if(q<=this.depth[i])continue;
        let r=255,g=255,bv=255;
        if(tex){
          const u=(wa*a[3]+wb*b[3]+wc*c[3])/q;
          let v=(wa*a[4]+wb*b[4]+wc*c[4])/q;if(flip)v=1-v;
          const j=4*(Math.floor((v-Math.floor(v))*tex.h)*tex.w+Math.floor((u-Math.floor(u))*tex.w));
          r=tex.data[j];g=tex.data[j+1];bv=tex.data[j+2];
        }
        this.depth[i]=q;
        this.color[i]=0xff000000|(Math.min(255,bv*shade[2])<<16)|(Math.min(255,g*shade[1])<<8)|Math.min(255,r*shade[0]);
      }
    }
  }
}
