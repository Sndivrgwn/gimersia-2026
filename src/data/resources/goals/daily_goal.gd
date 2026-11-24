class_name DailyGoal
extends Resource

## Fase 1A: satu tujuan harian untuk baris HUD.
##
## Kondisi dibaca dari state game saat ini (tas, struktur, base), jadi tidak ada
## penanda "sudah dibaca" yang bisa basi. Daftar tujuan ada di
## `src/data/configs/daily_goals.tres` (generator `tools/generate_daily_goals.gd`).

enum Kind {
	ITEM_COUNT,       ## punya `item` di tas sebanyak `count`
	TOOL_OWNED,       ## kepemilikan tool (Stone Axe / Stone Pickaxe)
	WEAPON_EQUIPPED,  ## `item` terpasang di slot WEAPON
	ARMOR_EQUIPPED,   ## `item` terpasang di slot ARMOR
	STRUCTURE_BUILT,  ## struktur camp ber-id `structure_id` sudah berdiri
	BASE_FOUNDED,     ## base sudah ditentukan (CampAnchor)
}

## Hari (1..7) tempat tujuan ini muncul.
@export_range(1, 7, 1) var day: int = 1
## Teks yang tampil di HUD (tanpa "Hari N:"), contoh "buat Kapak Batu".
@export_multiline var text: String = ""
## Cara mengevaluasi tujuan.
@export var kind: Kind = Kind.ITEM_COUNT
## Item acuan untuk ITEM_COUNT / TOOL_OWNED / WEAPON_EQUIPPED.
@export var item: ItemDefinition
## Jumlah yang dibutuhkan (ITEM_COUNT).
@export_range(1, 99, 1) var count: int = 1
## Id struktur untuk STRUCTURE_BUILT (campfire/workbench/chest/tent).
@export var structure_id: StringName = &""


func describe() -> String:
	return text


## Dievaluasi dari node hidup. Node yang tidak ada dianggap belum memenuhi.
func is_met(inventory: Node, camp: Node, anchor: Node) -> bool:
	match kind:
		Kind.ITEM_COUNT:
			if inventory == null or item == null or not inventory.has_method(&"count_item"):
				return false
			return int(inventory.count_item(item.id)) >= count
		Kind.TOOL_OWNED:
			if inventory == null or item == null or not inventory.has_method(&"has_tool"):
				return false
			return bool(inventory.has_tool(item))
		Kind.WEAPON_EQUIPPED:
			if inventory == null or item == null or not inventory.has_method(&"get_equipped"):
				return false
			return inventory.get_equipped(ItemDefinition.EquipmentSlot.WEAPON) == item
		Kind.ARMOR_EQUIPPED:
			if inventory == null or item == null or not inventory.has_method(&"get_equipped"):
				return false
			return inventory.get_equipped(ItemDefinition.EquipmentSlot.ARMOR) == item
		Kind.STRUCTURE_BUILT:
			if camp == null or not camp.has_method(&"has_built"):
				return false
			return bool(camp.has_built(structure_id))
		Kind.BASE_FOUNDED:
			if anchor == null or not anchor.has_method(&"is_founded"):
				return false
			return bool(anchor.is_founded())
	return false
