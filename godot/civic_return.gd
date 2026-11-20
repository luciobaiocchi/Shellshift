extends Node3D
## Two visits to the same rent window. The second keeps the countertop and adds a shutter.
const COUNTER := preload("res://civic_counter.gd")
const REACH := preload("res://prologue_art.gd")
const ENAMEL := Color("#637b74")
const GASKET := Color("#293538")
const PAPER := Color("#e3d3b1")
const INK := Color("#38444b")
const AMBER := Color("#e4ae60")
const BRASS := Color("#9c8058")
const OXIDE := Color("#975d42")
const BUS := Vector3(24,0,0)

var stage
var hall
var posing := REACH.new()
var late := false
var transfer_screen: Label3D
var heading: Label3D
var renewal: Label3D
var sheets: Array[Node3D] = []
var letter: Node3D
var basket: Node3D
var basket_handle: Vector3
var receipt: Node3D
var lock_key: Node3D
var streets: Node3D
var scan_light: MeshInstance3D
var transfer_lamp: MeshInstance3D
var street_set: Node3D
var rosa: Dictionary
var mother: Dictionary
var clerk: Dictionary
var shutter: Node3D
var roster_text: Label3D

func build(host, is_last: bool) -> void:
	stage = host
	add_child(posing)
	late = is_last
	hall = COUNTER.new()
	add_child(hall)
	hall.build(stage)
	hall.frame(17.7)
	rosa = hall.rosa
	mother = hall.mother
	clerk = hall.clerk
	hall.tickets.hide()
	for extra in hall.bystanders:
		extra.body.hide()
	for panel in hall.shutters:
		panel.hide()
	hall.shutters[0].visible = late
	hall.shutters[0].position.y = -.25
	for slat in hall.shutters[0].get_children():
		slat.show()
	hall.public_chair.position = Vector3(-2.0,0,.1)
	hall.bus.position.x = 3.48
	hall.number_boards[1].text = "—" if late else "01"
	mother.body.visible = not late
	var reader := stage.joint(self,Vector3(.11,0,-.42)) as Node3D
	reader.name = "Aster"
	terminal(reader)
	if late:
		closed_window()
		make_address()
	else:
		var in_tray := box(self,Vector3(-.60,1.166,-.375),Vector3(.71,.045,.37),INK)
		for side in [-1,1]:
			box(in_tray,Vector3(0,.028,side*.177),Vector3(.71,.052,.018),ENAMEL)
		for i in 7:
			var page := stage.joint(self,Vector3.ZERO) as Node3D
			sheets.append(page)
			box(page,Vector3.ZERO,Vector3(.41,.008,.29),PAPER.darkened(.03*(i%3)))
			box(page,Vector3(-.095,.006,-.103),Vector3(.16,.003,.023),ENAMEL)
			for j in 3:
				box(page,Vector3(-.01,.006,-.055+.032*j),Vector3(.30-.04*(j%2),.003,.009),BRASS)
		basket = make_basket()
		bus_interior()
	stage.key.visible = true
	stage.key.rotation_degrees = Vector3(-47,-33,0)
	stage.key.light_energy = .49 if late else .78
	stage.key.light_color = Color("#d5d6d0") if late else Color("#ffe6c9")
	stage.camera.environment.ambient_light_energy = .59 if late else .73
	stage.camera.environment.fog_enabled = late
	stage.camera.environment.fog_density = .011 if late else .003
	if late:
		stage.camera.environment.background_color = Color("#81918f")
		for lamp in hall.get_children():
			if lamp is OmniLight3D:
				lamp.light_color = Color("#b4c2ba")
				lamp.light_energy *= .41
	stage.camera.current = true
	frame(0)

func box(parent: Node3D, pos: Vector3, dims: Vector3, dye: Color) -> MeshInstance3D:
	return stage.block(parent,pos,dims,dye)

func rod(parent: Node3D, a: Vector3, b: Vector3, radius: float, dye: Color) -> MeshInstance3D:
	var mesh := CylinderMesh.new()
	mesh.radial_segments = 8
	mesh.rings = 0
	mesh.top_radius = radius
	mesh.bottom_radius = radius
	mesh.height = a.distance_to(b)
	var part: MeshInstance3D = stage.model(parent,(a+b)*.5,mesh,dye)
	part.quaternion = Quaternion(Vector3.UP,a.direction_to(b))
	return part

func label(parent: Node3D, pos: Vector3, value: String, size_m: float, tone: Color) -> Label3D:
	var text := Label3D.new()
	parent.add_child(text)
	text.position = pos
	text.font_size = 52
	text.pixel_size = size_m/52
	text.outline_size = 0
	text.modulate = tone
	text.text = value
	return text

func terminal(parent: Node3D) -> void:
	box(parent,Vector3(.18,1.11,-.05),Vector3(1.34,.13,.6),GASKET)
	# The glass face, green transfer light and brass acceptance key remain for twenty years.
	var screen := stage.joint(parent,Vector3(.40,1.50,-.073)) as Node3D
	box(screen,Vector3.ZERO,Vector3(.85,.62,.22),ENAMEL.darkened(.20))
	box(screen,Vector3(0,.012,.115),Vector3(.76,.52,.024),GASKET)
	heading = label(screen,Vector3(0,.185,.133),"ASTER  /  CIVIC DESK",.044,PAPER)
	transfer_screen = label(screen,Vector3(0,.01,.135),"",.055,AMBER)
	box(screen,Vector3(-.22,-.196,.136),Vector3(.19,.008,.005),ENAMEL)
	transfer_lamp = box(screen,Vector3(.30,-.196,.136),Vector3(.033,.024,.009),AMBER)
	box(parent,Vector3(-.33,1.245,-.04),Vector3(.33,.18,.31),ENAMEL)
	box(parent,Vector3(-.33,1.25,.123),Vector3(.27,.019,.012),GASKET)
	scan_light = box(parent,Vector3(-.33,1.29,.12),Vector3(.17,.012,.013),AMBER)
	var pad := stage.joint(parent,Vector3(.38,1.19,.246)) as Node3D
	pad.rotation.x = -.94
	box(pad,Vector3.ZERO,Vector3(.48,.17,.055),INK)
	box(pad,Vector3(.16,0,.03),Vector3(.075,.095,.012),BRASS)
	renewal = label(pad,Vector3(-.05,.001,.035),"RENEW",.036,PAPER)
	receipt = stage.joint(self,Vector3.ZERO)
	box(receipt,Vector3.ZERO,Vector3(.225,.255,.007),PAPER)
	label(receipt,Vector3(0,.078,.005),"CIVIC  /  02",.027,INK)
	label(receipt,Vector3(0,-.002,.005),"HUMAN REVIEW\nCONTINUITY" if late else "PAID TODAY",.020,INK)
	for i in 9:
		box(receipt,Vector3(-.068+i*.016,-.087,.006),Vector3(.006+.001*(i%3),.025,.003),INK)

func make_basket() -> Node3D:
	var crate := stage.joint(self,Vector3.ZERO) as Node3D
	box(crate,Vector3.ZERO,Vector3(.43,.055,.28),BRASS.darkened(.34))
	for side in [-1,1]:
		for y in [.054,.125,.183]:
			box(crate,Vector3(0,y,side*.14),Vector3(.43,.042,.03),OXIDE.lightened(.08*y))
			box(crate,Vector3(side*.21,y,0),Vector3(.024,.042,.27),OXIDE)
		rod(crate,Vector3(side*.198,.17,0),Vector3(side*.15,.38,0),.011,GASKET)
	box(crate,Vector3(0,.38,0),Vector3(.30,.027,.026),BRASS)
	basket_handle = Vector3(0,.38,0)
	var loaf: Node3D = stage.round_part(crate,Vector3(-.074,.192,-.041),Vector3(.16,.19,.26),Color("#b5895b"))
	loaf.rotation.x = -.31
	# Two pears ride home in the same basket at the end of the scene.
	for i in 2:
		var x := .005+i*.115
		var base := Vector3(x,.183,.074)
		var skin: Color = [Color("#c7a451"),Color("#999b53")][i]
		stage.round_part(crate,base,Vector3(.101,.126,.10),skin)
		stage.round_part(crate,base+Vector3(-.009,.051,0),Vector3(.064,.083,.062),skin)
		rod(crate,base+Vector3(-.008,.082,0),base+Vector3(-.022,.113,.003),.005,BRASS.darkened(.35))
	var milk := box(crate,Vector3(.128,.234,-.044),Vector3(.085,.186,.078),PAPER)
	milk.rotation.z = -.12
	box(milk,Vector3(0,.029,0),Vector3(.087,.065,.081),ENAMEL)
	return crate

func closed_window() -> void:
	shutter = stage.joint(self,Vector3(-.43,1.10,-.76))
	box(shutter,Vector3(-.31,.91,0),Vector3(1.85,1.79,.12),GASKET)
	for i in 14:
		box(shutter,Vector3(-.31,.071+i*.122,.078),Vector3(1.80,.112,.042),Color("#596665").darkened(.025*(i%3)))
	box(shutter,Vector3(-.31,.048,.109),Vector3(1.8,.075,.062),INK)
	box(shutter,Vector3(-.54,1.18,.110),Vector3(1.18,.34,.019),INK)
	roster_text = label(shutter,Vector3(-.54,1.18,.126),"COUNTER CLOSED\nNO LOCAL REVIEW",.083,PAPER)
	var keyhole := Vector3(-1.25,1.51,-.59)
	box(self,keyhole,Vector3(.099,.144,.03),BRASS)
	lock_key = stage.joint(self,keyhole+Vector3(0,0,.014))
	rod(lock_key,Vector3.ZERO,Vector3(0,0,.135),.012,BRASS.lightened(.3))
	rod(lock_key,Vector3(0,0,.136),Vector3(.059,0,.162),.013,BRASS.lightened(.32))
	var bow := TorusMesh.new()
	bow.rings = 12
	bow.ring_segments = 5
	bow.inner_radius = .029
	bow.outer_radius = .049
	var loop: Node3D = stage.model(lock_key,Vector3(.079,0,.162),bow,BRASS.lightened(.26))
	loop.rotation.x = PI*.5
	box(lock_key,Vector3(.021,0,.010),Vector3(.04,.018,.035),BRASS)
	hall.bus.hide()

func make_address() -> void:
	letter = stage.joint(self,Vector3.ZERO)
	box(letter,Vector3.ZERO,Vector3(.297,.206,.008),PAPER)
	box(letter,Vector3(0,.065,.005),Vector3(.297,.047,.002),ENAMEL)
	label(letter,Vector3(0,.066,.008),"CHANGE OF ADDRESS",.020,PAPER)
	label(letter,Vector3(0,-.002,.008),"MOTHER'S FILE\n14  LARCH ROAD",.023,INK)
	for i in 3:
		box(letter,Vector3(-.047+i*.045,-.070,.006),Vector3(.032,.012,.003),OXIDE)

func bus_interior() -> void:
	street_set = stage.joint(self,BUS)
	box(street_set,Vector3(0,-.07,0),Vector3(3,.13,3.0),GASKET)
	box(street_set,Vector3(0,.57,-.59),Vector3(4,1.15,.14),ENAMEL)
	box(street_set,Vector3(0,2.35,-.59),Vector3(4,.36,.14),ENAMEL)
	box(street_set,Vector3(0,2.50,0),Vector3(4,.13,2.4),PAPER.darkened(.25))
	for x in [-1.55,.22,1.55]:
		box(street_set,Vector3(x,1.655,-.59),Vector3(.059,1.10,.15),PAPER)
	for x in [-.58,.29]:
		box(street_set,Vector3(x,.48,0),Vector3(.7,.15,.53),GASKET)
		var seat_back := box(street_set,Vector3(x,.81,-.22),Vector3(.7,.65,.11),OXIDE.darkened(.15))
		seat_back.rotation.x = -.11
	for x in [-1.15,.93]:
		rod(street_set,Vector3(x,.16,.02),Vector3(x,2.44,.02),.025,BRASS)
	rod(street_set,Vector3(-1.55,1.10,-.47),Vector3(1.56,1.10,-.47),.024,BRASS)
	var sign := box(street_set,Vector3(-.85,2.23,-.47),Vector3(1.0,.19,.022),GASKET)
	label(sign,Vector3(0,0,.015),"12  /   RIVERSIDE",.076,AMBER)
	var fill := OmniLight3D.new()
	street_set.add_child(fill)
	fill.position = Vector3(-.2,1.76,.98)
	fill.light_color = Color("#e9d2b5")
	fill.light_energy = .44
	fill.light_specular = 0
	fill.omni_range = 4.2
	fill.omni_attenuation = 1.3
	streets = stage.joint(street_set,Vector3(0,0,-4.5))
	for i in 11:
		var b := box(streets,Vector3(-9+i*1.8,1.12,-.28*(i%3)),Vector3(1.77,2.55+.27*(i%3),1.12),[Color("#9b8b7b"),Color("#777f76"),Color("#b79b7d")][i%3])
		for j in 2:
			box(b,Vector3(-.42+.84*j,.52,.57),Vector3(.49,.70,.032),Color("#596d6f"))

func camera(eye: Vector3, at: Vector3, lens := 38.0) -> void:
	stage.camera.current = true
	stage.camera.fov = lens
	stage.camera.position = eye
	stage.camera.look_at(at)

func pose(actor: Dictionary, at: Vector3, yaw: float, glance: Vector3) -> void:
	actor.body.position = at
	actor.body.rotation.y = yaw
	actor.spine.rotation = Vector3.ZERO
	actor.head.rotation = glance
	for upper: Node3D in actor.arms:
		upper.rotation = Vector3.ZERO
		upper.get_node("Elbow").rotation = Vector3(-.26,0,0)

func hand(actor: Dictionary, side: int, target: Vector3) -> void:
	var direction := -1.0 if side == 0 else 1.0
	var elbow: Vector3 = actor.body.to_global(Vector3(direction*.39,1.12,.11))
	posing.reach(actor,side,target,elbow)

func smile(actor: Dictionary, ease: float) -> void:
	for lips: MeshInstance3D in actor.lips:
		lips.set_blend_shape_value(lips.find_blend_shape_by_name("Smile"),ease)

func frame(t: float) -> void:
	# Riding places the pelvis on the seat in the authored root translation.
	for actor in [rosa,mother]:
		actor.driver.seated = not late and t >= 16.55
		actor.driver.seat_drop = 0.0
	if late:
		closing(t)
	else:
		good_year(t)

func good_year(t: float) -> void:
	var choice := smoothstep(11.32,12.26,t)*(1.0-smoothstep(13.0,13.84,t))
	var pick_up := smoothstep(7.3,9.0,t)
	var leaving := smoothstep(14.0,16.55,t)
	var collect := smoothstep(6.8,8.6,t)
	var toward_bus := Vector3(1.47,0,.66)*leaving
	pose(rosa,Vector3(.09,0,.21)+toward_bus,2.66-1.50*leaving,Vector3(.17-.12*pick_up,-.08+.30*pick_up,0))
	pose(mother,Vector3(-.75,0,.69)+toward_bus,.99+.44*leaving,Vector3(.04,.27-.30*leaving,-.055))
	pose(clerk,Vector3(-.81,0,-1.29),.31,Vector3(.17-.14*collect,.17*collect,0))
	smile(rosa,.49*pick_up)
	smile(mother,.38*pick_up)
	var front := Vector3(-1.36,1.105,-.77).lerp(Vector3(-.405,1.105,-.26),smoothstep(5.70,7.0,t))
	var grip := Vector3(-.39,1.02+.037*sin(t*2),.11)+toward_bus
	basket.position = front.lerp(grip-basket_handle,collect)
	hand(rosa,1,(rosa.body.to_global(Vector3(.30,.89,.12)) as Vector3).lerp(basket.position+basket_handle,collect))
	hand(mother,1,mother.body.to_global(Vector3(.27,.91,.11)).lerp(grip+Vector3(-.13,-.17,.12),collect*(1.0-leaving)))
	var rest: Vector3 = rosa.body.to_global(Vector3(-.28,.90,.15))
	hand(rosa,0,rest.lerp(Vector3(.65,1.22,-.18),choice))
	hand(clerk,1,(clerk.body.to_global(Vector3(.28,.96,.17)) as Vector3).lerp(front+Vector3(-.10,.20,-.08),1.0-smoothstep(7.0,8.0,t)))
	receipt.visible = t>=4.87
	receipt.position = Vector3(-.22,1.25,-.286)+Vector3(0,-.068,.127)*smoothstep(4.90,5.65,t)
	receipt.rotation.x = -1.30
	for i in sheets.size():
		var u := smoothstep(.36+i*.41,1.52+i*.41,t)
		var start := Vector3(-.72,1.195+(6-i)*.009,-.37)
		sheets[i].position = start.lerp(Vector3(-.22,1.26,-.41),u)+Vector3(0,.044*sin(PI*u),0)
		sheets[i].rotation.y = lerpf(-.13+.024*(i%4),0,u)
		sheets[i].visible = u<.98
	transfer_lamp.visible = t>4.20 or fmod(t,.53)<.27
	scan_light.visible = t<4.25 and fmod(t,.33)<.20
	heading.text = "ASTER  /  CIVIC DESK"
	if t<4.25:
		transfer_screen.text = "MATCHING RECORDS\n%02d  /  28" % roundi(28*smoothstep(.3,4.17,t))
	elif t<9.75:
		transfer_screen.text = "RENT  /  PAID\nFOOD  /  RELEASED"
	elif t<12.35:
		transfer_screen.text = "NEXT MONTH\nRENEW FOR ME?"
	else:
		transfer_screen.text = "NEXT MONTH\nRENEWAL ON"
	renewal.text = "ACCEPTED" if t>=12.35 else "ACCEPT"
	if t<4.35:
		camera(Vector3(-.55,1.91,.16+.012*t),Vector3(-.12,1.36,-.47),52)
	elif t<7.0:
		camera(Vector3(.78,1.78,1.30),Vector3(.30,1.42,-.41),38)
	elif t<10.10:
		camera(Vector3(-1.26,1.49,-.19),Vector3(-.39,.91,.10),39)
	elif t<14.10:
		camera(Vector3(1.24,1.73,.65),Vector3(.49,1.41,-.37),41)
	elif t<16.55:
		camera(Vector3(2.46,1.76,2.40),Vector3(.38+.72*leaving,1.31,.24),44)
	else:
		riding(t-16.55)

func riding(t: float) -> void:
	var roll := sin(t*3.3)*.024
	pose(rosa,BUS+Vector3(.29,-.35,.07),-.24,Vector3(.10-.075*sin(t),-.35,roll))
	pose(mother,BUS+Vector3(-.58,-.38,.09),.24,Vector3(.08,.39-.66*smoothstep(.75,2.55,t),-roll))
	smile(rosa,.64)
	smile(mother,.46)
	basket.position = BUS+Vector3(-.12,.70,.34)
	hand(rosa,1,BUS+Vector3(.47,.72,.40))
	hand(mother,0,BUS+Vector3(-.80,.63,.40))
	var between := BUS+Vector3(-.13,1.02,.42)
	hand(rosa,0,between)
	hand(mother,1,between+Vector3(-.035,-.017,.02))
	streets.position.x = 1.3*t
	camera(BUS+Vector3(.16,1.52,.0)+Vector3(-.20*t,0,2.75),BUS+Vector3(-.14,1.47,-.13),43)

func closing(t: float) -> void:
	var ask := smoothstep(.25,2.85,t)
	var give_up := smoothstep(9.2,10.55,t)
	var submit := smoothstep(10.1,12.4,t)
	pose(rosa,Vector3(-.29,0,.18),-2.74+.40*submit,Vector3(.07+.24*give_up,-.32+.75*submit,-.04))
	pose(clerk,Vector3(-1.53,0,-.21),2.61,Vector3(.10+.26*give_up,-.29,.05*give_up))
	key_attempt(t,give_up)
	smile(rosa,0.0)
	mother.body.hide()
	var offered := Vector3(-.57,1.38,-.23)
	var place := Vector3(-.22,1.32,-.248)
	var file_hand: Vector3 = rosa.body.to_global(Vector3(.28,.95,.16)).lerp(offered,ask).lerp(place,submit)
	hand(rosa,1,file_hand)
	letter.position = file_hand+Vector3(0,.055,0)
	letter.rotation = Vector3(-.11-.96*submit,-.11,0)
	letter.position = letter.position.lerp(Vector3(-.22,1.24,-.40),smoothstep(12.4,13.64,t))
	letter.visible = t<13.6
	heading.text = "ASTER  /  REFERRALS"
	if t<10.5:
		transfer_screen.text = "PRESENT\nADDRESS FORM"
	elif t<13.85:
		transfer_screen.text = "READING\nAMENDMENT"
	else:
		transfer_screen.text = "HUMAN REVIEW\nROUTED TO\nCONTINUITY"
	renewal.text = "RECEIPT"
	transfer_lamp.visible = t>=13.85
	scan_light.visible = submit>0 and t<13.64 and fmod(t,.31)>.13
	receipt.visible = t>=14.0
	receipt.position = Vector3(-.22,1.25,-.286)+Vector3(0,-.12,.13)*smoothstep(14.0,15.24,t)
	receipt.rotation.x = -1.27+.68*smoothstep(14.0,15.24,t)
	if t<4.85:
		camera(Vector3(1.63,1.91,2.60-.05*t),Vector3(-.53,1.51,-.31),40)
	elif t<8.55:
		camera(Vector3(-.91,1.68,.22),Vector3(-1.26,1.46,-.52),34)
	elif t<10.60:
		camera(Vector3(-1.04,1.82,1.53),Vector3(-.94,1.58,-.17),40)
	elif t<13.92:
		camera(Vector3(.37,1.88,.22),Vector3(-.24,1.36,-.27),41)
	else:
		camera(Vector3(.50,1.44,.72-.043*(t-13.9)),Vector3(.45,1.43,-.43),37)

func key_attempt(t: float, withdraw: float) -> void:
	var turn := smoothstep(5.55,6.30,t)-smoothstep(6.65,7.30,t)
	var try_again := smoothstep(7.32,7.78,t)-smoothstep(8.0,8.45,t)
	var center := Vector3(-1.25,1.51,-.59)
	var reach_key := smoothstep(4.55,5.30,t)*(1.0-withdraw)
	var grip: Vector3 = clerk.body.to_global(Vector3(-.23,.96,.12)).lerp(center+Vector3(0,0,.15),reach_key)
	hand(clerk,0,grip)
	lock_key.position = grip+Vector3(0,0,-.135)
	lock_key.rotation.z = .46*turn+.32*try_again
	shutter.position.y = 1.10+.009*turn+.006*try_again
