extends Node3D
## Standalone casting cut of the discharge (01:21–01:36 in the archive).

const SCORE := preload("res://shift-score.mp3")
const DURATION := 15.0
const FRAME_COLOR := Color("#e5ddc4")
const ENAMEL := Color("#49686a")
const BRASS := Color("#a78a64")

var stage := preload("res://stage.gd").new()
var architecture := preload("res://prologue_art.gd").new()
var film := ShaderMaterial.new()
var elapsed := 0.0
var music := AudioStreamPlayer.new()

func _ready() -> void:
	add_child(stage)
	stage.set_root.add_child(architecture)
	architecture.stage = stage
	stage.materials[Color("#969d8f")] = _paint(Color("#a39985"),true)
	stage.materials[architecture.COPPER] = _paint(Color("#825b43"),false)
	stage.materials[architecture.MINT] = _paint(Color("#697c73"),false)
	var glazing := ShaderMaterial.new()
	glazing.shader = preload("res://casting/ward_glass.gdshader")
	architecture.hospital_exterior(glazing)
	for label: Label3D in architecture.find_children("*","Label3D",true,false):
		label.alpha_cut = Label3D.ALPHA_CUT_DISCARD
	stage.block(stage.set_root,Vector3(0,-.155,0),Vector3(30,.3,30),ENAMEL).material_override = stage.STONE_FLOOR
	_dress_exterior()
	var garden := preload("res://casting/ward_garden.gd").new()
	add_child(garden)
	garden.build(stage)
	_light_scene()
	_fit_lens()
	$Performance.build($Ada,$Mara,$OchreScarf)
	_make_ticket($Performance.ticket_socket)
	add_child(music)
	music.stream = SCORE
	music.volume_db = 7.5
	frame(0)

func _process(delta: float) -> void:
	if elapsed == 0.0:
		music.play(81.0)
	elapsed += delta
	if elapsed >= DURATION:
		elapsed = fmod(elapsed,DURATION)
		music.seek(81.0+elapsed)
	frame(elapsed)

func frame(t: float) -> void:
	$Performance.frame(t)
	var fold := smoothstep(7.35,8.37,t) - .67*smoothstep(8.49,9.42,t)
	$OchreScarf.material_override.set_shader_parameter("tuck",fold)
	var camera := stage.camera
	if t < 5.75:
		# Eye-level two-shot. Keep the hospital exit and the space between them visible.
		var s := smoothstep(0,5.75,t)
		camera.fov = 32.5
		camera.position = Vector3(-.85,1.46,3.46).lerp(Vector3(-.70,1.45,2.98),s)
		camera.look_at(Vector3(0,1.28,-.05))
	elif t < 10.30:
		# Stay on their side of the axis. The cuff, thumb and both eyes share this frame.
		var s := smoothstep(5.75,10.30,t)
		camera.fov = 29.0
		camera.position = Vector3(-.41,1.52,1.79).lerp(Vector3(-.46,1.53,1.63),s)
		camera.look_at(Vector3(0,1.50,.035))
	else:
		# Hold through the embrace; the mother's eyeline can settle in its own time.
		var s := smoothstep(10.30,DURATION,t)
		camera.fov = 30.5
		camera.position = Vector3(.51,1.58,1.56).lerp(Vector3(.67,1.62,1.08),s)
		camera.look_at(Vector3(.012,1.50,.045))
	film.set_shader_parameter("focus",camera.position.distance_to(Vector3(0,1.52,.03)))

func _paint(color: Color, tiled: bool) -> ShaderMaterial:
	var surface := ShaderMaterial.new()
	surface.shader = preload("res://casting/ward_surface.gdshader")
	surface.set_shader_parameter("paint",color)
	surface.set_shader_parameter("tile",tiled)
	return surface

func _fit_lens() -> void:
	var lens := MeshInstance3D.new()
	var quad := QuadMesh.new()
	quad.size = Vector2(2,2)
	lens.mesh = quad
	film.shader = preload("res://casting/film.gdshader")
	film.render_priority = -128
	lens.material_override = film
	lens.extra_cull_margin = 10.0
	lens.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	stage.camera.add_child(lens)
	lens.position.z = -.2

func _light_scene() -> void:
	var env := stage.camera.environment
	env.background_color = Color("#cbc5b0")
	env.ambient_light_color = Color("#e2e4ee")
	env.ambient_light_energy = .51
	stage.key.rotation_degrees = Vector3(-28,-28,0)
	stage.key.light_color = Color("#fff1db")
	stage.key.light_energy = .65
	stage.key.shadow_opacity = .70
	stage.key.directional_shadow_max_distance = 14.0
	var rim := OmniLight3D.new()
	add_child(rim)
	rim.position = Vector3(1.2,2.24,-.72)
	rim.light_color = Color("#ffd79e")
	rim.light_energy = .30
	rim.light_specular = .3
	rim.omni_range = 3.2
	stage.camera.near = .06
	for light: OmniLight3D in architecture.find_children("*","OmniLight3D",true,false):
		light.light_energy = .06

func _dress_exterior() -> void:
	# Sliding door tracks, kick plates, dark weather gaskets and ribbed safety glass.
	var set_root := stage.set_root
	for x in [-.59,.59]:
		stage.block(set_root,Vector3(x,.205,-1.649),Vector3(1.09,.27,.018),Color("#677773"))
		stage.block(set_root,Vector3(x,.991,-1.626),Vector3(.91,.011,.017),BRASS)
		for y in [1.29,1.314,1.338]:
			stage.block(set_root,Vector3(x,y,-1.625),Vector3(.80,.007,.008),Color("#90a29b"))
	for x in [-1.20,0,1.20]:
		stage.block(set_root,Vector3(x,1.04,-1.65),Vector3(.024,2.05,.03),Color("#354945"))
	# Reinforced corners, stitched straps and brass catches on Mara's return case.
	for x in [1.319,1.581]:
		stage.block(set_root,Vector3(x,.26,.222),Vector3(.027,.45,.008),Color("#75523c"))
		stage.block(set_root,Vector3(x,.29,.229),Vector3(.033,.045,.009),BRASS)
		stage.block(set_root,Vector3(x,.493,.10),Vector3(.027,.008,.246),Color("#75523c"))
	for x in [1.27,1.63]:
		for y in [.057,.462]:
			stage.block(set_root,Vector3(x,y,.223),Vector3(.043,.032,.01),Color("#705947"))
	stage.block(set_root,Vector3(1.45,.29,.224),Vector3(.398,.006,.003),Color("#654838"))
	for x in [-3.73,-2.45,2.45,3.73]:
		stage.block(set_root,Vector3(x,1.025,-1.78),Vector3(1.17,.047,.15),FRAME_COLOR)
		for y in [1.25,1.29,2.34,2.38,2.42]:
			stage.block(set_root,Vector3(x,y,-1.79),Vector3(1.04,.009,.023),Color("#788d91"))
	# A waiting bench just outside the frame of the close-ups.
	for x in [-2.53,-1.75]:
		stage.block(set_root,Vector3(x,.20,-.45),Vector3(.045,.38,.32),ENAMEL)
		stage.block(set_root,Vector3(x,.53,-.59),Vector3(.035,.38,.05),ENAMEL)
	for z in [-.57,-.46,-.35]:
		stage.block(set_root,Vector3(-2.14,.40,z),Vector3(1.24,.043,.092),BRASS)
	for y in [.55,.66]:
		stage.block(set_root,Vector3(-2.14,y,-.592),Vector3(1.24,.082,.038),BRASS)

func _make_ticket(socket: Node3D) -> void:
	var cream := Color("#e6d8b5")
	var ink := Color("#4a514d")
	stage.block(socket,Vector3.ZERO,Vector3(.103,.063,.0009),cream)
	stage.block(socket,Vector3(0,.022,.0006),Vector3(.102,.007,.0005),Color("#995d46"))
	var title := architecture.text_plate(socket,Vector3(-.007,.003,.0012),"RETURN",.011,ink)
	title.double_sided = true
	title.alpha_cut = Label3D.ALPHA_CUT_DISCARD
	for i in 13:
		stage.block(socket,Vector3(-.042+i*.0033,-.018,.001),Vector3(.0009 if i%3 else .0020,.007,.0003),ink)
