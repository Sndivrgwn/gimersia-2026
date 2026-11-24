class_name RaidDirector
extends Node

## Mission 9: raid sebagai EVENT. Saat `night_started` direktor membangun jadwal
## malam (offset waktu game) dari RaidConfig x global_pressure_multiplier, lalu:
## membunyikan peringatan `warning_seconds` sebelum tiap raid, memilih raider
## (boar hostile hidup terdekat ke pusat base) dan menandainya `is_raider`.
##
## Raid selesai setelah `raid_duration` detik game atau saat semua raider hilang;
## raider yang masih hidup kembali ke perilaku normal (tanda dilepas).
## Tidak ada raid yang dijadwalkan saat fajar; jadwal dibuang saat fase berakhir.
##
## Clock, RNG, dan parent fauna bisa di-inject untuk tes.

signal raid_warning(day: int, count: int, seconds: float)
signal raid_started(day: int, count: int)
signal raid_ended(day: int)

const GROUP := &"raid_director"
const DEFAULT_CONFIG: RaidConfig = preload("res://src/data/configs/fauna/raid_config.tres")

@export var config: RaidConfig = DEFAULT_CONFIG
@export var clock: Node
## NightSpawner; dipakai untuk meminta boar tambahan bila raider kurang.
@export var spawner: Node
@export var fauna_parent: Node2D

var rng: RandomNumberGenerator = RandomNumberGenerator.new()

var _day: int = 1
var _active: bool = false
var _elapsed: float = 0.0
var _schedule: Array[Dictionary] = []
var _raid_active: bool = false
var _raid_remaining: float = 0.0
var _raiders: Array[WildBoar] = []


func _enter_tree() -> void:
	add_to_group(GROUP)


func _ready() -> void:
	if config == null:
		config = DEFAULT_CONFIG
	if clock == null:
		clock = get_node_or_null("/root/DayNightManager")
	if spawner == null:
		spawner = get_node_or_null("../NightSpawner")
	_connect_clock()


func _process(delta: float) -> void:
	tick(delta)


func _connect_clock() -> void:
	if clock == null:
		return
	if clock.has_signal(&"night_started") and not clock.night_started.is_connected(_on_night_started):
		clock.night_started.connect(_on_night_started)
	if clock.has_signal(&"day_started") and not clock.day_started.is_connected(_on_day_started):
		clock.day_started.connect(_on_day_started)
	if clock.has_signal(&"rescue_started") and not clock.rescue_started.is_connected(_on_rescue_started):
		clock.rescue_started.connect(_on_rescue_started)


# --- Read API ---------------------------------------------------------------

func is_active() -> bool:
	return _active


func get_day() -> int:
	return _day


func is_raid_active() -> bool:
	return _raid_active


func get_raider_count() -> int:
	return _living_raiders().size()


func get_raiders() -> Array[WildBoar]:
	return _raiders.duplicate()


## Offset waktu game setiap raid malam ini (kosong setelah fajar).
func get_raid_times() -> Array[float]:
	var times: Array[float] = []
	for entry in _schedule:
		times.append(float(entry["time"]))
	return times


func get_schedule_size() -> int:
	return _schedule.size()


# --- Tick -------------------------------------------------------------------

## Satu tick game. `_process` hanya memanggil ini supaya tes deterministik.
func tick(delta: float) -> void:
	if not _active or delta <= 0.0:
		return
	if config == null or config.is_off():
		return
	var game_delta := delta * _time_scale()
	_elapsed += game_delta

	for entry in _schedule:
		if entry["warned"]:
			continue
		if _elapsed >= float(entry["time"]) - config.warning_seconds:
			entry["warned"] = true
			raid_warning.emit(_day, int(entry["count"]), config.warning_seconds)

	if not _raid_active:
		for entry in _schedule:
			if entry["started"]:
				continue
			if _elapsed < float(entry["time"]):
				continue
			entry["started"] = true
			_start_raid(int(entry["count"]))
			break
		return

	_raid_remaining -= game_delta
	if _raid_remaining <= 0.0 or _living_raiders().is_empty():
		_end_raid()


## Debug (island only): mulai raid sekarang juga, tanpa menunggu jadwal.
func trigger_raid_now() -> int:
	if config == null or config.is_off():
		return 0
	if not _active:
		_day = int(clock.get_current_day()) if clock != null and clock.has_method(&"get_current_day") else 1
		_active = true
		_elapsed = 0.0
	return _start_raid(maxi(config.get_raiders_for_raid(_day), 1))


# --- Jadwal -----------------------------------------------------------------

func _on_night_started(day: int) -> void:
	_day = clampi(day, 1, 7)
	_active = true
	_elapsed = 0.0
	_raid_active = false
	_raid_remaining = 0.0
	_raiders.clear()
	_build_schedule()


func _on_day_started(_day_arg: int = 0) -> void:
	_end_raid()
	_active = false
	_elapsed = 0.0
	_schedule.clear()


func _on_rescue_started(_ignored: Variant = null) -> void:
	_end_raid()
	_active = false
	_schedule.clear()


func _build_schedule() -> void:
	_schedule.clear()
	if config == null or config.is_off():
		return
	var raids := config.get_raids_for_night(_day)
	if raids <= 0:
		return
	var time := rng.randf_range(config.first_raid_delay_min, config.first_raid_delay_max)
	var gap := maxf(config.raid_gap_min, config.raid_duration)
	for index in raids:
		_schedule.append({
			"time": maxf(time, 0.0),
			"count": maxi(config.get_raiders_for_raid(_day), 1),
			"warned": false,
			"started": false,
		})
		time += gap


# --- Raid -------------------------------------------------------------------

func _start_raid(count: int) -> int:
	var chosen := _pick_raiders(count)
	_raiders = chosen
	_raid_active = true
	_raid_remaining = config.raid_duration
	raid_started.emit(_day, _raiders.size())
	return _raiders.size()


## Boar hostile hidup terdekat ke pusat base, maksimal `count`. Bila kurang,
## minta NightSpawner menambah selama batas hostile malam mengizinkan.
func _pick_raiders(count: int) -> Array[WildBoar]:
	var picked: Array[WildBoar] = []
	var center := CampAnchor.center_of(self)
	var candidates := _living_boars()
	candidates.sort_custom(func(a: WildBoar, b: WildBoar) -> bool:
		return a.global_position.distance_squared_to(center) < b.global_position.distance_squared_to(center)
	)
	for boar in candidates:
		if picked.size() >= count:
			break
		if boar.temperament != FaunaBase.Temperament.HOSTILE:
			continue
		_mark(boar, picked)

	while picked.size() < count:
		var extra := _request_boar()
		if extra == null:
			break
		extra.temperament = FaunaBase.Temperament.HOSTILE
		_mark(extra, picked)
	return picked


func _mark(boar: WildBoar, picked: Array[WildBoar]) -> void:
	boar.set_raider(true)
	picked.append(boar)


func _request_boar() -> WildBoar:
	if spawner != null and spawner.has_method(&"spawn_raid_boar"):
		return spawner.spawn_raid_boar() as WildBoar
	return null


func _end_raid() -> void:
	if not _raid_active:
		return
	for boar in _raiders:
		if is_instance_valid(boar):
			boar.set_raider(false)
	_raiders.clear()
	_raid_active = false
	_raid_remaining = 0.0
	raid_ended.emit(_day)


# --- Lookup -----------------------------------------------------------------

func _living_boars() -> Array[WildBoar]:
	var result: Array[WildBoar] = []
	var parent := _fauna_root()
	if parent == null:
		return result
	for child in parent.get_children():
		if _is_alive(child):
			result.append(child as WildBoar)
	return result


func _living_raiders() -> Array[WildBoar]:
	var result: Array[WildBoar] = []
	for boar in _raiders:
		if _is_alive(boar):
			result.append(boar)
	return result


## Hidup = masih di tree, belum masuk animasi mati, dan HP > 0.
## Parameter `Variant`: objek yang sudah di-free gagal type-check bila parameter
## bertipe `Node`, jadi validitas dicek dulu lewat `is_instance_valid()`.
func _is_alive(node: Variant) -> bool:
	if not is_instance_valid(node):
		return false
	var boar := node as WildBoar
	if boar == null or boar.is_dying():
		return false
	var health := boar.get_health()
	return health != null and health.get_current_hp() > 0.0


func _fauna_root() -> Node:
	if fauna_parent != null and is_instance_valid(fauna_parent):
		return fauna_parent
	var tree := get_tree()
	if tree == null:
		return null
	var found := tree.get_first_node_in_group(&"fauna")
	if found != null and found.get_parent() != null:
		fauna_parent = found.get_parent()
		return fauna_parent
	var local := get_node_or_null("../Fauna") as Node2D
	if local != null:
		fauna_parent = local
	return fauna_parent


func _time_scale() -> float:
	if clock != null and clock.has_method(&"get_time_scale"):
		return float(clock.get_time_scale())
	return 1.0
