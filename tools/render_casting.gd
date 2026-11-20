extends SceneTree
## Sample the film's actual Godot stage and active camera at each edit.
const SHOT := "res://casting/hospital.tscn"
const SIZE := Vector2i(1280,720)
const FPS := 24

func _initialize() -> void:
	call_deferred("record")

func record() -> void:
	var args := OS.get_cmdline_user_args()
	if args.is_empty() or not DirAccess.dir_exists_absolute(args[0]):
		push_error("Pass an existing frame directory after --")
		quit(1)
		return
	var ensemble := args.size() == 2
	var cuts: Array = JSON.parse_string(args[1]) if ensemble else [[0,3,0.0,15.0]]
	var screen := SubViewport.new()
	screen.size = SIZE
	screen.own_world_3d = true
	screen.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(screen)
	var scene: Node3D
	if ensemble:
		scene = load("res://stage.gd").new()
	else:
		scene = load(SHOT).instantiate()
	screen.add_child(scene)
	scene.process_mode = Node.PROCESS_MODE_DISABLED
	var frame_number := 0
	for cut: Array in cuts:
		if ensemble:
			scene.profile = int(cut[0])
		for tick in roundi(cut[3]*FPS):
			var seconds: float = cut[2]+float(tick)/FPS
			if ensemble:
				scene.frame(int(cut[1]),seconds)
			else:
				scene.frame(seconds)
			await process_frame
			RenderingServer.force_draw(false,1.0/FPS)
			var picture := screen.get_texture().get_image()
			if picture == null or picture.is_empty():
				push_error("No GPU image returned for frame %d" % frame_number)
				quit(1)
				return
			var filename := args[0].path_join("%04d.jpg" % frame_number)
			if picture.save_jpg(filename,.99) != OK:
				push_error("Could not write " + filename)
				quit(1)
				return
			frame_number += 1
	quit()
