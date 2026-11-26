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
	var card := PanelContainer.new()
	card.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card.add_theme_stylebox_override("panel", _toast_style())

	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", 14)
	label.add_theme_color_override("font_color", Color(1.0, 0.96, 0.88, 1.0))
	label.add_theme_color_override("font_outline_color", Color(0.14, 0.09, 0.05, 0.95))
	label.add_theme_constant_override("outline_size", 3)
	card.add_child(label)
	_box.add_child(card)
	_rows.append({"card": card, "label": label, "timer": LIFETIME})


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
			var card := row.get("card") as Control
			if card != null:
				card.modulate.a = clampf(timer / FADE_TIME, 0.0, 1.0)
			else:
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
	var node := (_rows[index].get("card") as Node) if _rows[index].has("card") else (_rows[index]["label"] as Node)
	if node != null:
		node.queue_free()
	_rows.remove_at(index)


func _toast_style() -> StyleBox:
	var tex_path := "res://assets/textures/ui/02_panel/panel_walnut_stitched.png"
	if ResourceLoader.exists(tex_path):
		var tex := load(tex_path) as Texture2D
		if tex != null:
			var box := StyleBoxTexture.new()
			box.texture = tex
			box.texture_margin_left = 20.0
			box.texture_margin_top = 20.0
			box.texture_margin_right = 20.0
			box.texture_margin_bottom = 20.0
			box.content_margin_left = 16.0
			box.content_margin_top = 10.0
			box.content_margin_right = 16.0
			box.content_margin_bottom = 10.0
			return box
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.16, 0.11, 0.08, 0.9)
	style.set_corner_radius_all(6)
	style.set_content_margin_all(10.0)
	return style


func _on_add_blocked(item: ItemDefinition, remaining: int) -> void:
	var item_name := item.display_name if item != null and not item.display_name.is_empty() else "item"
	show_toast(MSG_INVENTORY_FULL % [item_name, remaining])


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
