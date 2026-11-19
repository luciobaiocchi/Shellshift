extends Control
## The local window manager. Programs retain their documents when dismissed.
signal app_opened(id: String)
signal logoff_requested

const DARK := Color("#243538")
const SLATE := Color("#45565a")
const SILVER := Color("#cbcbb9")
const PAPER := Color("#e4debf")
const GOLD := Color("#e4b674")
const MOSS := Color("#506860")
const APP_IDS := ["work","files","mail"]
const DESK_LABELS := ["Work tray","Local disk","Mail"]

class DeskIcon extends Button:
	var kind := 0
	const LIGHT := Color("#e1ddba")
	const DARK := Color("#253b3a")
	const OCHRE := Color("#d4a965")
	func _draw() -> void:
		var a := Vector2(floor(size.x/2)-14,7)
		draw_set_transform(a)
		match kind:
			0:
				draw_rect(Rect2(0,8,28,18),DARK)
				draw_rect(Rect2(2,10,24,13),OCHRE)
				draw_rect(Rect2(4,3,20,16),DARK)
				draw_rect(Rect2(5,4,18,14),LIGHT)
				for i in 3:
					draw_line(Vector2(8,7+i*3),Vector2(19-i,7+i*3),DARK)
				draw_rect(Rect2(5,17,19,6),OCHRE)
			1:
				draw_rect(Rect2(1,4,13,5),DARK)
				draw_rect(Rect2(1,7,27,18),DARK)
				draw_rect(Rect2(2,5,10,4),OCHRE)
				draw_rect(Rect2(2,9,24,13),OCHRE)
				draw_rect(Rect2(5,11,16,2),LIGHT)
				draw_line(Vector2(3,22),Vector2(25,22),LIGHT)
			2:
				draw_rect(Rect2(0,6,29,19),DARK)
				draw_rect(Rect2(1,7,26,16),LIGHT)
				draw_polyline(PackedVector2Array([Vector2(1,7),Vector2(14,16),Vector2(27,7)]),DARK,2)
				draw_rect(Rect2(20,8,4,4),OCHRE)
		draw_set_transform(Vector2.ZERO)
		draw_string(get_theme_default_font(),Vector2(0,49),DESK_LABELS[kind],HORIZONTAL_ALIGNMENT_CENTER,size.x,12,LIGHT)

var layer := Control.new()
var shelf := HBoxContainer.new()
var owner_label := Label.new()
var clock_label := Label.new()
var menu_button := MenuButton.new()
var windows := {}
var active := ""
var moving := ""
var drag_from := Vector2.ZERO
var desktop_icons: Array[Button] = []

func _ready() -> void:
	set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	mouse_filter = MOUSE_FILTER_PASS
	_build_desktop()
	resized.connect(_contain_all)
	get_viewport().gui_focus_changed.connect(_on_keyboard_focus)

func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO,size),MOSS)
	var mid := Vector2(size.x*.70,size.y*.60)
	var pen := Color("#63786b")
	for band in 9:
		var dims := Vector2(104+band*11,52+band*5)
		var arc := PackedVector2Array()
		for k in 81:
			var angle := TAU*k/80
			var rel := Vector2(cos(angle)*dims.x,sin(angle)*dims.y).rotated(-.32)
			arc.append(mid + rel)
		draw_polyline(arc,pen)
	for x in range(20,int(size.x),20):
		for y in range(36,int(size.y)-40,20):
			draw_rect(Rect2(x,y,1,1),Color("#6a7c6b"))
	draw_rect(Rect2(0,0,size.x,24),DARK)
	draw_rect(Rect2(0,23,size.x,1),Color("#849281"))
	draw_string(get_theme_default_font(),Vector2(14,16),"CONTINUITY   /   LOCAL WORKSTATION",HORIZONTAL_ALIGNMENT_LEFT,-1,11,PAPER)
	draw_string(get_theme_default_font(),Vector2(14,size.y-49),"ASTER SYSTEMS",HORIZONTAL_ALIGNMENT_LEFT,-1,10,Color("#c1c4a5"))

func _panel_style(fill: Color, outline: Color, shadow := false) -> StyleBoxFlat:
	var b := StyleBoxFlat.new()
	b.bg_color = fill
	b.border_color = outline
	b.set_border_width_all(1)
	if shadow:
		b.shadow_color = Color(0.06,0.1,0.1,.45)
		b.shadow_size = 2
		b.shadow_offset = Vector2(3,4)
	return b

func _build_desktop() -> void:
	var rail := VBoxContainer.new()
	add_child(rail)
	rail.position = Vector2(8,33)
	rail.add_theme_constant_override("separation",8)
	for i in APP_IDS.size():
		var icon := DeskIcon.new()
		icon.kind = i
		icon.name = "Launcher" + APP_IDS[i].capitalize()
		icon.tooltip_text = "Open " + DESK_LABELS[i]
		icon.custom_minimum_size = Vector2(78,54)
		icon.flat = true
		icon.pressed.connect(open_app.bind(APP_IDS[i]))
		rail.add_child(icon)
		desktop_icons.append(icon)
	add_child(owner_label)
	owner_label.set_anchors_and_offsets_preset(PRESET_TOP_RIGHT)
	owner_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	owner_label.offset_left = -238
	owner_label.offset_right = -12
	owner_label.offset_top = 2
	owner_label.add_theme_color_override("font_color",PAPER)
	owner_label.add_theme_font_size_override("font_size",11)
	add_child(layer)
	layer.set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	layer.offset_top = 26
	layer.offset_bottom = -37
	layer.mouse_filter = MOUSE_FILTER_IGNORE
	var dock := Panel.new()
	dock.add_theme_stylebox_override("panel",_panel_style(SILVER,DARK))
	add_child(dock)
	dock.set_anchors_and_offsets_preset(PRESET_BOTTOM_WIDE)
	dock.offset_top = -34
	dock.add_child(shelf)
	shelf.set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	shelf.offset_left = 4
	shelf.offset_right = -4
	shelf.offset_top = 3
	shelf.offset_bottom = -3
	menu_button.text = "▦  Desk"
	menu_button.name = "DeskMenu"
	menu_button.flat = false
	menu_button.focus_mode = FOCUS_ALL
	menu_button.add_theme_font_size_override("font_size",12)
	shelf.add_child(menu_button)
	var menu := menu_button.get_popup()
	for i in APP_IDS.size():
		menu.add_item(["Work tray","File cabinet","Mail"][i],i)
	menu.add_separator()
	menu.add_item("Show desktop",8)
	menu.add_item("Log off…",9)
	menu.id_pressed.connect(_menu_selected)
	var spacer := Control.new()
	spacer.size_flags_horizontal = SIZE_EXPAND_FILL
	shelf.add_child(spacer)
	clock_label.name = "Clock"
	clock_label.add_theme_font_size_override("font_size",12)
	clock_label.add_theme_color_override("font_color",DARK)
	shelf.add_child(clock_label)

func _menu_selected(action: int) -> void:
	if action < 3: open_app(APP_IDS[action])
	elif action == 8:
		for id in windows:
			windows[id].panel.hide()
		_focus_window("")
		menu_button.grab_focus()
	elif action == 9:
		logoff_requested.emit()

func register_window(id: String, title: String, rect: Rect2) -> VBoxContainer:
	var panel := Panel.new()
	panel.name = id.capitalize()+"Window"
	panel.position = rect.position
	panel.size = rect.size
	panel.add_theme_stylebox_override("panel",_panel_style(SILVER,DARK,true))
	panel.hide()
	layer.add_child(panel)
	var stack := VBoxContainer.new()
	panel.add_child(stack)
	stack.set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	stack.offset_left = 3
	stack.offset_right = -3
	stack.offset_top = 3
	stack.offset_bottom = -3
	stack.add_theme_constant_override("separation",3)
	var cap := PanelContainer.new()
	cap.mouse_default_cursor_shape = CURSOR_MOVE
	stack.add_child(cap)
	var row := HBoxContainer.new()
	row.mouse_filter = MOUSE_FILTER_PASS
	cap.add_child(row)
	var nameplate := Label.new()
	nameplate.mouse_filter = MOUSE_FILTER_IGNORE
	nameplate.text = "  "+title
	nameplate.add_theme_font_size_override("font_size",13)
	nameplate.add_theme_color_override("font_color",PAPER)
	nameplate.size_flags_horizontal = SIZE_EXPAND_FILL
	row.add_child(nameplate)
	for item in [["−","Minimize",false],["×","Close",true]]:
		var b := Button.new()
		b.name = item[1]
		b.text = item[0]
		b.tooltip_text = item[1]
		b.add_theme_font_size_override("font_size",13)
		b.custom_minimum_size.x = 26
		b.pressed.connect(_hide_window.bind(id,item[2]))
		row.add_child(b)
	cap.gui_input.connect(_title_input.bind(id))
	var body := VBoxContainer.new()
	body.name = "Program"
	body.size_flags_vertical = SIZE_EXPAND_FILL
	stack.add_child(body)
	var task := Button.new()
	task.name = id.capitalize()+"Task"
	task.text = title
	task.add_theme_font_size_override("font_size",12)
	task.clip_text = true
	task.custom_minimum_size = Vector2(88,20)
	task.pressed.connect(_shelf_pressed.bind(id))
	shelf.add_child(task)
	shelf.move_child(task,shelf.get_child_count()-3)
	task.hide()
	windows[id] = {"panel":panel,"cap":cap,"label":nameplate,"task":task,"body":body}
	_contain(panel)
	return body

func rename_app(id: String,title: String) -> void:
	windows[id].label.text = "  "+title
	windows[id].task.text = title

func open_app(id: String) -> void:
	if not windows.has(id): return
	windows[id].panel.show()
	windows[id].task.show()
	_focus_window(id)
	app_opened.emit(id)
	var first := (windows[id].body as Control).find_next_valid_focus()
	if first and windows[id].body.is_ancestor_of(first): first.grab_focus()

func _shelf_pressed(id: String) -> void:
	if id == active and windows[id].panel.visible:
		_hide_window(id,false)
	else:
		open_app(id)

func _hide_window(id: String, close: bool) -> void:
	windows[id].panel.hide()
	if close: windows[id].task.hide()
	_focus_window("")
	for i in range(layer.get_child_count()-1,-1,-1):
		var front := layer.get_child(i)
		if front.visible:
			for key in windows:
				if front == windows[key].panel:
					_focus_window(key)
					return
	menu_button.grab_focus()

func _focus_window(id: String) -> void:
	if id == active: return
	active = id
	for key in windows:
		var fill := Color("#30514f") if key == id else SLATE
		windows[key].cap.add_theme_stylebox_override("panel",_panel_style(fill,fill))
		windows[key].task.add_theme_color_override("font_color",Color("#7d492d") if key == id else DARK)
	if not id.is_empty(): windows[id].panel.move_to_front()

func _window_for(node: Control) -> String:
	if node:
		for id in windows:
			if windows[id].panel == node or windows[id].panel.is_ancestor_of(node): return id
	return ""

func _on_keyboard_focus(node: Control) -> void:
	var id := _window_for(node)
	if not id.is_empty() and windows[id].panel.visible: _focus_window(id)

func _title_input(event: InputEvent, id: String) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		moving = id
		drag_from = event.global_position - windows[id].panel.global_position
		_focus_window(id)

func _input(event: InputEvent) -> void:
	if not is_visible_in_tree(): return
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			var id := _window_for(get_viewport().gui_get_hovered_control())
			if not id.is_empty(): _focus_window(id)
		else: moving = ""
	if event is InputEventMouseMotion and not moving.is_empty():
		var panel: Control = windows[moving].panel
		panel.global_position = (event.position-drag_from).round()
		_contain(panel)
	if event is InputEventKey and event.pressed and not event.echo:
		if event.ctrl_pressed and event.keycode == KEY_TAB:
			var first := APP_IDS.find(active)
			for i in range(1,APP_IDS.size()+1):
				var next: String = APP_IDS[posmod(first+i,APP_IDS.size())]
				if windows[next].task.visible:
					open_app(next)
					break
			get_viewport().set_input_as_handled()
		elif event.keycode == KEY_ESCAPE and not active.is_empty() and not menu_button.get_popup().visible:
			_hide_window(active,false)
			get_viewport().set_input_as_handled()

func _contain(p: Control) -> void:
	p.position = p.position.clamp(Vector2.ZERO, (layer.size-p.size).max(Vector2.ZERO))

func _contain_all() -> void:
	for data in windows.values(): _contain(data.panel)
	queue_redraw()
