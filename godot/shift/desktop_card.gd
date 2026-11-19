extends Button
## Each item has an equivalent keyboard action through the native Button.
var slot := 0

func _get_drag_data(_position: Vector2) -> Variant:
	var preview := Label.new()
	preview.text = text
	preview.add_theme_color_override("font_color", Color("#fff2ba"))
	preview.add_theme_color_override("font_outline_color", Color("#12292c"))
	preview.add_theme_constant_override("outline_size", 5)
	set_drag_preview(preview)
	return {"shift_item": slot}
