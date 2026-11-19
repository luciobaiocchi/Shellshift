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
		stage.block(self,Vector3(wx,2.2,-2.75),Vector3(1.46,1.87,.08),Color("#b4cbd0"))
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
	var skin := Color("#b77859") if curls else Color("#d2a585")
	var hair := Color("#3d2c2b") if curls else Color("#64463a")
	stage.person(Vector3(x,0,-.12),coat,hair,"office")
	var a: Dictionary = stage.actors.back()
	var head: Node3D = a.head
	# Rebuild the portrait while keeping the cast's proportions and rig.
	for child in head.get_children():
		child.free()
	stage.round_part(head,Vector3(0,.02,0),Vector3(.44,.50,.39),skin)
	stage.round_part(head,Vector3(0,-.085,.045),Vector3(.354,.32,.32),skin)
	stage.round_part(head,Vector3(0,-.025,.193),Vector3(.079,.12,.09),skin.lightened(.07))
	for side in [-1,1]:
		stage.round_part(head,Vector3(side*.21,-.005,0),Vector3(.079,.13,.073),skin)
	stage.round_part(head,Vector3(0,.13,-.045),Vector3(.47,.32,.4),hair)
	var count := 17 if curls else 9
	for i in count:
		var angle := TAU*i/count
		var tuft = stage.round_part(head,Vector3(.193*cos(angle),.13+.045*sin(i*2.7),.155*sin(angle)-.018),Vector3(.138,.15,.12),hair.lightened(.028*(i%3)))
		tuft.rotation.z = .4*sin(i)
	if curls:
		stage.round_part(head,Vector3(-.06,.13,-.20),Vector3(.28,.25,.24),hair)
	else:
		for side in [-1,1]:
			stage.block(head,Vector3(side*.176,.016,.075),Vector3(.049,.12,.063),hair)
	var eyes := []
	var brows := []
	var lips := []
	var smile = stage.round_part(head,Vector3(0,-.101,.212),Vector3(.12,.04,.018),UMBER)
	var teeth = stage.block(head,Vector3(0,-.095,.224),Vector3(.084,.012,.01),stage.PAPER)
	for side in [-1,1]:
		var eye = stage.joint(head,Vector3(side*.09,.04,.174))
		eye.rotation.y = side*.24
		stage.round_part(eye,Vector3.ZERO,Vector3(.092,.044,.031),stage.PAPER)
		stage.round_part(eye,Vector3(0,0,.014),Vector3(.033,.039,.016),UMBER)
		stage.block(eye,Vector3(-.006,.008,.023),Vector3(.009,.009,.006),Color.WHITE)
		eyes.append(eye)
		var brow = stage.block(head,Vector3(side*.09,.089,.174),Vector3(.083,.018,.026),hair)
		brows.append(brow)
		var lip = stage.joint(head,Vector3(0,-.10,.217))
		stage.block(lip,Vector3(side*.036,0,0),Vector3(.074,.014,.013),UMBER)
		lips.append(lip)
		var collar = stage.block(a.spine,Vector3(side*.095,.60,.163),Vector3(.14,.16,.052),coat.lightened(.23))
		collar.rotation.z = side*.46
	for j in 4:
		stage.round_part(a.spine,Vector3(0,.49-j*.105,.217),Vector3(.025,.025,.015),BRASS)
	stage.block(a.spine,Vector3(.174,.40,.175),Vector3(.123,.117,.031),coat.darkened(.15))
	stage.block(a.spine,Vector3(.174,.457,.20),Vector3(.124,.012,.012),BRASS)
	if not curls:
		for side in [-1,1]:
			var rims := TorusMesh.new()
			rims.inner_radius = .060
			rims.outer_radius = .068
			var rim = stage.model(head,Vector3(side*.089,.043,.203),rims,UMBER)
			rim.rotation.x = PI/2
		stage.block(head,Vector3(0,.048,.201),Vector3(.06,.013,.018),UMBER)
	cast.append({"rig":a,"eyes":eyes,"brows":brows,"lips":lips,"smile":smile,"teeth":teeth})

func frame(t: float) -> void:
	var relief := smoothstep(2.6,3.7,t)
	var bump := smoothstep(5.2,6.3,t) - smoothstep(6.6,7.5,t)
	status.text = "TEST  47 / 48" if t < 1.55 else "48 / 48\nTUTTI SUPERATI"
	lid.rotation.x = 1.49*smoothstep(8.0,9.1,t)
	for i in 2:
		var actor: Dictionary = cast[i]
		var rig: Dictionary = actor.rig
		var side := 1 if i == 0 else -1
		var look := smoothstep(2.65+i*.36,4+i*.3,t)
		rig.body.rotation.y = side*.21*look
		rig.head.rotation.y = side*(.14+.58*look)
		rig.head.rotation.x = .25*(1-relief)-.12*relief+.046*sin(t*9+i)*bump
		actor.smile.scale.y = .012 + .032*relief
		actor.teeth.visible = relief > .48
		rig.spine.rotation.x = .12*(1-relief)-.07*relief
		rig.spine.position.y = .91 - .045*relief + .025*bump*sin(t*10)
		for j in 2:
			var sign_x := -1 if j == 0 else 1
			actor.eyes[j].scale.y = (1-.37*relief) * (1-.90*exp(-pow((t-4.9-i*.25)/.11,2)))
			actor.brows[j].position.y = .088 + .026*look
			actor.brows[j].rotation.z = -sign_x*.10*relief
			actor.lips[j].rotation.z = sign_x*.43*relief
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
	elif t < 7.7:
		cam.position = Vector3(.09+.08*sin(t*.5),1.78,2.53-.06*(t-2.65))
		cam.look_at(Vector3(0,1.59,-.12))
	else:
		cam.position = Vector3(1.85,1.98,2.34)
		cam.look_at(Vector3(-.1,1.44,.07))
