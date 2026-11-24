class_name HealthRegenConfig
extends Resource

## Mission 9: regen HP pasif yang diskalakan oleh Hunger dan Thirst.
##
## `regen_hunger_curve`/`regen_thirst_curve` adalah titik (nilai need, multiplier)
## yang diinterpolasi linear. Multiplier akhir = min dari keduanya, jadi need yang
## paling buruk menentukan. Tier ZERO mematikan regen sepenuhnya (kerusakan
## kelaparan/kehausan menang).

@export_group("Regen")
## HP per detik game saat Hunger dan Thirst penuh.
@export var base_regen_per_second: float = 0.5
## Jeda setelah damage terakhir sebelum regen boleh jalan (detik game).
@export var out_of_combat_delay: float = 6.0

@export_group("Kurva")
## (nilai need, multiplier regen).
@export var regen_hunger_curve: PackedVector2Array = PackedVector2Array([
	Vector2(0.0, 0.0),
	Vector2(30.0, 0.3),
	Vector2(60.0, 0.75),
	Vector2(100.0, 1.0),
])
@export var regen_thirst_curve: PackedVector2Array = PackedVector2Array([
	Vector2(0.0, 0.0),
	Vector2(30.0, 0.3),
	Vector2(60.0, 0.75),
	Vector2(100.0, 1.0),
])


## Interpolasi linear murni; di luar ujung kurva dipakai nilai ujung.
static func sample_curve(points: PackedVector2Array, x: float) -> float:
	if points.is_empty():
		return 1.0
	if x <= points[0].x:
		return points[0].y
	for index in range(points.size() - 1):
		var a := points[index]
		var b := points[index + 1]
		if x <= b.x:
			var span := b.x - a.x
			if span <= 0.0:
				return b.y
			return lerpf(a.y, b.y, (x - a.x) / span)
	return points[points.size() - 1].y


## Multiplier akhir = min(kurva hunger, kurva thirst).
func get_multiplier(hunger: float, thirst: float) -> float:
	return minf(
		sample_curve(regen_hunger_curve, hunger),
		sample_curve(regen_thirst_curve, thirst)
	)
