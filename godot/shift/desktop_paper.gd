extends Control

signal item_placed(slot: int, point: Vector2)
signal margin_found

const INK := Color("#263d40")
const RED := Color("#a85a47")
const PAPER := Color("#ded7b9")
const GUIDE := Color("#a9ac91")
const TITLES := ["FIELD ATLAS", "QUEUE PLAN", "INTERNAL RECORD"]

var role := 0
var witness := "H-0442"
var caption := ""
var fault := 0
var echo := ""
var selected := -1
var revision := 0
var anchor := Vector2(.50,.55)
var margin_enabled := false
var revealed := false
var dragging_sheet := false
var press_position := Vector2.ZERO
var page_offset := Vector2.ZERO

func _ready() -> void:
	mouse_default_cursor_shape = Control.CURSOR_CROSS

func _can_drop_data(_point: Vector2, data: Variant) -> bool:
	return not margin_enabled and data is Dictionary and data.has("shift_item")

func _drop_data(point: Vector2, data: Variant) -> void:
	item_placed.emit(data.shift_item, (point / size).clamp(Vector2(.28,.42), Vector2(.72,.61)))

func _gui_input(event: InputEvent) -> void:
	if not margin_enabled or revealed:
		return
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		dragging_sheet = event.pressed
		press_position = event.position
		if not event.pressed:
			page_offset = Vector2.ZERO
			queue_redraw()
	elif event is InputEventMouseMotion and dragging_sheet:
		page_offset = (event.position - press_position).limit_length(58)
		if page_offset.length() > 40:
			dragging_sheet = false
			page_offset = Vector2.ZERO
			margin_found.emit()
		queue_redraw()

func _draw() -> void:
	var font := get_theme_default_font()
	var sheet := Rect2(Vector2(12,8)+page_offset, size-Vector2(25,19))
	draw_rect(Rect2(sheet.position+Vector2(3,4),sheet.size),INK)
	draw_rect(sheet,PAPER)
	draw_set_transform(sheet.position)
	var w := sheet.size.x
	var h := sheet.size.y
	draw_string(font,Vector2(12,21), "PERSONAL ARCHIVE" if revealed else TITLES[role],HORIZONTAL_ALIGNMENT_LEFT,-1,13,INK)
	draw_line(Vector2(12,28),Vector2(w-12,28),INK)
	if fault > 0 and not revealed:
		var tip := Vector2(w-24,18)
		match role:
			0:
				draw_line(tip-Vector2(16,3),tip-Vector2(10,7),INK,1)
				draw_line(tip-Vector2(8,3),tip-Vector2(2,7),RED,1)
			1:
				draw_rect(Rect2(tip-Vector2(18,10),Vector2(4,9)),INK)
				draw_rect(Rect2(tip-Vector2(9,10),Vector2(4,9)),RED)
			2:
				draw_line(tip-Vector2(30,2),tip-Vector2(20,7),INK,2)
				draw_line(tip-Vector2(22,0),tip-Vector2(12,5),RED,2)
	if fault >= 3 and not revealed:
		draw_rect(Rect2(w*.44,h-46,w*.56,22),Color("#c7b995"))
		draw_line(Vector2(w*.44,h-46),Vector2(w,h-46),GUIDE)
		draw_string(font,Vector2(w*.44+5,h-31),echo,HORIZONTAL_ALIGNMENT_LEFT,w*.56-5,11,RED)
	if revealed:
		draw_string(font,Vector2(16, h*.51),"“It moved.”",HORIZONTAL_ALIGNMENT_LEFT,-1,17,RED)
		draw_string(font,Vector2(16, h*.51+19),witness + "   /   on the other side",HORIZONTAL_ALIGNMENT_LEFT,-1,12,INK)
	else:
		var middle := Vector2(w*anchor.x, h*anchor.y)
		if role == 0:
			var image_type: String = [["seal","notebook","dome"],["seal","notebook","date"],["link","chart","notebook"]][revision][selected] if selected >= 0 else "blank"
			_draw_slide(image_type,middle,font)
		elif role == 1:
			for i in 3:
				var node := Rect2(middle+Vector2(-66+i*49,-12),Vector2(34,22))
				draw_rect(node,RED if selected == i else INK,false,2)
				draw_string(font,node.position+Vector2(10,16),str(i+1),HORIZONTAL_ALIGNMENT_LEFT,-1,12,INK)
				if i < 2: draw_line(node.position+Vector2(34,11),node.position+Vector2(48,11),INK)
		else:
			for i in 3:
				var start := middle+Vector2(-65,-13+i*13)
				draw_rect(Rect2(start,Vector2(76+14*(i%2),4)),INK if i == selected else GUIDE)
				if i == selected: draw_line(start+Vector2(-8,0),start+Vector2(90,4),RED,2)
		if selected >= 0:
			draw_string(font,Vector2(12,h-11),caption,HORIZONTAL_ALIGNMENT_LEFT,w-37,13,RED)
	draw_string(font,Vector2(w-28,h-10),"12" if margin_enabled else "01",HORIZONTAL_ALIGNMENT_LEFT,-1,11,INK)
	draw_set_transform(Vector2.ZERO)


func _draw_slide(image_type: String, at: Vector2, font: Font) -> void:
	var bounds := Rect2(at-Vector2(90,47), Vector2(180,94))
	# Printed crop marks establish scale and make the placement target visible.
	for horizontal in [-1,1]:
		for vertical in [-1,1]:
			var corner := at+Vector2(horizontal*90,vertical*47)
			draw_line(corner,corner+Vector2(-horizontal*10,0),GUIDE)
			draw_line(corner,corner+Vector2(0,-vertical*10),GUIDE)
	match image_type:
		"notebook","blank","link":
			var c := GUIDE if image_type == "blank" else INK
			for i in 4:
				draw_line(at+Vector2(-72,-25+i*16),at+Vector2(72,-25+i*16),GUIDE)
			for i in 5:
				draw_line(at+Vector2(-58+i*29,-32),at+Vector2(-58+i*29,30),GUIDE)
			var stars := [Vector2(-64,17),Vector2(-47,5),Vector2(-29,-14),Vector2(8,-1),Vector2(52,-20)]
			for i in stars.size():
				var p: Vector2 = at + stars[i]
				if i > 0:
					draw_line(at+stars[i-1],p,c)
				draw_rect(Rect2(p-Vector2(2,2),Vector2(4,4)),c)
			draw_arc(at+stars.back(),7,0,TAU,12,RED,1)
			if image_type == "link":
				draw_line(bounds.position,bounds.end,RED,2)
		"seal":
			var corners := PackedVector2Array([at+Vector2(-43,22),at+Vector2(-11,-30),at+Vector2(1,-12),at+Vector2(-20,22)])
			draw_colored_polygon(corners,INK)
			draw_colored_polygon(PackedVector2Array([at+Vector2(-9,22),at+Vector2(15,-17),at+Vector2(41,22)]),RED)
		"dome":
			draw_arc(at,32,PI,TAU,18,INK,2)
			draw_line(at-Vector2(39,0),at+Vector2(39,0),INK,2)
			draw_rect(Rect2(at+Vector2(-32,1),Vector2(64,19)),INK)
			draw_rect(Rect2(at+Vector2(9,4),Vector2(8,16)),PAPER)
			draw_line(at+Vector2(-13,-27),at+Vector2(-20,-7),RED,3)
		"date":
			draw_string(font,at+Vector2(-72,4),"THU  /  16:00",HORIZONTAL_ALIGNMENT_LEFT,-1,17,INK)
		"chart":
			for i in 5:
				draw_rect(Rect2(at+Vector2(-50+i*24,22-7*i),Vector2(15,8+7*i)),GUIDE)
