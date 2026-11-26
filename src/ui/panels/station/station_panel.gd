class_name StationPanel
extends CanvasLayer

## Mission 10 Phase 2: panel stasiun (Meja Kerja / Api Unggun) dibuka dengan E.
## UI murni: semua aturan craft tetap di CraftingComponent.

signal opened(station: Node)
signal closed(station: Node)

const PLAYER_GROUP := &"player"
const CRAFTING_NAME := "CraftingComponent"
const WORKBENCH_TYPE := RecipeDefinition.Station.WORKBENCH
const CAMPFIRE_TYPE := RecipeDefinition.Station.CAMPFIRE
const COLD_REASON := "Api belum menyala - gesek batu dulu"
const FLINT_HINT := "Gesek batu: tekan E saat penanda di zona hijau"
const FUEL_TEXT := "Bahan bakar: %d/%d dtk"
const REFUEL_LABEL := "Isi Bahan Bakar (2 Kayu)"
const FLINT_LABEL := "Gesek Batu"
const PANEL_COLOR := Color(0.08, 0.10, 0.09, 0.95)
const ROW_SCENE_SCRIPT := preload("res://src/ui/panels/inventory/crafting_row.gd")

@export var crafting: CraftingComponent
@export var player: Node2D

var station: Node
var interactor: Node

var _root: Control
var _title: Label
var _state: Label
var _rows_box: VBoxContainer
var _rows: Array = []
var _progress: ProgressBar
var _status: Label
var _fuel_label: Label
var _fuel_bar: ProgressBar
var _refuel: Button
var _flint: Button
var _is_open: bool = false
var _last_cold: bool = false
var _connected_crafting: CraftingComponent


func _ready() -> void:
	layer = 22
	visible = false
	_build_ui()


# --- API --------------------------------------------------------------------

func open(p_station: Node, p_interactor: Node = null) -> bool:
	if p_station == null or not is_instance_valid(p_station):
		return false
	if interactor == null and p_interactor == null:
		return false
	station = p_station
	interactor = p_interactor
	if crafting == null:
		crafting = _find_crafting()
	if player == null:
		player = _find_player()
	_is_open = true
	visible = true
	_root.visible = true
	_status.text = ""
	_set_player_locked(true)
	UiBackStack.register(self)
	_connect_crafting()
	_connect_station_signals()
	rebuild()
	_focus_first_action()
	opened.emit(station)
	return true


func _focus_first_action() -> void:
	if _flint != null and _flint.visible and not _flint.disabled:
		_flint.grab_focus()
		return
	if _refuel != null and _refuel.visible and not _refuel.disabled:
		_refuel.grab_focus()
		return
	for row in _rows:
		if row != null and is_instance_valid(row) and row.has_method(&"is_craft_disabled") and not row.is_craft_disabled():
			for child in (row as Node).find_children("", "Button", true, false):
				var btn := child as Button
				if btn != null and not btn.disabled:
					btn.grab_focus()
					return


func close() -> void:
	if not _is_open:
		visible = false
		return
	_is_open = false
	visible = false
	_root.visible = false
	_set_player_locked(false)
	UiBackStack.unregister(self)
	if crafting != null and crafting.get_active_station() == station:
		crafting.cancel_craft("Panel ditutup")
	_progress.visible = false
	closed.emit(station)


func is_open() -> bool:
	return _is_open


func _exit_tree() -> void:
	if _is_open:
		_set_player_locked(false)


## Dunia tetap berjalan; hanya input gerak pemain yang dikunci.
func _set_player_locked(locked: bool) -> void:
	if player != null and is_instance_valid(player) and player.has_method(&"set_input_locked"):
		player.call(&"set_input_locked", locked)


## Dipanggil _process dan tes.
func tick(delta: float) -> void:
	if not _is_open:
		return
	if delta <= 0.0:
		return
	if station == null or not is_instance_valid(station) or not station.is_inside_tree():
		close()
		return
	if get_tree() != null and get_tree().paused:
		close()
		return
	if player != null and is_instance_valid(player) and station is Node2D:
		var limit := _close_distance()
		if player.global_position.distance_to((station as Node2D).global_position) > limit:
			close()
			return
	_refresh_runtime()


func _process(delta: float) -> void:
	tick(delta)


func _unhandled_input(event: InputEvent) -> void:
	if not _is_open:
		return
	# Saat QTE gesek batu aktif, E adalah tombol strike dan Esc membatalkan
	# QTE di FireStarterController; jangan tutup panelnya dari sini.
	if _ignition_active() and (event.is_action_pressed(InputSetup.INTERACT) or event.is_action_pressed(&"ui_cancel")):
		return
	if event.is_action_pressed(&"ui_cancel") or event.is_action_pressed(InputSetup.INTERACT):
		close()
		get_viewport().set_input_as_handled()


func _ignition_active() -> bool:
	var tree := get_tree()
	if tree == null:
		return false
	var controller := tree.get_first_node_in_group(FireStarterController.GROUP) as FireStarterController
	return controller != null and controller.is_active()


# --- Read API (tes) ---------------------------------------------------------

func get_rows() -> Array:
	return _rows


func get_title_text() -> String:
	return "" if _title == null else _title.text


func get_status_text() -> String:
	return "" if _status == null else _status.text


func get_progress() -> ProgressBar:
	return _progress


func get_refuel_button() -> Button:
	return _refuel


func get_flint_button() -> Button:
	return _flint


func refuel_pressed() -> void:
	if station == null or not station.has_method(&"refuel"):
		return
	var ok: bool = bool(station.call(&"refuel", interactor))
	_status.text = "Bahan bakar ditambah" if ok else _refuel_reason()
	_refresh_runtime()
	refresh_rows()


func flint_pressed() -> void:
	if station == null or not station.has_method(&"request_ignition"):
		return
	var reason := _flint_reason()
	if not reason.is_empty():
		_status.text = reason
		return
	# Panel tetap terbuka: QTE berjalan di HUD layer lebih atas. Setelah api
	# menyala, `lit_changed` membangun ulang baris sehingga resep langsung aktif.
	var started: bool = bool(station.call(&"request_ignition", interactor))
	_status.text = FLINT_HINT if started else "Tidak bisa menyalakan api"
	_refresh_runtime()


## Bangun ulang daftar resep stasiun ini.
func rebuild() -> void:
	for child in _rows_box.get_children():
		_rows_box.remove_child(child)
		child.free()
	_rows.clear()
	if crafting == null or station == null:
		_status.text = "Crafting tidak tersedia"
		return
	_title.text = _station_title()
	_state.text = _state_text()
	_refresh_campfire_ui()
	var cold := _is_cold()
	_last_cold = cold
	for recipe in crafting.get_recipes_for(_station_type()):
		var row := ROW_SCENE_SCRIPT.new()
		row.station = station
		_rows_box.add_child(row)
		row.setup(recipe, crafting, crafting.inventory, cold)
		if cold:
			row.set_locked_reason(COLD_REASON)
		_rows.append(row)
	var active := crafting != null and crafting.is_crafting()
	_progress.visible = active
	if active:
		_progress.value = crafting.get_progress_ratio()


# --- Internal ---------------------------------------------------------------

## Sambungkan sekali per CraftingComponent supaya panel ikut progres/isi tas.
func _connect_crafting() -> void:
	if crafting == null:
		return
	if not crafting.craft_started.is_connected(_on_craft_started):
		crafting.craft_started.connect(_on_craft_started)
	if not crafting.craft_progress.is_connected(_on_craft_progress):
		crafting.craft_progress.connect(_on_craft_progress)
	if not crafting.craft_completed.is_connected(_on_craft_completed):
		crafting.craft_completed.connect(_on_craft_completed)
	if not crafting.craft_cancelled.is_connected(_on_craft_cancelled):
		crafting.craft_cancelled.connect(_on_craft_cancelled)
	var inventory := crafting.inventory
	if inventory != null and not inventory.inventory_changed.is_connected(_on_inventory_changed):
		inventory.inventory_changed.connect(_on_inventory_changed)
	_connected_crafting = crafting


func _connect_station_signals() -> void:
	if station == null:
		return
	var callback := Callable(self, &"_on_station_state_changed")
	# Hanya dengarkan lit_changed, bukan fuel_changed (fuel_changed terpancar tiap
	# frame saat api menyala; rebuild() di sini dulu menghancurkan tombol "Buat"
	# sebelum klik mouse selesai). Bar bahan bakar diperbarui di _refresh_runtime().
	if station.has_signal(&"lit_changed") and not station.is_connected(&"lit_changed", callback):
		station.connect(&"lit_changed", callback)


func refresh_rows() -> void:
	for row in _rows:
		if row != null and is_instance_valid(row):
			row.refresh()


func _on_craft_started(recipe: RecipeDefinition) -> void:
	_progress.visible = true
	_progress.value = 0.0
	_status.text = "Membuat %s..." % recipe.display_name
	refresh_rows()


func _on_craft_progress(ratio: float) -> void:
	_progress.visible = true
	_progress.value = clampf(ratio, 0.0, 1.0)


func _on_craft_completed(recipe: RecipeDefinition) -> void:
	_progress.visible = false
	_progress.value = 0.0
	_status.text = "Selesai: %s x%d" % [recipe.display_name, maxi(recipe.result_count, 1)]
	refresh_rows()


func _on_craft_cancelled(recipe: RecipeDefinition, reason: String) -> void:
	_progress.visible = false
	_progress.value = 0.0
	_status.text = "Batal: %s%s" % [recipe.display_name, " (" + reason + ")" if not reason.is_empty() else ""]
	refresh_rows()


func _on_inventory_changed() -> void:
	if _is_open:
		refresh_rows()


func _on_station_state_changed(_value: Variant = null) -> void:
	if not _is_open:
		return
	if not _is_cold():
		_status.text = "Api menyala"
	rebuild()


func _station_type() -> int:
	if station != null and ("station_type" in station):
		return int(station.get("station_type"))
	return WORKBENCH_TYPE


func _station_title() -> String:
	match _station_type():
		WORKBENCH_TYPE:
			return "MEJA KERJA"
		CAMPFIRE_TYPE:
			return "API UNGGUN"
		_:
			return "STASIUN"


func _state_text() -> String:
	if _is_cold():
		return COLD_REASON
	if _station_type() == CAMPFIRE_TYPE:
		return "Api menyala"
	return "Siap dipakai"


func _is_cold() -> bool:
	return station != null and station.has_method(&"is_cold") and bool(station.call(&"is_cold"))


func _close_distance() -> float:
	return crafting.get_station_config().panel_close_distance if crafting != null else 160.0


func _refuel_reason() -> String:
	if station != null and station.has_method(&"get_refuel_block_reason"):
		return String(station.call(&"get_refuel_block_reason", interactor))
	return ""


func _flint_reason() -> String:
	if station == null or not station.has_method(&"needs_ignition"):
		return ""
	if not bool(station.call(&"needs_ignition")):
		return "Api sudah menyala" if not _is_cold() else "Tambah bahan bakar dulu"
	if station.has_method(&"get_ignite_block_reason"):
		return String(station.call(&"get_ignite_block_reason", interactor))
	return ""


func _refresh_campfire_ui() -> void:
	var is_fire := _station_type() == CAMPFIRE_TYPE
	_refuel.visible = is_fire
	_flint.visible = is_fire
	_fuel_bar.visible = is_fire
	_fuel_label.visible = is_fire
	if not is_fire:
		return
	var refuel_reason := _refuel_reason()
	_refuel.disabled = not refuel_reason.is_empty()
	_refuel.tooltip_text = refuel_reason
	var flint_reason := _flint_reason()
	_flint.disabled = not flint_reason.is_empty()
	_flint.tooltip_text = flint_reason


func _refresh_runtime() -> void:
	if station == null or not is_instance_valid(station):
		return
	_state.text = _state_text()
	if crafting != null and crafting.is_crafting():
		_progress.visible = true
		_progress.value = crafting.get_progress_ratio()
	var cold := _is_cold()
	if cold != _last_cold:
		_last_cold = cold
		rebuild()
		return
	var max_fuel := 1.0
	if station.has_method(&"get_max_fuel"):
		max_fuel = maxf(float(station.call(&"get_max_fuel")), 1.0)
	_fuel_bar.max_value = max_fuel
	if station.has_method(&"get_fuel"):
		_fuel_bar.value = clampf(float(station.call(&"get_fuel")), 0.0, max_fuel)
		_fuel_label.text = FUEL_TEXT % [int(_fuel_bar.value), int(max_fuel)]
	_refresh_campfire_ui()


func _find_player() -> Node2D:
	var tree := get_tree()
	if tree == null:
		return null
	return tree.get_first_node_in_group(PLAYER_GROUP) as Node2D


func _find_crafting() -> CraftingComponent:
	var p := _find_player()
	if p == null:
		return null
	return p.get_node_or_null(CRAFTING_NAME) as CraftingComponent


func _build_ui() -> void:
	_root = Control.new()
	_root.name = "Root"
	_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	_root.mouse_filter = Control.MOUSE_FILTER_STOP
	_root.visible = false
	add_child(_root)

	var dim := ColorRect.new()
	dim.color = Color(0.0, 0.0, 0.0, 0.45)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.mouse_filter = Control.MOUSE_FILTER_STOP
	_root.add_child(dim)

	var panel := PanelContainer.new()
	panel.name = "Panel"
	panel.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	panel.custom_minimum_size = Vector2(780.0, 520.0)
	panel.set_anchors_preset(Control.PRESET_CENTER)
	panel.grow_horizontal = Control.GROW_DIRECTION_BOTH
	panel.grow_vertical = Control.GROW_DIRECTION_BOTH
	var panel_tex := "res://assets/textures/ui/02_panel/panel_walnut_stitched.png"
	if ResourceLoader.exists(panel_tex):
		var box := StyleBoxTexture.new()
		box.texture = load(panel_tex) as Texture2D
		box.texture_margin_left = 24.0
		box.texture_margin_top = 24.0
		box.texture_margin_right = 24.0
		box.texture_margin_bottom = 24.0
		box.content_margin_left = 24.0
		box.content_margin_top = 20.0
		box.content_margin_right = 24.0
		box.content_margin_bottom = 20.0
		panel.add_theme_stylebox_override("panel", box)
	else:
		var style := StyleBoxFlat.new()
		style.bg_color = PANEL_COLOR
		style.border_color = Color(0.85, 0.78, 0.5, 0.8)
		style.set_border_width_all(2)
		style.set_corner_radius_all(8)
		style.set_content_margin_all(18.0)
		panel.add_theme_stylebox_override("panel", style)
	_root.add_child(panel)

	var box := VBoxContainer.new()
	box.name = "Box"
	box.add_theme_constant_override("separation", 6)
	panel.add_child(box)

	_title = Label.new()
	_title.text = "STASIUN"
	_title.add_theme_font_size_override("font_size", 16)
	box.add_child(_title)

	_state = Label.new()
	_state.add_theme_font_size_override("font_size", 11)
	_state.add_theme_color_override("font_color", Color(0.82, 0.86, 0.78, 1.0))
	box.add_child(_state)

	_fuel_label = Label.new()
	_fuel_label.add_theme_font_size_override("font_size", 10)
	box.add_child(_fuel_label)

	_fuel_bar = ProgressBar.new()
	_fuel_bar.show_percentage = false
	_fuel_bar.custom_minimum_size = Vector2(0, 14)
	_apply_bar_textures(_fuel_bar)
	box.add_child(_fuel_bar)

	var fire_row := HBoxContainer.new()
	fire_row.add_theme_constant_override("separation", 8)
	box.add_child(fire_row)
	_refuel = Button.new()
	_refuel.text = REFUEL_LABEL
	_refuel.focus_mode = Control.FOCUS_ALL
	_apply_button_textures(_refuel)
	_refuel.pressed.connect(refuel_pressed)
	fire_row.add_child(_refuel)
	_flint = Button.new()
	_flint.text = FLINT_LABEL
	_flint.focus_mode = Control.FOCUS_ALL
	_apply_button_textures(_flint)
	_flint.pressed.connect(flint_pressed)
	fire_row.add_child(_flint)

	_progress = ProgressBar.new()
	_progress.max_value = 1.0
	_progress.show_percentage = false
	_progress.custom_minimum_size = Vector2(0, 14)
	_progress.visible = false
	_apply_bar_textures(_progress)
	box.add_child(_progress)

	_status = Label.new()
	_status.add_theme_font_size_override("font_size", 10)
	_status.add_theme_color_override("font_color", Color(0.9, 0.86, 0.66, 1.0))
	box.add_child(_status)

	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(0, 210)
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	box.add_child(scroll)

	_rows_box = VBoxContainer.new()
	_rows_box.name = "Rows"
	_rows_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_rows_box.add_theme_constant_override("separation", 4)
	scroll.add_child(_rows_box)

	var hint := Label.new()
	hint.text = "Esc / E: tutup"
	hint.add_theme_font_size_override("font_size", 10)
	hint.add_theme_color_override("font_color", Color(0.84, 0.8, 0.72, 1.0))
	box.add_child(hint)


func _apply_bar_textures(bar: ProgressBar) -> void:
	var bg_path := "res://assets/textures/ui/06_bar/bar_track_empty.png"
	var fill_path := "res://assets/textures/ui/06_bar/bar_fill_stamina.png"
	if ResourceLoader.exists(bg_path):
		var bg := StyleBoxTexture.new()
		bg.texture = load(bg_path) as Texture2D
		bg.texture_margin_left = 18.0
		bg.texture_margin_top = 14.0
		bg.texture_margin_right = 18.0
		bg.texture_margin_bottom = 14.0
		bar.add_theme_stylebox_override("background", bg)
	if ResourceLoader.exists(fill_path):
		var fill := StyleBoxTexture.new()
		fill.texture = load(fill_path) as Texture2D
		fill.texture_margin_left = 12.0
		fill.texture_margin_top = 8.0
		fill.texture_margin_right = 12.0
		fill.texture_margin_bottom = 8.0
		fill.expand_margin_left = -3.0
		fill.expand_margin_top = -3.0
		fill.expand_margin_right = -3.0
		fill.expand_margin_bottom = -3.0
		bar.add_theme_stylebox_override("fill", fill)


func _apply_button_textures(btn: Button) -> void:
	var states := {"normal": "normal", "hover": "hover", "pressed": "pressed", "disabled": "disabled"}
	for st in states:
		var path := "res://assets/textures/ui/03_button/button_primary_%s.png" % states[st]
		if ResourceLoader.exists(path):
			var box := StyleBoxTexture.new()
			box.texture = load(path) as Texture2D
			box.texture_margin_left = 14.0
			box.texture_margin_top = 12.0
			box.texture_margin_right = 14.0
			box.texture_margin_bottom = 12.0
			box.content_margin_left = 12.0
			box.content_margin_top = 6.0
			box.content_margin_right = 12.0
			box.content_margin_bottom = 6.0
			btn.add_theme_stylebox_override(st, box)
	btn.add_theme_color_override("font_color", Color(0.968627, 0.945098, 0.898039, 1.0))
