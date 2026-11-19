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
var voices := PackedStringArray()

func start() -> void:
	voices = DisplayServer.tts_get_voices_for_language("it")
	show()
	select_shot(0)

func stop() -> void:
	if not voices.is_empty():
		DisplayServer.tts_stop()
	hide()

func select_shot(index: int) -> void:
	shot = index
	elapsed = 0.0
	if not voices.is_empty():
		var voice_index := 0 if shot in [0, 1, 4, 5] else mini(1, voices.size() - 1)
		DisplayServer.tts_speak(LINES[shot], voices[voice_index], 85, 1.0, 1.0, shot, true)
	queue_redraw()

func _process(delta: float) -> void:
	if not is_visible_in_tree():
		return
	elapsed += delta
	if elapsed >= SECONDS[shot] and (voices.is_empty() or not DisplayServer.tts_is_speaking()):
		if shot + 1 == LINES.size():
			stop()
			finished.emit()
			return
		select_shot(shot + 1)
	queue_redraw()

func _draw() -> void:
	var panel := BOARD.get_size() / Vector2(2, 3)
	var origin := Vector2(shot % 2, floori(shot / 2.0)) * panel
	var image_area := Rect2(0, 0, size.x, size.y - 133)
	var crop := panel - Vector2(8, 8)
	var ratio := image_area.size.aspect()
	crop.x = minf(crop.x, crop.y * ratio)
	crop.y = crop.x / ratio
	var progress := clampf(elapsed / SECONDS[shot], 0.0, 1.0)
	crop *= 1.0 - 0.07 * progress
	var source := Rect2(origin + (panel - crop) * 0.5, crop)
	draw_texture_rect_region(BOARD, image_area, source)
	draw_rect(Rect2(0, image_area.end.y, size.x, 133), Color("#101319"))
	var font := get_theme_default_font()
	draw_string(font, Vector2(22, image_area.end.y + 22), YEARS[shot] + "   /   " + SOURCES[shot], HORIZONTAL_ALIGNMENT_LEFT, -1, 15, Color("#e8bb81"))
	draw_multiline_string(font, Vector2(22, image_area.end.y + 50), LINES[shot], HORIZONTAL_ALIGNMENT_LEFT, size.x - 44, 17)
