class_name CraftingComponent
extends Node

## Crafting pemain: satu craft pada satu waktu, satu stasiun dalam jangkauan.
##
## Bahan dicek dan dikonsumsi **atomik saat craft selesai**, bukan saat mulai.
## Waktu craft memakai delta nyata (`_process` -> `tick()`), dikali
## `StatsComponent.get_craft_time_factor()`; tidak menyentuh jam game.
##
## Stasiun adalah node di grup `crafting_station` yang menyediakan
## `station_type: int` (RecipeDefinition.Station) dan `is_station_active() -> bool`.
## HAND selalu tersedia.
##
## Input dibaca dengan polling (`Input.is_action_pressed()`), bukan
## `_unhandled_input`.

signal craft_started(recipe: RecipeDefinition)
signal craft_progress(ratio: float)
signal craft_completed(recipe: RecipeDefinition)
signal craft_cancelled(recipe: RecipeDefinition, reason: String)
## Hook XP masa depan (belum ada XP). Dipancarkan setelah craft_completed.
signal crafted(recipe: RecipeDefinition, count: int)
## Stasiun dalam jangkauan berubah (dibangun, hancur, menyala, atau pemain
## bergerak masuk/keluar). Dipakai UI untuk menyegarkan daftar resep.
signal stations_changed()

const STATION_GROUP := &"crafting_station"
const PLAYER_GROUP := &"player"
const CRAFT_STATION_RANGE := 140.0
const REASON_MOVED := "Bergerak"
const REASON_DAMAGED := "Terkena serangan"
const REASON_STATION_LOST := "Stasiun hilang"
const REASON_NO_INGREDIENTS := "Bahan kurang"
const REASON_UNKNOWN := "Resep tidak dikenal"
const REASON_BETTER_WEAPON := "Sudah punya senjata yang lebih baik"
const REASON_TOOL_OWNED := "Alat sudah dimiliki"
const REASON_ARMOR_EQUIPPED := "Zirah sudah terpasang"

const RECIPE_FILES: Array[String] = [
	"res://src/data/recipes/wooden_spear.tres",
	"res://src/data/recipes/torch.tres",
	"res://src/data/recipes/herbal_bandage.tres",
	"res://src/data/recipes/stone_axe.tres",
	"res://src/data/recipes/stone_pickaxe.tres",
	"res://src/data/recipes/stone_spear.tres",
	"res://src/data/recipes/bone_spear.tres",
	"res://src/data/recipes/leather_vest.tres",
	"res://src/data/recipes/waterskin.tres",
	"res://src/data/recipes/signal_flare.tres",
	"res://src/data/recipes/cooked_meat.tres",
	"res://src/data/recipes/boiled_water.tres",
	"res://src/data/recipes/bone_broth.tres",
]

## Jarak maksimum stasiun dari pemain.
@export var station_range: float = CRAFT_STATION_RANGE
## Mission 10: tuning panel stasiun (satu sumber angka, lihat StationConfig).
@export var station_config: StationConfig = preload("res://src/data/configs/station_config.tres")
## Daftar resep. Kosong = memuat `RECIPE_FILES`.
@export var recipes: Array[RecipeDefinition] = []
## Opsional; diisi otomatis dari parent (Player) bila kosong.
@export var inventory: InventoryComponent
@export var stats: StatsComponent
@export var player: Node
## Matikan di scene tes bila input tidak ingin ikut aktif.
@export var input_enabled: bool = true

var _recipe: RecipeDefinition
var _elapsed: float = 0.0
var _duration: float = 0.0
var _last_ratio: float = 0.0
var _hp_at_start: float = -1.0
var _loaded: bool = false
var _station_key: String = ""
## Stasiun yang dipakai craft berjalan (null = perilaku lama).
var _active_station: Node


func _ready() -> void:
	_bind()


func _process(delta: float) -> void:
	tick(delta)


# --- Setup ------------------------------------------------------------------

func setup(p_player: Node, p_inventory: InventoryComponent = null, p_stats: StatsComponent = null) -> void:
	player = p_player
	inventory = p_inventory
	stats = p_stats
	if is_inside_tree():
		_bind()


# --- Read API ---------------------------------------------------------------

## Stasiun aktif dalam jangkauan pemain.
func get_stations_in_range() -> Array:
	var result: Array = []
	var tree := get_tree()
	if tree == null:
		return result
	var origin := _origin()
	for node in tree.get_nodes_in_group(STATION_GROUP):
		if not _is_station_usable(node):
			continue
		var station := node as Node2D
		if station == null:
			continue
		if origin.distance_to(station.global_position) <= station_range:
			result.append(node)
	return result


## Resep yang bisa dicoba sekarang (stasiunnya tersedia). HAND selalu.
func get_available_recipes() -> Array[RecipeDefinition]:
	var result: Array[RecipeDefinition] = []
	for recipe in get_all_recipes():
		if _station_available(recipe.station):
			result.append(recipe)
	return result


## Resep yang stasiunnya belum ada (untuk bagian "terkunci" di UI).
func get_locked_recipes() -> Array[RecipeDefinition]:
	var result: Array[RecipeDefinition] = []
	for recipe in get_all_recipes():
		if not _station_available(recipe.station):
			result.append(recipe)
	return result


func get_all_recipes() -> Array[RecipeDefinition]:
	_ensure_recipes()
	return recipes


func get_current_recipe() -> RecipeDefinition:
	return _recipe


func is_crafting() -> bool:
	return _recipe != null


func get_progress_ratio() -> float:
	return _last_ratio


## Alasan kenapa resep tidak bisa di-craft; "" bila bisa.
##
## Urutan penting: stasiun -> aturan equip -> bahan. Alasan equip lebih
## informatif (mis. senjata lebih baik / alat sudah dimiliki / zirah terpasang)
## dan tidak akan berubah walau bahan dilengkapi, jadi dicek sebelum
## "Bahan kurang".
func get_block_reason(recipe: RecipeDefinition) -> String:
	if recipe == null:
		return REASON_UNKNOWN
	if not _station_available(recipe.station):
		return recipe.get_station_block_reason()
	var equipment_reason := _equipment_block_reason(recipe)
	if not equipment_reason.is_empty():
		return equipment_reason
	if not has_ingredients(recipe):
		return REASON_NO_INGREDIENTS
	return ""


func can_craft(recipe: RecipeDefinition) -> bool:
	if recipe == null or _recipe != null:
		return false
	return get_block_reason(recipe).is_empty()


## Bahan lengkap, termasuk bahan yang diambil dari slot WEAPON.
func has_ingredients(recipe: RecipeDefinition) -> bool:
	if recipe == null or inventory == null:
		return false
	for amount in ItemAmount.weapon_slot_amounts(recipe.ingredients):
		if not _weapon_matches(amount.item):
			return false
	return ItemAmount.has_all(ItemAmount.without_weapon_slot(recipe.ingredients), inventory)


## Jumlah bahan yang dimiliki untuk UI ("have/need").
func count_available(item: ItemDefinition) -> int:
	if item == null or inventory == null:
		return 0
	if item.equipment_slot == ItemDefinition.EquipmentSlot.WEAPON:
		return 1 if _weapon_matches(item) else 0
	return inventory.count_of(item)


# --- Kontrol ----------------------------------------------------------------

## Station opsional: craft hanya sah selama stasiun itu aktif dan dekat.
func start_craft(recipe: RecipeDefinition, station: Node = null) -> bool:
	if _recipe != null:
		return false
	if station != null and not _station_valid(station, recipe):
		return false
	if not can_craft(recipe):
		return false
	_active_station = station
	_recipe = recipe
	_elapsed = 0.0
	_last_ratio = 0.0
	_hp_at_start = _current_hp()
	_duration = maxf(recipe.craft_time * _craft_time_factor(), 0.0)
	craft_started.emit(recipe)
	if _duration <= 0.0:
		_complete()
	return true


func cancel_craft(reason: String = "") -> void:
	if _recipe == null:
		return
	var recipe := _recipe
	_clear_state()
	craft_progress.emit(0.0)
	craft_cancelled.emit(recipe, reason)


## Satu tick. _process() hanya memanggil ini supaya tes deterministik.
func tick(delta: float) -> void:
	_refresh_station_key()
	if _recipe == null or delta <= 0.0:
		return
	if input_enabled and InputSetup.is_movement_pressed():
		cancel_craft(REASON_MOVED)
		return
	if _hp_dropped():
		cancel_craft(REASON_DAMAGED)
		return
	if _active_station != null:
		if not _station_valid(_active_station, _recipe):
			cancel_craft(REASON_STATION_LOST)
			return
	elif not _station_available(_recipe.station):
		cancel_craft(REASON_STATION_LOST)
		return

	_elapsed += delta
	var ratio := 1.0 if _duration <= 0.0 else clampf(_elapsed / _duration, 0.0, 1.0)
	if not is_equal_approx(ratio, _last_ratio):
		_last_ratio = ratio
		craft_progress.emit(ratio)
	if _elapsed >= _duration:
		_complete()


# --- Internal ---------------------------------------------------------------

func _bind() -> void:
	if station_config != null and is_equal_approx(station_range, CRAFT_STATION_RANGE):
		station_range = station_config.use_range
	if player == null:
		player = get_parent()
	if inventory == null and player != null:
		inventory = player.get_node_or_null("InventoryComponent") as InventoryComponent
	if stats == null and player != null:
		stats = player.get_node_or_null("StatsComponent") as StatsComponent
	InputSetup.ensure_actions()


func _ensure_recipes() -> void:
	if _loaded or not recipes.is_empty():
		_loaded = true
		return
	for path in RECIPE_FILES:
		var recipe := load(path) as RecipeDefinition
		if recipe != null:
			recipes.append(recipe)
	_loaded = true


func get_station_config() -> StationConfig:
	if station_config == null:
		station_config = StationConfig.new()
	return station_config


## Resep milik satu jenis stasiun (WORKBENCH/CAMPFIRE/HAND).
func get_recipes_for(station_type: int) -> Array[RecipeDefinition]:
	_ensure_recipes()
	var result: Array[RecipeDefinition] = []
	for recipe in recipes:
		if recipe != null and recipe.station == station_type:
			result.append(recipe)
	return result


## Stasiun valid untuk resep ini: hidup, jenis sama, dan dalam jangkauan.
func _station_valid(station: Node, recipe: RecipeDefinition) -> bool:
	if station == null or recipe == null or not is_instance_valid(station):
		return false
	if not station.is_inside_tree() or recipe.station == RecipeDefinition.Station.HAND:
		return false
	if not _is_station_usable(station):
		return false
	if not ("station_type" in station) or int(station.get("station_type")) != recipe.station:
		return false
	var node := station as Node2D
	if node == null:
		return false
	return _origin().distance_to(node.global_position) <= get_station_config().use_range


func get_active_station() -> Node:
	return _active_station


func _origin() -> Vector2:
	if player is Node2D:
		return (player as Node2D).global_position
	return Vector2.ZERO


func _is_station_usable(node: Node) -> bool:
	if node == null or not is_instance_valid(node) or not node.is_inside_tree():
		return false
	if not ("station_type" in node):
		return false
	if not node.has_method("is_station_active"):
		return false
	return node.is_station_active()


func _station_available(station: int) -> bool:
	if station == RecipeDefinition.Station.HAND:
		return true
	var tree := get_tree()
	if tree == null:
		return false
	var origin := _origin()
	for node in tree.get_nodes_in_group(STATION_GROUP):
		if not _is_station_usable(node):
			continue
		if int(node.station_type) != station:
			continue
		var station_node := node as Node2D
		if station_node == null:
			continue
		if origin.distance_to(station_node.global_position) <= station_range:
			return true
	return false


func _equipment_block_reason(recipe: RecipeDefinition) -> String:
	var result := recipe.result
	if result == null or inventory == null:
		return ""
	match result.equipment_slot:
		ItemDefinition.EquipmentSlot.WEAPON:
			var current := inventory.get_equipped(ItemDefinition.EquipmentSlot.WEAPON)
			if current != null and current.weapon_damage >= result.weapon_damage:
				return REASON_BETTER_WEAPON
		ItemDefinition.EquipmentSlot.TOOL:
			if inventory.has_tool(result):
				return REASON_TOOL_OWNED
		ItemDefinition.EquipmentSlot.ARMOR:
			if inventory.get_equipped(ItemDefinition.EquipmentSlot.ARMOR) != null:
				return REASON_ARMOR_EQUIPPED
	return ""


func _weapon_matches(item: ItemDefinition) -> bool:
	if inventory == null or item == null:
		return false
	var equipped := inventory.get_equipped(ItemDefinition.EquipmentSlot.WEAPON)
	return equipped != null and equipped.id == item.id


func _consume_ingredients(recipe: RecipeDefinition) -> bool:
	if inventory == null or not has_ingredients(recipe):
		return false
	# Bahan tas lewat helper bersama; bahan senjata dilepas dari slot WEAPON.
	if not ItemAmount.consume_all(ItemAmount.without_weapon_slot(recipe.ingredients), inventory):
		return false
	for _amount in ItemAmount.weapon_slot_amounts(recipe.ingredients):
		inventory.unequip(ItemDefinition.EquipmentSlot.WEAPON)
	return true


func _complete() -> void:
	var recipe := _recipe
	if recipe == null:
		return
	_clear_state()
	craft_progress.emit(1.0)

	if not _consume_ingredients(recipe):
		craft_cancelled.emit(recipe, REASON_NO_INGREDIENTS)
		return

	var count := maxi(recipe.result_count, 1)
	var result := recipe.result
	if result != null and result.equipment_slot != ItemDefinition.EquipmentSlot.NONE:
		inventory.equip(result)
	else:
		inventory.add_or_drop(result, count)

	craft_completed.emit(recipe)
	crafted.emit(recipe, count if result != null else 0)


func _clear_state() -> void:
	_recipe = null
	_active_station = null
	_elapsed = 0.0
	_duration = 0.0
	_hp_at_start = -1.0
	_last_ratio = 0.0


func _craft_time_factor() -> float:
	if stats == null:
		return 1.0
	return stats.get_craft_time_factor()


func _current_hp() -> float:
	if stats == null:
		return -1.0
	return stats.current_hp


func _hp_dropped() -> bool:
	if stats == null or _hp_at_start < 0.0:
		return false
	return stats.current_hp < _hp_at_start - 0.0001


## Kunci stasiun dalam jangkauan; berubah -> pancarkan `stations_changed`.
func _refresh_station_key() -> void:
	var parts := PackedStringArray()
	var tree := get_tree()
	if tree != null:
		var origin := _origin()
		for node in tree.get_nodes_in_group(STATION_GROUP):
			if not _is_station_usable(node):
				continue
			var station := node as Node2D
			if station == null:
				continue
			if origin.distance_to(station.global_position) > station_range:
				continue
			parts.append("%d:%d" % [int(node.station_type), node.get_instance_id()])
	parts.sort()
	var key := ",".join(parts)
	if key == _station_key:
		return
	_station_key = key
	stations_changed.emit()
