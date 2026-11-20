extends RefCounted
## Late-period makeup matched to each original performer's head and hair UVs.
const MAKEUP := {
	"ada": [preload("res://casting/years/ada_face.jpg"), preload("res://casting/years/ada_hair.webp")],
	"clerk": [preload("res://casting/years/clerk_face.jpg"), null],
	"lea": [preload("res://casting/years/lea_face.jpg"), preload("res://casting/years/lea_hair.webp")],
	"nico": [preload("res://casting/years/nico_face.jpg"), preload("res://casting/years/nico_hair.webp")],
	"rosa": [preload("res://casting/years/rosa_face.jpg"), preload("res://casting/years/rosa_hair.webp")],
}


static func apply(mesh: MeshInstance3D, identity: String) -> void:
	if not is_instance_valid(mesh) or mesh.mesh == null or not MAKEUP.has(identity):
		return
	var textures: Array = MAKEUP[identity]
	for surface in mesh.mesh.get_surface_count():
		var original := mesh.mesh.surface_get_material(surface) as BaseMaterial3D
		if not original:
			continue
		var part := original.resource_name.to_lower()
		var texture: Texture2D
		if part.ends_with("_head"):
			texture = textures[0]
		elif part.ends_with("_opacity"):
			texture = textures[1]
		if texture == null:
			continue
		var material := mesh.get_active_material(surface) as BaseMaterial3D
		if material and material.albedo_texture != texture:
			var localized := material.duplicate() as BaseMaterial3D
			localized.albedo_texture = texture
			mesh.set_surface_override_material(surface, localized)
