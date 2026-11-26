class_name WeaponHUD
extends CanvasLayer

## HUD slot senjata aktif di samping HotbarHUD.
## Menampilkan senjata yang sedang dipakai dan memungkinkan pemain mengganti
## atau memakai senjata hasil crafting lewat klik UI atau tombol G.

const PLAYER_GROUP := &"player"
const INVENTORY_NAME := "InventoryComponent"

@export var inventory: InventoryComponent

var _button: Button
var _icon: TextureRect
var _name_label: Label
var _key_label: Label


func _ready() -> void:
	layer = 10
	_build()
	if inventory == null:
		inventory = _find_inventory()
	if inventory != null:
		if not inventory.equipment_changed.is_connected(_on_inventory_updated):
			inventory.equipment_changed.connect(_on_inventory_updated)
		if not inventory.inventory_changed.is_connected(_on_refresh):
			inventory.inventory_changed.connect(_on_refresh)
		if not inventory.slot_changed.is_connected(_on_inventory_updated):
			inventory.slot_changed.connect(_on_inventory_updated)
	refresh()


func _unhandled_input(event: InputEvent) -> void:
	if UiBackStack.has_open(self):
		return
	if event is InputEventKey and event.pressed and not event.echo and (event as InputEventKey).keycode == KEY_G:
		cycle_weapon()
		get_viewport().set_input_as_handled()


func cycle_weapon() -> void:
	if inventory == null:
		inventory = _find_inventory()
	if inventory == null:
		return
	var weapons := _owned_weapons()
	if weapons.is_empty():
		return
	var current := inventory.get_equipped(ItemDefinition.EquipmentSlot.WEAPON)
	if current == null:
		inventory.equip(weapons[0])
		return
	var idx := weapons.find(current)
	if idx == -1 or idx + 1 >= weapons.size():
		if weapons.size() == 1:
			inventory.unequip(ItemDefinition.EquipmentSlot.WEAPON)
		else:
			inventory.equip(weapons[0])
	else:
		inventory.equip(weapons[idx + 1])


func refresh() -> void:
	if _icon == null or _name_label == null:
		return
	if inventory == null:
		inventory = _find_inventory()
	var equipped := inventory.get_equipped(ItemDefinition.EquipmentSlot.WEAPON) if inventory != null else null
	var weapons := _owned_weapons()
	if equipped != null:
		var tex := equipped.get_icon()
		_icon.texture = tex
		_icon.visible = tex != null
		_name_label.text = equipped.display_name
		_name_label.add_theme_color_override("font_color", Color(1.0, 0.98, 0.92, 1.0))
	else:
		_icon.texture = null
		_icon.visible = false
		_name_label.text = "Pilih Senjata" if not weapons.is_empty() else "Kosong"
		_name_label.add_theme_color_override(
			"font_color",
			Color(1.0, 0.86, 0.35, 1.0) if not weapons.is_empty() else Color(0.76, 0.72, 0.64, 0.85)
		)
	if _button != null:
		_button.disabled = weapons.is_empty() and equipped == null


func _owned_weapons() -> Array[ItemDefinition]:
	var result: Array[ItemDefinition] = []
	if inventory == null:
		return result
	for stack in inventory.get_slots():
		if stack == null or stack.is_empty() or stack.item == null:
			continue
		if stack.item.equipment_slot == ItemDefinition.EquipmentSlot.WEAPON and not result.has(stack.item):
			result.append(stack.item)
	return result


func _on_inventory_updated(_arg: int) -> void:
	refresh()


func _on_refresh() -> void:
	refresh()


func _find_inventory() -> InventoryComponent:
	var tree := get_tree()
	if tree == null:
		return null
	var candidate := tree.get_first_node_in_group(PLAYER_GROUP)
	if candidate == null:
		return null
	return candidate.get_node_or_null(INVENTORY_NAME) as InventoryComponent


func _build() -> void:
	var root := Control.new()
	root.name = "Root"
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(root)

	var panel := PanelContainer.new()
	panel.name = "Panel"
	panel.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	panel.anchor_left = 0.5
	panel.anchor_right = 0.5
	panel.anchor_top = 1.0
	panel.anchor_bottom = 1.0
	panel.grow_horizontal = Control.GROW_DIRECTION_BOTH
	panel.grow_vertical = Control.GROW_DIRECTION_BEGIN
	panel.offset_left = 272.0
	panel.offset_top = -132.0
	panel.offset_right = 412.0
	panel.offset_bottom = -20.0
	panel.mouse_filter = Control.MOUSE_FILTER_STOP
	panel.add_theme_stylebox_override("panel", _panel_style())
	root.add_child(panel)

	_button = Button.new()
	_button.name = "WeaponButton"
	_button.focus_mode = Control.FOCUS_NONE
	_button.flat = true
	_button.tooltip_text = "Ganti / pakai senjata (G)"
	_button.pressed.connect(cycle_weapon)
	panel.add_child(_button)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 4)
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vbox.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_button.add_child(vbox)

	var slot_box := PanelContainer.new()
	slot_box.custom_minimum_size = Vector2(56.0, 54.0)
	slot_box.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	slot_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	slot_box.add_theme_stylebox_override("panel", _slot_style())
	vbox.add_child(slot_box)

	_icon = TextureRect.new()
	_icon.name = "Icon"
	_icon.custom_minimum_size = Vector2(34.0, 34.0)
	_icon.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	_icon.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	slot_box.add_child(_icon)

	_key_label = Label.new()
	_key_label.text = "G"
	_key_label.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	_key_label.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	_key_label.add_theme_font_size_override("font_size", 11)
	_key_label.add_theme_color_override("font_color", Color(1.0, 0.86, 0.35, 1.0))
	_key_label.add_theme_color_override("font_outline_color", Color(0.14, 0.09, 0.05, 1.0))
	_key_label.add_theme_constant_override("outline_size", 3)
	_key_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	slot_box.add_child(_key_label)

	_name_label = Label.new()
	_name_label.name = "Name"
	_name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_name_label.autowrap_mode = TextServer.AUTOWRAP_OFF
	_name_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	_name_label.clip_text = true
	_name_label.add_theme_font_size_override("font_size", 12)
	_name_label.add_theme_color_override("font_color", Color(1.0, 0.98, 0.92, 1.0))
	_name_label.add_theme_color_override("font_outline_color", Color(0.14, 0.09, 0.05, 1.0))
	_name_label.add_theme_constant_override("outline_size", 3)
	_name_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vbox.add_child(_name_label)


func _panel_style() -> StyleBox:
	var tex_path := "res://assets/textures/ui/02_panel/panel_walnut_stitched.png"
	if ResourceLoader.exists(tex_path):
		var tex := load(tex_path) as Texture2D
		if tex != null:
			var box := StyleBoxTexture.new()
			box.texture = tex
			box.texture_margin_left = 24.0
			box.texture_margin_top = 24.0
			box.texture_margin_right = 24.0
			box.texture_margin_bottom = 24.0
			box.content_margin_left = 14.0
			box.content_margin_top = 12.0
			box.content_margin_right = 14.0
			box.content_margin_bottom = 12.0
			return box
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.16, 0.11, 0.08, 0.9)
	style.set_corner_radius_all(8)
	style.set_content_margin_all(12.0)
	return style


func _slot_style() -> StyleBox:
	var tex_path := "res://assets/textures/ui/05_slot/slot_item_selected.png"
	if ResourceLoader.exists(tex_path):
		var tex := load(tex_path) as Texture2D
		if tex != null:
			var box := StyleBoxTexture.new()
			box.texture = tex
			box.texture_margin_left = 14.0
			box.texture_margin_top = 14.0
			box.texture_margin_right = 14.0
			box.texture_margin_bottom = 14.0
			box.content_margin_left = 6.0
			box.content_margin_top = 6.0
			box.content_margin_right = 6.0
			box.content_margin_bottom = 6.0
			return box
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.95, 0.9, 0.8, 0.9)
	style.set_corner_radius_all(6)
	return style
