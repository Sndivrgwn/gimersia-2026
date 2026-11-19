class_name ItemStack
extends RefCounted

## Satu slot inventory: definisi item + jumlahnya.
##
## InventoryComponent pemilik array slot; ItemStack hanya wadah nilai. Jangan
## mengubah `count` dari luar komponen.

var item: ItemDefinition
var count: int = 0


func _init(p_item: ItemDefinition = null, p_count: int = 0) -> void:
	item = p_item
	count = p_count


func is_empty() -> bool:
	return item == null or count <= 0
