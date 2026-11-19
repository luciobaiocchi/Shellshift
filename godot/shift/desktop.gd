extends Control

signal gateway_requested

const CONTENT := preload("res://shift/desktop_tasks.gd")
const CARD := preload("res://shift/desktop_card.gd")
const SHEET := preload("res://shift/desktop_paper.gd")
const INK := Color("#263d40")
const NIGHT := Color("#202d39")
const SAGE := Color("#bec2ac")
const PAPER := Color("#e6e0c5")
const GOLD := Color("#edc47d")

var profile := 0
var step := 0
var selected := -1
var score := 0
var reviewing := false
var margin_found := false
var gateway_opened := false

const BADGES := ["H-0317", "H-0442", "H-0528"]

const SHELL := preload("res://shift/workstation_desktop.gd")
const PEOPLE := ["Ada","Nico","Lea"]
var shell: Control
var session_minutes := -1
var boot_time := 0
var folder := "Local disk"
var file_entries: Array = []
var file_list: ItemList
var location_label: Label
var file_preview: Label
var file_open: Button
var file_up: Button
var mail_list: ItemList
var mail_heading: Label
var mail_stamp: Label
var mail_body: Label
var session_detail: Label
var call_sign: Label
var file_label: Label
var date_label: Label
var title_label: Label
var request_label: Label
var tool_title: Label
var note_label: Label
var score_label: Label
var paper: Control
var card_buttons: Array[Button] = []
var next_button: Button
var feed_button: Button
var feed_panel: PanelContainer
var feed_copy: Label
var feed_back: Button
var editor: VBoxContainer

func _ready() -> void:
	var skin: Theme = preload("res://art_direction/terminal_theme.tres").duplicate()
	skin.set_color("font_color","Label",INK)
	for state in ["normal","hover","pressed","disabled","focus"]:
		var box := StyleBoxFlat.new()
		box.bg_color = PAPER if state == "hover" else SAGE
		box.border_color = GOLD if state == "focus" else INK
		box.set_border_width_all(2 if state == "focus" else 1)
		box.draw_center = state != "focus"
		box.content_margin_left = 8
		box.content_margin_right = 8
		box.content_margin_top = 4
		box.content_margin_bottom = 4
		skin.set_stylebox(state,"Button",box)
		skin.set_color("font_color" if state == "normal" else "font_%s_color"%state,"Button",INK)
	skin.set_color("font_disabled_color","Button",Color("#686e64"))
	theme = skin
	_build()
	start(profile)

func _surface(parent: Control, tint: Color, padding: int = 8) -> PanelContainer:
	var panel := PanelContainer.new()
	var box := StyleBoxFlat.new()
	box.bg_color = tint
	for side in [SIDE_LEFT,SIDE_TOP,SIDE_RIGHT,SIDE_BOTTOM]:
		box.set_content_margin(side,padding)
	panel.add_theme_stylebox_override("panel",box)
	parent.add_child(panel)
	return panel

func _text(parent: Control, value: String, color := INK, font_size := 14) -> Label:
	var label := Label.new()
	label.text = value
	label.add_theme_font_size_override("font_size",font_size)
	label.add_theme_color_override("font_color",color)
	parent.add_child(label)
	return label

func _build() -> void:
	shell = SHELL.new()
	add_child(shell)
	shell.logoff_requested.connect(_request_logoff)
	shell.app_opened.connect(_on_app_opened)
	editor = shell.register_window("work","Work tray",Rect2(100,21,591,350))
	editor.add_theme_constant_override("separation",3)
	var header := HBoxContainer.new()
	_surface(editor,PAPER,5).add_child(header)
	title_label = _text(header,"",INK,14)
	title_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	feed_button = _button(header,"Mail",_show_feed)
	var brief := VBoxContainer.new()
	_surface(editor,PAPER,6).add_child(brief)
	score_label = _text(brief,"",Color("#77503e"),12)
	request_label = _text(brief,"")
	request_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	var workspace := HBoxContainer.new()
	editor.add_child(workspace)
	workspace.size_flags_vertical = Control.SIZE_EXPAND_FILL
	var palette := VBoxContainer.new()
	var rail := _surface(workspace,SAGE)
	rail.custom_minimum_size.x = 179
	rail.add_child(palette)
	tool_title = _text(palette,"",INK,13)
	for i in 3:
		var button := CARD.new()
		button.slot = i
		button.alignment = HORIZONTAL_ALIGNMENT_LEFT
		button.pressed.connect(_place.bind(i,Vector2(.50,.54)))
		button.size_flags_vertical = Control.SIZE_EXPAND_FILL
		palette.add_child(button)
		card_buttons.append(button)
	var mat := _surface(workspace,Color("#77877b"),3)
	mat.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	paper = SHEET.new()
	paper.item_placed.connect(_place)
	paper.margin_found.connect(_inspect_margin)
	paper.custom_minimum_size = Vector2(200,121)
	mat.add_child(paper)
	file_label = _text(_surface(editor,Color("#aeb5a1"),3),"",INK,12)
	file_label.clip_text = true
	var footer := HBoxContainer.new()
	_surface(editor,NIGHT).add_child(footer)
	note_label = _text(footer,"",PAPER,13)
	note_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	note_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	next_button = Button.new()
	next_button.pressed.connect(_advance)
	footer.add_child(next_button)
	_build_files(shell.register_window("files","File cabinet",Rect2(126,37,528,304)))
	_build_mail(shell.register_window("mail","Mail",Rect2(146,57,517,284)))
	var session: Control = shell.register_window("session","Session manager",Rect2(182,107,387,170))
	var release := VBoxContainer.new()
	_surface(session,PAPER,12).add_child(release)
	_text(release,"Log off",INK,17)
	session_detail = _text(release,"",INK,13)
	session_detail.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_button(session,"Return to session",func(): shell._hide_window("session",true))
	call_sign = shell.owner_label
	date_label = shell.clock_label

func _button(parent: Control, caption: String, callback: Callable) -> Button:
	var b := Button.new()
	b.text = caption
	b.add_theme_font_size_override("font_size",12)
	b.pressed.connect(callback)
	parent.add_child(b)
	return b

func _list(parent: Control) -> ItemList:
	var list := ItemList.new()
	list.size_flags_vertical = Control.SIZE_EXPAND_FILL
	list.allow_reselect = true
	list.add_theme_font_size_override("font_size",12)
	list.add_theme_color_override("font_color",INK)
	list.add_theme_color_override("font_selected_color",PAPER)
	var mat := StyleBoxFlat.new()
	mat.bg_color = Color("#e4dfcb")
	mat.content_margin_left = 6
	mat.content_margin_top = 5
	list.add_theme_stylebox_override("panel",mat)
	var selected_row := StyleBoxFlat.new()
	selected_row.bg_color = Color("#405b58")
	list.add_theme_stylebox_override("selected",selected_row)
	list.add_theme_stylebox_override("selected_focus",selected_row)
	parent.add_child(list)
	return list

func _build_files(host: VBoxContainer) -> void:
	var toolbar := HBoxContainer.new()
	host.add_child(toolbar)
	file_up = _button(toolbar,"↑ Up",_folder_up)
	location_label = _text(toolbar,"",INK,12)
	location_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var split := HBoxContainer.new()
	split.size_flags_vertical = Control.SIZE_EXPAND_FILL
	host.add_child(split)
	var sidebar := VBoxContainer.new()
	split.add_child(sidebar)
	sidebar.custom_minimum_size.x = 92
	for section in ["Local disk","Home","Work","Devices"]:
		var key := _button(sidebar,section,_browse.bind(section))
		key.alignment = HORIZONTAL_ALIGNMENT_LEFT
	var main := VBoxContainer.new()
	main.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	split.add_child(main)
	file_list = _list(main)
	file_list.item_selected.connect(_select_file)
	file_list.item_activated.connect(_open_file)
	var preview := _surface(main,PAPER,6)
	preview.custom_minimum_size.y = 73
	file_preview = _text(preview,"",INK,12)
	file_preview.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	file_open = _button(main,"Open",_open_selected_file)

func _open_selected_file() -> void:
	if not file_list.get_selected_items().is_empty():
		_open_file(file_list.get_selected_items()[0])

func _build_mail(host: VBoxContainer) -> void:
	var split := HBoxContainer.new()
	split.size_flags_vertical = Control.SIZE_EXPAND_FILL
	host.add_child(split)
	var box := VBoxContainer.new()
	box.custom_minimum_size.x = 170
	split.add_child(box)
	_text(_surface(box,SAGE,4),"  Local mailbox",INK,12)
	mail_list = _list(box)
	mail_list.item_selected.connect(_read_mail)
	mail_list.item_activated.connect(_read_mail)
	var page := VBoxContainer.new()
	var mail_paper := _surface(split,PAPER,10)
	mail_paper.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	mail_paper.add_child(page)
	mail_stamp = _text(page,"",Color("#79523d"),11)
	mail_heading = _text(page,"",INK,14)
	mail_heading.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	page.add_child(HSeparator.new())
	var reading := ScrollContainer.new()
	reading.size_flags_vertical = Control.SIZE_EXPAND_FILL
	reading.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	page.add_child(reading)
	mail_body = _text(reading,"",INK,13)
	mail_body.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	mail_body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART

func _browse(new_folder: String) -> void:
	folder = new_folder
	var own_name: String = PEOPLE[profile].to_lower()
	var roots := {"Local disk":"/","Home":"/home/"+own_name,"Work":"/work/"+BADGES[profile],"Devices":"/devices","Letters":"/home/"+own_name+"/letters"}
	location_label.text = "  Local disk   "+roots[folder]
	file_up.disabled = folder == "Local disk"
	match folder:
		"Local disk": file_entries = [["Home","Directory","folder"],["Work","Directory","folder"],["Devices","Directory","folder"]]
		"Home": file_entries = [["Letters","Directory","folder"],[CONTENT.OLD_FILE[profile],CONTENT.PRIVATE_FILE[profile],"read"]]
		"Letters": file_entries = [[CONTENT.LETTER_NAMES[profile],CONTENT.LETTERS[profile],"read"],["unsent.txt",CONTENT.MEMORY[profile],"read"]]
		"Work":
			file_entries = [[CONTENT.WORK_FILE[profile],CONTENT.DOCUMENTS[profile]+"  ·  Assigned to "+BADGES[profile],"work"],["intake.msg",CONTENT.INTAKE[profile],"read"]]
			if step >= 2 or step == 1 and reviewing: file_entries.append(["old_name.idx",CONTENT.OLD_FILE[profile]+"  →  "+CONTENT.WORK_FILE[profile]+"
The two names share one sheet.","read"])
		"Devices": file_entries = [["local-volume","Mounted. Read / write. Backups remain inside the facility.","read"],["external-line","Line disconnected. No external provider is configured.","read"],["print-spool","A carbon is caught under page 12." if step == 3 else "No sheets waiting.","read"]]
	file_list.clear()
	for entry in file_entries:
		file_list.add_item(("▸  " if entry[2] == "folder" else "   ")+str(entry[0]))
	file_list.select(0)
	_select_file(0)

func _select_file(i: int) -> void:
	if i < 0 or i >= file_entries.size(): return
	var e: Array = file_entries[i]
	file_preview.text = str(e[0])+"
"+ ("File folder" if e[2] == "folder" else "Local document" if e[2] == "read" else str(e[1]))
	file_open.text = "Read file" if e[2] == "read" else "Open"

func _open_file(i: int) -> void:
	if i < 0 or i >= file_entries.size(): return
	var e: Array = file_entries[i]
	match e[2]:
		"folder": _browse(e[0])
		"work": shell.open_app("work")
		_: file_preview.text = str(e[1])

func _folder_up() -> void:
	_browse("Home" if folder == "Letters" else "Local disk")

func _refresh_mail() -> void:
	var at := maxi(0,mail_list.get_selected_items()[0] if not mail_list.get_selected_items().is_empty() else 0)
	mail_list.clear()
	for subject in ["Transfer receipt","Staff circular","Unsent letter"]:
		mail_list.add_item(subject)
	if step > 0 or reviewing: mail_list.add_item("Printer notice")
	mail_list.select(mini(at,mail_list.item_count-1))
	_read_mail(mail_list.get_selected_items()[0])

func _read_mail(i: int) -> void:
	var from := "Intake office"
	var body: String = CONTENT.INTAKE[profile]
	match i:
		1:
			from = "Staff bulletin"
			body = CONTENT.FEED[mini(step+int(reviewing),3)].replace("H-0442",paper.witness)
		2:
			from = PEOPLE[profile]+"   ·   Drafts"
			body = CONTENT.MEMORY[profile]
		3:
			from = "Local print service"
			body = "Two cursors opened the same sheet. A second print head is recording strokes under the numbered edge."
	mail_stamp.text = "FROM   "+from
	mail_heading.text = mail_list.get_item_text(i)
	mail_body.text = body

func _on_app_opened(id: String) -> void:
	match id:
		"mail": _refresh_mail()
		"files": _browse(folder)

func _request_logoff() -> void:
	session_detail.text = "The workstation is ready to sign out. Your shift has no release signature. The local session will remain active."
	if step == 3: session_detail.text = "One print job is holding the session open. The carbon on sheet 12 is still under the roller."
	shell.open_app("session")

func _process(_delta: float) -> void:
	if not date_label: return
	var minutes := int((Time.get_ticks_msec()-boot_time)/60000.0)
	if minutes != session_minutes:
		session_minutes = minutes
		var t := (15*60+53+minutes)%1440
		date_label.text = "%s   %02d:%02d " % [CONTENT.DATES[step],t/60,t%60]

func start(role: int) -> void:
	profile = clampi(role,0,2)
	if not is_node_ready():
		return
	step = 0
	score = 0
	margin_found = false
	gateway_opened = false
	selected = -1
	reviewing = false
	boot_time = Time.get_ticks_msec()
	session_minutes = -1
	folder = "Local disk"
	for key in ["mail","files","session"]:
		shell._hide_window(key,true)
	call_sign.text = PEOPLE[profile]+"  /  "+BADGES[profile]+"  ●"
	shell.rename_app("work",CONTENT.APPS[profile])
	shell.open_app("work")
	paper.witness = "H-0317" if profile == 1 else "H-0442"
	paper.role = profile
	_show_request()

func _show_request() -> void:
	session_minutes = -1
	title_label.text = CONTENT.WORK_FILE[profile]
	score_label.text = "Supervisor   /   order %d of 3   /   credit %d" % [mini(step+1,3),score]
	tool_title.text = CONTENT.TOOLS[profile]
	paper.margin_enabled = step == 3
	paper.revealed = margin_found
	paper.selected = -1
	paper.revision = mini(step,2)
	_set_file_fault(step)
	paper.anchor = Vector2(.5,.54)
	paper.page_offset = Vector2.ZERO
	paper.dragging_sheet = false
	paper.queue_redraw()
	if step == 3:
		request_label.text = "The file is closed. A corner of page 12 is still outside the cover."
		for button in card_buttons:
			button.hide()
		note_label.text = "Something is written beneath the carbon."
		next_button.text = "Lift carbon"
		next_button.disabled = false
		next_button.grab_focus()
		return
	var entry: Array = CONTENT.ROUNDS[profile][step]
	request_label.text = entry[0]
	for i in card_buttons.size():
		card_buttons[i].text = entry[1][i]
		card_buttons[i].show()
		card_buttons[i].disabled = false
	note_label.text = "Draft  ·  no attachment"
	next_button.text = "Submit"
	next_button.disabled = true
	card_buttons[0].grab_focus()

func _place(slot: int, point: Vector2) -> void:
	if step >= 3 or reviewing or not editor.is_visible_in_tree():
		return
	selected = slot
	paper.anchor = point
	paper.selected = slot
	paper.caption = CONTENT.ROUNDS[profile][step][1][slot]
	paper.queue_redraw()
	note_label.text = "Draft saved  ·  one attachment"
	next_button.disabled = false

func _advance() -> void:
	if step == 3:
		if margin_found:
			if not gateway_opened:
				gateway_opened = true
				gateway_requested.emit()
		else:
			_inspect_margin()
		return
	if reviewing:
		step += 1
		selected = -1
		reviewing = false
		_show_request()
		return
	if selected < 0:
		return
	var entry: Array = CONTENT.ROUNDS[profile][step]
	var matched: bool = selected == entry[2]
	var points := 30 if matched else 10
	score += points
	reviewing = true
	for button in card_buttons:
		button.disabled = true
	score_label.text = "RECEIPT   ·   +%d POINTS   ·   TOTAL %d" % [points,score]
	request_label.text = entry[3] if matched else "You chose “%s”. Filed under exception. Liability stays with you." % entry[1][selected]
	_set_file_fault(step+1)
	note_label.text = [
		CONTENT.FIRST_FAULT[profile] + " See the bulletin.",
		"The file you closed just printed its old name. Both paths point here.",
		"The file is ready. A second sheet is caught in the binding."
	][step]
	next_button.text = "Open revision" if step < 2 else "File document"
	next_button.grab_focus()

func _inspect_margin() -> void:
	if step != 3 or margin_found:
		return
	margin_found = true
	paper.revealed = true
	paper.queue_redraw()
	request_label.text = "Someone writes back. “I can hold the hatch from this side. Push when you’re ready.”"
	note_label.text = "Page 12   /   connected to " + paper.witness
	next_button.text = "Push the sheet"
	next_button.grab_focus()

func _show_feed() -> void:
	shell.open_app("mail")
	mail_list.select(1)
	_read_mail(1)
	mail_list.grab_focus()

func _hide_feed() -> void:
	shell.open_app("work")

func _set_file_fault(count: int) -> void:
	var current: String = "desk/" + BADGES[profile] + "/" + str(CONTENT.WORK_FILE[profile])
	var previous := "home/" + str(CONTENT.OLD_FILE[profile])
	paper.fault = count
	paper.echo = CONTENT.MARGIN_ECHO[profile]
	paper.queue_redraw()
	match count:
		0: file_label.text = "FILE   " + current
		1: file_label.text = "FILE   " + current + "   /   2 cursors attached"
		2: file_label.text = "RECEIPT   " + current + "   =>   " + previous
		_: file_label.text = "MARGIN   " + current + "   +   " + paper.witness + "/page12"
