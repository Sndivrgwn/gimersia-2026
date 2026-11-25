extends CanvasLayer

const UiMotion := preload("res://src/ui/fx/ui_motion.gd")

## Panel tas interaktif (Step 2B): 12 slot tas + kolom equipment.
## Nama/deskripsi item hanya ada di tooltip slot, bukan teks di dalam slot.
##
## Bukan HUD: panel ini menerima mouse dan memanggil `move_slot()` /
## `use_slot()`. Ia tidak menyimpan state gameplay dan tidak mem-pause game:
## DayNightManager, drain Needs, dan gerakan pemain tetap berjalan.
##
## Semua isi dibaca dari InventoryComponent; refresh hanya terjadi lewat sinyal
## `slot_changed`, `equipment_changed`, dan `inventory_changed`.

const PLAYER_GROUP := &"player"
const INVENTORY_NAME := "InventoryComponent"
const CRAFTING_NAME := "CraftingComponent"
const CRAFTING_TAB_PATH := "Root/Frame/Margin/VBox/Tabs/Crafting"
const VBOX_PATH := "Root/Frame/Margin/VBox"
## Kolom Peralatan sudah 210 px; alat tas ditaruh di sana supaya grid 6 kolom
## tidak melebar keluar frame.
const BAG_TOOLS_PATH := "Root/Frame/Margin/VBox/Tabs/Tas/HBox/Equipment"
const BAG_HINT := "Klik kanan: pakai\nShift+klik: bagi"
## Petunjuk singkat tab panel di bawah judul.
const TABS_HINT := "Tab / I: buka-tutup · Tas · Rakit · Stat · Esc: tutup"
const STAT_NORMAL_COLOR := Color(0.88, 0.93, 0.88, 1.0)
const STAT_WARNING_COLOR := Color(1.0, 0.66, 0.52, 1.0)
const NEED_LABELS: Array[String] = ["LAPAR", "HAUS", "LELAH"]
const TOGGLE_ACTION := &"inventory_toggle"
## Esc hanya menutup panel; tidak membukanya.
const CLOSE_ACTION := &"ui_cancel"
const SLOT_SCENE: PackedScene = preload("res://src/ui/panels/inventory/bag_slot.tscn")
const DEFAULT_BAG_SIZE := 12
const DEFAULT_HOTBAR_SIZE := 5
const EMPTY_TEXT := "-"
## TOOL adalah set kepemilikan, jadi kolomnya menampilkan alat yang dimiliki.
const TOOL_ITEMS: Array[ItemDefinition] = [
	ItemCatalog.STONE_AXE,
	ItemCatalog.STONE_PICKAXE,
]

## Opsional; bila kosong dicari lewat grup "player" -> InventoryComponent.
@export var inventory: InventoryComponent
## Opsional; bila kosong dicari lewat grup "player" -> CraftingComponent.
@export var crafting_component: CraftingComponent
## Buka panel saat scene mulai (default: tersembunyi).
@export var open_on_start: bool = false
var _sort_button: Button

@onready var _root: Control = $Root
@onready var _tabs: TabContainer = $Root/Frame/Margin/VBox/Tabs
@onready var _grid: GridContainer = $Root/Frame/Margin/VBox/Tabs/Tas/HBox/Grid
@onready var _weapon_value: Label = $Root/Frame/Margin/VBox/Tabs/Tas/HBox/Equipment/Weapon/Value
@onready var _tool_value: Label = $Root/Frame/Margin/VBox/Tabs/Tas/HBox/Equipment/Tool/Value
@onready var _armor_value: Label = $Root/Frame/Margin/VBox/Tabs/Tas/HBox/Equipment/Armor/Value

var _slots: Array[BagSlot] = []
var _locked: bool = false
var _crafting_tab: Control
var _crafting_list: VBoxContainer
var _crafting_progress: ProgressBar
var _crafting_status: Label
var _crafting_cancel: Button
var _crafting_rows: Array[CraftingRow] = []
var _tabs_hint: Label
var _hp_value: Label
var _stamina_value: Label
var _move_value: Label
var _sprint_value: Label
var _atk_value: Label
var _atk_speed_value: Label
var _gather_value: Label
var _drain_value: Label
var _hunger_value: Label
var _thirst_value: Label
var _fatigue_value: Label
var _player_stats: StatsComponent
var _player_needs: NeedsComponent


func _ready() -> void:
	InputSetup.ensure_actions()
	# Tab harus dipakai untuk toggle, bukan navigasi fokus UI.
	_tabs.get_tab_bar().focus_mode = Control.FOCUS_NONE
	if _tabs.get_tab_count() >= 2:
		_tabs.set_tab_title(1, "Rakit")
	_hp_value = get_node_or_null("%HpValue") as Label
	_stamina_value = get_node_or_null("%StaminaValue") as Label
	_move_value = get_node_or_null("%MoveValue") as Label
	_sprint_value = get_node_or_null("%SprintValue") as Label
	_atk_value = get_node_or_null("%AtkValue") as Label
	_atk_speed_value = get_node_or_null("%AtkSpeedValue") as Label
	_gather_value = get_node_or_null("%GatherValue") as Label
	_drain_value = get_node_or_null("%DrainValue") as Label
	_hunger_value = get_node_or_null("%HungerValue") as Label
	_thirst_value = get_node_or_null("%ThirstValue") as Label
	_fatigue_value = get_node_or_null("%FatigueValue") as Label
	_connect_player_stats()

	if inventory == null:
		inventory = _find_inventory()
	_build_tabs_hint()
	_build_bag_tools()
	_build_slots()

	if inventory == null:
		push_warning("BagPanel: InventoryComponent tidak ditemukan.")
	else:
		_connect_inventory()

	refresh()

	if crafting_component == null:
		crafting_component = _find_crafting_component()
	_build_crafting_tab()
	_connect_crafting()
	refresh_crafting()

	_apply_visible(open_on_start)


## Mission 7: dikunci saat ChestPanel terbuka.
func set_locked(value: bool) -> void:
	_locked = value


func is_locked() -> bool:
	return _locked


func _unhandled_input(event: InputEvent) -> void:
	if _locked:
		return
	if is_open() and event.is_action_pressed(CLOSE_ACTION):
		_apply_visible(false)
		get_viewport().set_input_as_handled()
		return

	if not event.is_action_pressed(TOGGLE_ACTION):
		return
	toggle_panel()
	get_viewport().set_input_as_handled()


# --- API panel --------------------------------------------------------------

func is_open() -> bool:
	return _root.visible


func toggle_panel() -> void:
	if _locked:
		return
	# Mission 10: panel stasiun / UI lain yang terbuka menahan tas.
	if not is_open() and UiBackStack.has_open(self, self):
		return
	_apply_visible(not is_open())


func get_slots() -> Array[BagSlot]:
	return _slots


# --- Teks equipment (dipakai tes) -------------------------------------------

func get_tabs_hint_text() -> String:
	return "" if _tabs_hint == null else _tabs_hint.text


func get_weapon_text() -> String:
	return _weapon_value.text


func get_tool_text() -> String:
	return _tool_value.text


func get_armor_text() -> String:
	return _armor_value.text


# --- Internal ---------------------------------------------------------------

func _apply_visible(value: bool) -> void:
	_root.visible = value
	if value:
		UiBackStack.register(self)
		UiMotion.pop_in(_root)
		refresh()
		# Mission 10: daftar resep dihitung ulang saat dibuka supaya stasiun
		# yang baru dibangun tidak tetap tampil "Butuh Meja Kerja".
		refresh_crafting()
	else:
		UiBackStack.unregister(self)


## Satu baris petunjuk tab di bawah panel.
func _build_tabs_hint() -> void:
	var vbox := get_node_or_null(VBOX_PATH) as VBoxContainer
	if vbox == null:
		return
	_tabs_hint = Label.new()
	_tabs_hint.name = "TabsHint"
	_tabs_hint.text = TABS_HINT
	_tabs_hint.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_tabs_hint.add_theme_font_size_override("font_size", 10)
	_tabs_hint.add_theme_color_override("font_color", Color(0.36, 0.27, 0.19, 1.0))
	vbox.add_child(_tabs_hint)
	vbox.move_child(_tabs_hint, 1)


## Fase 4A: tombol urutkan + petunjuk pecah tumpukan di tab Tas.
func _build_bag_tools() -> void:
	var column := get_node_or_null(BAG_TOOLS_PATH) as VBoxContainer
	if column == null:
		return

	var tools := VBoxContainer.new()
	tools.name = "BagTools"
	tools.add_theme_constant_override("separation", 6)
	column.add_child(tools)

	var hint := Label.new()
	hint.name = "Hint"
	hint.text = BAG_HINT
	hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	hint.custom_minimum_size = Vector2(96.0, 0.0)
	hint.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hint.add_theme_font_size_override("font_size", 9)
	hint.add_theme_color_override("font_color", Color(0.72, 0.78, 0.72, 1.0))
	tools.add_child(hint)

	_sort_button = Button.new()
	_sort_button.name = "SortButton"
	_sort_button.text = "Urutkan"
	_sort_button.tooltip_text = "Gabung dan urutkan isi tas"
	_sort_button.custom_minimum_size = Vector2(96.0, 26.0)
	_sort_button.pressed.connect(_on_sort_pressed)
	tools.add_child(_sort_button)


func get_sort_button() -> Button:
	return _sort_button


func _on_sort_pressed() -> void:
	if inventory != null:
		inventory.sort()


func _build_slots() -> void:
	if _grid == null:
		return

	for child in _grid.get_children():
		_grid.remove_child(child)
		child.queue_free()
	_slots.clear()

	var capacity := DEFAULT_BAG_SIZE
	var hotbar := DEFAULT_HOTBAR_SIZE
	if inventory != null:
		capacity = inventory.get_capacity()
		hotbar = inventory.get_hotbar_size()

	for index in capacity:
		var slot := SLOT_SCENE.instantiate() as BagSlot
		slot.slot_index = index
		slot.hotbar_number = (index + 1) if index < hotbar else 0
		slot.inventory = inventory
		_grid.add_child(slot)
		_slots.append(slot)


func _connect_inventory() -> void:
	if not inventory.slot_changed.is_connected(_on_slot_changed):
		inventory.slot_changed.connect(_on_slot_changed)
	if not inventory.equipment_changed.is_connected(_on_equipment_changed):
		inventory.equipment_changed.connect(_on_equipment_changed)
	if not inventory.inventory_changed.is_connected(_on_inventory_changed):
		inventory.inventory_changed.connect(_on_inventory_changed)


func refresh() -> void:
	for slot in _slots:
		slot.refresh()
	_refresh_equipment()
	_refresh_stats()


func _connect_player_stats() -> void:
	var tree := get_tree()
	if tree == null:
		return
	var player := tree.get_first_node_in_group(PLAYER_GROUP) as Node
	if player == null:
		return
	_player_stats = player.get("stats") as StatsComponent
	_player_needs = player.get_node_or_null("NeedsComponent") as NeedsComponent
	if _player_stats != null:
		if not _player_stats.stats_changed.is_connected(_refresh_stats):
			_player_stats.stats_changed.connect(_refresh_stats)
		if not _player_stats.hp_changed.is_connected(_on_hp_changed):
			_player_stats.hp_changed.connect(_on_hp_changed)
	if _player_needs != null:
		if not _player_needs.tier_changed.is_connected(_on_need_changed):
			_player_needs.tier_changed.connect(_on_need_changed)
		if not _player_needs.value_changed.is_connected(_on_need_changed):
			_player_needs.value_changed.connect(_on_need_changed)
		if not _player_needs.fatigue_cap_changed.is_connected(_on_fatigue_cap_changed):
			_player_needs.fatigue_cap_changed.connect(_on_fatigue_cap_changed)


func _on_hp_changed(_current: float, _max_hp: float) -> void:
	_refresh_stats()


func _on_need_changed(_need: int, _value: Variant) -> void:
	_refresh_stats()


func _on_fatigue_cap_changed(_cap: float) -> void:
	_refresh_stats()


func _refresh_stats() -> void:
	if _hp_value == null:
		return
	if _player_stats == null:
		_connect_player_stats()
	if _player_stats == null:
		return
	var stamina_text := EMPTY_TEXT
	if _player_needs != null:
		stamina_text = "%.0f / %.0f" % [
			_player_needs.get_value(NeedsComponent.Need.FATIGUE),
			_player_needs.get_fatigue_cap(),
		]
	_hp_value.text = "%.0f / %.0f" % [_player_stats.current_hp, _player_stats.get_max_hp()]
	if _stamina_value != null:
		_stamina_value.text = stamina_text
	if _move_value != null:
		_move_value.text = "%.0f" % _player_stats.get_move_speed()
	if _sprint_value != null:
		_sprint_value.text = "%.0f" % _player_stats.get_sprint_speed()
	if _atk_value != null:
		_atk_value.text = "%.1f" % _player_stats.get_attack_damage()
	if _atk_speed_value != null:
		_atk_speed_value.text = "%.2f/s" % _player_stats.get_attack_speed()
	if _gather_value != null:
		_gather_value.text = "x%.2f" % _player_stats.get_gather_time_factor()
	if _drain_value != null:
		_drain_value.text = "x%.2f" % _player_stats.get_sprint_fatigue_drain_factor()

	var need_labels: Array[Label] = [_hunger_value, _thirst_value, _fatigue_value]
	for index in need_labels.size():
		var lbl := need_labels[index]
		if lbl == null:
			continue
		var tier := _player_needs.get_tier(index) if _player_needs != null else NeedsComponent.Tier.NORMAL
		lbl.text = _need_tier_text(tier)
		lbl.add_theme_color_override(
			"font_color",
			STAT_WARNING_COLOR if tier != NeedsComponent.Tier.NORMAL else STAT_NORMAL_COLOR
		)


func _need_tier_text(tier: int) -> String:
	match tier:
		NeedsComponent.Tier.LOW:
			return "RENDAH"
		NeedsComponent.Tier.ZERO:
			return "HABIS"
		_:
			return "NORMAL"


func _refresh_equipment() -> void:
	if _weapon_value == null:
		return
	_weapon_value.text = _equipped_text(ItemDefinition.EquipmentSlot.WEAPON)
	_armor_value.text = _equipped_text(ItemDefinition.EquipmentSlot.ARMOR)
	_tool_value.text = _owned_tools_text()


func _equipped_text(slot: int) -> String:
	if inventory == null:
		return EMPTY_TEXT
	var item := inventory.get_equipped(slot)
	return EMPTY_TEXT if item == null else item.display_name


func _owned_tools_text() -> String:
	if inventory == null:
		return EMPTY_TEXT

	var owned := PackedStringArray()
	for item in TOOL_ITEMS:
		if inventory.has_tool(item):
			owned.append(item.display_name)
	return ", ".join(owned) if not owned.is_empty() else EMPTY_TEXT


func _on_slot_changed(index: int) -> void:
	if index >= 0 and index < _slots.size():
		_slots[index].refresh()
	_refresh_crafting_rows()


func _on_equipment_changed(_slot: int) -> void:
	_refresh_equipment()
	_refresh_crafting_rows()


func _on_inventory_changed() -> void:
	refresh()


func _find_inventory() -> InventoryComponent:
	var tree := get_tree()
	if tree == null:
		return null
	var candidate := tree.get_first_node_in_group(PLAYER_GROUP)
	if candidate == null:
		return null
	return candidate.get_node_or_null(INVENTORY_NAME) as InventoryComponent


# --- Tab Crafting -----------------------------------------------------------

func get_crafting_rows() -> Array[CraftingRow]:
	return _crafting_rows


func get_crafting_status_text() -> String:
	return "" if _crafting_status == null else _crafting_status.text


func get_crafting_progress() -> ProgressBar:
	return _crafting_progress


## Batalkan craft yang sedang berjalan (tombol "Batalkan" dan tes).
func cancel_current_craft() -> void:
	if crafting_component == null:
		return
	crafting_component.cancel_craft("Dibatalkan")


func _find_crafting_component() -> CraftingComponent:
	var tree := get_tree()
	if tree == null:
		return null
	var candidate := tree.get_first_node_in_group(PLAYER_GROUP)
	if candidate == null:
		return null
	return candidate.get_node_or_null(CRAFTING_NAME) as CraftingComponent


func _build_crafting_tab() -> void:
	if _crafting_tab != null:
		return
	_crafting_tab = get_node_or_null(CRAFTING_TAB_PATH) as Control
	if _crafting_tab == null:
		return

	var vbox := VBoxContainer.new()
	vbox.name = "CraftingBox"
	vbox.add_theme_constant_override("separation", 8)
	_crafting_tab.add_child(vbox)

	_crafting_status = Label.new()
	_crafting_status.name = "Status"
	_crafting_status.add_theme_font_size_override("font_size", 12)
	_crafting_status.add_theme_color_override("font_color", Color(0.9, 0.86, 0.66, 1.0))
	vbox.add_child(_crafting_status)

	_crafting_progress = ProgressBar.new()
	_crafting_progress.name = "Progress"
	_crafting_progress.max_value = 1.0
	_crafting_progress.value = 0.0
	_crafting_progress.show_percentage = false
	_crafting_progress.custom_minimum_size = Vector2(0, 10)
	_crafting_progress.visible = false
	vbox.add_child(_crafting_progress)

	_crafting_cancel = Button.new()
	_crafting_cancel.name = "Cancel"
	_crafting_cancel.text = "Batalkan"
	_crafting_cancel.visible = false
	_crafting_cancel.custom_minimum_size = Vector2(90, 24)
	_crafting_cancel.pressed.connect(_on_crafting_cancel_pressed)
	vbox.add_child(_crafting_cancel)

	var scroll := ScrollContainer.new()
	scroll.name = "Scroll"
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.custom_minimum_size = Vector2(0, 250)
	vbox.add_child(scroll)

	_crafting_list = VBoxContainer.new()
	_crafting_list.name = "Rows"
	_crafting_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_crafting_list.add_theme_constant_override("separation", 4)
	scroll.add_child(_crafting_list)


func _connect_crafting() -> void:
	if crafting_component == null:
		return
	crafting_component.craft_started.connect(_on_craft_started)
	crafting_component.craft_progress.connect(_on_craft_progress)
	crafting_component.craft_completed.connect(_on_craft_completed)
	crafting_component.craft_cancelled.connect(_on_craft_cancelled)
	crafting_component.stations_changed.connect(_on_stations_changed)


## Bangun ulang daftar resep: tersedia dulu, lalu bagian "TERKUNCI" yang redup.
func refresh_crafting() -> void:
	if _crafting_list == null:
		return

	for child in _crafting_list.get_children():
		_crafting_list.remove_child(child)
		child.free()
	_crafting_rows.clear()

	if crafting_component == null:
		_crafting_status.text = "Crafting tidak tersedia (CraftingComponent tidak ditemukan)."
		return

	# Semua resep tampil: yang langsung bisa dibuat dan yang butuh stasiun.
	# Resep stasiun yang belum tersedia tetap tampil dengan status di kartunya.
	for recipe in crafting_component.get_available_recipes():
		_add_crafting_row(recipe, false)

	for recipe in crafting_component.get_locked_recipes():
		_add_crafting_row(recipe, true)

	# Status terakhir ("Selesai"/"Batal") dipertahankan sampai aksi berikutnya.
	if not crafting_component.is_crafting():
		_crafting_progress.visible = false
		_crafting_cancel.visible = false


func _add_crafting_row(recipe: RecipeDefinition, locked: bool) -> void:
	var row := CraftingRow.new()
	row.setup(recipe, crafting_component, inventory, locked)
	_crafting_list.add_child(row)
	_crafting_rows.append(row)


func _refresh_crafting_rows() -> void:
	for row in _crafting_rows:
		row.refresh()


func _on_crafting_cancel_pressed() -> void:
	cancel_current_craft()


func _on_craft_started(recipe: RecipeDefinition) -> void:
	_crafting_status.text = "Membuat %s..." % recipe.display_name
	_crafting_progress.value = 0.0
	_crafting_progress.visible = true
	_crafting_cancel.visible = true
	_refresh_crafting_rows()


func _on_craft_progress(ratio: float) -> void:
	if _crafting_progress == null:
		return
	_crafting_progress.value = clampf(ratio, 0.0, 1.0)
	_crafting_progress.visible = true


func _on_craft_completed(recipe: RecipeDefinition) -> void:
	_crafting_status.text = "Selesai: %s" % recipe.display_name
	_crafting_progress.value = 0.0
	_crafting_progress.visible = false
	_crafting_cancel.visible = false
	refresh_crafting()


func _on_craft_cancelled(recipe: RecipeDefinition, reason: String) -> void:
	var suffix := "" if reason.is_empty() else " (%s)" % reason
	_crafting_status.text = "Batal: %s%s" % [recipe.display_name, suffix]
	_crafting_progress.value = 0.0
	_crafting_progress.visible = false
	_crafting_cancel.visible = false
	refresh_crafting()


func _on_stations_changed() -> void:
	if is_open():
		refresh_crafting()
