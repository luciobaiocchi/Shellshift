extends Node3D

@onready var camera: Camera3D = $ShotCamera
@onready var performance: AnimationPlayer = $AnimationPlayer
@onready var train: MeshInstance3D = $SignalBox/CivilRailControl/Train
var preview_time := 0.0
const Rig := preload("res://casting/hospital_performance.gd").Performer
var ivo: Rig

const ROUTE := [Vector2(-1.03,-.03), Vector2(-.58,-.03), Vector2(-.32,.17),
	Vector2(.17,.17), Vector2(.37,-.04), Vector2(1.02,-.04)]

func _ready() -> void:
	set_process(get_tree().current_scene == self or get_parent() == get_tree().root)
	if is_processing():
		camera.make_current()
	ivo = Rig.new($Dispatcher)
	performance.play("handover")
	performance.pause()
	frame(0.0)

func _process(delta: float) -> void:
	preview_time = fmod(preview_time+delta,3.8)
	frame(preview_time)

func frame(time: float) -> void:
	var t := clampf(time,0.0,3.8)
	performance.seek(t,true)
	var locked := time >= 9.0
	var withdrawal := smoothstep(9.08,10.35,time) if locked else 0.0
	if locked:
		$SignalBox/CivilRailControl/Authority.text = "AGENT DISPATCH   /   RECEIPT ONLY"
	_pose_ivo(time,withdrawal)
	var distance := smoothstep(1.40,3.7,t)*(ROUTE.size()-1)
	if locked:
		distance = fmod((time-9.0)*1.37+1.35,ROUTE.size()-1)
	var step := mini(floori(distance),ROUTE.size()-2)
	var station: Vector2 = ROUTE[step].lerp(ROUTE[step+1],distance-step)
	train.position = Vector3(station.x,station.y+.055,.205)
	camera.position = Vector3(.51-.25*t/3.8,1.70+.04*sin(t*.5),2.27-.12*t/3.8)
	camera.look_at(to_global(Vector3(.02,1.52,-.32)))

func _pose_ivo(t: float, withdrawal: float) -> void:
	ivo.skeleton.reset_bone_poses()
	var glance := smoothstep(1.5,2.65,t)
	ivo.turn("Spine2",Vector3.RIGHT,.08+sin(t*1.4)*.014)
	ivo.turn("Neck",Vector3.UP,.24*glance-.35*withdrawal)
	ivo.turn("Head",Vector3.RIGHT,.19-.18*glance+.24*withdrawal)
	ivo.shape("BrowInnerUp",.16+.19*withdrawal)
	ivo.shape("Smile",.25*glance*(1.-withdrawal))
	ivo.shape("Blink",1.-smoothstep(.025,.15,absf(fposmod(t,3.75)-1.04)))
	var grip: Vector3 = $InterlockingDesk/Lever/Grip.global_position
	var fingers := Vector3(.11,-.67,.65).normalized()
	var axes := ivo.surface_axes(fingers,Vector3(.24,.69,.56))
	var wrist := grip - fingers*.095 + Vector3(-.13,.025,-.11)*withdrawal
	ivo.wrist("L",wrist,to_global(Vector3(-.12,1.09,-.05)),axes)
	ivo.fingers("L",axes,.79-.51*withdrawal,.33)
	var rest := ivo.surface_axes(Vector3(.12,-.44,.77),Vector3(-.33,.80,.24))
	ivo.wrist("R",to_global(Vector3(-.74,1.04,.28)),to_global(Vector3(-.87,1.19,-.12)),rest)
	ivo.fingers("R",rest,.30,.22)
