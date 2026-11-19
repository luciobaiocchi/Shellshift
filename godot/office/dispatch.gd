extends Node3D

@onready var camera: Camera3D = $ShotCamera
@onready var performance: AnimationPlayer = $AnimationPlayer
@onready var train: MeshInstance3D = $SignalBox/CivilRailControl/Train
var preview_time := 0.0

const ROUTE := [Vector2(-1.03,-.03), Vector2(-.58,-.03), Vector2(-.32,.17),
	Vector2(.17,.17), Vector2(.37,-.04), Vector2(1.02,-.04)]

func _ready() -> void:
	set_process(get_tree().current_scene == self or get_parent() == get_tree().root)
	if is_processing():
		camera.make_current()
	performance.play("handover")
	performance.pause()
	frame(0.0)

func _process(delta: float) -> void:
	preview_time = fmod(preview_time+delta,3.8)
	frame(preview_time)

func frame(time: float) -> void:
	var t := clampf(time,0.0,3.8)
	performance.seek(t,true)
	$Dispatcher/Head.rotation.y = .14+.76*smoothstep(1.55,2.45,t)
	$Dispatcher/Head.rotation.x = .19-.28*smoothstep(1.55,2.2,t)
	var locked := time >= 9.0
	var withdrawal := smoothstep(9.08,10.35,time) if locked else 0.0
	if locked:
		$SignalBox/CivilRailControl/Authority.text = "AGENT DISPATCH   /   RECEIPT ONLY"
		$Dispatcher/Head.rotation.y = .47-.46*withdrawal
		$Dispatcher/Head.rotation.x = -.06+.31*withdrawal
	var grip := to_local($InterlockingDesk/Lever/Grip.global_position)
	grip += Vector3(-.16,.03,-.16)*withdrawal
	var shoulder := Vector3(-.383,1.465,.025)
	var elbow := Vector3(-.35,1.20,.13+.035*sin(t*2.1))
	var wrist := grip+Vector3(-.054,.018,-.025)
	_segment($Sleeve,shoulder,elbow,.17)
	_segment($Forearm,elbow,wrist,.145)
	_segment($Cuff,wrist.lerp(elbow,.16),wrist.lerp(elbow,.02),.113)
	_segment($Hand,wrist,grip+Vector3(.044,.013,.032),.092)
	var distance := smoothstep(1.40,3.7,t)*(ROUTE.size()-1)
	if locked:
		distance = fmod((time-9.0)*1.37+1.35,ROUTE.size()-1)
	var step := mini(floori(distance),ROUTE.size()-2)
	var station: Vector2 = ROUTE[step].lerp(ROUTE[step+1],distance-step)
	train.position = Vector3(station.x,station.y+.055,.205)
	camera.position = Vector3(.51-.25*t/3.8,1.70+.04*sin(t*.5),2.27-.12*t/3.8)
	camera.look_at(to_global(Vector3(.02,1.52,-.32)))

func _segment(mesh: MeshInstance3D, a: Vector3, b: Vector3, width: float) -> void:
	var axis := b-a
	mesh.transform = Transform3D(Basis(Quaternion(Vector3.UP,axis.normalized())).scaled_local(
		Vector3(width,axis.length()+.028,width)),(a+b)*.5)
