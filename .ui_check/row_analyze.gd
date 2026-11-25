extends SceneTree

func _init() -> void:
	var img := Image.load_from_file("res://.ui_check/row.png")
	var counts := {}
	for y in img.get_height():
		for x in img.get_width():
			var c := img.get_pixel(x, y)
			var mx: float = maxf(c.r, maxf(c.g, c.b))
			var mn: float = minf(c.r, minf(c.g, c.b))
			if mx - mn < 0.06:
				continue
			var key := "%02X%02X%02X" % [int(c.r * 255), int(c.g * 255), int(c.b * 255)]
			counts[key] = counts.get(key, 0) + 1
	var keys := counts.keys()
	keys.sort_custom(func(a, b): return counts[a] > counts[b])
	print("== saturated palette")
	for k in keys.slice(0, 12):
		print("  #%s  %d" % [k, counts[k]])
	# bbox of a few known fills
	for pair in [["taupe", Color8(0xC1, 0xAD, 0x9D)], ["ink", Color8(0x3E, 0x27, 0x1A)]]:
		var t: Color = pair[1]
		var minx := 9999; var maxx := -1; var miny := 9999; var maxy := -1; var n := 0
		for y in img.get_height():
			for x in img.get_width():
				var c := img.get_pixel(x, y)
				if absf(c.r - t.r) < 0.02 and absf(c.g - t.g) < 0.02 and absf(c.b - t.b) < 0.02:
					n += 1
					minx = mini(minx, x); maxx = maxi(maxx, x); miny = mini(miny, y); maxy = maxi(maxy, y)
		print("== %s bbox x=%d..%d y=%d..%d (n=%d)" % [pair[0], minx, maxx, miny, maxy, n])
	# crops for visual inspection (2x)
	_save_region(img, Rect2i(0, 0, 460, 174), 2, "res://.ui_check/row_left.png")
	_save_region(img, Rect2i(440, 0, 460, 174), 2, "res://.ui_check/row_mid.png")
	_save_region(img, Rect2i(760, 0, 557, 174), 2, "res://.ui_check/row_right.png")
	quit(0)


func _save_region(img: Image, rect: Rect2i, scale: int, path: String) -> void:
	var region := img.get_region(rect)
	region.resize(rect.size.x * scale, rect.size.y * scale, Image.INTERPOLATE_NEAREST)
	region.save_png(path)
