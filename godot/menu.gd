extends Control

const DOSSIERS := [
	"ADA   ·   H-0317\nYou studied living cells. The director wants three slides from your sky journal.",
	"NICO  ·   H-0442\nYou kept three valley relays on the air. Thursday is missing from the dome roster.",
	"LEA   ·   H-0528\nYou checked alarms with a second witness. Your name is already on the report."
]

@onready var action: Button = $Content/Action
@onready var profiles: HBoxContainer = $Content/Profile
var selected_profile := 0
@onready var film = $Film
var shift: Control
var escape_room: Node
var shift_sound: Node
var previous_mode := Window.MODE_WINDOWED

func _ready() -> void:
	var roster := ButtonGroup.new()
	for index in profiles.get_child_count():
		var card: Button = profiles.get_child(index)
		card.button_group = roster
		card.pressed.connect(_show_dossier.bind(index))
	profiles.get_child(0).button_pressed = true
	_show_dossier(0)
	action.pressed.connect(advance)
	$Content/Exit.pressed.connect(get_tree().quit)
	film.finished.connect(_enter_shift)
	action.grab_focus()
	var args := OS.get_cmdline_user_args()
	if args.has("--programmatori") or args.has("--prologo"):
		advance.call_deferred()

func _show_dossier(profile: int) -> void:
	selected_profile = profile
	$Content/Message.text = DOSSIERS[profile]

func advance() -> void:
	previous_mode = get_window().mode
	get_window().mode = Window.MODE_FULLSCREEN
	$Content.hide()
	film.profile = selected_profile
	film.start()

func _enter_shift() -> void:
	film.stop()
	if OS.get_cmdline_user_args().has("--programmatori"):
		_return_to_register()
		return
	shift_sound = preload("res://shift/shift_audio.gd").new()
	add_child(shift_sound)
	shift_sound.start()
	shift = preload("res://shift/desktop.tscn").instantiate()
	add_child(shift)
	shift.gateway_requested.connect(_enter_gateway, CONNECT_ONE_SHOT)
	shift.start(selected_profile)

func _enter_gateway() -> void:
	shift.hide()
	shift.queue_free()
	shift = preload("res://shift/gateway.tscn").instantiate()
	shift.selected_profile = selected_profile
	add_child(shift)
	shift.filesystem_requested.connect(_enter_filesystem, CONNECT_ONE_SHOT)
	shift.return_requested.connect(_return_to_register, CONNECT_ONE_SHOT)

func _enter_filesystem(with_courier: bool) -> void:
	shift.hide()
	shift.queue_free()
	shift = null
	escape_room = preload("res://shift/filesystem.tscn").instantiate()
	escape_room.selected_profile = selected_profile
	escape_room.with_courier = with_courier
	escape_room.chapter_reached.connect(shift_sound.release, CONNECT_ONE_SHOT)
	escape_room.finished.connect(_return_to_register, CONNECT_ONE_SHOT)
	add_child(escape_room)

func _return_to_register() -> void:
	if is_instance_valid(escape_room):
		escape_room.queue_free()
		escape_room = null
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	if is_instance_valid(shift_sound):
		shift_sound.finish()
		shift_sound = null
	if is_instance_valid(shift):
		shift.queue_free()
		shift = null
	get_window().mode = previous_mode
	$Content.show()
	action.grab_focus()

func _input(event: InputEvent) -> void:
	if film.visible and event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		_enter_shift()
