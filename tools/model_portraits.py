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
    bsdf.inputs["Roughness"].default_value = .95
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
        point.co.z += .024*(abs(x)/.065)**1.7
        point.co.x *= 1.12
        point.co.y -= .002


def portrait(name, dark):
    bpy.ops.wm.read_factory_settings(use_empty=True)
    skin = pigment("Carnagione", "ad7258" if dark else "cb997f")
    hair = pigment("Capelli", "382c30" if dark else "594035")
    iris = pigment("Iride", "47332c")
    lip = pigment("Labbra", "824a45" if dark else "a7675e")
    ink = pigment("Ombra", "503637")
    white = pigment("Avorio", "d8c5ad")
    # Cross-sections from chin to crown. Recess the sockets and carry the nose
    # bridge, cheekbones and muzzle in the continuous surface of the face.
    rings = [(-.24,.047,.105),(-.215,.098,.147),(-.165,.151,.161),
             (-.10,.183,.173),(-.05,.196,.177),(0,.207,.18),
             (.055,.21,.179),(.105,.214,.185),(.17,.209,.18),
             (.219,.183,.151),(.25,.135,.113),(.27,.009,.01)]
    def depth(x,h):
        def hill(cx,cz,w,l):
            return exp(-((abs(x)-cx)/w)**2-((h-cz)/l)**2)
        return (.042*hill(0,.018,.028,.091)+.073*hill(0,-.031,.034,.029)
                +.023*hill(.037,-.045,.016,.016)-.018*hill(.083,.044,.05,.03)
                +.019*hill(.118,-.019,.052,.046)+.018*hill(0,-.098,.082,.035))
    angles = [2*pi*j/56 for j in range(56)]
    rows = []
    for a,b in zip(rings,rings[1:]):
        for f in (0,.5):
            h,w,r = [v+(k-v)*f for v,k in zip(a,b)]
            row = []
            for ang in angles:
                x = w*sin(ang)
                d = r*cos(ang)+max(0,cos(ang))*depth(x,h)
                row.append((x,h,d))
            rows.append(row)
    rows.append([(rings[-1][1]*sin(v),.27,.01*cos(v)) for v in angles])
    surface("Viso",rows,skin,True)
    for s in (-1,1):
        # Almond sclera follows the curved face. Both lids meet at the canthi.
        rows = [[],[],[]]
        upper = [[],[]]
        brow = [[],[]]
        for j in range(17):
            u = j/8-1
            bulge = max(0,1-u*u)
            x = s*.084+u*.045
            h = .041+s*u*.006
            d = .18*sqrt(1-(x/.21)**2)+depth(x,h)+.007
            for row,offset in zip(rows,[-.010,0,.015]):
                row.append((x,h+offset*bulge,d+.004*bulge))
            for row,offset in zip(upper,[0,.005]):
                row.append((x,h+(.014+offset)*bulge,d+.006*bulge))
            bh = h+.042+.008*bulge-s*u*.012
            for row,offset in zip(brow,[0,.010]):
                row.append((x,bh+offset*bulge,d+.009))
        surface("Occhio",rows,white)
        surface("Ciglia",upper,hair)
        surface("Sopracciglio",brow,hair)
        x = s*.084
        d = .18*sqrt(1-(x/.21)**2)+depth(x,.041)+.017
        pupil = [(x+.012*cos(v),.042+.012*sin(v),d-s*.005*cos(v)) for v in angles]
        mesh("Iride",pupil,[tuple(range(len(pupil)))],iris)
        ear = [[(s*(.194 + radius*.032*cos(v)), -.008+radius*.058*sin(v), z) for v in angles]
               for radius,z in [(1,-.014),(.85,.018),(.48,.012),(.12,.017)]]
        surface("Orecchio",ear,skin,True)
    mouth = [[],[],[],[]]
    for j in range(25):
        u = j/12-1
        x = .065*u
        h = -.108+.002*u+.003*u*u
        d = .174*sqrt(1-(x/.18)**2)+depth(x,h)+.005
        for row,offset in zip(mouth,[-.012,-.002,.001,.008]):
            row.append((x,h+offset*(1-u*u),d+.004*(1-u*u)))
    smile_key(surface("Labbra",mouth,lip))
    smile_key(surface("Rima", [[(x,h,d+.001) for x,h,d in row] for row in mouth[1:3]],ink))
    # A single asymmetric swept cap with irregular ridges, a side part and nape.
    cap = []
    for j in range(15):
        f = j/14
        row = []
        for a in angles:
            fringe = .10*cos(a)+.04+.023*sin(3*a+.7) if dark else .105*cos(a)+.025+.026*sin(2*a-.5)
            h = fringe + (.307-fringe)*f
            sample = min(.269,h-.04)
            lo,hi = next((lo,hi) for lo,hi in zip(rings,rings[1:]) if lo[0] <= sample <= hi[0])
            k = (sample-lo[0])/(hi[0]-lo[0])
            width = lo[1]+(hi[1]-lo[1])*k
            radius = lo[2]+(hi[2]-lo[2])*k
            ridge = .007*cos((13 if dark else 9)*a+5*f)
            row.append(((width+.024+ridge)*sin(a)-.012*f, h,
                        (radius+.026+ridge)*cos(a)))
        cap.append(row)
    surface("Pettinatura",cap,hair,True)
    neck = [[(.081*sin(a),h,.075*cos(a)-.025) for a in angles] for h in (-.34,-.16)]
    surface("Collo",neck,skin,True)
    for mat in bpy.data.materials:
        mat.use_backface_culling = False
    bpy.ops.export_scene.gltf(filepath=str(DEST/(name+".glb")),export_format="GLB",export_animations=False)


portrait("ada",True)
portrait("nico",False)
