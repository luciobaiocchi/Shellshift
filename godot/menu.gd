extends Control

@onready var action: Button = $Content/Action
@onready var secondary: Button = $Content/Exit
@onready var film = $Film
var receipt := false
var previous_mode := Window.MODE_WINDOWED

func _ready() -> void:
	action.pressed.connect(advance)
	secondary.pressed.connect(secondary_action)
	film.finished.connect(show_receipt)
	action.grab_focus()
	var args := OS.get_cmdline_user_args()
	if args.has("--programmatori") or args.has("--prologo"):
		advance.call_deferred()

func advance() -> void:
	if receipt:
		receipt = false
		$Content/Title.text = "SHELLSHIFT"
		$Content/Message.text = "Matricola H-0317. Il turno inizia alla presa visione."
		action.text = "Inizia turno"
		return
	for control in [$Content/Skyline, $Content/Title, $Content/Message, $Content/Station, action]:
		control.hide()
	previous_mode = get_window().mode
	get_window().mode = Window.MODE_FULLSCREEN
	$Content.hide()
	film.start()

func secondary_action() -> void:
	if film.visible:
		film.stop()
		show_receipt()
	else:
		get_tree().quit()

func show_receipt() -> void:
	get_window().mode = previous_mode
	$Content.show()
	receipt = true
	for control in [$Content/Skyline, $Content/Title, $Content/Message, $Content/Station, action]:
		control.show()
	$Content/Title.text = "Ricevuta di presenza"
	$Content/Message.text = "H-0317 · Presenza registrata.\nIl tempo impiegato per leggere viene detratto dalla pausa."
	action.text = "Torna al menu"
	secondary.text = "Esci"
	action.grab_focus()


func _input(event: InputEvent) -> void:
	if film.visible and event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		secondary_action()
