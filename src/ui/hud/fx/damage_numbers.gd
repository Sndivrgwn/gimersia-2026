extends CanvasLayer

## Mission 10 feedback: angka damage melayang di posisi target.
## Hanya membaca sinyal CombatComponent; tidak menyentuh damage/hitbox.

const MAX_LABELS := 20
const LIFE := 0.75
const RISE := 36.0
const HEAVY_DAMAGE := 8.0
const COLOR_NORMAL := Color(1.0, 0.95, 0.7, 1.0)
const COLOR_HEAVY := Color(1.0, 0.62, 0.35, 1.0)
const COLOR_KILL := Color(1.0, 0.4, 0.4, 1.0)
## Kill bukan angka: penanda netral supaya tidak pernah tampil "0".
const KILL_TEXT := "KO"

var _canvas: Control
var _entries: Array[Dictionary] = []


func _ready() -> void:
	layer = 11
	process_mode = Node.PROCESS_MODE_ALWAYS
	_canvas = Control.new()
	_canvas.name = "Numbers"
	_canvas.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_canvas.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(_canvas)


## Sambungkan ke pemain: setiap hit memberi angka di posisi target.
func bind_player(player: Node) -> void:
	if player == null:
		return
	var combat := player.get_node_or_null("CombatComponent") as CombatComponent
	if combat == null:
		return
	if not combat.hit_dealt.is_connected(_on_hit_dealt):
		combat.hit_dealt.connect(_on_hit_dealt)
	if not combat.enemy_killed.is_connected(_on_enemy_killed):
		combat.enemy_killed.connect(_on_enemy_killed)


func show_damage(world_position: Vector2, amount: float, color: Color = COLOR_NORMAL, text_override: String = "") -> void:
	if _canvas == null:
		return
	if _entries.size() >= MAX_LABELS:
		_free_entry(0)
	var label := Label.new()
	label.text = text_override if not text_override.is_empty() else "%d" % int(roundf(amount))
	var font_sz := 24 if (amount >= HEAVY_DAMAGE or not text_override.is_empty()) else 20
	label.add_theme_font_size_override("font_size", font_sz)
	label.add_theme_color_override("font_color", color)
	label.add_theme_color_override("font_outline_color", Color(0.12, 0.06, 0.03, 0.95))
	label.add_theme_constant_override("outline_size", 4)
	label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.75))
	label.add_theme_constant_override("shadow_offset_x", 1)
	label.add_theme_constant_override("shadow_offset_y", 2)
	label.position = _to_screen(world_position) - Vector2(12.0, 20.0) + Vector2(randf_range(-8.0, 8.0), 0.0)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_canvas.add_child(label)
	_entries.append({"label": label, "timer": LIFE, "origin": label.position})


## Dipakai tes: jumlah angka yang aktif dan teks terakhir.
func get_active_count() -> int:
	return _entries.size()


func get_last_text() -> String:
	if _entries.is_empty():
		return ""
	var label := _entries[-1]["label"] as Label
	return "" if label == null else label.text


func tick(delta: float) -> void:
	for index in range(_entries.size() - 1, -1, -1):
		var entry := _entries[index]
		entry["timer"] = float(entry["timer"]) - delta
		var label := entry["label"] as Label
		if label == null or float(entry["timer"]) <= 0.0:
			_free_entry(index)
			continue
		var t := 1.0 - float(entry["timer"]) / LIFE
		var origin := entry["origin"] as Vector2
		label.position = origin + Vector2(0.0, -RISE * t)
		label.modulate.a = clampf((1.0 - t) / 0.45, 0.0, 1.0)


func _process(delta: float) -> void:
	tick(delta)


func _on_hit_dealt(target: Node, damage: float) -> void:
	if target is not Node2D:
		return
	var color := COLOR_HEAVY if damage >= HEAVY_DAMAGE else COLOR_NORMAL
	show_damage((target as Node2D).global_position, damage, color)


func _on_enemy_killed(target: Node) -> void:
	if target is not Node2D:
		return
	show_damage((target as Node2D).global_position + Vector2(0.0, -18.0), 0.0, COLOR_KILL, KILL_TEXT)


func _free_entry(index: int) -> void:
	if index < 0 or index >= _entries.size():
		return
	var label := _entries[index]["label"] as Label
	if label != null:
		label.queue_free()
	_entries.remove_at(index)


func _to_screen(world_position: Vector2) -> Vector2:
	return get_viewport().get_canvas_transform() * world_position
