extends SceneTree

func _init() -> void:
	var img := Image.load_from_file("res://.ui_check/design.png")
	var w := img.get_width()
	var h := img.get_height()
	var seen := PackedByteArray()
	seen.resize(w * h)
	var colors := {
		"dark_card": Color8(0x33, 0x22, 0x19),
		"slot_cream": Color8(0xFA, 0xF4, 0xE8),
		"outer_cream": Color8(0xF7, 0xF1, 0xE5),
		"pill_cream": Color8(0xEB, 0xE0, 0xCE),
	}
	for name in colors:
		var target: Color = colors[name]
		seen.fill(0)
		var boxes: Array = []
		for y in h:
			for x in w:
				var idx := y * w + x
				if seen[idx] == 1:
					continue
				var c := img.get_pixel(x, y)
				if not _close(c, target):
					seen[idx] = 1
					continue
				# flood fill
				var stack: Array[Vector2i] = [Vector2i(x, y)]
				seen[idx] = 1
				var minx := x; var maxx := x; var miny := y; var maxy := y; var area := 0
				while not stack.is_empty():
					var p: Vector2i = stack.pop_back()
					area += 1
					minx = mini(minx, p.x); maxx = maxi(maxx, p.x)
					miny = mini(miny, p.y); maxy = maxi(maxy, p.y)
					for d: Vector2i in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
						var q: Vector2i = p + d
						if q.x < 0 or q.y < 0 or q.x >= w or q.y >= h:
							continue
						var qi: int = q.y * w + q.x
						if seen[qi] == 1:
							continue
						seen[qi] = 1
						if _close(img.get_pixel(q.x, q.y), target):
							stack.push_back(q)
				if area > 500:
					boxes.append([area, minx, miny, maxx, maxy])
		boxes.sort_custom(func(a, b): return a[1] < b[1] or (a[1] == b[1] and a[2] < b[2]))
		print("== ", name, " components: ", boxes.size())
		for b in boxes.slice(0, 24):
			print("  area=%6d  x=%3d..%3d  y=%3d..%3d  w=%3d h=%3d" % [b[0], b[1], b[3], b[2], b[4], b[3]-b[1]+1, b[4]-b[2]+1])
	quit(0)


func _close(c: Color, t: Color) -> bool:
	return absf(c.r - t.r) < 0.02 and absf(c.g - t.g) < 0.02 and absf(c.b - t.b) < 0.02
