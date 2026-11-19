extends Control
## Silent archive film, drawn on a 208 × 70 virtual film frame.

const INK := Color("#101a1d")
const STEEL := Color("#52645e")
const PAPER := Color("#c6bfa0")
const SHADE := Color("#918e78")
const AMBER := Color("#e2aa62")
var shot := 0
var elapsed := 0.0

func show_shot(index: int) -> void:
	shot = index
	elapsed = 0.0
	show()
	queue_redraw()

func _process(delta: float) -> void:
	if is_visible_in_tree():
		elapsed += delta
		queue_redraw()

func block(x: float, y: float, width: float, height: float, color: Color) -> void:
	draw_rect(Rect2(x, y, width, height), color)

func shape(points: Array, color: Color) -> void:
	draw_colored_polygon(PackedVector2Array(points), color)

func _draw() -> void:
	draw_set_transform(Vector2.ZERO, 0, size / Vector2(208, 70))
	block(0, 0, 208, 70, INK)
	if shot == 2:
		if elapsed < 0.16:
			block(0, 0, 208, 70, PAPER)
			return
		var fall := clampf((elapsed - 0.16) / 0.55, 0, 1)
		block(0, 58, 208, 1, STEEL)
		block(91, 58, 31, 1, Color.BLACK)
		var book_y := floorf(14 + 40 * fall * fall)
		block(92, book_y, 28, 4, SHADE)
		block(91, book_y, 30, 1, AMBER)
		return
	for x in range(0, 208, 16):
		block(x, 6, 1, 48, Color("#233134"))
	block(0, 54, 208, 16, STEEL)
	block(0, 56, 208, 2, INK)
	if shot == 0:
		# Two leaves meet at the spine; the cuff enters from the lower left.
		shape([Vector2(36,12),Vector2(88,17),Vector2(98,58),Vector2(33,50)], SHADE)
		shape([Vector2(88,17),Vector2(148,9),Vector2(158,47),Vector2(98,58)], PAPER)
		for i in range(4):
			draw_line(Vector2(44,22+i*5),Vector2(76,25+i*5),STEEL,1)
		for star in [Vector2(110,29),Vector2(122,24),Vector2(134,20)]:
			draw_rect(Rect2(star,Vector2(2,2)),INK)
		shape([Vector2(0,49),Vector2(31,40),Vector2(51,43),Vector2(37,54),Vector2(0,66)],INK)
		shape([Vector2(31,40),Vector2(49,38),Vector2(67,32),Vector2(68,35),Vector2(50,47),Vector2(37,51)],AMBER)
	else:
		# Wrist on the intake counter, opposite the robot's optical head.
		block(0, 36, 82, 14, SHADE)
		block(48, 34, 14, 18, PAPER)
		for x in [50, 53, 57, 59]:
			block(x, 36, 1, 12, INK)
		block(154, 10, 54, 10, STEEL)
		block(145, 16, 27, 13, SHADE)
		block(142, 26, 19, 5, INK)
		block(144, 29, 12, 2, AMBER)
		var scan_x := floorf(49 + 11 * (0.5 + 0.5 * sin(elapsed * 3)))
		draw_line(Vector2(149,31),Vector2(scan_x,40),AMBER,1)
