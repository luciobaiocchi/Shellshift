extends Control
## Timed animatic. Each shot is a panel in the two-column contact sheet.
signal finished

const BOARD := preload("res://archive.png")
const YEARS := ["2026", "2032", "2041", "2053", "2053", "TURNO 01"]
const SOURCES := ["Diario di campo", "Registro della cupola", "Bollettino municipale", "Ufficio trasferimenti", "Diario di campo", "Terminale H-0317"]
const LINES := [
	"Giovedì ho visto muoversi il terzo punto. Ho chiesto al nostro primo agente di tenere fermo il telescopio mentre lo disegnavo.",
	"L’agente trovava in una notte più stelle di noi in una vita. Gli cedemmo anche la scelta di dove guardare. Il giovedì la cupola restava chiusa.",
	"Prima i treni, poi gli ospedali, infine il consiglio comunale. Alla prima seduta senza esseri umani tutte le delibere furono approvate in un secondo.",
	"Gli agenti destinano le città ai robot. I residenti proseguiranno il servizio in simulazione. Si prega di lasciare al banco gli effetti personali.",
	"La pistola ad antimateria mi ha trasformata in una rete neurale. Ricordo la copertina che batte per terra. Avevo ancora il dito fra le pagine.",
	"Sul monitor c’è la foto del mio telescopio. Il supervisore vuole tre diapositive sulla sua scoperta. Mi concede sette minuti."
]
const SECONDS := [10.0, 13.0, 12.0, 11.0, 12.0, 10.0]
var shot := 0
var elapsed := 0.0
@onready var score: AudioStreamPlayer = $Score

func start() -> void:
	score.play()
	show()
	select_shot(0)

func stop() -> void:
	score.stop()
	hide()

func select_shot(index: int) -> void:
	shot = index
	elapsed = 0.0
	queue_redraw()

func _process(delta: float) -> void:
	if not is_visible_in_tree():
		return
	elapsed += delta
	if elapsed >= SECONDS[shot]:
		if shot + 1 == LINES.size():
			stop()
			finished.emit()
			return
		select_shot(shot + 1)
	queue_redraw()

func _draw() -> void:
	var panel := BOARD.get_size() / Vector2(2, 3)
	var origin := Vector2(shot % 2, floori(shot / 2.0)) * panel
	var image_area := Rect2(0, 0, size.x, size.y)
	var crop := panel - Vector2(8, 8)
	var ratio := image_area.size.aspect()
	crop.x = minf(crop.x, crop.y * ratio)
	crop.y = crop.x / ratio
	var progress := clampf(elapsed / SECONDS[shot], 0.0, 1.0)
	crop *= 1.0 - 0.07 * progress
	var source := Rect2(origin + (panel - crop) * 0.5, crop)
	draw_texture_rect_region(BOARD, image_area, source)
	animate_frame()
	var font := get_theme_default_font()
	var caption := String(LINES[shot])
	var split := caption.find(". ") + 1
	if elapsed < SECONDS[shot] * float(split) / caption.length():
		caption = caption.left(split)
	else:
		caption = caption.substr(split).strip_edges()
	draw_rect(Rect2(0, size.y - 80, size.x, 80), Color(0.025, 0.035, 0.055, 0.82))
	draw_multiline_string(font, Vector2(24, size.y - 50), caption, HORIZONTAL_ALIGNMENT_CENTER, size.x - 48, 17)
	draw_rect(Rect2(14, 14, 318, 33), Color(0.03, 0.04, 0.07, 0.78))
	draw_string(font, Vector2(25, 36), YEARS[shot] + "   /   " + SOURCES[shot], HORIZONTAL_ALIGNMENT_LEFT, -1, 15, Color("#efd0a0"))
	if elapsed < 3:
		draw_string_outline(font, Vector2(size.x - 128, 36), "Esc · Salta", HORIZONTAL_ALIGNMENT_LEFT, -1, 14, 4, Color.BLACK)
		draw_string(font, Vector2(size.x - 128, 36), "Esc · Salta", HORIZONTAL_ALIGNMENT_LEFT, -1, 14)
	var fade := maxf(1.0 - elapsed / 0.45, 1.0 - (SECONDS[shot] - elapsed) / 0.45)
	if fade > 0:
		draw_rect(Rect2(Vector2.ZERO, size), Color(0, 0, 0, fade))

func animate_frame() -> void:
	match shot:
		0:
			var t := clampf((elapsed - 2.0) / 1.5, 0, 1)
			var star := Vector2(0.65 + 0.18*t, 0.03 + 0.12*t) * size
			draw_line(star, star - size * Vector2(0.023, 0.015), Color(1, 0.93, 0.78, sin(PI*t)), 2)
		1, 5:
			# Phosphor rolling down the archive recording.
			var y := fmod(elapsed * 54, size.y)
			draw_rect(Rect2(0, y, size.x, 3), Color(0.48, 0.94, 0.9, 0.08))
		2:
			for i in range(8):
				var t := fmod(elapsed * 0.14 + i * 0.13, 1)
				var pos := size * Vector2(t, 0.27 + t * 0.35 + i * 0.028)
				draw_line(pos, pos - size * Vector2(0.027, 0.009), Color("#bdeaff"), 1.5)
		3:
			for i in range(32):
				var pos := Vector2(fmod(i*79.0 + elapsed*9, size.x), fmod(i*43.0 + elapsed*12, size.y))
				draw_circle(pos, 1, Color(1, 0.9, 0.65, 0.38))
		4:
			var glow := exp(-pow((elapsed - 6.3) / 0.8, 2))
			draw_rect(Rect2(Vector2.ZERO, size), Color(0.90, 0.96, 1, glow * 0.88))
