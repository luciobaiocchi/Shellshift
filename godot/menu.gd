extends Control

@onready var action: Button = $Content/Action
@onready var title: Label = $Content/Title
@onready var message: Label = $Content/Message
var on_shift := false

func _ready() -> void:
	action.pressed.connect(toggle_shift)
	$Content/Exit.pressed.connect(get_tree().quit)
	action.grab_focus()

func toggle_shift() -> void:
	on_shift = not on_shift
	if on_shift:
		title.text = "Ricevuta di presenza"
		message.text = "H-0317 · Presenza registrata.\nIl tempo impiegato per leggere viene detratto dalla pausa."
		action.text = "Torna al menu"
	else:
		title.text = "SHELLSHIFT"
		message.text = "Matricola H-0317. Il turno inizia alla presa visione."
		action.text = "Inizia turno"
