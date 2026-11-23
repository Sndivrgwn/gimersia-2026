extends GutTest

## Tes InventoryComponent, ItemDefinition/ItemEffect, ItemPickup, HotbarHUD.
##
## Memakai Player asli (StatsComponent + NeedsComponent) supaya efek item
## terverifikasi lewat getter nyata. NeedsComponent._process dimatikan; tick()
## tidak dipanggil sehingga nilai hanya berubah karena item.

const InventoryComponentScript = preload("res://src/components/inventory/inventory_component.gd")
const PLAYER_SCENE: PackedScene = preload("res://src/entities/player/player.tscn")
const PICKUP_SCENE: PackedScene = preload("res://src/entities/props/item_pickup.tscn")
const HOTBAR_HUD_SCENE: PackedScene = preload("res://src/ui/hud/inventory/hotbar_hud.tscn")

const ARMOR_SLOT := ItemDefinition.EquipmentSlot.ARMOR
const WEAPON_SLOT := ItemDefinition.EquipmentSlot.WEAPON
const TOOL_SLOT := ItemDefinition.EquipmentSlot.TOOL

var player: Player
var needs: NeedsComponent
var stats: StatsComponent
var inventory: InventoryComponentScript


func before_each() -> void:
	player = PLAYER_SCENE.instantiate() as Player
	player.add_to_group(&"player")
	add_child_autofree(player)

	needs = player.get_node("NeedsComponent") as NeedsComponent
	needs.set_process(false)
	stats = player.stats

	inventory = InventoryComponentScript.new()
	inventory.name = "InventoryComponent"
	inventory.setup(player)
	player.add_child(inventory)
	# Hotbar dibaca di _process; tes memanggilnya manual supaya deterministik.
	inventory.set_process(false)


# --- Kapasitas & stacking ---------------------------------------------------

func test_capacity_comes_from_config() -> void:
	assert_eq(inventory.get_capacity(), 12)
	assert_eq(inventory.get_hotbar_size(), 5)
	assert_eq(inventory.get_slot(0), null)


func test_stacking_tops_up_first_then_leftmost_empty_slot() -> void:
	inventory.add_item(ItemCatalog.STONE, 3)

	assert_eq(inventory.add_item(ItemCatalog.BERRY, 26), 0)
	assert_same(inventory.get_slot_item(0), ItemCatalog.STONE, "slot 0 tidak boleh diacak")
	assert_same(inventory.get_slot_item(1), ItemCatalog.BERRY)
	assert_eq(inventory.get_slot_count(1), 20)
	assert_eq(inventory.get_slot_count(2), 6)

	# Top up stack pertama yang masih punya ruang, bukan membuat slot baru.
	assert_eq(inventory.add_item(ItemCatalog.BERRY, 3), 0)
	assert_eq(inventory.get_slot_count(1), 20)
	assert_eq(inventory.get_slot_count(2), 9)
	assert_true(inventory.is_slot_empty(3))


func test_max_stack_one_items_take_one_slot_each() -> void:
	assert_eq(inventory.add_item(ItemCatalog.WATERSKIN, 3), 0)
	for index in 3:
		assert_eq(inventory.get_slot_count(index), 1)

	assert_eq(inventory.add_item(ItemCatalog.SIGNAL_FLARE, 2), 0)
	assert_eq(inventory.get_slot_count(3), 1)
	assert_eq(inventory.get_slot_count(4), 1)
	assert_eq(inventory.count_of(&"waterskin"), 3)
	assert_eq(inventory.count_of(&"signal_flare"), 2)


func test_full_inventory_returns_leftover() -> void:
	assert_eq(inventory.add_item(ItemCatalog.WATERSKIN, 12), 0)
	assert_true(inventory.is_full())

	assert_eq(inventory.add_item(ItemCatalog.WOOD, 1), 1, "slot penuh -> sisa dikembalikan")
	assert_eq(inventory.add_item(ItemCatalog.WOOD, 5), 5)


# --- Hapus, hitung, pindah --------------------------------------------------

func test_remove_item_is_atomic() -> void:
	inventory.add_item(ItemCatalog.BERRY, 25)
	assert_eq(inventory.count_of(&"berry"), 25)

	assert_false(inventory.remove_item(ItemCatalog.BERRY, 30), "semua atau tidak sama sekali")
	assert_eq(inventory.count_of(&"berry"), 25)
	assert_eq(inventory.get_slot_count(0), 20)

	assert_true(inventory.remove_item(ItemCatalog.BERRY, 5))
	assert_eq(inventory.count_of(&"berry"), 20)
	assert_true(inventory.is_slot_empty(1), "diambil dari stack terakhir dulu")
	assert_eq(inventory.get_slot_count(0), 20)


func test_has_item_and_count_of_across_stacks() -> void:
	inventory.add_item(ItemCatalog.BERRY, 26)

	assert_eq(inventory.count_of(ItemCatalog.BERRY), 26)
	assert_eq(inventory.count_of(&"berry"), 26)
	assert_eq(inventory.count_item(&"berry"), 26)
	assert_true(inventory.has_item(&"berry", 26))
	assert_false(inventory.has_item(&"berry", 27))
	assert_false(inventory.has_item(&"wood", 1))


func test_move_slot_swaps_and_merges() -> void:
	inventory.add_item(ItemCatalog.STONE, 1)
	inventory.add_item(ItemCatalog.BERRY, 5)
	inventory.add_item(ItemCatalog.COCONUT, 1)

	assert_true(inventory.move_slot(0, 2), "tukar dua item berbeda")
	assert_same(inventory.get_slot_item(0), ItemCatalog.COCONUT)
	assert_same(inventory.get_slot_item(2), ItemCatalog.STONE)

	# Dua stack berry terpisah: slot 1 (20) dan slot 3 (5).
	inventory.add_item(ItemCatalog.BERRY, 20)
	assert_eq(inventory.get_slot_count(1), 20)
	assert_eq(inventory.get_slot_count(3), 5)

	assert_true(inventory.move_slot(1, 3), "gabung item sama")
	assert_eq(inventory.get_slot_count(3), 20)
	assert_eq(inventory.get_slot_count(1), 5, "sisa sumber tetap di slot asal")

	assert_false(inventory.move_slot(1, 3), "target penuh -> tidak bisa gabung")
	assert_eq(inventory.get_slot_count(1), 5)
	assert_eq(inventory.get_slot_count(3), 20)


func test_move_slot_into_empty_slot() -> void:
	inventory.add_item(ItemCatalog.WOOD, 4)
	assert_true(inventory.move_slot(0, 7))
	assert_true(inventory.is_slot_empty(0))
	assert_eq(inventory.get_slot_count(7), 4)
	assert_false(inventory.move_slot(0, 1), "slot asal kosong")


# --- Konsumsi ---------------------------------------------------------------

func test_use_slot_applies_exact_deltas_and_consumes_one() -> void:
	var cases := [
		{"item": ItemCatalog.BERRY, "hunger": 62.0, "thirst": 50.0, "fatigue": 60.0, "hp": 40.0},
		{"item": ItemCatalog.COCONUT, "hunger": 60.0, "thirst": 80.0, "fatigue": 60.0, "hp": 40.0},
		{"item": ItemCatalog.RAW_MEAT, "hunger": 65.0, "thirst": 40.0, "fatigue": 50.0, "hp": 40.0},
		{"item": ItemCatalog.COOKED_MEAT, "hunger": 95.0, "thirst": 50.0, "fatigue": 50.0, "hp": 55.0},
		{"item": ItemCatalog.BONE_BROTH, "hunger": 85.0, "thirst": 90.0, "fatigue": 50.0, "hp": 40.0},
		{"item": ItemCatalog.BOILED_WATER, "hunger": 50.0, "thirst": 90.0, "fatigue": 50.0, "hp": 40.0, "start_thirst": 30.0},
		{"item": ItemCatalog.HERBAL_BANDAGE, "hunger": 50.0, "thirst": 50.0, "fatigue": 50.0, "hp": 75.0},
	]

	for case in cases:
		_prepare_needs()
		if case.has("start_thirst"):
			needs.set_value(NeedsComponent.Need.THIRST, case["start_thirst"])
		inventory.clear()
		assert_eq(inventory.add_item(case["item"], 2), 0)
		assert_true(inventory.use_slot(0), "%s harus terpakai" % case["item"].id)

		assert_almost_eq(needs.get_value(NeedsComponent.Need.HUNGER), case["hunger"], 0.001, "%s hunger" % case["item"].id)
		assert_almost_eq(needs.get_value(NeedsComponent.Need.THIRST), case["thirst"], 0.001, "%s thirst" % case["item"].id)
		assert_almost_eq(needs.get_value(NeedsComponent.Need.FATIGUE), case["fatigue"], 0.001, "%s fatigue" % case["item"].id)
		assert_almost_eq(stats.current_hp, case["hp"], 0.001, "%s hp" % case["item"].id)
		assert_eq(inventory.get_slot_count(0), 1, "tepat satu item terpakai")


func test_use_slot_consumes_even_when_stat_is_full() -> void:
	needs.set_value(NeedsComponent.Need.THIRST, 100.0)
	inventory.add_item(ItemCatalog.BOILED_WATER, 1)

	assert_true(inventory.use_slot(0))
	assert_almost_eq(needs.get_value(NeedsComponent.Need.THIRST), 100.0, 0.001)
	assert_true(inventory.is_slot_empty(0), "item tetap terpakai walau stat penuh")


func test_use_slot_rejects_non_consumables_and_empty_slots() -> void:
	assert_false(inventory.use_slot(0), "slot kosong")

	inventory.add_item(ItemCatalog.WOOD, 1)
	inventory.add_item(ItemCatalog.TORCH, 1)
	inventory.add_item(ItemCatalog.STONE_SPEAR, 1)
	inventory.add_item(ItemCatalog.LEATHER_VEST, 1)

	for index in 4:
		assert_false(inventory.use_slot(index), "slot %d bukan consumable" % index)
		assert_eq(inventory.get_slot_count(index), 1, "item tidak boleh hilang")


# --- Equipment --------------------------------------------------------------

func test_armor_adds_and_removes_modifiers() -> void:
	assert_almost_eq(stats.get_damage_reduction(), 0.0, 0.001)
	assert_almost_eq(stats.get_max_hp(), 100.0, 0.001)

	assert_true(inventory.equip(ItemCatalog.LEATHER_VEST))
	assert_almost_eq(stats.get_damage_reduction(), 0.20, 0.001)
	assert_almost_eq(stats.get_max_hp(), 115.0, 0.001)
	assert_same(inventory.get_equipped(ARMOR_SLOT), ItemCatalog.LEATHER_VEST)

	assert_true(inventory.unequip(ARMOR_SLOT))
	assert_almost_eq(stats.get_damage_reduction(), 0.0, 0.001)
	assert_almost_eq(stats.get_max_hp(), 100.0, 0.001)
	assert_null(inventory.get_equipped(ARMOR_SLOT))


func test_replacing_armor_does_not_stack_modifiers() -> void:
	assert_true(inventory.equip(ItemCatalog.LEATHER_VEST))
	assert_true(inventory.equip(ItemCatalog.LEATHER_VEST))
	assert_true(inventory.equip(ItemCatalog.LEATHER_VEST))

	assert_almost_eq(stats.get_damage_reduction(), 0.20, 0.001, "modifier armor tidak menumpuk")
	assert_almost_eq(stats.get_max_hp(), 115.0, 0.001)


func test_weapon_replaces_previous_weapon() -> void:
	assert_true(inventory.equip(ItemCatalog.WOODEN_SPEAR))
	assert_same(inventory.get_equipped(WEAPON_SLOT), ItemCatalog.WOODEN_SPEAR)

	assert_true(inventory.equip(ItemCatalog.BONE_SPEAR))
	assert_same(inventory.get_equipped(WEAPON_SLOT), ItemCatalog.BONE_SPEAR)
	assert_almost_eq(stats.get_attack_damage(), 8.0, 0.001, "senjata tidak mengubah stat sekarang")


func test_tool_slot_is_an_ownership_set() -> void:
	assert_false(inventory.has_tool(&"stone_axe"))
	assert_true(inventory.equip(ItemCatalog.STONE_AXE))
	assert_true(inventory.has_tool(&"stone_axe"))
	assert_false(inventory.has_tool(&"stone_pickaxe"))

	assert_true(inventory.equip(ItemCatalog.STONE_PICKAXE))
	assert_true(inventory.has_tool(ItemCatalog.STONE_AXE))
	assert_true(inventory.has_tool(ItemCatalog.STONE_PICKAXE))

	var changes := []
	inventory.equipment_changed.connect(func(slot: int) -> void: changes.append(slot))
	assert_true(inventory.equip(ItemCatalog.STONE_AXE), "duplikat diabaikan")
	assert_eq(changes.size(), 0, "tool duplikat tidak memancarkan sinyal")

	assert_true(inventory.unequip(TOOL_SLOT))
	assert_false(inventory.has_tool(&"stone_axe"))


func test_equip_rejects_items_without_equipment_slot() -> void:
	assert_false(inventory.equip(ItemCatalog.BERRY))
	assert_false(inventory.equip(ItemCatalog.WOOD))
	assert_false(inventory.equip(null))


# --- Drop & pickup ----------------------------------------------------------

func test_add_or_drop_spawns_pickup_when_full() -> void:
	inventory.add_item(ItemCatalog.WATERSKIN, 12)
	assert_true(inventory.is_full())

	assert_eq(inventory.add_or_drop(ItemCatalog.WOOD, 2), 2, "semua meluber ke dunia")

	var parent := _scene_parent()
	var pickup: ItemPickup = null
	for child in parent.get_children():
		if child is ItemPickup and child.item == ItemCatalog.WOOD:
			pickup = child
			break

	assert_not_null(pickup, "ItemPickup harus muncul di scene")
	if pickup != null:
		assert_eq(pickup.count, 2)
		assert_eq(pickup.global_position, player.global_position)
		pickup.queue_free()


func test_pickup_partial_then_freed_and_delay() -> void:
	inventory.add_item(ItemCatalog.WATERSKIN, 10)
	var pickup := PICKUP_SCENE.instantiate() as ItemPickup
	pickup.item = ItemCatalog.SIGNAL_FLARE
	pickup.count = 5
	add_child_autofree(pickup)

	# Pickup diabaikan selama pickup_delay.
	pickup.body_entered.emit(player)
	assert_eq(inventory.count_of(&"signal_flare"), 0, "masih dalam pickup delay")
	assert_eq(pickup.count, 5)

	pickup._process(pickup.get_pickup_delay())
	pickup.body_entered.emit(player)
	assert_eq(inventory.count_of(&"signal_flare"), 2, "hanya 2 slot kosong yang terisi")
	assert_eq(pickup.count, 3, "sisa tetap di dunia")
	assert_false(pickup.is_queued_for_deletion())

	inventory.clear()
	pickup.body_entered.emit(player)
	assert_eq(inventory.count_of(&"signal_flare"), 3)
	assert_true(pickup.is_queued_for_deletion(), "habis -> hilang dari dunia")


func test_pickup_ignores_non_player_bodies() -> void:
	var pickup := PICKUP_SCENE.instantiate() as ItemPickup
	pickup.item = ItemCatalog.BERRY
	pickup.count = 1
	add_child_autofree(pickup)
	pickup._process(1.0)

	var stranger := Node2D.new()
	add_child_autofree(stranger)
	pickup.body_entered.emit(stranger)

	assert_eq(inventory.count_of(&"berry"), 0)
	assert_false(pickup.is_queued_for_deletion())


# --- Sinyal ----------------------------------------------------------------

func test_signals_fire_once_per_change() -> void:
	var slots: Array[int] = []
	var inventory_events: Array[int] = []
	inventory.slot_changed.connect(func(index: int) -> void: slots.append(index))
	inventory.inventory_changed.connect(func() -> void: inventory_events.append(1))

	inventory.add_item(ItemCatalog.WOOD, 3)
	assert_eq(slots.size(), 1, "satu slot berubah")
	assert_eq(inventory_events.size(), 1)

	inventory.add_item(ItemCatalog.WOOD, 1)
	assert_eq(slots.size(), 2)
	assert_eq(inventory_events.size(), 2)

	inventory.move_slot(0, 1)
	assert_eq(slots.size(), 4, "pindah slot menyentuh dua slot")
	assert_eq(inventory_events.size(), 3, "satu aksi = satu inventory_changed")

	inventory.add_item(ItemCatalog.BERRY, 1)
	assert_eq(slots.size(), 5)
	assert_eq(inventory_events.size(), 4)

	assert_true(inventory.use_slot(0))
	assert_eq(slots.size(), 6)
	assert_eq(inventory_events.size(), 5)


func test_equipment_signal_fires_on_change() -> void:
	var slots: Array[int] = []
	inventory.equipment_changed.connect(func(slot: int) -> void: slots.append(slot))

	inventory.equip(ItemCatalog.LEATHER_VEST)
	assert_eq(slots, [ARMOR_SLOT])
	inventory.unequip(ARMOR_SLOT)
	assert_eq(slots, [ARMOR_SLOT, ARMOR_SLOT])


# --- Hotbar & HUD -----------------------------------------------------------

func test_hotbar_actions_use_slots_without_touching_needs_debug_keys() -> void:
	# Input.action_press()/is_action_just_pressed() memakai frame proses, jadi
	# pastikan tes tidak sedang berada di dalam frame fisika.
	await get_tree().process_frame

	for index in 5:
		var action := "hotbar_%d" % (index + 1)
		assert_true(InputMap.has_action(action), "%s harus terdaftar" % action)
		assert_true(
			ProjectSettings.has_setting("input/" + action),
			"%s harus ada di Input Map project settings" % action
		)

	var keys := [KEY_1, KEY_2, KEY_3, KEY_4, KEY_5]
	for index in keys.size():
		var has_key := false
		for event in InputMap.action_get_events("hotbar_%d" % (index + 1)):
			var key_event := event as InputEventKey
			if key_event != null and key_event.physical_keycode == keys[index]:
				has_key = true
		assert_true(has_key, "hotbar_%d harus memakai tombol %d" % [index + 1, index + 1])

	needs.set_value(NeedsComponent.Need.THIRST, 20.0)
	inventory.add_item(ItemCatalog.BOILED_WATER)

	# Mission 10 (R4): default hotbar kini MEMILIH item. Tes ini menguji jalur
	# lama "tekan angka = pakai", jadi flag kompatibilitas dinyalakan di sini.
	inventory.get_config().hotbar_select_mode = false
	Input.action_press(&"hotbar_1")
	inventory._process(0.0)
	Input.action_release(&"hotbar_1")

	assert_almost_eq(needs.get_value(NeedsComponent.Need.THIRST), 80.0, 0.001)
	assert_true(inventory.is_slot_empty(0))
	inventory.get_config().hotbar_select_mode = true


func test_hotbar_hud_reflects_slots_and_counts() -> void:
	inventory.add_item(ItemCatalog.BERRY, 3)
	var hud := HOTBAR_HUD_SCENE.instantiate()
	hud.inventory = inventory
	add_child_autofree(hud)

	var slot1 := "Root/Panel/Margin/HBox/Slot1/"
	assert_eq((hud.get_node(slot1 + "Key") as Label).text, "1")
	assert_eq((hud.get_node(slot1 + "Name") as Label).text, "Beri")
	assert_eq((hud.get_node(slot1 + "Count") as Label).text, "x3")
	assert_eq((hud.get_node("Root/Panel/Margin/HBox/Slot2/Name") as Label).text, "-")

	inventory.add_item(ItemCatalog.COCONUT)
	assert_eq((hud.get_node("Root/Panel/Margin/HBox/Slot2/Name") as Label).text, "Kelapa")
	assert_eq((hud.get_node("Root/Panel/Margin/HBox/Slot2/Count") as Label).text, "x1")

	inventory.use_slot(0)
	assert_eq((hud.get_node(slot1 + "Count") as Label).text, "x2", "HUD ikut slot_changed")
	assert_false((hud.get_node(slot1 + "Icon") as TextureRect).visible, "tanpa ikon -> pakai nama")


# --- Helper -----------------------------------------------------------------

func _prepare_needs() -> void:
	needs.set_value(NeedsComponent.Need.HUNGER, 50.0)
	needs.set_value(NeedsComponent.Need.THIRST, 50.0)
	needs.set_value(NeedsComponent.Need.FATIGUE, 50.0)
	stats.set_hp(40.0)


func _scene_parent() -> Node:
	var tree := get_tree()
	if tree.current_scene != null:
		return tree.current_scene
	return tree.root
