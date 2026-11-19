"""Run blender -b art/office_cast.blend -P tools/export_office_cast.py from the repo."""
from pathlib import Path
import bpy
from mathutils import Matrix

destination = Path(bpy.data.filepath).resolve().parent.parent / "godot" / "office" / "wardrobe"
destination.mkdir(parents=True, exist_ok=True)

# Each object's local origin is also its rotation pivot in Godot. Export in
# place at that origin while keeping the assembled Blender scene intact.
for name in ("Ada", "Nico"):
    for piece in ("Jacket", "Trousers", "UpperL", "UpperR", "ForearmL", "ForearmR", "Accessory"):
        obj = bpy.data.objects[name + piece]
        transform = obj.matrix_world.copy()
        bpy.ops.object.select_all(action="DESELECT")
        obj.select_set(True)
        try:
            obj.matrix_world = Matrix.Identity(4)
            bpy.ops.export_scene.gltf(
                filepath=str(destination / (obj.name + ".glb")),
                use_selection=True,
                export_format="GLB",
                export_animations=False,
            )
        finally:
            obj.matrix_world = transform
