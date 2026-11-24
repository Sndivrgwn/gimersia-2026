class_name CraftingRow
extends PanelContainer

## Satu kartu resep di tab Crafting dan panel stasiun.
##
## Kartu menampilkan ikon hasil (dummy huruf), nama, deskripsi, stasiun/waktu,
## bahan dengan badge have/need, tombol Buat, dan status di bawah tombol.
## Semua angka dibaca dari CraftingComponent/InventoryComponent saat refresh().
## Baris terkunci (stasiun belum ada / api dingin) tetap tampil, dengan alasan
## di bawah tombol.

<<<<<<< Updated upstream
const MISSING_COLOR := Color(1.0, 0.5, 0.45, 1.0)
const NORMAL_COLOR := Color(0.88, 0.93, 0.88, 1.0)
const LOCKED_ALPHA := 0.45
const REASON_COLOR := Color(1.0, 0.62, 0.5, 1.0)
## Fase 4B: baris yang bisa di-craft sekarang diberi latar hijau tipis.
const READY_BG := Color(0.16, 0.26, 0.18, 0.95)
const READY_BORDER := Color(0.45, 0.85, 0.5, 0.8)
const IDLE_BG := Color(0.1, 0.12, 0.14, 0.55)
const IDLE_BORDER := Color(0.35, 0.4, 0.35, 0.25)
const DEFAULT_BATCH_MAX := 5
=======
const CARD_TEXTURE := "res://assets/textures/ui/inventory/inventory_slot.png"
const LOCKED_ALPHA := 0.82

const TITLE_COLOR := Color(0.22, 0.14, 0.09, 1.0)
const DESC_COLOR := Color(0.43, 0.34, 0.25, 1.0)
const META_COLOR := Color(0.48, 0.38, 0.28, 1.0)
const STATUS_COLOR := Color(0.45, 0.32, 0.2, 1.0)
const BADGE_TEXT := Color(0.2, 0.14, 0.1, 1.0)
const BADGE_OK := Color(0.55, 0.73, 0.45, 1.0)
const BADGE_MISSING := Color(0.88, 0.52, 0.43, 1.0)
const BADGE_BORDER := Color(0.28, 0.2, 0.13, 1.0)
const RESULT_ICON_BG := Color(0.9, 0.82, 0.68, 1.0)
const INGREDIENT_ICON_BG := Color(0.82, 0.86, 0.68, 1.0)
const ICON_BORDER := Color(0.3, 0.21, 0.14, 1.0)
const ICON_TEXT := Color(0.25, 0.17, 0.11, 1.0)

const BUTTON_BG := Color(0.36, 0.23, 0.16, 1.0)
const BUTTON_HOVER := Color(0.45, 0.3, 0.21, 1.0)
const BUTTON_PRESSED := Color(0.28, 0.17, 0.11, 1.0)
const BUTTON_DISABLED := Color(0.72, 0.66, 0.58, 1.0)
const BUTTON_BORDER := Color(0.2, 0.12, 0.08, 1.0)
const BUTTON_DISABLED_BORDER := Color(0.45, 0.37, 0.29, 1.0)
const BUTTON_TEXT := Color(0.97, 0.93, 0.86, 1.0)
const BUTTON_DISABLED_TEXT := Color(0.48, 0.4, 0.33, 1.0)
>>>>>>> Stashed changes

var recipe: RecipeDefinition
var crafting: CraftingComponent
var inventory: InventoryComponent
var locked: bool = false
## Alasan khusus saat terkunci (mis. api unggun masih dingin).
var locked_reason: String = ""
## Mission 10: stasiun pemanggil (null = tab tas).
var station: Node

var _name_label: Label
var _desc_label: Label
var _time_label: Label
var _reason_label: Label
var _craft_button: Button
var _count_input: SpinBox
var _ingredient_labels: Array[Label] = []
var _ingredient_badges: Array[PanelContainer] = []
var _missing_flags: Array[bool] = []
var _block_reason: String = ""
var _badge_ok: StyleBoxFlat
var _badge_missing: StyleBoxFlat


func setup(
	p_recipe: RecipeDefinition,
	p_crafting: CraftingComponent,
	p_inventory: InventoryComponent,
	p_locked: bool
) -> void:
	recipe = p_recipe
	crafting = p_crafting
	inventory = p_inventory
	locked = p_locked
	_build()
	refresh()


# --- Read API (dipakai panel dan tes) ---------------------------------------

func get_recipe() -> RecipeDefinition:
	return recipe


func is_locked() -> bool:
	return locked


## Ganti alasan terkunci; dipakai panel stasiun untuk status "Api dingin".
func set_locked_reason(reason: String) -> void:
	locked_reason = reason
	refresh()


func get_block_reason() -> String:
	return _block_reason


func is_craft_disabled() -> bool:
	return _craft_button == null or _craft_button.disabled


## Fase 4B: jumlah craft yang dipilih di baris (1..craft_batch_max).
func get_batch_quantity() -> int:
	if _count_input == null:
		return 1
	return maxi(int(_count_input.value), 1)


func set_batch_quantity(value: int) -> void:
	if _count_input == null:
		return
	_count_input.value = clampi(value, 1, int(_count_input.max_value))


## True bila baris ditandai siap craft (latar hijau).
func is_highlighted() -> bool:
	var style := get_theme_stylebox(&"panel")
	var flat := style as StyleBoxFlat
	return flat != null and flat.bg_color.is_equal_approx(READY_BG)


func get_name_text() -> String:
	return "" if _name_label == null else _name_label.text


func get_ingredient_count() -> int:
	return _ingredient_labels.size()


func get_ingredient_text(index: int) -> String:
	if index < 0 or index >= _ingredient_labels.size():
		return ""
	return _ingredient_labels[index].text


func is_ingredient_missing(index: int) -> bool:
	if index < 0 or index >= _missing_flags.size():
		return false
	return _missing_flags[index]


## Simulasi klik tombol Buat (dipakai tes tanpa mouse).
func press_craft() -> void:
	if _craft_button == null or _craft_button.disabled:
		return
	_craft_button.pressed.emit()


# --- Refresh ----------------------------------------------------------------

func refresh() -> void:
	if recipe == null or _name_label == null:
		return

	_name_label.text = recipe.display_name
	_desc_label.text = "" if recipe.result == null else recipe.result.description
	_time_label.text = "%s / %d DETIK" % [
		recipe.get_station_name().to_upper(), int(round(recipe.craft_time)),
	]

	if locked:
		_block_reason = locked_reason if not locked_reason.is_empty() else recipe.get_station_block_reason()
	else:
		_block_reason = "" if crafting == null else crafting.get_block_reason(recipe)

	_update_ingredients()

	var busy := crafting != null and crafting.is_crafting()
	_craft_button.disabled = locked or not _block_reason.is_empty() or busy
	_craft_button.tooltip_text = _block_reason

	var status := _status_text()
	_reason_label.text = status
	_reason_label.visible = not status.is_empty()
	modulate = Color(1.0, 1.0, 1.0, LOCKED_ALPHA) if locked else Color(1.0, 1.0, 1.0, 1.0)
	_apply_highlight(not locked and _block_reason.is_empty() and not busy)


func _status_text() -> String:
	if locked:
		return locked_reason if not locked_reason.is_empty() else "Harus di meja untuk dibuat"
	if _block_reason == CraftingComponent.REASON_NO_INGREDIENTS:
		return _missing_status_text()
	return _block_reason


func _missing_status_text() -> String:
	for index in recipe.ingredients.size():
		var amount := recipe.ingredients[index]
		if amount == null or amount.item == null:
			continue
		var have := _available_count(amount.item)
		if have < amount.count:
			return "Kumpulkan %d %s" % [amount.count - have, amount.item.display_name]
	return "Bahan kurang"


func _available_count(item: ItemDefinition) -> int:
	if crafting != null:
		return crafting.count_available(item)
	if inventory != null:
		return inventory.count_of(item)
	return 0


func _update_ingredients() -> void:
	_missing_flags.clear()
	for index in _ingredient_labels.size():
		var amount := recipe.ingredients[index]
		var label := _ingredient_labels[index]
		var badge := _ingredient_badges[index]
		if amount == null or amount.item == null:
			label.text = ""
			_missing_flags.append(false)
			continue

		var have := _available_count(amount.item)
		var missing := have < amount.count
		label.text = "%d/%d" % [have, amount.count]
		badge.add_theme_stylebox_override("panel", _badge_missing if missing else _badge_ok)
		badge.tooltip_text = "%s: %d/%d" % [amount.item.display_name, have, amount.count]
		_missing_flags.append(missing)


# --- Build ------------------------------------------------------------------

func _build() -> void:
	var card := StyleBoxTexture.new()
	card.texture = load(CARD_TEXTURE)
	card.texture_margin_left = 18.0
	card.texture_margin_top = 18.0
	card.texture_margin_right = 18.0
	card.texture_margin_bottom = 18.0
	card.content_margin_left = 18.0
	card.content_margin_top = 14.0
	card.content_margin_right = 18.0
	card.content_margin_bottom = 14.0
	add_theme_stylebox_override("panel", card)
	custom_minimum_size = Vector2(0.0, 128.0)
	size_flags_horizontal = Control.SIZE_EXPAND_FILL
	mouse_filter = Control.MOUSE_FILTER_PASS
	texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR

	var row := HBoxContainer.new()
	row.name = "Row"
	row.add_theme_constant_override("separation", 12)
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(row)

	var result_icon := _make_letter_icon(recipe.result, 48, 20, RESULT_ICON_BG)
	result_icon.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(result_icon)

	var info := VBoxContainer.new()
	info.name = "Info"
	info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	info.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	info.add_theme_constant_override("separation", 2)
	info.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(info)

	_name_label = _make_label("", 16, TITLE_COLOR)
	_name_label.name = "Name"
	_name_label.autowrap_mode = TextServer.AUTOWRAP_OFF
	_name_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	_name_label.clip_text = true
	info.add_child(_name_label)

	_desc_label = _make_label("", 10, DESC_COLOR)
	_desc_label.name = "Description"
	_desc_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_desc_label.max_lines_visible = 2
	info.add_child(_desc_label)

	_time_label = _make_label("", 9, META_COLOR)
	_time_label.name = "Meta"
	info.add_child(_time_label)

	var ingredients := HBoxContainer.new()
	ingredients.name = "Ingredients"
	ingredients.add_theme_constant_override("separation", 6)
	ingredients.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	ingredients.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(ingredients)

	_ingredient_labels.clear()
	_ingredient_badges.clear()
	_badge_ok = _badge_style(BADGE_OK)
	_badge_missing = _badge_style(BADGE_MISSING)
	for amount in recipe.ingredients:
		var col := VBoxContainer.new()
		col.add_theme_constant_override("separation", 2)
		col.mouse_filter = Control.MOUSE_FILTER_IGNORE
		ingredients.add_child(col)

		var icon := _make_letter_icon(amount.item if amount != null else null, 30, 12, INGREDIENT_ICON_BG)
		icon.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		col.add_child(icon)

		var badge := PanelContainer.new()
		badge.custom_minimum_size = Vector2(38.0, 17.0)
		badge.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		badge.mouse_filter = Control.MOUSE_FILTER_PASS
		badge.add_theme_stylebox_override("panel", _badge_ok)
		var label := _make_label("", 9, BADGE_TEXT)
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		badge.add_child(label)
		col.add_child(badge)
		_ingredient_labels.append(label)
		_ingredient_badges.append(badge)

	var action := VBoxContainer.new()
	action.name = "Action"
	action.custom_minimum_size = Vector2(150.0, 0.0)
	action.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	action.add_theme_constant_override("separation", 4)
	action.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(action)

	_count_input = SpinBox.new()
	_count_input.name = "Count"
	_count_input.min_value = 1
	_count_input.max_value = DEFAULT_BATCH_MAX
	_count_input.step = 1
	_count_input.value = 1
	_count_input.tooltip_text = "Jumlah craft"
	_count_input.custom_minimum_size = Vector2(62.0, 26.0)
	if crafting != null:
		_count_input.max_value = maxi(crafting.get_station_config().craft_batch_max, 1)
	row.add_child(_count_input)

	_craft_button = Button.new()
	_craft_button.text = "Buat"
	_craft_button.custom_minimum_size = Vector2(130.0, 30.0)
	_craft_button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	_craft_button.focus_mode = Control.FOCUS_NONE
	_craft_button.mouse_filter = Control.MOUSE_FILTER_STOP
	_craft_button.add_theme_font_size_override("font_size", 10)
	_craft_button.add_theme_stylebox_override("normal", _button_style(BUTTON_BG, BUTTON_BORDER))
	_craft_button.add_theme_stylebox_override("hover", _button_style(BUTTON_HOVER, BUTTON_BORDER))
	_craft_button.add_theme_stylebox_override("pressed", _button_style(BUTTON_PRESSED, BUTTON_BORDER))
	_craft_button.add_theme_stylebox_override("disabled", _button_style(BUTTON_DISABLED, BUTTON_DISABLED_BORDER))
	_craft_button.add_theme_color_override("font_color", BUTTON_TEXT)
	_craft_button.add_theme_color_override("font_hover_color", BUTTON_TEXT)
	_craft_button.add_theme_color_override("font_pressed_color", BUTTON_TEXT)
	_craft_button.add_theme_color_override("font_disabled_color", BUTTON_DISABLED_TEXT)
	_craft_button.pressed.connect(_on_craft_pressed)
	action.add_child(_craft_button)

	_reason_label = _make_label("", 9, STATUS_COLOR)
	_reason_label.name = "Status"
	_reason_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_reason_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_reason_label.custom_minimum_size = Vector2(150.0, 0.0)
	action.add_child(_reason_label)


func _make_label(text: String, font_size: int, color: Color) -> Label:
	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return label


func _make_letter_icon(item: ItemDefinition, size: int, font_size: int, bg: Color) -> Control:
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(size, size)
	panel.mouse_filter = Control.MOUSE_FILTER_PASS
	var style := StyleBoxFlat.new()
	style.bg_color = bg
	style.border_color = ICON_BORDER
	style.set_border_width_all(2)
	style.set_corner_radius_all(int(size / 2.0))
	panel.add_theme_stylebox_override("panel", style)

	var label := Label.new()
	label.text = "?" if item == null else item.display_name.left(1).to_upper()
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", ICON_TEXT)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_child(label)

	if item != null:
		panel.tooltip_text = item.display_name
	return panel


func _badge_style(bg: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = bg
	style.border_color = BADGE_BORDER
	style.set_border_width_all(1)
	style.set_corner_radius_all(5)
	style.content_margin_left = 4.0
	style.content_margin_top = 1.0
	style.content_margin_right = 4.0
	style.content_margin_bottom = 1.0
	return style


func _button_style(bg: Color, border: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = bg
	style.border_color = border
	style.set_border_width_all(1)
	style.set_corner_radius_all(8)
	style.content_margin_left = 10.0
	style.content_margin_top = 4.0
	style.content_margin_right = 10.0
	style.content_margin_bottom = 4.0
	return style


func _on_craft_pressed() -> void:
	if crafting == null or recipe == null:
		return
	crafting.start_craft(recipe, station, get_batch_quantity())


func _apply_highlight(ready: bool) -> void:
	var style := StyleBoxFlat.new()
	style.bg_color = READY_BG if ready else IDLE_BG
	style.border_color = READY_BORDER if ready else IDLE_BORDER
	style.set_border_width_all(1)
	style.set_corner_radius_all(4)
	style.content_margin_left = 8.0
	style.content_margin_right = 8.0
	style.content_margin_top = 4.0
	style.content_margin_bottom = 4.0
	add_theme_stylebox_override(&"panel", style)
