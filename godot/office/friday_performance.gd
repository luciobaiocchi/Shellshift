extends Node3D
## Two colleagues at a standing desk. Hands are posed against the real keybed and lid.
const Performer = preload("res://casting/hospital_performance.gd").Performer

var ada: Performer
var nico: Performer
var hinge: Node3D
var scarf: Node3D

func bind(first: Node3D, second: Node3D, display: Node3D, collar: Node3D) -> void:
	ada = Performer.new(first)
	nico = Performer.new(second)
	hinge = display
	scarf = collar

func frame(t: float) -> void:
	for p: Performer in [ada,nico]:
		p.skeleton.reset_bone_poses()
		var is_ada := p == ada
		var delayed := t if is_ada else t - .68
		var notices := smoothstep(2.38,3.55,delayed)
		var meets_eyes := smoothstep(3.5,4.66,delayed)
		var lets_go := smoothstep(7.54,8.30,t)
		var checks_clock := smoothstep(5.86,6.50,t) * (1.0-smoothstep(6.82,7.58,t))
		var closes := smoothstep(7.98,8.58,t)*(1.-smoothstep(9.60,10.56,t))
		var smile := smoothstep(3.62,4.84,delayed)*(.86+.14*sin(2.8*delayed))
		var turn := 1.0 if is_ada else -1.0
		var axes := p.body.global_basis.orthonormalized()
		var breath := sin(t*1.8+(0.0 if is_ada else 1.2))
		var down := .14*(1.-notices)+.09*closes if is_ada else .18*closes+.11*(1.-notices)
		p.turn("Spine",axes.x,.08*(1.0-notices)+(.16*closes if not is_ada else .0))
		p.turn("Spine1",axes.x,.037*breath-.08*smile+(.08*closes if not is_ada else .0))
		p.turn("Spine2",Vector3.UP,turn*.18*meets_eyes*(1.-.56*lets_go))
		var eye_turn := turn*(.45 if is_ada else .44)*meets_eyes*(1.-.65*lets_go)
		if not is_ada:
			eye_turn = lerpf(eye_turn,.90,checks_clock)-.19*closes
		p.turn("Neck",Vector3.UP,eye_turn*.55)
		p.turn("Head",Vector3.UP,eye_turn)
		p.turn("Neck",axes.x,down+.18*checks_clock)
		p.turn("Head",axes.x,down+.11*checks_clock-.077*smile + .028*sin(t*7.)*smile)
		p.turn("Head",axes.z,turn*(-.09*smile))
		var blink_t := fposmod(delayed+.18,3.49)
		var blink := 1.-smoothstep(.018,.122,absf(blink_t-2.86))
		p.shape("EyeBlinkLeft",blink)
		p.shape("EyeBlinkRight",blink*.98)
		p.shape("MouthSmileLeft",smile*(.95 if is_ada else .76))
		p.shape("MouthSmileRight",smile*(.74 if is_ada else .94))
		p.shape("CheekRaise",smile*.66)
		p.shape("EyeSquintLeft",.26*smile)
		p.shape("EyeSquintRight",.21*smile)
		p.shape("LipsPart",(.18 if is_ada else .14)*smile)
		p.shape("BrowInnerUp",.38*notices*(1.-.65*meets_eyes))
		p.shape("LookDown",down*1.9+checks_clock*.52)
		p.shape("LookLeft",.37*meets_eyes if is_ada else .30*checks_clock)
		p.shape("LookRight",.38*meets_eyes if not is_ada else .0)
		var words := smoothstep(3.42,3.66,t)-smoothstep(4.55,4.88,t) if is_ada else smoothstep(5.99,6.27,t)-smoothstep(6.78,7.16,t)
		p.shape("JawOpen",(.05+.10*absf(sin(t*7.)))*smile + .21*words*absf(sin(t*10.)))
		_hands(p,is_ada,t)
	var neck_axes := ada.orient("Neck")*ada.neck_to_body
	scarf.global_transform = Transform3D(neck_axes,ada.point("Neck")+neck_axes*Vector3(0,.01,.002))

func _hands(p: Performer,is_ada: bool,t: float) -> void:
	var front := p.body.global_basis.z.normalized()
	var left := p.body.global_basis.x.normalized()
	var pause := smoothstep(2.46,3.49,t)
	for side: String in ["L","R"]:
		var sign_x := 1. if side=="L" else -1.
		var shoulder := p.point(side+" UpperArm")
		var pole := shoulder+left*.19*sign_x-Vector3.UP*.26-front*.035
		var wrist := shoulder+left*.049*sign_x-Vector3.UP*.455+front*.048
		var direction := (Vector3.DOWN+front*.21).normalized()
		var dorsal := left*sign_x
		var curl := .17
		var tap := .5+.5*sin(t*15.5+sign_x*2.45)
		if is_ada:
			var keys := Vector3(-.39+sign_x*.117,1.105+.008*tap,.191+.007*sin(t*5.7+sign_x))
			var rests := Vector3(-.45+sign_x*.194,1.067,.112)
			wrist = keys.lerp(rests,pause)
			direction = (front+Vector3.DOWN*(.26-.10*pause)).normalized()
			dorsal = Vector3.UP
			curl = .26+.17*(1.-pause)*tap
		else:
			if side=="R":
				wrist = Vector3(.24,1.11,.135)
				direction = (front+Vector3.DOWN*.24).normalized()
				dorsal = Vector3.UP
				var reach := smoothstep(7.86,8.57,t)*(1.-smoothstep(9.55,10.53,t))
				var lid_target := hinge.to_global(Vector3(-.327,.474,.0))
				var across_top := (Vector3(.0,-.25,.97)).normalized()
				var down := hinge.global_basis.y.normalized()
				var lid_fingers := (across_top*.92-down*.24).normalized()
				wrist = wrist.lerp(lid_target-lid_fingers*.12+down*.014,reach)
				wrist.y += .10*sin(reach*PI)
				direction = direction.lerp(lid_fingers,reach).normalized()
				dorsal = dorsal.lerp((down+Vector3.UP*.7).normalized(),reach).normalized()
				curl += reach*.14
		var inside := (side=="L") if is_ada else (side=="R")
		if inside:
			# They have time for their old knuckle tap; Ada offers it first.
			var early := .0 if is_ada else .13
			var bump := smoothstep(6.86+early,7.46+early,t)*(1.-smoothstep(7.61,7.98+early,t))
			var inward := Vector3.RIGHT if is_ada else Vector3.LEFT
			var contact := Vector3(-.11,1.50,.125)
			wrist = wrist.lerp(contact-inward*.095,bump)
			direction = direction.lerp((inward*.88+front*.45).normalized(),bump).normalized()
			dorsal = dorsal.lerp((Vector3.UP*.70+front*.5).normalized(),bump).normalized()
			curl = lerpf(curl,1.39,bump)
		var axes := p.surface_axes(direction,dorsal)
		p.wrist(side,wrist,pole,axes)
		p.fingers(side,axes,curl,.17+.26*minf(1,curl))
