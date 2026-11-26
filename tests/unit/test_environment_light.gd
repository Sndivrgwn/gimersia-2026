extends GutTest

## Kunang-kunang hanya di atmosfer NIGHT, dan PointLight2D api unggun mengikuti
## kegelapan tint dunia (siang redup, malam penuh).

const VISUAL_SCENE: PackedScene = preload("res://src/levels/components/environment/day_night_visual.tscn")
const CAMPFIRE_SCENE: PackedScene = preload("res://src/entities/camp/campfire/campfire.tscn")


class StubDarkness extends Node:
	var darkness := 0.0

	func get_world_darkness() -> float:
		return darkness


func test_fireflies_are_night_only() -> void:
	var visual := VISUAL_SCENE.instantiate() as DayNightVisual
	add_child_autofree(visual)
	await wait_frames(1)

	var fireflies := visual.get_node("Effects/Fireflies") as CPUParticles2D
	var motes := visual.get_node("Effects/DayMotes") as CPUParticles2D

	visual.call(&"_update_effects", DayNightVisualConfig.Atmosphere.EVENING)
	assert_false(fireflies.emitting, "senja masih terang: tanpa kunang-kunang")
	assert_true(motes.emitting, "partikel siang tetap tampil saat senja")

	visual.call(&"_update_effects", DayNightVisualConfig.Atmosphere.NIGHT)
	assert_true(fireflies.emitting, "malam: kunang-kunang aktif")
	assert_false(motes.emitting, "malam: partikel siang mati")

	visual.call(&"_update_effects", DayNightVisualConfig.Atmosphere.DAY)
	assert_false(fireflies.emitting, "siang: tidak ada kunang-kunang")
	assert_true(motes.emitting)


func test_campfire_light_dims_during_day() -> void:
	var stub := StubDarkness.new()
	stub.add_to_group(&"day_night_visual")
	add_child_autofree(stub)

	var fire := CAMPFIRE_SCENE.instantiate() as Campfire
	add_child_autofree(fire)
	fire.set_fuel(120.0)
	assert_true(fire.ignite(), "api menyala untuk tes")
	fire.tick(1.0)

	stub.darkness = 0.0
	fire.call(&"_refresh_light")
	var day_energy := fire.get_light().energy

	stub.darkness = 1.0
	fire.call(&"_refresh_light")
	var night_energy := fire.get_light().energy

	assert_almost_eq(day_energy, fire.config.light_energy_day, 0.001, "siang: cahaya redup")
	assert_almost_eq(night_energy, fire.config.light_energy_night, 0.001, "malam: cahaya penuh")
	assert_lt(day_energy, night_energy * 0.5, "cahaya siang jauh lebih lemah")
