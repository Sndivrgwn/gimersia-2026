class_name ItemDefinition
extends Resource

## Definisi satu item (nama, kategori, stack, efek, stat peralatan).
##
## Definisi item adalah `.tres` di `src/data/items/<id>.tres` dan diakses lewat
## `ItemCatalog`. Kode gameplay tidak boleh menulis angka efek langsung dan
## tidak boleh menduplikasi definisi item.

## Kategori gameplay; menentukan apakah item bisa dipakai dan ke slot mana ia
## boleh dipasang.
enum Category { RESOURCE, CONSUMABLE, WEAPON, TOOL, ARMOR, SPECIAL }

## Slot peralatan permanen. TOOL dipakai sebagai kepemilikan bersama
## (Stone Axe + Stone Pickaxe), bukan satu item per slot.
enum EquipmentSlot { NONE, WEAPON, TOOL, ARMOR }

## Id stabil untuk inventory, resep, dan penyimpanan (English, snake_case).
@export var id: StringName = &""
## Nama yang tampil di HUD (Indonesian).
@export var display_name: String = ""
## Deskripsi singkat untuk tooltip/bag UI (bag UI belum ada).
@export_multiline var description: String = ""
## Kategori item.
@export var category: Category = Category.RESOURCE
## Maksimum tumpukan per slot. Spesifikasi: 20 (Waterskin/Flare = 1).
@export var max_stack: int = 20
## Ikon opsional; HUD jatuh ke display_name bila null.
@export var icon: Texture2D
## Efek saat dipakai. Null berarti item tidak berefek.
@export var consume_effect: ItemEffect
## Varian item yang menggantikan item ini setelah dipakai (mis. Waterskin
## penuh -> `waterskin_empty.tres`). Null berarti item habis seperti biasa.
## Berlaku untuk stack berisi satu item (max_stack 1).
@export var use_result: ItemDefinition
## Jumlah pemakaian per item sebelum habis/berubah ke `use_result` (mis. Waterskin = 3).
@export var use_charges: int = 1
## Slot peralatan bila item ini bisa dipasang.
@export var equipment_slot: EquipmentSlot = EquipmentSlot.NONE
## Damage senjata (dipakai combat nanti; belum di-wire).
@export var weapon_damage: float = 0.0
## Jangkauan senjata dalam piksel.
@export var weapon_range: float = 0.0
## Pengurangan damage armor (0.20 = -20%).
@export var armor_damage_reduction: float = 0.0
## Bonus max HP armor.
@export var armor_max_hp_bonus: float = 0.0


func is_consumable() -> bool:
	return category == Category.CONSUMABLE and consume_effect != null


## Ikon untuk UI: field icon bila diisi, kalau tidak art dari
## assets/icons/items/<id>.png. Null berarti UI memakai teks saja.
func get_icon() -> Texture2D:
	if icon != null:
		return icon
	return Assets.item_icon(id)
