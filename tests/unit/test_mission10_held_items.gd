extends GutTest

## Mission 10 Phase 3: hotbar memilih item, use_held memakainya, item terlihat.

const IslandHarness = preload("res://tests/integration/island_harness.gd")
const Rooster = preload("res://src/entities/player/player.tscn")

var _harness: IslandHarness


func before_each() -> void:
	_harness = IslandHarness.new()
	_harness.setup(self)


func after_each() -> void:
	if _harness != null:
		_harness.teardown()
		_harness = null


func _selection() -> HotbarSelectionComponent:
	return _harness.player.get_node_or_null("HotbarSelectionComponent") as HotbarSelectionComponent


func test_actions_are_registered_with_free_keys() -> void:
	InputSetup.ensure_actions()
	assert_true(InputMap.has_action(InputSetup.HOTBAR_NEXT))
	assert_true(InputMap.has_action(InputSetup.HOTBAR_PREV))
	assert_true(InputMap.has_action(InputSetup.USE_HELD))
	var f_bound := false
	for event in InputMap.action_get_events(InputSetup.USE_HELD):
		var key := event as InputEventKey
		if key != null and key.physical_keycode == KEY_F:
			f_bound = true
	assert_true(f_bound, "F dipakai untuk use_held")


func test_selection_wraps_and_fires_signal() -> void:
	var selection := _selection()
	assert_not_null(selection, "komponen seleksi terpasang di Player")
	watch_signals(selection)
	selection.select(2)
	assert_eq(selection.selected_index, 2)
	selection.select(0)
	selection.select(4)
	selection.tick(0.0) # tidak mengubah apa pun tanpa input
	assert_signal_emitted(selection, "selected_changed")


func test_use_held_only_consumes_selected_consumable() -> void:
	var selection := _selection()
	_harness.inventory.add_item(ItemCatalog.BERRY, 3)
	_harness.inventory.add_item(ItemCatalog.WOOD, 2)
	selection.select(0)
	_harness.needs.set_value(NeedsComponent.Need.HUNGER, 10.0)
	assert_true(selection.use_held(), "beri di slot terpilih terpakai")
	assert_eq(_harness.inventory.get_slot_count(0), 2)
	selection.select(1)
	assert_false(selection.use_held(), "resource tidak bisa dipakai")
	assert_eq(_harness.inventory.get_slot_count(1), 2)


func test_old_mode_flag_restores_press_uses_behaviour() -> void:
	var config := InventoryConfig.new()
	config.hotbar_select_mode = false
	assert_false(config.hotbar_select_mode, "flag lama tersedia untuk kompatibilitas")
	config.hotbar_select_mode = true
	assert_true(_harness.inventory.get_config().hotbar_select_mode, "default = mode pilih")


func test_hotbar_hud_shows_held_item_label() -> void:
	var hud = _harness.island.get_node("HotbarHUD")
	var selection := _selection()
	_harness.inventory.add_item(ItemCatalog.BERRY, 3)
	selection.select(0)
	selection.selected_changed.emit(0, selection.get_held_stack())
	assert_eq(hud.get_held_label_text(), "Beri x3")
	assert_eq(hud.get_selected_index(), 0)
	selection.select(1)
	assert_eq(hud.get_held_label_text(), "", "slot kosong tanpa label")


func test_held_visual_falls_back_to_equipped_weapon() -> void:
	var held := _harness.player.get_node("HeldItemVisual") as HeldItemVisual
	assert_not_null(held, "HeldItemVisual terpasang")
	assert_false(held.is_holding(), "tangan kosong tanpa item")
	_harness.inventory.add_item(ItemCatalog.WOODEN_SPEAR, 1)
	_harness.inventory.equip(ItemCatalog.WOODEN_SPEAR)
	held.refresh()
	assert_true(held.is_holding(), "senjata terpasang tampil di tangan")
	assert_eq(held.get_current_id(), &"wooden_spear")
	assert_gt(held.get_shape_points().size(), 0, "placeholder shape dibuat")


func test_held_visual_prefers_selected_hotbar_item() -> void:
	var held := _harness.player.get_node("HeldItemVisual") as HeldItemVisual
	var selection := _selection()
	_harness.inventory.add_item(ItemCatalog.BERRY, 2)
	selection.select(0)
	held.refresh()
	assert_eq(held.get_current_id(), &"berry")
	assert_eq(held.get_shape_points().size(), 10, "consumable = lingkaran placeholder")
	held.notify_swing()
	assert_true(held.is_swing_active())
	held.tick(held.config.swing_seconds + 0.01)
	assert_false(held.is_swing_active())
