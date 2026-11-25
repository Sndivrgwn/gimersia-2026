extends SceneTree

func _init() -> void:
	var img := Image.load_from_file("res://.ui_check/row.webp")
	if img == null:
		print("LOAD_FAIL"); quit(1); return
	print("SIZE ", img.get_size())
	img.save_png("res://.ui_check/row.png")
	var counts := {}
	for y in img.get_height():
		for x in img.get_width():
			var c := img.get_pixel(x, y)
			var key := "%02X%02X%02X" % [int(c.r * 255), int(c.g * 255), int(c.b * 255)]
			counts[key] = counts.get(key, 0) + 1
	var keys := counts.keys()
	keys.sort_custom(func(a, b): return counts[a] > counts[b])
	for k in keys.slice(0, 14):
		print("  #%s  %d" % [k, counts[k]])
	quit(0)
