extends Node3D
## The same cast, materials and model proportions are used on every set.
const INK := Color("#243440")
const TEAL := Color("#427c7c")
const WOOD := Color("#ad6b49")
const SUN := Color("#edb95f")
const SKIN := Color("#cd9474")
const PAPER := Color("#ddd4af")
const BLUE := Color("#425971")
const STONE_FLOOR := preload("res://art_direction/stone_floor.tres")
const MASONRY := preload("res://art_direction/masonry.tres")
const STEEL := preload("res://art_direction/steel.tres")

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

const MARKS := preload("res://casting/archive_marks.tscn")
const ARCHIVE_ACTOR := preload("res://casting/archive_actor.gd")
const ARCHIVE_AGE := preload("res://casting/archive_age.gd")
const LEADS := ["ada","nico","lea"]
const AUDIENCE := ["extra_a","clerk","jo","extra_b","ivo","rosa"]
const GALLERY := ["extra_c","extra_a"]
const QUEUE := ["extra_d","nico","lea","extra_e","ada"]
var cast_scenes := {}

func person(pos: Vector3, identity: String, pose: String, yaw: float) -> Node3D:
	var body := MARKS.instantiate() as Node3D
	body.name = identity.to_pascal_case()
	set_root.add_child(body,true)
	body.position = pos
	body.rotation.y = yaw
	if not cast_scenes.has(identity):
		cast_scenes[identity] = load("res://casting/%s.glb" % identity)
	var model := (cast_scenes[identity] as PackedScene).instantiate() as Node3D
	var player := ARCHIVE_ACTOR.new()
	body.add_child(player)
	player.bind(body,model,pose)
	var face := model.find_child("ActorMesh",true,false) as MeshInstance3D
	if scene_index in [7,8,9,12]:
		ARCHIVE_AGE.apply(face,identity)
	var face_parts: Array[MeshInstance3D] = [face]
	var spine: Node3D = body.get_node("Spine")
	var arms := [spine.get_node("ShoulderL"),spine.get_node("ShoulderR")]
	var legs := [body.get_node("HipL"),body.get_node("HipR")]
	var knees := [legs[0].get_node("Knee"),legs[1].get_node("Knee")]
	actors.append({"body":body,"spine":spine,"head":spine.get_node("Head"),"arms":arms,
		"legs":legs,"knees":knees,"lids":face_parts,"lips":face_parts,
		"driver":player,"identity":identity,"pose":pose,"start":pos})
	if identity == "ada" and scene_index in [1,5,8]:
		var attachment := player.socket("Neck") as Node3D
		var scarf := preload("res://casting/scarf.gd").new()
		attachment.add_child(scarf)
		scarf.basis = player.socket_axes("Neck")
		scarf.position = scarf.basis * Vector3(0,.01,.002)
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

const SCREENPLAY := preload("res://screenplay.gd")
var profile := 0
var built_profile := -1
var archive_art: Node3D

func lead(pos: Vector3, pose: String, yaw: float, role: int) -> Node3D:
	return person(pos,LEADS[role],pose,yaw)

func frame(index: int, t: float) -> void:
	if index != scene_index or profile != built_profile:
		build_set(index)
	if index in [0,3]:
		opening.frame(t)
		return
	for i in actors.size():
		var a := actors[i]
		var phase := t*4.2+i*.83
		var eyelid := fposmod(t+i*1.17,3.9 + .27*(i%3))
		var blink := smoothstep(1.82,1.9,eyelid)*(1.0-smoothstep(1.9,2.025,eyelid))
		for lid: MeshInstance3D in a.lids:
			lid.set_blend_shape_value(lid.find_blend_shape_by_name("Blink"),blink)
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
			prop.position.x = lerpf(-10.5,10.5,clampf(t/14.0,0,1))
	camera.position = eye + Vector3(.38*sin(t*.12),.08*sin(t*.2),-.055*t)
	camera.look_at(target)
	archive_art.frame(t)
	for actor in actors:
		if actor.body.is_visible_in_tree():
			actor.driver.pose(t)

func clear_set() -> void:
	for child in set_root.get_children():
		set_root.remove_child(child)
		child.queue_free()
	actors.clear()
	moving_props.clear()
	opening = null
	archive_art = null
	scene_index = -1

func end_film() -> void:
	clear_set()
	cast_scenes.clear()

func build_set(index: int) -> void:
	clear_set()
	scene_index = index
	built_profile = profile
	var civic := index in [10,11,12]
	var warm := index < 5 or index in [10,11]
	var decline := 0.0 if warm else clampf((index-4)/4.0,0,1)
	if index == 12:
		decline = .72
	camera.fov = 42
	key.rotation_degrees = Vector3(-52,-30,0)
	camera.environment.ambient_light_color = Color("#c3cfd6")
	key.light_energy = lerpf(.84,.42,decline)
	key.light_color = Color("#fff0db").lerp(Color("#bac5e3"),decline)
	camera.environment.fog_enabled = not warm
	camera.environment.fog_density = lerpf(.004,.049,decline)
	camera.environment.fog_light_color = Color("#716981")
	camera.environment.ambient_light_energy = lerpf(.7,.40,decline)
	camera.environment.background_color = Color("#eacda3") if warm else BLUE.darkened(.5)
	key.visible = index not in [0,3]
	if index == 3:
		# Play the same ward performance as the standalone screen test. The film owns the clock and score.
		opening = load("res://casting/hospital.tscn").instantiate()
		set_root.add_child(opening)
		opening.set_process(false)
		return
	if index != 0:
		camera.current = true
		var ground := Color("#ac9170") if warm else BLUE
		if index in [1,5]:
			ground = Color("#545e65")
		var floor_slab := block(set_root,Vector3(0,-.16,0),Vector3(45,.3,40),ground)
		if index in [2,7,8,9]:
			floor_slab.material_override = STONE_FLOOR
	eye = Vector3(4,2.6,5)
	target = Vector3(0,1,0)
	if civic:
		if index == 10:
			archive_art = preload("res://civic_counter.gd").new()
			set_root.add_child(archive_art)
			archive_art.build(self)
		else:
			archive_art = preload("res://civic_return.gd").new()
			set_root.add_child(archive_art)
			archive_art.build(self,index == 12)
		return
	match index:
		0:
			opening = preload("res://office/venerdi.tscn").instantiate()
			set_root.add_child(opening)
		4:
			# The laboratory places these two performers in the review bay.
			lead(Vector3.ZERO,"type",PI,0)
			lead(Vector3.ZERO,"point",0,2)
		9:
			block(set_root,Vector3(0,2.6,-17),Vector3(22,5.2,.3),TEAL)
			for bay in range(-3,4):
				block(set_root,Vector3(bay*2.9,2.6,-16.8),Vector3(2.5,2.7,.09),PAPER if warm else BLUE)
				block(set_root,Vector3(bay*2.9,2.6,-16.72),Vector3(.08,2.7,.1),INK)
			for row in range(6):
				for col in range(-2,3):
					desk(col*3.1,-row*2.8)
			lead(Vector3(-.65,0,.8),"type",PI,profile)
			var supervisor := joint(set_root,Vector3(.68,1.59,.17))
			supervisor.rotation.y = -.62
			block(supervisor,Vector3(0,-.20,-.05),Vector3(.064,.45,.075),INK)
			block(supervisor,Vector3.ZERO,Vector3(.27,.16,.22),BLUE)
			round_part(supervisor,Vector3(0,.012,.12),Vector3(.097,.095,.065),INK)
			block(supervisor,Vector3(.099,.041,.119),Vector3(.023,.023,.011),SUN)
			book(Vector3(-.8,1,.25))
			var terminal := joint(set_root,Vector3(0,1.38,.19))
			block(terminal,Vector3.ZERO,Vector3(1.12,.79,.20),INK)
			block(terminal,Vector3(0,0,.112),Vector3(.94,.61,.04),Color("#372a26"))
			var assignment := Label3D.new()
			terminal.add_child(assignment)
			assignment.position = Vector3(.116,0,.14)
			assignment.pixel_size = .00118
			assignment.font_size = 46
			assignment.outline_size = 0
			assignment.modulate = Color("#ffc675")
			assignment.text = SCREENPLAY.BADGES[profile]+"  /  SHIFT 01\n\n"+SCREENPLAY.ORDERS[profile]+"\nTIME   07:00"
			# One archive still becomes Ada's personal photo inside the terminal.
			if profile == 0:
				var photo := Sprite3D.new()
				terminal.add_child(photo)
				photo.texture = preload("res://archive.png")
				photo.region_enabled = true
				photo.region_rect = Rect2(4,5,269,245)
				photo.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
				photo.pixel_size = .001
				photo.position = Vector3(-.31,.012,.149)
				block(terminal,Vector3(-.31,.012,.14),Vector3(.287,.264,.01),PAPER)
			else:
				block(terminal,Vector3(-.30,.012,.14),Vector3(.26,.23,.015),BLUE)
				for i in range(3):
					var x := -.38+.079*i
					block(terminal,Vector3(x,.03+.025*(i%2),.157),Vector3(.045,.044,.006),SUN if profile==1 else PAPER)
					if i<2:
						block(terminal,Vector3(x+.041,.03,.157),Vector3(.05,.009,.006),PAPER)
			eye = Vector3(.09,1.65,2.46)
			target = Vector3(0,1.37,0)
		1,5:
			if profile != 0:
				lead(Vector3(-.40,0,.27),"watch",.62,profile)
			else:
				for i in range(14):
					var peak := CylinderMesh.new()
					peak.top_radius = 0
					peak.bottom_radius = 5.6 + .8*sin(i*2.3)
					peak.height = 3.6 + 1.5*sin(i*1.7)
					peak.radial_segments = 5
					var mountain := model(set_root,Vector3(-21+i*3,.9,-10-i%3),peak,Color("#536878").darkened(.07*(i%3)))
					mountain.rotation.y = i*.71
				lead(Vector3(-.85,0,.42),"watch",.6,0)
				eye = Vector3(3,2.1,4.8)
		2:
			for i in range(8):
				var pos := Vector3(-8+i*2.3,0,-3-i%3)
				block(set_root,pos+Vector3.UP,Vector3(.3,2,.33),WOOD)
				round_part(set_root,pos+Vector3.UP*2.7,Vector3(2.2,2.6,2.1),TEAL)
			for i in AUDIENCE.size():
				person(Vector3(i*.94-2.4,0,1+i%2),AUDIENCE[i],"point",PI)
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
			block(set_root,Vector3(0,2.8,-4),Vector3(24,5.6,.3),BLUE.darkened(.5)).material_override = MASONRY
			for bay in range(-3,4):
				block(set_root,Vector3(bay*3,2,-3.77),Vector3(2.25,3.75,.18),TEAL.darkened(.62)).material_override = STEEL
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
			for walker in GALLERY.size():
				person(Vector3(-5+walker*4.2,2.86,-1.94),GALLERY[walker],"walk",PI/2)
			if index == 7:
				for i in QUEUE.size():
					person(Vector3(1.7-i*1.32,0,.2*sin(i)),QUEUE[i],"walk",PI/2)
				eye = Vector3(4.6,1.02,7.4)
				target = Vector3(.6,1.96,-1)
			else:
				lead(Vector3(0,0,0),"point",.6,profile)
				var keepsake := book(Vector3(.58,1.23,.24)) if profile==0 else joint(set_root,Vector3(.58,1.23,.24))
				if profile == 0:
					keepsake.scale = Vector3.ONE*.70
					block(keepsake,Vector3(.136,.052,0),Vector3(.018,.006,.535),INK)
					block(keepsake,Vector3(-.07,.052,.13),Vector3(.135,.005,.071),PAPER)
				if profile==1:
					block(keepsake,Vector3.ZERO,Vector3(.39,.04,.24),TEAL)
					for i in 3:
						block(keepsake,Vector3(-.12+i*.11,.036,0),Vector3(.047,.045,.075),SUN)
				if profile==2:
					block(keepsake,Vector3.ZERO,Vector3(.23,.075,.13),WOOD)
					round_part(keepsake,Vector3(0,.09,0),Vector3(.068,.14,.068),INK)
				moving_props.append(keepsake)
				var arm := block(set_root,Vector3(1.6,1.5,-.2),Vector3(.27,1.4,.32),INK)
				block(arm,Vector3(-.36,.62,.14),Vector3(.92,.37,.45),TEAL)
				eye = Vector3(2,1.55,2.8)
				target = Vector3(.45,1.36,0)

	if index != 0:
		archive_art = preload("res://prologue_art.gd").new()
		set_root.add_child(archive_art)
		archive_art.build(self,index)
