class_name ItemSlotStore
extends RefCounted

## Logika slot bersama untuk tas (`InventoryComponent`) dan Peti
## (`ChestComponent`).
##
## Helper ini tidak menyimpan state sendiri: pemilik array dan sinyal tetap
## komponen masing-masing. Semua fungsi statis mengubah isi `slots` dan
## melaporkan index yang tersentuh lewat `touched` (dipakai pemanggil untuk
## memancarkan `slot_changed`).
##
## Aturan yang dibagi:
## - tambah: isi stack bertipe sama dulu (urutan slot), lalu slot kosong paling
##   kiri; urutan slot tidak pernah diacak; sisa dikembalikan sebagai int.
## - kurang: atomik (semua atau tidak sama sekali), dari slot terakhir ke
##   pertama supaya stack paling kiri dipertahankan.
## - kosong/penuh dihitung dari isi array; ukuran array hanya diatur
##   `ensure_size()`.

## Sesuaikan jumlah slot tanpa menyentuh isi yang sudah ada.
static func ensure_size(slots: Array[ItemStack], size: int) -> void:
	var target := maxi(size, 0)
	if slots.size() == target:
		return
	slots.resize(target)


## Masukkan item; mengembalikan sisa yang tidak muat (0 = semua masuk).
static func add(
	slots: Array[ItemStack],
	item: ItemDefinition,
	count: int,
	touched: Array[int]
) -> int:
	if item == null or count <= 0:
		return maxi(count, 0)

	var remaining := count
	var stack_max := clampi(item.max_stack, 1, 99)

	for index in slots.size():
		if remaining <= 0:
			break
		var stack := slots[index]
		if stack == null or stack.item == null or stack.item.id != item.id:
			continue
		var space := stack_max - stack.count
		if space <= 0:
			continue
		var moved := mini(remaining, space)
		stack.count += moved
		remaining -= moved
		touched.append(index)

	for index in slots.size():
		if remaining <= 0:
			break
		if slots[index] != null and not slots[index].is_empty():
			continue
		var moved := mini(remaining, stack_max)
		slots[index] = ItemStack.new(item, moved)
		remaining -= moved
		touched.append(index)

	return remaining


## Buang item; atomik. True bila seluruh jumlah terbuang.
static func remove(
	slots: Array[ItemStack],
	item: Variant,
	count: int,
	touched: Array[int]
) -> bool:
	if count <= 0:
		return false
	var id := resolve_id(item)
	if id == &"":
		return false
	if count_of(slots, id) < count:
		return false

	var remaining := count
	for index in range(slots.size() - 1, -1, -1):
		if remaining <= 0:
			break
		var stack := slots[index]
		if stack == null or stack.item == null or stack.item.id != id:
			continue
		var taken := mini(remaining, stack.count)
		stack.count -= taken
		remaining -= taken
		if stack.count <= 0:
			slots[index] = null
		touched.append(index)
	return true


## Total item dengan id tertentu di seluruh slot.
static func count_of(slots: Array[ItemStack], item: Variant) -> int:
	var id := resolve_id(item)
	if id == &"":
		return 0
	var total := 0
	for stack in slots:
		if stack != null and stack.item != null and stack.item.id == id:
			total += stack.count
	return total


static func is_full(slots: Array[ItemStack]) -> bool:
	for stack in slots:
		if stack == null or stack.is_empty():
			return false
	return true


static func is_empty(slots: Array[ItemStack]) -> bool:
	for stack in slots:
		if stack != null and not stack.is_empty():
			return false
	return true


## Kosongkan semua slot. True bila ada yang berubah; `touched` berisi slot yang
## benar-benar dikosongkan.
static func clear(slots: Array[ItemStack], touched: Array[int]) -> bool:
	var changed := false
	for index in slots.size():
		if slots[index] == null:
			continue
		slots[index] = null
		touched.append(index)
		changed = true
	return changed


## ItemDefinition / StringName / String -> id; &"" bila tidak dikenali.
static func resolve_id(item: Variant) -> StringName:
	if item == null:
		return &""
	if item is ItemDefinition:
		return (item as ItemDefinition).id
	if item is StringName:
		return item as StringName
	if item is String:
		return StringName(item as String)
	return &""
