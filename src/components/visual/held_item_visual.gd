class_name HeldItemVisual
extends Node2D

## Mission 10 Phase 3: item yang dipilih terlihat di tangan pemain.
## Prioritas: slot hotbar terpilih -> senjata terpasang -> tangan kosong.
## Art: assets/held/<id>.png bila ada; kalau tidak, bentuk placeholder per
## kategori (weapon: persegi tipis, consumable: bulat, resource: kotak kecil,
## special/armor/tool: belah ketupat).

const CONFIG_PATH := "res://src/data/configs/held_item_config.tres"
const INVENTORY_NAME := "InventoryComponent"
const SELECTION_NAME := "HotbarSelectionComponent"
const COMBAT_NAME := "CombatComponent"
const INTERACTOR_NAME := "InteractorComponent"
const HELD_DIR := "res://assets/held/"

@export var config: HeldItemConfig
@export var player: Node2D

var selection: HotbarSelectionComponent
var inventory: InventoryComponent
var combat: CombatComponent
var interactor: InteractorComponent

var _shape: Polygon2D
var _sprite: Sprite2D
var _swing_left: float = 0.0
var _use_left: float = 0.0
var _bob_phase: float = 0.0
var _current_id: StringName = &""


func _ready() -> void:
	if config == null:
		config = load(CONFIG_PATH) as HeldItemConfig
	if config == null:
		config = HeldItemConfig.new()
	if player == null:
		player = get_parent() as Node2D
	selection = get_parent().get_node_or_null(SELECTION_NAME) as HotbarSelectionComponent
	inventory = get_parent().get_node_or_null(INVENTORY_NAME) as InventoryComponent
	combat = get_parent().get_node_or_null(COMBAT_NAME) as CombatComponent
	interactor = get_parent().get_node_or_null(INTERACTOR_NAME) as InteractorComponent
	_build()
	_connect_signals()
	refresh()


func _process(delta: float) -> void:
	tick(delta)


## Dipanggil _process dan tes. Semua timer state-pure (kembali ke diam).
func tick(delta: float) -> void:
	if delta <= 0.0:
		return
	_swing_left = maxf(_swing_left - delta, 0.0)
	_use_left = maxf(_use_left - delta, 0.0)
	_bob_phase += delta
	_update_transform()


func refresh() -> void:
	var item := resolve_item()
	_current_id = item.id if item != null else &""
	visible = item != null and not _player_dead()
	if item == null:
		return
	_apply_art(item)
	_update_transform()


## Item yang tampil sekarang (dipakai tes).
func resolve_item() -> ItemDefinition:
	var stacked := selection.get_held_item() if selection != null else null
	if stacked != null:
		return stacked
	if inventory != null:
		return inventory.get_equipped(ItemDefinition.EquipmentSlot.WEAPON)
	return null


func get_current_id() -> StringName:
	return _current_id


func is_holding() -> bool:
	return visible and _current_id != &""


func get_shape_points() -> PackedVector2Array:
	return _shape.polygon if _shape != null else PackedVector2Array()


func get_hand_position() -> Vector2:
	return position


func is_swing_active() -> bool:
	return _swing_left > 0.0


func notify_swing() -> void:
	_swing_left = config.swing_seconds


func notify_use() -> void:
	_use_left = config.use_bob_seconds


# --- Internal ---------------------------------------------------------------

func _build() -> void:
	_shape = Polygon2D.new()
	_shape.name = "Shape"
	_shape.color = Color(0.85, 0.8, 0.6, 1.0)
	add_child(_shape)
	_sprite = Sprite2D.new()
	_sprite.name = "Art"
	_sprite.visible = false
	add_child(_sprite)


func _connect_signals() -> void:
	if selection != null:
		selection.selected_changed.connect(_on_selection_changed)
	if inventory != null:
		inventory.inventory_changed.connect(refresh)
		inventory.slot_changed.connect(_on_slot_changed)
		inventory.equipment_changed.connect(_on_equipment_changed)
	if combat != null:
		combat.swing.connect(_on_swing)
	if interactor != null:
		interactor.progress_changed.connect(_on_progress_changed)


func _on_selection_changed(_index: int, _stack: ItemStack) -> void:
	refresh()


func _on_slot_changed(_index: int) -> void:
	refresh()


func _on_equipment_changed(_slot: int) -> void:
	refresh()


func _on_swing(_aim: Vector2, _hits: int) -> void:
	notify_swing()


func _on_progress_changed(ratio: float) -> void:
	if ratio > 0.0:
		refresh()


## Ikon item dari UI (fallback) memakai kotak tangan apa adanya (hand_size),
## jadi ukurannya kecil, sebesar tangan.
const ICON_HAND_SCALE := 1.0


func _apply_art(item: ItemDefinition) -> void:
	var texture := _load_held_texture(item.id)
	var from_icon := false
	if texture == null:
		# Tidak ada art khusus di assets/held/: pakai ikon item dari UI.
		texture = item.get_icon()
		from_icon = texture != null
	_sprite.visible = texture != null
	if texture != null:
		_sprite.texture = texture
		var size := texture.get_size()
		if size.x > 0.0 and size.y > 0.0:
			var target := config.hand_size * (ICON_HAND_SCALE if from_icon else 1.0)
			# Ikon dijaga proporsional; art held khusus mengikuti kotak tangan.
			if from_icon:
				var uniform := minf(target.x / size.x, target.y / size.y)
				_sprite.scale = Vector2(uniform, uniform)
			else:
				_sprite.scale = Vector2(target.x / size.x, target.y / size.y)
		if from_icon:
			# Polygon tetap disiapkan (fallback/tes), tapi disembunyikan di balik ikon.
			_shape.polygon = _placeholder_polygon(item.category)
			_shape.visible = false
		else:
			_shape.polygon = PackedVector2Array()
			_shape.visible = true
		return
	_shape.visible = true
	_shape.polygon = _placeholder_polygon(item.category)


func _load_held_texture(item_id: StringName) -> Texture2D:
	var path := HELD_DIR + String(item_id) + ".png"
	if not ResourceLoader.exists(path):
		return null
	return load(path) as Texture2D


## Bentuk placeholder per kategori (dipakai tes).
static func _placeholder_polygon(category: int) -> PackedVector2Array:
	match category:
		ItemDefinition.Category.WEAPON:
			return PackedVector2Array([
				Vector2(-8.0, -2.0), Vector2(8.0, -2.0), Vector2(8.0, 2.0), Vector2(-8.0, 2.0),
			])
		ItemDefinition.Category.CONSUMABLE:
			return _circle(4.0)
		ItemDefinition.Category.RESOURCE:
			return PackedVector2Array([
				Vector2(-4.0, -4.0), Vector2(4.0, -4.0), Vector2(4.0, 4.0), Vector2(-4.0, 4.0),
			])
		_:
			return PackedVector2Array([
				Vector2(0.0, -6.0), Vector2(6.0, 0.0), Vector2(0.0, 6.0), Vector2(-6.0, 0.0),
			])


static func _circle(radius: float, steps: int = 10) -> PackedVector2Array:
	var points := PackedVector2Array()
	for index in steps:
		var angle := TAU * float(index) / float(steps)
		points.append(Vector2(cos(angle), sin(angle)) * radius)
	return points


func _facing() -> Vector2:
	if player != null and ("facing_direction" in player):
		var facing: Vector2 = player.facing_direction
		if facing != Vector2.ZERO:
			return facing.normalized()
	return Vector2.DOWN


func _update_transform() -> void:
	if player == null:
		return
	var facing := _facing()
	var offset := config.hand_offset_down
	if facing.y < -0.5:
		offset = config.hand_offset_up
	elif facing.x < -0.5:
		offset = config.hand_offset_left
	elif facing.x > 0.5:
		offset = config.hand_offset_right
	var bob := 0.0
	if player is CharacterBody2D and (player as CharacterBody2D).velocity.length() > 1.0:
		bob = sin(_bob_phase * TAU * 2.0) * config.walk_bob
	position = offset + Vector2(0.0, bob - _use_left * 2.0)
	z_index = -1 if facing.y < -0.5 else 1
	rotation = 0.0
	if _swing_left > 0.0:
		var progress := 1.0 - (_swing_left / maxf(config.swing_seconds, 0.001))
		rotation = deg_to_rad(lerpf(-config.swing_arc_degrees, config.swing_arc_degrees, progress))
	if facing.x < -0.5:
		scale.x = -1.0
	else:
		scale.x = 1.0


func _player_dead() -> bool:
	if player == null:
		return false
	var stats := player.get_node_or_null("StatsComponent") as StatsComponent
	return stats != null and float(stats.get("current_hp")) <= 0.0
