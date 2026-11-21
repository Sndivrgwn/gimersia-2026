class_name ProficiencyComponent
extends Node

## XP dan passive untuk empat proficiency (spesifikasi V8 §7.6).
##
## Level tetap milik `StatsComponent` (`strength_level` dst); komponen ini hanya
## menulis lewat properti tersebut dan tidak menghitung ulang efek per level.
## XP, `max_reached_level`, passive, bonus malam, dan debuff kematian ada di sini.
##
## Sumber XP dihubungkan dari sinyal yang sudah ada: `CombatComponent.hit_dealt`
## / `enemy_killed`, `PlayerDamageReceiver.dodged`, `ResourceNode.gathered`,
## `CraftingComponent.crafted`, dan `WildBoar.dash_ended`. Speed memakai
## perpindahan nyata pemain per tick. Tidak ada clock kedua: bonus malam membaca
## DayNightManager.

signal xp_gained(prof: int, amount: float)
signal level_changed(prof: int, level: int)
signal max_reached_level_changed(prof: int, level: int)
signal passive_unlocked(prof: int, level: int)

enum Prof { STRENGTH, SPEED, MASTERY, AGILITY }

const PROF_COUNT := 4
const DEFAULT_CONFIG: ProficiencyConfig = preload("res://src/data/configs/proficiency_config.tres")
const PLAYER_GROUP := &"player"
const FAUNA_GROUP := &"fauna"
const INTERACTABLE_GROUP := &"interactable"
const CLOCK_PATH := "/root/DayNightManager"

const HEAVY_STRIKE_SOURCE := &"prof_heavy_strike"
const QUICK_REFLEX_SOURCE := &"prof_quick_reflex"

## Batas perpindahan satu tick yang dihitung untuk XP Speed; teleport debug
## tidak boleh menghasilkan XP.
const MAX_TRACKED_STEP := 200.0
## Jeda pemindaian node (resource/fauna) dalam detik nyata.
const SCAN_INTERVAL := 0.5

@export var config: ProficiencyConfig = DEFAULT_CONFIG
@export var stats: StatsComponent
@export var player: Node
@export var inventory: InventoryComponent
@export var needs: NeedsComponent
@export var combat: CombatComponent
@export var crafting: CraftingComponent
@export var receiver: PlayerDamageReceiver
@export var clock: Node
## Matikan di scene tes yang tidak ingin XP berjalan.
@export var xp_enabled: bool = true
## 0 = acak; selain 0 = deterministik (Resourceful).
@export var rng_seed: int = 0

var _xp: Array[float] = [0.0, 0.0, 0.0, 0.0]
var _max_reached: Array[int] = [1, 1, 1, 1]
var _hit_counter: int = 0
var _swift_counter_armed: bool = false
var _sprinting: bool = false
var _dodge_cooldowns: Dictionary = {}
var _dash_misses: Dictionary = {}
var _connected_fauna: Dictionary = {}
var _connected_nodes: Dictionary = {}
var _scan_timer: float = 0.0
var _last_position: Vector2 = Vector2.ZERO
var _position_ready: bool = false
var _rng := RandomNumberGenerator.new()
var _bound: bool = false
## Cegah rekursi: modifier Quick Reflex memancarkan stats_changed lagi.
var _refreshing: bool = false


func _ready() -> void:
	_bind()
	_install_hit_modifiers()
	_connect_sources()
	_refresh_passives()


func _process(delta: float) -> void:
	tick(delta)


## Rangkai dependensi eksplisit (tes / scene lain).
func setup(p_player: Node) -> void:
	player = p_player
	_bound = false
	_bind()
	_install_hit_modifiers()
	_connect_sources()
	_refresh_passives()


# --- Read API ---------------------------------------------------------------

func get_level(prof: int) -> int:
	if stats == null:
		return 1
	match prof:
		Prof.STRENGTH:
			return stats.strength_level
		Prof.SPEED:
			return stats.speed_level
		Prof.MASTERY:
			return stats.mastery_level
		Prof.AGILITY:
			return stats.agility_level
	return 1


func get_xp(prof: int) -> float:
	if prof < 0 or prof >= PROF_COUNT:
		return 0.0
	return _xp[prof]


func get_max_reached_level(prof: int) -> int:
	if prof < 0 or prof >= PROF_COUNT:
		return 1
	return _max_reached[prof]


## XP yang masih dibutuhkan pada level sekarang (0 saat level maksimum).
func get_xp_to_next_level(prof: int) -> float:
	if config == null:
		return 0.0
	var level := get_level(prof)
	if level >= config.max_level:
		return 0.0
	return maxf(config.xp_to_next(level) - _xp[prof], 0.0)


func has_passive(prof: int, level: int) -> bool:
	return get_level(prof) >= level


func is_max_level(prof: int) -> bool:
	return config != null and get_level(prof) >= config.max_level


## Bonus restore makanan/minuman Campfire (Master Chef). Belum diterapkan:
## tidak ada hook konsumsi item yang boleh ditambah (lihat laporan misi).
func get_campfire_restore_bonus() -> float:
	if config == null or not has_passive(Prof.MASTERY, config.master_chef_level):
		return 0.0
	return config.master_chef_bonus


# --- XP ---------------------------------------------------------------------

## Tambah XP. `combat` = true berarti kena bonus malam 1.5x saat malam.
func add_xp(prof: int, amount: float, combat: bool = false) -> void:
	if not xp_enabled or amount <= 0.0 or config == null:
		return
	if prof < 0 or prof >= PROF_COUNT:
		return
	if get_level(prof) >= config.max_level:
		_xp[prof] = 0.0
		return

	var gained := amount
	if combat and _is_night():
		gained *= config.night_xp_multiplier
	_xp[prof] += gained
	xp_gained.emit(prof, gained)
	_apply_overflow(prof)


## Debuff kematian: turunkan maksimal `death_debuff_levels` proficiency yang
## memenuhi syarat. Mengembalikan daftar proficiency yang turun.
func apply_death_debuff() -> Array[int]:
	var changed: Array[int] = []
	if config == null:
		return changed

	var eligible: Array[int] = []
	for prof in PROF_COUNT:
		var level := get_level(prof)
		if level > 1 and level > _max_reached[prof] - 2:
			eligible.append(prof)
	eligible.sort_custom(_compare_for_debuff)

	var count := mini(eligible.size(), config.death_debuff_levels)
	for index in count:
		var prof: int = eligible[index]
		_set_level(prof, get_level(prof) - 1)
		_xp[prof] = 0.0
		changed.append(prof)
	return changed


# --- Tick -------------------------------------------------------------------

## Satu tick delta nyata: XP Speed, cooldown dodge, dan pemindaian sumber.
func tick(delta: float) -> void:
	if delta <= 0.0:
		return
	_bind()
	_track_speed(delta)
	_tick_dodge_cooldowns(delta)

	_scan_timer += delta
	if _scan_timer >= SCAN_INTERVAL:
		_scan_timer = 0.0
		_scan_nodes()


# --- Internal: XP -----------------------------------------------------------

func _apply_overflow(prof: int) -> void:
	var level := get_level(prof)
	while level < config.max_level:
		var needed := config.xp_to_next(level)
		if _xp[prof] < needed:
			break
		_xp[prof] -= needed
		level += 1
		_set_level(prof, level)

	if get_level(prof) >= config.max_level:
		_xp[prof] = 0.0


func _set_level(prof: int, level: int) -> void:
	if level == get_level(prof):
		return
	match prof:
		Prof.STRENGTH:
			stats.strength_level = level
		Prof.SPEED:
			stats.speed_level = level
		Prof.MASTERY:
			stats.mastery_level = level
		Prof.AGILITY:
			stats.agility_level = level

	var reached := maxi(_max_reached[prof], level)
	if reached != _max_reached[prof]:
		_max_reached[prof] = reached
		max_reached_level_changed.emit(prof, reached)

	level_changed.emit(prof, level)
	_refresh_passives()
	if config != null and level == config.passive_level_for(prof):
		passive_unlocked.emit(prof, level)


func _compare_for_debuff(a: int, b: int) -> bool:
	var level_a := get_level(a)
	var level_b := get_level(b)
	if level_a != level_b:
		return level_a > level_b
	return a < b


# --- Internal: Speed --------------------------------------------------------

func _track_speed(delta: float) -> void:
	if player == null or not (player is Node2D) or not xp_enabled:
		return
	var position := (player as Node2D).global_position
	if not _position_ready:
		_position_ready = true
		_last_position = position
		return

	var step := position.distance_to(_last_position)
	_last_position = position
	if step <= 0.0 or step > MAX_TRACKED_STEP:
		return
	var outside := position.distance_to(CampAnchor.center_of(self)) > config.speed_camp_radius
	if not outside:
		return
	if _sprinting:
		add_xp(Prof.SPEED, config.speed_sprint_xp_per_second * delta)
	else:
		add_xp(Prof.SPEED, step / maxf(config.speed_walk_distance, 1.0) * config.speed_walk_xp)


# --- Internal: binding / sumber ---------------------------------------------

func _bind() -> void:
	if _bound:
		return
	if player == null:
		player = get_parent()
	if player != null:
		if stats == null:
			stats = player.get_node_or_null("StatsComponent") as StatsComponent
		if inventory == null:
			inventory = player.get_node_or_null("InventoryComponent") as InventoryComponent
		if needs == null:
			needs = player.get_node_or_null("NeedsComponent") as NeedsComponent
		if combat == null:
			combat = player.get_node_or_null("CombatComponent") as CombatComponent
		if crafting == null:
			crafting = player.get_node_or_null("CraftingComponent") as CraftingComponent
		if receiver == null:
			receiver = player.get_node_or_null("PlayerDamageReceiver") as PlayerDamageReceiver
	if clock == null:
		clock = get_node_or_null(CLOCK_PATH)
	if config == null:
		config = DEFAULT_CONFIG
	if rng_seed != 0:
		_rng.seed = rng_seed
	else:
		_rng.randomize()
	_bound = true


func _install_hit_modifiers() -> void:
	if combat == null:
		return
	combat.register_hit_modifier(HEAVY_STRIKE_SOURCE, Callable(self, "_modify_hit"))


func _connect_sources() -> void:
	if combat != null:
		if not combat.hit_dealt.is_connected(_on_hit_dealt):
			combat.hit_dealt.connect(_on_hit_dealt)
		if not combat.enemy_killed.is_connected(_on_enemy_killed):
			combat.enemy_killed.connect(_on_enemy_killed)
	if receiver != null and not receiver.dodged.is_connected(_on_dodged):
		receiver.dodged.connect(_on_dodged)
	if crafting != null and not crafting.crafted.is_connected(_on_crafted):
		crafting.crafted.connect(_on_crafted)
	if stats != null and not stats.hp_changed.is_connected(_on_hp_changed):
		stats.hp_changed.connect(_on_hp_changed)
	if stats != null and not stats.stats_changed.is_connected(_on_stats_changed):
		stats.stats_changed.connect(_on_stats_changed)
	if player != null and player.has_signal(&"sprint_state_changed"):
		if not player.sprint_state_changed.is_connected(_on_sprint_state_changed):
			player.sprint_state_changed.connect(_on_sprint_state_changed)


## Pindai node resource dan fauna sekali per SCAN_INTERVAL. Node yang sudah
## terhubung tidak didaftarkan ulang, jadi spawner malam tetap tertangani.
func _scan_nodes() -> void:
	var tree := get_tree()
	if tree == null:
		return
	for node in tree.get_nodes_in_group(INTERACTABLE_GROUP):
		var resource := node as ResourceNode
		if resource == null or _connected_nodes.has(resource.get_instance_id()):
			continue
		_connected_nodes[resource.get_instance_id()] = true
		if not resource.gathered.is_connected(_on_gathered):
			resource.gathered.connect(_on_gathered)

	for node in tree.get_nodes_in_group(FAUNA_GROUP):
		var boar := node as WildBoar
		if boar == null or _connected_fauna.has(boar.get_instance_id()):
			continue
		_connected_fauna[boar.get_instance_id()] = true
		if not boar.dash_ended.is_connected(_on_dash_ended):
			boar.dash_ended.connect(_on_dash_ended.bind(boar))


# --- Internal: handler ------------------------------------------------------

func _on_hit_dealt(_target: Node, _damage: float) -> void:
	add_xp(Prof.STRENGTH, config.strength_hit_xp, true)


func _on_enemy_killed(_target: Node) -> void:
	add_xp(Prof.AGILITY, config.agility_kill_xp, true)


func _on_dodged(source: Node) -> void:
	if source != null:
		var key := source.get_instance_id()
		if _dodge_cooldowns.has(key) and float(_dodge_cooldowns[key]) > 0.0:
			return
		_dodge_cooldowns[key] = config.agility_dodge_cooldown
	_swift_counter_armed = true
	add_xp(Prof.AGILITY, config.agility_dodge_xp, true)


func _on_dash_ended(hit: bool, boar: Node) -> void:
	if hit:
		return
	if boar == null:
		return
	var key := boar.get_instance_id()
	var count := int(_dash_misses.get(key, 0))
	if count >= config.agility_dash_miss_max_per_boar:
		return
	_dash_misses[key] = count + 1
	add_xp(Prof.AGILITY, config.agility_dash_miss_xp, true)


func _on_gathered(definition: ResourceNodeDefinition, _amount: int, interactor: Node) -> void:
	if definition == null or definition.item == null:
		return
	if player != null and interactor != null and interactor.get_parent() != player:
		return
	add_xp(Prof.MASTERY, config.mastery_gather_xp)

	match definition.item.id:
		&"wood":
			add_xp(Prof.STRENGTH, config.strength_tree_xp)
		&"stone":
			add_xp(Prof.STRENGTH, config.strength_rock_xp)

	if has_passive(Prof.MASTERY, config.resourceful_level) and _rng.randf() < config.resourceful_chance:
		if inventory != null:
			inventory.add_or_drop(definition.item, config.resourceful_bonus)


func _on_crafted(recipe: RecipeDefinition, count: int) -> void:
	if recipe == null:
		return
	var per_item := config.mastery_craft_xp
	if recipe.station == RecipeDefinition.Station.CAMPFIRE:
		per_item = config.mastery_cook_xp
	add_xp(Prof.MASTERY, per_item * float(maxi(count, 1)))


func _on_sprint_state_changed(is_sprinting: bool) -> void:
	_sprinting = is_sprinting


func _on_hp_changed(_current: float, _max_value: float) -> void:
	_refresh_quick_reflex()


## Level bisa berubah dari luar (mis. debuff kematian), jadi passive
## disegarkan setiap stats berubah.
func _on_stats_changed() -> void:
	if _refreshing:
		return
	_refreshing = true
	_refresh_passives()
	_refreshing = false


func _tick_dodge_cooldowns(delta: float) -> void:
	for key in _dodge_cooldowns.keys():
		var remaining := float(_dodge_cooldowns[key]) - delta
		if remaining <= 0.0:
			_dodge_cooldowns.erase(key)
		else:
			_dodge_cooldowns[key] = remaining


# --- Internal: passive ------------------------------------------------------

## Modifier damage: Swift Counter (sekali setelah dodge) lalu Heavy Strike
## tiap 4 hit yang benar-benar mengenai sasaran.
func _modify_hit(damage: float, _target: Node) -> float:
	var result := damage
	if _swift_counter_armed and has_passive(Prof.AGILITY, config.swift_counter_level):
		_swift_counter_armed = false
		result *= config.swift_counter_multiplier

	if has_passive(Prof.STRENGTH, config.heavy_strike_level):
		_hit_counter += 1
		if _hit_counter >= config.heavy_strike_every:
			_hit_counter = 0
			result *= config.heavy_strike_multiplier
	return result


func _refresh_passives() -> void:
	if player != null and "knockback_multiplier" in player:
		player.knockback_multiplier = (
			config.sturdy_knockback_multiplier
			if has_passive(Prof.STRENGTH, config.sturdy_level)
			else 1.0
		)

	if needs != null:
		if has_passive(Prof.SPEED, config.second_wind_level):
			needs.set_idle_regen_multiplier(&"prof_second_wind", config.second_wind_regen_multiplier)
		else:
			needs.clear_idle_regen_multiplier(&"prof_second_wind")

	_refresh_quick_reflex()


func _refresh_quick_reflex() -> void:
	if stats == null:
		return
	stats.remove_modifier(QUICK_REFLEX_SOURCE)
	if not has_passive(Prof.AGILITY, config.quick_reflex_level):
		return
	var maximum := stats.get_max_hp()
	if maximum <= 0.0:
		return
	if stats.current_hp / maximum >= config.quick_reflex_hp_threshold:
		return
	stats.add_modifier(
		QUICK_REFLEX_SOURCE,
		&"dodge",
		StatModifier.Kind.PERCENT,
		config.quick_reflex_dodge_percent
	)


func _is_night() -> bool:
	if clock == null or not clock.has_method(&"is_night"):
		return false
	return bool(clock.is_night())


func get_proficiency_name(prof: int) -> String:
	match prof:
		Prof.STRENGTH:
			return "Strength"
		Prof.SPEED:
			return "Speed"
		Prof.MASTERY:
			return "Mastery"
		Prof.AGILITY:
			return "Agility"
	return "?"
