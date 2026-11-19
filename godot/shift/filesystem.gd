extends Control

signal chapter_reached
signal finished

const PROJECTION := preload("res://shift/materialization.tscn")
const IDS := ["H-0317", "H-0442", "H-0528"]
const SPEED := 3.25
var selected_profile: int = 0
var with_courier: bool = false

@onready var hall: Node3D = $View/Film/Hall
@onready var player: CharacterBody3D = $View/Film/Hall/Player
@onready var eye: Camera3D = $View/Film/Hall/Player/Eye
@onready var packet: Node3D = $View/Film/Hall/Packet
@onready var shutter: Node3D = $View/Film/Hall/Drive/Door
@onready var state: Label3D = $View/Film/Hall/Spool/State
@onready var header: Label = $HUD/Backdrop/Lines/Header
@onready var hint: Label = $HUD/Backdrop/Lines/Hint
@onready var menu := $Overlay/Center/Column
var routed := false
var delivered := false
var complete := false
var paused := false
var pitch := 0.0
var clock := 0.0
var station := ""
var note := ""
var note_until := 0.0
var transit: Tween
var previous_mouse_mode := Input.MOUSE_MODE_VISIBLE
var mouse_look := false

func _ready() -> void:
	selected_profile = clampi(selected_profile,0,IDS.size()-1)
	hall.get_node("Press").selected_profile = selected_profile
	previous_mouse_mode = Input.mouse_mode
	mouse_look = DisplayServer.get_name() != "headless"
	var glass = PROJECTION.instantiate()
	glass.selected_profile = selected_profile
	hall.add_child(glass)
	glass.position = Vector3(1.12,0,2.05)
	glass.rotation.y = -.18
	menu.get_node("Resume").pressed.connect(_resume)
	menu.get_node("Exit").pressed.connect(_finish)
	if mouse_look:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	# First sight of the process: its carrier advances until the reader catches it.
	state.text = "INBOUND"
	packet.position.z += .88
	transit = create_tween()
	transit.tween_property(packet,"position:z",-2.30,1.1).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	transit.tween_callback(func(): state.text = "BLOCKED")
	# At boot /home accepts input from the very first position.
	_message("The courier taps twice inside the wall. Find the stalled envelope at /spool." if with_courier else "A hand knocks twice inside the wall. Find the stalled envelope at /spool.",5.0)
	_update_hud()

func _exit_tree() -> void:
	if mouse_look:
		Input.mouse_mode = previous_mouse_mode

func _physics_process(delta: float) -> void:
	if paused or complete:
		return
	clock += delta
	var moves := Input.get_vector("ui_left","ui_right","ui_up","ui_down")
	# The keyboard arrows turn and move. A gamepad's left stick strafes directly.
	var turn := float(Input.is_physical_key_pressed(KEY_LEFT))-float(Input.is_physical_key_pressed(KEY_RIGHT))
	var input_x := float(Input.is_physical_key_pressed(KEY_D))-float(Input.is_physical_key_pressed(KEY_A))
	var input_z := float(Input.is_physical_key_pressed(KEY_S))-float(Input.is_physical_key_pressed(KEY_W))
	var pads := Input.get_connected_joypads()
	if not pads.is_empty():
		var pad: int = pads[0]
		var stick_x := Input.get_joy_axis(pad,JOY_AXIS_LEFT_X)
		if absf(stick_x)>.16:
			input_x += stick_x
		var right_x := Input.get_joy_axis(pad,JOY_AXIS_RIGHT_X)
		if absf(right_x)>.18:
			turn -= right_x
		var right_y := Input.get_joy_axis(pad,JOY_AXIS_RIGHT_Y)
		if absf(right_y)>.18:
			pitch = clampf(pitch-right_y*delta*1.8,-1.08,1.05)
	player.rotate_y(turn*delta*1.9)
	eye.rotation.x = pitch
	var movement := Vector2(input_x,input_z+moves.y).limit_length(1.0)
	var velocity := player.basis * Vector3(movement.x,0,movement.y) * SPEED
	player.velocity.x = velocity.x
	player.velocity.z = velocity.z
	player.velocity.y = maxf(player.velocity.y-15.0*delta,-16.0)
	player.move_and_slide()
	_update_hud()

func _input(event: InputEvent) -> void:
	if not is_inside_tree() or not is_visible_in_tree():
		return
	if event.is_action_pressed("ui_cancel"):
		if not complete:
			if paused:
				_resume()
			else:
				_show_menu(false)
		get_viewport().set_input_as_handled()
		return
	if paused or complete:
		return
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		player.rotate_y(-event.screen_relative.x*.0025)
		pitch = clampf(pitch-event.screen_relative.y*.0023,-1.08,1.05)
		eye.rotation.x = pitch
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		if mouse_look and Input.mouse_mode!=Input.MOUSE_MODE_CAPTURED:
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
		else:
			interact()
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("ui_accept") or (event is InputEventKey and event.physical_keycode==KEY_E and event.pressed and not event.echo):
		interact()
		get_viewport().set_input_as_handled()

func _near(x: float,z: float,range_m: float) -> bool:
	return Vector2(player.position.x-x,player.position.z-z).length() < range_m

func _update_hud() -> void:
	var prompt := ""
	if _near(-2.65,-2.2,2.25):
		station = "/spool"
		prompt = "E · Read the routing receipt" if routed else "E · Send page 12 through the queue"
	elif _near(2.0,-3.05,2.25) or _near(4.15,-3.22,2.0):
		station = "/archive"
		prompt = "E · Read the retained copy" if routed else "E · Inspect the idle press"
	elif _near(0,-7.15,2.0) and player.position.z>-8.7:
		station = "/dev"
		prompt = "Walk through the open gate" if delivered else "E · Inspect the shutter"
	elif delivered and _near(0,-12.20,2.6):
		station = "/dev/pipe12"
		prompt = "E · Answer the incoming line"
	elif player.position.z>1.0:
		station = "/home"
		prompt = "E · Read your handover slip"
	else:
		station = "/"
		prompt = "Find the light above /spool, left of the shutter." if not routed else "Follow the belt to /dev, then answer the line."
	header.text = "%s   %s   ·   PID 042   %s" % [IDS[selected_profile],station,state.text]
	if clock < note_until:
		hint.text = note + ("  ·  "+prompt if station in ["/home","/dev/pipe12"] else "")
	else:
		hint.text = prompt

func _message(text: String, seconds: float = 4.0) -> void:
	note = text
	note_until = clock+seconds

func interact() -> void:
	_update_hud()
	match station:
		"/home":
			_message("Badge accepted. The outline in the glass is yours. Carry page 12 to the queue beneath /spool.",5.0)
		"/spool":
			if not routed:
				_route_page()
			else:
				_message("Receipt 042. The next reader is at /dev/pipe12.")
		"/archive":
			if not routed:
				_message("The press holds an empty carbon sheet. Its time wheel already reads THU 17 SEP 2054.",4.0)
			else:
				_message("Duplicate filed, THU 17 SEP 2054. Your own badge is embossed on tomorrow’s copy.",4.0)
		"/dev":
			_message("The shutter is waiting for the envelope from /spool. Follow the brass line back to the reader." if not delivered else "The line is open. Walk through and answer the signal.")
		"/dev/pipe12":
			if delivered and not complete:
				complete = true
				_show_menu(true)
				chapter_reached.emit()
	_update_hud()

func _route_page() -> void:
	routed = true
	state.text = "RUNNING"
	hall.get_node("Press").start_copy()
	_message("PID 042 resumes. Your page is moving toward the shutter.",3.0)
	if transit and transit.is_running():
		transit.kill()
	transit = create_tween()
	transit.tween_property(packet,"position:z",-7.29,2.0)
	transit.tween_property(packet,"position:x",0.0,1.0)
	transit.tween_callback(_unlock)

func _unlock() -> void:
	delivered = true
	state.text = "DELIVERED"
	_message("Received. The /dev shutter is lifting. A light is pulsing beyond it.",4.0)
	transit = create_tween()
	transit.tween_property(shutter,"position:y",3.45,.8).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)

func _show_menu(at_end: bool) -> void:
	paused = true
	hall.process_mode = Node.PROCESS_MODE_DISABLED
	hall.get_node("Press").process_mode = Node.PROCESS_MODE_DISABLED
	if transit and transit.is_running():
		transit.pause()
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	$Overlay.show()
	menu.get_node("Title").text = "END OF CHAPTER ONE" if at_end else "Shift suspended"
	menu.get_node("Text").text = "The receiver shows an address outside the register. A human voice asks, “Which one of you sent the page?”" if at_end else "WASD or left stick to walk. Mouse, arrow keys or right stick to turn. E, Enter, left click or A to use the nearest station."
	menu.get_node("Resume").visible = not at_end
	var focus: Button = menu.get_node("Exit" if at_end else "Resume")
	focus.grab_focus()

func _resume() -> void:
	if complete:
		return
	$Overlay.hide()
	paused = false
	hall.process_mode = Node.PROCESS_MODE_INHERIT
	hall.get_node("Press").process_mode = Node.PROCESS_MODE_INHERIT
	if transit and transit.is_valid():
		transit.play()
	if mouse_look:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func _finish() -> void:
	finished.emit()
