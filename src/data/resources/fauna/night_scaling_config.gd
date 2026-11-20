class_name NightScalingConfig
extends Resource

## Tabel peningkatan malam 1..7 (spesifikasi §7.3).

@export var max_enemies: Array[int] = [3, 4, 5, 6, 7, 9, 12]
@export var spawn_interval: Array[float] = [45.0, 40.0, 35.0, 30.0, 25.0, 20.0, 15.0]
@export var hp_damage_multiplier: Array[float] = [1.0, 1.0, 1.1, 1.2, 1.3, 1.4, 1.5]


func _index(night: int) -> int:
	return clampi(night, 1, max_enemies.size()) - 1


func get_max_enemies(night: int) -> int:
	return max_enemies[_index(night)]


func get_spawn_interval(night: int) -> float:
	return spawn_interval[_index(night)]


func get_hp_damage_multiplier(night: int) -> float:
	return hp_damage_multiplier[_index(night)]
