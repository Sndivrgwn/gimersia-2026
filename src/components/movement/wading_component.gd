class_name WadingComponent
extends Node

## Mission 9 fase 4: mendeteksi pemain di zona sungai lalu memberi tahu Player.
## Komponen ini hanya MEMBACA posisi pemain; semua pengali kecepatan dan blokir
## sprint tetap dihitung Player dari `wading_config` (satu sumber angka).
## Anak dari Player di player.tscn, jadi ikut semua scene yang memakai pemain.

@export var player: Player

var _in_water: bool = false


func _ready() -> void:
	if player == null:
		player = get_parent() as Player


func _physics_process(_delta: float) -> void:
	tick()


## Satu langkah deteksi; dipanggil _physics_process dan tes.
func tick() -> void:
	if player == null or not is_instance_valid(player):
		return
	_in_water = IslandZones.zone_at(player.global_position) == IslandZones.Zone.RIVER
	player.set_wading(_in_water)


func is_in_water() -> bool:
	return _in_water
