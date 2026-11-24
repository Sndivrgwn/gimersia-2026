extends GutTest

## BLOCK H (Mission 13): WorldValidator (W001-W017), CLI function, overlay.

const Fixture = preload("res://tests/helpers/validator_world_fixture.gd")
const SAMPLE_PATH := "res://src/levels/worlds/sample_island/world.tscn"
const TEMPLATE_PATH := "res://src/levels/worlds/_template/world.tscn"

var fixture: Fixture
var cfg: WorldConfig


func before_each() -> void:
	WorldRules.reset()
	fixture = Fixture.new()
	cfg = WorldConfig.new()
	cfg.cell_size = Fixture.CELL


func after_each() -> void:
	WorldRules.reset()
	fixture = null


func test_clean_world_has_no_results() -> void:
	var results := _run(fixture.clean_data())
	assert_eq(results.size(), 0, "dunia bersih tidak boleh punya temuan: %s" % str(_codes(results)))


func test_generated_worlds_have_no_errors() -> void:
	for path in [SAMPLE_PATH, TEMPLATE_PATH]:
		var result := WorldValidator.validate_scene(path, cfg)
		assert_eq(int(result["errors"]), 0, "%s: %s" % [path, String(result["report"])])
		assert_eq(int(result["exit_code"]), 0)
	assert_true(String(WorldValidator.validate_scene(SAMPLE_PATH, cfg)["report"]).contains("Validasi dunia"))


func test_cli_reports_missing_scene_as_error() -> void:
	var result := WorldValidator.validate_scene("res://tidak/ada.tscn", cfg)
	assert_eq(int(result["exit_code"]), 1)
	assert_eq(int(result["errors"]), 1)
	for error in get_errors():
		error.handled = true


func test_w001_invalid_or_self_intersecting_outline() -> void:
	var short := fixture.clean_data()
	short["outline"] = PackedVector2Array([Vector2.ZERO, Vector2(100.0, 0.0)])
	short["zone_areas"][0]["polygon"] = short["outline"]
	assert_true(_has(_run(short), "W001"), "outline < 3 titik")

	var bowtie := fixture.clean_data()
	var crossing := PackedVector2Array([
		Vector2(-1000.0, -1000.0), Vector2(1000.0, 1000.0), Vector2(1000.0, -1000.0), Vector2(-1000.0, 1000.0),
	])
	bowtie["outline"] = crossing
	bowtie["zone_areas"][0]["polygon"] = crossing
	assert_true(_has(_run(bowtie), "W001"), "outline memotong diri sendiri")


func test_w002_more_than_one_outline() -> void:
	var data := fixture.clean_data()
	data["zone_areas"].append({
		"name": "SecondOutline", "polygon": fixture.rect(-500.0, -500.0, 500.0, 500.0),
		"zone": WorldZoneType.Zone.FOREST, "priority": -90, "order": 99,
		"walkable": true, "build_rule": 0, "is_outline": true,
	})
	assert_true(_has(_run(data), "W002"), "W002")


func test_w003_missing_marker() -> void:
	var data := fixture.clean_data()
	(data["markers"] as Dictionary).erase(WorldSource.POI_SIGNAL_BEACON)
	assert_true(_has(_run(data), "W003"), "W003")


func test_w004_marker_outside_island() -> void:
	var data := fixture.clean_data()
	(data["markers"] as Dictionary)[WorldSource.POI_SIGNAL_BEACON] = Vector2(5000.0, 5000.0)
	assert_true(_has(_run(data), "W004"), "W004")


func test_w005_too_few_night_spawns() -> void:
	var data := fixture.clean_data()
	data["night_points"] = PackedVector2Array([Vector2(1300.0, 0.0), Vector2(0.0, 1300.0)])
	assert_true(_has(_run(data), "W005"), "W005")


func test_w006_night_spawn_not_walkable() -> void:
	var data := fixture.clean_data()
	var night: PackedVector2Array = data["night_points"]
	night.append(Fixture.LAKE_CENTER)
	data["night_points"] = night
	assert_true(_has(_run(data), "W006"), "W006")


func test_w007_night_spawn_too_close() -> void:
	var data := fixture.clean_data()
	var night: PackedVector2Array = data["night_points"]
	night.append(Vector2(0.0, 700.0))
	data["night_points"] = night
	var results := _run(data)
	assert_true(_has(results, "W007"), "W007")
	assert_eq(_severity(results, "W007"), "WARN")


func test_w008_beacon_unreachable() -> void:
	var data := fixture.clean_data()
	# Tembok selebar pulau memisahkan start (utara) dari beacon (selatan).
	(data["zone_areas"] as Array).append(_blocked("Wall", fixture.rect(-1600.0, 950.0, 1600.0, 1050.0), 60))
	var results := _run(data)
	assert_true(_has(results, "W008"), "W008")
	assert_true(_has_error(results, "W008"), "titik wajib tak terjangkau = ERROR")


func test_w009_no_buildable_disk() -> void:
	var data := fixture.clean_data()
	for area in data["zone_areas"]:
		area["build_rule"] = 2
	assert_true(_has(_run(data), "W009"), "W009")


func test_w010_missing_required_resource() -> void:
	var data := fixture.clean_data()
	var only_water: Array = []
	for area in data["resource_areas"]:
		if String(area["name"]) == "RiverBamboo":
			only_water.append(area)
	data["resource_areas"] = only_water
	var results := _run(data)
	assert_true(_has(results, "W010"), "W010")
	assert_true(_has_error(results, "W010"), "kayu/batu/fiber/berry hilang = ERROR")


func test_w011_resource_below_formula_ratio() -> void:
	var data := fixture.clean_data()
	for area in data["resource_areas"]:
		if String(area["name"]) == "ForestGather":
			area["entries"] = [_entry(Fixture.DEF_TREE, 2)]
		elif String(area["name"]) == "CampGather":
			area["entries"] = [
				_entry(Fixture.DEF_TWIG, 2), _entry(Fixture.DEF_SMALL_TREE, 2),
				_entry(Fixture.DEF_SMALL_ROCK, 8), _entry(Fixture.DEF_FIBER_BUSH, 5),
				_entry(Fixture.DEF_BERRY_BUSH, 4),
			]
	var results := _run(data)
	assert_true(_has(results, "W011"), "W011")
	assert_eq(_severity(results, "W011"), "WARN")


func test_w012_narrow_corridor() -> void:
	var data := fixture.clean_data()
	(data["zone_areas"] as Array).append(_blocked("WallLeft", fixture.rect(-1600.0, 950.0, -32.0, 1050.0), 60))
	(data["zone_areas"] as Array).append(_blocked("WallRight", fixture.rect(32.0, 950.0, 1600.0, 1050.0), 60))
	var results := _run(data)
	assert_false(_has_error(results, "W008"), "masih terjangkau sebelum erosi")
	assert_true(_has(results, "W012"), "W012")
	assert_eq(_severity(results, "W012"), "WARN")


func test_w013_overlapping_equal_priority_zones() -> void:
	var data := fixture.clean_data()
	(data["zone_areas"] as Array).append({
		"name": "OverlapBeach", "polygon": fixture.rect(-400.0, -400.0, 400.0, 400.0),
		"zone": WorldZoneType.Zone.EAST_BEACH, "priority": 10, "order": 50,
		"walkable": true, "build_rule": 0, "is_outline": false,
	})
	assert_true(_has(_run(data), "W013"), "W013")


func test_w014_polygon_vertex_limit() -> void:
	cfg.polygon_vertex_limit = 4
	assert_true(_has(_run(fixture.clean_data()), "W014"), "W014")


func test_w015_resource_shortfall() -> void:
	var data := fixture.clean_data()
	(data["resource_areas"] as Array).append({
		"name": "TinyPatch", "polygon": fixture.rect(300.0, 300.0, 500.0, 500.0),
		"entries": [_entry(Fixture.DEF_BERRY_BUSH, 40)], "min_spacing": 400.0, "enabled": true,
	})
	assert_true(_has(_run(data), "W015"), "W015")


func test_w016_forest_too_small() -> void:
	cfg.min_forest_area = 1000000000000.0
	assert_true(_has(_run(fixture.clean_data()), "W016"), "W016")


func test_w017_manual_resource_inside_blocked_area() -> void:
	var data := fixture.clean_data()
	data["manual_resources"] = [{
		"definition": &"twig",
		"position": Fixture.LAKE_CENTER,
	}]
	assert_true(_has(_run(data), "W017"), "W017")


# --- Helper grid: flood fill + erosi ----------------------------------------

func test_flood_fill_and_erode_are_pure_functions() -> void:
	var source := fixture.clean_source()
	var grid := source.grid
	var start := Vector2(0.0, 64.0)
	var reachable := WorldValidator.flood_fill(grid, start)
	assert_eq(int(reachable[ZoneGrid.cell_index(grid, start)]), 1)
	assert_eq(int(reachable[ZoneGrid.cell_index(grid, Vector2(0.0, 1200.0))]), 1, "beacon terjangkau")
	assert_eq(ZoneGrid.cell_index(grid, Vector2(5000.0, 0.0)), -1, "indeks di luar grid = -1")

	var walkable_before := 0
	for value in WorldValidator.walkable_mask(grid):
		walkable_before += int(value)
	var eroded := WorldValidator.erode(grid, 1)
	var walkable_after := 0
	for value in eroded:
		walkable_after += int(value)
	assert_lt(walkable_after, walkable_before, "erosi mengurangi sel walkable")
	assert_eq(int(eroded[ZoneGrid.cell_index(grid, start)]), 1, "pusat camp tetap solid setelah erosi 1 sel")


func test_format_report_counts_and_lines() -> void:
	var results := [
		{"code": "W001", "severity": "ERROR", "message": "rusak", "position": Vector2.ZERO},
		{"code": "W015", "severity": "WARN", "message": "kurang", "position": null},
	]
	var report := WorldValidator.format_report(results)
	assert_true(report.contains("1 ERROR, 1 WARN"))
	assert_true(report.contains("W001"))
	assert_true(report.contains("W015"))
	assert_true(report.contains("(0.0, 0.0)"), report)
	assert_true(WorldValidator.format_report([]).contains("Tidak ada masalah"))


# --- Overlay + tombol editor ------------------------------------------------

func test_overlay_is_off_by_default_and_toggles() -> void:
	WorldRules.set_source(fixture.clean_source())
	var overlay := WorldDebugOverlay.new()
	overlay.config = cfg
	add_child_autofree(overlay)
	assert_false(overlay.is_enabled(), "overlay default OFF")
	assert_false(overlay.visible)
	overlay.toggle()
	assert_true(overlay.is_enabled())
	assert_eq(int(overlay.get_counts()["errors"]), 0, "dunia bersih -> 0 error")
	assert_eq(int(overlay.get_counts()["warnings"]), 0)
	var text := overlay.get_panel_text()
	assert_true(text.contains("AUTHORED"), text)
	assert_true(text.contains("O:"), "panel menyebut tombol toggle")
	overlay.toggle()
	assert_false(overlay.is_enabled())


func test_overlay_works_in_formula_mode() -> void:
	WorldRules.set_source(FormulaWorld.new())
	var overlay := WorldDebugOverlay.new()
	overlay.config = cfg
	add_child_autofree(overlay)
	overlay.set_enabled(true)
	assert_true(overlay.is_formula_mode())
	assert_eq(int(overlay.get_counts()["errors"]), 0)
	assert_true(overlay.get_panel_text().contains("FORMULA"))


func test_tool_button_writes_last_validation_summary() -> void:
	var packed := load(SAMPLE_PATH) as PackedScene
	assert_not_null(packed)
	if packed == null:
		return
	var world := packed.instantiate() as AuthoredWorld
	assert_not_null(world)
	world._validate_world()
	assert_true(world.last_validation_summary.contains("sample_island"), world.last_validation_summary)
	assert_true(world.last_validation_summary.contains("ERROR"), world.last_validation_summary)
	world.free()


# --- Helpers ----------------------------------------------------------------

func _run(data: Dictionary) -> Array:
	return WorldValidator.validate(fixture.make_source(data), cfg)


func _codes(results: Array) -> Array:
	var codes := []
	for result in results:
		codes.append(String(result["code"]))
	return codes


func _has(results: Array, code: String) -> bool:
	return _codes(results).has(code)


func _has_error(results: Array, code: String) -> bool:
	for result in results:
		if String(result["code"]) == code and String(result["severity"]) == "ERROR":
			return true
	return false


func _severity(results: Array, code: String) -> String:
	for result in results:
		if String(result["code"]) == code:
			return String(result["severity"])
	return ""


func _entry(definition: ResourceNodeDefinition, count: int) -> ResourceSpawnEntry:
	var entry := ResourceSpawnEntry.new()
	entry.definition = definition
	entry.count = count
	return entry


func _blocked(node_name: String, polygon: PackedVector2Array, priority: int) -> Dictionary:
	return {
		"name": node_name,
		"polygon": polygon,
		"zone": WorldZoneType.Zone.FOREST,
		"priority": priority,
		"order": 60,
		"walkable": false,
		"build_rule": 2,
		"is_outline": false,
	}
