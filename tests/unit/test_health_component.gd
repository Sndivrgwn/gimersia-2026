extends GutTest

var _target: Node2D
var _health: HealthComponent


func before_each() -> void:
	_target = add_child_autofree(Node2D.new())
	_health = HealthComponent.new()
	_health.name = "HealthComponent"
	_target.add_child(_health)
	_health.setup(80.0)


func test_setup_sets_full_hp_and_group() -> void:
	assert_eq(_health.get_max_hp(), 80.0)
	assert_eq(_health.get_current_hp(), 80.0)
	assert_false(_health.is_dead())
	assert_true(_target.is_in_group(&"damageable"))


func test_take_damage_reports_applied_amount_and_clamps() -> void:
	var hit := _health.take_damage(30.0, null)
	assert_eq(hit, 30.0)
	assert_eq(_health.get_current_hp(), 50.0)
	var overkill := _health.take_damage(999.0, null)
	assert_eq(overkill, 50.0)
	assert_true(_health.is_dead())
	assert_eq(_health.take_damage(10.0, null), 0.0, "mati tidak menerima damage lagi")


func test_died_signal_fires_once() -> void:
	watch_signals(_health)
	_health.take_damage(999.0, null)
	_health.take_damage(1.0, null)
	assert_signal_emit_count(_health, "died", 1)


func test_bleed_ticks_and_stops() -> void:
	_health.apply_bleed(2.0, 3.0, null)
	assert_true(_health.is_bleeding())
	_health.tick(1.0)
	assert_eq(_health.get_current_hp(), 78.0)
	_health.tick(2.0)
	assert_eq(_health.get_current_hp(), 74.0)
	assert_false(_health.is_bleeding())
	_health.tick(1.0)
	assert_eq(_health.get_current_hp(), 74.0)


func test_set_max_hp_keeping_ratio() -> void:
	_health.take_damage(40.0, null)
	_health.set_max_hp_keeping_ratio(120.0)
	assert_eq(_health.get_max_hp(), 120.0)
	assert_eq(_health.get_current_hp(), 60.0)
