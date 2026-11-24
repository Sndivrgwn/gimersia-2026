extends SceneTree

## BLOCK F (Mission 13): merekam perilaku dunia FORMULA yang berlaku SEKARANG
## menjadi literal di tests/unit/test_world_golden.gd.
##
## Jalankan sekali SEBELUM refactor WorldSource/WorldRules:
##   GODOT --headless --path . -s tools/gen_world_golden.gd
##
## Literal yang ditulis: 3000 zona sampel (seed tetap), 267 titik batas zona,
## tabel 60 pusat BaseSiteRules (valid + reason), konstanta POI, dan plan
## IslandBuilder layout default (jumlah per definition + marker + 20 posisi).

const OUT_PATH := "res://tests/unit/test_world_golden.gd"
const ZONE_SEED := 131013
const ZONE_SAMPLE_COUNT := 3000


func _init() -> void:
	var zone_digits := ""
	var rng := RandomNumberGenerator.new()
	rng.seed = ZONE_SEED
	for index in ZONE_SAMPLE_COUNT:
		var point := Vector2(rng.randf_range(-2600.0, 2600.0), rng.randf_range(-2600.0, 2600.0))
		zone_digits += String.chr(48 + int(IslandZones.zone_at(point)))

	var boundary_points := _boundary_points()
	var boundary_zones: Array[int] = []
	for point in boundary_points:
		boundary_zones.append(int(IslandZones.zone_at(point)))

	var centers := _site_centers()
	var site_valid: Array[bool] = []
	var site_reasons: Array[String] = []
	for center in centers:
		var result := BaseSiteRules.evaluate(center, null)
		site_valid.append(bool(result["valid"]))
		site_reasons.append(String(result["reason"]))

	var builder := IslandBuilder.new()
	builder.auto_build = false
	var entries := builder.plan()
	var counts := {}
	var positions: Array[Vector2] = []
	var markers := 0
	for entry in entries:
		positions.append(entry["position"])
		if entry["kind"] == IslandBuilder.KIND_MARKER:
			markers += 1
			continue
		var key := String(entry["definition"].id)
		counts[key] = int(counts.get(key, 0)) + 1
	builder.free()

	var count_keys: Array = counts.keys()
	count_keys.sort()
	var count_text := ""
	for key in count_keys:
		if not count_text.is_empty():
			count_text += ", "
		count_text += "\"%s\": %d" % [String(key), int(counts[key])]

	var text := PackedStringArray()
	text.append("extends GutTest")
	text.append("")
	text.append("## GOLDEN (BLOCK F, Mission 13): perilaku dunia FORMULA SEBELUM WorldSource/")
	text.append("## WorldRules. Semua literal di file ini direkam tools/gen_world_golden.gd dari")
	text.append("## kode lama. JANGAN diubah: tes merah berarti perilaku dunia berubah.")
	text.append("")
	text.append("const ZONE_SEED := %d" % ZONE_SEED)
	text.append("const ZONE_SAMPLE_COUNT := %d" % ZONE_SAMPLE_COUNT)
	text.append("## Satu digit per titik (0..6 = enum IslandZones.Zone).")
	text.append("const ZONE_DIGITS := \"%s\"" % zone_digits)
	text.append("")
	text.append("const POI_PLAYER_START := %s" % var_to_str(IslandBuilder.KEEP_OUT_POINTS[0]))
	text.append("const POI_PLANE_WRECKAGE := %s" % var_to_str(IslandBuilder.KEEP_OUT_POINTS[1]))
	text.append("const POI_EMERGENCY_SUITCASE := %s" % var_to_str(IslandBuilder.KEEP_OUT_POINTS[2]))
	text.append("const POI_SIGNAL_BEACON := %s" % var_to_str(IslandZones.BEACON_POSITION))
	text.append("")
	text.append("## Jumlah entri plan layout default per definition id.")
	text.append("const PLAN_COUNTS := {%s}" % count_text)
	text.append("const PLAN_MARKER_COUNT := %d" % markers)
	text.append("")
	text.append("const BOUNDARY_POINTS: Array[Vector2] = [")
	for point in boundary_points:
		text.append("\t%s," % var_to_str(point))
	text.append("]")
	text.append("const BOUNDARY_ZONES: Array[int] = [")
	text.append("\t%s," % _ints_text(boundary_zones))
	text.append("]")
	text.append("")
	text.append("## 60 pusat: dalam camp, dekat pantai, dekat sungai, di sungai, luar pulau.")
	text.append("const SITE_CENTERS: Array[Vector2] = [")
	for center in centers:
		text.append("\t%s," % var_to_str(center))
	text.append("]")
	text.append("const SITE_VALID: Array[bool] = [")
	text.append("\t%s," % _bools_text(site_valid))
	text.append("]")
	text.append("const SITE_REASONS: Array[String] = [")
	for reason in site_reasons:
		text.append("\t%s," % var_to_str(reason))
	text.append("]")
	text.append("")
	text.append("## 20 posisi pertama plan layout default (urutan sama dengan plan()).")
	text.append("const PLAN_FIRST_POSITIONS: Array[Vector2] = [")
	for index in 20:
		text.append("\t%s," % var_to_str(positions[index]))
	text.append("]")
	text.append("")
	text.append("")
	text.append("func test_seeded_zones_match_golden() -> void:")
	text.append("\tassert_eq(ZONE_DIGITS.length(), ZONE_SAMPLE_COUNT, \"literal golden harus lengkap\")")
	text.append("\tvar local_rng := RandomNumberGenerator.new()")
	text.append("\tlocal_rng.seed = ZONE_SEED")
	text.append("\tvar mismatches := PackedInt32Array()")
	text.append("\tfor index in ZONE_SAMPLE_COUNT:")
	text.append("\t\tvar point := Vector2(")
	text.append("\t\t\tlocal_rng.randf_range(-2600.0, 2600.0),")
	text.append("\t\t\tlocal_rng.randf_range(-2600.0, 2600.0)")
	text.append("\t\t)")
	text.append("\t\tvar expected := ZONE_DIGITS.unicode_at(index) - 48")
	text.append("\t\tvar actual := int(IslandZones.zone_at(point))")
	text.append("\t\tif actual != expected:")
	text.append("\t\t\tmismatches.append(index)")
	text.append("\tassert_true(mismatches.is_empty(), \"zone_at berubah di %d titik: %s\" % [")
	text.append("\t\tmismatches.size(), str(mismatches.slice(0, mini(5, mismatches.size())))")
	text.append("\t])")
	text.append("")
	text.append("")
	text.append("func test_boundary_points_match_golden() -> void:")
	text.append("\tassert_eq(BOUNDARY_POINTS.size(), BOUNDARY_ZONES.size())")
	text.append("\tfor index in BOUNDARY_POINTS.size():")
	text.append("\t\tassert_eq(")
	text.append("\t\t\tint(IslandZones.zone_at(BOUNDARY_POINTS[index])),")
	text.append("\t\t\tBOUNDARY_ZONES[index],")
	text.append("\t\t\t\"batas #%d %s\" % [index, str(BOUNDARY_POINTS[index])]")
	text.append("\t\t)")
	text.append("")
	text.append("")
	text.append("func test_base_site_rules_table_matches_golden() -> void:")
	text.append("\tassert_eq(SITE_CENTERS.size(), 60, \"tabel 60 sampel\")")
	text.append("\tfor index in SITE_CENTERS.size():")
	text.append("\t\tvar center := SITE_CENTERS[index]")
	text.append("\t\tvar result := BaseSiteRules.evaluate(center, null)")
	text.append("\t\tassert_eq(bool(result[\"valid\"]), SITE_VALID[index], \"valid #%d %s\" % [index, str(center)])")
	text.append("\t\tassert_eq(String(result[\"reason\"]), SITE_REASONS[index], \"reason #%d %s\" % [index, str(center)])")
	text.append("")
	text.append("")
	text.append("func test_poi_constants_match_golden() -> void:")
	text.append("\tassert_eq(IslandBuilder.KEEP_OUT_POINTS[0], POI_PLAYER_START)")
	text.append("\tassert_eq(IslandBuilder.KEEP_OUT_POINTS[1], POI_PLANE_WRECKAGE)")
	text.append("\tassert_eq(IslandBuilder.KEEP_OUT_POINTS[2], POI_EMERGENCY_SUITCASE)")
	text.append("\tassert_eq(IslandZones.BEACON_POSITION, POI_SIGNAL_BEACON)")
	text.append("")
	text.append("")
	text.append("func test_island_plan_matches_golden() -> void:")
	text.append("\tvar builder := IslandBuilder.new()")
	text.append("\tbuilder.layout = IslandBuilder.LAYOUT_DEFAULT")
	text.append("\tbuilder.auto_build = false")
	text.append("\tadd_child_autofree(builder)")
	text.append("\tvar entries := builder.plan()")
	text.append("\tvar counts := {}")
	text.append("\tvar markers := 0")
	text.append("\tvar positions: Array[Vector2] = []")
	text.append("\tfor entry in entries:")
	text.append("\t\tpositions.append(entry[\"position\"])")
	text.append("\t\tif entry[\"kind\"] == IslandBuilder.KIND_MARKER:")
	text.append("\t\t\tmarkers += 1")
	text.append("\t\t\tcontinue")
	text.append("\t\tvar key := String(entry[\"definition\"].id)")
	text.append("\t\tcounts[key] = int(counts.get(key, 0)) + 1")
	text.append("\tassert_eq(markers, PLAN_MARKER_COUNT)")
	text.append("\tassert_eq(counts.size(), PLAN_COUNTS.size(), \"tidak ada definition tak terduga\")")
	text.append("\tfor key in PLAN_COUNTS:")
	text.append("\t\tassert_eq(int(counts.get(key, 0)), int(PLAN_COUNTS[key]), \"jumlah %s\" % key)")
	text.append("\tfor index in PLAN_FIRST_POSITIONS.size():")
	text.append("\t\tassert_true(")
	text.append("\t\t\tpositions[index].is_equal_approx(PLAN_FIRST_POSITIONS[index]),")
	text.append("\t\t\t\"posisi #%d: %s != %s\" % [index, str(positions[index]), str(PLAN_FIRST_POSITIONS[index])]")
	text.append("\t\t)")

	var file := FileAccess.open(OUT_PATH, FileAccess.WRITE)
	if file == null:
		push_error("gen_world_golden: gagal menulis %s" % OUT_PATH)
		quit(1)
		return
	file.store_string("\n".join(text) + "\n")
	file.close()
	print("gen_world_golden: %s (%d titik seed, %d titik batas, %d sampel situs, %d entri plan)" % [
		OUT_PATH, ZONE_SAMPLE_COUNT, boundary_points.size(), centers.size(), entries.size()
	])
	quit()


func _ints_text(values: Array[int]) -> String:
	var parts := PackedStringArray()
	for value in values:
		parts.append(str(value))
	return ", ".join(parts)


func _bools_text(values: Array[bool]) -> String:
	var parts := PackedStringArray()
	for value in values:
		parts.append("true" if value else "false")
	return ", ".join(parts)


## Titik batas memakai koordinat bilangan bulat supaya literal di tes persis
## sama (tanpa galat pembulatan trigonometri).
func _boundary_points() -> Array[Vector2]:
	var points: Array[Vector2] = []
	for x in [-2400.0, -2399.0, -2401.0, 2400.0, 2399.0, 2401.0]:
		for y in [-2000.0, -500.0, 0.0, 900.0, 1400.0, 1600.0, 2300.0]:
			points.append(Vector2(x, y))
	for y in [-2400.0, -2399.0, -2401.0, 2400.0, 2399.0, 2401.0]:
		for x in [-2000.0, -950.0, -500.0, 0.0, 900.0, 1400.0, 1600.0, 2300.0]:
			points.append(Vector2(x, y))
	# Lingkaran camp r=800: titik kisi 3-4-5 (panjang tepat 800) + geser 1 px.
	for base in [
		Vector2(800.0, 0.0), Vector2(0.0, 800.0), Vector2(-800.0, 0.0), Vector2(0.0, -800.0),
		Vector2(480.0, 640.0), Vector2(-480.0, 640.0), Vector2(480.0, -640.0), Vector2(-480.0, -640.0),
		Vector2(640.0, 480.0), Vector2(-640.0, 480.0), Vector2(640.0, -480.0), Vector2(-640.0, -480.0),
	]:
		for offset in [Vector2.ZERO, Vector2(1.0, 0.0), Vector2(-1.0, 0.0), Vector2(0.0, 1.0), Vector2(0.0, -1.0)]:
			points.append(base + offset)
	for y in [1399.0, 1400.0, 1401.0]:
		for x in [-2200.0, -1050.0, -950.0, -850.0, -500.0, 0.0, 500.0, 1400.0, 1401.0, 1600.0, 2200.0]:
			points.append(Vector2(x, y))
	for x in [1399.0, 1400.0, 1401.0]:
		for y in [-2000.0, -1400.0, -1399.0, -1000.0, 0.0, 900.0, 1400.0, 1401.0, 1600.0]:
			points.append(Vector2(x, y))
	for x in [-1399.0, -1400.0, -1401.0]:
		for y in [-2000.0, -1400.0, -1399.0, -1000.0, 0.0, 900.0, 1400.0, 1401.0, 1600.0]:
			points.append(Vector2(x, y))
	for x in [-1051.0, -1050.0, -1049.0, -851.0, -850.0, -849.0]:
		for y in [-2000.0, -1400.0, -1399.0, 0.0, 900.0, 1400.0, 1401.0]:
			points.append(Vector2(x, y))
	return points


func _site_centers() -> Array[Vector2]:
	return [
		# Dalam camp (10)
		Vector2(0.0, 0.0), Vector2(200.0, 150.0), Vector2(-300.0, 100.0), Vector2(450.0, -250.0),
		Vector2(100.0, 700.0), Vector2(-700.0, 0.0), Vector2(250.0, 650.0), Vector2(650.0, 200.0),
		Vector2(-500.0, -400.0), Vector2(0.0, -780.0),
		# Dekat pantai / luar tepi (10)
		Vector2(2200.0, 0.0), Vector2(0.0, 2200.0), Vector2(-2200.0, 0.0), Vector2(2200.0, 2200.0),
		Vector2(-2200.0, -2200.0), Vector2(2150.0, 500.0), Vector2(500.0, -2150.0), Vector2(2300.0, 2300.0),
		Vector2(-2399.0, 0.0), Vector2(0.0, 2399.0),
		# Di luar pulau (10)
		Vector2(2500.0, 0.0), Vector2(-2501.0, 0.0), Vector2(0.0, 2600.0), Vector2(2600.0, 2600.0),
		Vector2(-2600.0, -100.0), Vector2(2401.0, 0.0), Vector2(0.0, -2401.0), Vector2(4800.0, 0.0),
		Vector2(1400.0, 2500.0), Vector2(-3000.0, 3000.0),
		# Dekat sungai (10)
		Vector2(-800.0, 0.0), Vector2(-780.0, 300.0), Vector2(-1100.0, 0.0), Vector2(-760.0, -500.0),
		Vector2(-1120.0, 900.0), Vector2(-800.0, 1300.0), Vector2(-700.0, 0.0), Vector2(-1150.0, -700.0),
		Vector2(-799.0, 1290.0), Vector2(-800.0, -1290.0),
		# Di dalam sungai (10)
		Vector2(-950.0, 0.0), Vector2(-1050.0, 900.0), Vector2(-850.0, -900.0), Vector2(-950.0, 1300.0),
		Vector2(-1000.0, 0.0), Vector2(-900.0, -400.0), Vector2(-1050.0, -1400.0), Vector2(-850.0, 1400.0),
		Vector2(-950.0, 1399.0), Vector2(-1049.0, -1000.0),
		# Zona lain (10)
		Vector2(1600.0, 0.0), Vector2(0.0, 1600.0), Vector2(-1600.0, 0.0), Vector2(1000.0, -1000.0),
		Vector2(-1200.0, 1600.0), Vector2(1700.0, -1600.0), Vector2(900.0, 1700.0), Vector2(-1700.0, 1700.0),
		Vector2(-1000.0, -1000.0), Vector2(1000.0, 1000.0),
	]
