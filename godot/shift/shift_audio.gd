extends Node
## A single player follows the matricola from desk to gateway.
const ROOM := preload("res://shift/shift_audio_room.wav")
const RELEASE := preload("res://shift/shift_audio_release.wav")
const QUIET_DB := -65.0

var room := AudioStreamPlayer.new()
var ending := AudioStreamPlayer.new()
var transition: Tween
var released := false
var closing := false

func _ready() -> void:
	room.stream = ROOM
	ending.stream = RELEASE
	add_child(room)
	add_child(ending)

func start() -> void:
	if room.playing or closing:
		return
	room.volume_db = QUIET_DB
	room.play()
	transition = create_tween()
	transition.tween_property(room,"volume_db",-9.0,1.6).set_trans(Tween.TRANS_SINE)

func release() -> void:
	if released or closing:
		return
	released = true
	if transition:
		transition.kill()
	transition = create_tween()
	transition.tween_property(room,"volume_db",QUIET_DB,2.7).set_trans(Tween.TRANS_SINE)
	transition.tween_callback(room.stop)
	ending.volume_db = -6.5
	ending.play()

func finish() -> void:
	if closing:
		return
	closing = true
	if transition:
		transition.kill()
	transition = create_tween()
	transition.tween_property(room,"volume_db",QUIET_DB,.65)
	transition.tween_callback(room.stop)
	if ending.playing:
		transition.tween_interval(.85)
		transition.tween_property(ending,"volume_db",QUIET_DB,1.6)
	transition.tween_callback(queue_free)
