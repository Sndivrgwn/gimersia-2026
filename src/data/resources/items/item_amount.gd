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
