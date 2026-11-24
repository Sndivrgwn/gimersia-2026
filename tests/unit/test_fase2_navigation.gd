extends GutTest

## Fase 2: panah base (2A), penanda tas jatuh (2B), indikator target auto-attack
## dan bar HP hewan (2C).

const CAMP_ARROW_SCRIPT := preload("res://src/ui/hud/compass/camp_arrow.gd")
const LOOT_ARROW_SCRIPT := preload("res://src/ui/hud/compass/loot_arrow.gd")
const COMPASS_CONFIG: CompassConfig = preload("res://src/data/configs/compass_config.tres")
const BOAR_SCENE: PackedScene = preload("res://src/entities/fauna/wild_boar/wild_boar.tscn")


class StubAnchor extends Node:
	var center: Vector2 = Vector2.ZERO
	var founded := true

	func get_center() -> Vector2:
		return center

	func is_founded() -> bool:
		return founded


class StubBag extends Node2D:
	pass


class StubTarget extends Node2D:
	var health: HealthComponent

	func _ready() -> void:
		health = HealthComponent.new()
		health.name = "HealthComponent"
		add_child(health)
		health.setup(40.0)

	func can_be_auto_targeted() -> bool:
		return true


var _anchor: StubAnchor
var _player: Node2D
var _bag: StubBag


func before_each() -> void:
	_anchor = StubAnchor.new()
	_anchor.name = "CampAnchorStub"
	_anchor.add_to_group(CampAnchor.GROUP)
	add_child_autofree(_anchor)
	_player = Node2D.new()
	_player.name = "PlayerStub"
	_player.add_to_group(&"player")
	add_child_autofree(_player)


func after_each() -> void:
	if _bag != null and is_instance_valid(_bag):
		_bag.queue_free()
	_bag = null


# --- 2A: panah ke base ------------------------------------------------------

func test_camp_arrow_uses_camp_anchor_center() -> void:
	assert_almost_eq(COMPASS_CONFIG.camp_arrow_distance, 600.0, 0.01, "ambang dari config")
	_anchor.center = Vector2(6000.0, 0.0)

	var arrow := CAMP_ARROW_SCRIPT.new()
	add_child_autofree(arrow)
	arrow.call(&"refresh")
	assert_true(arrow.call(&"is_showing"), "panah muncul saat jauh dari base")
	assert_string_contains(arrow.call(&"get_text"), "Base")
	assert_string_contains(arrow.call(&"get_text"), "→")

	_player.global_position = Vector2(6000.0 - 100.0, 0.0)
	arrow.call(&"refresh")
	assert_false(arrow.call(&"is_showing"), "panah hilang saat base sudah dekat")


func test_camp_arrow_hidden_before_base_founded() -> void:
	_anchor.founded = false
	_anchor.center = Vector2(6000.0, 0.0)
	var arrow := CAMP_ARROW_SCRIPT.new()
	add_child_autofree(arrow)
	arrow.call(&"refresh")
	assert_false(arrow.call(&"is_showing"), "belum ada base: BaseHUD yang memandu")


# --- 2B: penanda tas jatuh --------------------------------------------------

func test_loot_arrow_follows_bag_until_taken() -> void:
	_bag = StubBag.new()
	_bag.name = "StubBag"
	_bag.add_to_group(&"loot_bag")
	add_child_autofree(_bag)
	_bag.global_position = _player.global_position + Vector2(0.0, 400.0)

	var arrow := LOOT_ARROW_SCRIPT.new()
	add_child_autofree(arrow)
	arrow.call(&"refresh")
	assert_true(arrow.call(&"is_showing"), "penanda tas muncul")
	assert_string_contains(arrow.call(&"get_text"), "Tas")
	assert_string_contains(arrow.call(&"get_text"), "↓")

	_bag.queue_free()
	_bag = null
	arrow.call(&"refresh")
	assert_false(arrow.call(&"is_showing"), "tas diambil: penanda hilang")


func test_loot_arrow_hidden_when_bag_is_underfoot() -> void:
	_bag = StubBag.new()
	_bag.add_to_group(&"loot_bag")
	add_child_autofree(_bag)
	_bag.global_position = _player.global_position + Vector2(10.0, 0.0)

	var arrow := LOOT_ARROW_SCRIPT.new()
	add_child_autofree(arrow)
	arrow.call(&"refresh")
	assert_false(arrow.call(&"is_showing"), "tas di dekat kaki tidak perlu panah")


# --- 2C: indikator target ---------------------------------------------------

func test_target_indicator_follows_auto_target() -> void:
	var player := Node2D.new()
	add_child_autofree(player)
	var stats := StatsComponent.new()
	stats.name = "StatsComponent"
	player.add_child(stats)
	var combat := CombatComponent.new()
	combat.name = "CombatComponent"
	combat.ignore_ui_guard = true
	player.add_child(combat)
	var indicator := TargetIndicator.new()
	indicator.name = "TargetIndicator"
	player.add_child(indicator)

	var target := StubTarget.new()
	add_child_autofree(target)
	target.global_position = Vector2(20.0, 0.0)

	combat.tick(0.0)
	indicator.tick(0.0)
	assert_eq(combat.get_auto_target(), target, "target auto-attack terdeteksi")
	assert_eq(indicator.get_target(), target)
	assert_true(indicator.is_showing(), "penanda target tampil")

	target.global_position = Vector2(400.0, 0.0)
	combat.tick(0.0)
	indicator.tick(0.0)
	assert_null(indicator.get_target(), "target keluar jangkauan: penanda hilang")
	assert_false(indicator.is_showing())


# --- 2C: bar HP hewan -------------------------------------------------------

func test_fauna_hp_bar_hides_after_timeout() -> void:
	var boar := BOAR_SCENE.instantiate() as WildBoar
	add_child_autofree(boar)
	boar.ensure_ready()
	var bar := boar.get_hp_bar()
	assert_not_null(bar, "bar HP fauna ada")
	assert_false(bar.visible, "bar HP tersembunyi saat HP penuh")

	var hide_after: float = boar.config.hp_bar_hide_seconds
	assert_gt(hide_after, 0.0, "durasi dari config")
	boar.get_health().take_damage(5.0, null)
	assert_true(bar.visible, "bar muncul setelah terkena damage")

	boar.tick(hide_after * 0.5)
	assert_true(bar.visible, "masih tampil sebelum ambang")
	boar.tick(hide_after)
	assert_false(bar.visible, "bar hilang setelah beberapa detik tanpa serangan")
	assert_lt(boar.get_health().get_ratio(), 1.0, "HP memang masih terluka")
