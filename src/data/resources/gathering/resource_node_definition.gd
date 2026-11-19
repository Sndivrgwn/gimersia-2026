class_name ResourceNodeDefinition
extends Resource

## Definisi satu node resource: tool, waktu gather, yield, biaya Fatigue,
## dan aturan respawn. Angka tuning ada di `src/data/gathering/*.tres`.

## Tool yang wajib dimiliki. AXE = Stone Axe, PICKAXE = Stone Pickaxe.
enum RequiredTool { NONE, AXE, PICKAXE }
## Kapan node muncul lagi setelah habis.
enum RespawnRule { DAILY, EVERY_OTHER_DAY, NEVER }

## Id stabil (English, snake_case) untuk layout dan tes.
@export var id: StringName = &""
## Nama tampilan di prompt interaksi.
@export var display_name: String = ""
## Item yang didapat saat panen.
@export var item: ItemDefinition
## Jumlah minimum hasil per panen (inklusif).
@export var yield_min: int = 1
## Jumlah maksimum hasil per panen (inklusif).
@export var yield_max: int = 1
## Tool wajib; NONE berarti bisa dengan tangan.
@export var required_tool: RequiredTool = RequiredTool.NONE
## Lama hold dasar (detik nyata); dikali `StatsComponent.get_gather_time_factor()`.
@export var gather_time: float = 1.0
## Fatigue yang dibayar sekali saat panen selesai.
@export var fatigue_cost: float = 2.0
## Aturan respawn setelah habis.
@export var respawn_rule: RespawnRule = RespawnRule.DAILY


## Jumlah hasil panen. `rng` diinjeksi supaya tes/layout deterministik.
func roll_yield(rng: RandomNumberGenerator) -> int:
	var low := maxi(mini(yield_min, yield_max), 0)
	var high := maxi(maxi(yield_min, yield_max), 0)
	if high <= low:
		return low
	return rng.randi_range(low, high)


## Id tool yang dibutuhkan; &"" bila tanpa tool.
func get_required_tool_id() -> StringName:
	match required_tool:
		RequiredTool.AXE:
			return &"stone_axe"
		RequiredTool.PICKAXE:
			return &"stone_pickaxe"
		_:
			return &""


## Alasan blokir saat tool belum dimiliki.
func get_block_reason() -> String:
	match required_tool:
		RequiredTool.AXE:
			return "Butuh Kapak Batu"
		RequiredTool.PICKAXE:
			return "Butuh Beliung Batu"
		_:
			return ""
