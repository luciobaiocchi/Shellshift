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
var paperwork: Node3D
var daughter: Dictionary
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
		3: discharge()
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

func discharge() -> void:
	stage.key.light_energy = .61
	stage.camera.environment.ambient_light_energy = .61
	box(self,Vector3(0,1.47,-2.02),Vector3(8.8,2.95,.3),Color("#969d8f"))
	for x in [-3.73,-2.45,2.45,3.73]:
		box(self,Vector3(x,1.8,-1.84),Vector3(1.08,1.48,.06),GLASS)
		box(self,Vector3(x,1.71,-1.79),Vector3(1.08,.045,.04),IVORY)
		box(self,Vector3(x,1.8,-1.79),Vector3(.04,1.48,.04),IVORY)
	box(self,Vector3(0,1.08,-1.79),Vector3(2.43,2.16,.12),INK)
	for x in [-.59,.59]:
		box(self,Vector3(x,.99,-1.70),Vector3(1.14,1.94,.07),MINT)
		box(self,Vector3(x,1.44,-1.65),Vector3(.81,.7,.04),GLASS)
		box(self,Vector3(x,.9,-1.61),Vector3(.84,.045,.05),IVORY)
	box(self,Vector3(0,2.45,-1.69),Vector3(3.1,.45,.12),GLASS)
	text_plate(self,Vector3(0,2.45,-1.615),"WARD   /   EXIT",.17)
	for x in [-1.9,1.9]:
		rod(self,Vector3(x,.02,-1),Vector3(x,.69,-1),.068,GLASS)
	box(self,Vector3(1.45,.26,.1),Vector3(.41,.46,.24),COPPER)
	rod(self,Vector3(1.34,.55,.10),Vector3(1.55,.55,.10),.023,INK)
	for x in [1.34,1.55]:
		rod(self,Vector3(x,.47,.10),Vector3(x,.55,.1),.016,INK)
	# The same brass pin is visible when Mara keeps a seat for Ada at the dome.
	narrator = stage.actors.back()
	daughter = stage.actors[0]
	box(narrator.spine,Vector3(.12,.44,.16),Vector3(.055,.023,.012),AMBER)
	paperwork = stage.joint(narrator.arms[0].get_node("Elbow"),Vector3(.008,-.368,.045))
	box(paperwork,Vector3.ZERO,Vector3(.157,.087,.004),IVORY)
	box(paperwork,Vector3(0,.033,.003),Vector3(.157,.013,.003),COPPER)
	text_plate(paperwork,Vector3(0,.004,.004),"RETURN",.019,INK)
	for i in 7:
		box(paperwork,Vector3(-.058+i*.013,-.021,.004),Vector3(.005,.012,.002),INK)
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

func reunion(t: float) -> void:
	var arrival := smoothstep(.7,3.0,t)
	var close := smoothstep(5.0,6.7,t)
	var embrace := smoothstep(10.3,12.05,t)
	var settle := smoothstep(12.0,13.6,t)
	daughter.body.position = Vector3(lerpf(-.95,-.59,arrival)+.14*close+.27*embrace,0,.04+.23*embrace)
	narrator.body.position = Vector3(lerpf(.82,.54,arrival)-.12*close-.24*embrace,0,lerpf(-.32,0,arrival)-.08*embrace)
	daughter.spine.position.y = .91-.10*embrace
	daughter.body.rotation.y = 1.10+.34*embrace
	narrator.body.rotation.y = -1.06-.40*embrace
	daughter.head.rotation = Vector3(.055-.21*close+.51*embrace,.28-.49*embrace,.05+.22*embrace)
	narrator.head.rotation = Vector3(.10+.13*close-.24*embrace,-.32+.31*embrace,-.035-.13*embrace)
	for lip: MeshInstance3D in daughter.lips:
		lip.set_blend_shape_value(0,.73*arrival-.47*embrace)
	for lip: MeshInstance3D in narrator.lips:
		lip.set_blend_shape_value(0,.47*arrival+.25*settle)
	var ticket_hand: Vector3 = narrator.body.position+Vector3(-.19,1.20,.02)
	reach(narrator,0,ticket_hand,narrator.body.position+Vector3(.09,1.10,-.36))
	paperwork.global_rotation = Vector3(-.16,.29,.11)
	var collar: Vector3 = daughter.spine.to_global(Vector3(-.13,.55,.15))
	var hand: Vector3 = narrator.body.position + Vector3(-.10,.94,.29)
	hand = hand.lerp(collar+Vector3(0,.014*sin(t*3.5),0),close)
	hand = hand.lerp(daughter.body.position+Vector3(-.065,1.41,.24),embrace)
	reach(narrator,1,hand,narrator.body.position+Vector3(-.22,1.15,.38))
	for side in 2:
		var sign_x := -1.0 if side==0 else 1.0
		var rest: Vector3 = daughter.body.to_global(Vector3(sign_x*.27,.91,.12))
		var wrap: Vector3 = narrator.body.to_global(Vector3(sign_x*.19,1.36,-.13))
		reach(daughter,side,rest.lerp(wrap,embrace),daughter.body.to_global(Vector3(sign_x*.35,1.19,.22)))
	if t < 2.8:
		return
	if t < 5.7:
		var slip := paperwork.global_position
		stage.camera.position = slip + Vector3(-.14,.10,.49)
		stage.camera.look_at(slip)
	elif t < 10.3:
		stage.camera.position = Vector3(.13,1.72,1.80-.018*(t-5.7))
		stage.camera.look_at(Vector3(-.03,1.65,.045))
	else:
		stage.camera.position = Vector3(.59,1.68,1.85)
		stage.camera.look_at(Vector3(0,1.52,.11))

func laboratory() -> void:
	for i in 3:
		var rack: Node3D = stage.joint(self,Vector3(4.85+i*.78,0,-1.7))
		box(rack,Vector3(0,1.24,0),Vector3(.74,2.48,.52),INK)
		for row in 9:
			var y := .23+.235*row
			box(rack,Vector3(0,y,.277),Vector3(.63,.194,.03),GLASS)
			box(rack,Vector3(-.12,y,.30),Vector3(.23,.025,.015),INK)
			box(rack,Vector3(.24,y,.30),Vector3(.036,.029,.016),AMBER if row%3==0 else MINT)
	board = stage.joint(self,Vector3(.18,2.35,-2.05))
	box(board,Vector3.ZERO,Vector3(3.7,1.54,.12),INK)
	box(board,Vector3(0,0,.07),Vector3(3.54,1.39,.03),GLASS.darkened(.37))
	text_plate(board,Vector3(0,.42,.10),"RESEARCH   /   LAB 09",.14,IVORY)
	readout = text_plate(board,Vector3(0,-.1,.10),"SEARCH IN PROGRESS",.19,AMBER)
	narrator = stage.actors.back()
	var strap := box(narrator.spine,Vector3(-.11,.396,.154),Vector3(.036,.28,.016),COPPER)
	strap.rotation.z = -.26
	box(narrator.spine,Vector3(-.08,.244,.17),Vector3(.104,.077,.016),IVORY)
	# The rubber stamp moves with the reviewer's palm, down once onto the paper.
	var stamp_hand: Node3D = narrator.arms[1].get_node("Elbow")
	box(stamp_hand,Vector3(0,-.395,.044),Vector3(.144,.045,.094),COPPER)
	rod(stamp_hand,Vector3(0,-.395,.044),Vector3(0,-.337,.044),.025,INK)
	box(self,Vector3(.92,.952,.10),Vector3(.49,.02,.39),IVORY)

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
	stage.person(Vector3(2.02,0,.82),Color("#62667e"),INK,"watch",-.78)
	narrator = stage.actors.back()
	box(narrator.spine,Vector3(.13,.437,.16),Vector3(.12,.067,.015),AMBER)
	gate = stage.joint(self,Vector3(2.34,0,.96))
	rod(gate,Vector3.ZERO,Vector3(0,1.09,0),.047,GLASS)
	for y in [.64,1.02]:
		rod(gate,Vector3(0,y,0),Vector3(0,y,-.94),.028,IVORY)
	for z in [-.24,-.54,-.91]:
		rod(gate,Vector3(0,.64,z),Vector3(0,1.02,z),.022,GLASS)
	stage.person(Vector3(1.2,0,1.02),stage.WOOD,GLASS,"watch",.64)
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
		3:
			reunion(t)
		4:
			readout.text = "PROOF COMPLETE" if t>3.7 else "SEARCH IN PROGRESS"
			var review := smoothstep(5.2,7.0,t)
			narrator.head.rotation.x = -.08+.32*review
			narrator.body.rotation.y = -.8-.7*review
			narrator.arms[1].rotation.x = -.69-.57*review+.55*(smoothstep(11.4,11.76,t)-smoothstep(11.82,12.15,t))
			if t>6.4:
				stage.camera.position = Vector3(1.5,2.4,2.05-.035*(t-6.4))
				stage.camera.look_at(Vector3(.15,2.28,-1.9))
			if t>9.85:
				stage.camera.position = Vector3(-.91,1.57,2.54)
				stage.camera.look_at(Vector3(.89,1.46,.60))
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
			visitor.spine.position.y = .91-.22*stoop
			visitor.body.get_node("Trousers").scale.y = 1.0-.22*stoop
			visitor.head.rotation.x = .35*stoop
			visitor.arms[1].rotation.x = -.16-1.03*stoop
			sheets.position.y = lerpf(1.05,.046,fall)+.98*retrieve
			sheets.position.z = 1.25+.18*fall
			sheets.rotation.z = .36*sin(fall*PI)
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
