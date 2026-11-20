class_name ItemAmount
extends Resource

## Satu pasangan item + jumlah, dipakai resep dan biaya struktur.
##
## Resource ini hanya wadah data; tidak menyimpan state gameplay.

## Item yang dimaksud. Wajib diisi.
@export var item: ItemDefinition
## Jumlah yang dibutuhkan / dihasilkan.
@export var count: int = 1


func _init(p_item: ItemDefinition = null, p_count: int = 1) -> void:
	item = p_item
	count = p_count


## Id item, atau &"" bila kosong.
func get_item_id() -> StringName:
	return item.id if item != null else &""


# --- Helper biaya bersama ----------------------------------------------------
## Dipakai BlueprintSlot (build_cost), RepairComponent (repair_cost), dan
## CraftingComponent (bahan non-senjata). Bahan senjata tetap ditangani
## CraftingComponent karena diambil dari slot WEAPON.

## True bila semua bahan tersedia di tas. Entri kosong diabaikan.
static func has_all(amounts: Array[ItemAmount], inventory: InventoryComponent) -> bool:
	if inventory == null:
		return false
	for amount in amounts:
		if amount == null or amount.item == null or amount.count <= 0:
			continue
		if not inventory.has_item(amount.item, amount.count):
			return false
	return true


## Konsumsi atomik: cek semuanya dulu, lalu kurangi satu per satu. Bila ada
## pengurangan yang gagal di tengah, bahan yang sudah terlanjur diambil
## dikembalikan lewat `add_or_drop()`.
static func consume_all(amounts: Array[ItemAmount], inventory: InventoryComponent) -> bool:
	if inventory == null:
		return false
	if not has_all(amounts, inventory):
		return false

	var consumed: Array[ItemAmount] = []
	for amount in amounts:
		if amount == null or amount.item == null or amount.count <= 0:
			continue
		if not inventory.remove_item(amount.item, amount.count):
			for paid in consumed:
				inventory.add_or_drop(paid.item, paid.count)
			return false
		consumed.append(amount)
	return true


## Bahan yang tidak diambil dari slot WEAPON (untuk CraftingComponent).
static func without_weapon_slot(amounts: Array[ItemAmount]) -> Array[ItemAmount]:
	var result: Array[ItemAmount] = []
	for amount in amounts:
		if amount == null or amount.item == null:
			continue
		if amount.item.equipment_slot == ItemDefinition.EquipmentSlot.WEAPON:
			continue
		result.append(amount)
	return result


## Bahan yang diambil dari slot WEAPON (maksimal satu di resep MVP).
static func weapon_slot_amounts(amounts: Array[ItemAmount]) -> Array[ItemAmount]:
	var result: Array[ItemAmount] = []
	for amount in amounts:
		if amount == null or amount.item == null:
			continue
		if amount.item.equipment_slot == ItemDefinition.EquipmentSlot.WEAPON:
			result.append(amount)
	return result
