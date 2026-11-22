class_name Dir4
extends RefCounted

## Helper arah 4 arah untuk animasi. Murni (tanpa node) supaya mudah dites.

const DOWN := &"down"
const UP := &"up"
const LEFT := &"left"
const RIGHT := &"right"
const NAMES: Array[String] = ["down", "up", "left", "right"]
## Ambang histeresis: arah lama dipertahankan selama komponennya masih
## >= 35% komponen dominan.
const DEFAULT_HYSTERESIS := 0.35


## Arah hadap dari vektor gerak. `previous` dipertahankan selama masih wajar
## (mencegah kedip saat vektor diagonal).
static func from_vector(vector: Vector2, previous: StringName = DOWN, hysteresis: float = DEFAULT_HYSTERESIS) -> StringName:
	if vector.length_squared() < 0.000001:
		return previous if not String(previous).is_empty() else DOWN

	var ax := absf(vector.x)
	var ay := absf(vector.y)
	var dominant: StringName = RIGHT if vector.x > 0.0 else LEFT
	if ay > ax:
		dominant = DOWN if vector.y > 0.0 else UP

	if String(previous).is_empty():
		return dominant

	var previous_component := _component(vector, previous)
	if previous_component > 0.0 and previous_component >= hysteresis * maxf(ax, ay):
		return previous
	return dominant


## Arah berlawanan untuk fallback mirror ("" bila tidak ada).
static func mirrored(dir: StringName) -> StringName:
	match dir:
		LEFT:
			return RIGHT
		RIGHT:
			return LEFT
		_:
			return &""


## Komponen vektor searah `dir` (negatif berarti bergerak menjauh).
static func _component(vector: Vector2, dir: StringName) -> float:
	match dir:
		LEFT:
			return -vector.x
		RIGHT:
			return vector.x
		UP:
			return -vector.y
		DOWN:
			return vector.y
		_:
			return 0.0


## True bila nama adalah arah yang dikenal.
static func is_direction(name: String) -> bool:
	return NAMES.has(name)
