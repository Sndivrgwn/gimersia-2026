extends SceneTree

## Generator data Fase 1A/1B: tujuan harian + pengaturan panel rekap fajar.
## Jalankan: GODOT --headless --path . -s tools/generate_daily_goals.gd
##
## Menulis ulang:
##   res://src/data/configs/daily_goals.tres
##   res://src/data/configs/dawn_recap_config.tres

const GOALS_PATH := "res://src/data/configs/daily_goals.tres"
const RECAP_PATH := "res://src/data/configs/dawn_recap_config.tres"


func _init() -> void:
	_write_goals()
	_write_recap()
	quit()


func _write_recap() -> void:
	var config := DawnRecapConfig.new()
	config.panel_seconds = 6.0
	config.fade_seconds = 0.35
	_report(RECAP_PATH, ResourceSaver.save(config, RECAP_PATH))


func _write_goals() -> void:
	var config := DailyGoalConfig.new()
	var goals: Array[DailyGoal] = [
		# Hari 1: bertahan hidup pertama + mulai base.
		_goal(1, "bangun api unggun", DailyGoal.Kind.STRUCTURE_BUILT, null, 1, &"campfire"),
		_goal(1, "kumpulkan 4 Kayu", DailyGoal.Kind.ITEM_COUNT, ItemCatalog.WOOD, 4),
		_goal(1, "petakan base (tekan B)", DailyGoal.Kind.BASE_FOUNDED),
		# Hari 2: alat pertama + kulit untuk armor.
		_goal(2, "bangun meja kerja", DailyGoal.Kind.STRUCTURE_BUILT, null, 1, &"workbench"),
		_goal(2, "buat Kapak Batu", DailyGoal.Kind.TOOL_OWNED, ItemCatalog.STONE_AXE),
		_goal(2, "cari 2 Kulit dari rusa", DailyGoal.Kind.ITEM_COUNT, ItemCatalog.HIDE, 2),
		# Hari 3: penyimpanan + makanan matang.
		_goal(3, "bangun Peti", DailyGoal.Kind.STRUCTURE_BUILT, null, 1, &"chest"),
		_goal(3, "masak 1 Daging", DailyGoal.Kind.ITEM_COUNT, ItemCatalog.COOKED_MEAT, 1),
		_goal(3, "kumpulkan 6 Batu", DailyGoal.Kind.ITEM_COUNT, ItemCatalog.STONE, 6),
		# Hari 4: senjata lebih kuat + tempat tidur.
		_goal(4, "buat Tombak Batu", DailyGoal.Kind.WEAPON_EQUIPPED, ItemCatalog.STONE_SPEAR),
		_goal(4, "bangun Tenda", DailyGoal.Kind.STRUCTURE_BUILT, null, 1, &"tent"),
		# Hari 5: bertahan malam makin berat.
		_goal(5, "kumpulkan 3 Tulang", DailyGoal.Kind.ITEM_COUNT, ItemCatalog.BONE, 3),
		_goal(5, "buat Obor untuk malam", DailyGoal.Kind.ITEM_COUNT, ItemCatalog.TORCH, 1),
		# Hari 6: siapkan pelarian.
		_goal(6, "kumpulkan 5 Kayu untuk Suar", DailyGoal.Kind.ITEM_COUNT, ItemCatalog.WOOD, 5),
		_goal(6, "pakai Obor di malam gelap", DailyGoal.Kind.ITEM_COUNT, ItemCatalog.TORCH, 1),
		# Hari 7: puncak.
		_goal(7, "buat Suar Darurat", DailyGoal.Kind.ITEM_COUNT, ItemCatalog.SIGNAL_FLARE, 1),
		_goal(7, "bawa Tombak Tulang", DailyGoal.Kind.WEAPON_EQUIPPED, ItemCatalog.BONE_SPEAR),
	]
	config.goals = goals
	_report(GOALS_PATH, ResourceSaver.save(config, GOALS_PATH))


func _goal(day: int, text: String, kind: int, item: ItemDefinition = null,
		count: int = 1, structure_id: StringName = &"") -> DailyGoal:
	var goal := DailyGoal.new()
	goal.day = day
	goal.text = text
	goal.kind = kind
	goal.item = item
	goal.count = count
	goal.structure_id = structure_id
	return goal


func _report(path: String, error: int) -> void:
	if error == OK:
		print("generate_daily_goals: %s" % path)
	else:
		push_error("generate_daily_goals gagal menulis %s (error %d)" % [path, error])
