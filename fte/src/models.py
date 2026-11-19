"""Convert the existing Shellshift worker to an animated Quake MDL."""
from pathlib import Path
import sys,json,struct,base64,re
import numpy as np
from scipy.spatial.transform import Rotation
from PIL import Image
out=Path(sys.argv[1]);root=Path(__file__).resolve().parents[2]
data=base64.b64decode(re.search("'([^']+)'",(root/'assets/courier.js').read_text())[1])
n=struct.unpack_from('<I',data,12)[0];g=json.loads(data[20:20+n]);buf=data[28+n:]
def acc(k):
    a=g['accessors'][k];v=g['bufferViews'][a['bufferView']];dim={'MAT4':16,'VEC4':4,'VEC3':3,'VEC2':2,'SCALAR':1}[a['type']]
    dtype=np.dtype({5126:'<f4',5123:'<u2',5121:'u1'}[a['componentType']])
    return np.ndarray((a['count'],dim),dtype,buf,v.get('byteOffset',0)+a.get('byteOffset',0),(v.get('byteStride',dtype.itemsize*dim),dtype.itemsize))
def mdl(name,frames,uv,faces,skin):
    f=np.asarray(frames);lo=f.min(axis=(0,1));scale=np.maximum(f.max(axis=(0,1))-lo,.01)/255
    coords=np.rint((f-lo)/scale).astype('uint8')
    verts=len(uv);w,h=skin.size
    header=struct.pack('<ii3f3ff3f8if',1330660425,6,*scale,*lo,80,0,0,48,1,w,h,verts,len(faces),len(frames),0,0,1.)
    # IDPO ident is stored literally, independent of host endianness.
    header=b'IDPO'+header[4:]
    payload=bytearray(header+struct.pack('<i',0)+skin.tobytes())
    for u,v in uv:payload+=struct.pack('<3i',0,int(u*(w-1)),int(v*(h-1)))
    for tri in faces:payload+=struct.pack('<4i',1,*tri)
    for i,frame in enumerate(coords):
        payload+=struct.pack('<i',0)+bytes(frame.min(axis=0))+b'\0'+bytes(frame.max(axis=0))+b'\0'+('walk%d'%i).encode().ljust(16,b'\0')
        payload+=np.column_stack((frame,np.zeros(verts,dtype='uint8'))).astype('uint8').tobytes()
    (out/'progs'/name).write_bytes(payload)
pal=Image.new('P',(1,1));pal.putpalette((out/'gfx/palette.lmp').read_bytes())
p=g['meshes'][0]['primitives'][0];a=p['attributes'];pos=acc(a['POSITION']);uv=acc(a['TEXCOORD_0'])
joints=acc(a['JOINTS_0']);weights=acc(a['WEIGHTS_0']);faces=acc(p['indices']).reshape(-1,3)
skin=g['skins'][0];inv=acc(skin['inverseBindMatrices']).reshape(-1,4,4).transpose(0,2,1)
frames=[]
for phase in np.linspace(0,1,10,endpoint=False):
    nodes=[dict(v) for v in g['nodes']];anim=g['animations'][0]
    for ch in anim['channels']:
        samp=anim['samplers'][ch['sampler']];times=acc(samp['input']).ravel();keys=acc(samp['output'])
        t=times[0]+phase*(times[-1]-times[0]);i=max(0,min(len(times)-2,np.searchsorted(times,t)-1))
        k=(t-times[i])/max(.000001,times[i+1]-times[i])
        dst=ch['target'];a0=keys[i];a1=keys[i+1]
        if dst['path']=='rotation' and a0@a1<0:a1=-a1
        nodes[dst['node']][dst['path']]=a0*(1-k)+a1*k
    glob={}
    def visit(i,parent):
        v=nodes[i]
        if 'matrix' in v:m=np.array(v['matrix']).reshape(4,4).T
        else:
            m=np.eye(4);m[:3,:3]=Rotation.from_quat(v.get('rotation',[0,0,0,1])).as_matrix()@np.diag(v.get('scale',[1,1,1]));m[:3,3]=v.get('translation',[0,0,0])
        glob[i]=parent@m
        for child in v.get('children',[]):visit(child,glob[i])
    for i in g['scenes'][0]['nodes']:visit(i,np.eye(4))
    mats=np.array([glob[i] for i in skin['joints']])@inv
    homogeneous=np.column_stack((pos,np.ones(len(pos))))
    posed=np.einsum('nj,njik,nk->ni',weights,mats[joints],homogeneous)[:,:3]
    frames.append(posed[:,[0,2,1]]*[1,-1,1]*37)
texture=Image.open(root/'assets/courier-coat.jpg').resize((128,128)).convert('RGB').quantize(palette=pal)
mdl('courier.mdl',frames,uv,faces,texture)
v=np.array([[7,0,0],[-7,0,0],[0,7,0],[0,-7,0],[0,0,9],[0,0,-9]])
tri=[[0,2,4],[2,1,4],[1,3,4],[3,0,4],[2,0,5],[1,2,5],[3,1,5],[0,3,5]]
mdl('signal.mdl',[v],np.zeros((6,2)),tri,Image.new('P',(16,16),254))
