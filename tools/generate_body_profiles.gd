extends SceneTree

## Mission 10 Phase 4: menulis profil massa player/boar/deer.
## Jalankan: GODOT --headless --path . -s tools/generate_body_profiles.gd

const ProfileScript = preload("res://src/data/resources/physics/body_profile.gd")
const OUT := "res://src/data/configs/physics/"

## Radius = radius CircleShape2D di scene masing-masing (player 12, babi 12,
## rusa 10). Layer/mask mencerminkan matriks Mission 10: pemain di
## WORLD|PLAYER_BODY dan bertabrakan dengan WORLD|FAUNA_BODY (bukan pagar);
## fauna di FAUNA_BODY dan bertabrakan dengan WORLD|FENCE|FAUNA_BODY|PLAYER_BODY.
const PROFILES: Array = [
	{"id": &"player", "mass": 0, "radius": 12.0, "layer": 5, "mask": 3, "blocks": true, "kb": 1.0},
	{"id": &"wild_boar", "mass": 2, "radius": 12.0, "layer": 2, "mask": 15, "blocks": true, "kb": 0.35},
	{"id": &"island_deer", "mass": 1, "radius": 10.0, "layer": 2, "mask": 15, "blocks": true, "kb": 0.6},
]


func _init() -> void:
	DirAccess.make_dir_recursive_absolute(OUT)
	for entry in PROFILES:
		var profile := ProfileScript.new()
		profile.id = entry["id"]
		profile.mass_class = entry["mass"]
		profile.radius = entry["radius"]
		profile.collision_layer = entry["layer"]
		profile.collision_mask = entry["mask"]
		profile.blocks_player = entry["blocks"]
		profile.knockback_taken_multiplier = entry["kb"]
		profile.pushable_by_others = false
		var path := ""
		match entry["id"]:
			&"player":
				path = "res://src/data/configs/physics/body_player.tres"
			&"wild_boar":
				path = "res://src/data/configs/physics/body_wild_boar.tres"
			_:
				path = "res://src/data/configs/physics/body_island_deer.tres"
		if ResourceSaver.save(profile, path) != OK:
			printerr("generate_body_profiles: gagal menulis %s" % path)
			quit(1)
			return
		print("generate_body_profiles: %s" % path)
	quit(0)
