class_name CraftingRow
extends PanelContainer

## Satu baris resep di tab Crafting.
##
## Baris ini tidak punya state gameplay: semua angka dibaca dari
## CraftingComponent/InventoryComponent saat `refresh()`, dan satu-satunya aksi
## adalah `start_craft()` pada tombol Craft. Baris "terkunci" (stasiun belum ada)
## ditampilkan redup dengan nama stasiun sebagai alasan.

const MISSING_COLOR := Color(1.0, 0.5, 0.45, 1.0)
const NORMAL_COLOR := Color(0.88, 0.93, 0.88, 1.0)
const LOCKED_ALPHA := 0.45
const REASON_COLOR := Color(1.0, 0.62, 0.5, 1.0)

var recipe: RecipeDefinition
var crafting: CraftingComponent
var inventory: InventoryComponent
var locked: bool = false
## Alasan khusus saat terkunci (mis. api unggun masih dingin).
var locked_reason: String = ""
## Mission 10: stasiun pemanggil (null = tab tas, perilaku lama).
var station: Node

var _name_label: Label
var _time_label: Label
var _reason_label: Label
var _craft_button: Button
var _ingredient_labels: Array[Label] = []
var _missing_flags: Array[bool] = []
var _block_reason: String = ""


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


## Simulasi klik tombol Craft (dipakai tes tanpa mouse).
func press_craft() -> void:
	if _craft_button == null or _craft_button.disabled:
		return
	_craft_button.pressed.emit()


# --- Refresh ----------------------------------------------------------------

func refresh() -> void:
	if recipe == null:
		return

	_name_label.text = recipe.display_name
	_time_label.text = "%.1f s" % recipe.craft_time

	if locked:
		_block_reason = locked_reason if not locked_reason.is_empty() else recipe.get_station_block_reason()
	else:
		_block_reason = "" if crafting == null else crafting.get_block_reason(recipe)

	_update_ingredients()

	var busy := crafting != null and crafting.is_crafting()
	_craft_button.disabled = locked or not _block_reason.is_empty() or busy
	_craft_button.tooltip_text = _block_reason
	_reason_label.text = _block_reason
	_reason_label.visible = not _block_reason.is_empty()
	modulate = Color(1.0, 1.0, 1.0, LOCKED_ALPHA) if locked else Color(1.0, 1.0, 1.0, 1.0)


func _update_ingredients() -> void:
	_missing_flags.clear()
	for index in _ingredient_labels.size():
		var amount := recipe.ingredients[index]
		var label := _ingredient_labels[index]
		if amount == null or amount.item == null:
			label.text = ""
			_missing_flags.append(false)
			continue

		var have := 0
		if crafting != null:
			have = crafting.count_available(amount.item)
		elif inventory != null:
			have = inventory.count_of(amount.item)

		var missing := have < amount.count
		label.text = "%s %d/%d" % [amount.item.display_name, have, amount.count]
		label.add_theme_color_override("font_color", MISSING_COLOR if missing else NORMAL_COLOR)
		_missing_flags.append(missing)


# --- Build ------------------------------------------------------------------

func _build() -> void:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	add_child(row)

	var info := VBoxContainer.new()
	info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	info.add_theme_constant_override("separation", 2)
	row.add_child(info)

	_name_label = Label.new()
	_name_label.add_theme_font_size_override("font_size", 13)
	info.add_child(_name_label)

	var ingredients := HBoxContainer.new()
	ingredients.add_theme_constant_override("separation", 8)
	info.add_child(ingredients)
	_ingredient_labels.clear()
	for _amount in recipe.ingredients:
		var label := Label.new()
		label.add_theme_font_size_override("font_size", 11)
		ingredients.add_child(label)
		_ingredient_labels.append(label)

	_reason_label = Label.new()
	_reason_label.add_theme_font_size_override("font_size", 10)
	_reason_label.add_theme_color_override("font_color", REASON_COLOR)
	_reason_label.visible = false
	info.add_child(_reason_label)

	_time_label = Label.new()
	_time_label.add_theme_font_size_override("font_size", 12)
	row.add_child(_time_label)

	_craft_button = Button.new()
	_craft_button.text = "Craft"
	_craft_button.custom_minimum_size = Vector2(64.0, 26.0)
	_craft_button.pressed.connect(_on_craft_pressed)
	row.add_child(_craft_button)


func _on_craft_pressed() -> void:
	if crafting == null or recipe == null:
		return
	crafting.start_craft(recipe, station)
