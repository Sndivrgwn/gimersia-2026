class_name ItemPickup
extends Area2D

## Pickup item di dunia. Body di grup "player" yang menyentuh area ini
## memasukkan item-nya ke InventoryComponent. Sisa yang tidak muat tetap di
## pickup. Pickup diabaikan selama `pickup_delay` sejak spawn supaya item yang
## baru dijatuhkan tidak langsung terambil lagi.

const DEFAULT_CONFIG: InventoryConfig = preload("res://src/data/configs/inventory_config.tres")
const PLAYER_GROUP := &"player"

## Definisi item yang dibawa. Wajib diisi di scene.
@export var item: ItemDefinition
## Jumlah yang dibawa. Sisa yang tidak muat dikembalikan ke sini.
@export var count: int = 1
## Tuning; null berarti memakai InventoryConfig() bawaan.
@export var config: InventoryConfig = DEFAULT_CONFIG

var _elapsed: float = 0.0

@onready var _shape: CollisionShape2D = get_node_or_null("CollisionShape2D") as CollisionShape2D
@onready var _count_label: Label = get_node_or_null("Count") as Label


func _ready() -> void:
	_apply_config()
	if not body_entered.is_connected(_on_body_entered):
		body_entered.connect(_on_body_entered)
	_refresh_visual()


func _process(delta: float) -> void:
	if not is_pickup_ready():
		_elapsed += delta


func get_pickup_delay() -> float:
	return config.pickup_delay if config != null else 0.0


func is_pickup_ready() -> bool:
	return _elapsed >= get_pickup_delay()


func _on_body_entered(body: Node) -> void:
	if item == null or body == null or not is_pickup_ready():
		return
	if not body.is_in_group(PLAYER_GROUP):
		return

	var inventory := body.get_node_or_null("InventoryComponent") as InventoryComponent
	if inventory == null:
		return

	var leftover := inventory.add_item(item, count)
	if leftover <= 0:
		count = 0
		queue_free()
		return
	count = leftover
	_refresh_visual()


func _apply_config() -> void:
	if config == null or _shape == null:
		return
	var circle := _shape.shape as CircleShape2D
	if circle == null:
		return
	var resized := circle.duplicate() as CircleShape2D
	resized.radius = config.pickup_radius
	_shape.shape = resized


func _refresh_visual() -> void:
	if _count_label != null:
		_count_label.text = "x%d" % count
	_refresh_icon()


## Ikon item dari assets/icons/items/<id>.png bila ada; polygon lama disembunyikan.
func _refresh_icon() -> void:
	if item == null:
		return
	var texture := Assets.item_icon(item.id)
	if texture == null:
		return
	var sprite := get_node_or_null("Icon") as Sprite2D
	if sprite == null:
		sprite = Sprite2D.new()
		sprite.name = "Icon"
		sprite.z_index = 1
		sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		add_child(sprite)
	sprite.texture = texture
	var visual := get_node_or_null("Visual") as CanvasItem
	if visual != null:
		visual.visible = false
