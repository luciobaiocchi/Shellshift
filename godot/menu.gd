extends Control

@onready var action: Button = $Content/Action
@onready var secondary: Button = $Content/Exit
@onready var film = $Content/Film
var receipt := false

func _ready() -> void:
	action.pressed.connect(advance)
	secondary.pressed.connect(secondary_action)
	film.finished.connect(show_receipt)
	action.grab_focus()

func advance() -> void:
	if receipt:
		receipt = false
		$Content/Title.text = "SHELLSHIFT"
		$Content/Message.text = "Matricola H-0317. Il turno inizia alla presa visione."
		action.text = "Inizia turno"
		return
	for control in [$Content/Skyline, $Content/Title, $Content/Message, $Content/Station, action]:
		control.hide()
	film.start()
	secondary.text = "Salta il filmato"
	secondary.grab_focus()

func secondary_action() -> void:
	if film.visible:
		film.stop()
		show_receipt()
	else:
		get_tree().quit()

func show_receipt() -> void:
	receipt = true
	for control in [$Content/Skyline, $Content/Title, $Content/Message, $Content/Station, action]:
		control.show()
	$Content/Title.text = "Ricevuta di presenza"
	$Content/Message.text = "H-0317 · Presenza registrata.\nIl tempo impiegato per leggere viene detratto dalla pausa."
	action.text = "Torna al menu"
	secondary.text = "Esci"
	action.grab_focus()
