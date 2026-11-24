class_name ItemCatalog
extends RefCounted

## Akses tetap ke definisi item.
##
## Definisi item adalah Resource `.tres` di `src/data/items/`; file ini hanya
## mengumpulkannya supaya kode lain dan tes tidak menulis path berulang.
## Kalau menambah item baru: buat `.tres`-nya, lalu tambahkan const di sini.

const WOOD: ItemDefinition = preload("res://src/data/items/wood.tres")
const STONE: ItemDefinition = preload("res://src/data/items/stone.tres")
const FIBER: ItemDefinition = preload("res://src/data/items/fiber.tres")
const BAMBOO: ItemDefinition = preload("res://src/data/items/bamboo.tres")
const BONE: ItemDefinition = preload("res://src/data/items/bone.tres")
const HIDE: ItemDefinition = preload("res://src/data/items/hide.tres")

const BERRY: ItemDefinition = preload("res://src/data/items/berry.tres")
const COCONUT: ItemDefinition = preload("res://src/data/items/coconut.tres")
const RAW_MEAT: ItemDefinition = preload("res://src/data/items/raw_meat.tres")
const COOKED_MEAT: ItemDefinition = preload("res://src/data/items/cooked_meat.tres")
const BONE_BROTH: ItemDefinition = preload("res://src/data/items/bone_broth.tres")
const BOILED_WATER: ItemDefinition = preload("res://src/data/items/boiled_water.tres")
const HERBAL_BANDAGE: ItemDefinition = preload("res://src/data/items/herbal_bandage.tres")

const COCKPIT_NOTES: ItemDefinition = preload("res://src/data/items/cockpit_notes.tres")

const WATERSKIN: ItemDefinition = preload("res://src/data/items/waterskin.tres")
const WATERSKIN_EMPTY: ItemDefinition = preload("res://src/data/items/waterskin_empty.tres")
const SIGNAL_FLARE: ItemDefinition = preload("res://src/data/items/signal_flare.tres")
const TORCH: ItemDefinition = preload("res://src/data/items/torch.tres")

const WOODEN_SPEAR: ItemDefinition = preload("res://src/data/items/wooden_spear.tres")
const STONE_SPEAR: ItemDefinition = preload("res://src/data/items/stone_spear.tres")
const BONE_SPEAR: ItemDefinition = preload("res://src/data/items/bone_spear.tres")

const STONE_AXE: ItemDefinition = preload("res://src/data/items/stone_axe.tres")
const STONE_PICKAXE: ItemDefinition = preload("res://src/data/items/stone_pickaxe.tres")

const LEATHER_VEST: ItemDefinition = preload("res://src/data/items/leather_vest.tres")

const ALL: Array[ItemDefinition] = [
	WOOD,
	STONE,
	FIBER,
	BAMBOO,
	BONE,
	HIDE,
	BERRY,
	COCONUT,
	RAW_MEAT,
	COOKED_MEAT,
	BONE_BROTH,
	BOILED_WATER,
	HERBAL_BANDAGE,
	COCKPIT_NOTES,
	WATERSKIN,
	WATERSKIN_EMPTY,
	SIGNAL_FLARE,
	TORCH,
	WOODEN_SPEAR,
	STONE_SPEAR,
	BONE_SPEAR,
	STONE_AXE,
	STONE_PICKAXE,
	LEATHER_VEST,
]


static func get_by_id(id: StringName) -> ItemDefinition:
	for item in ALL:
		if item != null and item.id == id:
			return item
	return null
