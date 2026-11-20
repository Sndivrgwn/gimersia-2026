class_name RecipeDefinition
extends Resource

## Definisi satu resep crafting.
##
## Angka (bahan, waktu, stasiun) ada di `.tres` `src/data/recipes/*.tres`,
## dibuat lewat `tools/generate_recipes.gd`. Kode gameplay hanya membaca.

## Stasiun yang dibutuhkan. HAND selalu tersedia; WORKBENCH butuh Workbench
## yang sudah dibangun; CAMPFIRE butuh Campfire yang menyala.
enum Station { HAND, WORKBENCH, CAMPFIRE }

## Id stabil (English, snake_case). Sama dengan nama file `.tres`.
@export var id: StringName = &""
## Nama tampilan baris resep (mengikuti nama item hasil).
@export var display_name: String = ""
## Item hasil crafting.
@export var result: ItemDefinition
## Jumlah hasil per craft.
@export var result_count: int = 1
## Bahan yang dicek dan dikonsumsi atomik saat craft selesai.
@export var ingredients: Array[ItemAmount] = []
## Stasiun yang harus ada di dekat pemain.
@export var station: Station = Station.HAND
## Waktu craft dasar (detik nyata); dikali `StatsComponent.get_craft_time_factor()`.
@export var craft_time: float = 1.0


## Nama stasiun untuk prompt/alasan blokir.
func get_station_name() -> String:
	match station:
		Station.WORKBENCH:
			return "Workbench"
		Station.CAMPFIRE:
			return "Api Unggun"
		_:
			return "Tangan"


## Alasan blokir saat stasiun tidak tersedia.
func get_station_block_reason() -> String:
	match station:
		Station.WORKBENCH:
			return "Butuh Workbench"
		Station.CAMPFIRE:
			return "Butuh Api Unggun menyala"
		_:
			return ""
