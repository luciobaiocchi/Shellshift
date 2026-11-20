"""Build the additional prologue performers using Python 3, Pillow and Blender 5.

python tools/build_rocketbox_ensemble.py [nico lea ...] --cache /tmp/rocketbox
"""
import argparse
from concurrent.futures import ThreadPoolExecutor
import hashlib
import json
from pathlib import Path
import re
import shutil
import struct
import subprocess
import sys
from urllib.request import urlopen

PIN = "0943055db6ec570bcef9f2c8b41c9e5467c808f9"
REPO = "microsoft/Microsoft-Rocketbox"
CAST = {
    "nico": "Male_Adult_02", "lea": "Business_Female_01",
    "rosa": "Female_Adult_05", "rosa_mother": "Business_Female_02",
    "clerk": "Business_Male_07", "ren": "Business_Male_05",
    "ivo": "Male_Adult_05", "jo": "Female_Adult_13",
    "extra_a": "Male_Adult_12", "extra_b": "Female_Adult_06",
    "extra_c": "Female_Adult_03", "extra_d": "Male_Adult_04", "extra_e": "Female_Adult_09",
}
EXPRESSIONS = {
    "AU_45_Blink": "Blink", "AU_12_LipCornerPuller": "Smile",
    "AU_06_CheekRaiser": "CheekRaise", "AU_25_LipsPart": "LipsPart",
    "AU_61_EyesTurnLeft": "LookLeft", "AU_62_EyesTurnRight": "LookRight",
    "AU_63_EyesUp": "LookUp", "AU_64_EyesDown": "LookDown",
}
SIDED = {
    "BrowInnerUp", "BrowDownLeft", "BrowDownRight", "EyeBlinkLeft",
    "EyeBlinkRight", "MouthSmileLeft", "MouthSmileRight", "JawOpen",
    "EyeSquintLeft", "EyeSquintRight", "MouthFrownLeft", "MouthFrownRight",
}


def acquire(cache, roles):
    index_url = f"https://api.github.com/repos/{REPO}/git/trees/{PIN}?recursive=1"
    index_file = cache / f"tree-{PIN}.json"
    if not index_file.exists():
        with urlopen(index_url, timeout=60) as response:
            index_file.write_bytes(response.read())
    tree = json.loads(index_file.read_text())
    if tree["sha"] != PIN or tree.get("truncated"):
        raise ValueError("Incomplete Rocketbox tree")
    jobs = []
    for role in roles:
        avatar = CAST[role]
        folder = cache / avatar
        folder.mkdir(exist_ok=True)
        for item in tree["tree"]:
            path = item["path"]
            if (path.startswith("Assets/Avatars/") and f"/{avatar}/" in path
                    and path.endswith(("_facial.fbx", "_color.tga"))):
                jobs.append((item, folder / Path(path).name))

    def fetch(job):
        item, dest = job
        if not dest.exists() or dest.stat().st_size != item["size"]:
            url = f"https://raw.githubusercontent.com/{REPO}/{PIN}/{item['path']}"
            subprocess.run(["curl", "-fsSL", "--retry", "3", url, "-o", str(dest)], check=True)
        digest = hashlib.sha1(f"blob {item['size']}\0".encode() + dest.read_bytes()).hexdigest()
        if digest != item["sha"]:
            raise ValueError(f"Wrong Git blob for {dest}")

    with ThreadPoolExecutor(max_workers=8) as pool:
        list(pool.map(fetch, jobs))


def silver_hair(image, material):
    """Keep the photographed highlights and grade hair UV islands around the face."""
    from PIL import Image, ImageDraw, ImageFilter, ImageOps
    mask = Image.new("L", (420, 420))
    paint = ImageDraw.Draw(mask)
    if material == "head":
        paint.polygon([(0,0),(419,0),(419,209),(349,211),(335,168),(320,139),
                       (310,140),(302,124),(283,103),(269,78),(250,61),(216,57),
                       (197,64),(172,66),(159,79),(151,98),(140,118),(127,133),
                       (110,119),(93,129),(80,170),(72,212),(0,210)], fill=220)
        paint.polygon([(54,282),(198,351),(258,330),(415,254),(419,419),(135,419),
                       (131,372),(119,360),(92,364),(63,327)], fill=220)
    else:
        paint.rectangle((0,0,419,419),fill=220)
        # The thin lash islands share the transparency atlas with the hair.
        paint.rectangle((356,125,384,212), fill=0)
        paint.rectangle((198,387,303,419), fill=0)
    mask = mask.resize(image.size, Image.Resampling.BICUBIC).filter(ImageFilter.GaussianBlur(8))
    luminance = ImageOps.grayscale(image).point(lambda x: 30 + .88*x)
    silver = Image.merge("RGB", (luminance.point(lambda x: x+5), luminance.point(lambda x: x+4), luminance))
    result = Image.composite(silver, image.convert("RGB"), mask)
    if "A" in image.getbands():
        result.putalpha(image.getchannel("A"))
    return result


def prepare_textures(folder, role):
    from PIL import Image
    for source in folder.glob("*_color.tga"):
        kind = source.stem.split("_", 1)[1].removesuffix("_color")
        if kind == "glasses_opacity":
            kind = "glasses"
        with Image.open(source) as original:
            image = original.copy()
        if role == "rosa_mother" and kind in ("head", "opacity"):
            image = silver_hair(image, kind)
        limit = 1536 if kind == "head" else 1024
        image.thumbnail((limit,limit), Image.Resampling.LANCZOS)
        if kind in ("opacity", "glasses"):
            image.save(folder / (kind + ".png"), optimize=True)
        else:
            image.convert("RGB").save(folder / (kind + ".jpg"), quality=91, subsampling=0, optimize=True)


def blender_build(cache, out, roles):
    import bpy
    from mathutils import Matrix
    for role in roles:
        folder = cache / CAST[role]
        bpy.ops.wm.read_factory_settings(use_empty=True)
        bpy.ops.import_scene.fbx(filepath=str(folder / (CAST[role]+"_facial.fbx")), use_anim=False)
        mesh, = [o for o in bpy.context.scene.objects if o.type == "MESH"]
        rig, = [o for o in bpy.context.scene.objects if o.type == "ARMATURE"]
        mesh_world = mesh.matrix_world.copy()
        rig_world = rig.matrix_world.copy()
        mesh.parent = None
        for bone in rig.pose.bones:
            bone.matrix_basis = Matrix.Identity(4)
        rig.data.transform(rig_world)
        rig.matrix_world = Matrix.Identity(4)
        mesh.data.transform(mesh_world, shape_keys=True)
        mesh.parent = rig
        mesh.matrix_parent_inverse = Matrix.Identity(4)
        mesh.matrix_world = Matrix.Identity(4)
        rig.name, mesh.name = "CastRig", "ActorMesh"

        for shape in list(mesh.data.shape_keys.key_blocks)[1:]:
            arkit = re.fullmatch(r"AK_\d+_(.*)", shape.name)
            if shape.name in EXPRESSIONS:
                shape.name = EXPRESSIONS[shape.name]
            elif arkit and arkit[1] in SIDED:
                shape.name = arkit[1]
            else:
                mesh.shape_key_remove(shape)
                continue
            shape.value = 0
        actual = set(mesh.data.shape_keys.key_blocks.keys()) - {"Basis"}
        expected = set(EXPRESSIONS.values()) | SIDED
        if expected - actual:
            raise ValueError(f"Missing facial controls on {role}: {expected-actual}")

        for mat in mesh.data.materials:
            kind = mat.name.split("_")[1]
            transparent = kind in ("opacity","glasses")
            mat.name = role.title() + "_" + kind
            mat.use_nodes = True
            nodes, links = mat.node_tree.nodes, mat.node_tree.links
            nodes.clear()
            target = nodes.new("ShaderNodeOutputMaterial")
            surface = nodes.new("ShaderNodeBsdfPrincipled")
            surface.inputs["Roughness"].default_value = .90
            surface.inputs["Specular IOR Level"].default_value = .18
            links.new(surface.outputs[0],target.inputs[0])
            texture = nodes.new("ShaderNodeTexImage")
            texture.image = bpy.data.images.load(str(folder / (kind + (".png" if transparent else ".jpg"))))
            texture.image.name = mat.name
            links.new(texture.outputs["Color"], surface.inputs["Base Color"])
            if transparent:
                links.new(texture.outputs["Alpha"], surface.inputs["Alpha"])
            mat.use_backface_culling = not transparent
        bpy.context.view_layer.update()
        dest = out / (role + ".glb")
        bpy.ops.export_scene.gltf(filepath=str(dest), export_format="GLB", export_animations=False,
                                  export_morph_normal=False, export_morph_tangent=False,
                                  export_try_sparse_sk=True, export_try_omit_sparse_sk=True,
                                  export_skins=True, export_all_influences=True)
        # Mark lash and glasses cards explicitly as blended, double-sided surfaces.
        data = dest.read_bytes()
        length, kind = struct.unpack_from("<II", data, 12)
        doc = json.loads(data[20:20+length])
        for mat in doc["materials"]:
            if mat["name"].endswith(("_opacity","_glasses")):
                mat.update(alphaMode="BLEND", doubleSided=True)
                mat.pop("alphaCutoff", None)
        payload = json.dumps(doc,separators=(",", ":")).encode()
        payload += b" " * (-len(payload)%4)
        tail = data[20+length:]
        dest.write_bytes(data[:8] + struct.pack("<III",20+len(payload)+len(tail),len(payload),kind) + payload + tail)
        print("CAST_READY", role, len(rig.data.bones), len(actual), dest.stat().st_size, flush=True)


def main():
    project = Path(__file__).resolve().parents[1]
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("roles", nargs="*")
    parser.add_argument("--cache", type=Path, default=Path.home()/".cache"/"shellshift-rocketbox")
    parser.add_argument("--out", type=Path, default=project/"godot"/"casting")
    opts = parser.parse_args()
    roles = opts.roles or list(CAST)
    if not set(roles) <= CAST.keys():
        parser.error("Available performers: " + ", ".join(CAST))
    cache, out = opts.cache.resolve(), opts.out.resolve()
    cache.mkdir(parents=True, exist_ok=True)
    out.mkdir(parents=True, exist_ok=True)
    acquire(cache, roles)
    with ThreadPoolExecutor(max_workers=3) as pool:
        list(pool.map(lambda r: prepare_textures(cache/CAST[r], r), roles))
    blender = shutil.which("blender")
    if not blender:
        raise SystemExit("The Blender executable must be on PATH")
    subprocess.run([blender, "-b", "--python-exit-code", "1", "--python", __file__,
                    "--", str(cache), str(out), *roles],check=True)


if __name__ == "__main__":
    if "--" in sys.argv:
        cache_arg, out_arg, *role_args = sys.argv[sys.argv.index("--")+1:]
        blender_build(Path(cache_arg), Path(out_arg), role_args)
    else:
        main()
