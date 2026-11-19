"""Build Quake map, palette and textures. Run from any directory with Pillow installed."""
from pathlib import Path
from PIL import Image
import struct, sys
src = Path(__file__).resolve().parent
out = Path(sys.argv[1]).resolve()
for sub in ('maps','gfx','progs'):
    (out/sub).mkdir(parents=True,exist_ok=True)
art = src.parents[1]/'assets'
# 216 ordinary colours; 32 emissive indices at the end of the palette.
palette = [(r*51,g*51,b*51) for r in range(6) for g in range(6) for b in range(6)]
palette += [(v,v,v) for v in range(8,72,8)]
palette += [(int(100+5*i),int(39+4*i),18) for i in range(32)]
raw = bytes(c for rgb in palette for c in rgb)
(out/'gfx/palette.lmp').write_bytes(raw)
pal = Image.new('P',(1,1)); pal.putpalette(raw)
def indexed(im):
    return im.convert('RGB').quantize(palette=pal,dither=Image.Dither.NONE)
colormap = bytearray()
for level in range(64):
    for i,(r,g,b) in enumerate(palette):
        f=1-level/64
        colormap.append(i if i>=224 else min(range(224),key=lambda j:sum((v*f-t)**2 for v,t in zip((r,g,b),palette[j]))))
(out/'gfx/colormap.lmp').write_bytes(colormap+struct.pack('<I',32))
wad=bytearray(b'WAD2'+bytes(8));directory=bytearray()
materials={'iron':'iron','stone':'fieldstone','slab':'flagstone','wood':'timber','locker':'sandbox-console','filter':'supervisor-console','archive':'archivio-console'}
for name in [*materials,'void','amber','beacon']:
    if name in materials:
        im=Image.open(art/(materials[name]+'.jpg')).resize((128,128))
    else:
        im=Image.new('RGB',(16,16),{'void':(0,0,0),'amber':(254,160,18),'beacon':(196,98,18)}[name])
    w,h=im.size;data=bytearray();offsets=[]
    for level in range(4):
        offsets.append(40+len(data))
        small=indexed(im.resize((w>>level,h>>level),Image.Resampling.BOX))
        if name in ('amber','beacon'):small.paste(253 if name=='amber' else 240,(0,0,*small.size))
        data+=small.tobytes()
    key=name.encode().ljust(16,b'\0');tex=key+struct.pack('<6I',w,h,*offsets)+data
    directory+=struct.pack('<iiiBBH16s',len(wad),len(tex),len(tex),68,0,0,key);wad+=tex
struct.pack_into('<ii',wad,4,len(directory)//32,len(wad));(out/'sector.wad').write_bytes(wad+directory)
brushes=[]; entities=[]
def box(x,y,z,X,Y,Z,texture):
    faces=[((x,y,z),(x,Y,z),(x,Y,Z)),((X,Y,z),(X,y,z),(X,y,Z)),((X,y,z),(x,y,z),(x,y,Z)),((x,Y,z),(X,Y,z),(X,Y,Z)),((x,Y,z),(x,y,z),(X,y,z)),((X,y,Z),(x,y,Z),(x,Y,Z))]
    # Quake map plane normals use the opposite winding to the conventional cross product.
    brushes.append('{\n'+'\n'.join(' '.join('( %d %d %d )'%p for p in face)+' '+texture+' 0 0 0 1 1' for face in faces)+'\n}')
def entity(name,x,y,z,**props):
    ent=dict(classname=name,origin=f'{x} {y} {z}',**props)
    entities.append('{\n'+'\n'.join(f'"{k}" "{v}"' for k,v in ent.items())+'\n}')
def light(x,y,z,power):
    entity('light',x,y,z,light=str(power))
# Sealed black shell and fully walkable dark floor.
box(-2032,-1536,-64,2032,3000,0,'slab')
box(-2064,-1568,-64,-2032,3032,1536,'void');box(2032,-1568,-64,2064,3032,1536,'void')
box(-2032,-1568,-64,2032,-1536,1536,'void');box(-2032,3000,-64,2032,3032,1536,'void')
box(-2064,-1568,1536,2064,3032,1568,'void')
def container(x,y,w,d,h,panel):
    box(x,y,0,x+w,y+d,h,'iron')
    for xx in range(x,x+w,100):
        box(xx,y-10,0,xx+10,y,h,'iron')
    box(x,y-14,h-18,x+w,y,h,'stone')
    box(x+24,y-18,h-10,x+42,y,h,'beacon')
    cx=x+w//2
    box(cx-38,y-13,0,cx+38,y,94,'wood')
    box(cx+44,y-22,30,cx+72,y,68,panel)
    box(cx-34,y-19,99,cx+34,y,103,'amber')
    light(cx,y-96,120,340);light(cx+80,y-180,260,290)
container(-1120,-160,640,900,600,'locker')
container(400,430,720,880,710,'filter')
container(1170,-250,430,510,435,'archive')
# Thirty-four metre gantry; the opening is dark and can be walked through.
for x in [-590,360]:
    box(x,1690,0,x+230,2160,1088,'stone')
    box(x-24,1658,0,x+254,2170,54,'iron')
    for z in (192,480,832):box(x+45,1678,z,x+69,1690,z+8,'beacon')
    light(x+100,1510,90,400);light(x+110,1510,730,410)
box(-590,1690,895,590,2160,1088,'iron')
box(-240,1685,922,240,1690,929,'amber')
light(0,1540,940,390)
# The pipe snakes between sandbox, supervisor and archive. Only couplings are lit.
for x,y,X,Y in [(-795,-400,-785,-160),(-795,-400,325,-390),(315,-400,325,330),(315,320,765,330),(755,320,765,430),(765,320,1150,330),(1140,-300,1150,320),(1140,-300,1390,-290),(1380,-300,1390,-250)]:
    box(x,y,10,X,Y,21,'iron')
for x,y in [(-790,-392),(-280,-392),(320,-392),(320,322),(760,322),(1145,322),(1145,-294),(1385,-294)]:
    box(x-7,y-7,10,x+7,y+7,25,'beacon');light(x,y,46,125)
entity('shift_signal',-790,-158,36)
for px,py,w,d,h in [(-1350,2200,570,620,492),(690,2210,560,590,562),(-800,2300,1500,12,20)]:
    box(px,py,0,px+w,py+d,h,'iron')
    entities.append('{\n"classname" "shift_pod"\n'+brushes.pop()+'\n}')
    light(px+w//2,py-100,165,285)
entity('info_player_start',-100,-1020,42,angle='90')
entity('shift_worker',-192,-680,2,angle='40')
entity('shift_worker',715,340,2,angle='175')
light(-195,-690,95,205);light(-410,-304,244,480);light(-826,-418,540,450)
light(804,210,600,460)
(out/'maps/void.map').write_text('{\n"classname" "worldspawn"\n"wad" "sector.wad"\n"message" "Shellshift - Black Sector"\n'+'\n'.join(brushes)+'\n}\n'+'\n'.join(entities)+'\n')
