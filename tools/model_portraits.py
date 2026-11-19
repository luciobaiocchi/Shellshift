"""Rebuild both opening portraits with Blender --background --python <this file>."""
from math import cos, sin, pi, exp, sqrt
from pathlib import Path
import bpy

DEST = Path(__file__).resolve().parents[1] / "godot" / "cast"


def pigment(name, rgb):
    mat = bpy.data.materials.new(name)
    mat.diffuse_color = tuple(((int(rgb[i:i+2], 16)/255 + .055)/1.055)**2.4 for i in (0, 2, 4)) + (1,)
    mat.use_nodes = True
    bsdf = mat.node_tree.nodes.get("Principled BSDF")
    bsdf.inputs["Base Color"].default_value = mat.diffuse_color
    bsdf.inputs["Roughness"].default_value = .97
    bsdf.inputs["Specular IOR Level"].default_value = .12
    return mat


def mesh(name, points, faces, mat):
    data = bpy.data.meshes.new(name)
    data.from_pydata([(x, -d, h) for x, h, d in points], [], faces)
    data.materials.append(mat)
    obj = bpy.data.objects.new(name, data)
    bpy.context.collection.objects.link(obj)
    return obj


def surface(name, rows, mat, wrap=False):
    n = len(rows[0])
    faces = [(i*n+j, i*n+(j+1)%n, (i+1)*n+(j+1)%n, (i+1)*n+j)
             for i in range(len(rows)-1) for j in range(n if wrap else n-1)]
    return mesh(name, sum(rows, []), faces, mat)


def smile_key(obj):
    obj.shape_key_add(name="Basis")
    key = obj.shape_key_add(name="Smile")
    for point in key.data:
        x = point.co.x
        point.co.z += .009*(abs(x)/.065)**1.7
        point.co.x *= 1.045
        point.co.y -= .0006


def blink(obj, side):
    obj.shape_key_add(name="Basis")
    key = obj.shape_key_add(name="Blink")
    for point in key.data:
        baseline = .041 + side*(point.co.x-side*.084)*.13
        point.co.z = baseline + (point.co.z-baseline)*.045


def portrait(name, dark):
    reviewer = name == "lea"
    bpy.ops.wm.read_factory_settings(use_empty=True)
    skin = pigment("Carnagione", "976b59" if dark else "af8974")
    hair = pigment("Capelli", "383232" if dark else "554940")
    glint = pigment("Creste", "514241" if dark else "756657")
    brow_mat = pigment("Sopracciglio", "4b3734" if dark else "695044")
    if reviewer:
        hair.node_tree.nodes["Principled BSDF"].inputs["Base Color"].default_value = (.070,.076,.078,1)
        glint.node_tree.nodes["Principled BSDF"].inputs["Base Color"].default_value = (.126,.125,.118,1)
    iris = pigment("Iride", "494338" if dark else "635c49")
    pupil = pigment("Pupilla", "342e2b")
    lip = pigment("Labbra", "8f6256" if dark else "ac8172")
    ink = pigment("Ombra", "63473e" if dark else "785a4e")
    white = pigment("Sclera", "a18f7d" if dark else "ad9f8d")
    lid_mat = pigment("Palpebra", "946957" if dark else "ac8574")
    # Width and front-to-back depth are specified independently at each landmark.
    # Nico has a long bridge and square chin, Ada a higher cheek and a soft jaw.
    rings = [(-.245,.042,.073),(-.232,.085,.111),(-.214,.119,.143),
             (-.179,.143,.158),(-.145,.160,.163),(-.102,.174,.163),
             (-.056,.184,.172),(-.012,.196,.178),(.036,.196,.173),
             (.078,.193,.178),(.119,.193,.181),(.166,.191,.180),
             (.210,.171,.151),(.25,.121,.108),(.271,.006,.011)]
    if not dark:
        rings = [(h-.010*max(0,-h/.24),w*(1.0+.046*exp(-((h+.17)/.08)**2)),
                  r+.013*exp(-((h+.21)/.055)**2)) for h,w,r in rings]

    if reviewer:
        rings = [(h*.96,w*(1+.054*exp(-((h+.013)/.047)**2)-.075*exp(-((h+.165)/.064)**2)),r) for h,w,r in rings]

    def section(h):
        h = max(rings[0][0], min(rings[-1][0], h))
        lo,hi = next((a,b) for a,b in zip(rings,rings[1:]) if a[0] <= h <= b[0])
        k = (h-lo[0])/(hi[0]-lo[0])
        return lo[1]+(hi[1]-lo[1])*k,lo[2]+(hi[2]-lo[2])*k

    def hill(x,h,cx,cz,w,l):
        return exp(-((abs(x)-cx)/w)**2 - ((h-cz)/l)**2)

    def relief(x,h):
        bridge = .031 if reviewer else (.037 if dark else .048)
        tip = -.052 if dark else -.063
        return (bridge*hill(x,h,0,.007,.023,.087)
                +(.041 if reviewer else (.048 if dark else .051))*hill(x,h,0,tip,.028,.029)
                +.025*hill(x,h,.031,tip-.007,.014,.015)
                -.012*hill(x,h,.021,tip-.019,.014,.01)
                -.024*hill(x,h,.080,.039,.043,.029)
                +.016*hill(x,h,.076,.081,.047,.024)
                +.024*hill(x,h,.118,-.014,.053,.031)
                -.013*hill(x,h,.134,-.092,.041,.049)
                +.018*hill(x,h,.011,-.108,.068,.039)
                -.009*hill(x,h,.003,-.148,.055,.013)
                +.014*hill(x,h,.015,-.192,.068,.037))

    def face_depth(x,h):
        w,r = section(h)
        frontal = sqrt(max(0.0,1-(x/w)**2))
        return (r+relief(x,h))*frontal

    angles = [2*pi*j/80 for j in range(80)]
    rows = []
    for lo,hi in zip(rings,rings[1:]):
        for j in range(4):
            h = lo[0]+(hi[0]-lo[0])*j/4
            w,r = section(h)
            rows.append([(w*sin(a),h,(r+relief(w*sin(a),h)*max(0,cos(a)))*cos(a)) for a in angles])
    rows.append([(rings[-1][1]*sin(a),rings[-1][0],.01*cos(a)) for a in angles])
    face = surface("Viso",rows,skin,True)
    for poly in face.data.polygons:
        poly.use_smooth = True
    # A restrained wash follows the planes of the face like the printed room textures.
    # Small tonal steps stay legible in the low-resolution viewport and the glTF.
    for index in range(1,8):
        tone=skin.copy()
        tone.name="Carnagione tono %d" % index
        rgb=tuple(v*(1-.037*index) for v in skin.diffuse_color[:3])+(1,)
        tone.diffuse_color=rgb
        tone.node_tree.nodes["Principled BSDF"].inputs["Base Color"].default_value=rgb
        face.data.materials.append(tone)
    for poly in face.data.polygons:
        x,y,h = poly.center
        sockets = hill(x,h,.079,.046,.054,.040)
        temples = hill(x,h,.164,.065,.031,.065)
        jaw = .5+.5*cos(pi*min(1, max(0,(h+.20)/.13)))
        grain = .27*sin(x*9171+h*3317)*cos(x*8103+h*931)
        poly.material_index=max(0,min(7,round(3.4*sockets+2.3*temples+(1.1 if dark else 3.2)*jaw+grain)))

    for side in (-1,1):
        suffix = "L" if side < 0 else "R"
        cx = side*.084
        upper,lower,lashes,brows = ([[],[]] for _ in range(4))
        whites = [[],[],[]]
        irises = [[],[],[]]
        # Upper lids overlap the iris; the visible sclera is a small, tinted almond.
        for j in range(25):
            u = j/12-1
            bell = max(0,1-u*u)**.72
            x = cx+u*.039
            h = .041+.004*side*u
            base = face_depth(x,h)
            for row,dy in zip(whites,[-.008,0,.010]):
                row.append((x,h+dy*bell,base+.0039+.002*bell))
            for row,dy in zip(upper,[.0095,.023]):
                y = h+dy*bell
                row.append((x,y,face_depth(x,y)+(.006 if dy<.01 else .0014)*bell+.0006))
            for row,dy in zip(lower,[-.019,-.008]):
                y = h+dy*bell
                row.append((x,y,face_depth(x,y)+(.0012 if dy<-.01 else .0063)*bell+.0006))
            for row,dy in zip(lashes,[.0084,.0104]):
                row.append((x,h+dy*bell,base+.008*bell+.001))
            bx = cx+u*.048
            bh = (.085 if reviewer else .078) + (.011 if reviewer else .007)*bell - .004*side*u + (.003 if side==1 else 0)
            for row,dy in zip(brows,[0,.009 if dark else .008]):
                y = bh+dy*bell
                row.append((bx,y,face_depth(bx,y)+.0021))
        blink(surface("Occhio"+suffix,whites,white),side)
        surface("Plica"+suffix,upper,lid_mat)
        surface("Borsa"+suffix,lower,skin)
        blink(surface("Ciglia"+suffix,lashes,ink),side)
        surface("Sopracciglio"+suffix,brows,brow_mat)
        def iris_patch(n,rad,mat,front):
            for row in irises: row.clear()
            for j in range(19):
                u=j/9-1
                x=cx+u*rad
                circle=sqrt(max(0,1-u*u))*rad
                for row,dy in zip(irises,[-min(.0076,circle),0,min(.0092,circle)]):
                    row.append((x,.041+dy,face_depth(x,.041)+front))
            return surface(n,irises,mat)
        blink(iris_patch("Iride"+suffix,.0135,iris,.0074),side)
        # The pupil shares the iris mesh so the gaze and blink tracks move it too.
        eye = bpy.data.objects["Iride"+suffix]
        eye.data.materials.append(pupil)
        for poly in eye.data.polygons:
            if abs(poly.center.x-cx)<.0045:
                poly.material_index=1
        ear = [[(side*(.188+radius*.029*cos(a)),-.012+radius*.052*sin(a),z)
                for a in angles] for radius,z in [(1,-.020),(.86,.014),(.54,.010),(.10,.013)]]
        surface("Orecchio"+suffix,ear,skin,True)
    # Rims and lip seam hug the same facial surface, even in three-quarter view.
    mouth=[[],[],[],[],[]]
    for j in range(33):
        u=j/16-1
        x=.064*u
        h=-.115+.001*u+.0006*cos(pi*u)
        bell=max(0,1-u*u)
        bow=exp(-((abs(u)-.27)/.20)**2)
        for row,dy in zip(mouth,[-.010,-.006,0,.004,.006+.003*bow]):
            y=h+dy*bell
            d=face_depth(x,y)+.0009+(.0024 if dy in [-.006,.004] else .0009)*bell
            row.append((x,y,d))
    smile_key(surface("Labbra",mouth,lip))
    seam=[[(x,h+delta*(1-(x/.064)**2),d+.0014) for x,h,d in mouth[2]] for delta in [-.0012,.0013]]
    smile_key(surface("Rima",seam,ink))

    # A shaped scalp with receding temples, ears cut free and an irregular side part.
    def scalp(a,t):
        c=cos(a)
        fringe=((.092 if dark else .11)*c+.041+.021*sin(2*a-.28)
                +(.040 if not dark else .019)*exp(-((abs(sin(a))-.71)/.21)**2)*max(0,c)
                -.045*exp(-((abs(sin(a))-.96)/.055)**2))
        if reviewer:
            fringe += .044*max(0,sin(a))*max(0,c)-.033*max(0,-sin(a))
        elif not dark:
            fringe += .028*max(0,c)**2
        h=fringe+(.289-fringe)*t
        w,r=section(h-.013)
        crown=max(0,1-t**6)
        ridge=.0029*cos(15*a+6*t)*crown
        return ((w+.010*crown+ridge)*sin(a)-.013*t,
                h,(r+.011*crown+ridge)*cos(a)-.005)
    surface("Pettinatura",[[scalp(a,t/16) for a in angles] for t in range(17)],hair,True)
    bands = 19 if dark else (23 if reviewer else 21)
    for j in range(bands):
        a0=2*pi*(j+.14*sin(2.1*j))/bands
        lock=[]
        sweep=(.80 if dark else (-.85 if reviewer else 1.17))*cos(a0-.20)
        for k in range(13):
            t=k/12
            f=t*.86
            a=a0+sweep*f
            width=(pi/bands)*(.36+.66*sin(pi*t)**.55)
            row=[]
            for u in [-1,-.35,.12,1]:
                theta=a+width*u
                x,h,d=scalp(theta,f)
                puff=(.001+.0065*(1-abs(u))*sin(pi*t)**.65)
                row.append((x+puff*sin(theta),h-(.003+.001*sin(j))*(1-t)**5+.0035*sin(pi*t),d+puff*cos(theta)))
            lock.append(row)
        strand=surface("Ciocca",lock,hair)
        strand.data.materials.append(glint)
        for poly in strand.data.polygons:
            if poly.index%3==0 and 3<poly.index<30 and j%4==1:
                poly.material_index=1
    neck = [[((.079 if dark else .087)*sin(a),h,.075*cos(a)-.028) for a in angles] for h in (-.34,-.16)]
    surface("Collo",neck,skin,True)
    for mat in bpy.data.materials:
        mat.use_backface_culling = False
    # The assembled costume file links this collection as a whole. New sculpted
    # details therefore appear automatically when the source portrait is revised.
    collection = bpy.data.collections.new(name.capitalize()+" Portrait")
    bpy.context.scene.collection.children.link(collection)
    for obj in list(bpy.context.scene.collection.objects):
        bpy.context.scene.collection.objects.unlink(obj)
        collection.objects.link(obj)
    bpy.context.preferences.filepaths.save_version = 0
    for area in bpy.context.screen.areas:
        if area.type == "VIEW_3D":
            from mathutils import Euler
            view = area.spaces.active
            view.region_3d.view_rotation = Euler((pi/2,0,.16)).to_quaternion()
            view.region_3d.view_distance = 1.15
            view.overlay.show_overlays = False
            view.shading.color_type = "MATERIAL"
    bpy.ops.wm.save_as_mainfile(filepath=str(DEST.parents[1]/"art"/"office"/(name+".blend")),compress=True)
    bpy.ops.export_scene.gltf(filepath=str(DEST/(name+".glb")),export_format="GLB",export_animations=False)


portrait("ada",True)
portrait("nico",False)
portrait("lea",False)
