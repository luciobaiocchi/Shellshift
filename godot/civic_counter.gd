extends Node3D
## 2024. The two queues and the departing evening bus share one address.
const IRON := Color("#33434b")
const TILE := Color("#748c83")
const PAINT := Color("#b5ac92")
const CREAM := Color("#f1deb3")
const INK := Color("#213a40")
const OAK := Color("#ab7853")
const BRASS := Color("#bf9255")
const RED := Color("#ad604c")
const WINDOW := Color("#708996")

var stage
var counter_root: Node3D
var rosa: Dictionary
var mother: Dictionary
var clerk: Dictionary
var bystanders: Array[Dictionary] = []
var tickets: Node3D
var shutters: Array[Node3D] = []
var clock: Node3D
var bus: Node3D
var number_boards: Array[Label3D] = []
var clock_minute: Node3D
var clock_second: Node3D
var ticket_fan: Node3D
var rent_number: Node3D
var bell: Node3D

func build(host) -> void:
	stage = host
	stage.key.visible = true
	stage.key.light_energy=.39
	stage.key.light_color=Color("#c9c4d7")
	stage.camera.environment.fog_enabled=false
	stage.camera.environment.ambient_light_energy=.41
	stage.camera.environment.background_color=Color("#78748a")
	_hall()
	_street()
	_cast()
	frame(0)

func joint(parent: Node3D,p: Vector3) -> Node3D:
	return stage.joint(parent,p)

func box(parent: Node3D,p: Vector3,dimensions: Vector3,tint: Color) -> MeshInstance3D:
	return stage.block(parent,p,dimensions,tint)

func cylinder(parent: Node3D, a: Vector3, b: Vector3, radius: float, tint: Color, segments := 14) -> Node3D:
	var mesh := CylinderMesh.new()
	mesh.top_radius=radius
	mesh.bottom_radius=radius
	mesh.height=a.distance_to(b)
	mesh.radial_segments=segments
	mesh.rings=0
	var item: Node3D=stage.model(parent,(a+b)*.5,mesh,tint)
	item.quaternion=Quaternion(Vector3.UP,(b-a).normalized())
	return item

func text(parent: Node3D,p: Vector3,value: String,height: float,tint: Color) -> Label3D:
	var label := Label3D.new()
	parent.add_child(label)
	label.position=p
	label.font_size=64
	label.pixel_size=height/64
	label.outline_size=0
	label.modulate=tint
	label.text=value
	return label

func light(p: Vector3, tint: Color, energy: float, radius: float) -> void:
	var practical:=OmniLight3D.new()
	add_child(practical)
	practical.position=p
	practical.light_color=tint
	practical.light_energy=energy
	practical.omni_range=radius

func _hall() -> void:
	counter_root=joint(self,Vector3.ZERO)
	counter_root.name="Counters"
	box(self,Vector3(0,-.051,.40),Vector3(14,.12,8),Color("#545d59"))
	_terrazzo()
	# The outer piers keep the queues inside an arcade, with street on one side.
	box(self,Vector3(-4.7,1.56,-.90),Vector3(1.06,3.12,.43),Color("#84948b"))
	box(self,Vector3(-4.75,1.57,.97),Vector3(.19,3.14,3.60),Color("#9b9c8d"))
	box(self,Vector3(-4.61,1.14,.96),Vector3(.074,.072,3.60),OAK)
	box(self,Vector3(-2.27,3.08,-.13),Vector3(4.83,.103,1.74),Color("#74766e"))
	for x in [-2.46,-.25]:
		cylinder(self,Vector3(x,2.82,-.32),Vector3(x,3.06,-.32),.015,IRON)
		cylinder(self,Vector3(x,2.79,-.32),Vector3(x,2.83,-.32),.156,IRON)
		_lit(cylinder(self,Vector3(x,2.768,-.32),Vector3(x,2.784,-.32),.132,CREAM),Color("#eac595"))
		light(Vector3(x,2.57,-.32),Color("#e8b37f"),.68,2.85)
	for x in [-4.30,1.20,6.22]:
		box(self,Vector3(x,1.67,-.93),Vector3(.24,3.34,.46),PAINT)
		box(self,Vector3(x,.58,-.90),Vector3(.26,1.16,.49),TILE)
		box(self,Vector3(x,1.17,-.90),Vector3(.30,.07,.50),IRON)
	box(self,Vector3(.41,3.20,-.92),Vector3(11.8,.33,.52),PAINT)
	box(self,Vector3(-1.63,1.66,-2.05),Vector3(5.58,3.33,.13),Color("#677e7a"))
	for i in 2:
		_booth(i)
	var scene_clock:=joint(self,Vector3(1.22,2.32,-.626))
	clock=scene_clock
	clock.name="WallClock"
	cylinder(clock,Vector3.ZERO,Vector3(0,0,.04),.274,IRON,36)
	cylinder(clock,Vector3(0,0,.041),Vector3(0,0,.055),.244,CREAM,36)
	for i in 12:
		var a:=i*TAU/12
		var dash:=box(clock,Vector3(sin(a)*.209,cos(a)*.209,.058),Vector3(.008 if i%3 else .016,.025,.005),INK)
		dash.rotation.z=-a
	var hour:=joint(clock,Vector3(0,0,.074))
	hour.rotation.z=-TAU*(8.75/12)
	box(hour,Vector3(0,.057,0),Vector3(.021,.142,.010),INK)
	clock_minute=joint(clock,Vector3(0,0,.083))
	box(clock_minute,Vector3(0,.089,0),Vector3(.015,.203,.009),INK)
	clock_second=joint(clock,Vector3(0,0,.089))
	box(clock_second,Vector3(0,.064,0),Vector3(.006,.228,.006),RED)
	cylinder(clock,Vector3(0,0,.092),Vector3(0,0,.099),.018,BRASS)
	# The route card hangs beside the dial, visible in the same cut.
	box(self,Vector3(1.22,1.79,-.627),Vector3(.51,.29,.030),IRON)
	box(self,Vector3(1.22,1.79,-.606),Vector3(.468,.251,.018),CREAM)
	text(self,Vector3(1.22,1.845,-.591),"BUS   12",.065,INK)
	text(self,Vector3(1.22,1.745,-.591),"20:45",.098,INK)
	for x in [-3.60,-2.65,.89]:
		for z in [.24,1.82]:
			cylinder(self,Vector3(x,.02,z),Vector3(x,.064,z),.111,IRON)
			cylinder(self,Vector3(x,.064,z),Vector3(x,.82,z),.019,BRASS)
			cylinder(self,Vector3(x,.81,z),Vector3(x,.84,z),.031,BRASS)
		box(self,Vector3(x,.771,1.03),Vector3(.021,.049,1.56),Color("#8f6353"))
	# A few folded lunch leaflets sit at the observer's end of the rent counter.
	var pamphlet:=joint(self,Vector3(.67,1.11,-.58))
	pamphlet.rotation=Vector3(-.18,-.17,0)
	for i in 2:
		var fold:=joint(pamphlet,Vector3(.061*i,0,-.015*i))
		fold.rotation.y=.32*i
		box(fold,Vector3(0,.075,0),Vector3(.135,.153,.009),CREAM)
		if i==0:
			text(fold,Vector3(0,.103,.007),"LUNCH",.031,INK)
			box(fold,Vector3(0,.062,.007),Vector3(.088,.011,.005),RED)
			box(fold,Vector3(0,.038,.007),Vector3(.067,.004,.005),IRON)
	light(Vector3(-1.39,2.73,1.77),Color("#ffd39f"),.77,5.1)
	light(Vector3(2.9,2.27,-.65),Color("#f2c99d"),1.05,4.9)

func _lit(object: Node3D, tint: Color) -> void:
	var luminous:=StandardMaterial3D.new()
	luminous.shading_mode=BaseMaterial3D.SHADING_MODE_UNSHADED
	luminous.albedo_color=tint
	(object as MeshInstance3D).material_override=luminous

func _terrazzo() -> void:
	var builder:=SurfaceTool.new()
	builder.begin(Mesh.PRIMITIVE_TRIANGLES)
	var tones: Array[Color]=[Color("#818379"),Color("#797d73"),Color("#83847a"),Color("#7d8177")]
	for ix in range(-11,11):
		for iz in range(-5,8):
			var tile:=Vector3(ix*.60,.013,iz*.60)
			var tint:=tones[posmod(ix*53+iz*71,4)]
			var dx:=Vector3(.591,0,0)
			var dz:=Vector3(0,0,.591)
			for v in [tile,tile+dx,tile+dx+dz,tile,tile+dx+dz,tile+dz]:
				builder.set_color(tint.srgb_to_linear())
				builder.set_normal(Vector3.UP)
				builder.add_vertex(v)
	var mesh:=MeshInstance3D.new()
	mesh.mesh=builder.commit()
	var surface:=StandardMaterial3D.new()
	surface.vertex_color_use_as_albedo=true
	surface.cull_mode=BaseMaterial3D.CULL_DISABLED
	surface.roughness=.88
	mesh.material_override=surface
	add_child(mesh)

func _booth(i: int) -> void:
	var x: float=[-2.53,-.29][i]
	var bay:=joint(counter_root,Vector3(x,0,-.93))
	bay.name="Food" if i==0 else "Rent"
	box(bay,Vector3(0,.506,0),Vector3(2.19,1.01,.40),TILE)
	for flute in range(13):
		box(bay,Vector3(-.996+.163*flute,.50,.206),Vector3(.013,.88,.011),Color("#657e73"))
	box(bay,Vector3(0,.16,.218),Vector3(2.18,.033,.025),BRASS)
	box(bay,Vector3(0,1.046,.057),Vector3(2.27,.102,.62),OAK)
	box(bay,Vector3(0,1.010,.365),Vector3(2.26,.036,.033),IRON)
	for upright in [-1.08,1.08]:
		box(bay,Vector3(upright,1.88,.06),Vector3(.047,1.64,.12),IRON)
	box(bay,Vector3(0,2.68,.04),Vector3(2.20,.28,.15),IRON)
	text(bay,Vector3(-.09,2.68,.126),"FOOD DESK" if i==0 else "RENT OFFICE",.135,CREAM)
	var number:=text(bay,Vector3(.78,2.685,.13),"30" if i==0 else "17",.116,Color("#ffb977"))
	number_boards.append(number)
	box(bay,Vector3(0,2.42,.021),Vector3(2.15,.094,.115),OAK)
	var shutter:=joint(bay,Vector3(0,0,.006))
	shutter.name="Shutter"
	shutters.append(shutter)
	for row in 13:
		box(shutter,Vector3(0,1.42+.083*row,0),Vector3(2.095,.078,.068),Color("#7d8c86") if row%2 else Color("#88958e"))
	box(shutter,Vector3(0,1.354,0),Vector3(2.11,.059,.091),IRON)
	box(shutter,Vector3(.22,1.349,.069),Vector3(.21,.037,.059),BRASS)
	# The edges above the talk-through slot catch the light on clear glass.
	box(bay,Vector3(0,1.62,-.033),Vector3(2.06,.013,.011),Color("#a7b2a6"))
	if i==1:
		var stamp:=joint(bay,Vector3(-.66,1.104,.11))
		box(stamp,Vector3(0,.022,0),Vector3(.12,.044,.10),INK)
		cylinder(stamp,Vector3(0,.03,0),Vector3(0,.115,0),.026,OAK)
		bell=joint(bay,Vector3(.05,1.107,.22))
		cylinder(bell,Vector3.ZERO,Vector3.UP*.020,.065,IRON)
		stage.round_part(bell,Vector3(0,.031,0),Vector3(.112,.073,.112),BRASS)

func _street() -> void:
	# The west sky still holds a little light. Windows and lamps carry the street.
	var backdrop:=MeshInstance3D.new()
	var horizon:=QuadMesh.new()
	horizon.size=Vector2(180,50)
	backdrop.mesh=horizon
	add_child(backdrop)
	backdrop.position=Vector3(0,4,-14)
	var shader:=Shader.new()
	shader.code="""shader_type spatial;
render_mode unshaded, cull_disabled, fog_disabled;
varying float height;
void vertex(){ height=VERTEX.y; }
void fragment(){
	float band=smoothstep(-4.,3.,height);
	ALBEDO=mix(vec3(.60,.39,.33),vec3(.19,.22,.32),band);
}"""
	var evening:=ShaderMaterial.new()
	evening.shader=shader
	backdrop.material_override=evening
	box(self,Vector3(4.15,.32,-.93),Vector3(5.76,.64,.27),TILE)
	box(self,Vector3(4.15,.68,-.93),Vector3(5.80,.066,.37),OAK)
	for i in range(4):
		box(self,Vector3(1.61+1.52*i,1.92,-.93),Vector3(.042,2.48,.076),IRON)
	box(self,Vector3(4.12,2.59,-.93),Vector3(5.6,.046,.083),IRON)
	box(self,Vector3(5.4,-.10,-3.6),Vector3(18,.14,5.1),Color("#62717b"))
	for i in range(9):
		var p:=Vector3(-1.0+i*1.58,0,-9.2-.46*(i%3))
		var height:=2.4+.46*(i%4)
		var facade:=joint(self,p)
		var colors: Array[Color]=[Color("#a89080"),Color("#918d89"),Color("#ac9b89")]
		box(facade,Vector3(0,height*.5,0),Vector3(1.55,height,.9),colors[i%3])
		box(facade,Vector3(0,height,.03),Vector3(1.67,.10,1.02),IRON)
		for k in range(2):
			for j in range(3):
				var pane:=Vector3(-.48+j*.47,.82+k*.78,.47)
				box(facade,pane,Vector3(.31,.44,.035),IRON)
				var window:=box(facade,pane+Vector3(0,.0,.024),Vector3(.242,.37,.013),WINDOW)
				if (i+j+k)%3==0:
					_lit(window,Color("#e1b383"))
				box(facade,pane+Vector3(0,.028,.041),Vector3(.255,.018,.012),IRON)
		if i%3==0:
			box(facade,Vector3(.49,height+.23,0),Vector3(.18,.49,.20),Color("#8d7163"))
	for i in [0,1]:
		var x: float=2.1+i*5
		cylinder(self,Vector3(x,0,-5.92),Vector3(x,3.09,-5.92),.035,IRON)
		cylinder(self,Vector3(x,2.99,-5.92),Vector3(x+.35,3.13,-5.92),.026,IRON)
		box(self,Vector3(x+.36,3.09,-5.92),Vector3(.27,.077,.19),IRON)
		_lit(box(self,Vector3(x+.36,3.044,-5.92),Vector3(.215,.027,.151),CREAM),Color("#efc18a"))
		light(Vector3(x+.36,2.86,-5.92),Color("#eab475"),1.27,4.4)
	for h in [3.02,3.13]:
		cylinder(self,Vector3(-1.18,h,-5.92),Vector3(10.1,h-.13,-5.92),.010,IRON)
	bus=joint(self,Vector3(3.48,0,-4.2))
	bus.name="Route12"
	box(bus,Vector3(0,.76,0),Vector3(3.28,1.13,1.15),RED)
	box(bus,Vector3(0,1.31,0),Vector3(3.35,.16,1.18),Color("#b6ae91"))
	box(bus,Vector3(0,.41,.59),Vector3(3.25,.09,.031),CREAM)
	for j in 6:
		var x:=-1.30+j*.50
		box(bus,Vector3(x,1.012,.581),Vector3(.435,.40,.032),IRON)
		box(bus,Vector3(x,1.022,.605),Vector3(.392,.335,.015),WINDOW)
	for x in [-.99,.99]:
		cylinder(bus,Vector3(x,.25,.55),Vector3(x,.25,.65),.245,INK)
		cylinder(bus,Vector3(x,.25,.652),Vector3(x,.25,.661),.109,BRASS)
	text(bus,Vector3(-1.27,.756,.61),"12",.118,CREAM)
	# A last sliver of light behind the roofs.
	var sun:=stage.round_part(self,Vector3(6.69,2.98,-13),Vector3(.66,.66,.66),CREAM) as MeshInstance3D
	var emission:=StandardMaterial3D.new()
	emission.shading_mode=BaseMaterial3D.SHADING_MODE_UNSHADED
	emission.albedo_color=Color("#f5d59f")
	sun.material_override=emission

var public_chair: Node3D
var chair_start:=Vector3(-.62,0,-.35)
var chair_end:=Vector3(-.71,0,.24)

func actor(p: Vector3,identity: String,yaw: float) -> Dictionary:
	stage.person(to_global(p),identity,"watch",yaw)
	return stage.actors.back()

func _cast() -> void:
	rosa=actor(Vector3(.08,0,.93),"rosa",-.66)
	mother=actor(Vector3(-.85,0,.94),"rosa_mother",.64)
	mother.body.scale=Vector3(.95,.93,.95)
	clerk=actor(Vector3(-.64,0,-1.38),"clerk",.18)
	clerk.body.scale=Vector3(.98,.98,.98)
	bystanders.append(actor(Vector3(-2.90,0,.45),"extra_a",2.72))
	bystanders.append(actor(Vector3(-2.38,0,1.35),"extra_b",-2.83))
	bystanders.append(actor(Vector3(-3.37,0,2.73),"ivo",2.80))
	bystanders.append(actor(Vector3(.28,0,2.91),"jo",-2.74))
	public_chair=joint(self,chair_start)
	public_chair.name="WaitingChair"
	box(public_chair,Vector3(0,.529,.01),Vector3(.422,.042,.381),OAK)
	for x in [-.166,.166]:
		for z in [-.152,.156]:
			cylinder(public_chair,Vector3(x,.019,z),Vector3(x,.513,z),.018,IRON)
		cylinder(public_chair,Vector3(x,.48,-.14),Vector3(x,1.225,-.19),.018,IRON)
	box(public_chair,Vector3(0,1.18,-.187),Vector3(.407,.148,.039),OAK)
	tickets=joint(self,Vector3.ZERO)
	tickets.name="RosasNumbers"
	tickets.scale=Vector3.ONE*1.10
	rent_number=joint(tickets,Vector3(.069,.014,0))
	_ticket(rent_number,"RENT","R18",Color("#e5b081"))
	ticket_fan=joint(tickets,Vector3(-.081,-.063,.009))
	_ticket(ticket_fan,"FOOD","F31",CREAM)

func _ticket(parent: Node3D,desk: String,number: String,stock: Color) -> void:
	box(parent,Vector3.ZERO,Vector3(.147,.123,.004),stock)
	text(parent,Vector3(0,.035,.004),desk,.029,INK)
	box(parent,Vector3(0,.012,.0045),Vector3(.116,.002,.002),INK)
	text(parent,Vector3(0,-.017,.005),number,.050,INK)
	for j in 7:
		box(parent,Vector3(-.052+.017*j,-.048,.005),Vector3(.007,.002,.002),RED)

func _reach(a: Dictionary, side: int, target: Vector3, outward: Vector3) -> void:
	var upper: Node3D=a.arms[side]
	var lower: Node3D=upper.get_node("Elbow")
	var direction: Vector3=(upper.get_parent() as Node3D).to_local(target)-upper.position
	var length:=clampf(direction.length(),.09,.688)
	var axis:=direction.normalized()
	var humerus:=lower.position.length()
	var along:=(humerus*humerus-.36*.36+length*length)/(2*length)
	var off:=(outward-axis*outward.dot(axis)).normalized()
	var elbow:=axis*along+off*sqrt(maxf(0,humerus*humerus-along*along))
	upper.quaternion=Quaternion(Vector3.DOWN,elbow.normalized())
	lower.quaternion=Quaternion(Vector3.DOWN,upper.quaternion.inverse()*(axis*length-elbow).normalized())

func _aim(p: Vector3,mark: Vector3) -> void:
	stage.camera.global_position=to_global(p)
	stage.camera.look_at(to_global(mark))

func _animate_people(t: float) -> void:
	var check:=smoothstep(9.5,11.0,t)
	var approach:=smoothstep(12.5,16.7,t)
	var turn:=smoothstep(17.,19.5,t)
	rosa.body.position=to_global(Vector3(.08-.06*approach,.008*sin(approach*PI),.93-.43*approach))
	rosa.body.rotation.y=lerpf(-.66,-1.95,approach)+1.74*turn
	rosa.head.rotation.y=-.15+.16*sin(t*.72)+.75*check-.70*approach+.66*turn
	rosa.head.rotation.x=.12+.19*smoothstep(3.8,5.5,t)-.44*check+.21*turn
	mother.body.position=to_global(Vector3(-.85+.05*approach,0,.94-.20*approach))
	mother.body.rotation.y=.64-.20*approach+.37*turn
	mother.head.rotation.y=.17*sin(.60*t)-.26*approach+.74*turn
	mother.head.rotation.x=.10+.17*approach-.24*turn
	var clutch_position:=Vector3(-.043,1.24,1.196)
	clutch_position.y+=.126*smoothstep(3.2,5.2,t)-.145*approach
	clutch_position.z-=.46*approach
	clutch_position.x-=.107*approach
	tickets.position=clutch_position
	tickets.rotation=Vector3(-.24,-.09,.11+.09*sin(t*1.2))
	# The two slips part as the women choose queues. Mother keeps the food
	# number tucked against her jacket. Rosa carries the rent slip to the clerk.
	var separate:=smoothstep(8.65,10.55,t)
	var returned: Vector3=mother.spine.to_global(Vector3(.17,.33,.23))
	ticket_fan.position=Vector3(-.090,-.045,.009).lerp(tickets.to_local(returned),separate)
	ticket_fan.rotation.z=-.08-.18*smoothstep(4.,5.9,t)+.16*separate
	_reach(rosa,1,rent_number.to_global(Vector3(.081,-.055,-.024)),Vector3(.8,-.4,.15))
	var support:=to_global(Vector3(.06,1.08,.68-.42*approach))
	_reach(rosa,0,ticket_fan.to_global(Vector3(.050,-.063,-.032)).lerp(support,separate),Vector3(-.8,-.48,.16))
	_reach(mother,1,ticket_fan.to_global(Vector3(-.065,-.051,-.018)),Vector3(.76,-.47,.2))
	var draw_chair:=smoothstep(14.2,16.7,t)
	public_chair.position=chair_start.lerp(chair_end,draw_chair)
	public_chair.rotation.y=-.20+.23*draw_chair
	var rest:=to_global(Vector3(-.52,.96,.94))
	var chair_grip:=public_chair.to_global(Vector3(-.1,1.20,-.18))
	_reach(mother,0,rest.lerp(chair_grip,smoothstep(15.1,18.,t)),Vector3(-.70,-.64,.32))
	clerk.body.position=to_global(Vector3(-.64+.19*approach,.01,-1.38+.39*approach))
	clerk.body.rotation.y=.18-.36*approach
	clerk.spine.rotation.x=.12*smoothstep(12.2,14.2,t)-.07*turn
	clerk.head.rotation.y=.18+.31*smoothstep(3.1,5.5,t)-.82*approach
	clerk.head.rotation.x=.17-.11*approach
	var desk_target:=to_global(Vector3(-.58,1.13,-.79))
	_reach(clerk,0,desk_target.lerp(public_chair.to_global(Vector3(.13,1.216,-.19)),smoothstep(12.7,14.5,t)),Vector3(-.68,-.17,.39))
	_reach(clerk,1,to_global(Vector3(-.20,1.12,-.74)),Vector3(.71,-.54,.19))
	for i in bystanders.size():
		var a:=bystanders[i]
		a.head.rotation.y=.105*sin(t*.73+i)
		a.body.position=a.start+Vector3(.028*sin(t*.62+i),.008*absf(sin(t*.75+i)),-.11*smoothstep(1.+i,3.5+i,t))
	for a in [rosa,mother,clerk]:
		var eye_time:=fposmod(t+float(a.start.x),4.39)
		var blink:=smoothstep(2.20,2.28,eye_time)*(1.-smoothstep(2.28,2.42,eye_time))
		for lid in a.lids:
			lid.set_blend_shape_value(lid.find_blend_shape_by_name("Blink"),blink)
	for lip in clerk.lips:
		lip.set_blend_shape_value(lip.find_blend_shape_by_name("Smile"),.23*approach)

func frame(t: float) -> void:
	for i in 2:
		var opening:=smoothstep(.15+i*.41,3.6+i*.52,t)
		shutters[i].position.y=-.22+1.17*opening
		# Slats disappear into the hood as the spring draws the shutter up.
		for slat in shutters[i].get_children():
			slat.visible=slat.position.y+shutters[i].position.y<2.47
	number_boards[0].text="30" if t<8.9 else "31"
	number_boards[1].text="17" if t<11.2 else "18"
	clock_second.rotation.z=-TAU*(44.0+t)/60.
	clock_minute.rotation.z=-TAU*(44.73+t/60.)/60.
	bus.position.x=3.48+6.40*smoothstep(16.9,21.5,t)
	_animate_people(t)
	if t<4.85:
		var drift:=smoothstep(.1,4.6,t)
		_aim(Vector3(3.02-.55*drift,2.05-.10*drift,5.31-.48*drift),Vector3(-.83,1.40,.02))
	elif t<7.40:
		_aim(Vector3(.82,1.73,2.33),Vector3(-.31,1.57,.87))
	elif t<10.24:
		var follow:=smoothstep(8.75,10.2,t)
		_aim(Vector3(.065-.27*follow,1.49,1.83+.41*follow),tickets.position+Vector3(-.13*follow,-.019,0))
	elif t<13.60:
		_aim(Vector3(1.91,2.03,.65),Vector3(1.46,2.06,-.68))
	elif t<17.5:
		_aim(Vector3(-1.82,1.57,.78),Vector3(-.49,1.32,-.58))
	else:
		_aim(Vector3(-2.44,1.69,3.06),Vector3(.18,1.53,.30))
