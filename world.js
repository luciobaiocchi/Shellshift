// The low-resolution render target and mipmapped bitmap materials are independent
// of the desktop UI, which stays at native resolution for readability.
class District3D {
  constructor(canvas, renderer) {
    this.canvas=canvas;
    this.renderer=renderer;
    renderer.outputEncoding=THREE.sRGBEncoding;
    this.scene=new THREE.Scene();
    this.scene.background=new THREE.Color(0x303948);
    this.scene.fog=new THREE.FogExp2(0x303948,.035);
    this.camera=new THREE.PerspectiveCamera(62,1,.08,95);
    this.x=0; this.z=6.6; this.yaw=0; this.keys=new Set(); this.foundPass=false;
    this.motion=!matchMedia('(prefers-reduced-motion: reduce)').matches;
    this.mixers=[];this.crew=[];this.bounds=[];this.last=0;
    this.loader=new THREE.TextureLoader();
    this.materials={};
    this.scene.add(new THREE.HemisphereLight(0xe2e8f8,0x605649,1.22));
    const sun=new THREE.DirectionalLight(0xffdfb1,1.22);
    sun.position.set(-8,13,5);this.scene.add(sun);
    this.build();
  }
  material(name,repeatX=1,repeatY=1,tint=0xffffff){
    const key=[name,repeatX,repeatY,tint].join('/');
    if(!this.materials[key]){
      const tex=this.loader.load(districtMaps[name]);
      tex.encoding=THREE.sRGBEncoding;tex.magFilter=THREE.NearestFilter;
      tex.minFilter=THREE.LinearMipMapLinearFilter;
      tex.wrapS=tex.wrapT=THREE.RepeatWrapping;tex.repeat.set(repeatX,repeatY);
      this.materials[key]=new THREE.MeshLambertMaterial({map:tex,color:tint});
    }
    return this.materials[key];
  }
  mesh(geometry,material,x,y,z,parent=this.scene){
    const m=new THREE.Mesh(geometry,material);m.position.set(x,y,z);parent.add(m);return m;
  }
  block(x,y,z,w,h,d,material,parent){
    return this.mesh(new THREE.BoxGeometry(w,h,d),material,x,y,z,parent);
  }
  glow(color){return new THREE.MeshBasicMaterial({color});}
  arch(x,z,rise,radius,depth){
    const stone=this.material('fieldstone',1,2);
    const outer=radius+.58;
    for(const side of [-1,1]){
      const cx=x+side*(radius+.29);
      this.block(cx,rise/2,z,.58,rise,depth,stone);
      this.block(cx,.18,z,.82,.36,depth+.18,stone);
      this.block(cx,rise-.12,z,.8,.24,depth+.16,stone);
      this.bounds.push([cx,z,.44,depth/2]);
    }
    for(let i=0;i<13;i++){
      const a=Math.PI*i/13+.005,b=Math.PI*(i+1)/13-.005;
      const shape=new THREE.Shape();
      const rim=i===6?outer+.15:outer;
      for(const [idx,[angle,r]] of [[a,radius],[a,rim],[b,rim],[b,radius]].entries()){
        const u=r*Math.cos(angle),v=r*Math.sin(angle);
        if(idx===0)shape.moveTo(u,v);else shape.lineTo(u,v);
      }
      shape.closePath();
      this.mesh(new THREE.ExtrudeGeometry(shape,{depth,bevelEnabled:false}),this.material('flagstone',.7,.7,i%2?0xcbc4b2:0xddd1b7),x,rise,z-depth/2);
    }
  }
  plaque(word,x,y,z,width){
    const cv=document.createElement('canvas');cv.width=256;cv.height=48;
    const c=cv.getContext('2d');c.fillStyle='#222824';c.fillRect(0,0,256,48);
    c.strokeStyle='#998875';c.strokeRect(2,2,252,44);
    c.font='bold 26px monospace';c.fillStyle='#ffdda1';c.textAlign='center';c.fillText(word,128,32);
    const map=new THREE.CanvasTexture(cv);map.encoding=THREE.sRGBEncoding;map.magFilter=THREE.NearestFilter;
    this.mesh(new THREE.PlaneGeometry(width,width*48/256),new THREE.MeshBasicMaterial({map}),x,y,z);
  }
  lantern(x,y,z){
    const metal=this.material('iron');
    this.block(x,y,z,.27,.52,.27,this.glow(0xffc878));
    for(const dx of [-.15,.15])for(const dz of [-.15,.15])
      this.block(x+dx,y,z+dz,.035,.55,.035,metal);
    for(const dy of [-.29,.29])this.block(x,y+dy,z,.39,.09,.39,metal);
  }
  terminal(x,z,type){
    const metal=this.material('iron');
    this.block(x,1.16,z,1.55,2.32,.95,metal);
    this.block(x,.12,z,1.82,.24,1.18,this.material('flagstone'));
    const tex=this.material(type+'-console').map;
    this.mesh(new THREE.PlaneGeometry(1.36,1.67),new THREE.MeshBasicMaterial({map:tex}),x,1.38,z+.49);
    this.bounds.push([x,z,.88,.61]);
  }
  crate(x,z,size,base=0){
    const wood=this.material('timber'),metal=this.material('iron');
    this.block(x,base+size/2,z,size,size,size,wood);
    for(const y of [.12,.88])this.block(x,base+size*y,z,size+.025,.10,size+.025,metal);
    const brace=this.block(x,base+size/2,z+size*.505,.11,size*1.22,.05,wood);brace.rotation.z=-.72;
    this.bounds.push([x,z,size/2,size/2]);
  }
  actor(x,z,heading,height,tint,pace){
    const bytes=Uint8Array.from(atob(courierGLB),ch=>ch.charCodeAt(0));
    new THREE.GLTFLoader().parse(bytes.buffer,'',g=>{
      const rig=g.scene,box=new THREE.Box3().setFromObject(rig);
      const scale=height/(box.max.y-box.min.y);
      rig.scale.setScalar(scale);rig.position.y=-box.min.y*scale;
      const group=new THREE.Group();group.add(rig);group.position.set(x,0,z);group.rotation.y=heading;this.scene.add(group);
      const suit=this.loader.load(districtMaps[pace>.3?'courier-coat':'warden-coat']);
      suit.encoding=THREE.sRGBEncoding;suit.flipY=false;suit.magFilter=THREE.NearestFilter;
      rig.traverse(m=>{if(m.isMesh){m.material.map=suit;m.material.color.setHex(tint);}});
      const shade=this.mesh(new THREE.CircleGeometry(.42,14),new THREE.MeshBasicMaterial({color:0x44443e}),x,.003,z);
      shade.rotation.x=-Math.PI/2;shade.scale.y=.58;
      const mixer=new THREE.AnimationMixer(rig);
      if(g.animations.length)mixer.clipAction(g.animations[0]).play();
      this.mixers.push(mixer);this.crew.push({group,shade,x,z,heading,pace});
    },error=>console.error('Modello del corriere:',error));
  }
  build(){
    const wall=this.material('fieldstone',3,1.3),metal=this.material('iron'),wood=this.material('timber');
    const floor=this.mesh(new THREE.PlaneGeometry(48,56),this.material('flagstone',15,19),0,-.02,-7);floor.rotation.x=-Math.PI/2;
    // Build up the walls in bays, keeping the stone pattern close to human scale.
    for(const side of [-1,1]){
      for(let z=-22;z<=10;z+=4){
        this.block(side*9,2.6,z,.9,5.2,4,this.material('fieldstone',2,2));
        this.block(side*8.48,2.5,z-1.8,.45,5,.55,this.material('fieldstone',1,2));
        this.block(side*8.28,4.9,z,.45,.34,4,wood);
      }
    }
    for(const z of [-8,-13,-18]){
      this.arch(0,z,2.85,2.45,1.3);
      for(const side of [-1,1]){
        this.block(side*6.05,2.8,z,6.1,5.6,1.25,wall);
        this.bounds.push([side*6.05,z,3.05,.625]);
        this.lantern(side*3.25,3.0,z+.96);
      }
    }
    this.plaque('GATEWAY  /  01',0,5.92,-7.27,2.95);
    const door=this.block(0,1.8,-22,5.3,3.6,.4,this.material('timber',2,1));
    for(const y of [.65,2.65])this.block(door.position.x,y,-21.75,5.2,.17,.1,metal);
    this.terminal(-4.7,-3,'sandbox');this.terminal(2.4,-5.8,'supervisor');this.terminal(5.2,-4,'archivio');
    this.crate(-6.4,-1.7,1.28);this.crate(-7.4,-3.3,1.55);this.crate(-7.4,-3.3,1.0,1.55);
    this.crate(6.8,-5.7,1.4);this.crate(7.3,-7,1);
    const route=[[-4.7,.42,-2.3],[-4.7,.42,-1.88],[2.4,.42,-1.88],[2.4,.42,-5.15],[2.4,.42,-2.5],[5.2,.42,-2.5],[5.2,.42,-3.35]];
    this.route=route.map(v=>new THREE.Vector3(...v));
    for(let i=1;i<this.route.length;i++){
      const a=this.route[i-1],b=this.route[i],dir=b.clone().sub(a);
      const pipe=this.mesh(new THREE.CylinderGeometry(.085,.085,dir.length(),8),metal,0,0,0);
      pipe.position.copy(a).lerp(b,.5);pipe.quaternion.setFromUnitVectors(new THREE.Vector3(0,1,0),dir.normalize());
    }
    this.packet=this.mesh(new THREE.OctahedronGeometry(.18),this.glow(0x74f6c4),0,0,0);
    this.pass=this.block(-5,.88,-10,.6,.35,.09,this.glow(0xffdc78));
    this.actor(-1.45,2.1,1.9,1.92,0xffe0bf,.38);
    this.actor(3.4,-2.8,-1.5,1.92,0xb8d6d1,.24);

    this.sky=this.mesh(new THREE.CylinderGeometry(44,44,22,32,1,true),new THREE.MeshBasicMaterial({map:this.material('skyline',3,1).map,side:THREE.BackSide,fog:false,color:0x9aabc0}),0,9,-6);
  }
  move(dt){
    const pressed=(...keys)=>Number(keys.some(k=>this.keys.has(k)));
    this.yaw+=dt*1.8*(pressed('ArrowRight')-pressed('ArrowLeft'));
    const f=pressed('w','ArrowUp')-pressed('s','ArrowDown'),r=pressed('d')-pressed('a');
    const speed=dt*4/(Math.hypot(f,r)||1);
    const walkable=(x,z)=>Math.abs(x)<8 && z<11 && z>-21 && !this.bounds.some(([cx,cz,w,d])=>Math.abs(x-cx)<w+.18&&Math.abs(z-cz)<d+.18);
    const nx=this.x+speed*(f*Math.sin(this.yaw)+r*Math.cos(this.yaw));
    if(walkable(nx,this.z))this.x=nx;
    const nz=this.z+speed*(-f*Math.cos(this.yaw)+r*Math.sin(this.yaw));
    if(walkable(this.x,nz))this.z=nz;
    if(Math.hypot(this.x-this.pass.position.x,this.z-this.pass.position.z)<1.4)this.foundPass=true;
  }
  draw(sim,now){
    const w=Math.max(1,this.canvas.clientWidth),h=Math.max(1,this.canvas.clientHeight),scale=Math.min(1,(this.renderer.software?460:720)/w);
    const width=Math.round(w*scale),height=Math.max(1,Math.round(h*scale));
    if(this.canvas.width!==width||this.canvas.height!==height){
      this.renderer.setSize(width,height,false);this.camera.aspect=w/h;this.camera.updateProjectionMatrix();
    }
    const delta=Math.min(.08,(now-this.last)/1000);this.last=now;
    this.camera.position.set(this.x,1.62,this.z);this.camera.rotation.set(-.055,-this.yaw,0,'YXZ');
    this.pass.visible=!this.foundPass;this.pass.rotation.y=now*.001;
    for(const mixer of this.mixers)mixer.update(delta*(this.motion ? .68 : 0));
    for(const npc of this.crew){
      const t=now*.0003+npc.heading;
      npc.group.position.x=npc.x+Math.sin(t)*npc.pace;
      npc.group.position.z=npc.z+Math.cos(t)*npc.pace;
      npc.shade.position.x=npc.group.position.x;npc.shade.position.z=npc.group.position.z;
      npc.group.rotation.y=npc.heading+Math.sin(t)*.45;
    }
    const p=sim.packet;this.packet.visible=!!p;
    if(p){
      const segment=p.progress<=.5?p.progress*6:3+(p.progress-.5)*6;
      const from=Math.min(5,Math.floor(segment));
      this.packet.position.copy(this.route[from]).lerp(this.route[from+1],segment-from);
      this.packet.position.y+=.18;this.packet.material.color.setHex(p.state==='denied'?0xff9347:0x74f6c4);
    }
    if(sim.pairs===2&&!this.spawned){
      this.spawned=true;this.terminal(-1.5,-17,'sandbox');this.terminal(1.5,-17,'supervisor');
      this.block(0,.44,-16.8,3,.12,.12,this.material('iron'));this.plaque('NODO 02',0,3.2,-16.3,2);
    }
    this.renderer.render(this.scene,this.camera);
  }
}
class Outside {
  constructor(canvas){
    let renderer;
    try{renderer=new THREE.WebGLRenderer({canvas,antialias:false,alpha:false,powerPreference:'low-power'});}
    catch(error){renderer=new SoftwareRenderer(canvas);}
    return new District3D(canvas,renderer);
  }
}
