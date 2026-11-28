class_name PlayerLight
extends Node2D

## Fase 1C: cahaya pemain saat malam (PointLight2D).
##
## Radius 110 px; kalau Obor ada di slot hotbar terpilih, radius naik ke 190 px.
## Energi mengikuti `DayNightVisual.get_world_darkness()` (0 siang, 1 malam) jadi
## cahaya muncul halus saat senja dan padam saat fajar, tanpa mengubah
## CanvasModulate yang sudah ada.

const CONFIG_PATH := "res://src/data/configs/player_light_config.tres"
const VISUAL_GROUP := &"day_night_visual"
const INVENTORY_NAME := "InventoryComponent"
const HOTBAR_NAME := "HotbarSelectionComponent"
const LIGHT_NAME := "Light"

@export var config: PlayerLightConfig
@export var inventory: InventoryComponent
## Node pemilih hotbar (punya `get_held_item()`); default anak Player.
@export var hotbar: Node

var _light: PointLight2D
var _texture: GradientTexture2D


func _ready() -> void:
	if config == null:
		config = load(CONFIG_PATH) as PlayerLightConfig
	_build()
	_bind()
	tick()


func _process(delta: float) -> void:
	tick(delta)


func tick(_delta: float = 0.0) -> void:
	if _light == null:
		return
	_bind()
	var radius := get_radius()
	var width := maxf(float(_texture.get_width()), 1.0)
	_light.texture_scale = (radius * 2.0) / width
	_light.visible = radius > 0.0
	_light.energy = get_energy(get_world_darkness())


# --- API --------------------------------------------------------------------

## Radius aktif: Obor di slot terpilih -> `torch_radius`, selain itu
## `player_radius`.
func get_radius() -> float:
	if config == null:
		return 0.0
	return config.torch_radius if is_torch_active() else config.player_radius


## Energi untuk tingkat kegelapan 0..1 (0 = siang, 1 = malam).
func get_energy(darkness: float) -> float:
	if config == null:
		return 0.0
	var energy := lerpf(config.day_energy, config.night_energy, clampf(darkness, 0.0, 1.0))
	if is_torch_active():
		energy += config.torch_energy_bonus
	return maxf(energy, 0.0)


func is_torch_active() -> bool:
	if config == null or config.torch_item == null:
		return false
	var held := get_held_item()
	if held != null and held.id == config.torch_item.id:
		return true
	var parent := get_parent()
	if parent != null:
		var status := parent.get_node_or_null("StatusEffectsComponent") as StatusEffectsComponent
		if status != null and status.is_active(StatusEffectsComponent.TORCH_EFFECT_ID):
			return true
	return false


func get_held_item() -> ItemDefinition:
	if hotbar != null and hotbar.has_method(&"get_held_item"):
		return hotbar.get_held_item() as ItemDefinition
	if inventory == null:
		return null
	return inventory.get_slot_item(0)


## 0 siang terang, 1 malam; dibaca dari DayNightVisual (satu-satunya
## CanvasModulate).
func get_world_darkness() -> float:
	var tree := get_tree()
	if tree == null:
		return 0.0
	var visual := tree.get_first_node_in_group(VISUAL_GROUP)
	if visual != null and visual.has_method(&"get_world_darkness"):
		return clampf(float(visual.call(&"get_world_darkness")), 0.0, 1.0)
	return 0.0


func get_light_node() -> PointLight2D:
	return _light


# --- Internal ---------------------------------------------------------------

func _bind() -> void:
	var parent := get_parent()
	if parent == null:
		return
	if inventory == null:
		inventory = parent.get_node_or_null(INVENTORY_NAME) as InventoryComponent
	if hotbar == null:
		hotbar = parent.get_node_or_null(HOTBAR_NAME)


func _build() -> void:
	_texture = GradientTexture2D.new()
	var gradient := Gradient.new()
	gradient.set_color(0, Color(1.0, 1.0, 1.0, 1.0))
	gradient.set_color(1, Color(1.0, 1.0, 1.0, 0.0))
	_texture.gradient = gradient
	_texture.fill = GradientTexture2D.FILL_RADIAL
	_texture.fill_from = Vector2(0.5, 0.5)
	_texture.fill_to = Vector2(1.0, 0.5)
	_texture.width = 256
	_texture.height = 256

	_light = PointLight2D.new()
	_light.name = LIGHT_NAME
	_light.texture = _texture
	_light.color = config.color if config != null else Color(1.0, 0.86, 0.62, 1.0)
	_light.energy = 0.0
	_light.shadow_enabled = false
	# Jangkau SunSweepOverlay (layer 2) agar cahaya pemain/obor tidak tertutup gelap senja.
	_light.range_layer_max = SunSweepOverlay.LAYER
	add_child(_light)
