class_name FaunaBase
extends CharacterBody2D

## Basis fauna: HP, temperament, modifier kecepatan/kecepatan serang,
## scaling malam, Dazzled, gerak mengembara, kabur, dan jatuhan item.
##
## Mission 9: fauna dengan `config.blocks_player` true (babi) berada di layer
## FAUNA_BODY sehingga pemain tidak bisa menembusnya; fauna lain tetap layer 0
## (bisa ditembus). Mask fauna: dinding pantai + pagar + FAUNA_BODY (fauna tidak
## saling menumpuk) + PLAYER_BODY bila memblokir pemain.
## Komponen ini tidak memakai physics query untuk menyerang; itu tugas subclass.

signal died(node: Node)

enum Temperament { PASSIVE, NEUTRAL, HOSTILE }

const GROUP := &"fauna"
const STRUCTURE_GROUP := &"camp_structure"
const PLAYER_GROUP := &"player"
const DAMAGE_RECEIVER_NAME := "PlayerDamageReceiver"
const PICKUP_SCENE_PATH := "res://src/entities/props/item_pickup.tscn"
const DAZZLE_SOURCE := &"dazzle"
const DAZZLE_SPEED := 0.7
const DAZZLE_ATTACK := 0.75

@export var config: FaunaConfig
@export var clock: Node
## Opsional; default node pertama di grup "player".
@export var player: Node

var health: HealthComponent
var temperament: int = Temperament.NEUTRAL
var raid_camp: bool = false

## Bisa diganti tes dengan RNG ber-seed.
var rng: RandomNumberGenerator = RandomNumberGenerator.new()

var _provoked: bool = false
## Debug (GatherDebug F6): paksa HOSTILE walau siang.
var forced_hostile: bool = false
var _freeze_remaining: float = 0.0
var _provoke_elapsed: float = 0.0
var _knockback_remaining: float = 0.0
var _knockback_velocity: Vector2 = Vector2.ZERO
var _dying: bool = false
## D5: durasi animasi mati sebelum queue_free (0 = langsung).
@export var death_sequence_time: float = 0.25
var _speed_modifiers: Dictionary = {}
var _attack_modifiers: Dictionary = {}
var _damage_multiplier: float = 1.0
var _home: Vector2 = Vector2.ZERO
var _wander_target: Vector2 = Vector2.ZERO
var _wander_pause: float = 0.0
var _flee_remaining: float = 0.0
var _flee_elapsed: float = 0.0
var _flee_direction: Vector2 = Vector2.ZERO
var _flash_remaining: float = 0.0
var _visual: Polygon2D
var _hp_bar: ProgressBar
var _ready_done: bool = false
var _pickup_scene: PackedScene


func _enter_tree() -> void:
	add_to_group(GROUP)


func _ready() -> void:
	_apply_body_profile()
	ensure_ready()


## Mission 10 Phase 4: profil massa per spesies (satu baris, additive).
func _apply_body_profile() -> void:
	var profile_id: StringName = &""
	if self is IslandDeer:
		profile_id = &"island_deer"
	elif self is WildBoar:
		profile_id = &"wild_boar"
	if profile_id == &"":
		return
	var path := "res://src/data/configs/physics/body_%s.tres" % profile_id
	if ResourceLoader.exists(path):
		BodyProfileApplier.apply(self, load(path) as BodyProfile)


func _physics_process(delta: float) -> void:
	tick(delta)


## Satu tick publik (dipanggil _physics_process dan tes).
func tick(delta: float) -> void:
	ensure_ready()
	if delta <= 0.0:
		return
	if _freeze_remaining > 0.0:
		_freeze_remaining = maxf(_freeze_remaining - delta, 0.0)
		return
	if _knockback_remaining > 0.0:
		# Mission 9: dorongan lewat fisika (bukan tulis global_position langsung)
		# supaya dinding/pagar/pemain tetap dihormati.
		var step := minf(delta, _knockback_remaining)
		move_and_collide(_knockback_velocity * step)
		_knockback_remaining = maxf(_knockback_remaining - delta, 0.0)
	health.tick(delta)
	_tick_flash(delta)
	_update_dazzle()
	# Mission 10 Phase 4: jaring pengaman anti-tumpuk, dihormati dinding/sungai.
	BodySeparation.apply(self, delta, _find_player())

	if _flee_remaining > 0.0:
		_tick_flee(delta)
		return
	_update_behavior(delta)


## Dipanggil sekali; aman dipanggil berkali-kali.
func ensure_ready() -> void:
	if _ready_done:
		return
	_ready_done = true
	if config == null:
		config = FaunaConfig.new()
	if clock == null:
		clock = get_node_or_null("/root/DayNightManager")
	if player == null:
		player = _find_player()
	_home = global_position
	collision_layer = PhysicsLayers.FAUNA_BODY if config.blocks_player else 0
	var mask := PhysicsLayers.WORLD | PhysicsLayers.FENCE_LAYER | PhysicsLayers.FAUNA_BODY
	if config.blocks_player:
		mask |= PhysicsLayers.PLAYER_BODY
	collision_mask = mask
	_ensure_health()
	_ensure_visual()
	_ensure_hp_bar()
	_wander_pause = _random_pause()


# --- Read API ---------------------------------------------------------------

func get_health() -> HealthComponent:
	ensure_ready()
	return health


## Bar HP kecil di atas hewan; hanya terlihat setelah terkena damage.
func get_hp_bar() -> ProgressBar:
	ensure_ready()
	return _hp_bar


func get_temperament() -> int:
	return temperament


func is_provoked() -> bool:
	return _provoked


func can_be_auto_targeted() -> bool:
	return temperament == Temperament.HOSTILE or _provoked


func get_speed_factor() -> float:
	var factor := 1.0
	for source in _speed_modifiers:
		factor *= float(_speed_modifiers[source])
	return factor


func get_attack_speed_factor() -> float:
	var factor := 1.0
	for source in _attack_modifiers:
		factor *= float(_attack_modifiers[source])
	return factor


func get_damage_multiplier() -> float:
	return _damage_multiplier


func get_move_speed() -> float:
	ensure_ready()
	var base_speed := config.move_speed_day
	if _is_night():
		base_speed = config.move_speed_night
	return base_speed * get_speed_factor()


func is_fleeing() -> bool:
	return _flee_remaining > 0.0


## Mission 9 fase 4: pengali radius deteksi terhadap `target`. Pemain yang
## jongkok melaporkan `get_stealth_multiplier()` < 1 sehingga fauna baru
## menyadarinya dari jarak lebih dekat. Target lain selalu 1.0.
func get_detection_multiplier(target: Node) -> float:
	if target == null or not target.has_method(&"get_stealth_multiplier"):
		return 1.0
	return clampf(float(target.call(&"get_stealth_multiplier")), 0.05, 1.0)


# --- Modifier ---------------------------------------------------------------

func set_speed_modifier(source: StringName, multiplier: float) -> void:
	_speed_modifiers[source] = maxf(multiplier, 0.0)


func clear_speed_modifier(source: StringName) -> void:
	_speed_modifiers.erase(source)


func set_attack_speed_modifier(source: StringName, multiplier: float) -> void:
	_attack_modifiers[source] = maxf(multiplier, 0.0)


func clear_attack_speed_modifier(source: StringName) -> void:
	_attack_modifiers.erase(source)


# --- Temperament / scaling --------------------------------------------------

func provoke(source: Node) -> void:
	_provoke_elapsed = 0.0
	if _provoked:
		return
	_provoked = true
	_on_provoked(source)
	provoked(source)


## Hook untuk subclass/sinyal masa depan.
func provoked(_source: Node) -> void:
	pass


## Hentikan provoke tanpa menyentuh temperament (dipakai saat malam berakhir).
func clear_provoke() -> void:
	_provoked = false


func reset_provoke_calm() -> void:
	_provoke_elapsed = 0.0


func tick_provoke(delta: float) -> void:
	_provoke_elapsed += delta


func get_provoke_elapsed() -> float:
	return _provoke_elapsed


## HitStop lokal (juice): fauna melewati tick selama `seconds`.
func freeze_for(seconds: float) -> void:
	_freeze_remaining = maxf(_freeze_remaining, seconds)


func is_frozen() -> bool:
	return _freeze_remaining > 0.0


## D5: dorongan visual/kinematik diterapkan di tick. Diabaikan saat dash/telegraph.
## Mission 9: perpindahan dikali `config.knockback_resistance`.
func apply_knockback(direction: Vector2, distance: float, duration: float) -> void:
	if direction.length_squared() <= 0.0001 or distance <= 0.0 or duration <= 0.0:
		return
	if is_knockback_ignored():
		return
	ensure_ready()
	# Profil massa (Mission 10) adalah sumber utama; config tetap jadi cadangan.
	var multiplier := BodyProfileApplier.knockback_multiplier(self, config.knockback_resistance)
	var scaled := distance * maxf(multiplier, 0.0)
	if scaled <= 0.0:
		return
	_knockback_remaining = duration
	_knockback_velocity = direction.normalized() * (scaled / duration)


## Hook subclass: dash/telegraph kebal knockback.
func is_knockback_ignored() -> bool:
	return false


func is_knocked_back() -> bool:
	return _knockback_remaining > 0.0


## Radius badan dari CollisionShape2D pertama (CircleShape2D); default 12 px.
func get_body_radius() -> float:
	return _radius_of(self)


func is_dying() -> bool:
	return _dying


func set_temperament(value: int) -> void:
	temperament = value


## HP dijaga rasionya saat multiplier malam berubah.
func apply_night_scaling(hp_multiplier: float, damage_multiplier: float) -> void:
	ensure_ready()
	_damage_multiplier = damage_multiplier
	health.set_max_hp_keeping_ratio(config.max_hp * hp_multiplier)


func reset_night_scaling() -> void:
	ensure_ready()
	_damage_multiplier = 1.0
	health.set_max_hp_keeping_ratio(config.max_hp)
	_provoked = false
	raid_camp = false
	if temperament == Temperament.HOSTILE:
		temperament = Temperament.NEUTRAL


# --- Flee -------------------------------------------------------------------

## Kabur menjauh dari `from_position` selama `duration` detik.
func begin_flee(from_position: Vector2, duration: float) -> void:
	var away := global_position - from_position
	if away.length_squared() < 0.0001:
		away = Vector2.RIGHT
	_flee_direction = away.normalized()
	_flee_remaining = duration
	_flee_elapsed = 0.0


func stop_flee() -> void:
	_flee_remaining = 0.0


# --- Loot -------------------------------------------------------------------

## Jatuhkan item ke dunia sebagai ItemPickup. Dipanggil sekali saat mati.
func drop_loot() -> void:
	if config == null or config.loot_ids.is_empty():
		return
	var tree := get_tree()
	if tree == null or tree.current_scene == null:
		return
	if _pickup_scene == null:
		_pickup_scene = load(PICKUP_SCENE_PATH) as PackedScene
	if _pickup_scene == null:
		return
	for index in config.loot_ids.size():
		var item := ItemCatalog.get_by_id(StringName(config.loot_ids[index]))
		if item == null:
			continue
		var count := 1
		if index < config.loot_counts.size():
			count = maxi(int(config.loot_counts[index]), 1)
		var pickup := _pickup_scene.instantiate()
		if pickup is ItemPickup:
			(pickup as ItemPickup).item = item
			(pickup as ItemPickup).count = count
		tree.current_scene.add_child(pickup)
		if pickup is Node2D:
			(pickup as Node2D).global_position = global_position


# --- Visual -----------------------------------------------------------------

func flash_hit() -> void:
	_flash_remaining = 0.12
	if _visual != null:
		_visual.modulate = Color(1.6, 0.7, 0.7, 1.0)


# --- Internal ---------------------------------------------------------------

func _ensure_health() -> void:
	if health != null and is_instance_valid(health):
		return
	health = HealthComponent.new()
	health.name = "HealthComponent"
	add_child(health)
	health.setup(config.max_hp)
	if not health.died.is_connected(_on_health_died):
		health.died.connect(_on_health_died)
	if not health.damaged.is_connected(_on_health_damaged):
		health.damaged.connect(_on_health_damaged)


func _ensure_visual() -> void:
	if _visual != null and is_instance_valid(_visual):
		return
	_visual = get_node_or_null("Visual") as Polygon2D
	if _visual == null:
		_visual = Polygon2D.new()
		_visual.name = "Visual"
		_visual.color = Color(0.55, 0.4, 0.28, 1.0)
		_visual.polygon = PackedVector2Array([
			Vector2(-12, -8), Vector2(12, -8), Vector2(14, 6), Vector2(-14, 6)
		])
		add_child(_visual)
	var key := visual_key()
	if not String(key).is_empty():
		VisualSlot.attach(self, key, [_visual], null, FaunaVisual.new())


## Kunci slot aset fauna; diisi subclass (wild_boar / island_deer).
func visual_key() -> StringName:
	return &""


func _on_health_damaged(_amount: float, source: Node) -> void:
	provoke(source)
	flash_hit()
	_refresh_hp_bar()


func _on_health_died(source: Node) -> void:
	drop_loot()
	velocity = Vector2.ZERO
	died.emit(self)
	_start_death_sequence()


## D5: shrink + spin + fade 0.25 s sebelum bebas; loot sudah jatuh di atas.
## Animasi mati memakai "jasad" visual terpisah supaya fauna asli tetap langsung
## dibebaskan: kuota/spawn/soak tidak bergeser sama sekali (D5).
func _start_death_sequence() -> void:
	_dying = true
	_spawn_corpse()
	queue_free()


func _spawn_corpse() -> void:
	if death_sequence_time <= 0.0 or not is_inside_tree():
		return
	var parent := get_parent()
	if parent == null:
		return
	var corpse := Node2D.new()
	corpse.name = "FaunaCorpse"
	var death_art := _death_art()
	if death_art != null:
		corpse.add_child(death_art)
	elif _visual != null:
		var copy := _visual.duplicate()
		if copy is Node2D:
			(copy as Node2D).position = Vector2.ZERO
			corpse.add_child(copy)
	corpse.global_position = global_position
	corpse.rotation = rotation
	parent.add_child(corpse)
	var tween := corpse.create_tween()
	tween.set_parallel(true)
	tween.tween_property(corpse, "scale", Vector2(0.2, 0.2), death_sequence_time)
	tween.tween_property(corpse, "rotation", rotation + TAU * 0.5, death_sequence_time)
	tween.tween_property(corpse, "modulate:a", 0.0, death_sequence_time)
	tween.chain().tween_callback(corpse.queue_free)


## Art jasad: salinan node art dalam state death bila slot punya art.
func _death_art() -> Node2D:
	var slot := get_node_or_null("VisualSlot") as VisualSlot
	if slot == null or not slot.is_showing_art() or not slot.has_state(&"death"):
		return null
	slot.set_state(&"death", slot.get_direction())
	var art := slot.duplicate_art()
	if art == null:
		return null
	art.position = Vector2.ZERO
	art.rotation = 0.0
	art.scale = Vector2.ONE
	return art


func _update_behavior(delta: float) -> void:
	_wander(delta)


func _on_provoked(_source: Node) -> void:
	pass


func _ensure_hp_bar() -> void:
	if _hp_bar != null and is_instance_valid(_hp_bar):
		return
	_hp_bar = ProgressBar.new()
	_hp_bar.name = "HpBar"
	_hp_bar.position = Vector2(-18.0, -26.0)
	_hp_bar.size = Vector2(36.0, 4.0)
	_hp_bar.show_percentage = false
	_hp_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_hp_bar)
	_refresh_hp_bar()


func _refresh_hp_bar() -> void:
	if _hp_bar == null:
		return
	_hp_bar.max_value = maxf(health.get_max_hp(), 1.0)
	_hp_bar.value = health.get_current_hp()
	_hp_bar.visible = health.get_current_hp() < health.get_max_hp()


func _tick_flash(delta: float) -> void:
	if _flash_remaining <= 0.0:
		return
	_flash_remaining -= delta
	if _flash_remaining <= 0.0 and _visual != null:
		_visual.modulate = Color(1.0, 1.0, 1.0, 1.0)


func _update_dazzle() -> void:
	var dazzled := false
	for node in get_tree().get_nodes_in_group(STRUCTURE_GROUP):
		var fire := node as Campfire
		if fire == null or not is_instance_valid(fire) or not fire.is_lit():
			continue
		if global_position.distance_to(fire.global_position) <= fire.get_dazzle_radius():
			dazzled = true
			break
	if dazzled:
		set_speed_modifier(DAZZLE_SOURCE, DAZZLE_SPEED)
		set_attack_speed_modifier(DAZZLE_SOURCE, DAZZLE_ATTACK)
	else:
		clear_speed_modifier(DAZZLE_SOURCE)
		clear_attack_speed_modifier(DAZZLE_SOURCE)


func _tick_flee(delta: float) -> void:
	_flee_remaining = maxf(_flee_remaining - delta, 0.0)
	_flee_elapsed += delta
	var target := _find_player()
	var far_enough := target is Node2D and global_position.distance_to((target as Node2D).global_position) >= config.flee_despawn_distance
	if far_enough or _flee_elapsed >= config.flee_despawn_timeout:
		despawn()
		return
	move_in_direction(_flee_direction, get_move_speed() * 1.2, delta)


func despawn() -> void:
	velocity = Vector2.ZERO
	queue_free()


## Gerak satu langkah dengan collision dinding.
func move_in_direction(direction: Vector2, speed: float, _delta: float) -> void:
	if direction.length_squared() <= 0.0001 or speed <= 0.0:
		velocity = Vector2.ZERO
		move_and_slide()
		return
	velocity = direction.normalized() * speed
	move_and_slide()


func face(direction: Vector2) -> void:
	if direction.length_squared() <= 0.0001:
		return
	rotation = 0.0
	scale.x = absf(scale.x) * (1.0 if direction.x >= 0.0 else -1.0)


func _wander(delta: float) -> void:
	if _wander_pause > 0.0:
		_wander_pause = maxf(_wander_pause - delta, 0.0)
		move_in_direction(Vector2.ZERO, 0.0, delta)
		return

	if _wander_target == Vector2.ZERO:
		_wander_target = _random_wander_point()
	var offset := _wander_target - global_position
	if offset.length() <= 8.0:
		_wander_target = Vector2.ZERO
		_wander_pause = _random_pause()
		move_in_direction(Vector2.ZERO, 0.0, delta)
		return
	move_in_direction(offset, get_move_speed() * config.wander_speed_factor, delta)


func _random_wander_point() -> Vector2:
	var angle := rng.randf() * TAU
	var radius := rng.randf_range(16.0, maxf(config.wander_radius, 16.0))
	return _home + Vector2(cos(angle), sin(angle)) * radius


func _random_pause() -> float:
	var low := minf(config.wander_pause_min, config.wander_pause_max)
	var high := maxf(config.wander_pause_min, config.wander_pause_max)
	return rng.randf_range(low, high)


func _find_player() -> Node:
	var target := player
	if target == null or not is_instance_valid(target):
		var tree := get_tree()
		if tree == null:
			return null
		target = tree.get_first_node_in_group(PLAYER_GROUP)
	if target == null:
		return null
	# Mission 9: selama perlindungan respawn fauna tidak memilih pemain.
	if _player_is_protected(target):
		return null
	return target


func _player_is_protected(target: Node) -> bool:
	var receiver := target.get_node_or_null(DAMAGE_RECEIVER_NAME) as PlayerDamageReceiver
	if receiver == null:
		return false
	if receiver.run_config != null and not receiver.run_config.protection_ignored_by_enemies:
		return false
	return receiver.is_protected()


func get_player_receiver() -> PlayerDamageReceiver:
	var target := _find_player()
	if target == null:
		return null
	return target.get_node_or_null(DAMAGE_RECEIVER_NAME) as PlayerDamageReceiver


## Jarak menempel ke pemain (radius badan fauna + radius pemain + extra).
func get_contact_distance_to_player() -> float:
	ensure_ready()
	var extra := config.contact_stop_extra
	var profile := BodyProfileApplier.profile_of(self)
	if profile != null:
		extra = profile.contact_stop_extra
	return _radius_of(_find_player()) + get_body_radius() + maxf(extra, 0.0)


## Satu jalur radius untuk fauna ini maupun target lain (pemain).
func _radius_of(node: Node) -> float:
	var body := node as Node2D
	if body == null:
		return 12.0
	for child in body.get_children():
		var shape_node := child as CollisionShape2D
		if shape_node == null:
			continue
		var circle := shape_node.shape as CircleShape2D
		if circle != null:
			return circle.radius
	return 12.0


func _is_night() -> bool:
	if clock != null and clock.has_method(&"is_night"):
		return bool(clock.is_night())
	return false


func get_day() -> int:
	if clock != null and clock.has_method(&"get_current_day"):
		return int(clock.get_current_day())
	return 1


func get_time_scale() -> float:
	if clock != null and clock.has_method(&"get_time_scale"):
		return float(clock.get_time_scale())
	return 1.0


func nearest_structure() -> CampStructure:
	var tree := get_tree()
	if tree == null:
		return null
	var candidates: Array[CampStructure] = []
	for node in tree.get_nodes_in_group(STRUCTURE_GROUP):
		var structure := node as CampStructure
		if structure != null and is_instance_valid(structure) and structure.get_current_hp() > 0.0:
			candidates.append(structure)
	candidates.sort_custom(func(a: CampStructure, b: CampStructure) -> bool:
		return a.get_aggro_priority() < b.get_aggro_priority()
	)
	return candidates[0] if not candidates.is_empty() else null
