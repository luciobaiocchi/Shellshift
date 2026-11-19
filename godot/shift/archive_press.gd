extends Node3D
## Retention runs independently of the courier process and keeps its output here.
const BADGES := ["H-0317","H-0442","H-0528"]

@export_range(0,2) var selected_profile := 0:
	set(value):
		selected_profile = clampi(value,0,BADGES.size()-1)
		if is_node_ready():
			_label_sheets()

var started := false

func _ready() -> void:
	_label_sheets()

func _label_sheets() -> void:
	$Original/Badge.text = BADGES[selected_profile]
	$Copy/Badge.text = BADGES[selected_profile]

func start_copy() -> void:
	if started:
		return
	started = true
	$Status.text = "COPYING"
	$Copy.show()
	var feed := create_tween()
	feed.tween_property($Ram,"position:y",1.30,.22).set_trans(Tween.TRANS_SINE)
	feed.tween_interval(.16)
	feed.tween_property($Ram,"position:y",1.385,.19)
	feed.tween_property($Original,"position:y",.748,.76).set_trans(Tween.TRANS_SINE)
	feed.parallel().tween_property($Copy,"position:y",1.121,.93).set_trans(Tween.TRANS_SINE)
	feed.tween_callback($Original.hide)
	feed.tween_callback(func(): $Status.text = "COPY HELD")
