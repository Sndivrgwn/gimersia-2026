extends SceneTree

## Mission 10 Phase 4: menulis ulang config fauna dengan angka startle/ramp baru.
## Jalankan: GODOT --headless --path . -s tools/generate_fauna_configs.gd

const BoarScript = preload("res://src/data/resources/fauna/boar_config.gd")
const DeerScript = preload("res://src/data/resources/fauna/deer_config.gd")

const BOAR_PATH := "res://src/data/configs/fauna/boar_config.tres"
const DEER_PATH := "res://src/data/configs/fauna/deer_config.tres"


func _init() -> void:
	var boar := BoarScript.new()
	boar.max_hp = 80.0
	boar.move_speed_day = 115.0
	boar.move_speed_night = 150.0
	boar.wander_speed_factor = 0.5
	boar.wander_radius = 200.0
	boar.wander_pause_min = 2.0
	boar.wander_pause_max = 5.0
	boar.flee_despawn_distance = 600.0
	boar.flee_despawn_timeout = 8.0
	boar.blocks_player = true
	boar.knockback_resistance = 0.35
	boar.contact_stop_extra = 2.0
	if ResourceSaver.save(boar, BOAR_PATH) != OK:
		printerr("generate_fauna_configs: gagal menulis %s" % BOAR_PATH)
		quit(1)
		return
	_force_fields(BOAR_PATH, {
		"max_hp": "80.0",
		"move_speed_day": "115.0",
		"move_speed_night": "150.0",
		"wander_speed_factor": "0.5",
		"wander_radius": "200.0",
		"wander_pause_min": "2.0",
		"wander_pause_max": "5.0",
		"flee_despawn_distance": "600.0",
		"flee_despawn_timeout": "8.0",
		"blocks_player": "true",
		"knockback_resistance": "0.35",
		"contact_stop_extra": "2.0",
		"smart_chase_enabled": "true",
		"separation_radius_px": "48.0",
		"separation_weight": "1.2",
		"max_simultaneous_attackers": "2",
		"circle_radius_px": "140.0",
		"circle_speed_factor": "0.7",
		"approach_slot_count": "5",
		"windup_seconds": "0.45",
		"recovery_seconds": "0.6",
		"attack_cooldown_min": "1.2",
		"attack_cooldown_max": "2.2",
		"reaction_delay_max": "0.35",
		"boar_charge_speed_multiplier": "2.6",
		"boar_charge_distance_px": "220.0",
		"boar_overshoot_px": "40.0",
		"lose_aggro_distance_px": "600.0",
	})

	var deer := DeerScript.new()
	deer.max_hp = 40.0
	deer.move_speed_day = 60.0
	deer.move_speed_night = 60.0
	deer.wander_speed_factor = 1.0
	deer.wander_radius = 200.0
	deer.wander_pause_min = 2.0
	deer.wander_pause_max = 5.0
	deer.flee_despawn_distance = 600.0
	deer.flee_despawn_timeout = 8.0
	deer.blocks_player = true
	deer.knockback_resistance = 0.6
	deer.contact_stop_extra = 2.0
	deer.flee_speed = 175.0
	deer.flee_trigger_radius = 130.0
	deer.flee_duration = 5.0
	deer.alert_radius_factor = 1.25
	deer.alert_time = 0.45
	deer.startle_seconds = 0.9
	deer.flee_accel_seconds = 0.5
	deer.sneak_notice_floor_px = 24.0
	deer.hit_stun = 0.35
	if ResourceSaver.save(deer, DEER_PATH) != OK:
		printerr("generate_fauna_configs: gagal menulis %s" % DEER_PATH)
		quit(1)
		return
	_force_fields(DEER_PATH, {
		"max_hp": "40.0",
		"move_speed_day": "60.0",
		"move_speed_night": "60.0",
		"wander_speed_factor": "1.0",
		"wander_radius": "200.0",
		"wander_pause_min": "2.0",
		"wander_pause_max": "5.0",
		"flee_despawn_distance": "600.0",
		"flee_despawn_timeout": "8.0",
		"blocks_player": "true",
		"knockback_resistance": "0.6",
		"contact_stop_extra": "2.0",
		"flee_speed": "175.0",
		"flee_trigger_radius": "130.0",
		"flee_duration": "5.0",
		"alert_radius_factor": "1.25",
		"alert_time": "0.45",
		"startle_seconds": "0.9",
		"flee_accel_seconds": "0.5",
		"sneak_notice_floor_px": "24.0",
		"hit_stun": "0.35",
	})
	print("generate_fauna_configs: %s dan %s diperbarui" % [BOAR_PATH, DEER_PATH])
	quit(0)


## ResourceSaver menghilangkan properti yang sama dengan default script. Paksa
## semua angka tampil di .tres supaya bisa di-tune dari Inspector.
func _force_fields(path: String, values: Dictionary) -> void:
	var text := FileAccess.get_file_as_string(path)
	if text.is_empty():
		return
	for key in values:
		if text.contains("%s = " % key):
			continue
		text = text + "%s = %s\n" % [key, values[key]]
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file != null:
		file.store_string(text)
		file.close()
