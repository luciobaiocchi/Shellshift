extends Node3D
## Retargets the archive's floor, blocking, gaze and prop-contact controls onto a cast member.
## Call pose after the shot has posed its controls; hand targets are world-space grip points.
const CastRig := preload("res://casting/hospital_performance.gd")
const SIDES := ["L", "R"]
const CAST_SCALE := 1.095

var seated := false
var seat_drop := .37
var hand_targets := {}
var _actor: Node3D
var _model: Node3D
var _spine: Node3D
var _head: Node3D
var _rig: CastRig.Performer
var _kind: StringName
var _arms := {}
var _knees := {}
var _rest := {}
var _grip_offsets := {}
var _sockets := {}
var _moving_bones := PackedInt32Array()

func bind(legacy: Node3D, model: Node3D, pose_kind: StringName = &"watch") -> void:
	_actor = legacy
	_model = model
	_kind = pose_kind
	_spine = legacy.get_node("Spine")
	_head = _spine.get_node("Head")
	for side: String in SIDES:
		var control_side := "R" if side == "L" else "L"
		var upper := _spine.get_node("Shoulder"+control_side)
		_arms[side] = upper.get_node("Elbow")
		_knees[side] = legacy.get_node("Hip"+control_side+"/Knee")
	if model.get_parent():
		model.reparent(self, false)
	else:
		add_child(model)
	model.transform = Transform3D(Basis.IDENTITY.scaled(Vector3.ONE*CAST_SCALE), Vector3.ZERO)
	_rig = CastRig.Performer.new(model)
	var relative := model.global_basis.orthonormalized().inverse()
	for key: String in ["Pelvis", "Spine", "Spine1", "Spine2", "Neck", "Head"]:
		_rest[key] = relative*_rig.orient(key)
		_moving_bones.append(_rig.ids[key])
	for side: String in SIDES:
		for joint in ["Clavicle","UpperArm","Forearm","Hand","Thigh","Calf","Foot"]:
			_moving_bones.append(_rig.ids[side+" "+joint])
		var palm := _rig.point(side+" Finger2") - _rig.point(side+" Hand")
		var across := _rig.point(side+" Finger4") - _rig.point(side+" Finger1")
		var axes := _rig.surface_axes(palm, palm.cross(across)*(1 if side=="L" else -1))
		# The holding point lies between index and thumb, inside a lightly closed hand.
		_rig.fingers(side, axes, .30 if pose_kind!=&"type" else .21, .24)
		_grip_offsets[side] = _rig.orient(side+" Hand").inverse()*(grip_world(side)-_rig.point(side+" Hand"))/model.global_basis.x.length()
	pose(0.0)

func socket(key: String) -> BoneAttachment3D:
	if not _sockets.has(key):
		var joint := BoneAttachment3D.new()
		var bone := key+" Hand" if key in SIDES else key
		joint.name = key+"Socket"
		_rig.skeleton.add_child(joint)
		joint.bone_idx = _rig.ids[bone]
		_sockets[key] = joint
	return _sockets[key]

## Child basis for an accessory modelled facing +Z in the neutral body frame.
func socket_axes(key: String) -> Basis:
	var bone := key+" Hand" if key in SIDES else key
	if key in SIDES:
		return (_rig.hand_offsets[key] as Basis).inverse()
	return (_rest[bone] as Basis).inverse()

## Reading this during a blocking pass uses the current control marks, even after a seek.
func ear_world(side: String) -> Vector3:
	_torso()
	var sign_x := 1.0 if side=="L" else -1.0
	var axes := _rig.orient("Head")*socket_axes("Head")
	return _rig.point("Head")+axes*Vector3(.080*sign_x,.082,.017)*_model.global_basis.x.length()

func grip_world(side: String) -> Vector3:
	return _rig.point(side+" Finger11").lerp(_rig.thumb(side), .50)

func _torso() -> void:
	var root_basis := _actor.global_basis.orthonormalized()
	var lean := _spine.basis.orthonormalized().get_rotation_quaternion()
	var gaze := _head.basis.orthonormalized().get_rotation_quaternion()
	var pelvis := int(_rig.ids["Pelvis"])
	var movement := _spine.position - Vector3(0,.91,0)
	if seated: movement.y -= seat_drop
	_rig.skeleton.set_bone_pose_position(pelvis, _rig.skeleton.get_bone_rest(pelvis).origin + _rig.skeleton.global_basis.inverse()*(_actor.global_basis*movement))
	# The authored spine mark is at the belt. The pelvis shares the hinge when
	# bending to the floor, while the upper back takes most of a small glance.
	var deep := smoothstep(.13,.72,lean.get_angle())
	var hip_lean := .76*deep
	_rig.set_orient("Pelvis",root_basis*Basis(Quaternion.IDENTITY.slerp(lean,hip_lean))*_rest["Pelvis"])
	_rig.set_orient("Spine",root_basis*Basis(Quaternion.IDENTITY.slerp(lean,lerpf(.37,.92,deep)))*_rest["Spine"])
	_rig.set_orient("Spine1",root_basis*Basis(Quaternion.IDENTITY.slerp(lean,lerpf(.74,.98,deep)))*_rest["Spine1"])
	_rig.set_orient("Spine2",root_basis*Basis(lean)*_rest["Spine2"])
	var shoulders := root_basis*Basis(lean)
	_rig.set_orient("Neck", shoulders*Basis(Quaternion.IDENTITY.slerp(gaze,.40))*_rest["Neck"])
	_rig.set_orient("Head", shoulders*Basis(gaze)*_rest["Head"])

func _leg(side: String) -> void:
	var sign_x := 1.0 if side=="L" else -1.0
	var frame_basis := _actor.global_basis.orthonormalized()
	var foot := _model.to_global(_rig.planted[side])
	var pole := _rig.point(side+" Thigh") + frame_basis*Vector3(.065*sign_x, -.17, .46)
	var foot_roll := 0.0
	if seated:
		# Some scenes lower the controls all the way into the cabin seat. Lift the
		# ankles by that pre-authored part of the sit, leaving their soles on the deck.
		foot += _actor.global_basis*Vector3(.022*sign_x, maxf(0.,-_actor.position.y), .38+.032*sign_x)
	elif _kind == &"walk":
		var knee: Node3D = _knees[side]
		var sock := _actor.to_local(knee.to_global(Vector3(0,-.39,0)))
		var offset := sock - Vector3(sign_x*.15,.11,0)
		foot += _actor.global_basis*Vector3(offset.x, maxf(-.006,offset.y),offset.z)
		var phase := (knee.get_parent_node_3d().rotation.x + knee.rotation.x)
		foot_roll = clampf(-phase*.28,-.14,.14)
	_rig.reach(side+" Thigh",side+" Calf",side+" Foot",foot,pole)
	_rig.set_orient(side+" Foot",frame_basis*Basis(Vector3.RIGHT,foot_roll)*_rig.sole_basis[side])

func _arm(side: String) -> void:
	var elbow: Node3D = _arms[side]
	var sign_x := 1.0 if side=="L" else -1.0
	var frame_basis := _actor.global_basis.orthonormalized()
	var target: Vector3 = hand_targets.get(side, elbow.to_global(Vector3(0,-.36,0)))
	var pole := elbow.global_position
	var fingers := -elbow.global_basis.y.normalized()
	if hand_targets.has(side):
		var extension := target - _rig.point(side+" UpperArm")
		var straightening := smoothstep(.46,.66,extension.length()/_model.global_basis.x.length())
		fingers = (target-pole).normalized().slerp(extension.normalized(),straightening)
	var outward := frame_basis.x*sign_x
	var palm_up := smoothstep(.14,.84,absf(fingers.dot(frame_basis.z)))
	var dorsal := outward.lerp(frame_basis.y, palm_up*.88)
	if absf(fingers.dot(dorsal.normalized())) > .94:
		dorsal = frame_basis.z
	var axes := _rig.surface_axes(fingers,dorsal)
	var hand_basis: Basis = axes*_rig.hand_offsets[side]
	var target_wrist: Vector3 = target - hand_basis*(_grip_offsets[side]*_model.global_basis.x.length())
	var shoulder_name := side+" UpperArm"
	var forearm_name := side+" Forearm"
	var hand_name := side+" Hand"
	var shoulder := _rig.point(shoulder_name)
	var arm_length := shoulder.distance_to(_rig.point(forearm_name)) + _rig.point(forearm_name).distance_to(_rig.point(hand_name))
	var required := target_wrist.distance_to(shoulder)
	if required > arm_length-.025:
		# Lead a reach with the shoulder girdle; preserve the shape of the gloved hand.
		var direction := shoulder.direction_to(target_wrist)
		var length_scale := _model.global_basis.x.length()
		var travel := minf(required-arm_length+.025,.085*length_scale)
		var clavicle := int(_rig.ids[side+" Clavicle"])
		var parent_pose := _rig.skeleton.get_bone_global_pose(_rig.skeleton.get_bone_parent(clavicle))
		var local_shift := (_rig.skeleton.global_basis*parent_pose.basis).inverse()*(direction*travel)
		_rig.skeleton.set_bone_pose_position(clavicle,_rig.skeleton.get_bone_rest(clavicle).origin+local_shift)
	# Avoid a locked or inverted elbow as the hands hang alongside a coat.
	var arm_ray := _rig.point(shoulder_name).direction_to(target_wrist)
	if (pole-_rig.point(shoulder_name)).slide(arm_ray).length() < .10:
		pole += frame_basis*Vector3(sign_x*.13,-.10,-.14)
	_rig.wrist(side,target_wrist,pole,axes)

func pose(_time: float) -> void:
	if not _rig: return
	# Finger curl is authored once in the local knuckle frames. The scene writes
	# facial expression weights directly to ActorMesh independently of this solve.
	for i in _moving_bones:
		_rig.skeleton.reset_bone_pose(i)
	_torso()
	for side: String in SIDES:
		_leg(side)
		_arm(side)
