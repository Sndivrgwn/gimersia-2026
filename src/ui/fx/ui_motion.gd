extends RefCounted

## Gerak UI kecil (Mission 9 polish): bar yang mengalir, panel yang "pop".
## Semua fungsi no-op instan di headless supaya tes tetap deterministik.

const POP_IN_TIME := 0.14
const POP_TIME := 0.12
const BAR_TIME := 0.22


static func is_instant() -> bool:
	return DisplayServer.get_name() == "headless"


## Panel muncul: sedikit membesar + fade masuk.
static func pop_in(control: Control) -> void:
	if control == null:
		return
	control.visible = true
	if is_instant():
		control.scale = Vector2.ONE
		control.modulate.a = 1.0
		return
	control.pivot_offset = control.size * 0.5
	control.scale = Vector2(0.94, 0.94)
	control.modulate.a = 0.0
	var tween := control.create_tween()
	tween.set_parallel(true)
	tween.tween_property(control, "scale", Vector2.ONE, POP_IN_TIME).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(control, "modulate:a", 1.0, POP_IN_TIME)


## Kedutan kecil (slot hotbar dipilih / item berubah).
static func pop(control: Control) -> void:
	if control == null or is_instant():
		return
	control.pivot_offset = control.size * 0.5
	var tween := control.create_tween()
	tween.tween_property(control, "scale", Vector2(1.08, 1.08), POP_TIME * 0.45).set_trans(Tween.TRANS_QUAD)
	tween.tween_property(control, "scale", Vector2.ONE, POP_TIME * 0.55).set_trans(Tween.TRANS_QUAD)


## Bar bergerak ke nilai baru tanpa mengubah nilai logika (target = nilai asli).
static func tween_bar(bar: ProgressBar, target: float, duration: float = BAR_TIME) -> void:
	if bar == null:
		return
	if is_instant():
		bar.value = target
		return
	if bar.has_meta(&"ui_motion_tween"):
		var existing := bar.get_meta(&"ui_motion_tween") as Tween
		if existing != null and existing.is_valid():
			existing.kill()
	var tween := bar.create_tween()
	bar.set_meta(&"ui_motion_tween", tween)
	tween.tween_property(bar, "value", target, duration).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
