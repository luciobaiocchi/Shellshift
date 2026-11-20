extends Control
## Real-time archive film. The 3D stage is drawn behind the captions.
signal finished

const SCRIPT := preload("res://screenplay.gd")
const SECONDS := SCRIPT.SECONDS
var profile := 0
var shot: int = SCRIPT.SHOT_ORDER[0]
var elapsed := 0.0
var office_take := OS.get_cmdline_user_args().has("--programmatori")
@onready var score: AudioStreamPlayer = $Score

func start() -> void:
	profile = clampi(profile,0,SCRIPT.NAMES.size()-1)
	select_shot(0 if office_take else SCRIPT.SHOT_ORDER[0])
	score.play(_start_time(shot))
	show()

func _start_time(index: int) -> float:
	var seconds := 0.0
	for reel: int in SCRIPT.SHOT_ORDER:
		if reel == index:
			break
		seconds += SECONDS[reel]
	return seconds

func stop() -> void:
	score.stop()
	hide()
	$Screen/View/Stage.end_film()

func select_shot(index: int) -> void:
	shot = index
	elapsed = 0.0
	queue_redraw()

func _process(delta: float) -> void:
	if not is_visible_in_tree():
		return
	elapsed += delta
	while elapsed >= SECONDS[shot]:
		if office_take:
			start()
			return
		var next := SCRIPT.SHOT_ORDER.find(shot) + 1
		if next == SCRIPT.SHOT_ORDER.size():
			stop()
			finished.emit()
			return
		var remainder: float = elapsed - SECONDS[shot]
		select_shot(SCRIPT.SHOT_ORDER[next])
		elapsed = remainder
	queue_redraw()

func _draw() -> void:
	var stage = $Screen/View/Stage
	stage.profile = profile
	stage.frame(shot,elapsed)
	var font := get_theme_default_font()
	var cues := SCRIPT.OFFICE_CUES if office_take else SCRIPT.cues(profile,shot)
	var caption := String(cues[0][1])
	for cue in cues:
		if elapsed < cue[0]:
			break
		caption = cue[1]
	if not caption.is_empty():
		var caption_height := font.get_multiline_string_size(caption,HORIZONTAL_ALIGNMENT_CENTER,size.x-60,17).y
		var top := size.y-caption_height-24.0
		draw_rect(Rect2(0,top,size.x,size.y-top),Color(0.035,0.055,0.075,0.84))
		draw_multiline_string(font,Vector2(30,top+10+font.get_ascent(17)),caption,HORIZONTAL_ALIGNMENT_CENTER,size.x-60,17, -1)
	var source: String = "2026   /   Friday afternoon" if office_take else SCRIPT.YEARS[shot] + "   /   " + SCRIPT.source(profile,shot,elapsed)
	var source_width := font.get_string_size(source,HORIZONTAL_ALIGNMENT_LEFT,-1,15).x+24
	draw_rect(Rect2(14,14,source_width,33),Color(0.06,0.09,0.11,0.88))
	draw_rect(Rect2(14,14,source_width,1),Color("#aa8259"))
	draw_string(font, Vector2(25, 36), source, HORIZONTAL_ALIGNMENT_LEFT, -1, 15, Color("#efd0a0"))
	if (office_take or shot == SCRIPT.SHOT_ORDER[0]) and elapsed < 3:
		draw_string_outline(font, Vector2(size.x - 128, 36), "Esc · Skip", HORIZONTAL_ALIGNMENT_LEFT, -1, 14, 4, Color.BLACK)
		draw_string(font, Vector2(size.x - 128, 36), "Esc · Skip", HORIZONTAL_ALIGNMENT_LEFT, -1, 14)
	var fade := maxf(1.0 - elapsed / 0.45, 1.0 - (SECONDS[shot] - elapsed) / 0.45)
	if fade > 0:
		draw_rect(Rect2(Vector2.ZERO, size), Color(0, 0, 0, fade))
