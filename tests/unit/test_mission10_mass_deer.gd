extends GutTest

## Mission 10 Phase 4: profil massa per body dan jaminan first-hit rusa.

const DEER_SCENE: PackedScene = preload("res://src/entities/fauna/island_deer/island_deer.tscn")
const PLAYER_PROFILE: BodyProfile = preload("res://src/data/configs/physics/body_player.tres")
const BOAR_PROFILE: BodyProfile = preload("res://src/data/configs/physics/body_wild_boar.tres")
const DEER_PROFILE: BodyProfile = preload("res://src/data/configs/physics/body_island_deer.tres")


func test_profiles_have_expected_mass_and_knockback() -> void:
	assert_eq(PLAYER_PROFILE.id, &"player")
	assert_eq(BOAR_PROFILE.mass_class, BodyProfile.MassClass.HEAVY)
	assert_almost_eq(BOAR_PROFILE.knockback_taken_multiplier, 0.35, 0.01)
	assert_almost_eq(DEER_PROFILE.knockback_taken_multiplier, 0.6, 0.01)
	assert_false(BOAR_PROFILE.pushable_by_others, "tidak ada body yang bisa didorong")
	assert_true(DEER_PROFILE.blocks_player, "pemain tidak menembus rusa")


func test_applier_attaches_profile_to_body() -> void:
	var body := CharacterBody2D.new()
	add_child_autofree(body)
	BodyProfileApplier.apply(body, DEER_PROFILE, true)
	assert_eq(BodyProfileApplier.profile_of(body), DEER_PROFILE)
	assert_eq(body.collision_layer, DEER_PROFILE.collision_layer)
	assert_eq(body.collision_mask, DEER_PROFILE.collision_mask)
	assert_almost_eq(BodyProfileApplier.knockback_multiplier(body), 0.6, 0.01)
	assert_almost_eq(BodyProfileApplier.knockback_multiplier(null, 1.5), 1.5, 0.01)


func test_deer_enters_startle_after_alert_and_then_flees() -> void:
	var deer := DEER_SCENE.instantiate() as IslandDeer
	add_child_autofree(deer)
	var config := deer._deer_config()
	deer.state = IslandDeer.State.ALERT
	deer._alert_remaining = 0.0
	deer._tick_alert(config, 0.016)
	assert_eq(deer.get_state(), IslandDeer.State.STARTLE, "waspada berakhir -> STARTLE, bukan langsung kabur")
	assert_almost_eq(deer.get_startle_remaining(), config.startle_seconds, 0.01)
	assert_true(deer.is_startling())

	deer._tick_startle(config, config.startle_seconds * 0.5, Vector2.ZERO)
	assert_eq(deer.get_state(), IslandDeer.State.STARTLE, "masih terpaku setengah timer")
	deer._tick_startle(config, config.startle_seconds, Vector2.ZERO)
	assert_eq(deer.get_state(), IslandDeer.State.FLEE, "timer habis -> kabur")


func test_deer_config_has_startle_and_sneak_floor() -> void:
	var deer := DEER_SCENE.instantiate() as IslandDeer
	add_child_autofree(deer)
	var config := deer._deer_config()
	assert_almost_eq(config.startle_seconds, 0.9, 0.01)
	assert_almost_eq(config.flee_accel_seconds, 0.5, 0.01)
	assert_almost_eq(config.sneak_notice_floor_px, 24.0, 0.01)
