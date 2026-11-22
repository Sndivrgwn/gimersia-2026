extends CanvasLayer

## Mission 10 feedback: satu saluran toast untuk kegagalan yang dulu senyap
## (tas penuh, crafting batal, api unggun padam/hampir habis).
## Hanya membaca sinyal; tidak mengubah state gameplay.

const MAX_VISIBLE := 3
const LIFETIME := 2.8
const FADE_TIME := 0.3
const DEDUP_WINDOW := 0.4
const LOW_FUEL_SECONDS := 60.0

const MSG_INVENTORY_FULL := "Tas penuh: %s (sisa %d)"
const MSG_CRAFT_CANCELLED := "Crafting batal: %s"
const MSG_CRAFT_CANCELLED_PLAIN := "Crafting batal"
const MSG_FUEL_DEPLETED := "Api unggun padam — isi bahan bakar"
const MSG_FUEL_LOW := "Bahan bakar api hampir habis"

var _box: VBoxContainer
var _rows: Array[Dictionary] = []
var _last_text: String = ""
var _since_last: float = 0.0
var _player: Node


func _ready() -> void:
	layer = 17
	process_mode = Node.PROCESS_MODE_ALWAYS
	_build()
	get_tree().node_added.connect(_on_node_added)


## Sambungkan ke pemain dan semua campfire (yang bisa lahir setelah build).
func bind_player(player: Node) -> void:
	_player = player
	if player == null:
		return
	var inventory := player.get_node_or_null("InventoryComponent") as InventoryComponent
	if inventory != null and not inventory.add_blocked.is_connected(_on_add_blocked):
		inventory.add_blocked.connect(_on_add_blocked)
	var crafting := player.get_node_or_null("CraftingComponent") as CraftingComponent
	if crafting != null and not crafting.craft_cancelled.is_connected(_on_craft_cancelled):
		crafting.craft_cancelled.connect(_on_craft_cancelled)
	_watch_existing_campfires()


# --- API --------------------------------------------------------------------

func show_toast(text: String) -> void:
	if text.is_empty() or (text == _last_text and _since_last < DEDUP_WINDOW):
		return
	_last_text = text
	_since_last = 0.0
	if _rows.size() >= MAX_VISIBLE:
		_remove_row(0)
	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", 13)
	label.add_theme_color_override("font_color", Color(1.0, 0.94, 0.85, 1.0))
	label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.8))
	label.add_theme_constant_override("shadow_offset_x", 1)
	label.add_theme_constant_override("shadow_offset_y", 1)
	_box.add_child(label)
	_rows.append({"label": label, "timer": LIFETIME})


## Dipakai tes: teks toast yang sedang tampil, dari yang paling lama.
func get_visible_texts() -> Array[String]:
	var texts: Array[String] = []
	for row in _rows:
		var label := row["label"] as Label
		if label != null and label.visible:
			texts.append(label.text)
	return texts


func tick(delta: float) -> void:
	_since_last += delta
	for index in range(_rows.size() - 1, -1, -1):
		var row := _rows[index]
		row["timer"] = float(row["timer"]) - delta
		var label := row["label"] as Label
		if label == null:
			_rows.remove_at(index)
			continue
		var timer := float(row["timer"])
		if timer <= 0.0:
			_remove_row(index)
		elif timer < FADE_TIME:
			label.modulate.a = clampf(timer / FADE_TIME, 0.0, 1.0)


# --- Internal ---------------------------------------------------------------

func _process(delta: float) -> void:
	tick(delta)


func _build() -> void:
	_box = VBoxContainer.new()
	_box.name = "Toasts"
	_box.alignment = BoxContainer.ALIGNMENT_END
	_box.add_theme_constant_override("separation", 4)
	_box.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_LEFT, Control.PRESET_MODE_MINSIZE, 24)
	_box.grow_vertical = Control.GROW_DIRECTION_BEGIN
	_box.custom_minimum_size = Vector2(360, 0)
	add_child(_box)


func _remove_row(index: int) -> void:
	if index < 0 or index >= _rows.size():
		return
	var label := _rows[index]["label"] as Label
	if label != null:
		label.queue_free()
	_rows.remove_at(index)


func _on_add_blocked(item: ItemDefinition, remaining: int) -> void:
	var name := item.display_name if item != null and not item.display_name.is_empty() else "item"
	show_toast(MSG_INVENTORY_FULL % [name, remaining])


func _on_craft_cancelled(_recipe: RecipeDefinition, reason: String) -> void:
	show_toast(MSG_CRAFT_CANCELLED % reason if not reason.is_empty() else MSG_CRAFT_CANCELLED_PLAIN)


func _on_node_added(node: Node) -> void:
	if node != null and node.has_signal(&"fuel_depleted"):
		_watch_campfire(node)


func _watch_existing_campfires() -> void:
	var scene := get_tree().current_scene
	if scene == null:
		return
	for node in scene.find_children("*", "", true, false):
		if node.has_signal(&"fuel_depleted"):
			_watch_campfire(node)


func _watch_campfire(campfire: Node) -> void:
	if campfire == null or campfire.has_meta(&"toast_watched"):
		return
	campfire.set_meta(&"toast_watched", true)
	campfire.set_meta(&"toast_low_fuel", false)
	if not campfire.is_connected(&"fuel_depleted", _on_fuel_depleted):
		campfire.connect(&"fuel_depleted", _on_fuel_depleted)
	if not campfire.is_connected(&"fuel_changed", _on_fuel_changed.bind(campfire)):
		campfire.connect(&"fuel_changed", _on_fuel_changed.bind(campfire))


func _on_fuel_depleted() -> void:
	show_toast(MSG_FUEL_DEPLETED)


func _on_fuel_changed(seconds: float, campfire: Node) -> void:
	if campfire == null:
		return
	if seconds > LOW_FUEL_SECONDS * 2.0:
		campfire.set_meta(&"toast_low_fuel", false)
		return
	if seconds <= 0.0 or seconds > LOW_FUEL_SECONDS:
		return
	if bool(campfire.get_meta(&"toast_low_fuel", false)):
		return
	campfire.set_meta(&"toast_low_fuel", true)
	show_toast(MSG_FUEL_LOW)
