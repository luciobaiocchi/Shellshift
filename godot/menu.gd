extends Control

const TITLES := ["Il quaderno", "Trasferimento", "Ultimo accesso"]
const CAPTIONS := [
	"«Tornare giovedì. Forse si muove.»\nTiene il dito sulla pagina mentre la fila avanza.",
	"Il robot legge il polso. «H-0317. Effetti personali al banco.»\nLa pistola ad antimateria si accende.",
	"Il quaderno cade chiuso. Sei già dentro il computer\nquando senti la copertina battere sul pavimento."
]

@onready var action: Button = $Content/Action
@onready var secondary: Button = $Content/Exit
@onready var film = $Content/Film
var page := -1

func _ready() -> void:
	action.pressed.connect(advance)
	secondary.pressed.connect(secondary_action)
	action.grab_focus()

func advance() -> void:
	page += 1
	if page > TITLES.size():
		page = -1
	display_page()

func secondary_action() -> void:
	if page >= 0 and page < TITLES.size():
		page = TITLES.size()
		display_page()
	else:
		get_tree().quit()

func display_page() -> void:
	var in_film := page >= 0 and page < TITLES.size()
	$Content/Skyline.visible = not in_film
	film.visible = in_film
	secondary.text = "Salta il filmato" if in_film else "Esci"
	if in_film:
		film.show_shot(page)
		$Content/Station.text = "ARCHIVIO TRASFERIMENTI                     %02d / 03" % (page + 1)
		$Content/Title.text = TITLES[page]
		$Content/Message.text = CAPTIONS[page]
		action.text = "Ho preso visione" if page == 2 else "Avanti"
	else:
		$Content/Station.text = "UFFICIO ASSEGNAZIONI                         / NODO 01"
		if page == -1:
			$Content/Title.text = "SHELLSHIFT"
			$Content/Message.text = "Matricola H-0317. Il turno inizia alla presa visione."
			action.text = "Inizia turno"
		else:
			$Content/Title.text = "Ricevuta di presenza"
			$Content/Message.text = "H-0317 · Presenza registrata.\nIl tempo impiegato per leggere viene detratto dalla pausa."
			action.text = "Torna al menu"
	action.grab_focus()
