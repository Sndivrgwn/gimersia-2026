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
## Petunjuk singkat tab panel di bawah judul.
const TABS_HINT := "Tas 1   Rakit 2   Stat 3   Mahir 4"
const STAT_NORMAL_COLOR := Color(0.88, 0.93, 0.88, 1.0)
const STAT_WARNING_COLOR := Color(1.0, 0.66, 0.52, 1.0)
const NEED_LABELS: Array[String] = ["LAPAR", "HAUS", "LELAH"]
const TOGGLE_ACTION := &"inventory_toggle"
## Esc hanya menutup panel; tidak membukanya.
const CLOSE_ACTION := &"ui_cancel"
const SLOT_SCENE: PackedScene = preload("res://src/ui/panels/inventory/bag_slot.tscn")
const NOTE_MODAL_SCENE: PackedScene = preload("res://src/ui/panels/inventory/note_modal.tscn")
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
var _preserve_hotbar_check: CheckBox
var _note_modal: Control

@onready var _root: Control = $Root
@onready var _tabs: TabContainer = $Root/Frame/Margin/VBox/Tabs
@onready var _grid: GridContainer = %Grid
var _weapon_value: Label
var _tool_value: Label
var _armor_value: Label
var _weight_value: Label

var _slots: Array[BagSlot] = []
var _locked: bool = false
var _crafting_tab: Control
var _crafting_list: VBoxContainer
var _crafting_progress: ProgressBar
var _crafting_status: Label
var _crafting_cancel: Button
var _crafting_rows: Array[CraftingRow] = []
var _tabs_hint: Label
var _action_hint: Label
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
var _player_prof: ProficiencyComponent
var _weapon_icon: TextureRect
var _weapon_cycle_btn: Button
var _tab_buttons: Array[Button] = []
var _prof_levels: Array[Label] = []
var _prof_bars: Array[ProgressBar] = []


func _ready() -> void:
	InputSetup.ensure_actions()
	# Tab harus dipakai untuk toggle, bukan navigasi fokus UI.
	_tabs.get_tab_bar().focus_mode = Control.FOCUS_NONE
	_bind_scene_nodes()
	_connect_player_stats()

	if inventory == null:
		inventory = _find_inventory()
	_build_slots()

	if inventory == null:
		push_warning("BagPanel: InventoryComponent tidak ditemukan.")
	else:
		_connect_inventory()

	refresh()

	if crafting_component == null:
		crafting_component = _find_crafting_component()
	_connect_crafting()
	refresh_crafting()

	_apply_visible(open_on_start)


func _bind_scene_nodes() -> void:
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

	_weapon_value = get_node_or_null("%WeaponValue") as Label
	_tool_value = get_node_or_null("%ToolValue") as Label
	_armor_value = get_node_or_null("%ArmorValue") as Label
	_weapon_icon = get_node_or_null("%WeaponIcon") as TextureRect
	_weapon_cycle_btn = get_node_or_null("%WeaponCycleButton") as Button
	if _weapon_cycle_btn != null and not _weapon_cycle_btn.pressed.is_connected(_on_weapon_cycle_pressed):
		_weapon_cycle_btn.pressed.connect(_on_weapon_cycle_pressed)

	_sort_button = get_node_or_null("%SortButton") as Button
	if _sort_button != null and not _sort_button.pressed.is_connected(_on_sort_pressed):
		_sort_button.pressed.connect(_on_sort_pressed)
	_preserve_hotbar_check = get_node_or_null("%PreserveHotbarCheck") as CheckBox

	_crafting_tab = get_node_or_null("Root/Frame/Margin/VBox/Tabs/RAKIT") as Control
	_crafting_list = get_node_or_null("%CraftingList") as VBoxContainer
	_crafting_progress = get_node_or_null("%CraftingProgress") as ProgressBar
	_crafting_status = get_node_or_null("%CraftingStatus") as Label
	_crafting_cancel = get_node_or_null("%CraftingCancel") as Button
	if _crafting_cancel != null and not _crafting_cancel.pressed.is_connected(_on_crafting_cancel_pressed):
		_crafting_cancel.pressed.connect(_on_crafting_cancel_pressed)

	_weight_value = get_node_or_null("%WeightValue") as Label
	_tabs_hint = get_node_or_null("%TabsHint") as Label
	_action_hint = get_node_or_null("%ActionHint") as Label

	_tab_buttons.clear()
	var tab_bar_box := get_node_or_null("%TabButtons") as HBoxContainer
	if tab_bar_box != null:
		for child in tab_bar_box.get_children():
			var btn := child as Button
			if btn == null:
				continue
			var idx := _tab_buttons.size()
			_tab_buttons.append(btn)
			if not btn.pressed.is_connected(_on_tab_button_pressed):
				btn.pressed.connect(_on_tab_button_pressed.bind(idx))
	if _tabs != null and not _tabs.tab_changed.is_connected(_on_tabs_changed):
		_tabs.tab_changed.connect(_on_tabs_changed)
	_sync_tab_buttons()

	_prof_levels.clear()
	_prof_bars.clear()
	for idx in 4:
		var lv := get_node_or_null("%%ProfLevel%d" % idx) as Label
		var bar := get_node_or_null("%%ProfBar%d" % idx) as ProgressBar
		if lv != null and bar != null:
			_prof_levels.append(lv)
			_prof_bars.append(bar)


## Mission 7: dikunci saat ChestPanel terbuka.
func set_locked(value: bool) -> void:
	_locked = value


func is_locked() -> bool:
	return _locked


func _unhandled_input(event: InputEvent) -> void:
	if _locked:
		return
	if is_note_modal_open() and event.is_action_pressed(CLOSE_ACTION):
		close_note_modal()
		get_viewport().set_input_as_handled()
		return
	if is_open() and event.is_action_pressed(CLOSE_ACTION):
		_apply_visible(false)
		get_viewport().set_input_as_handled()
		return
	if is_open() and event is InputEventKey and event.pressed and not event.echo:
		var key := (event as InputEventKey).keycode
		var count := _tabs.get_tab_count()
		if key == KEY_Q or key == KEY_E:
			if count > 0:
				var delta := -1 if key == KEY_Q else 1
				_tabs.current_tab = posmod(_tabs.current_tab + delta, count)
				_focus_current_tab()
				get_viewport().set_input_as_handled()
			return
		var tab_idx := -1
		match key:
			KEY_1, KEY_KP_1: tab_idx = 0
			KEY_2, KEY_KP_2: tab_idx = 1
			KEY_3, KEY_KP_3: tab_idx = 2
			KEY_4, KEY_KP_4: tab_idx = 3
		if tab_idx >= 0 and tab_idx < count:
			_tabs.current_tab = tab_idx
			_focus_current_tab()
			get_viewport().set_input_as_handled()
			return

	if not event.is_action_pressed(TOGGLE_ACTION):
		return
	toggle_panel()
	get_viewport().set_input_as_handled()


# --- API panel --------------------------------------------------------------

var _is_open: bool = false

func is_open() -> bool:
	return _is_open


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
	_is_open = value
	if value:
		_root.visible = true
		UiBackStack.register(self)
		UiMotion.pop_in(_root)
		refresh()
		# Mission 10: daftar resep dihitung ulang saat dibuka supaya stasiun
		# yang baru dibangun tidak tetap tampil "Butuh Meja Kerja".
		refresh_crafting()
		_focus_current_tab()
	else:
		UiBackStack.unregister(self)
		UiMotion.pop_out(_root)


func _focus_current_tab() -> void:
	if _tabs == null:
		return
	_sync_tab_buttons()
	if _tabs.current_tab == 0 and not _slots.is_empty():
		_slots[0].grab_focus()
	elif _tabs.current_tab == 1:
		for row in _crafting_rows:
			if row != null and not row.is_craft_disabled():
				var btn := row.get_node_or_null("Row/Action/Button") as Button
				if btn != null:
					btn.grab_focus()
				break


func _on_tab_button_pressed(index: int) -> void:
	if _tabs == null or index < 0 or index >= _tabs.get_tab_count():
		return
	_tabs.current_tab = index
	_focus_current_tab()


func _on_tabs_changed(_tab: int) -> void:
	_sync_tab_buttons()


func _sync_tab_buttons() -> void:
	if _tabs == null:
		return
	var current := _tabs.current_tab
	for idx in _tab_buttons.size():
		var btn := _tab_buttons[idx]
		if btn != null:
			btn.set_pressed_no_signal(idx == current)
	if _action_hint != null:
		_action_hint.visible = (current == 0)


func get_sort_button() -> Button:
	return _sort_button


func get_preserve_hotbar_checkbox() -> CheckBox:
	return _preserve_hotbar_check


func _on_sort_pressed() -> void:
	if inventory != null:
		var keep_hotbar := _preserve_hotbar_check != null and _preserve_hotbar_check.button_pressed
		inventory.sort(keep_hotbar)


func _on_weapon_cycle_pressed() -> void:
	if inventory == null:
		return
	var weapons: Array[ItemDefinition] = []
	for stack in inventory.get_slots():
		if stack != null and not stack.is_empty() and stack.item != null:
			if stack.item.equipment_slot == ItemDefinition.EquipmentSlot.WEAPON and not weapons.has(stack.item):
				weapons.append(stack.item)
	if weapons.is_empty():
		return
	var current := inventory.get_equipped(ItemDefinition.EquipmentSlot.WEAPON)
	if current == null:
		inventory.equip(weapons[0])
		return
	var idx := weapons.find(current)
	if idx == -1 or idx + 1 >= weapons.size():
		if weapons.size() == 1:
			inventory.unequip(ItemDefinition.EquipmentSlot.WEAPON)
		else:
			inventory.equip(weapons[0])
	else:
		inventory.equip(weapons[idx + 1])


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
	if not inventory.item_inspected.is_connected(_on_item_inspected):
		inventory.item_inspected.connect(_on_item_inspected)


const COCKPIT_NOTES_TEXT := (
	"LOG PENERBANGAN 07-G:\n\n"
	+ "Mesin kehilangan daya di atas gugusan pulau selatan. Kami mendarat darurat di dekat pantai.\n\n"
	+ "Catatan bertahan hidup:\n"
	+ "- Nyalakan Api Unggun sebelum gelap (gesek batu dengan Batu di tas).\n"
	+ "- Bangun Meja Kerja untuk merakit kapak, tombak, dan Suar Darurat.\n"
	+ "- Bertahan hingga fajar Hari ke-7, lalu nyalakan Suar di Beacon untuk penyelamatan."
)


func _on_item_inspected(item: ItemDefinition, _slot_index: int) -> void:
	if item == null:
		return
	open_note_modal(item)


func open_note_modal(item: ItemDefinition) -> void:
	_ensure_note_modal()
	var body_text := COCKPIT_NOTES_TEXT if item.id == &"cockpit_notes" else item.description
	_note_modal.open_item(item, body_text)


func close_note_modal() -> void:
	if _note_modal != null:
		_note_modal.close_modal()


func is_note_modal_open() -> bool:
	return _note_modal != null and _note_modal.visible


func _ensure_note_modal() -> void:
	if _note_modal != null:
		return
	_note_modal = NOTE_MODAL_SCENE.instantiate() as Control
	add_child(_note_modal)


func refresh() -> void:
	for slot in _slots:
		slot.refresh()
	_refresh_weight()
	_refresh_equipment()
	_refresh_stats()


func _refresh_weight() -> void:
	if _weight_value == null:
		return
	var total_w := 0.0
	var max_w := InventoryComponent.MAX_WEIGHT_KG
	if inventory != null:
		total_w = inventory.get_total_weight()
		max_w = inventory.get_max_weight()
	_weight_value.text = "%.1f / %.0f kg" % [total_w, max_w]


func _connect_player_stats() -> void:
	var tree := get_tree()
	if tree == null:
		return
	var player := tree.get_first_node_in_group(PLAYER_GROUP) as Node
	if player == null:
		return
	_player_stats = player.get("stats") as StatsComponent
	_player_needs = player.get_node_or_null("NeedsComponent") as NeedsComponent
	_player_prof = player.get_node_or_null("ProficiencyComponent") as ProficiencyComponent
	if _player_prof != null:
		if not _player_prof.xp_gained.is_connected(_on_proficiency_changed):
			_player_prof.xp_gained.connect(_on_proficiency_changed)
		if not _player_prof.level_changed.is_connected(_on_proficiency_level_changed):
			_player_prof.level_changed.connect(_on_proficiency_level_changed)
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


func _on_proficiency_changed(_prof: int, _amount: float) -> void:
	_refresh_proficiency()


func _on_proficiency_level_changed(_prof: int, _level: int) -> void:
	_refresh_proficiency()


func _refresh_proficiency() -> void:
	if _prof_levels.is_empty():
		return
	if _player_prof == null:
		_connect_player_stats()
	for idx in _prof_levels.size():
		var lv_lbl := _prof_levels[idx]
		var bar := _prof_bars[idx]
		if _player_prof == null:
			lv_lbl.text = "Lv. 1"
			bar.value = 0.0
			continue
		var lv := _player_prof.get_level(idx)
		lv_lbl.text = "Lv. %d" % lv
		if _player_prof.is_max_level(idx):
			lv_lbl.text = "Lv. %d (MAX)" % lv
			bar.max_value = 1.0
			bar.value = 1.0
		else:
			var need := maxf(_player_prof.get_xp_to_next_level(idx), 1.0)
			bar.max_value = need
			bar.value = clampf(_player_prof.get_xp(idx), 0.0, need)


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
	if _weapon_value != null:
		_weapon_value.text = _equipped_text(ItemDefinition.EquipmentSlot.WEAPON)
	if _armor_value != null:
		_armor_value.text = _equipped_text(ItemDefinition.EquipmentSlot.ARMOR)
	if _tool_value != null:
		_tool_value.text = _owned_tools_text()
	if _weapon_icon != null:
		var equipped := inventory.get_equipped(ItemDefinition.EquipmentSlot.WEAPON) if inventory != null else null
		var tex := equipped.get_icon() if equipped != null else null
		_weapon_icon.texture = tex
		_weapon_icon.visible = tex != null
	if _weapon_cycle_btn != null and inventory != null:
		var has_weapon := false
		for stack in inventory.get_slots():
			if stack != null and not stack.is_empty() and stack.item != null and stack.item.equipment_slot == ItemDefinition.EquipmentSlot.WEAPON:
				has_weapon = true
				break
		_weapon_cycle_btn.disabled = not has_weapon
	_refresh_proficiency()


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
