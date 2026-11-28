extends GutTest

## Tes Poin 1: Obor 300s, Kantung Air 3/3, Night Watch dari Api Unggun,
## Tidur sampai Pagi di Tenda, Catatan Kokpit bisa dibaca, dan Urutkan Jaga Hotbar.

const PLAYER_SCENE: PackedScene = preload("res://src/entities/player/player.tscn")
const CAMPFIRE_SCENE: PackedScene = preload("res://src/entities/camp/campfire/campfire.tscn")
const TENT_SCENE: PackedScene = preload("res://src/entities/camp/tent/tent.tscn")
const BAG_PANEL_SCENE: PackedScene = preload("res://src/ui/panels/inventory/bag_panel.tscn")
const TENT_DEF: StructureDefinition = preload("res://src/data/camp/tent.tres")


class StubClock extends Node:
	signal time_skipped(seconds: float)
	signal night_ended(day: int)
	var night: bool = true
	var remaining: float = 200.0
	var elapsed: float = 0.0
	var skip_calls: int = 0
	var last_skip: float = 0.0
	var watch_active: bool = false

	func is_day() -> bool:
		return not night

	func is_night() -> bool:
		return night

	func get_remaining_seconds() -> float:
		return remaining

	func get_total_elapsed_seconds() -> float:
		return elapsed

	func get_time_scale() -> float:
		return 1.0

	func set_night_watch(active: bool) -> void:
		watch_active = active

	func skip_time(seconds: float) -> void:
		skip_calls += 1
		last_skip = seconds
		elapsed += seconds
		remaining = maxf(remaining - seconds, 0.0)
		time_skipped.emit(seconds)


func _make_player_with_components() -> Dictionary:
	var player := PLAYER_SCENE.instantiate() as Player
	add_child_autofree(player)
	var inv := InventoryComponent.new()
	inv.name = "InventoryComponent"
	inv.hotbar_input_enabled = false
	inv.setup(player)
	player.add_child(inv)
	var status := StatusEffectsComponent.new()
	status.name = "StatusEffectsComponent"
	status.inventory = inv
	player.add_child(status)
	var light := PlayerLight.new()
	light.name = "PlayerLight"
	light.inventory = inv
	player.add_child(light)
	return {"player": player, "inv": inv, "status": status, "light": light}


func test_torch_consumable_starts_300s_buff_and_activates_player_light() -> void:
	var h := _make_player_with_components()
	var inv: InventoryComponent = h["inv"]
	var status: StatusEffectsComponent = h["status"]
	var light: PlayerLight = h["light"]
	inv.clear()
	inv.add_item(ItemCatalog.TORCH, 2)

	assert_true(inv.use_slot(0), "Obor bisa dipakai")
	assert_eq(inv.count_of(ItemCatalog.TORCH), 1, "1 obor terkonsumsi")
	assert_true(status.is_active(StatusEffectsComponent.TORCH_EFFECT_ID), "Buff obor aktif")
	assert_almost_eq(status.get_remaining(StatusEffectsComponent.TORCH_EFFECT_ID), 300.0, 0.1)

	# Buang sisa obor dari hotbar -> PlayerLight tetap terang karena buff 300s masih aktif!
	inv.clear()
	assert_true(light.is_torch_active(), "PlayerLight tetap radius obor saat buff 300s aktif")

	# Setelah 300 detik habis -> buff mati dan PlayerLight kembali ke radius karakter.
	status.tick(301.0)
	assert_false(status.is_active(StatusEffectsComponent.TORCH_EFFECT_ID))
	assert_false(light.is_torch_active())


func test_campfire_night_watch_fallback_when_no_tent() -> void:
	var clock := StubClock.new()
	add_child_autofree(clock)

	var camp := CampController.new()
	add_child_autofree(camp)
	var nw := NightWatchController.new()
	nw.clock = clock
	nw.camp = camp
	nw.input_enabled = false
	camp.add_child(nw)

	var fire := CAMPFIRE_SCENE.instantiate() as Campfire
	fire.clock = clock
	fire.night_watch = nw
	camp.add_child(fire)
	fire.set_fuel(240.0)
	fire.ignite()

	assert_true(fire.is_lit())
	assert_true(fire.can_night_watch(), "Malam + api menyala + tanpa tenda -> boleh Jaga Malam dari api")
	assert_true(fire.toggle_night_watch())
	assert_true(nw.is_active())
	assert_true(fire.is_night_watch_active())
	assert_true(fire.toggle_night_watch())
	assert_false(nw.is_active())


func test_tent_sleep_until_morning_skips_remaining_night() -> void:
	var clock := StubClock.new()
	clock.night = true
	clock.remaining = 210.0
	add_child_autofree(clock)

	var tent := TENT_SCENE.instantiate() as Tent
	tent.definition = TENT_DEF
	tent.clock = clock
	add_child_autofree(tent)

	assert_true(tent.can_sleep_until_morning())
	assert_true(tent.sleep_until_morning())
	assert_eq(clock.skip_calls, 1)
	assert_almost_eq(clock.last_skip, 210.0, 0.01, "Melewati sisa malam hingga pagi")


func test_cockpit_notes_opens_modal_without_consuming_item() -> void:
	var h := _make_player_with_components()
	var inv: InventoryComponent = h["inv"]
	inv.clear()
	inv.add_item(ItemCatalog.COCKPIT_NOTES, 1)

	var panel := BAG_PANEL_SCENE.instantiate()
	panel.inventory = inv
	add_child_autofree(panel)

	assert_false(panel.is_note_modal_open())
	assert_true(inv.use_slot(0), "Catatan Kokpit bisa dibaca")
	assert_true(panel.is_note_modal_open(), "Modal Catatan Kokpit terbuka")
	assert_eq(inv.count_of(ItemCatalog.COCKPIT_NOTES), 1, "Catatan Kokpit tidak hilang setelah dibaca")
	panel.close_note_modal()
	assert_false(panel.is_note_modal_open())


func test_sort_preserve_hotbar_keeps_slots_0_to_4_untouched() -> void:
	var h := _make_player_with_components()
	var inv: InventoryComponent = h["inv"]
	inv.clear()
	# Hotbar slot 0 = Berry, slot 1 = Wood (sengaja tidak terurut)
	inv.add_item(ItemCatalog.BERRY, 3)
	inv.add_item(ItemCatalog.WOOD, 2)
	# Isi slot 5 & 6 (di luar hotbar) secara tidak terurut
	inv.get_slots()[5] = ItemStack.new(ItemCatalog.BERRY, 4)
	inv.get_slots()[6] = ItemStack.new(ItemCatalog.STONE, 2)

	assert_true(inv.sort(true), "Slot tas 5..11 diurutkan")
	assert_same(inv.get_slot_item(0), ItemCatalog.BERRY, "Hotbar slot 0 tidak berubah")
	assert_same(inv.get_slot_item(1), ItemCatalog.WOOD, "Hotbar slot 1 tidak berubah")
	assert_same(inv.get_slot_item(5), ItemCatalog.STONE, "Slot 5 jadi STONE (RESOURCE dulu)")
	assert_same(inv.get_slot_item(6), ItemCatalog.BERRY, "Slot 6 jadi BERRY (CONSUMABLE setelah RESOURCE)")
