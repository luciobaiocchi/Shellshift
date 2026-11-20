extends Node3D
## F6 plays the same editable take that the prologue samples in its SubViewport.
@onready var timeline: AnimationPlayer = $AnimationPlayer
@onready var focus_material: ShaderMaterial = $Camera/Lens.material_override
var elapsed := 0.0

func _ready() -> void:
	$Workstation/Laptop.scale *= .72
	$Workstation/Laptop.position += Vector3(.05,-.0083,-.23)
	$Performance.bind($Ada,$Nico,$Workstation/Laptop/LidHinge,$OchreScarf)
	timeline.play(&"Venerdi")
	timeline.pause()
	set_process(self == get_tree().current_scene or get_parent() == get_tree().root)
	frame(0.)

func _process(delta: float) -> void:
	elapsed = fmod(elapsed+delta,12.0)
	frame(elapsed)

func frame(seconds: float) -> void:
	timeline.seek(seconds,true)
	$Performance.frame(seconds)
	$Camera.look_at($Watch.global_position)
	focus_material.set_shader_parameter("focus",$Camera.position.distance_to($Watch.position))
