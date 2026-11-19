extends MeshInstance3D
## The new body's hand seen at eye level. Its broken contours match the registration glass.

func build(dye: Color) -> void:
	var surface := SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	# Successive contours form the forearm, wrist, heel of the palm and knuckles.
	var palm := [
		Vector3(.024,-.23,.017), Vector3(.011,-.12,.009), Vector3(.004,-.043,.005),
		Vector3(0,-.024,.002), Vector3(-.002,.008,0), Vector3(0,.045,-.001),
		Vector3(.001,.065,-.003), Vector3(.002,.071,-.003)
	]
	var widths := [Vector2(.037,.026),Vector2(.03,.023),Vector2(.022,.015),
		Vector2(.024,.016),Vector2(.035,.018),Vector2(.040,.015),Vector2(.038,.012),Vector2(.034,.007)]
	for i in range(palm.size()-1):
		_contour(surface,palm[i],palm[i+1],widths[i],widths[i+1])
	# Fingers part a little and curl toward the palm at the last joint.
	for digit in [Vector3(-.027,.070,-.009), Vector3(-.008,.083,-.002),
			Vector3(.012,.075,.005), Vector3(.030,.056,.012)]:
		var wrist := Vector3(digit.x,.061,-.002)
		_finger(surface,wrist,Vector3(digit.z,digit.y,-.012),.009 if digit.x < .025 else .007)
	_finger(surface,Vector3(-.026,.003,.002),Vector3(-.036,.047,.015),.011)
	var mat := StandardMaterial3D.new()
	mat.albedo_color = dye.lightened(.12)
	mat.roughness = 0.84
	mat.emission_enabled = true
	mat.emission = dye
	mat.emission_energy_multiplier = .21
	surface.set_material(mat)
	mesh = surface.commit()
	cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF

func _finger(surface: SurfaceTool, start: Vector3, reach: Vector3, radius: float) -> void:
	var previous := start
	var previous_radius := Vector2(radius,radius*.8)
	for fraction: float in [.37,.68,.90,1.0]:
		var center := start + reach * fraction
		center.z += .014 * fraction * fraction
		var r := radius * (1.0-.28*fraction)
		var next_radius := Vector2(r,r*.79)
		if fraction == 1.0:
			next_radius *= .14
		_contour(surface,previous,center,previous_radius,next_radius)
		previous = center
		previous_radius = next_radius

func _contour(surface: SurfaceTool, start: Vector3, end: Vector3, base: Vector2, tip: Vector2) -> void:
	const SIDES := 10
	var direction := (end-start).normalized()
	var right := direction.cross(Vector3.BACK).normalized()
	var forward := right.cross(direction).normalized()
	for i in SIDES:
		var a := i*TAU/SIDES
		var b := (i+1)*TAU/SIDES
		for corner in [0,1,2,0,2,3]:
			var high: bool = corner >= 2
			var angle := b if corner == 1 or corner == 2 else a
			var radius := tip if high else base
			var center := end if high else start
			var normal := (right*cos(angle)/radius.x + forward*sin(angle)/radius.y).normalized()
			surface.set_normal(normal)
			surface.add_vertex(center+right*cos(angle)*radius.x+forward*sin(angle)*radius.y)
