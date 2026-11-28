class_name CraftingRow
extends PanelContainer

## Satu kartu resep di tab Crafting dan panel stasiun.
##
## Kartu menampilkan ikon hasil (dummy huruf), nama, deskripsi, stasiun/waktu,
## bahan dengan badge have/need, tombol Buat, dan status di bawah tombol.
## Semua angka dibaca dari CraftingComponent/InventoryComponent saat refresh().
## Baris terkunci (stasiun belum ada / api dingin) tetap tampil, dengan alasan
## di bawah tombol.

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
const CARD_TEXTURE := "res://assets/textures/ui/02_panel/panel_cream_stitched.png"
const PILL_GOOD_TEXTURE := "res://assets/textures/ui/09_extra/pill_good.svg"
const PILL_BAD_TEXTURE := "res://assets/textures/ui/09_extra/pill_bad.svg"
const BTN_NORMAL_STYLE := preload("res://src/ui/panels/inventory/styles/button_normal.tres")
const BTN_HOVER_STYLE := preload("res://src/ui/panels/inventory/styles/button_hover.tres")
const BTN_PRESSED_STYLE := preload("res://src/ui/panels/inventory/styles/button_pressed.tres")
const BTN_DISABLED_STYLE := preload("res://src/ui/panels/inventory/styles/button_disabled.tres")
const FONT_BOLD := preload("res://assets/fonts/nunito/Nunito-Bold.ttf")
const FONT_MEDIUM := preload("res://assets/fonts/nunito/Nunito-Medium.ttf")
const TOOLTIP_SCENE: PackedScene = preload("res://src/ui/panels/inventory/item_tooltip.tscn")

const TITLE_COLOR := Color(0.243137, 0.152941, 0.101961, 1.0)
const DESC_COLOR := Color(0.42, 0.30, 0.21, 1.0)
const META_COLOR := Color(0.42, 0.30, 0.21, 1.0)
const STATUS_COLOR := Color(0.45, 0.30, 0.20, 1.0)
const BADGE_TEXT := Color(0.243137, 0.152941, 0.101961, 1.0)
const BADGE_OK := Color(0.55, 0.73, 0.45, 1.0)
const BADGE_MISSING := Color(0.88, 0.52, 0.43, 1.0)
const BADGE_BORDER := Color(0.28, 0.2, 0.13, 1.0)
const RESULT_ICON_BG := Color(0.95, 0.89, 0.79, 1.0)
const INGREDIENT_ICON_BG := Color(0.95, 0.89, 0.79, 1.0)
const ICON_BORDER := Color(0.243137, 0.152941, 0.101961, 1.0)
const ICON_TEXT := Color(0.243137, 0.152941, 0.101961, 1.0)

const BUTTON_BG := Color(0.36, 0.23, 0.16, 1.0)
const BUTTON_HOVER := Color(0.45, 0.3, 0.21, 1.0)
const BUTTON_PRESSED := Color(0.28, 0.17, 0.11, 1.0)
const BUTTON_DISABLED := Color(0.72, 0.66, 0.58, 1.0)
const BUTTON_BORDER := Color(0.2, 0.12, 0.08, 1.0)
const BUTTON_DISABLED_BORDER := Color(0.45, 0.37, 0.29, 1.0)
const BUTTON_TEXT := Color(0.243137, 0.152941, 0.101961, 1.0)
const BUTTON_DISABLED_TEXT := Color(0.243137, 0.152941, 0.101961, 0.85)

var recipe: RecipeDefinition
var crafting: CraftingComponent
var inventory: InventoryComponent
var locked: bool = false
## Alasan khusus saat terkunci (mis. api unggun masih dingin).
var locked_reason: String = ""
## Mission 10: stasiun pemanggil (null = tab tas).
var station: Node

var _name_label: Label
var _time_label: Label
var _reason_label: Label
var _craft_button: Button
var _count_input: SpinBox
var _ingredient_labels: Array[Label] = []
var _ingredient_badges: Array[PanelContainer] = []
var _missing_flags: Array[bool] = []
var _block_reason: String = ""
var _badge_ok: StyleBox
var _badge_missing: StyleBox


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
	tooltip_text = "" if recipe.result == null else BagSlot.describe_item(recipe.result)
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

	var status := _status_text(busy)
	_reason_label.text = status
	_reason_label.visible = true
	var ready := not locked and _block_reason.is_empty() and not busy
	_reason_label.add_theme_color_override(
		"font_color",
		Color(0.28, 0.45, 0.22, 1.0) if ready else Color(0.62, 0.24, 0.18, 1.0)
	)
	modulate = Color(1.0, 1.0, 1.0, LOCKED_ALPHA) if locked else Color(1.0, 1.0, 1.0, 1.0)
	_apply_highlight(ready)


func _status_text(busy: bool = false) -> String:
	if locked:
		return locked_reason if not locked_reason.is_empty() else "Harus di meja untuk dibuat"
	if _block_reason == CraftingComponent.REASON_NO_INGREDIENTS:
		return _missing_status_text()
	if not _block_reason.is_empty():
		return _block_reason
	if busy:
		return "Sedang membuat..."
	return "Bisa dibuat"


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
	card.texture_margin_left = 34.0
	card.texture_margin_top = 34.0
	card.texture_margin_right = 34.0
	card.texture_margin_bottom = 34.0
	card.content_margin_left = 22.0
	card.content_margin_top = 14.0
	card.content_margin_right = 22.0
	card.content_margin_bottom = 14.0
	add_theme_stylebox_override("panel", card)
	custom_minimum_size = Vector2(0.0, 108.0)
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
	result_icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	result_icon.tooltip_text = ""
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
	_name_label.add_theme_font_override("font", FONT_BOLD)
	_name_label.autowrap_mode = TextServer.AUTOWRAP_OFF
	_name_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	_name_label.clip_text = true
	info.add_child(_name_label)

	_time_label = _make_label("", 11, META_COLOR)
	_time_label.name = "Meta"
	_time_label.add_theme_font_override("font", FONT_MEDIUM)
	info.add_child(_time_label)

	var ingredients := HBoxContainer.new()
	ingredients.name = "Ingredients"
	ingredients.add_theme_constant_override("separation", 6)
	ingredients.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	ingredients.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(ingredients)

	_ingredient_labels.clear()
	_ingredient_badges.clear()
	_badge_ok = _pill_style(PILL_GOOD_TEXTURE)
	_badge_missing = _pill_style(PILL_BAD_TEXTURE)
	for amount in recipe.ingredients:
		var col := VBoxContainer.new()
		col.add_theme_constant_override("separation", 2)
		col.mouse_filter = Control.MOUSE_FILTER_IGNORE
		ingredients.add_child(col)

		var icon := _make_letter_icon(amount.item if amount != null else null, 30, 12, INGREDIENT_ICON_BG)
		icon.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		col.add_child(icon)

		var badge := PanelContainer.new()
		badge.custom_minimum_size = Vector2(46.0, 22.0)
		badge.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		badge.mouse_filter = Control.MOUSE_FILTER_PASS
		badge.add_theme_stylebox_override("panel", _badge_ok)
		var label := _make_label("", 12, BADGE_TEXT)
		label.add_theme_font_override("font", FONT_BOLD)
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

	_craft_button = Button.new()
	_craft_button.name = "Button"
	_craft_button.text = "Buat"
	_craft_button.custom_minimum_size = Vector2(118.0, 38.0)
	_craft_button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	_craft_button.focus_mode = Control.FOCUS_ALL
	_craft_button.mouse_filter = Control.MOUSE_FILTER_STOP
	_craft_button.add_theme_font_override("font", FONT_BOLD)
	_craft_button.add_theme_font_size_override("font_size", 15)
	_craft_button.add_theme_stylebox_override("normal", BTN_NORMAL_STYLE)
	_craft_button.add_theme_stylebox_override("hover", BTN_HOVER_STYLE)
	_craft_button.add_theme_stylebox_override("pressed", BTN_PRESSED_STYLE)
	_craft_button.add_theme_stylebox_override("disabled", BTN_DISABLED_STYLE)
	_craft_button.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
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


func _make_letter_icon(item: ItemDefinition, icon_size: int, font_size: int, bg: Color) -> Control:
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(icon_size, icon_size)
	panel.mouse_filter = Control.MOUSE_FILTER_PASS
	var style := StyleBoxFlat.new()
	style.bg_color = bg
	style.border_color = ICON_BORDER
	style.set_border_width_all(2)
	style.set_corner_radius_all(int(icon_size / 2.0))
	panel.add_theme_stylebox_override("panel", style)

	var icon_tex: Texture2D = null if item == null else item.get_icon()
	if icon_tex != null:
		var tex_rect := TextureRect.new()
		tex_rect.texture = icon_tex
		tex_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		tex_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		tex_rect.custom_minimum_size = Vector2(icon_size - 8, icon_size - 8)
		tex_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
		panel.add_child(tex_rect)
	else:
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


func _make_custom_tooltip(_for_text: String) -> Object:
	if recipe == null or recipe.result == null:
		return null
	var tip := TOOLTIP_SCENE.instantiate() as ItemTooltip
	tip.show_item(recipe.result, maxi(recipe.result_count, 1))
	return tip


func _pill_style(tex_path: String) -> StyleBoxTexture:
	var style := StyleBoxTexture.new()
	style.texture = load(tex_path)
	style.texture_margin_left = 10.0
	style.texture_margin_top = 8.0
	style.texture_margin_right = 10.0
	style.texture_margin_bottom = 10.0
	style.content_margin_left = 8.0
	style.content_margin_top = 2.0
	style.content_margin_right = 8.0
	style.content_margin_bottom = 3.0
	return style


func _on_craft_pressed() -> void:
	if crafting == null or recipe == null:
		return
	crafting.start_craft(recipe, station, get_batch_quantity())


func _apply_highlight(_is_ready: bool) -> void:
	pass
