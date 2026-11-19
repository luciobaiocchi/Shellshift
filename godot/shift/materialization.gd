extends Node3D
## A projected body is registered as separate axial samples, rebuilt from heel
## to crown. Deterministic displacement keeps the readout calm when revisited.
const PROJECTION := preload("res://shift/materialization.gdshader")
const FirstPersonHand := preload("res://shift/body_hand.gd")
const BADGES := ["H-0317   ADA", "H-0442   NICO", "H-0528   LEA"]
const DYES := [Color("#79bea8"),Color("#82b3c6"),Color("#c6aa83")]
const SLICES := 40

@export_range(0,2) var selected_profile: int = 0:
	set(value):
		selected_profile = clampi(value,0,2)
		if is_node_ready():
			_load_identity()

@onready var body: MeshInstance3D = $NeuralImage
@onready var ready_caption: Label3D = $RegistryStatus
var projection_material := ShaderMaterial.new()
var elapsed := 0.0
var hand := FirstPersonHand.new()

func _ready() -> void:
	projection_material.shader = PROJECTION
	body.material_override = projection_material
	add_child(hand)
	hand.top_level = true
	hand.hide()
	engrave_scale()
	_load_identity()

func _load_identity() -> void:
	$Badge.text = BADGES[selected_profile]
	projection_material.set_shader_parameter("dye", DYES[selected_profile])
	body.mesh = _build_body()
	hand.build(DYES[selected_profile])
	hand.hide()
	projection_material.set_shader_parameter("assembly",0.0)
	ready_caption.text = "REGISTERING   /   00"
	elapsed = 0
	set_process(true)

func _process(delta: float) -> void:
	elapsed += delta
	var amount := minf(elapsed / 2.9,1.0)
	projection_material.set_shader_parameter("assembly",amount)
	# The worker checks their own hand. The corresponding arm in the glass follows.
	var lift := smoothstep(1.6,3.1,elapsed) * (1.0-smoothstep(4.15,5.25,elapsed))
	projection_material.set_shader_parameter("arm_lift",lift)
	var camera := get_viewport().get_camera_3d()
	if camera and lift > .001:
		hand.show()
		var wrist := Vector3(.092,lerpf(-.46,-.142,lift),-.46)
		var angle := Vector3(-.12,.30+.32*lift,-.12+.18*lift)
		hand.global_transform = camera.global_transform * Transform3D(Basis.from_euler(angle),wrist)
	else:
		hand.hide()
	ready_caption.text = "REGISTERING   /   %02d" % floori(amount*SLICES)
	if elapsed >= 2.9:
		ready_caption.text = "LOCAL BODY   /   ONLINE"
	if elapsed >= 5.25:
		set_process(false)

# Each Vector3 entry is height, half-width, half-depth. Samples between
# landmarks describe the body's contour without rectangular limb joints.
func _section(height: float, keys: Array) -> Vector2:
	for i in range(1,keys.size()):
		var a: Vector3 = keys[i-1]
		var b: Vector3 = keys[i]
		if height <= b.x:
			var t := clampf(inverse_lerp(a.x,b.x,height),0,1)
			return Vector2(a.y,a.z).lerp(Vector2(b.y,b.z),t)
	return Vector2.ZERO

func _build_body() -> ArrayMesh:
	var builder := SurfaceTool.new()
	builder.begin(Mesh.PRIMITIVE_TRIANGLES)
	var shoulder := [0.202,0.235,0.214][selected_profile] as float
	var skull := [0.119,0.112,0.116][selected_profile] as float
	var anatomy := [Vector3(.55,.094,.060),Vector3(.65,.157,.086),Vector3(.77,.141,.087),
		Vector3(.89,.153,.100),Vector3(1.04,shoulder,.098),Vector3(1.11,.147,.081),
		Vector3(1.145,.052,.052),Vector3(1.188,.054,.054),Vector3(1.21,.073,.075),
		Vector3(1.25,skull*.84,.093),Vector3(1.31,skull,.103),Vector3(1.38,skull*.97,.100),
		Vector3(1.43,skull*.73,.077),Vector3(1.46,.024,.033)]
	for i in SLICES:
		var y := .025+i*.0365
		var band := float(i)/SLICES
		if y >= .56:
			var radius := _section(y,anatomy)
			_band(builder,Vector3(0,y,0),radius,band)
		if y < .65:
			for side in [-1,1]:
				var leg := _section(y,[Vector3(0,.062,.106),Vector3(.075,.043,.055),Vector3(.26,.056,.064),Vector3(.38,.060,.063),Vector3(.59,.079,.084),Vector3(.65,.080,.085)])
				_band(builder,Vector3(side*.081,y,.028 if y < .06 else 0.0),leg,band)
		if y >= .53 and y <= 1.08:
			for side in [-1,1]:
				var arm := _section(y,[Vector3(.52,.026,.033),Vector3(.61,.038,.042),Vector3(.68,.027,.033),Vector3(.79,.041,.046),Vector3(.87,.044,.044),Vector3(1.03,.060,.062),Vector3(1.081,.035,.050)])
				var reach := (1.08-y)*.16
				_band(builder,Vector3(side*(shoulder-.027+reach),y,.045*sin((1.08-y)*4.)),arm,band,side == 1)
	return builder.commit()

func _band(builder: SurfaceTool, center: Vector3, radius: Vector2, layer: float, raised_arm := false) -> void:
	if radius.x <= 0.0:
		return
	const SIDES := 12
	for i in SIDES:
		var a := TAU*i/SIDES
		var b := TAU*(i+1)/SIDES
		var pa := Vector3(cos(a)*radius.x,0,sin(a)*radius.y)
		var pb := Vector3(cos(b)*radius.x,0,sin(b)*radius.y)
		var normal := (pa+pb).normalized()
		for corner in [0,2,1,0,3,2]:
			var high: bool = corner == 2 or corner == 3
			var rim := pa if corner == 0 or corner == 3 else pb
			builder.set_normal(normal)
			builder.set_color(Color(1.0 if raised_arm else 0.0,0,0))
			builder.set_uv(Vector2(layer,1.0 if high else 0.0))
			builder.add_vertex(center+rim+Vector3.UP*(.030 if high else 0.0))


func engrave_scale() -> void:
	var lines := ImmediateMesh.new()
	var ink := StandardMaterial3D.new()
	ink.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	ink.albedo_color = Color("#425657")
	lines.surface_begin(Mesh.PRIMITIVE_LINES, ink)
	for tick in range(31):
		var y := .30 + tick*.0475
		var length := .056 if tick%5 == 0 else .026
		for side in [-1.0,1.0]:
			lines.surface_add_vertex(Vector3(side*.49,y,.025))
			lines.surface_add_vertex(Vector3(side*(.49-length),y,.025))
	lines.surface_end()
	var gauge := MeshInstance3D.new()
	gauge.mesh = lines
	add_child(gauge)
