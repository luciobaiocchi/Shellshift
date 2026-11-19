extends Control

signal filesystem_requested(with_courier: bool)
signal return_requested

const BAY_DISTANCE := 166.0
const LOCATIONS := ["Original office", "Office copy", "Mailroom", "Gateway"]
const SEALS := ["Pencil", "Stamp", "Envelope"]
@onready var art = $Canvas/View/Viewport/Drawing
@onready var actions := $Canvas/Panel/Stack/Actions
@onready var routes := $Canvas/Panel/Stack/Travel
@onready var location := $Canvas/Panel/Stack/Location
@onready var story := $Canvas/Panel/Stack/Story
@onready var session_menu: ConfirmationDialog = $SessionMenu
var selected_profile: int = 0
const BADGES := ["ADA · H-0317", "NICO · H-0442", "LEA · H-0528"]
var station := 0
var moving := false
var original := false
var page := false
var pass_signed := false
var spoke_to_courier := false
var courier_joined := false
var is_open := false
var stamps: Array[String] = []
var note := ""

func _ready() -> void:
	selected_profile = clampi(selected_profile,0,BADGES.size()-1)
	art.profile = selected_profile
	session_menu.confirmed.connect(func(): return_requested.emit())
	session_menu.canceled.connect(_restore_focus)
	refresh()

func button(row: Control, caption: String, action: Callable) -> Button:
	var control := Button.new()
	control.text = caption
	control.pressed.connect(action)
	row.add_child(control)
	return control

func _input(event: InputEvent) -> void:
	if not is_visible_in_tree() or session_menu.visible or not event.is_action_pressed("ui_cancel"):
		return
	get_viewport().set_input_as_handled()
	if art.photo_open:
		close_photo()
	else:
		session_menu.popup_centered()
		session_menu.get_cancel_button().grab_focus()

func _restore_focus() -> void:
	if not moving:
		refresh()

func refresh() -> void:
	for row in [actions,routes]:
		for child in row.get_children():
			row.remove_child(child)
			child.queue_free()
	location.text = BADGES[selected_profile]+"  /  "+LOCATIONS[station]
	var line := ""
	var focus: Button
	var forward: Button
	match station:
		0:
			if original:
				line = "Wednesday ends at a torn edge. At the next desk, the rest of the sheet sticks out of the same book."
			else:
				line = "Your desk is here twice, right down to the cup ring. The ledger on the first desk is open."
			var ledger := button(actions,"Read the ledger",read_original)
			if not original:
				focus = ledger
		1:
			if art.photo_open:
				line = "The print is dated tomorrow. That’s you at the keyboard. In the margin someone wrote, “Waited for the stamp to dry before slipping this into the envelope.”"
				focus = button(actions,"Pocket the photograph",close_photo)
			else:
				line = "The desk is empty of paper now. Your double has gone back to work. A mail trolley rattles in the next room." if page else "Someone at your desk is typing with your hands. A photograph sticks out of the ledger."
				var photo := button(actions,"Look at the photograph again" if page else "Take the loose page",read_copy)
				if not page:
					focus = photo
		2:
			line = "The courier waits beside the outgoing hatch. Your two names are still wet on the pass." if pass_signed else "The courier holds out a time card. “Thursday’s my day off. They’ve owed me a Thursday for twenty years.”"
			var talk := button(actions,"Talk to the courier",ask_courier)
			if not spoke_to_courier and not pass_signed:
				focus = talk
			if page and not pass_signed:
				var sign_pass := button(actions,"Countersign the pass",share_pass)
				if spoke_to_courier:
					focus = sign_pass
		3:
			line = "There’s no handle on this side. Three brass keys sit below the mail slot. Beside them, a second slot is worn to the width of a pass."
			if is_open:
				line = "The hatch is open. Someone on the far side has already turned the wheel."
				focus = button(actions,"Step through",enter_filesystem)
			else:
				if pass_signed:
					focus = button(actions,"Use the signed pass",use_pass)
				for seal in [SEALS[1],SEALS[2],SEALS[0]]:
					var key := button(actions,seal,apply_seal.bind(seal))
					key.disabled = seal in stamps
					if not focus and not key.disabled:
						focus = key
	if not art.photo_open:
		if station>0:
			button(routes,"‹ "+str(LOCATIONS[station-1]),travel.bind(station-1))
		if station<3:
			forward = button(routes,str(LOCATIONS[station+1])+" ›",travel.bind(station+1))
	story.text = note if not note.is_empty() else line
	if not focus:
		focus = forward
	if focus and not session_menu.visible:
		focus.grab_focus()

func read_original() -> void:
	original = true
	note = "Wednesday 16th. “Sketch it in pencil first. The archivist only stamps finished drawings.” Someone tore out the next sheet."
	refresh()

func read_copy() -> void:
	page = true
	art.page_taken = true
	art.photo_open = true
	note = ""
	refresh()

func close_photo() -> void:
	art.photo_open = false
	art.glance_until = art.time + 3.2
	note = "Your double looks up. Its release date has been rubbed out. On the back of your page, a faded stamp reads INTERNAL MAIL."
	refresh()

func ask_courier() -> void:
	spoke_to_courier = true
	note = "“They let me through when I’m carrying mail. Two names on that page would do it.”" if page else "“Empty hands don’t get past that shutter. A sheet always goes missing between those two desks.”"
	if pass_signed:
		note = "“Both names are there. Take it to the Gateway. Just once I’d like to see where the letters go.”"
	refresh()

func share_pass() -> void:
	pass_signed = true
	note = "The courier puts down the rubber stamp and signs by hand. One pass, two names."
	refresh()

func apply_seal(seal: String) -> void:
	if is_open:
		return
	if not page or not original:
		if not page:
			note = "The rollers turn on nothing. On the glass: INSERT OUTGOING SHEET. The copy desk had a loose page."
		else:
			note = "The rollers spit the sheet back. ORIGINAL ENTRY REQUIRED. The ledger is still open at the first desk."
	elif seal != SEALS[stamps.size()]:
		stamps.clear()
		note = "The sheet slides back, clean. Start with the drawing. The stamp must be dry before the page goes in the envelope."
	else:
		stamps.append(seal)
		note = "Seals applied · "+" → ".join(stamps)
		if stamps.size() == SEALS.size():
			open_gate(false)
	refresh()

func use_pass() -> void:
	if pass_signed:
		open_gate(true)
		refresh()

func open_gate(with_courier: bool) -> void:
	is_open = true
	courier_joined = with_courier
	note = "The shutter rolls up. The courier draws level with you and pockets the pass." if with_courier else "The envelope slips through the hatch. A hand opens it and raises the shutter for you."
	create_tween().tween_property(art,"aperture",1.0,.6)

func travel(destination: int) -> void:
	if art.photo_open or moving or destination < 0 or destination > 3:
		return
	moving = true
	var target_x := destination*BAY_DISTANCE
	art.walking = true
	art.facing = 1 if destination>station else -1
	for row in [actions,routes]:
		for item in row.get_children():
			item.disabled = true
	location.text = "Passage · "+str(LOCATIONS[destination])
	story.text = ""
	var tween := create_tween().set_parallel(true).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(art,"camera_x",target_x,.8)
	tween.tween_property(art,"walk_x",target_x-35,.8)
	await tween.finished
	art.walking = false
	station = destination
	note = ""
	moving = false
	refresh()

func enter_filesystem() -> void:
	if is_open:
		filesystem_requested.emit(courier_joined)
