extends SceneTree

func _init() -> void:
	var img := Image.load_from_file("res://.ui_check/design.svg")
	if img == null:
		print("LOAD_FAIL")
		quit(1)
		return
	print("SIZE ", img.get_size())
	img.save_png("res://.ui_check/design.png")
	quit(0)
