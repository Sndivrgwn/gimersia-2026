class_name ItemStack
extends RefCounted

## Satu slot inventory: definisi item + jumlahnya.
##
## InventoryComponent pemilik array slot; ItemStack hanya wadah nilai. Jangan
## mengubah `count` dari luar komponen.

var item: ItemDefinition
var count: int = 0
## Sisa tegukan/pemakaian untuk item multi-charge (0 = pakai default 1).
var charges: int = 0


func _init(p_item: ItemDefinition = null, p_count: int = 0, p_charges: int = -1) -> void:
	item = p_item
	count = p_count
	if p_charges >= 0:
		charges = p_charges
	elif p_item != null and p_item.use_charges > 1:
		charges = p_item.use_charges
	else:
		charges = 0


func is_empty() -> bool:
	return item == null or count <= 0
