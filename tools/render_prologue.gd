extends SceneTree
## Record the selected account's full-screen film, including its in-game typography.
const SCREEN := Vector2i(1280,720)
const UI := Vector2i(854,480)
const FPS := 24

func _initialize() -> void:
	call_deferred("render")

func render() -> void:
	var args := OS.get_cmdline_user_args()
	if args.is_empty() or not DirAccess.dir_exists_absolute(args[0]):
		push_error("Pass an existing frame directory after --")
		quit(1)
		return
	var capture := SubViewport.new()
	capture.size = SCREEN
	capture.size_2d_override = UI
	capture.size_2d_override_stretch = true
	capture.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(capture)
	var menu = load("res://menu.tscn").instantiate()
	capture.add_child(menu)
	menu.get_node("Content").hide()
	var film = menu.get_node("Film")
	film.profile = menu.selected_profile
	film.start()
	film.set_process(false)
	var monitor: SubViewportContainer = film.get_node("Screen")
	# Keep text at the full-screen game's 480 logical lines, while sampling the 3D at 720p.
	monitor.set_anchors_and_offsets_preset(Control.PRESET_TOP_LEFT)
	monitor.size = Vector2(SCREEN)
	monitor.scale = Vector2(UI)/Vector2(SCREEN)
	monitor.get_node("View").render_target_update_mode = SubViewport.UPDATE_ALWAYS
	await process_frame
	if film.size != Vector2(UI) or monitor.get_node("View").size != SCREEN:
		push_error("Film layout %s and stage %s do not match the recording." % [film.size,monitor.get_node("View").size])
		quit(1)
		return

	var frame_number := 0
	for shot: int in film.SCRIPT.SHOT_ORDER:
		film.select_shot(shot)
		for tick in roundi(FPS*film.SECONDS[shot]):
			film.elapsed = float(tick)/FPS
			film.queue_redraw()
			await RenderingServer.frame_post_draw
			var picture := capture.get_texture().get_image()
			if picture == null or picture.get_size() != SCREEN:
				push_error("Empty or mis-sized frame %d" % frame_number)
				quit(1)
				return
			if picture.save_jpg(args[0].path_join("%05d.jpg" % frame_number),.98) != OK:
				push_error("Could not write frame %d" % frame_number)
				quit(1)
				return
			frame_number += 1

	# Let the last frame elapse through the game's own finish signal. The MP4 ends
	# on the prologue fade; the next screen belongs to the interactive desktop.
	film._process(1.0/FPS+.000001)
	if film.visible or not is_instance_valid(menu.shift) or menu.shift.get_parent() != menu:
		push_error("The reader did not reach the first shift from the final film frame")
		quit(1)
		return
	capture.queue_free()
	await process_frame
	await process_frame
	print("Recorded %d frames with the shift handoff." % frame_number)
	quit()
