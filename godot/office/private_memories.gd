extends Node3D
## Three private places filmed from returning camera marks. Stage space here is
## set apart from the civic archive so that the portraits share one light rig.
const IRON := Color("#34404a")
const BRASS := Color("#b89156")
const WOOD := Color("#956142")
const PINE := Color("#274541")
const CREAM := Color("#d0c49d")
const RUST := Color("#a36047")
const INK := Color("#222e37")
const SLATE := Color("#526574")

var stage
var early := true
var role := 0
var lead: Dictionary
var partner: Dictionary
var scope: Node3D
var chair: Node3D
var handset: Node3D
var paper: Node3D
var pilot_lamps: Array[Node3D] = []
var book_lid: Node3D
var second_cup: Node3D
var remote_switch: Node3D
var readout: Label3D
var indicator: Node3D
var lead_smiles: Array[MeshInstance3D] = []
var partner_smiles: Array[MeshInstance3D] = []

func build(host, first: bool) -> void:
	stage = host
	early = first
	role = stage.profile
	position = Vector3(55,0,0)
	if not stage.actors.is_empty():
		lead = stage.actors[0]
	if role == 0:
		_roof()
	else:
		_room()
	if not lead.is_empty():
		lead_smiles = lead.lips
	if not partner.is_empty():
		partner_smiles = partner.lips
	frame(0)

func _smile(parts: Array[MeshInstance3D], amount: float) -> void:
	for part in parts:
		part.set_blend_shape_value(part.find_blend_shape_by_name("Smile"),amount)

func box(parent: Node3D,p: Vector3,d: Vector3,c: Color) -> Node3D:
	return stage.block(parent,p,d,c)

func point(parent: Node3D,p: Vector3) -> Node3D:
	return stage.joint(parent,p)

func rod(parent: Node3D, a: Vector3, b: Vector3, r: float, c: Color, top: float = -1, sides: int = 12) -> Node3D:
	var m := CylinderMesh.new()
	m.bottom_radius = r
	m.top_radius = r if top<0 else top
	m.height = a.distance_to(b)
	m.radial_segments = sides
	m.rings = 0
	var o: Node3D = stage.model(parent,(a+b)*.5,m,c)
	o.quaternion = Quaternion(Vector3.UP,(b-a).normalized())
	return o

func plate(parent: Node3D, p: Vector3, msg: String, h: float, tint: Color) -> Label3D:
	var v := Label3D.new()
	v.font_size = 48
	v.pixel_size = h/48
	v.outline_size = 0
	v.modulate = tint
	v.position = p
	v.text = msg
	parent.add_child(v)
	return v

func practical(p: Vector3,c: Color,energy: float,radius: float) -> void:
	var light := OmniLight3D.new()
	light.position = p
	light.light_color = c
	light.light_energy = energy
	light.omni_range = radius
	add_child(light)

func stool(p: Vector3, yaw: float) -> Node3D:
	var obj := point(self,p)
	obj.rotation.y = yaw
	rod(obj,Vector3(0,.55,0),Vector3(0,.593,0),.218,WOOD,-1,24)
	for side in [-1,1]:
		for back in [-1,1]:
			rod(obj,Vector3(side*.187,.015,back*.17),Vector3(side*.123,.55,back*.12),.018,IRON)
		rod(obj,Vector3(side*.135,.43,-.14),Vector3(side*.135,.978,-.17),.016,IRON)
	box(obj,Vector3(0,.956,-.17),Vector3(.341,.120,.035),WOOD).rotation.x = -.13
	return obj

func cup(parent: Node3D, p: Vector3, chipped: bool) -> Node3D:
	var obj := point(parent,p)
	rod(obj,Vector3.ZERO,Vector3.UP*.135,.060,CREAM,.077)
	rod(obj,Vector3.UP*.135,Vector3.UP*.141,.077,CREAM)
	rod(obj,Vector3.UP*.141,Vector3.UP*.143,.063,Color("#4c3933"))
	var handle := TorusMesh.new()
	handle.inner_radius=.026
	handle.outer_radius=.038
	handle.rings=16
	handle.ring_segments=5
	var ring: Node3D = stage.model(obj,Vector3(.08,.078,0),handle,CREAM)
	ring.rotation.x=PI/2
	if chipped:
		var chip := box(obj,Vector3(.022,.136,.070),Vector3(.029,.018,.012),Color("#704933"))
		chip.rotation.z = .49
		rod(obj,Vector3.UP*.039,Vector3.UP*.052,.065,RUST,.067)
	return obj

func _lamp(p: Vector3) -> void:
	var o := point(self,p)
	rod(o,Vector3.ZERO,Vector3.UP*.045,.117,IRON)
	rod(o,Vector3.UP*.03,Vector3.UP*.265,.015,BRASS)
	rod(o,Vector3.UP*.245,Vector3.UP*.30,.13,Color("#e6bb7b"),.12)
	rod(o,Vector3.UP*.266,Vector3.UP*.393,.153,RUST,.058)
	practical(to_local(o.global_position)+Vector3(.10,.21,.08),Color("#ffd6a3"),early_default(.70,.36),2.8)

func early_default(a: float,b: float) -> float:
	return a if early else b

func _roof() -> void:
	stage.camera.environment.background_color = Color("#485777") if early else Color("#36445b")
	stage.camera.environment.fog_enabled = false
	stage.camera.environment.ambient_light_energy = early_default(.54,.38)
	stage.key.light_energy = early_default(.46,.26)
	stage.key.light_color = Color("#b3c5e1")
	_mountains()
	box(self,Vector3(0,-.075,-.1),Vector3(8,.15,5),Color("#515967"))
	for i in range(-5,6):
		box(self,Vector3(i*.65,.008,0),Vector3(.013,.007,4.9),IRON)
	for i in range(-4,5):
		var x := i*.9
		rod(self,Vector3(x,0,-1.92),Vector3(x,.88,-1.92),.023,IRON)
	for h in [.38,.88]:
		rod(self,Vector3(-4.1,h,-1.92),Vector3(4.1,h,-1.92),.026,SLATE)
	# Shutter hoops sweep into the top left of the composition.
	for z in [.15,-.70,-1.55]:
		var prev := Vector3(-2.50,0,z)
		for j in 14:
			var ang := (j+1)*.102
			var tip := Vector3(-2.50+2.06*(1-cos(ang)),2.30+1.61*sin(ang),z)
			rod(self,prev,tip,.049,IRON)
			prev = tip
	rod(self,Vector3(-2.48,2.24,.22),Vector3(-2.48,2.24,-1.63),.046,BRASS)
	_telescope()
	stool(Vector3(-1.40,0,-.43),.16)
	chair = stool(Vector3(-.64,0,.28),-.12)
	var ledge := point(self,Vector3(-1.01,.866,.54))
	box(ledge,Vector3.ZERO,Vector3(.92,.047,.43),WOOD)
	for x in [-.38,.38]:
		rod(ledge,Vector3(x,-.863,.04),Vector3(x,-.025,.04),.022,IRON)
	second_cup = cup(ledge,Vector3(-.12,.026,.062),true)
	cup(ledge,Vector3(.19,.026,-.008),false)
	_lamp(ledge.position+Vector3(-.34,.025,-.065))
	paper = _notebook()
	practical(Vector3(-1.94,1.59,.84),Color("#ffd09b"),early_default(.62,.33),3.8)
	if early:
		lead.body.position=to_global(Vector3(-.04,0,.32))
		stage.person(to_global(Vector3(-1.01,0,-.16)),"mara","watch",.82)
		partner = stage.actors.back()
	else:
		lead.body.position = to_global(Vector3(-.99,0,.27))
		var panel := point(self,Vector3(-1.64,1.24,.32))
		box(panel,Vector3.ZERO,Vector3(.52,.37,.13),IRON)
		box(panel,Vector3(0,0,.075),Vector3(.47,.31,.025),INK)
		remote_switch = point(panel,Vector3(.192,-.098,.10))
		box(remote_switch,Vector3.ZERO,Vector3(.050,.035,.021),BRASS)
		readout = plate(panel,Vector3(0,.01,.096),"REMOTE LINK",.044,BRASS)

func _notebook() -> Node3D:
	var root := point(self,Vector3(-.82,.904,.68))
	root.rotation.y=.15
	# Hinge at the cloth binding: when closed the front cover lies over the
	# right-hand page. A ribbon and two dated observations survive both years.
	for side in [1,-1]:
		var leaf := point(root,Vector3.ZERO)
		if side == -1:
			book_lid = leaf
		box(leaf,Vector3(side*.092,.001,0),Vector3(.184,.012,.240),Color("#884336"))
		box(leaf,Vector3(side*.092,.012,0),Vector3(.177,.011,.232),Color("#d6c99f"))
		for row in 4:
			box(leaf,Vector3(side*.094,.018,-.074+row*.041),Vector3(.15,.001,.0016),Color("#afa284"))
		var shift := -.040 if side==1 else -.061
		for v in [Vector2(-.045,.023),Vector2(.021,-.037),Vector2(shift,-.052)]:
			var dot := Vector3(side*.089+v.x,.019,v.y)
			rod(leaf,dot,dot+Vector3.UP*.003,.0052,INK)
		box(leaf,Vector3(side*.059,.020,.072),Vector3(.052,.002,.004),Color("#686353"))
	box(root,Vector3(.013,.016,.080),Vector3(.010,.007,.125),RUST)
	book_lid.rotation.z=-PI*.965 if early else .015
	return root

func _telescope() -> void:
	var footing := point(self,Vector3(-2.05,.08,-.78))
	for i in 3:
		var phi := i*TAU/3+.4
		rod(footing,Vector3(cos(phi)*.55,.012,sin(phi)*.55),Vector3(cos(phi)*.09,1.17,sin(phi)*.09),.041,SLATE,.064)
	rod(footing,Vector3.UP*1.10,Vector3.UP*1.25,.174,IRON)
	rod(footing,Vector3(0,1.19,0),Vector3(.165,1.52,-.03),.083,BRASS)
	rod(footing,Vector3(-.15,1.38,0),Vector3(.32,1.53,-.07),.034,SLATE)
	rod(footing,Vector3(-.31,1.32,.028),Vector3(-.148,1.38,0),.105,IRON)
	scope = point(footing,Vector3(.22,1.58,-.03))
	scope.rotation=Vector3(-.48,2.28,0)
	for piece in [[-.89,-.72,.046,IRON],[-.72,-.51,.086,BRASS],[-.52,.61,.145,CREAM],[.60,.77,.172,SLATE],[.77,.79,.144,INK],[.791,.796,.121,Color("#456878")]]:
		rod(scope,Vector3(0,0,piece[0]),Vector3(0,0,piece[1]),piece[2],piece[3],-1,24)
	for z in [-.42,.25]:
		rod(scope,Vector3(0,0,z),Vector3(0,0,z+.052),.155,BRASS)
		rod(scope,Vector3(.065,.106,z),Vector3(.076,.18,z),.018,IRON)
	rod(scope,Vector3(.072,.20,-.42),Vector3(.072,.20,.31),.037,IRON)
	rod(scope,Vector3(0,0,-.74),Vector3(0,.115,-.81),.035,IRON)

func _mountains() -> void:
	var sky := MeshInstance3D.new()
	var mesh := QuadMesh.new()
	mesh.size = Vector2(63,27)
	sky.mesh = mesh
	var sky_material := ShaderMaterial.new()
	sky_material.shader = preload("res://office/memory_sky.gdshader")
	sky_material.set_shader_parameter("winter",0.0 if early else 1.0)
	sky.material_override=sky_material
	sky.position = Vector3(0,4.5,-23)
	add_child(sky)
	# Sloping front and rear ridges share a jagged skyline and snow tongues.
	var terrain := SurfaceTool.new()
	terrain.begin(Mesh.PRIMITIVE_TRIANGLES)
	for layer in 3:
		var far := -19.0+layer*2.25
		for i in 48:
			var x := -25+i*1.07
			var a := _ridge(i,layer)
			var b := _ridge(i+1,layer)
			var top_a := Vector3(x,a,far-.20*cos(i*.88))
			var top_b := Vector3(x+1.07,b,far-.20*cos((i+1)*.88))
			var seam_a := top_a+Vector3(.11,-.34-.28*absf(sin(i*2.1)),.54)
			var seam_b := top_b+Vector3(.11,-.34-.28*absf(sin((i+1)*2.1)),.54)
			var base_a := Vector3(x,-.9,far+3.0)
			var base_b := Vector3(x+1.07,-.9,far+3.0)
			var stone := [Color("#758394"),Color("#586a75"),Color("#354e53")][layer] as Color
			var snow := Color("#b8b0aa") if layer == 0 else Color("#81949a") if layer == 1 else stone
			_quad(terrain,top_a,top_b,seam_b,seam_a,snow.darkened(.11*absf(sin(i))))
			_quad(terrain,seam_a,seam_b,base_b,base_a,stone.darkened(.14*absf(cos(i))))
	for i in 97:
		var x := -15.0+i*.31
		var h := .35+1.05*absf(sin(i*17.93))
		var z := -6.4-2.1*absf(sin(i*3.842))
		for tier in 2:
			var ht := h*(.77 if tier == 0 else .52)
			var y := .22*sin(i*.17)+tier*h*.46
			var r := h*(.29 if tier==0 else .18)
			for j in 5:
				var a := j*TAU/5+.30
				var b := (j+1)*TAU/5+.30
				var c := [Color("#344c52"),Color("#2b444b"),Color("#243a43")][(j+i)%3] as Color
				for v in [Vector3(x+cos(a)*r,y,z+sin(a)*r),Vector3(x,y+ht,z),Vector3(x+cos(b)*r,y,z+sin(b)*r)]:
					terrain.set_color(c)
					terrain.add_vertex(v)
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.vertex_color_use_as_albedo=true
	mat.cull_mode=BaseMaterial3D.CULL_DISABLED
	var land := MeshInstance3D.new()
	land.mesh=terrain.commit()
	land.material_override=mat
	add_child(land)
	for i in range(120):
		var x := sin(i*136.71)*17
		var h := 3.1+5.7*absf(sin(i*23.76))
		stage.round_part(self,Vector3(x,h,-18.8),Vector3.ONE*(.038+.046*absf(sin(i*39))),CREAM)
	for i in range(8):
		var x := 1.1+i*.35
		var window := box(self,Vector3(x,.66+.10*sin(i*1.8),-5.9-.16*i),Vector3(.056,.045,.022),BRASS)
		var m := StandardMaterial3D.new()
		m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		m.albedo_color = Color("#d39a5d")
		window.material_override=m

func _ridge(i: int,layer: int) -> float:
	return 2.45-layer*.70+(.9-.20*layer)*absf(sin(i*.43+layer*.81))+.48*cos(i*.93+layer)+.27*sin(i*2.34)

func _quad(builder: SurfaceTool, a: Vector3,b: Vector3,c: Vector3,d: Vector3,color: Color) -> void:
	for v in [a,b,c,a,c,d]:
		builder.set_color(color)
		builder.add_vertex(v)

func _room() -> void:
	var relay := role == 1
	stage.key.light_energy = early_default(.52,.34)
	stage.camera.environment.ambient_light_energy = early_default(.52,.43)
	lead.body.position = to_global(Vector3(-.43,0,.14))
	box(self,Vector3(0,-.076,0),Vector3(7,.15,6),Color("#66594f"))
	box(self,Vector3(0,1.7,-1.85),Vector3(8,3.4,.19),Color("#697772") if relay else Color("#7f8073"))
	for w in 3:
		var x := -3.18+1.18*w
		box(self,Vector3(x,1.95,-1.73),Vector3(1.12,1.66,.10),IRON)
		box(self,Vector3(x,1.96,-1.66),Vector3(.99,1.52,.04),SLATE)
		for j in 6:
			box(self,Vector3(x,2.52-j*.089,-1.62),Vector3(1.01,.042,.056),Color("#6f776f")).rotation.x=.23
	box(self,Vector3(.96,1.87,-1.70),Vector3(1.34,.96,.09),WOOD)
	box(self,Vector3(.96,1.87,-1.64),Vector3(1.22,.84,.023),CREAM)
	for i in 4:
		var p := Vector3(.53+i*.26,1.68+.22*sin(i*1.5),-1.60)
		rod(self,p,p+Vector3(0,0,.02),.030,BRASS)
		if i:
			var previous := Vector3(.53+(i-1)*.26,1.68+.22*sin((i-1)*1.5),-1.60)
			rod(self,previous,p,.010,Color("#547267"))
	var desk := point(self,Vector3(.34,1.0,.30))
	box(desk,Vector3.ZERO,Vector3(1.63,.07,.78),WOOD)
	for x in [-.69,.69]:
		box(desk,Vector3(x,-.52,-.02),Vector3(.063,1.01,.61),IRON)
	_lamp(desk.position+Vector3(.59,.048,-.125))
	practical(Vector3(-1.44,1.80,1.08),Color("#efc89d"),early_default(.78,.52),3.)
	chair = stool(Vector3(.89,0,-.25),.34)
	indicator = point(self,desk.position+Vector3(.06,.31,-.14))
	box(indicator,Vector3.ZERO,Vector3(.76,.50,.16),IRON)
	box(indicator,Vector3(0,0,.094),Vector3(.675,.401,.032),Color("#253c43"))
	readout = plate(indicator,Vector3(0,.017,.121),"",.053,Color("#f4ca85"))
	for i in (3 if relay else 2):
		var x := -.23+i*(.23 if relay else .46)
		rod(indicator,Vector3(x,.114,.12),Vector3(x,.114,.147),.041,INK)
		pilot_lamps.append(rod(indicator,Vector3(x,.114,.145),Vector3(x,.114,.153),.029,BRASS))
	readout.position.y -= .040
	if relay:
		handset = point(self,Vector3(-.17,1.18,.55))
		for side in [-1,1]:
			rod(handset,Vector3(side*.12,-.015,0),Vector3(side*.12,.052,0),.044,IRON)
		rod(handset,Vector3(-.122,0,0),Vector3(.122,0,0),.024,RUST)
		box(desk,Vector3(-.43,.082,.27),Vector3(.38,.093,.185),Color("#797665"))
		for tap in 3:
			box(desk,Vector3(-.47+.046*tap,.137,.27),Vector3(.028,.011,.045),BRASS)
		for post in [-.39,-.29]:
			rod(desk,Vector3(post,.04,-.20),Vector3(post,.91,-.20),.011,IRON)
	else:
		paper = point(self,desk.position+Vector3(.05,.057,.19))
		box(paper,Vector3.ZERO,Vector3(.42,.013,.25),CREAM)
		for x in [-.10,.10]:
			box(paper,Vector3(x,.008,.043),Vector3(.143,.004,.009),IRON)
		rod(paper,Vector3(-.07,.018,.07),Vector3(.12,.018,-.07),.011,INK)
		if early:
			stage.person(to_global(Vector3(.83,0,-.38)),"jo","watch",-.72)
			partner = stage.actors.back()

func _reach(actor: Dictionary, side: int, world_target: Vector3, bend: Vector3) -> void:
	actor.driver.hand_targets["L" if side == 1 else "R"] = world_target
	var upper: Node3D=actor.arms[side]
	var fore: Node3D=upper.get_node("Elbow")
	var desired := (upper.get_parent() as Node3D).to_local(world_target)-upper.position
	var axis := desired.normalized()
	var extent := clampf(desired.length(),.07,.685)
	var upper_length := fore.position.length()
	var fore_length := .36
	var along := (upper_length**2-fore_length**2+extent**2)/(2.0*extent)
	var out := (bend-axis*bend.dot(axis)).normalized()
	var elbow := axis*along + out*sqrt(maxf(0.,upper_length**2-along**2))
	upper.quaternion = Quaternion(Vector3.DOWN,elbow.normalized())
	fore.quaternion = Quaternion(Vector3.DOWN,upper.quaternion.inverse()*(axis*extent-elbow).normalized())

func _camera(here: Vector3,there: Vector3) -> void:
	stage.camera.position=to_global(here)
	stage.camera.look_at(to_global(there))

func frame(t: float) -> void:
	if role == 0:
		_roof_frame(t)
	else:
		_room_frame(t)

func _roof_frame(t: float) -> void:
	var move := smoothstep(.40,3.70,t)
	var withdraw := smoothstep(4.7,6.65,t)
	# Identical first camera mark in both years: the cups and the missing figure
	# do the work before the camera moves in on the chipped enamel.
	var drift := .12 * smoothstep(.8,6.3,t)
	_camera(Vector3(.75-drift,1.69,3.29-drift),Vector3(-.52,1.34,-.25))
	if early:
		lead.body.rotation.y = lerpf(.26,-.72,move)+1.45*withdraw
		lead.head.rotation.y = -.35*move+.52*withdraw
		lead.head.rotation.x = .15-.31*withdraw
		partner.body.rotation.y=.84
		partner.head.rotation.y=.20+.13*move
		partner.head.rotation.x=.11-.10*move
		_smile(lead_smiles,.65*move*(1-.6*withdraw))
		_smile(partner_smiles,.6*move)
		var chair_top := chair.to_global(Vector3(.12,.96,-.17))
		_reach(partner,1,chair_top+Vector3(-.07,.00,-.03),Vector3(.34,-.4,-.52))
		var endpoint := to_global(Vector3(.16,1.05,.60)).lerp(chair_top+Vector3(.04,.022,.08),move)
		_reach(lead,1,to_global(Vector3(.10,1.26,.55)),Vector3(.66,-.56,.27))
		_reach(lead,0,endpoint.lerp(to_global(Vector3(-.32,1.28,.55)),withdraw),Vector3(-.65,-.42,.27))
		var set_down := smoothstep(7.1,8.8,t)
		var elbow: Node3D = lead.arms[1].get_node("Elbow")
		var held := elbow.global_transform * Transform3D(Basis.from_euler(Vector3(.64,-.20,.06)),Vector3(-.071,-.335,.087))
		var table_mark := global_transform * Transform3D(Basis.from_euler(Vector3(0,.12,0)),Vector3(-.79,.905,.691))
		paper.global_transform=held.interpolate_with(table_mark,set_down)
		book_lid.rotation.z=lerpf(-PI*.965,.015,smoothstep(8.2,9.22,t))
		if t>5.65:
			_camera(Vector3(.53,1.77,1.66),Vector3(-.20,1.65,.03))
		if t>8.15:
			_camera(Vector3(-.31,1.57,1.37),Vector3(-.88,.935,.57))
			_reach(partner,1,to_global(Vector3(-.89,.95,.61)),Vector3(.86,-.22,.03))
	else:
		# Her hand still turns the chipped handle towards the empty stool.
		var turn_cup := smoothstep(.7,3.1,t)
		var let_go := smoothstep(3.45,5.3,t)
		var handover := smoothstep(6.0,9.2,t)
		var release := smoothstep(9.6,11.3,t)
		second_cup.rotation.y = -.88*turn_cup
		lead.body.rotation.y = lerpf(.37,-1.0,handover)
		lead.spine.rotation.x = .16-.10*let_go
		lead.head.rotation.x = .36-.28*let_go+.12*handover
		lead.head.rotation.y = .10+.46*let_go-.86*handover
		var handle := second_cup.to_global(Vector3(.08,.077,0))
		var rest: Vector3 = lead.body.to_global(Vector3(-.28,.98,.13))
		var reach := handle.lerp(rest,let_go)
		var button := remote_switch.to_global(Vector3(0,0,.022))
		reach = reach.lerp(button,handover).lerp(rest,.82*release)
		_reach(lead,0,reach,Vector3(-.78,-.42,.23))
		if t>4.6:
			_camera(Vector3(-.22,1.43,1.98),Vector3(-1.05,1.06,.46))
		if t>7.15:
			_camera(Vector3(-2.19,1.53,2.26),Vector3(-1.29,1.34,.29))
		remote_switch.position.z = .10-.012*(smoothstep(8.95,9.22,t)-smoothstep(9.65,10.0,t))
		readout.text="REMOTE LINK" if t<9.22 else "ONLY   2 / 3"
	scope.rotation.y=2.28-.29*smoothstep(5.8,9.50,t) if not early else 2.28
	scope.rotation.x=-.48+.11*smoothstep(5.8,9.50,t) if not early else -.48

func _room_frame(t: float) -> void:
	var amp := smoothstep(.5,2.25,t)
	var leave := smoothstep(4.2,6.8,t)
	var relay := role == 1
	_camera(Vector3(.62,1.60,2.72),Vector3(.01,1.38,.08))
	lead.body.rotation.y = .40+.19*amp
	lead.head.rotation.y = .33*amp
	lead.head.rotation.x = .12+.09*amp
	for i in pilot_lamps.size():
		pilot_lamps[i].visible = t > 1.9+i*.36 if early else t < 4.1 or i == 0
	if relay:
		readout.text = ("CHANNEL   03\nBROTHER CALLING" if t<1.7 else "CHANNEL   03\nLINE OPEN") if early else ("NIGHT SHIFT\nLINE OPEN" if t<4.1 else "NIGHT SHIFT\nCALLS MUTED")
		var rest := Vector3(-.17,1.159,.56)
		var earpiece := Vector3(.12,.035,0).rotated(Vector3.BACK,1.32)
		var ear := to_local(lead.driver.ear_world("L")) - earpiece
		handset.position = rest.lerp(ear,amp if early else 1.-leave)
		handset.rotation.z = lerpf(.14,1.32,amp if early else 1.-leave)
		_reach(lead,1,handset.to_global(Vector3(0,-.018,.012)),Vector3(.86,-.22,.03))
		_smile(lead_smiles,.77*amp if early else .25*(1.-leave))
		if t>5.2:
			if early:
				_camera(Vector3(.39,1.62,1.68),Vector3(-.36,1.73,.13))
			else:
				_camera(Vector3(.22,1.50,1.56),Vector3(.08,1.25,.36))
	else:
		readout.text = ("DRILL   02\nTWO WITNESSES" if t<4.65 else "DRILL   02\nTWO SIGNATURES") if early else ("DRILL   02\nWAITING" if t<4.1 else "AUTO-SIGN\nVERIFIED")
		var line := paper.to_global(Vector3(-.08,.035,.00))
		var pilot := indicator.to_global(Vector3(-.23,.114,.157))
		var ask := pilot.lerp(line,leave) if early else to_global(Vector3(-.13,1.23,.52)).lerp(line,amp)
		_reach(lead,1,ask,Vector3(.72,-.32,.24))
		if early:
			_reach(partner,0,line+Vector3(.18,.16*(1-leave),-.04),Vector3(-.65,-.43,.32))
			partner.head.rotation.x=.20*(1-leave)
			partner.head.rotation.y=-.38+.27*leave
			_smile(lead_smiles,.47*leave)
			_smile(partner_smiles,.54*leave)
		else:
			lead.head.rotation.y=.34+.64*leave
			_reach(lead,1,ask.lerp(to_global(Vector3(-.08,1.15,.63)),leave),Vector3(.94,-.23,.1))
		if t>5.0:
			_camera(Vector3(.43,1.70,1.73),Vector3(.34,1.21,.07))
