extends SceneTree
func _initialize() -> void:
	auto_accept_quit = false
	call_deferred("render")
func render() -> void:
	var menu = load("res://menu.tscn").instantiate()
	root.add_child(menu)
	menu.get_node("Content").hide()
	var film = menu.get_node("Film")
	film.show()
	film.set_process(false)
	for i in range(film.SECONDS.size()):
		film.select_shot(i)
		for frame in range(int(film.SECONDS[i] * 24)):
			film.elapsed = frame / 24.0
			film.queue_redraw()
			await RenderingServer.frame_post_draw
	quit()
