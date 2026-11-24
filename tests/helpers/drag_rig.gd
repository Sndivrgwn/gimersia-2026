class_name DragRig
extends Node

## Mission 11 (Block A): reproduksi "fauna keseret" memakai scene SUNGGUHAN
## (player.tscn, wild_boar.tscn, island_deer.tscn) di atas lantai datar.
##
## Rig ini hanya alat tes. Eksperimen E1..E6 adalah toggle LOKAL di rig, bukan
## kode produksi. Gerak pemain selalu lewat jalur input asli
## (Input.action_press -> Player._physics_process -> move_and_slide).

const PLAYER_SCENE: PackedScene = preload("res://src/entities/player/player.tscn")
const BOAR_SCENE: PackedScene = preload("res://src/entities/fauna/wild_boar/wild_boar.tscn")
const DEER_SCENE: PackedScene = preload("res://src/entities/fauna/island_deer/island_deer.tscn")

const DELTA := 1.0 / 60.0
const FLOOR_HALF := 3000.0
## Tiap skenario dapat arena sendiri supaya sisa body skenario sebelumnya
## (queue_free tertunda) tidak pernah menyentuh skenario berikutnya.
const ARENA_SPACING := 8000.0
const WALL_SIZE := Vector2(20.0, 400.0)

const DIRS := {
	&"right": Vector2.RIGHT,
	&"left": Vector2.LEFT,
	&"up": Vector2.UP,
	&"down": Vector2.DOWN,
}

## Jam netral: hanya untuk hari/malam, tidak menyentuh fisika.
class StubClock extends Node:
	func is_night() -> bool:
		return false

	func is_day() -> bool:
		return true

	func get_current_day() -> int:
		return 1

	func get_time_scale() -> float:
		return 1.0


var player: Player
var animal: FaunaBase
var clock: StubClock
var wall: StaticBody2D
## Sampel per frame fisika (lihat `_record_frame`).
var samples: Array[Dictionary] = []
## Toggle eksperimen: floating, no_separation, no_ai, sym_mask, ...
var toggles: Dictionary = {}

var _floor: StaticBody2D
var _held_actions: Array[StringName] = []
var _kind: StringName = &"boar"
var _case_index: int = 0
## Titik tengah arena skenario aktif.
var origin: Vector2 = Vector2.ZERO


func _ready() -> void:
	InputSetup.ensure_actions()


## Bangun dunia datar + pemain + satu fauna. `offset` = posisi fauna relatif
## titik tengah. Pemain diletakkan 1 px sebelum jarak kontak di arah `dir`.
func setup(kind: StringName, offset: Vector2 = Vector2.ZERO, dir: Vector2 = Vector2.RIGHT, with_wall: bool = false) -> void:
	_kind = kind
	clock = StubClock.new()
	add_child(clock)
	# Top-down: lantai = ruang kosong. Yang dipasang hanya batas tipis di
	# sekeliling arena supaya layer WORLD tetap punya kolisi nyata. Kotak padat
	# besar TIDAK dipakai: body di dalamnya akan terlempar keluar oleh depenetrasi.
	_floor = StaticBody2D.new()
	_floor.name = "Floor"
	_floor.collision_layer = PhysicsLayers.WORLD
	_floor.collision_mask = 0
	for direction in [Vector2.RIGHT, Vector2.LEFT, Vector2.UP, Vector2.DOWN]:
		var boundary := CollisionShape2D.new()
		var boundary_box := RectangleShape2D.new()
		var horizontal := absf(direction.y) < 0.5
		boundary_box.size = Vector2(2.0, FLOOR_HALF * 2.0) if horizontal else Vector2(FLOOR_HALF * 2.0, 2.0)
		boundary.shape = boundary_box
		boundary.position = direction * FLOOR_HALF
		_floor.add_child(boundary)
	add_child(_floor)

	origin = offset
	player = PLAYER_SCENE.instantiate() as Player
	add_child(player)
	player.add_to_group(&"player")
	player.global_position = offset - dir * (24.0 + 1.0)

	spawn_animal(kind, offset)

	if with_wall:
		wall = StaticBody2D.new()
		wall.name = "BackWall"
		wall.collision_layer = PhysicsLayers.WORLD
		wall.collision_mask = 0
		var wall_shape := CollisionShape2D.new()
		var wall_box := RectangleShape2D.new()
		wall_box.size = WALL_SIZE
		wall_shape.shape = wall_box
		wall.add_child(wall_shape)
		wall.position = offset + dir * (get_animal_radius() + WALL_SIZE.x * 0.5)
		add_child(wall)


## Siapkan ulang satu skenario TANPA membuat ulang lantai/pemain.
func reset_case(kind: StringName, dir: Vector2, with_wall: bool = false, lateral: float = 0.0) -> void:
	release_input()
	samples.clear()
	_case_index += 1
	origin = Vector2(ARENA_SPACING * _case_index, 0.0)
	_floor.global_position = origin
	player.global_position = origin - dir * (24.0 + 1.0) + dir.orthogonal() * lateral
	player.velocity = Vector2.ZERO
	player._knockback_remaining = 0.0
	player._knockback_velocity = Vector2.ZERO
	spawn_animal(kind, origin)
	if wall != null and is_instance_valid(wall):
		wall.free()
		wall = null
	if with_wall:
		wall = StaticBody2D.new()
		wall.name = "BackWall"
		wall.collision_layer = PhysicsLayers.WORLD
		wall.collision_mask = 0
		var wall_shape := CollisionShape2D.new()
		var wall_box := RectangleShape2D.new()
		wall_box.size = WALL_SIZE
		wall_shape.shape = wall_box
		wall.add_child(wall_shape)
		wall.global_position = origin + dir * (get_animal_radius() + WALL_SIZE.x * 0.5)
		add_child(wall)


func spawn_animal(kind: StringName, offset: Vector2) -> FaunaBase:
	if animal != null and is_instance_valid(animal):
		# Bebaskan segera: queue_free masih hidup satu frame dan bisa menggeser
		# body baru lewat BodySeparation.
		animal.free()
	animal = (BOAR_SCENE if kind == &"boar" else DEER_SCENE).instantiate() as FaunaBase
	animal.player = player
	animal.clock = clock
	add_child(animal)
	animal.global_position = offset
	animal.ensure_ready()
	animal.set_physics_process(true)
	return animal


## Paksa state fauna. State yang dikenal: idle, passive, alert, startle,
## hostile_chase. `idle` = WANDER tanpa gerak (NEUTRAL di siang hari).
func force_state(state: StringName) -> void:
	if animal == null:
		return
	animal.velocity = Vector2.ZERO
	if animal is WildBoar:
		var boar := animal as WildBoar
		boar.forced_hostile = false
		boar._wander_pause = 9999.0
		boar.state = WildBoar.State.WANDER
		if state == &"hostile_chase":
			boar.forced_hostile = true
			boar.state = WildBoar.State.CHASE
		elif state == &"wander_into_player":
			# AI WANDER aktif dan sengaja berjalan menembus pemain.
			boar._wander_pause = 0.0
			var toward := player.global_position - boar.global_position
			boar._wander_target = boar.global_position + toward.normalized() * 400.0
		elif state == &"passive":
			boar.set_temperament(FaunaBase.Temperament.PASSIVE)
	elif animal is IslandDeer:
		var deer := animal as IslandDeer
		deer._wander_pause = 9999.0
		deer.state = IslandDeer.State.WANDER
		if state == &"alert":
			deer.state = IslandDeer.State.ALERT
			deer._alert_remaining = 9999.0
		elif state == &"startle":
			deer.state = IslandDeer.State.STARTLE
			deer._startle_remaining = 9999.0


## Kembalikan semua toggle ke keadaan produksi (pemain FLOATING, fauna GROUNDED).
func reset_toggles() -> void:
	toggles.clear()
	if animal != null and is_instance_valid(animal):
		animal.set_physics_process(true)
		_restore_grounded(animal)
	_restore_player_mode()
	if player != null and is_instance_valid(player):
		player.collision_mask = PhysicsLayers.WORLD | PhysicsLayers.FAUNA_BODY
	if animal != null and is_instance_valid(animal):
		animal.collision_mask = PhysicsLayers.WORLD | PhysicsLayers.FENCE_LAYER | PhysicsLayers.FAUNA_BODY | PhysicsLayers.PLAYER_BODY


func _restore_grounded(body: CharacterBody2D) -> void:
	body.motion_mode = CharacterBody2D.MOTION_MODE_GROUNDED
	body.platform_on_leave = CharacterBody2D.PLATFORM_ON_LEAVE_ADD_VELOCITY
	body.platform_floor_layers = 0xFFFFFFFF
	body.platform_wall_layers = 0xFFFFFFFF


func _restore_player_mode() -> void:
	if player == null or not is_instance_valid(player):
		return
	player.motion_mode = CharacterBody2D.MOTION_MODE_FLOATING
	player.platform_on_leave = CharacterBody2D.PLATFORM_ON_LEAVE_ADD_VELOCITY
	player.platform_floor_layers = 0xFFFFFFFF
	player.platform_wall_layers = 0xFFFFFFFF


## Arahkan target WANDER fauna (offset dari posisinya sekarang).
func set_wander_target(offset: Vector2) -> void:
	if animal == null or not is_instance_valid(animal):
		return
	animal._wander_pause = 0.0
	animal._wander_target = animal.global_position + offset


## Toggle eksperimen lokal (E1..E6). Tidak menyentuh kode produksi.
func set_toggle(name: StringName, value: bool) -> void:
	toggles[name] = value
	match name:
		&"floating":
			_apply_floating(player, value)
			_apply_floating(animal, value)
		&"no_separation":
			if animal != null:
				var profile := BodyProfileApplier.profile_of(animal)
				if profile != null:
					var copy := profile.duplicate() as BodyProfile
					if not value:
						copy.separation_speed = profile.separation_speed
					else:
						copy.separation_speed = 0.0
					animal.set_meta(BodyProfileApplier.META, copy)
		&"no_ai":
			if animal != null:
				animal.set_physics_process(not value)
		&"sym_mask":
			if animal != null:
				if value:
					animal.collision_mask = PhysicsLayers.WORLD | PhysicsLayers.PLAYER_BODY
					player.collision_mask = PhysicsLayers.WORLD | PhysicsLayers.FAUNA_BODY
				else:
					animal.collision_mask = PhysicsLayers.WORLD
					player.collision_mask = PhysicsLayers.WORLD | PhysicsLayers.FAUNA_BODY


func _apply_floating(body: CharacterBody2D, value: bool) -> void:
	if body == null:
		return
	if value:
		body.motion_mode = CharacterBody2D.MOTION_MODE_FLOATING
		body.platform_on_leave = CharacterBody2D.PLATFORM_ON_LEAVE_DO_NOTHING
		body.platform_floor_layers = 0
		body.platform_wall_layers = 0
	else:
		body.motion_mode = CharacterBody2D.MOTION_MODE_GROUNDED
		body.platform_on_leave = CharacterBody2D.PLATFORM_ON_LEAVE_ADD_VELOCITY
		body.platform_floor_layers = 0xFFFFFFFF
		body.platform_wall_layers = 0xFFFFFFFF


## Tahan action gerak (dan sprint) lewat Input Map asli.
func press(dir: StringName, sprint: bool = false) -> void:
	var action := StringName("move_" + String(dir))
	Input.action_press(action)
	_held_actions.append(action)
	if sprint:
		Input.action_press(&"sprint")
		_held_actions.append(&"sprint")


func release_input() -> void:
	for action in _held_actions:
		Input.action_release(action)
	_held_actions.clear()


func step_frames(count: int, record: bool = false) -> void:
	for _index in count:
		if toggles.get(&"no_ai", false) and animal != null and is_instance_valid(animal):
			BodySeparation.apply(animal, DELTA, player)
			animal.velocity = Vector2.ZERO
			animal.move_and_slide()
		await get_tree().physics_frame
		if record:
			_record_frame()


func _record_frame() -> void:
	if animal == null or not is_instance_valid(animal):
		return
	var offset := animal.global_position - player.global_position
	var contact := get_player_radius() + get_animal_radius()
	samples.append({
		"player_pos": player.global_position,
		"player_vel": player.velocity,
		"animal_pos": animal.global_position,
		"animal_vel": animal.velocity,
		"animal_state": animal.get_state() if animal.has_method(&"get_state") else -1,
		"ai_desired": animal.velocity,
		"overlap": maxf(contact - offset.length(), 0.0),
	})


## Rasio seret: perpindahan fauna diproyeksikan ke arah jalan pemain dibagi
## perpindahan pemain. 0 = tidak terseret sama sekali.
func drag_ratio(from_index: int, to_index: int, dir: Vector2) -> float:
	if to_index <= from_index or samples.is_empty():
		return 0.0
	to_index = mini(to_index, samples.size() - 1)
	var player_moved := ((samples[to_index]["player_pos"] as Vector2) - (samples[from_index]["player_pos"] as Vector2)).dot(dir)
	# Pemain yang benar-benar terhalang tidak menyeret apa pun: rasio dengan
	# pembagi ~0 hanya derau pembulatan, jadi dianggap 0.
	if absf(player_moved) < 0.5:
		return 0.0
	var animal_moved := ((samples[to_index]["animal_pos"] as Vector2) - (samples[from_index]["animal_pos"] as Vector2)).dot(dir)
	return animal_moved / player_moved


func max_overlap(from_index: int) -> float:
	var worst := 0.0
	for index in range(maxi(from_index, 0), samples.size()):
		worst = maxf(worst, float(samples[index]["overlap"]))
	return worst


## Perpindahan fauna selama jendela sampel (px, panjang).
func animal_displacement(from_index: int) -> float:
	if samples.is_empty():
		return 0.0
	var from_pos: Vector2 = samples[mini(from_index, samples.size() - 1)]["animal_pos"]
	var to_pos: Vector2 = samples[samples.size() - 1]["animal_pos"]
	return from_pos.distance_to(to_pos)


func get_player_radius() -> float:
	return BodySeparation.radius_of(player)


func get_animal_radius() -> float:
	return BodySeparation.radius_of(animal) if animal != null else 12.0


## Lepas semua input dan buang node rig. Tidak menyentuh state global lain.
func cleanup() -> void:
	release_input()
	if is_instance_valid(player):
		player.queue_free()
	if is_instance_valid(animal):
		animal.queue_free()
	if is_instance_valid(_floor):
		_floor.queue_free()
	if is_instance_valid(wall):
		wall.queue_free()
	if is_instance_valid(clock):
		clock.queue_free()
	player = null
	animal = null
	samples.clear()
	queue_free()
