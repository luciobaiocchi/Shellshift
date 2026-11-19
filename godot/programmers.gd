extends Node3D
## F6 plays the same editable take that the prologue samples in its SubViewport.
@onready var timeline: AnimationPlayer = $AnimationPlayer

func _ready() -> void:
	timeline.play(&"Venerdi")
	if self == get_tree().current_scene or get_parent() == get_tree().root:
		timeline.animation_finished.connect(_replay)
	else:
		timeline.pause()

func _replay(_clip: StringName) -> void:
	timeline.play(&"Venerdi")

func frame(seconds: float) -> void:
	timeline.seek(seconds, true)
