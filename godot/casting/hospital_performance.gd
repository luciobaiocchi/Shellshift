extends Node3D
## Fifteen seconds at the ward door. The time argument also permits scrubbing.
var ticket_socket: Node3D
var _ada: Performer
var _mara: Performer
var _scarf: Node3D

class Performer:
	var body: Node3D
	var skeleton: Skeleton3D
	var ids := {}
	var face: MeshInstance3D
	var shapes := {}
	var planted := {}
	var sole_basis := {}
	var hand_offsets := {}
	var neck_to_body: Basis
	var body_basis: Basis

	func _init(model: Node3D) -> void:
		body = model
		skeleton = model.find_children("*","Skeleton3D",true,false)[0]
		for i in skeleton.get_bone_count():
			var key := String(skeleton.get_bone_name(i)).replace("_"," ").replace("Bip01","").strip_edges()
			ids[key] = i
		skeleton.reset_bone_poses()
		for obj in body.find_children("*","MeshInstance3D",true,false):
			if obj.get_blend_shape_count() <= 0: continue
			face = obj
			for i in face.get_blend_shape_count():
				shapes[String(face.mesh.get_blend_shape_name(i))] = i
			break
		body_basis = body.basis
		neck_to_body = orient("Neck").inverse()*body.global_basis.orthonormalized()
		for side in ["L","R"]:
			var prefix: String = side+" "
			planted[side] = body.to_local(point(prefix+"Foot"))
			sole_basis[side] = body.global_basis.orthonormalized().inverse()*orient(prefix+"Foot")
			var fingers := point(prefix+"Finger2")-point(prefix+"Hand")
			var across := (point(prefix+"Finger4")-point(prefix+"Finger1"))*(1.0 if side=="L" else -1.0)
			var axes := surface_axes(fingers,fingers.cross(across))
			hand_offsets[side] = axes.inverse()*orient(prefix+"Hand")

	func point(key: String) -> Vector3:
		return skeleton.to_global(skeleton.get_bone_global_pose(ids[key]).origin)

	func orient(key: String) -> Basis:
		return (skeleton.global_basis*skeleton.get_bone_global_pose(ids[key]).basis).orthonormalized()

	func set_orient(key: String, world_basis: Basis) -> void:
		var i: int = ids[key]
		var parent := skeleton.get_bone_parent(i)
		var parent_world := skeleton.global_basis
		if parent >= 0: parent_world *= skeleton.get_bone_global_pose(parent).basis
		var local := parent_world.orthonormalized().inverse()*world_basis.orthonormalized()
		skeleton.set_bone_pose_rotation(i,local.get_rotation_quaternion())

	func turn(key: String, world_axis: Vector3, angle: float) -> void:
		if absf(angle) > .00001:
			set_orient(key,Basis(world_axis.normalized(),angle)*orient(key))

	func aim(a: String,b: String,target: Vector3) -> void:
		var direction := (point(b)-point(a)).normalized()
		var goal := (target-point(a)).normalized()
		if direction.dot(goal) > .999999 or goal.is_zero_approx(): return
		set_orient(a,Basis(Quaternion(direction,goal))*orient(a))

	func reach(a: String,b: String,c: String,target: Vector3,pole: Vector3) -> void:
		var anchor := point(a)
		var l1 := anchor.distance_to(point(b))
		var l2 := point(b).distance_to(point(c))
		var ray := (target-anchor).normalized()
		var d := clampf(anchor.distance_to(target),absf(l1-l2)+.001,l1+l2-.001)
		var x := (l1*l1-l2*l2+d*d)/(2*d)
		var outward := (pole-anchor).slide(ray).normalized()
		var elbow := anchor+ray*x+outward*sqrt(maxf(0,l1*l1-x*x))
		aim(a,b,elbow)
		aim(b,c,anchor+ray*d)

	func surface_axes(fingers: Vector3,dorsal: Vector3) -> Basis:
		var z := fingers.normalized()
		var x := dorsal.cross(z).normalized()
		return Basis(x,z.cross(x).normalized(),z)

	func wrist(side: String,target: Vector3,pole: Vector3,axes: Basis) -> void:
		var prefix := side+" "
		reach(prefix+"UpperArm",prefix+"Forearm",prefix+"Hand",target,pole)
		set_orient(prefix+"Hand",axes*hand_offsets[side])

	func fingers(side: String,axes: Basis,amount: float,pinch: float) -> void:
		var prefix := side+" Finger"
		for digit in range(1,5):
			var root := prefix+str(digit)
			var curl := amount*(.68+float(digit)*.11)
			if digit == 1: curl += .14*pinch
			turn(root,axes.x,curl)
			turn(root+"1",axes.x,curl*.77)
			turn(root+"2",axes.x,curl*.43)
		turn(prefix+"0",axes.z,(.20 if side=="L" else -.20)*pinch)
		turn(prefix+"01",axes.x,.10+.14*pinch)

	func pinch_index(side: String, amount: float) -> void:
		if amount < .001: return
		var digit := side+" Finger1"
		var end := point(digit+"2")
		var tip := end+(end-point(digit+"1"))*.65
		var thumbtip := thumb(side)
		var target := tip.lerp(thumbtip+(tip-thumbtip).normalized()*.009,amount)
		# Both pads surround the folded hem. Leave room for the thickness of the wool.
		for pass_index in 4:
			for key: String in [digit+"1",digit,digit+"2"]:
				end = point(digit+"2")
				tip = end+(end-point(digit+"1"))*.65
				var start := point(key)
				var arc := Quaternion((tip-start).normalized(),(target-start).normalized())
				var weight := minf(1.0,.31/maxf(.001,arc.get_angle()))
				set_orient(key,Basis(Quaternion.IDENTITY.slerp(arc,weight))*orient(key))

	func thumb(side: String) -> Vector3:
		var base := side+" Finger0"
		var end := point(base+"2")
		return end+(end-point(base+"1"))*.66

	func shape(key: String,value: float) -> void:
		if face and shapes.has(key): face.set_blend_shape_value(shapes[key],clampf(value,0,1))

func build(ada: Node3D,mara: Node3D,scarf: Node3D) -> void:
	_ada = Performer.new(ada)
	_mara = Performer.new(mara)
	_scarf = scarf
	if _scarf.get_parent() == null: add_child(_scarf)
	ticket_socket = Node3D.new()
	ticket_socket.name = "ReturnTicket"
	add_child(ticket_socket)
	frame(0)

func collar_world() -> Vector3:
	# The right-hand turn of Ada's scarf is on the camera side of her throat.
	return _scarf.to_global(Vector3(-.078,-.064,.11))

func ticket_world() -> Vector3:
	return ticket_socket.global_position

func _weight(t: float,a: float,b: float) -> float:
	return smoothstep(a,b,t)

func _steps(t: float,start: float,duration: float,leading: bool) -> Vector2:
	var phase := clampf((t-start)/duration,0,1)
	if leading:
		var first := smoothstep(.0,.34,phase)
		var last := smoothstep(.64,1,phase)
		return Vector2((first+last)*.5,(sin(PI*first)+sin(PI*last))*.027)
	var middle := smoothstep(.29,.73,phase)
	return Vector2(middle,sin(middle*PI)*.039)

func _position_body(p: Performer,ada: bool,t: float) -> void:
	var start := Vector3(-.72,0,.09) if ada else Vector3(.73,0,-.16)
	var collar := Vector3(-.177,0,.085) if ada else Vector3(.167,0,-.005)
	var hug := Vector3(-.115,0,.100) if ada else Vector3(.115,0,-.046)
	var lead := _steps(t,.75 if ada else .35,3.45,true)
	var trail := _steps(t,.75 if ada else .35,3.45,false)
	var hug_lead := _steps(t,9.95 if ada else 10.18,2.48,true)
	var hug_trail := _steps(t,9.95 if ada else 10.18,2.48,false)
	var together := (hug_lead.x+hug_trail.x)*.5
	var arrival := (lead.x+trail.x)*.5
	var sign_x := 1.0 if ada else -1.0
	var first_yaw := (.85 if ada else -.70)
	var second_yaw := (1.12 if ada else -1.20)
	var final_yaw := (1.31 if ada else -1.25)
	var yaw := lerpf(lerpf(first_yaw,second_yaw,arrival),final_yaw,together)
	p.body.position = start.lerp(collar,arrival).lerp(hug,together)
	p.body.basis = Basis(Vector3.UP,yaw)*p.body_basis
	var forward := p.body.global_basis.z.normalized()
	var left := p.body.global_basis.x.normalized()
	for side: String in ["L","R"]:
		var advancing := (side=="L") == ada
		var a := lead if advancing else trail
		var h := hug_lead if advancing else hug_trail
		var fixed_foot: Vector3 = p.planted[side]
		var foot_yaw := lerpf(lerpf(first_yaw,second_yaw,a.x),final_yaw,h.x)
		var stance := Basis(Vector3.UP,foot_yaw)*fixed_foot
		var ankle := p.body.get_parent_node_3d().to_global(start.lerp(collar,a.x).lerp(hug,h.x)+stance+Vector3.UP*(a.y+h.y))
		var side_sign := 1.0 if side=="L" else -1.0
		var knee := p.point(side+" Thigh")+forward*.45+left*.12*side_sign
		p.reach(side+" Thigh",side+" Calf",side+" Foot",ankle,knee)
		p.set_orient(side+" Foot",p.body.global_basis.orthonormalized()*p.sole_basis[side])
	var look := _weight(t,1.1,3.35)
	var tuck := _weight(t,5.6,7.5)*(1-_weight(t,9.8,11.7))
	var breath := .010*sin(t*1.62+(0 if ada else .9))
	p.turn("Spine",left,.16*together+.037*tuck)
	p.turn("Spine1",left,breath+.12*together+.04*tuck)
	p.turn("Spine2",Vector3.UP,sign_x*(.08*look+.045*together))
	p.turn("Neck",Vector3.UP,sign_x*(.14*look-.07*together))
	p.turn("Head",Vector3.UP,sign_x*(.14*look-.18*together))
	p.turn("Neck",left,(.075 if ada else .11)*tuck)
	p.turn("Head",left,(.14 if ada else .21)*tuck-.13*together)
	p.turn("Head",forward,(.16 if ada else -.145)*together+(.032 if ada else -.02)*look)

func _dress_scarf() -> void:
	var neck_axes := _ada.orient("Neck")*_ada.neck_to_body
	_scarf.global_transform = Transform3D(neck_axes,_ada.point("Neck")+neck_axes*Vector3(0,.01,.002))

func _blink(t: float,centres: Array) -> float:
	var v := 0.
	for c: float in centres:
		v = maxf(v,1.0-smoothstep(.022,.14,absf(t-c)))
	return v

func _face(p: Performer,ada: bool,t: float) -> void:
	var warmth := _weight(t,1.55,3.15)
	var reunion := _weight(t,9.95,12.5)
	var tuck := _weight(t,5.55,6.8)*(1-_weight(t,9.5,10.8))
	var blink := _blink(t,[1.43,5.45,9.07] if ada else [.78,4.72,8.92])
	blink = maxf(blink,reunion*(.92 if ada else .78))
	p.shape("EyeBlinkLeft",blink)
	p.shape("EyeBlinkRight",blink*.96)
	p.shape("MouthSmileLeft",(.42 if ada else .38)*warmth+.11*reunion)
	p.shape("MouthSmileRight",(.34 if ada else .43)*warmth+.12*reunion)
	p.shape("CheekRaise",.19*warmth+.15*reunion)
	p.shape("BrowInnerUp",.20*warmth-.09*reunion)
	p.shape("LookDown",.56*tuck if not ada else .40*tuck)
	p.shape("LookLeft",.15*warmth if ada else 0.)
	p.shape("LookRight",0. if ada else .19*warmth)
	p.shape("JawOpen",(.035 if ada else .07)*warmth*(1.0-reunion)+.054*tuck)

func _arms(p: Performer,other: Performer,ada: bool,t: float) -> void:
	var approach := _weight(t,5.48,7.17)
	var settle := _weight(t,7.35,8.37)-_weight(t,8.49,9.42)
	var hug := _weight(t,10.25 if ada else 10.48,12.48 if ada else 12.65)
	var front := p.body.global_basis.z.normalized()
	var left := p.body.global_basis.x.normalized()
	var theirs := other.body.global_basis.orthonormalized()
	var their_neck := other.point("Neck")
	for side: String in ["L","R"]:
		var s := 1.0 if side=="L" else -1.0
		var shoulder := p.point(side+" UpperArm")
		var wrist := shoulder+left*s*.058-Vector3.UP*.486+front*.055
		var pole := shoulder+left*s*.20-Vector3.UP*.27-front*.06
		var fingers := (Vector3.DOWN+front*.15).normalized()
		var dorsal := left*s
		var turn_collar := not ada and side=="L"
		var holds_ticket := not ada and side=="R"
		if holds_ticket:
			wrist = shoulder-Vector3.UP*.34+front*.19+left*.075
			pole = shoulder-left*.115-Vector3.UP*.32
			fingers = (front*.70+Vector3.DOWN*.34+left*.2).normalized()
			dorsal = (front+Vector3.UP*.30).normalized()
		if turn_collar:
			var angle := other.body.global_basis.z.normalized()
			wrist = wrist.lerp(collar_world()+Vector3(.015,-.080,.04),approach)
			pole += (front*.08+left*.05)*approach
			fingers = fingers.lerp((Vector3.UP*.71-angle*.44).normalized(),approach).normalized()
			dorsal = dorsal.lerp(angle,approach).normalized()
		var near_side := (side=="R") == ada
		var partner_side := "R" if side=="L" else "L"
		var shoulder_contact := other.point(partner_side+" UpperArm")
		var wrap := their_neck+theirs*Vector3(-.179*s,-.172,-.085)
		var hug_fingers := (theirs.x*s*.26+theirs.z*.12-Vector3.UP*.92).normalized()
		var hug_dorsal := (-theirs.z*.68-theirs.x*s).normalized()
		var elbow_height := -.28
		if ada == near_side:
			# This palm drapes over a shoulder. The other arm circles the ribs.
			wrap = shoulder_contact+theirs*Vector3(-.016*s,.056,.085)
			hug_fingers = (-theirs.z*.9-Vector3.UP*.12).normalized()
			hug_dorsal = (Vector3.UP*.8-theirs.x*s*.5).normalized()
			if ada:
				wrap = shoulder_contact+theirs*Vector3(.088,.064,.060)
				hug_fingers = (theirs.x*.20-theirs.z*.74-Vector3.UP*.35).normalized()
				hug_dorsal = (theirs.x*.82+Vector3.UP*.42-theirs.z*.14).normalized()
			elbow_height = -.20
		elif not ada and near_side:
			var stroke := _weight(t,12.62,13.35)-_weight(t,13.45,14.62)
			wrap += Vector3.UP*.029*stroke
		wrist = wrist.lerp(wrap,hug)+left*s*.09*sin(PI*hug)
		if ada and near_side:
			# Clear Mara's moving sleeve before the fingers settle along the knit.
			wrist += (theirs.x*.185+Vector3.UP*.065)*sin(PI*hug)
		var open_elbow := shoulder+left*s*.50+front*.035+Vector3.UP*elbow_height
		pole = pole.lerp(open_elbow,hug)
		fingers = fingers.lerp(hug_fingers,hug).normalized()
		dorsal = dorsal.lerp(hug_dorsal,hug).normalized()
		var axes := p.surface_axes(fingers,dorsal)
		p.wrist(side,wrist,pole,axes)
		p.fingers(side,axes,.15+.09*hug+(.49*approach*(1-hug) if turn_collar else .0),.76 if holds_ticket else approach*(1-hug) if turn_collar else .15)
		if turn_collar:
			var fold := collar_world()+Vector3.UP*(.014*settle)
			var correction := (fold-p.thumb(side))*approach*(1-hug)
			p.wrist(side,wrist+correction,pole,axes)
			p.pinch_index(side,approach*(1-hug))

func frame(t: float) -> void:
	if not _ada: return
	t = clampf(t,0,15)
	for p: Performer in [_ada,_mara]: p.skeleton.reset_bone_poses()
	_position_body(_ada,true,t)
	_position_body(_mara,false,t)
	_dress_scarf()
	_arms(_ada,_mara,true,t)
	_arms(_mara,_ada,false,t)
	_face(_ada,true,t)
	_face(_mara,false,t)
	var ticket_at := _mara.point("R Finger1").lerp(_mara.thumb("R"),.46)
	var right := _mara.body.global_basis.x.normalized()
	var up := Vector3.UP.rotated(right,-.17)
	var normal := Vector3(0,.12,1).normalized().rotated(Vector3.UP,-.24)
	ticket_socket.global_transform = Transform3D(Basis(up.cross(normal).normalized(),up,normal).orthonormalized(),ticket_at)
