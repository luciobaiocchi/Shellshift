extends Node3D
## Props and camera inserts for the archive sequences after the office.
const IVORY := Color("#d4c49d")
const INK := Color("#28333a")
const COPPER := Color("#ad6749")
const MINT := Color("#759489")
const GLASS := Color("#435c69")
const AMBER := Color("#e8b563")

var stage
var private_memory: Node3D
var shot: int
var readout: Label3D
var board: Node3D
var ring: Node3D
var scan: MeshInstance3D
var witness: Node3D
var narrator: Dictionary
var gate: Node3D
var dispatch: Node3D
var visitor: Dictionary
var sheets: Node3D

func build(host, index: int) -> void:
	stage = host
	shot = index
	match shot:
		1,5:
			private_memory = preload("res://office/private_memories.gd").new()
			add_child(private_memory)
			private_memory.build(stage,shot==1)
		2: campaign()
		4: laboratory()
		6: viaduct()
		7: concourse()
		8: chamber()
		9: terminal()

func box(parent: Node3D, pos: Vector3, dims: Vector3, color: Color) -> MeshInstance3D:
	return stage.block(parent,pos,dims,color)

func rod(parent: Node3D, start: Vector3, end: Vector3, radius: float, color: Color, taper: float = 1.0) -> MeshInstance3D:
	var segment := end-start
	var mesh := CylinderMesh.new()
	mesh.radial_segments = 12
	mesh.rings = 0
	mesh.top_radius = radius*taper
	mesh.bottom_radius = radius
	mesh.height = segment.length()
	var piece: MeshInstance3D = stage.model(parent,(start+end)*.5,mesh,color)
	piece.quaternion = Quaternion(Vector3.UP,segment.normalized())
	return piece

func text_plate(parent: Node3D, pos: Vector3, value: String, height: float, color: Color = IVORY) -> Label3D:
	var label := Label3D.new()
	parent.add_child(label)
	label.position = pos
	label.text = value
	label.pixel_size = height/48.0
	label.font_size = 48
	label.outline_size = 0
	label.modulate = color
	return label

func campaign() -> void:
	board = stage.joint(self,Vector3(0,2.2,-1.13))
	box(board,Vector3.ZERO,Vector3(7.5,3.65,.29),INK)
	box(board,Vector3(0,0,.16),Vector3(7.27,3.40,.04),MINT.darkened(.34))
	for y in [-1.59,1.59]:
		box(board,Vector3(0,y,.191),Vector3(7,.035,.024),IVORY)
	for x in [-2.97,2.97]:
		rod(board,Vector3(x,-2.25,-.1),Vector3(x,-1.7,-.1),.105,INK)
	text_plate(board,Vector3(0,1.14,.20),"ASTER   /   PUBLIC INITIATIVE",.20,IVORY)
	readout = text_plate(board,Vector3(0,.31,.20),"A cure for all.",.42)
	text_plate(board,Vector3(0,-1.10,.20),"2027 CAMPAIGN",.18,AMBER)
	stage.eye = Vector3(2.2,1.88,6.9)
	stage.target = Vector3(0,2.12,-.8)

func hospital_exterior(glazing: Material = null) -> void:
	stage.key.light_energy = .61
	stage.camera.environment.ambient_light_energy = .61
	box(self,Vector3(0,1.47,-2.02),Vector3(8.8,2.95,.3),Color("#969d8f"))
	for x in [-3.73,-2.45,2.45,3.73]:
		var window := box(self,Vector3(x,1.8,-1.84),Vector3(1.08,1.48,.06),GLASS)
		if glazing: window.material_override = glazing
		box(self,Vector3(x,1.71,-1.79),Vector3(1.08,.045,.04),IVORY)
		box(self,Vector3(x,1.8,-1.79),Vector3(.04,1.48,.04),IVORY)
	box(self,Vector3(0,1.08,-1.79),Vector3(2.43,2.16,.12),INK)
	for x in [-.59,.59]:
		box(self,Vector3(x,.99,-1.70),Vector3(1.14,1.94,.07),MINT)
		var pane := box(self,Vector3(x,1.44,-1.65),Vector3(.81,.7,.04),GLASS)
		if glazing: pane.material_override = glazing
		box(self,Vector3(x,.9,-1.61),Vector3(.84,.045,.05),IVORY)
	box(self,Vector3(0,2.45,-1.69),Vector3(3.1,.45,.12),GLASS)
	text_plate(self,Vector3(0,2.45,-1.615),"WARD   /   EXIT",.17)
	for x in [-1.9,1.9]:
		rod(self,Vector3(x,.02,-1),Vector3(x,.69,-1),.068,GLASS)
	box(self,Vector3(1.45,.26,.1),Vector3(.41,.46,.24),COPPER)
	rod(self,Vector3(1.34,.55,.10),Vector3(1.55,.55,.10),.023,INK)
	for x in [1.34,1.55]:
		rod(self,Vector3(x,.47,.10),Vector3(x,.55,.1),.016,INK)
	var awning := box(self,Vector3(0,2.82,-1.23),Vector3(5.8,.15,1.6),INK)
	awning.material_override = stage.STEEL
	for x in [-1.8,1.8]:
		box(self,Vector3(x,2.73,-.82),Vector3(.81,.04,.12),IVORY)
	var bounce := OmniLight3D.new()
	add_child(bounce)
	bounce.position = Vector3(.35,1.9,.90)
	bounce.light_color = Color("#f0d7b1")
	bounce.light_energy = .24
	bounce.omni_range = 3.5
	bounce.light_specular = 0
	stage.eye = Vector3(.05,1.58,3.36)
	stage.target = Vector3(0,1.45,-.18)

# Pose both real arm segments against a point on the other actor's coat.
func reach(actor: Dictionary, side: int, target_point: Vector3, elbow_hint: Vector3) -> void:
	var upper: Node3D = actor.arms[side]
	var lower: Node3D = upper.get_node("Elbow")
	var start := upper.global_position
	var ray := (target_point-start).normalized()
	var distance := clampf(start.distance_to(target_point),.14,.709)
	var along := (.337*.337-.375*.375+distance*distance)/(2.0*distance)
	var bend := sqrt(maxf(0,.337*.337-along*along))
	var perpendicular := (elbow_hint-start).slide(ray).normalized()
	var joint_at := start+ray*along+perpendicular*bend
	var upper_direction := upper.get_parent_node_3d().global_basis.inverse()*(joint_at-start)
	upper.quaternion = Quaternion(Vector3.DOWN,upper_direction.normalized())
	var lower_direction := upper.global_basis.inverse()*(start+ray*distance-joint_at)
	lower.quaternion = Quaternion(Vector3.DOWN,lower_direction.normalized())

func laboratory() -> void:
	# The inspection bench occupies its own enclosed bay in the municipal building.
	position.x = 42.
	var paint := Color("#8b958c")
	var lino := Color("#566963")
	var oak := Color("#936d52")
	var steel := Color("#495957")
	var paper := Color("#ecdfc3")
	stage.key.light_energy = .40
	stage.key.rotation_degrees = Vector3(-35,-36,0)
	stage.camera.environment.ambient_light_color = Color("#c1c6be")
	stage.camera.environment.ambient_light_energy = .46
	box(self,Vector3(0,-.085,-.10),Vector3(8.3,.17,7.7),lino)
	box(self,Vector3(0,1.63,-2.39),Vector3(8.3,3.26,.15),paint)
	box(self,Vector3(-3.83,1.63,.1),Vector3(.15,3.26,5.2),paint.darkened(.08))
	box(self,Vector3(3.73,1.63,.10),Vector3(.15,3.26,5.2),paint.darkened(.14))
	box(self,Vector3(0,3.24,.2),Vector3(8.3,.12,5.5),Color("#a4a59a"))
	box(self,Vector3(0,.40,-2.28),Vector3(7.56,.80,.10),lino)
	box(self,Vector3(0,.80,-2.20),Vector3(7.56,.055,.06),steel)
	for x in [-2.7,-1.65,.1,1.81,3.16]:
		box(self,Vector3(x,.39,-2.22),Vector3(.017,.72,.045),steel.lightened(.08))
	# Side lights sit above the service window. The daylight slats catch a warm edge.
	for i in 2:
		var x := -2.77+i*.83
		box(self,Vector3(x,1.79,-2.27),Vector3(.83,1.42,.10),steel)
		box(self,Vector3(x,1.8,-2.20),Vector3(.74,1.31,.035),Color("#b5c4b5"))
		for slat in 9:
			var blade := box(self,Vector3(x,2.34-slat*.127,-2.156),Vector3(.738,.052,.086),Color("#85938a"))
			blade.rotation.x = -.32
		box(self,Vector3(x,1.08,-2.17),Vector3(.84,.046,.24),steel)
	# Original proof and elapsed machine time remain legible on the relay's face.
	board = stage.joint(self,Vector3(.12,1.82,-2.22))
	box(board,Vector3.ZERO,Vector3(2.57,1.30,.20),steel)
	box(board,Vector3(-.11,.02,.118),Vector3(2.15,1.03,.06),INK)
	box(board,Vector3(-.11,.02,.154),Vector3(2.05,.94,.023),Color("#253d3c"))
	text_plate(board,Vector3(-.1,.325,.171),"ASTER   /   PROOF 17",.090,Color("#ccc6a0"))
	readout = text_plate(board,Vector3(-.1,.008,.172),"RUNNING",.146,Color("#eec486"))
	narrator = stage.actors.back()
	narrator.lab_elapsed = text_plate(board,Vector3(-.1,-.286,.172),"START    23:11",.077,Color("#a7c6b1"))
	for i in 3:
		box(board,Vector3(1.12,.33-i*.17,.124),Vector3(.059,.047,.027),[AMBER,MINT,INK][i])
	for i in 6:
		box(board,Vector3(1.10,-.23-i*.039,.119),Vector3(.16,.015,.014),INK)
	for x in [-1.03,.98]:
		rod(self,Vector3(x,.42,-2.09),Vector3(x,1.30,-2.09),.017,steel)
	# A second testing station and filing cabinet close the rear of the room.
	var back: Node3D = stage.joint(self,Vector3(-1.22,0,-1.27))
	box(back,Vector3(0,.905,0),Vector3(1.95,.083,.78),oak)
	for x in [-.80,.81]: box(back,Vector3(x,.43,0),Vector3(.065,.86,.63),steel)
	box(back,Vector3(-.30,1.04,0),Vector3(.73,.18,.36),steel)
	box(back,Vector3(-.30,1.045,.19),Vector3(.61,.115,.018),INK)
	for i in 5:
		rod(back,Vector3(-.49+.097*i,1.045,.2),Vector3(-.49+.097*i,1.045,.235),.025,AMBER if i == 3 else MINT)
	box(back,Vector3(.32,.968,.11),Vector3(.29,.025,.34),paper)
	var cabinet: Node3D = stage.joint(self,Vector3(2.60,.02,-1.96))
	box(cabinet,Vector3(0,1.11,0),Vector3(1.16,2.21,.48),steel)
	for row in 5:
		var y := .26+row*.427
		box(cabinet,Vector3(0,y,.26),Vector3(1.07,.385,.04),Color("#788880"))
		box(cabinet,Vector3(0,y+.03,.295),Vector3(.26,.069,.023),INK)
		box(cabinet,Vector3(0,y+.03,.310),Vector3(.18,.042,.009),paper)
		box(cabinet,Vector3(0,y-.064,.306),Vector3(.28,.021,.05),steel)
	var lamp: Node3D = stage.joint(self,Vector3(.36,2.93,-.24))
	box(lamp,Vector3.ZERO,Vector3(1.70,.11,.27),steel)
	box(lamp,Vector3(0,-.064,0),Vector3(1.55,.033,.18),Color("#f4dfb4"))
	for x in [-.64,.64]: rod(lamp,Vector3(x,.03,0),Vector3(x,.28,0),.012,INK)
	var tasklight := SpotLight3D.new()
	add_child(tasklight)
	tasklight.position = Vector3(-1.08,2.69,.91)
	tasklight.look_at(to_global(Vector3(.50,1.0,-.03)))
	tasklight.light_color = Color("#ffdfac")
	tasklight.light_energy = 1.45
	tasklight.spot_range = 5.0
	tasklight.spot_angle = 65
	tasklight.spot_attenuation = .63
	tasklight.light_specular = .15
	tasklight.shadow_enabled = true
	var window_light := OmniLight3D.new()
	add_child(window_light)
	window_light.position = Vector3(-1.87,2.12,-1.08)
	window_light.light_energy = .64
	window_light.light_color = Color("#d8ece8")
	window_light.omni_range = 4.6
	window_light.light_specular = .12
	# The counter's pay ledger sits beside six separate monthly examination bundles.
	var bench: Node3D = stage.joint(self,Vector3(.40,0,.27))
	box(bench,Vector3(0,.945,0),Vector3(2.53,.092,.85),oak)
	box(bench,Vector3(0,.997,0),Vector3(2.48,.014,.81),Color("#4d635b"))
	box(bench,Vector3(0,.884,0),Vector3(2.42,.080,.73),steel)
	for x in [-1.08,1.08]:
		for z in [-.30,.30]: box(bench,Vector3(x,.44,z),Vector3(.048,.88,.048),steel)
	var files: Node3D = stage.joint(self,Vector3(-.23,1.011,.25))
	var months := ["JAN","FEB","MAR","APR","MAY","JUN"]
	for i in 6:
		var file: Node3D = stage.joint(files,Vector3(floori(i/3)*.422+(i%3)*.008,(i%3)*.050,-(i%3)*.028))
		file.rotation.y = -.032+.019*(i%3)
		box(file,Vector3(0,.024,0),Vector3(.398,.039,.291),paper.darkened(.11))
		for y in [.003,.046]:
			box(file,Vector3(0,y,0),Vector3(.412,.007,.303),Color("#a9875d").darkened(.045*(i%3)))
		box(file,Vector3(.02,.026,.157),Vector3(.28,.044,.009),paper)
		text_plate(file,Vector3(.02,.026,.163),months[i]+"  /  30",.031,INK)
	var accounts: Node3D = stage.joint(self,Vector3(-.16,1.012,.57))
	accounts.rotation.x = -1.04
	box(accounts,Vector3(0,.063,0),Vector3(.43,.19,.010),paper)
	text_plate(accounts,Vector3(0,.108,.009),"CITY PAYROLL",.038,INK)
	text_plate(accounts,Vector3(0,.041,.009),"JAN – JUN  /  2 EXAMINERS",.021,INK)
	narrator.lab_form = stage.joint(self,Vector3(.87,1.017,.31))
	var form: Node3D = narrator.lab_form
	box(form,Vector3(0,-.002,0),Vector3(.44,.015,.39),Color("#866b4d"))
	box(form,Vector3(0,.010,0),Vector3(.407,.009,.363),paper)
	var printface: Node3D = stage.joint(form,Vector3(0,.0155,0))
	printface.rotation.x = -PI/2
	text_plate(printface,Vector3(0,.116,0),"FINAL REVIEW",.044,INK)
	text_plate(printface,Vector3(0,.054,0),"PROOF 17   /   28 JUN 2030",.024,INK)
	for i in 3:
		box(printface,Vector3(-.105,-.020-i*.033,.001),Vector3(.124-.02*(i%2),.004,.001),Color("#959181"))
	var ink := text_plate(printface,Vector3(.074,-.075,.001),"VERIFIED",.030,Color("#924b3d"))
	ink.name = "Seal"
	narrator.lab_ink = ink
	var stamp: Node3D = stage.joint(self,Vector3.ZERO)
	stamp.name = "ExaminerStamp"
	narrator.lab_stamp = stamp
	box(stamp,Vector3(0,.010,0),Vector3(.147,.020,.071),Color("#443c35"))
	box(stamp,Vector3(0,.030,0),Vector3(.150,.020,.075),Color("#aa7d52"))
	rod(stamp,Vector3(0,.034,0),Vector3(0,.102,0),.023,steel)
	stage.round_part(stamp,Vector3(0,.106,0),Vector3(.080,.062,.073),Color("#80543d"))
	box(self,Vector3(1.105,1.025,.105),Vector3(.195,.043,.122),steel)
	box(self,Vector3(1.105,1.050,.105),Vector3(.161,.009,.093),Color("#76524c"))
	narrator.body.position = to_global(Vector3(.70,0,-.21))
	narrator.body.rotation.y = .16
	# Fold the individual fingers around the turned wooden handle. The rest of
	# the body still follows the same time-scrubbable block as the other actors.
	var hand = narrator.driver._rig
	var knuckles: Basis = hand.orient("L Hand") * hand.hand_offsets["L"].inverse()
	hand.fingers("L",knuckles,.77,.46)
	var colleague: Dictionary = stage.actors.front()
	colleague.body.position = to_global(Vector3(-1.05,0,-1.59))
	colleague.body.rotation.y = .12
	var pencil := rod(self,Vector3(-.93,.969,-1.145),Vector3(-.89,1.11,-1.17),.006,Color("#ab733e"))
	narrator.lab_pencil = pencil

func viaduct() -> void:
	box(self,Vector3(0,.06,4.24),Vector3(29,.12,1.6),Color("#46667a"))
	for j in range(19):
		box(self,Vector3(-11+j*1.24,.131,4.2+.51*sin(j*2.7)),Vector3(.68,.012,.043),MINT)
	for z in [2.42,3.2]:
		box(self,Vector3(0,.16,z),Vector3(25,.13,.07),INK)
	var train: Node3D = stage.moving_props[0]
	for x in [-1.97,1.97]:
		box(train,Vector3(x,.06,.591),Vector3(.34,.72,.042),INK)
		box(train,Vector3(x,.19,.622),Vector3(.23,.31,.021),MINT)
	for i in range(-3,4):
		box(train,Vector3(i*.44,.15,.588),Vector3(.057,.32,.038),GLASS)
	for x in [-1.61,1.61]:
		rod(train,Vector3(x,-.42,.4),Vector3(x,-.42,.64),.22,INK)
	for x in [-6.8,0,6.8]:
		box(self,Vector3(x,1.78,1.78),Vector3(.16,3.56,.16),GLASS)
		box(self,Vector3(x,3.54,2.48),Vector3(.15,.14,1.63),MINT)
	box(self,Vector3(0,3.59,2.80),Vector3(25,.04,.04),INK)
	dispatch = preload("res://office/dispatch.tscn").instantiate()
	dispatch.position = Vector3(60,0,0)
	add_child(dispatch)

func concourse() -> void:
	box(self,Vector3(2.52,3.09,-.1),Vector3(2.22,.59,.15),INK)
	text_plate(self,Vector3(2.52,3.09,-.014),"TRANSFERS  →",.165,AMBER)
	for i in range(-4,5):
		box(self,Vector3(i*1.6,.025,.91),Vector3(.65,.015,.096),IVORY.darkened(.46))
	stage.person(Vector3(2.02,0,.82),"ren","watch",-.78)
	narrator = stage.actors.back()
	gate = stage.joint(self,Vector3(2.34,0,.96))
	rod(gate,Vector3.ZERO,Vector3(0,1.09,0),.047,GLASS)
	for y in [.64,1.02]:
		rod(gate,Vector3(0,y,0),Vector3(0,y,-.94),.028,IVORY)
	for z in [-.24,-.54,-.91]:
		rod(gate,Vector3(0,.64,z),Vector3(0,1.02,z),.022,GLASS)
	stage.person(Vector3(1.2,0,1.02),"extra_b","watch",.64)
	visitor = stage.actors.back()
	sheets = stage.joint(self,Vector3(1.44,1.13,1.25))
	for i in 3:
		var slip := box(sheets,Vector3(i*.052,i*.006,-i*.025),Vector3(.17,.009,.245),IVORY.lightened(.025*i))
		slip.rotation.y = -.3+i*.37

func chamber() -> void:
	witness = stage.actors.back().body
	# A ring scanner and an enclosed cabinet make the conversion legible in silhouette.
	var pillar := Vector3(1.64,0,-.4)
	box(self,pillar+Vector3(0,1.24,0),Vector3(.65,2.48,.62),GLASS)
	for j in 8:
		box(self,pillar+Vector3(0,.25+j*.155,.325),Vector3(.43,.048,.025),INK)
	text_plate(self,pillar+Vector3(0,1.85,.34),"A/M\n"+stage.SCREENPLAY.BADGES[stage.profile].right(4),.11,AMBER)
	ring = stage.joint(self,Vector3.ZERO)
	var torus := TorusMesh.new()
	torus.inner_radius=.48
	torus.outer_radius=.51
	torus.rings=36
	torus.ring_segments=8
	scan = stage.model(ring,Vector3.ZERO,torus,MINT)
	var light := OmniLight3D.new()
	ring.add_child(light)
	light.light_color=Color("#9bebcd")
	light.light_energy=.95
	light.omni_range=2.0
	box(self,Vector3(0,.03,0),Vector3(1.3,.06,1.19),INK)
	stage.target = Vector3(.36,1.16,0)
	stage.eye = Vector3(1.8,1.6,3.85)

func terminal() -> void:
	# Amber function keys and punched vents repeat the earlier desk instrument.
	for i in 4:
		box(self,Vector3(.52,1.54-.09*i,.305),Vector3(.051,.046,.025),AMBER.darkened(.16*i))
	for j in 6:
		box(self,Vector3(-.49,1.19+.036*j,.305),Vector3(.048,.011,.018),GLASS)

func frame(t: float) -> void:
	if shot in [1,5]:
		private_memory.frame(t)
		return
	match shot:
		2:
			var copy := ["A cure for all.","Income for all.","An end to hunger."]
			readout.text = copy[mini(2,floori(t/4.8))]
		4:
			var finished := t >= 3.72
			var next_run := t >= 10.0
			readout.text = "NEXT DESIGN READY" if next_run else "PROOF COMPLETE" if finished else "SEARCHING"
			narrator.lab_elapsed.text = "ASTER 03    /    REVISION B" if next_run else "23:11   —   04:38" if finished else "START    23:11"
			var stamp: Node3D = narrator.lab_stamp
			var form: Node3D = narrator.lab_form
			# Its origin is the face of the rubber die. Both the die and the mark
			# share the form's plane for the five-frame compression of the handle.
			var parked := Vector3(1.105,1.055,.105)
			var sealed := to_local(form.to_global(Vector3(.074,.0165,.075)))
			var lift := smoothstep(8.98,9.62,t)
			var swing := smoothstep(9.25,10.47,t)
			var press := smoothstep(11.32,11.72,t)
			var release := smoothstep(11.99,12.46,t)
			var set_back := smoothstep(13.10,14.38,t)
			stamp.position = parked.lerp(sealed,swing).lerp(parked,set_back)
			stamp.position.y += .125*lift*(1.-press)+.112*release*(1.-set_back)
			stamp.rotation.y = -.13*(1.-swing)+.04*swing*(1.-set_back)
			narrator.lab_ink.visible = t >= 11.78
			var body: Node3D = narrator.body
			var noticing := smoothstep(2.7,4.2,t)*(1.-smoothstep(5.4,6.45,t))
			var watching := smoothstep(12.76,14.0,t)
			narrator.head.rotation = Vector3(.27-.35*noticing-.29*watching,-.10-.32*noticing-.36*watching,-.025)
			narrator.spine.rotation = Vector3(.047+.076*press*(1.-release),-.09,0)
			var grasp := smoothstep(7.85,9.02,t)*(1.-smoothstep(14.38,14.85,t))
			var own_edge := form.to_global(Vector3(-.106,.036,-.084))
			var resting := body.to_global(Vector3(.285,1.10,.20))
			var lever := stamp.to_global(Vector3(0,.114,.006))
			narrator.driver.hand_targets = {"L":resting.lerp(lever,grasp),"R":own_edge}
			reach(narrator,1,narrator.driver.hand_targets.L,body.to_global(Vector3(.35,1.15,.04)))
			reach(narrator,0,own_edge,body.to_global(Vector3(-.40,1.18,.07)))
			var colleague: Dictionary = stage.actors.front()
			var pencil: Node3D = narrator.lab_pencil
			pencil.position.x = -.91+.014*sin(t*2.1)
			colleague.driver.hand_targets = {
				"L":pencil.global_position+Vector3(0,.015,0),
				"R":to_global(Vector3(-1.15,1.005,-1.155))
			}
			for side in 2:
				var key := "L" if side == 1 else "R"
				reach(colleague,side,colleague.driver.hand_targets[key],colleague.body.to_global(Vector3(.39 if side==1 else -.39,1.19,.09)))
			colleague.head.rotation = Vector3(.31+.018*sin(.8*t),.13,.025)
			var cam: Vector3
			var look: Vector3
			if t < 3.72:
				cam = Vector3(-1.62+.105*t,1.86,2.86-.066*t)
				look = Vector3(-.04,1.47,-.65)
				stage.camera.fov = 45
			elif t < 6.45:
				cam = Vector3(.37,1.96,.13-.047*(t-3.72))
				look = Vector3(-.005,1.80,-2.19)
				stage.camera.fov = 34
			elif t < 9.85:
				cam = Vector3(.12-.022*(t-6.45),1.39,1.34)
				look = Vector3(-.095,1.105,.325)
				stage.camera.fov = 32
			elif t < 12.9:
				cam = Vector3(1.04,1.68,.99)
				look = Vector3(.91,1.075,.295)
				stage.camera.fov = 29
			else:
				cam = Vector3(.02+.028*(t-12.9),1.74,1.23)
				look = Vector3(.48,1.66,-.45)
				stage.camera.fov = 37
			stage.camera.position = to_global(cam)
			stage.camera.look_at(to_global(look))
		6:
			if (t>=1 and t<4.8) or t>=9.0:
				dispatch.frame(t-1.0 if t<4.8 else t)
				if not dispatch.camera.current:
					dispatch.camera.make_current()
			else:
				if not stage.camera.current:
					stage.camera.make_current()
				if t>=4.8:
					var carriage_x: float = stage.moving_props[0].position.x
					stage.camera.position = Vector3(carriage_x+2.6,1.54,7.75)
					stage.camera.look_at(Vector3(carriage_x-.32,.91,2.68))
		7:
			var open := smoothstep(8.0,9.5,t)
			var fall := smoothstep(8.05,8.78,t)
			var retrieve := smoothstep(10.65,11.78,t)
			var stoop := smoothstep(8.65,10.42,t)*(1.0-retrieve)
			visitor.spine.rotation.x = .96*stoop
			visitor.spine.position.y = .91-.65*stoop
			visitor.head.rotation.x = .35*stoop
			visitor.arms[1].rotation.x = -.16-1.03*stoop
			sheets.position.y = lerpf(1.05,.046,fall)+.98*retrieve
			sheets.position.z = 1.25+.18*fall
			sheets.rotation.z = .36*sin(fall*PI)
			sheets.rotation.x = -.52*(1.-fall)-.46*retrieve
			var holding := 1.-smoothstep(8.05,8.30,t)+smoothstep(8.65,10.42,t)
			var left_elbow: Node3D = visitor.arms[1].get_node("Elbow")
			var right_elbow: Node3D = visitor.arms[0].get_node("Elbow")
			var paper_edge := sheets.to_global(Vector3(.04,.018,-.065))
			var knee_support: Vector3 = visitor.body.to_global(Vector3(-.19,.23,.31))
			visitor.driver.hand_targets = {
				"L": left_elbow.to_global(Vector3(0,-.36,0)).lerp(paper_edge,holding),
				"R": right_elbow.to_global(Vector3(0,-.36,0)).lerp(knee_support,stoop)
			}
			for person in stage.actors:
				if person.pose == "walk" and person.start.y<1.0 and t>8.75:
					person.body.position = person.start+Vector3(8.75*.48,0,0)
					for leg in person.legs:
						leg.rotation.x = 0
					for knee in person.knees:
						knee.rotation.x = 0
			gate.rotation.y = -1.35*open
			narrator.arms[1].rotation.x = -.38-.92*open
			narrator.head.rotation.y = .34-.78*open
			if t>7.5:
				stage.camera.position = Vector3(.12,1.58,4.05)
				stage.camera.look_at(Vector3(1.73,1.05-.35*stoop,.76))
		8:
			var progress := smoothstep(3.9,5.55,t)
			var lead_actor: Dictionary = stage.actors.back()
			var keepsake: Node3D = stage.moving_props[0]
			var drop := smoothstep(5.20,5.84,t)
			keepsake.position = Vector3(.21,lerpf(1.31,.08,drop),.26)
			keepsake.rotation = Vector3(lerpf(1.19,0,drop),-.19,.05+.14*drop)
			for side in 2:
				var direction := -1 if side == 0 else 1
				var edge := Vector3(.21+direction*.115,1.30,.29)
				reach(lead_actor,side,edge,Vector3(direction*.46,1.09,.16))
			lead_actor.head.rotation.x = .14-.29*smoothstep(.7,3.1,t)
			lead_actor.head.rotation.y = -.21-.28*smoothstep(.7,3.1,t)
			if t < 3.65:
				stage.camera.position = Vector3(.88,1.69,1.74-.035*t)
				stage.camera.look_at(Vector3(.09,1.58,.13))
			ring.position.y = lerpf(2.26,.12,progress)
			ring.visible = t>3.65 and t<5.75
			witness.visible = t<5.42
			# Hold on the dropped notebook after the person has gone.
			if t>6.05:
				stage.camera.position = Vector3(1.13,.83,1.62)
				stage.camera.look_at(Vector3(.21,.10,.26))
