class_name ChestComponent
extends Node

## Penyimpanan Peti: 24 slot dengan aturan stacking yang sama dengan tas.
##
## ItemStack adalah wadah nilai yang sama dengan tas; urutan slot tidak pernah
## diacak, stack yang sama diisi lebih dulu, lalu slot kosong paling kiri.
## Komponen ini tidak menyentuh UI dan tidak punya clock.

signal slot_changed(index: int)
## Sekali per aksi yang mengubah isi (bukan per slot).
signal contents_changed()

const DEFAULT_CAPACITY := 24

## Jumlah slot. Default 24 sesuai spesifikasi.
@export var capacity: int = DEFAULT_CAPACITY

var _slots: Array[ItemStack] = []


func _ready() -> void:
	_ensure_slots()


# --- Read API ---------------------------------------------------------------

func get_capacity() -> int:
	return maxi(capacity, 0)


func get_slots() -> Array[ItemStack]:
	_ensure_slots()
	return _slots


func get_slot(index: int) -> ItemStack:
	if not _is_valid_slot(index):
		return null
	return _slots[index]


func get_slot_item(index: int) -> ItemDefinition:
	var stack := get_slot(index)
	return null if stack == null else stack.item


func get_slot_count(index: int) -> int:
	var stack := get_slot(index)
	return 0 if stack == null else stack.count


func is_slot_empty(index: int) -> bool:
	var stack := get_slot(index)
	return stack == null or stack.is_empty()


func is_empty() -> bool:
	return ItemSlotStore.is_empty(_slots)


func is_full() -> bool:
	return ItemSlotStore.is_full(_slots)


func count_of(item: Variant) -> int:
	return ItemSlotStore.count_of(_slots, item)


# --- Write API --------------------------------------------------------------

## Masukkan item; mengembalikan sisa yang tidak muat (0 = semua masuk).
func add_item(item: ItemDefinition, count: int = 1) -> int:
	if item == null or count <= 0:
		return maxi(count, 0)
	_ensure_slots()

	var touched: Array[int] = []
	var remaining := ItemSlotStore.add(_slots, item, count, touched)

	if touched.is_empty():
		return remaining
	for index in touched:
		slot_changed.emit(index)
	contents_changed.emit()
	return remaining


## Buang item; atomik (semua atau tidak sama sekali).
func remove_item(item: Variant, count: int = 1) -> bool:
	if count <= 0:
		return false
	_ensure_slots()
	var touched: Array[int] = []
	if not ItemSlotStore.remove(_slots, item, count, touched):
		return false

	for index in touched:
		slot_changed.emit(index)
	contents_changed.emit()
	return true


## Kosongkan peti (dipakai saat hancur setelah isinya dijatuhkan).
func clear() -> void:
	_ensure_slots()
	var touched: Array[int] = []
	var changed := ItemSlotStore.clear(_slots, touched)
	for index in touched:
		slot_changed.emit(index)
	if changed:
		contents_changed.emit()


## Pindahkan seluruh stack slot peti ke tas. Sisa yang tidak muat tetap di peti.
func move_to_bag(index: int, inventory: InventoryComponent) -> bool:
	if inventory == null or not _is_valid_slot(index):
		return false
	var stack := _slots[index]
	if stack == null or stack.is_empty():
		return false

	var leftover := inventory.add_item(stack.item, stack.count)
	if leftover == stack.count:
		return false
	if leftover <= 0:
		_slots[index] = null
	else:
		stack.count = leftover
	slot_changed.emit(index)
	contents_changed.emit()
	return true


## Pindahkan seluruh stack slot tas ke peti. Sisa yang tidak muat tetap di tas.
func move_from_bag(inventory: InventoryComponent, index: int) -> bool:
	if inventory == null:
		return false
	var stack := inventory.get_slot(index)
	if stack == null or stack.is_empty():
		return false

	var leftover := add_item(stack.item, stack.count)
	var moved := stack.count - leftover
	if moved <= 0:
		return false
	# Kurangi persis slot yang diklik; `remove_item` bisa mengambil dari slot
	# lain dengan item sama sehingga slot yang diklik tidak berubah.
	inventory.remove_from_slot(index, moved)
	return true


# --- Internal ---------------------------------------------------------------

func _ensure_slots() -> void:
	ItemSlotStore.ensure_size(_slots, get_capacity())


func _is_valid_slot(index: int) -> bool:
	return index >= 0 and index < _slots.size()

