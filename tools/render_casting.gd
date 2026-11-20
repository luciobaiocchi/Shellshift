extends SceneTree

const SHOT := "res://casting/hospital.tscn"
const SIZE := Vector2i(1280, 720)
const FPS := 24
const FRAME_COUNT := 15 * FPS

func _initialize() -> void:
	call_deferred("record")

func record() -> void:
	var args := OS.get_cmdline_user_args()
	if args.size() != 1 or not DirAccess.dir_exists_absolute(args[0]):
		push_error("Pass an existing frame directory after --")
		quit(1)
		return
	var packed := load(SHOT) as PackedScene
	if packed == null:
		quit(1)
		return

	var screen := SubViewport.new()
	screen.size = SIZE
	screen.own_world_3d = true
	screen.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(screen)
	var scene := packed.instantiate()
	screen.add_child(scene)
	if not scene.has_method("frame"):
		push_error("The screen test needs a frame(seconds) method")
		quit(1)
		return
	scene.set_process(false)
	scene.set_physics_process(false)
	for frame_number in FRAME_COUNT:
		scene.frame(float(frame_number) / FPS)
		await process_frame
		RenderingServer.force_draw(false, 1.0 / FPS)
		var picture := screen.get_texture().get_image()
		if picture == null or picture.is_empty():
			push_error("No GPU image returned for frame %d" % frame_number)
			quit(1)
			return
		var filename := args[0].path_join("%04d.png" % frame_number)
		if picture.save_png(filename) != OK:
			push_error("Could not write " + filename)
			quit(1)
			return
	quit()
