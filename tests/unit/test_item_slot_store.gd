extends GutTest

## Tes helper slot bersama (`ItemSlotStore`) yang dipakai tas dan Peti.

func _slots(size: int) -> Array[ItemStack]:
	var slots: Array[ItemStack] = []
	slots.resize(size)
	return slots


func test_add_tops_up_existing_stack_then_uses_leftmost_empty() -> void:
	var slots := _slots(3)
	var touched: Array[int] = []

	var leftover := ItemSlotStore.add(slots, ItemCatalog.WOOD, 25, touched)

	assert_eq(leftover, 0)
	assert_eq(slots[0].count, 20)
	assert_eq(slots[1].count, 5)
	assert_eq(touched.size(), 2)
	assert_eq(touched[0], 0)
	assert_eq(touched[1], 1)
	assert_true(ItemSlotStore.count_of(slots, &"wood") == 25)


func test_add_reports_leftover_when_full() -> void:
	var slots := _slots(1)
	ItemSlotStore.add(slots, ItemCatalog.STONE, 20, _touch())

	var touched: Array[int] = []
	var leftover := ItemSlotStore.add(slots, ItemCatalog.WOOD, 5, touched)

	assert_eq(leftover, 5)
	assert_true(touched.is_empty())
	assert_true(ItemSlotStore.is_full(slots))


func test_remove_is_atomic_and_takes_from_last_slot_first() -> void:
	var slots := _slots(3)
	ItemSlotStore.add(slots, ItemCatalog.WOOD, 25, _touch())
	assert_eq(slots[1].count, 5)

	var touched: Array[int] = []
	assert_false(ItemSlotStore.remove(slots, &"wood", 26, touched), "tidak cukup")
	assert_eq(ItemSlotStore.count_of(slots, &"wood"), 25)

	assert_true(ItemSlotStore.remove(slots, &"wood", 10, touched))
	assert_eq(ItemSlotStore.count_of(slots, &"wood"), 15)
	assert_eq(slots[0].count, 15, "stack kiri dipertahankan")
	assert_null(slots[1], "slot terakhir dikosongkan dulu")


func test_clear_reports_touched_slots() -> void:
	var slots := _slots(2)
	ItemSlotStore.add(slots, ItemCatalog.WOOD, 3, _touch())
	var touched: Array[int] = []

	assert_true(ItemSlotStore.clear(slots, touched))
	assert_true(ItemSlotStore.is_empty(slots))
	assert_eq(touched.size(), 1)
	assert_eq(touched[0], 0)
	assert_false(ItemSlotStore.clear(slots, _touch()), "sudah kosong -> tidak berubah")


func test_ensure_size_keeps_existing_stacks() -> void:
	var slots := _slots(1)
	ItemSlotStore.add(slots, ItemCatalog.BERRY, 4, _touch())

	ItemSlotStore.ensure_size(slots, 3)

	assert_eq(slots.size(), 3)
	assert_eq(slots[0].count, 4)
	assert_eq(ItemSlotStore.count_of(slots, ItemCatalog.BERRY), 4)


func _touch() -> Array[int]:
	var touched: Array[int] = []
	return touched


func test_resolve_id_accepts_definition_name_and_string() -> void:
	assert_eq(ItemSlotStore.resolve_id(ItemCatalog.WOOD), &"wood")
	assert_eq(ItemSlotStore.resolve_id(&"wood"), &"wood")
	assert_eq(ItemSlotStore.resolve_id("wood"), &"wood")
	assert_eq(ItemSlotStore.resolve_id(null), &"")
