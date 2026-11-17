class_name StatModifier
extends RefCounted

## Satu baris modifier milik sebuah source_id.
## FLAT menambah nilai langsung; PERCENT menambah/mengurangi faktor pecahan
## (0.10 = +10%, -0.15 = -15%). Beberapa modifier dengan source_id yang sama
## dianggap satu paket dan dihapus bersama lewat StatsComponent.remove_modifier().

enum Kind { FLAT, PERCENT }

var source_id: StringName
var stat: StringName
var kind: int
var value: float


func _init(p_source_id: StringName, p_stat: StringName, p_kind: int, p_value: float) -> void:
	source_id = p_source_id
	stat = p_stat
	kind = p_kind
	value = p_value
