class_name ChestPanel
extends CanvasLayer


## Mission 7: panel peti 24 slot + cermin tas 12 slot. Tidak mem-pause.

signal closed

const CLOSE_DISTANCE := 120.0
const CHEST_GROUP := &"camp_structure"
const UiMotion := preload("res://src/ui/fx/ui_motion.gd")

@export var chest: Node
@export var inventory: InventoryComponent
@export var player: Node2D
@export var bag_panel: Node

var _open: bool = false
var _connected_chests: Dictionary = {}
var _chest_grid: GridContainer
var _bag_grid: GridContainer
var _title: Label
var _hint: Label
var _built: bool = false


func _ready() -> void:
	layer = 21
	visible = false
	_build_ui()
	UiSkin.apply_all(self)


func _process(_delta: float) -> void:
	_scan_chests()
	if not _open:
		return
	if chest == null or not is_instance_valid(chest):
		close()
		return
	if player != null and chest is Node2D and player.is_inside_tree():
		if (chest as Node2D).global_position.distance_to(player.global_position) > CLOSE_DISTANCE:
			close()


func _unhandled_input(event: InputEvent) -> void:
	if not _open:
		return
	if event.is_action_pressed(&"ui_cancel") or event.is_action_pressed(InputSetup.INTERACT):
		close()
		get_viewport().set_input_as_handled()


func setup(p_chest: Node, p_inventory: InventoryComponent, p_player: Node2D, p_bag_panel: Node = null) -> void:
	chest = p_chest
	inventory = p_inventory
	player = p_player
	bag_panel = p_bag_panel
	_connect_chest(p_chest)


func _ui_root() -> Control:
	return get_child(0) as Control if get_child_count() > 0 else null


func open_for(p_chest: Node, p_inventory: InventoryComponent, p_player: Node2D) -> bool:
	if p_chest == null:
		return false
	setup(p_chest, p_inventory, p_player, bag_panel)
	_open = true
	visible = true
	UiMotion.pop_in(_ui_root())
	UiBackStack.register(self)
	if bag_panel != null and bag_panel.has_method(&"set_locked"):
		bag_panel.set_locked(true)
	refresh()
	if _chest_grid != null and _chest_grid.get_child_count() > 0:
		(_chest_grid.get_child(0) as Control).grab_focus()
	return true


func close() -> void:
	if not _open:
		visible = false
		return
	_open = false
	UiBackStack.unregister(self)
	if bag_panel != null and bag_panel.has_method(&"set_locked"):
		bag_panel.set_locked(false)
	closed.emit()
	UiMotion.pop_out(_ui_root(), func() -> void:
		if not _open:
			visible = false
	)


func is_open() -> bool:
	return _open


func get_chest_slots() -> Array[ItemStack]:
	var component := _component()
	return component.get_slots() if component != null else []


func get_bag_slots() -> Array[ItemStack]:
	return inventory.get_slots() if inventory != null else []


func take_all() -> void:
	var component := _component()
	if component == null or inventory == null:
		return
	for index in component.get_capacity():
		if component.is_slot_empty(index):
			continue
		component.move_to_bag(index, inventory)
	refresh()


## Pindahkan seluruh isi tas ke peti (sisa yang tidak muat tetap di tas).
func store_all() -> void:
	var component := _component()
	if component == null or inventory == null:
		return
	# Satu slot bisa tersisa sebagian bila peti hampir penuh; ulangi selama
	# masih ada yang berpindah supaya sisa ruang terpakai.
	var moved_any := true
	var guard := 0
	while moved_any and guard < 50:
		moved_any = false
		guard += 1
		for index in inventory.get_capacity():
			if inventory.is_slot_empty(index):
				continue
			if component.move_from_bag(inventory, index):
				moved_any = true
	refresh()


func refresh() -> void:
	if not _built:
		return
	var component := _component()
	if component == null:
		return
	var used := 0
	for stack in component.get_slots():
		if stack != null and not stack.is_empty():
			used += 1
	_title.text = "Peti (%d/%d slot)" % [used, component.get_capacity()]
	if _hint != null:
		_hint.text = "Klik kiri/kanan slot: pindahkan barang antara peti dan tas"
	var chest_slots := component.get_slots()
	for index in _chest_grid.get_child_count():
		var button := _chest_grid.get_child(index) as Button
		button.text = _slot_text(chest_slots, index)
		button.icon = _slot_icon(chest_slots, index)
	if inventory == null:
		return
	var bag_slots := inventory.get_slots()
	for index in _bag_grid.get_child_count():
		var button := _bag_grid.get_child(index) as Button
		button.text = _slot_text(bag_slots, index)
		button.icon = _slot_icon(bag_slots, index)


# --- Internal ---------------------------------------------------------------

func _component() -> ChestComponent:
	if chest == null or not is_instance_valid(chest) or not chest.has_method(&"get_component"):
		return null
	return chest.get_component() as ChestComponent


func _slot_text(slots: Array, index: int) -> String:
	if index >= slots.size():
		return "-"
	var stack := slots[index] as ItemStack
	if stack == null or stack.item == null or stack.count <= 0:
		return "-"
	return "%s x%d" % [stack.item.display_name, stack.count]


func _slot_icon(slots: Array, index: int) -> Texture2D:
	if index >= slots.size():
		return null
	var stack := slots[index] as ItemStack
	if stack == null or stack.item == null or stack.count <= 0:
		return null
	return stack.item.get_icon()


func _scan_chests() -> void:
	var tree := get_tree()
	if tree == null:
		return
	for node in tree.get_nodes_in_group(CHEST_GROUP):
		# Grup camp_structure juga berisi Campfire/Workbench yang sinyalnya
		# interaction_requested(station, interactor). Hanya peti yang boleh
		# disambung ke _on_chest_interaction(interactor).
		if node is Chest:
			_connect_chest(node)


func _connect_chest(node: Node) -> void:
	if not (node is Chest) or not is_instance_valid(node):
		return
	var id := node.get_instance_id()
	if _connected_chests.has(id):
		return
	_connected_chests[id] = true
	# Bind peti pengirim: interactor adalah InteractorComponent (Node), bukan
	# Node2D, jadi menebak "peti terdekat dari (0,0)" bisa membuka peti lain.
	if not node.interaction_requested.is_connected(_on_chest_interaction):
		node.interaction_requested.connect(_on_chest_interaction.bind(node))


func _on_chest_interaction(interactor: Node, source: Chest = null) -> void:
	if inventory == null and interactor != null and interactor.has_method(&"get_inventory"):
		inventory = interactor.get_inventory() as InventoryComponent
	if player == null and interactor != null:
		player = interactor.get_parent() as Node2D
	var target: Node = source if source != null and is_instance_valid(source) else null
	if target == null:
		target = chest if _open and chest is Chest else _sender_chest(interactor)
	if target == null:
		return
	open_for(target, inventory, player)


## Peti terdekat dari pemain (fallback bila sinyal tidak membawa peti).
func _sender_chest(interactor: Node) -> Node:
	var tree := get_tree()
	if tree == null:
		return null
	var origin := Vector2.ZERO
	if player != null and is_instance_valid(player):
		origin = player.global_position
	elif interactor != null and interactor.get_parent() is Node2D:
		origin = (interactor.get_parent() as Node2D).global_position
	var best: Chest = null
	var best_distance := INF
	for node in tree.get_nodes_in_group(CHEST_GROUP):
		if not (node is Chest):
			continue
		var candidate := node as Chest
		var distance := origin.distance_to(candidate.global_position)
		if distance < best_distance:
			best_distance = distance
			best = candidate
	return best


func _on_chest_slot(index: int) -> void:
	var component := _component()
	if component == null or inventory == null:
		return
	component.move_to_bag(index, inventory)
	refresh()


func _on_bag_slot(index: int) -> void:
	var component := _component()
	if component == null or inventory == null:
		return
	component.move_from_bag(inventory, index)
	refresh()


func _build_ui() -> void:
	var dim := ColorRect.new()
	dim.name = "Dim"
	dim.color = Color(0.0, 0.0, 0.0, 0.45)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(dim)

	var frame := Panel.new()
	frame.name = "Frame"
	frame.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
	frame.add_theme_stylebox_override("panel", _tex_box("res://assets/textures/ui/02_panel/panel_walnut_stitched.png", 24.0, Vector2(24.0, 20.0)))
	add_child(frame)

	var root := VBoxContainer.new()
	root.name = "Root"
	root.set_anchors_preset(Control.PRESET_CENTER)
	root.grow_horizontal = Control.GROW_DIRECTION_BOTH
	root.grow_vertical = Control.GROW_DIRECTION_BOTH
	root.add_theme_constant_override("separation", 10)
	root.mouse_filter = Control.MOUSE_FILTER_STOP
	root.resized.connect(func() -> void:
		frame.position = root.position - Vector2(24.0, 20.0)
		frame.size = root.size + Vector2(48.0, 40.0)
	)
	add_child(root)
	_title = Label.new()
	_title.text = "Peti"
	_title.add_theme_font_size_override("font_size", 18)
	_title.add_theme_color_override("font_color", Color(0.922, 0.761, 0.451, 1.0))
	root.add_child(_title)
	var slot_normal := _tex_box("res://assets/textures/ui/05_slot/slot_item.png", 12.0, Vector2(8.0, 6.0))
	var slot_focus := _tex_box("res://assets/textures/ui/05_slot/slot_item_selected.png", 12.0, Vector2(8.0, 6.0))
	_chest_grid = GridContainer.new()
	_chest_grid.name = "ChestGrid"
	_chest_grid.columns = 6
	_chest_grid.add_theme_constant_override("h_separation", 6)
	_chest_grid.add_theme_constant_override("v_separation", 6)
	root.add_child(_chest_grid)
	for index in 24:
		var button := _make_slot_button(index, true, slot_normal, slot_focus)
		_chest_grid.add_child(button)
	_bag_grid = GridContainer.new()
	_bag_grid.name = "BagGrid"
	_bag_grid.columns = 6
	_bag_grid.add_theme_constant_override("h_separation", 6)
	_bag_grid.add_theme_constant_override("v_separation", 6)
	root.add_child(_bag_grid)
	for index in 12:
		var button := _make_slot_button(index, false, slot_normal, slot_focus)
		_bag_grid.add_child(button)
	_hint = Label.new()
	_hint.name = "Hint"
	_hint.add_theme_font_size_override("font_size", 11)
	_hint.add_theme_color_override("font_color", Color(0.88, 0.84, 0.76, 1.0))
	_hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	root.add_child(_hint)
	var actions := HBoxContainer.new()
	actions.add_theme_constant_override("separation", 10)
	root.add_child(actions)
	var take := _make_action_button("TakeAll", "Ambil semua", "primary")
	take.pressed.connect(take_all)
	actions.add_child(take)
	var store := _make_action_button("StoreAll", "Simpan semua", "primary")
	store.pressed.connect(store_all)
	actions.add_child(store)
	var close_button := _make_action_button("Close", "Tutup", "back")
	close_button.pressed.connect(close)
	actions.add_child(close_button)
	_built = true


func _make_slot_button(index: int, from_chest: bool, normal_box: StyleBox, focus_box: StyleBox) -> Button:
	var button := Button.new()
	button.focus_mode = Control.FOCUS_ALL
	button.custom_minimum_size = Vector2(104.0, 34.0)
	if normal_box != null:
		button.add_theme_stylebox_override("normal", normal_box)
	if focus_box != null:
		button.add_theme_stylebox_override("hover", focus_box)
		button.add_theme_stylebox_override("focus", focus_box)
		button.add_theme_stylebox_override("pressed", focus_box)
	button.add_theme_color_override("font_color", Color(0.22, 0.14, 0.09, 1.0))
	button.add_theme_color_override("font_hover_color", Color(0.22, 0.14, 0.09, 1.0))
	button.add_theme_color_override("font_focus_color", Color(0.22, 0.14, 0.09, 1.0))
	button.add_theme_font_size_override("font_size", 11)
	button.gui_input.connect(_on_slot_input.bind(button, index, from_chest))
	return button


func _make_action_button(btn_name: String, label_text: String, variant: String) -> Button:
	var btn := Button.new()
	btn.name = btn_name
	btn.text = label_text
	btn.custom_minimum_size = Vector2(120.0, 34.0)
	var base := "res://assets/textures/ui/03_button/button_%s_" % variant
	var n := _tex_box(base + "normal.png", 14.0, Vector2(12.0, 6.0))
	var h := _tex_box(base + "hover.png", 14.0, Vector2(12.0, 6.0))
	var p := _tex_box(base + "pressed.png", 14.0, Vector2(12.0, 6.0))
	if n != null:
		btn.add_theme_stylebox_override("normal", n)
	if h != null:
		btn.add_theme_stylebox_override("hover", h)
	if p != null:
		btn.add_theme_stylebox_override("pressed", p)
	btn.add_theme_color_override("font_color", Color(0.968627, 0.945098, 0.898039, 1.0))
	return btn


func _tex_box(path: String, tex_margin: float, content: Vector2) -> StyleBox:
	if ResourceLoader.exists(path):
		var tex := load(path) as Texture2D
		if tex != null:
			var box := StyleBoxTexture.new()
			box.texture = tex
			box.texture_margin_left = tex_margin
			box.texture_margin_top = tex_margin
			box.texture_margin_right = tex_margin
			box.texture_margin_bottom = tex_margin
			box.content_margin_left = content.x
			box.content_margin_top = content.y
			box.content_margin_right = content.x
			box.content_margin_bottom = content.y
			return box
	return null


func _on_slot_input(event: InputEvent, _button: Button, index: int, from_chest: bool) -> void:
	if event.is_action_pressed(&"ui_accept"):
		get_viewport().set_input_as_handled()
		if from_chest:
			_on_chest_slot(index)
		else:
			_on_bag_slot(index)
		return
	var mouse := event as InputEventMouseButton
	if mouse == null or not mouse.pressed:
		return
	# Klik kiri adalah aksi utama; klik kanan dipertahankan untuk pemain lama.
	if mouse.button_index != MOUSE_BUTTON_LEFT and mouse.button_index != MOUSE_BUTTON_RIGHT:
		return
	if from_chest:
		_on_chest_slot(index)
	else:
		_on_bag_slot(index)
