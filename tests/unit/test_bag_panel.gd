extends GutTest

## Tes BagPanel (Step 2B): action toggle, grid 12 slot + penanda hotbar,
## tooltip, drag-drop (swap/merge), klik kanan pakai, equipment read-only,
## dan refresh lewat sinyal InventoryComponent.

const InventoryComponentScript = preload("res://src/components/inventory/inventory_component.gd")
const BagSlotScript = preload("res://src/ui/panels/inventory/bag_slot.gd")
const PLAYER_SCENE: PackedScene = preload("res://src/entities/player/player.tscn")
const BAG_PANEL_SCENE: PackedScene = preload("res://src/ui/panels/inventory/bag_panel.tscn")

const TABS_PATH := "Root/Frame/Margin/VBox/Tabs"
const WEAPON_PATH := "Root/Frame/Margin/VBox/Tabs/Tas/HBox/Equipment/Weapon/Value"
const TOOL_PATH := "Root/Frame/Margin/VBox/Tabs/Tas/HBox/Equipment/Tool/Value"
const ARMOR_PATH := "Root/Frame/Margin/VBox/Tabs/Tas/HBox/Equipment/Armor/Value"
const CRAFTING_TAB_PATH := "Root/Frame/Margin/VBox/Tabs/Crafting"

var player: Player
var needs: NeedsComponent
var inventory: InventoryComponentScript
var panel


func before_each() -> void:
	player = PLAYER_SCENE.instantiate() as Player
	player.add_to_group(&"player")
	add_child_autofree(player)

	needs = player.get_node("NeedsComponent") as NeedsComponent
	needs.set_process(false)

	inventory = InventoryComponentScript.new()
	inventory.name = "InventoryComponent"
	inventory.setup(player)
	player.add_child(inventory)
	# Hotbar 1-5 dibaca di _process; matikan supaya tes deterministik.
	inventory.set_process(false)

	panel = BAG_PANEL_SCENE.instantiate()
	panel.inventory = inventory
	add_child_autofree(panel)


# --- Toggle & input ---------------------------------------------------------

func test_toggle_action_has_tab_and_i_in_project_settings() -> void:
	assert_true(InputMap.has_action(&"inventory_toggle"))
	assert_true(
		ProjectSettings.has_setting("input/inventory_toggle"),
		"inventory_toggle harus ada di Input Map project settings"
	)

	var codes: Array[int] = []
	for event in InputMap.action_get_events(&"inventory_toggle"):
		var key_event := event as InputEventKey
		if key_event != null:
			codes.append(key_event.physical_keycode)
	assert_true(codes.has(KEY_TAB), "Tab harus terdaftar")
	assert_true(codes.has(KEY_I), "I harus terdaftar")


func test_panel_hidden_by_default_and_toggles_with_action() -> void:
	assert_false(panel.is_open(), "panel harus tersembunyi saat mulai")

	var event := InputEventAction.new()
	event.action = &"inventory_toggle"
	event.pressed = true

	panel._unhandled_input(event)
	assert_true(panel.is_open(), "Tab/I membuka panel")

	panel._unhandled_input(event)
	assert_false(panel.is_open(), "Tab/I menutup panel")


func test_escape_closes_only_when_open() -> void:
	var escape := InputEventAction.new()
	escape.action = &"ui_cancel"
	escape.pressed = true

	panel._unhandled_input(escape)
	assert_false(panel.is_open(), "Esc tidak membuka panel")

	panel.toggle_panel()
	assert_true(panel.is_open())
	panel._unhandled_input(escape)
	assert_false(panel.is_open(), "Esc menutup panel")


func test_panel_does_not_pause_the_game() -> void:
	var paused_before := get_tree().paused
	panel.toggle_panel()

	assert_true(panel.is_open())
	assert_eq(get_tree().paused, paused_before, "panel tidak boleh mengubah pause")
	assert_false(get_tree().paused, "game tetap berjalan saat panel terbuka")


func test_header_hint_names_the_two_tabs() -> void:
	var hint: String = panel.get_tabs_hint_text()
	assert_string_contains(hint, "Tab / I")
	assert_string_contains(hint, "Tas")
	assert_string_contains(hint, "Crafting")
	assert_string_contains(hint, "Esc")
	assert_false(hint.contains("Profisiensi"), "tab Profisiensi sudah dihapus")


func test_panel_and_slots_block_mouse_and_avoid_focus() -> void:
	var root := panel.get_node("Root") as Control
	assert_eq(root.mouse_filter, Control.MOUSE_FILTER_STOP, "root panel menelan mouse")
	assert_eq(
		(panel.get_node(TABS_PATH) as TabContainer).focus_mode,
		Control.FOCUS_NONE,
		"Tab tidak boleh dipakai navigasi fokus"
	)

	for slot in panel.get_slots():
		assert_eq(slot.mouse_filter, Control.MOUSE_FILTER_STOP)
		assert_eq(slot.focus_mode, Control.FOCUS_NONE)


# --- Grid & isi slot --------------------------------------------------------

func test_grid_has_twelve_slots_and_hotbar_markers() -> void:
	var slots: Array = panel.get_slots()
	assert_eq(slots.size(), 12, "tas 12 slot")

	var grid := panel.get_node(TABS_PATH + "/Tas/HBox/Grid") as GridContainer
	assert_eq(grid.get_child_count(), 12)

	for index in slots.size():
		assert_eq(slots[index].slot_index, index)
		assert_true(slots[index].custom_minimum_size.x >= 64.0, "slot minimal 64x64")
		assert_true(slots[index].custom_minimum_size.y >= 64.0)

	for index in 5:
		assert_eq(slots[index].get_key_text(), str(index + 1), "slot 0-4 ditandai 1-5")
	for index in range(5, 12):
		assert_eq(slots[index].get_key_text(), "", "slot 5-11 bukan hotbar")


func test_slot_shows_count_and_tooltip_only() -> void:
	var slots: Array = panel.get_slots()
	assert_eq(slots[0].get_label_text(), "", "slot kosong tanpa teks nama")
	assert_eq(slots[0].get_count_text(), "")
	assert_eq(slots[0].tooltip_text, "", "slot kosong tanpa tooltip")

	inventory.add_item(ItemCatalog.BERRY, 3)
	assert_eq(slots[0].get_label_text(), "", "nama item tidak ditampilkan di slot")
	assert_eq(slots[0].get_count_text(), "x3")
	assert_string_contains(slots[0].tooltip_text, "Beri", "nama/deskripsi lewat tooltip")

	inventory.use_slot(0)
	assert_eq(slots[0].get_count_text(), "x2")


# --- Tooltip ----------------------------------------------------------------

func test_tooltip_has_name_description_and_effect_line() -> void:
	inventory.add_item(ItemCatalog.BERRY)
	var tooltip: String = panel.get_slots()[0].tooltip_text

	assert_string_contains(tooltip, "Beri")
	assert_string_contains(tooltip, "Buah beri hutan")
	assert_string_contains(tooltip, "Hunger +12")
	assert_string_contains(tooltip, "Fatigue +10")


func test_effect_summary_covers_consumable_weapon_and_armor() -> void:
	assert_string_contains(BagSlotScript.describe_effect(ItemCatalog.RAW_MEAT), "Thirst -10")
	assert_string_contains(BagSlotScript.describe_effect(ItemCatalog.BOILED_WATER), "Thirst +60")
	assert_string_contains(BagSlotScript.describe_effect(ItemCatalog.WOODEN_SPEAR), "Damage 18")
	assert_string_contains(BagSlotScript.describe_effect(ItemCatalog.LEATHER_VEST), "-20% damage")
	assert_string_contains(BagSlotScript.describe_effect(ItemCatalog.LEATHER_VEST), "+15 max HP")
	assert_string_contains(BagSlotScript.describe_effect(ItemCatalog.BONE_BROTH), "Regen +1.0 HP/dtk")
	assert_eq(BagSlotScript.describe_effect(ItemCatalog.WOOD), "", "resource tanpa efek")


# --- Drag & drop ------------------------------------------------------------

func test_drop_swaps_two_bag_slots() -> void:
	inventory.add_item(ItemCatalog.STONE, 2)
	inventory.add_item(ItemCatalog.BERRY, 3)
	var slots: Array = panel.get_slots()

	var data: Variant = slots[0]._get_drag_data(Vector2.ZERO)
	assert_not_null(data)
	assert_true(slots[1]._can_drop_data(Vector2.ZERO, data))

	slots[1]._drop_data(Vector2.ZERO, data)
	assert_eq(inventory.get_slot_item(0).id, ItemCatalog.BERRY.id)
	assert_eq(inventory.get_slot_item(1).id, ItemCatalog.STONE.id)
	assert_eq(inventory.get_slot_count(1), 2)


func test_drop_merges_same_item_when_target_has_room() -> void:
	inventory.add_item(ItemCatalog.BERRY, 25)
	var slots: Array = panel.get_slots()
	assert_eq(inventory.get_slot_count(0), 20, "stack penuh memaksa slot kedua")
	assert_eq(inventory.get_slot_count(1), 5)

	var data: Variant = slots[0]._get_drag_data(Vector2.ZERO)
	slots[1]._drop_data(Vector2.ZERO, data)

	assert_eq(inventory.get_slot_count(1), 20, "merge mengisi slot target")
	assert_eq(inventory.get_slot_count(0), 5)


func test_empty_slot_cannot_start_a_drag() -> void:
	assert_null(panel.get_slots()[3]._get_drag_data(Vector2.ZERO))


func test_drop_rejects_foreign_payload() -> void:
	inventory.add_item(ItemCatalog.STONE)
	assert_false(panel.get_slots()[1]._can_drop_data(Vector2.ZERO, {"index": 0}))
	assert_false(panel.get_slots()[1]._can_drop_data(Vector2.ZERO, null))


# --- Klik kanan -------------------------------------------------------------

func test_right_click_uses_consumable() -> void:
	needs.set_value(NeedsComponent.Need.THIRST, 20.0)
	inventory.add_item(ItemCatalog.BOILED_WATER)

	_right_click(panel.get_slots()[0])

	assert_almost_eq(needs.get_value(NeedsComponent.Need.THIRST), 80.0, 0.001)
	assert_true(inventory.is_slot_empty(0), "satu item terpakai")


func test_right_click_ignores_non_consumable_and_empty_slot() -> void:
	inventory.add_item(ItemCatalog.WOOD, 2)

	_right_click(panel.get_slots()[0])
	assert_eq(inventory.get_slot_count(0), 2, "resource tidak terpakai")

	_right_click(panel.get_slots()[6])
	assert_true(inventory.is_slot_empty(6), "slot kosong tidak berbuat apa-apa")


# --- Equipment --------------------------------------------------------------

func test_equipment_column_is_read_only_and_shows_ownership() -> void:
	var weapon := panel.get_node(WEAPON_PATH) as Label
	var tool := panel.get_node(TOOL_PATH) as Label
	var armor := panel.get_node(ARMOR_PATH) as Label

	assert_eq(weapon.text, "-")
	assert_eq(tool.text, "-")
	assert_eq(armor.text, "-")

	inventory.equip(ItemCatalog.WOODEN_SPEAR)
	inventory.equip(ItemCatalog.LEATHER_VEST)
	inventory.equip(ItemCatalog.STONE_AXE)

	assert_eq(weapon.text, ItemCatalog.WOODEN_SPEAR.display_name, "sinyal equipment_changed")
	assert_eq(armor.text, ItemCatalog.LEATHER_VEST.display_name)
	assert_eq(tool.text, ItemCatalog.STONE_AXE.display_name)

	inventory.equip(ItemCatalog.STONE_PICKAXE)
	assert_string_contains(tool.text, ItemCatalog.STONE_PICKAXE.display_name)

	for label: Label in [weapon, tool, armor]:
		assert_eq(label.mouse_filter, Control.MOUSE_FILTER_IGNORE, "equipment read-only")
		assert_ne(label.get_script(), BagSlotScript, "equipment bukan BagSlot")


func test_equipment_drops_are_not_accepted() -> void:
	var weapon := panel.get_node(WEAPON_PATH) as Control
	assert_false(weapon.has_method(&"_can_drop_data"), "label equipment tidak menerima drop")
	assert_false(weapon.has_method(&"_get_drag_data"), "label equipment tidak bisa di-drag")


# --- Tab Crafting -----------------------------------------------------------

func test_crafting_tab_hosts_code_built_ui_instead_of_placeholder() -> void:
	var tabs := panel.get_node(TABS_PATH) as TabContainer
	# Tab Profisiensi dihapus; panel tas hanya Tas + Crafting.
	assert_eq(tabs.get_tab_count(), 2)
	assert_eq(tabs.get_tab_title(0), "Tas")
	assert_eq(tabs.get_tab_title(1), "Crafting")

	var tab := panel.get_node(CRAFTING_TAB_PATH) as Control
	assert_not_null(tab.find_child("CraftingBox", true, false), "isi tab dibuat saat runtime")
	assert_null(tab.find_child("Label", false, false), "label 'Segera hadir' sudah diganti")
	assert_true(panel.get_crafting_rows().is_empty(), "tanpa pemain tidak ada baris resep")


# --- Helper -----------------------------------------------------------------

func _right_click(slot: Node) -> void:
	var event := InputEventMouseButton.new()
	event.button_index = MOUSE_BUTTON_RIGHT
	event.pressed = true
	slot._gui_input(event)
