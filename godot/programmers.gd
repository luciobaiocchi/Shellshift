extends Node3D
## Opening shot. All positions and performances are sampled against film time.
var stage
var cast := []
var lid: Node3D
var status: Label3D
var clock_face: Label3D
var laptop: Node3D
const UMBER := Color("#513936")
const DENIM := Color("#3e5666")
const MOSS := Color("#638075")
const BRASS := Color("#bd9057")

func build(host) -> void:
	stage = host
	for side in [-1,1]:
		var x := float(side)*.65
		make_actor(x,side == -1)
	stage.block(self,Vector3(0,.96,.54),Vector3(2.95,.11,.91),stage.WOOD)
	for x in [-1.28,1.28]:
		stage.block(self,Vector3(x,.47,.54),Vector3(.10,.93,.65),UMBER)
	laptop = stage.joint(self,Vector3(-.44,1.025,.52))
	laptop.rotation.y = PI
	stage.block(laptop,Vector3.ZERO,Vector3(.75,.04,.49),DENIM)
	for row in 3:
		for col in 11:
			stage.block(laptop,Vector3(-.29+.058*col,.025,-.10+.059*row),Vector3(.047,.012,.043),stage.INK)
	lid = stage.joint(laptop,Vector3(0,.025,-.24))
	stage.block(lid,Vector3(0,.24,0),Vector3(.76,.49,.035),DENIM)
	var decal = stage.block(lid,Vector3(.19,.30,-.024),Vector3(.12,.07,.008),BRASS)
	decal.rotation.z = -.19
	stage.block(lid,Vector3(-.21,.14,-.025),Vector3(.085,.065,.008),MOSS)
	stage.block(lid,Vector3(0,.24,.02),Vector3(.70,.42,.01),stage.INK)
	status = lettering(lid,Vector3(0,.24,.035),"",.0023)
	stage.book(Vector3(.28,1.05,.47))
	stage.block(self,Vector3(0,2,-2.9),Vector3(11,4.4,.2),MOSS)
	for i in range(-2,3):
		var wx := i*1.6
		stage.block(self,Vector3(wx,2.2,-2.75),Vector3(1.46,1.87,.08),Color("#839992"))
		for y in [1.30,2.33,3.10]:
			stage.block(self,Vector3(wx,y,-2.66),Vector3(1.52,.048,.08),UMBER)
		stage.block(self,Vector3(wx,2.2,-2.66),Vector3(.04,1.86,.08),UMBER)
		for j in 3:
			stage.block(self,Vector3(wx-.49+.32*j,1.49,-2.68),Vector3(.23,.37+.18*((i+j+4)%3),.05),DENIM)
	clock_face = lettering(self,Vector3(1.27,1.26,.54),"16:00",.003)
	stage.block(self,Vector3(1.27,1.26,.48),Vector3(.46,.19,.10),UMBER)
	# Folded cardigan, ceramic mug and handle on the worktop.
	stage.round_part(self,Vector3(-1.1,1.13,.53),Vector3(.17,.23,.16),stage.PAPER)
	var handle := TorusMesh.new()
	handle.inner_radius = .035
	handle.outer_radius = .061
	var ring = stage.model(self,Vector3(-1.01,1.14,.53),handle,stage.PAPER)
	ring.rotation.x = PI/2

func lettering(parent: Node3D,pos: Vector3,value: String,unit: float) -> Label3D:
	var label := Label3D.new()
	parent.add_child(label)
	label.position = pos
	label.text = value
	label.font_size = 36
	label.pixel_size = unit
	label.outline_size = 0
	label.modulate = Color("#d1eab6")
	return label

func make_actor(x: float, curls: bool) -> void:
	var coat := Color("#b77346") if curls else MOSS
	var hair := Color("#3d2c2b") if curls else Color("#64463a")
	stage.person(Vector3(x,0,-.12),coat,hair,"office")
	var rig: Dictionary = stage.actors.back()
	for child in rig.head.get_children():
		child.free()
	var portrait = preload("res://cast/ada.glb") if curls else preload("res://cast/nico.glb")
	var face = portrait.instantiate()
	rig.head.add_child(face)
	# Lower the shirt neckline to expose the jaw when the actor looks down.
	rig.spine.get_child(0).scale.y = .74
	rig.spine.get_child(0).position.y = .29
	for child in rig.spine.get_children():
		if child is MeshInstance3D and child.mesh is BoxMesh:
			child.position.y -= .11
	var mouth := []
	for part in face.find_children("*","MeshInstance3D",true,false):
		if part.find_blend_shape_by_name("Smile") >= 0:
			mouth.append(part)
	for side in [-1,1]:
		var collar = stage.block(rig.spine,Vector3(side*.084,.53,.13),Vector3(.115,.13,.033),coat.lightened(.13))
		collar.rotation.z = side*.48
	for j in 3:
		stage.round_part(rig.spine,Vector3(0,.45-j*.105,.21),Vector3(.021,.021,.015),BRASS)
	if not curls:
		for side in [-1,1]:
			var rims := TorusMesh.new()
			rims.inner_radius = .058
			rims.outer_radius = .063
			var rim = stage.model(rig.head,Vector3(side*.084,.042,.18),rims,UMBER)
			rim.rotation.x = PI/2
			rim.rotation.y = side*.27
		stage.block(rig.head,Vector3(0,.052,.196),Vector3(.055,.008,.012),UMBER)
	cast.append({"rig":rig,"mouth":mouth})

func frame(t: float) -> void:
	var relief := smoothstep(2.6,3.7,t)
	var bump := smoothstep(5.2,6.3,t) - smoothstep(6.6,7.5,t)
	status.text = "TEST  47 / 48" if t < 1.55 else "48 / 48\nTUTTI SUPERATI"
	lid.rotation.x = 1.49*smoothstep(8.0,9.1,t)
	for i in 2:
		var actor: Dictionary = cast[i]
		var rig: Dictionary = actor.rig
		var side := 1 if i == 0 else -1
		var look := smoothstep(2.65+i*.85,4+i*.85,t)
		rig.body.rotation.y = side*.21*look
		rig.head.rotation.y = side*(.14+.58*look)
		rig.head.rotation.x = .25*(1-relief)-.12*relief+.046*sin(t*9+i)*bump
		var grin := smoothstep(3.55+i*.78,4.65+i*.78,t)
		for part in actor.mouth:
			part.set_blend_shape_value(part.find_blend_shape_by_name("Smile"),grin)
		rig.spine.rotation.x = .12*(1-relief)-.07*relief
		rig.spine.position.y = .91 - .045*relief + .025*bump*sin(t*10)
		for j in 2:
			rig.arms[j].rotation.x = -.66*(1-relief) + .09*sin(t*13+j)*(1-relief)
			rig.arms[j].rotation.z = 0
		var inner: Node3D = rig.arms[1-i]
		inner.rotation.z = side*1.37*bump
		inner.rotation.x -= .36*bump
		if i == 0:
			inner.rotation.x -= .92*(smoothstep(7.4,8.1,t)-smoothstep(9.1,9.7,t))
	var cam: Camera3D = stage.camera
	if t < 3.15:
		cam.position = Vector3(-.04,1.76,-.44)
		cam.look_at(Vector3(-.44,1.32,.75))
	elif t < 5.35:
		cam.position = Vector3(-.15,1.86,1.12)
		cam.look_at(Vector3(-.62,1.77,-.12))
	elif t < 6.15:
		cam.position = Vector3(.25,1.83,1.12)
		cam.look_at(Vector3(.63,1.75,-.12))
	elif t < 7.7:
		cam.position = Vector3(.09+.08*sin(t*.5),1.78,2.53-.06*(t-2.65))
		cam.look_at(Vector3(0,1.59,-.12))
	else:
		cam.position = Vector3(1.85,1.98,2.34)
		cam.look_at(Vector3(-.1,1.44,.07))
