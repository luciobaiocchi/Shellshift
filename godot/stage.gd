extends Node3D
## The same cast, materials and model proportions are used on every set.
const INK := Color("#243440")
const TEAL := Color("#427c7c")
const WOOD := Color("#ad6b49")
const SUN := Color("#edb95f")
const SKIN := Color("#cd9474")
const PAPER := Color("#ddd4af")
const BLUE := Color("#425971")

var opening: Node3D
var key := DirectionalLight3D.new()
var camera := Camera3D.new()
var set_root := Node3D.new()
var actors: Array[Dictionary] = []
var moving_props: Array[Node3D] = []
var materials := {}
var scene_index := -1
var eye := Vector3.ZERO
var target := Vector3.ZERO

func _ready() -> void:
	add_child(set_root)
	add_child(camera)
	camera.fov = 42
	camera.current = true
	var environment := Environment.new()
	environment.background_mode = Environment.BG_COLOR
	environment.background_color = BLUE
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.ambient_light_color = Color("#c3cfd6")
	environment.ambient_light_energy = 0.7
	camera.environment = environment
	add_child(key)
	key.rotation_degrees = Vector3(-52, -30, 0)
	key.light_energy = 1.08
	key.shadow_enabled = true

func joint(parent: Node3D, pos: Vector3) -> Node3D:
	var node := Node3D.new()
	parent.add_child(node)
	node.position = pos
	return node

func block(parent: Node3D, pos: Vector3, dims: Vector3, color: Color) -> MeshInstance3D:
	var mesh := BoxMesh.new()
	mesh.size = dims
	return model(parent,pos,mesh,color)

func model(parent: Node3D, pos: Vector3, mesh: PrimitiveMesh, color: Color) -> MeshInstance3D:
	if not materials.has(color):
		var material := StandardMaterial3D.new()
		material.albedo_color = color
		material.roughness = 0.92
		materials[color] = material
	var node := MeshInstance3D.new()
	node.mesh = mesh
	node.material_override = materials[color]
	parent.add_child(node)
	node.position = pos
	return node

func round_part(parent: Node3D, pos: Vector3, dims: Vector3, color: Color) -> Node3D:
	var mesh := SphereMesh.new()
	mesh.radial_segments = 8
	mesh.rings = 4
	var node := model(parent,pos,mesh,color)
	node.scale = dims
	return node

func person(pos: Vector3, coat: Color, hair: Color, pose: String, yaw: float = 0) -> Node3D:
	var body := joint(set_root,pos)
	body.rotation.y = yaw
	var spine := joint(body,Vector3(0,0.91,0))
	round_part(spine,Vector3(0,.34,0),Vector3(.71,.94,.44),coat)
	var head := joint(spine,Vector3(0,.87,0))
	round_part(head,Vector3.ZERO,Vector3(.44,.56,.44),SKIN)
	round_part(head,Vector3(0,.14,-.045),Vector3(.47,.37,.46),hair)
	if coat == WOOD:
		round_part(head,Vector3(0,-.025,-.13),Vector3(.47,.48,.28),hair)
		block(spine,Vector3(-.15,.46,.20),Vector3(.13,.38,.06),SUN)
	block(head,Vector3(0,-.015,.215),Vector3(.085,.10,.085),SKIN)
	for side in [-1,1]:
		block(head,Vector3(.095*side,.055,.192),Vector3(.045,.025,.03),INK)
	block(spine,Vector3(0,.65,.02),Vector3(.43,.12,.42),SUN if coat == WOOD else coat.lightened(.2))
	var arms: Array[Node3D] = []
	var legs: Array[Node3D] = []
	var knees: Array[Node3D] = []
	for side in [-1,1]:
		var shoulder := joint(spine,Vector3(side*.31,.57,0))
		arms.append(shoulder)
		round_part(shoulder,Vector3(0,-.19,0),Vector3(.22,.48,.23),coat)
		var elbow := joint(shoulder,Vector3(0,-.36,0))
		elbow.rotation.x = -.36
		round_part(elbow,Vector3(0,-.14,0),Vector3(.18,.35,.18),coat)
		round_part(elbow,Vector3(0,-.32,0),Vector3(.15,.18,.17),SKIN)
		var hip := joint(body,Vector3(side*.155,.93,0))
		legs.append(hip)
		block(hip,Vector3(0,-.22,0),Vector3(.23,.45,.26),BLUE)
		var knee := joint(hip,Vector3(0,-.43,0))
		knees.append(knee)
		block(knee,Vector3(0,-.2,0),Vector3(.19,.41,.22),BLUE)
		block(knee,Vector3(0,-.42,.065),Vector3(.21,.14,.38),INK)
	actors.append({"body":body,"head":head,"spine":spine,"arms":arms,"legs":legs,"knees":knees,"pose":pose,"start":pos})
	return body

func desk(x: float, z: float) -> void:
	block(set_root,Vector3(x,.87,z),Vector3(2.5,.12,1.15),WOOD)
	for dx in [-1,1]:
		block(set_root,Vector3(x+dx,.43,z),Vector3(.09,.86,.87),INK)
	block(set_root,Vector3(x,1.36,z),Vector3(1.05,.8,.47),PAPER)
	block(set_root,Vector3(x,1.37,z+.245),Vector3(.88,.62,.035),TEAL)
	for i in range(4):
		block(set_root,Vector3(x-.13,1.53-i*.105,z+.268),Vector3(.47-i*.065,.025,.012),PAPER)
	block(set_root,Vector3(x,.97,z+.35),Vector3(.78,.05,.31),INK)

func book(pos: Vector3) -> Node3D:
	var notebook := joint(set_root,pos)
	block(notebook,Vector3.ZERO,Vector3(.38,.065,.52),PAPER)
	for y in [-.041,.041]:
		block(notebook,Vector3(0,y,0),Vector3(.4,.016,.54),Color("#8d433b"))
	return notebook

func frame(index: int, t: float) -> void:
	if index != scene_index:
		build_set(index)
	if index == 0:
		opening.frame(t)
		return
	for i in actors.size():
		var a := actors[i]
		var phase := t*4.2+i*.83
		a.head.rotation.y = .16*sin(t*.9+i)
		a.spine.rotation.z = .018*sin(t*1.4+i)
		match a.pose:
			"walk":
				# Walk a straight aisle, with ankle height carried by hip and knee.
				a.body.position = a.start + Vector3(t*.48,.037*abs(sin(phase)),0)
				for j in 2:
					var swing := sin(phase + PI*j)
					a.legs[j].rotation.x = .46*swing
					a.knees[j].rotation.x = .44*maxf(0,-swing)
					a.arms[j].rotation.x = -.38*swing
			"type":
				for j in 2:
					a.arms[j].rotation.x = -1.0 + .12*sin(t*6+j*2)
				a.head.rotation.x = .19 + .10*sin(t*1.2)
			"embrace":
				for j in 2:
					a.arms[j].rotation.x = -1.25 * smoothstep(.3,2.8,t)
					a.arms[j].rotation.z = (.22 if j == 0 else -.22)
				a.body.position = a.start + a.body.transform.basis.z * .28*smoothstep(0,2.4,t)
			"point":
				a.arms[1].rotation.x = -.25 - 1.6*smoothstep(1,3,t)
				a.head.rotation.x = -.18
	for prop in moving_props:
		if index == 8:
			var fall := smoothstep(5.2,6,t)
			prop.position.y = lerpf(1.23,.09,fall)
			prop.rotation.z = fall*.17
		elif index in [1,5]:
			prop.rotation.y = .45*sin(t*.32)
		elif index == 6:
			prop.position.x = fmod(t*2.5,22)-11
	camera.position = eye + Vector3(.38*sin(t*.12),.08*sin(t*.2),-.055*t)
	camera.look_at(target)

func build_set(index: int) -> void:
	for child in set_root.get_children():
		set_root.remove_child(child)
		child.queue_free()
	actors.clear()
	moving_props.clear()
	scene_index = index
	var warm := index < 5
	var decline := clampf((index-4)/4.0,0,1)
	key.light_energy = lerpf(.84,.42,decline)
	key.light_color = Color("#fff0db").lerp(Color("#bac5e3"),decline)
	camera.environment.fog_enabled = index >= 5
	camera.environment.fog_density = lerpf(.004,.049,decline)
	camera.environment.fog_light_color = Color("#716981")
	camera.environment.ambient_light_energy = lerpf(.7,.40,decline)
	camera.environment.background_color = Color("#eacda3") if warm else BLUE.darkened(.5)
	block(set_root,Vector3(0,-.16,0),Vector3(45,.3,40),Color("#ac9170") if warm else BLUE)
	eye = Vector3(4,2.6,5)
	target = Vector3(0,1,0)
	match index:
		0:
			opening = preload("res://programmers.gd").new()
			set_root.add_child(opening)
			opening.build(self)
		4,9:
			block(set_root,Vector3(0,2.6,-17),Vector3(22,5.2,.3),TEAL)
			for bay in range(-3,4):
				block(set_root,Vector3(bay*2.9,2.6,-16.8),Vector3(2.5,2.7,.09),PAPER if warm else BLUE)
				block(set_root,Vector3(bay*2.9,2.6,-16.72),Vector3(.08,2.7,.1),INK)
			for row in range(3 if index != 9 else 6):
				for col in range(-2,3):
					desk(col*3.1,-row*2.8)
			person(Vector3(-.65,0,.8),WOOD,INK,"type",PI)
			person(Vector3(.95,0,.65),TEAL,WOOD,"point",-.8)
			book(Vector3(-.8,1,.25))
			if index == 4:
				eye = Vector3(6,5,7)
			if index == 9:
				var terminal := joint(set_root,Vector3(0,1.38,.19))
				block(terminal,Vector3.ZERO,Vector3(1.12,.79,.20),INK)
				block(terminal,Vector3(0,0,.112),Vector3(.94,.61,.04),Color("#372a26"))
				var assignment := Label3D.new()
				terminal.add_child(assignment)
				assignment.position = Vector3(0,0,.14)
				assignment.pixel_size = .00135
				assignment.font_size = 46
				assignment.outline_size = 0
				assignment.modulate = Color("#ffc675")
				assignment.text = "H-0317  /  TURNO 01\n\n3 DIAPOSITIVE\nTEMPO   07:00"
				eye = Vector3(.09,1.65,2.46)
				target = Vector3(0,1.37,0)
		1,5:
			for i in range(14):
				var peak := CylinderMesh.new()
				peak.top_radius = 0
				peak.bottom_radius = 5
				peak.height = 4 + i%4
				peak.radial_segments = 5
				model(set_root,Vector3(-21+i*3,1,-10-i%3),peak,TEAL.darkened(.18))
			var mount := joint(set_root,Vector3(0,0,0))
			block(mount,Vector3(0,.7,0),Vector3(.24,1.4,.24),INK)
			var tube := block(mount,Vector3(0,1.65,0),Vector3(.46,.48,2.5),PAPER)
			tube.rotation.x = -.46
			moving_props.append(mount)
			if index == 1:
				person(Vector3(-.85,0,.42),WOOD,INK,"point",.6)
			else:
				desk(-2,0)
			eye = Vector3(3,2.1,4.8)
		2,3:
			for i in range(8):
				var pos := Vector3(-8+i*2.3,0,-3-i%3)
				block(set_root,pos+Vector3.UP,Vector3(.3,2,.33),WOOD)
				round_part(set_root,pos+Vector3.UP*2.7,Vector3(2.2,2.6,2.1),TEAL)
			if index == 2:
				block(set_root,Vector3(0,2,-1.4),Vector3(6,3.6,.25),INK)
				block(set_root,Vector3(0,2,-1.2),Vector3(5.7,3.3,.15),TEAL)
				block(set_root,Vector3(0,2,-1),Vector3(.38,1.7,.15),PAPER)
				block(set_root,Vector3(0,2,-.99),Vector3(1.7,.38,.15),PAPER)
				for i in range(6):
					person(Vector3(i*.94-2.4,0,1+i%2),[TEAL,WOOD,BLUE][i%3],INK,"point",PI)
			else:
				person(Vector3(-.58,0,0),WOOD,INK,"embrace",PI/2)
				person(Vector3(.58,0,0),TEAL,PAPER,"embrace",-PI/2)
				eye = Vector3(1,1.8,4)
				target = Vector3(0,1.45,0)
		6:
			for i in range(24):
				var h := 2.0 + (i*7)%9
				var pos := Vector3((i%8-3.5)*2.4,h/2,-floori(i/8.0)*3.1)
				block(set_root,pos,Vector3(1.6,h,1.6),BLUE)
				for floor_index in range(1,int(h)):
					block(set_root,Vector3(pos.x,floor_index,pos.z+.81),Vector3(1.24,.08,.02),SUN)
			var train := block(set_root,Vector3(-11,.65,2.8),Vector3(4.6,1,1.1),TEAL)
			block(train,Vector3(0,.15,.56),Vector3(4,.32,.03),PAPER)
			moving_props.append(train)
			eye = Vector3(8,7,13)
			target = Vector3(0,3,0)
		7,8:
			block(set_root,Vector3(0,2.8,-4),Vector3(24,5.6,.3),BLUE.darkened(.5))
			for bay in range(-3,4):
				block(set_root,Vector3(bay*3,2,-3.77),Vector3(2.25,3.75,.18),TEAL.darkened(.62))
				block(set_root,Vector3(bay*3,4.05,-3.67),Vector3(1.15,.10,.16),SUN)
			for lane in range(-2,3):
				block(set_root,Vector3(0,.005,lane*1.35),Vector3(24,.014,.045),TEAL)
			for i in range(-3,4):
				block(set_root,Vector3(i*3,2.6,-2),Vector3(.36,5.2,.5),WOOD)
				block(set_root,Vector3(i*3,4.9,-2),Vector3(3.1,.28,.6),INK)
			for x in [1.8,3.35]:
				block(set_root,Vector3(x,1.3,0),Vector3(.2,2.6,.26),TEAL)
			block(set_root,Vector3(2.57,2.6,0),Vector3(1.8,.14,.27),SUN)
			# The public gallery hangs above the people waiting for transfer.
			block(set_root,Vector3(0,2.75,-1.94),Vector3(22,.22,1.38),INK)
			for rail_y in [3.18,3.52]:
				block(set_root,Vector3(0,rail_y,-1.29),Vector3(22,.045,.045),BLUE)
			for post in range(-8,9):
				block(set_root,Vector3(post*1.28,3.16,-1.29),Vector3(.042,.81,.042),INK)
			for walker in range(3):
				person(Vector3(-5+walker*2.7,2.86,-1.94),BLUE.darkened(.36),INK,"walk",PI/2)
			if index == 7:
				for i in range(9):
					person(Vector3(1.7-i*1.32,0,.2*sin(i)),[BLUE,WOOD,TEAL][i%3],PAPER if i%3 == 0 else INK,"walk",PI/2)
				eye = Vector3(4.6,1.02,7.4)
				target = Vector3(.6,1.96,-1)
			else:
				person(Vector3(0,0,0),WOOD,PAPER,"point",.6)
				moving_props.append(book(Vector3(.58,1.23,.24)))
				var arm := block(set_root,Vector3(1.6,1.5,-.2),Vector3(.27,1.4,.32),INK)
				block(arm,Vector3(-.36,.62,.14),Vector3(.92,.37,.45),TEAL)
				eye = Vector3(2,1.55,2.8)
				target = Vector3(.45,1.36,0)
