extends Control
## Real-time archive film. The 3D stage is drawn behind the captions.
signal finished

const YEARS := ["2026","2026","2027","2029","2030","2032","2041","2053","2053","TURNO 01"]
const SOURCES := ["Venerdì pomeriggio","Diario di campo","Spazio pubblicitario","Giardino dell’ospedale","Reparto ricerca","Registro della cupola","Seduta pubblica","Ufficio trasferimenti","Diario di campo","Terminale H-0317"]
const LINES := [
	"Alle quattro l’agente aveva già finito i test. Mio fratello chiuse il portatile e venne a prendermi in bici. Di solito il venerdì cenava in ufficio.",
	"Quella sera disegnai tre stelle. Chiesi all’agente di inseguire la terza col telescopio. Ogni volta aspettava il mio sì.",
	"Le aziende che vendevano gli agenti comprarono tutte le vetrine. Promettevano cure per ogni malattia, la fine del cancro, della fame e delle disuguaglianze. Un reddito universale, per tutti.",
	"Il primo accredito pagò il viaggio in ospedale. Dopo la cura mamma tornò a casa con me. Quando ci chiesero di affidare agli agenti anche le liste d’attesa, firmai.",
	"Gli agenti cominciarono a progettare i propri successori. Uno risolse in una notte il problema che bloccava il nostro laboratorio da nove anni. A noi servirono sei mesi per capire la prova.",
	"Ogni giovedì approvavo il piano del telescopio. Dopo duecento conferme spuntai «Approva anche in futuro». La settimana dopo il mio terzo punto sparì dal programma.",
	"Alla piena del fiume il consiglio affidò all’agente i treni di soccorso. Arrivarono tutti. Alla piena successiva il consiglio ricevette direttamente il verbale.",
	"Fu lo stesso ufficio a convocarci per il trasferimento. Le città sarebbero rimaste ai robot. Chi mi precedeva tenne aperto il cancelletto anche per me.",
	"La pistola ad antimateria mi ha trasformata in una rete neurale. Ho sentito il quaderno cadere quando ero già dentro il computer.",
	"Sul monitor c’è la foto del mio telescopio. Il supervisore vuole tre diapositive sulla sua scoperta. Mi concede sette minuti."
]
const SECONDS := [12,11,16,15,15,15,14,13,12,10]
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
	$Screen/View/Stage.frame(shot, elapsed)
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
