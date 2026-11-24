class_name NeedsComponent
extends Node

## Hunger, Thirst, Fatigue untuk satu entity (saat ini Player).
##
## Komponen ini pemilik tunggal nilai need. Modul lain hanya membaca getter /
## sinyal atau memanggil add()/spend_fatigue(); jangan menulis nilainya.
##
## Waktu: laju Hunger/Thirst dikalikan DayNightManager.get_time_scale(), jadi
## final dawn (0) membekukan drain dan Night Watch (2) menggandakannya tanpa
## penanganan khusus. Komponen ini tidak punya clock sendiri dan tidak
## menghitung wall-clock.
##
## Efek tier hanya lewat StatsComponent.add_modifier()/remove_modifier() dengan
## source_id tetap: &"lapar", &"haus", &"lelah". Satu source_id boleh membawa
## beberapa stat; semuanya dihapus bersama sebelum tier baru dipasang.
##
## Tier: NORMAL (> 25), LOW (<= 25 dan > 0), ZERO (<= 0). Tier ZERO mempertahankan
## efek LOW dan menimpanya bila stat-nya sama (Fatigue: move speed -45%).
##
## Fatigue punya plafon sendiri (`_fatigue_cap`, mulai dari max_value). Sprint
## menurunkan plafon itu sedikit demi sedikit, jadi setelah beberapa kali sprint
## nilai maksimum Fatigue bisa 80 dari 100. Jalan tidak menurunkan plafon, hanya
## menguras nilai. Diam memulihkan nilai sampai plafon. Makan
## (`restore_fatigue_capacity()`) dan tidur (time_skipped) menaikkan plafon lagi.

signal value_changed(need: int, value: float)
signal tier_changed(need: int, tier: int)
signal fatigue_cap_changed(cap: float)

enum Need { HUNGER, THIRST, FATIGUE }
enum Tier { NORMAL, LOW, ZERO }

const NEED_COUNT := 3
const SOURCE_IDS: Array[StringName] = [&"lapar", &"haus", &"lelah"]
## Mission 9: blokir sprint saat Hunger rendah (source_id tetap).
const HUNGER_SPRINT_BLOCK := &"hunger"
const DEFAULT_CONFIG: NeedsConfig = preload("res://src/data/configs/needs_config.tres")
const MANAGER_PATH := "/root/DayNightManager"

## Angka tuning. Null berarti memakai NeedsConfig() bawaan.
@export var config: NeedsConfig = DEFAULT_CONFIG

## Opsional: diisi otomatis (parent / autoload) bila dibiarkan kosong.
@export var clock: Node
@export var stats: StatsComponent
@export var player: Node

var _values: Array[float] = []
var _tiers: Array[int] = []
## Plafon Fatigue saat ini (<= config.max_value). -1 berarti belum diinisialisasi.
var _fatigue_cap: float = -1.0
var _is_sprinting: bool = false
var _bound: bool = false
## Override regen diam dari sumber luar (mis. `&"campfire"`).
var _idle_regen_overrides: Dictionary = {}
## Pengali regen override (mis. passive Second Wind). Hanya mengalikan regen
## yang datang dari override, bukan regen diam dasar.
var _idle_regen_multipliers: Dictionary = {}
var _warned_no_clock: bool = false


func _ready() -> void:
	_bind()


func _process(delta: float) -> void:
	tick(delta)


# --- Setup ------------------------------------------------------------------

## Rangkai dependensi secara eksplisit (dipakai tes dan scene lain).
## Bila dipanggil sebelum masuk tree, koneksi sinyal dilakukan di _ready().
func setup(p_clock: Node, p_stats: StatsComponent, p_player: Node) -> void:
	clock = p_clock
	stats = p_stats
	player = p_player
	if is_inside_tree():
		_bind()


func get_config() -> NeedsConfig:
	return config


# --- Public API -------------------------------------------------------------

func get_value(need: int) -> float:
	if not _is_valid_need(need):
		return 0.0
	_ensure_state()
	return _values[need]


func get_tier(need: int) -> int:
	if not _is_valid_need(need):
		return Tier.NORMAL
	_ensure_state()
	return _tiers[need]


## Plafon Fatigue saat ini. Turun saat sprint, naik lagi lewat makan/tidur.
func get_fatigue_cap() -> float:
	_ensure_state()
	return _fatigue_cap


## Makan / minum: menaikkan plafon Fatigue sampai paling tinggi max_value DAN
## mengisi nilai Fatigue sebanyak `amount` (dibatasi plafon baru). Satu panggilan
## ini sudah cukup untuk item; jangan memanggil `add(Need.FATIGUE, ...)` lagi.
func restore_fatigue_capacity(amount: float) -> void:
	if amount <= 0.0:
		return
	_ensure_state()
	_set_fatigue_cap(_fatigue_cap + amount)
	_apply_value(Need.FATIGUE, _values[Need.FATIGUE] + amount)


## Satu-satunya jalur tulis nilai selain add()/tick(). Nilai di-clamp 0..max.
func set_value(need: int, value: float) -> void:
	if not _is_valid_need(need):
		push_warning("NeedsComponent: need %d tidak dikenal; set_value diabaikan." % need)
		return
	_ensure_state()
	_apply_value(need, value)


func add(need: int, amount: float) -> void:
	if not _is_valid_need(need):
		push_warning("NeedsComponent: need %d tidak dikenal; add diabaikan." % need)
		return
	if is_zero_approx(amount):
		return
	_ensure_state()
	_apply_value(need, _values[need] + amount)


## Regen diam efektif: `max(fatigue_idle_regen, override tertinggi)`. Selalu
## dibatasi plafon Fatigue karena lewat `_apply_value()`.
func get_idle_regen() -> float:
	if config == null:
		return 0.0
	var override_value := -1.0
	for source_id in _idle_regen_overrides:
		override_value = maxf(override_value, float(_idle_regen_overrides[source_id]))
	if override_value <= 0.0:
		return config.fatigue_idle_regen

	# Pengali hanya berlaku pada regen override; bila override tidak lebih
	# tinggi dari regen dasar, regen dasar yang dipakai tanpa pengali.
	if override_value <= config.fatigue_idle_regen:
		return config.fatigue_idle_regen
	var multiplier := 1.0
	for source_id in _idle_regen_multipliers:
		multiplier *= float(_idle_regen_multipliers[source_id])
	return override_value * multiplier


## Pengali untuk regen override saja (passive Speed Lv6 Second Wind).
func set_idle_regen_multiplier(source_id: StringName, multiplier: float) -> void:
	_idle_regen_multipliers[source_id] = maxf(multiplier, 0.0)


func clear_idle_regen_multiplier(source_id: StringName) -> void:
	_idle_regen_multipliers.erase(source_id)


## Tambah/ubah override regen diam dari satu sumber (mis. Campfire menyala).
## Additive: sumber lain tetap aktif; yang dipakai nilai tertinggi.
func set_idle_regen_override(source_id: StringName, per_second: float) -> void:
	_idle_regen_overrides[source_id] = maxf(per_second, 0.0)


## Hapus override satu sumber (mis. pemain keluar radius / api padam).
func clear_idle_regen_override(source_id: StringName) -> void:
	_idle_regen_overrides.erase(source_id)


## Biaya Fatigue manual: serangan (-1.2) dan gather (-2.0) menyusul.
func spend_fatigue(amount: float) -> void:
	if amount <= 0.0:
		return
	add(Need.FATIGUE, -amount)


## Satu tick gameplay. _process() hanya memanggil fungsi ini supaya tes bisa
## menggerakkannya secara deterministik.
func tick(delta: float) -> void:
	if delta <= 0.0:
		return

	_ensure_state()
	var game_delta := delta * _time_scale()
	if game_delta > 0.0:
		var night := _is_night()
		var day := _day()
		var hunger_rate := config.hunger_night_drain if night else config.hunger_day_drain
		var thirst_rate := config.thirst_night_drain if night else config.thirst_day_drain
		hunger_rate *= config.hunger_drain_scale(day)
		thirst_rate *= config.thirst_drain_scale(day)
		_apply_value(Need.HUNGER, _values[Need.HUNGER] - hunger_rate * game_delta)
		_apply_value(Need.THIRST, _values[Need.THIRST] - thirst_rate * game_delta)
		_apply_zero_tier_hp_loss(game_delta)

	# Fatigue memakai waktu nyata, bukan time_scale hari/malam:
	# - sprint: nilai turun cepat (dikali faktor StatsComponent) DAN plafon turun;
	# - jalan: nilai turun pelan, plafon tetap;
	# - diam: nilai pulih sampai plafon.
	if _is_sprinting:
		var factor := 1.0
		if stats != null:
			factor = stats.get_sprint_fatigue_drain_factor()
		_apply_value(Need.FATIGUE, _values[Need.FATIGUE] - config.fatigue_sprint_drain * factor * delta)
		if config.fatigue_sprint_cap_drain > 0.0:
			_set_fatigue_cap(_fatigue_cap - config.fatigue_sprint_cap_drain * delta)
	elif _is_moving():
		if config.fatigue_walk_drain > 0.0:
			_apply_value(Need.FATIGUE, _values[Need.FATIGUE] - config.fatigue_walk_drain * delta)
	else:
		var idle_regen := get_idle_regen()
		if idle_regen > 0.0:
			_apply_value(Need.FATIGUE, _values[Need.FATIGUE] + idle_regen * delta)


# --- Internal ---------------------------------------------------------------

func _bind() -> void:
	if config == null:
		push_warning("NeedsComponent: config kosong; memakai NeedsConfig() bawaan.")
		config = NeedsConfig.new()

	_resolve_refs()
	_ensure_state()

	if _bound:
		_refresh_sprint_lock()
		_reapply_tier_modifiers()
		return
	_bound = true

	if clock != null and clock.has_signal("time_skipped"):
		clock.connect("time_skipped", _on_time_skipped)
	if player != null and player.has_signal("sprint_state_changed"):
		player.connect("sprint_state_changed", _on_sprint_state_changed)

	_reapply_tier_modifiers()


func _resolve_refs() -> void:
	if player == null:
		player = get_parent()
	if stats == null and player != null:
		stats = player.get_node_or_null("StatsComponent") as StatsComponent
	if clock == null:
		clock = get_node_or_null(MANAGER_PATH)


func _ensure_state() -> void:
	if config == null:
		config = NeedsConfig.new()
	if not _values.is_empty():
		return

	_values.resize(NEED_COUNT)
	_tiers.resize(NEED_COUNT)
	var start := clampf(config.start_value, 0.0, config.max_value)
	for need in NEED_COUNT:
		_values[need] = start
		_tiers[need] = _tier_for_value(start)
	if _fatigue_cap < 0.0:
		_fatigue_cap = clampf(config.max_value, 0.0, config.max_value)
	_refresh_sprint_lock()


func _is_valid_need(need: int) -> bool:
	return need >= 0 and need < NEED_COUNT


func _tier_for_value(value: float) -> int:
	if value <= config.zero_threshold:
		return Tier.ZERO
	if value <= config.low_threshold:
		return Tier.LOW
	return Tier.NORMAL


## Plafon Fatigue hanya berubah lewat sini supaya nilai Fatigue ikut turun bila
## plafonnya turun di bawah nilai saat ini (mis. sprint panjang).
func _set_fatigue_cap(value: float) -> void:
	var clamped := clampf(value, 0.0, config.max_value)
	if is_equal_approx(clamped, _fatigue_cap):
		return
	_fatigue_cap = clamped
	if not _values.is_empty() and _values[Need.FATIGUE] > _fatigue_cap:
		_apply_value(Need.FATIGUE, _fatigue_cap)
	fatigue_cap_changed.emit(_fatigue_cap)


## Batas atas satu need: Fatigue dibatasi plafonnya, lainnya config.max_value.
func _max_for(need: int) -> float:
	if need == Need.FATIGUE:
		return minf(config.max_value, _fatigue_cap)
	return config.max_value


## Tulis satu nilai, pancarkan sinyal hanya bila berubah, lalu perbarui tier.
## Nilai selalu disimpan; is_equal_approx hanya memutuskan sinyal. Kalau
## penyimpanan ikut dijaga olehnya, drain per frame yang lebih kecil dari
## toleransi (layar 240 Hz di nilai mendekati 100) akan hilang, bukan menumpuk.
func _apply_value(need: int, value: float) -> void:
	var clamped := clampf(value, 0.0, _max_for(need))
	var changed := not is_equal_approx(clamped, _values[need])
	_values[need] = clamped
	if changed:
		value_changed.emit(need, clamped)
		if need == Need.FATIGUE:
			_refresh_sprint_lock()
		elif need == Need.HUNGER:
			_refresh_hunger_sprint_lock()
	_update_tier(need)


func _update_tier(need: int) -> void:
	var tier := _tier_for_value(_values[need])
	if tier == _tiers[need]:
		return
	_tiers[need] = tier
	_apply_tier_modifiers(need, tier)
	tier_changed.emit(need, tier)


func _apply_tier_modifiers(need: int, tier: int) -> void:
	if stats == null:
		return

	var source: StringName = SOURCE_IDS[need]
	# Hapus paket tier sebelumnya dulu agar stat tidak menumpuk.
	stats.remove_modifier(source)
	if tier == Tier.NORMAL:
		return

	match need:
		Need.HUNGER:
			_add_percent(source, &"move_speed", config.hunger_low_move_speed)
			_add_percent(source, &"attack_damage", config.hunger_low_attack_damage)
		Need.THIRST:
			_add_percent(source, &"sprint_fatigue_drain", config.thirst_low_sprint_fatigue_drain)
			_add_percent(source, &"attack_speed", config.thirst_low_attack_speed)
		Need.FATIGUE:
			if tier == Tier.ZERO:
				_add_percent(source, &"move_speed", config.fatigue_zero_move_speed)
				_add_percent(source, &"attack_speed", config.fatigue_zero_attack_speed)
			else:
				_add_percent(source, &"move_speed", config.fatigue_low_move_speed)
			_add_percent(source, &"gather_time", config.fatigue_gather_time)


func _add_percent(source: StringName, stat: StringName, value: float) -> void:
	stats.add_modifier(source, stat, StatModifier.Kind.PERCENT, value)


## Pasang ulang paket modifier untuk tier yang sedang aktif. Dipanggil _bind()
## agar efek tier tidak hilang bila StatsComponent baru tersedia belakangan
## (mis. setup() setelah nilai sempat turun). _apply_tier_modifiers() selalu
## menghapus paket lama dulu, jadi aman dipanggil berkali-kali.
func _reapply_tier_modifiers() -> void:
	if stats == null or _tiers.is_empty():
		return
	for need in NEED_COUNT:
		_apply_tier_modifiers(need, _tiers[need])


## HP hilang saat Hunger/Thirst ZERO; keduanya menumpuk.
func _apply_zero_tier_hp_loss(game_delta: float) -> void:
	if stats == null or game_delta <= 0.0:
		return

	var loss := 0.0
	if _tiers[Need.HUNGER] == Tier.ZERO:
		loss += config.hunger_zero_hp_loss
	if _tiers[Need.THIRST] == Tier.ZERO:
		loss += config.thirst_zero_hp_loss
	if loss <= 0.0:
		return

	# get_max_hp() memastikan cache/HP StatsComponent sudah terinisialisasi.
	stats.get_max_hp()
	stats.set_hp(stats.current_hp - loss * game_delta)


## Tidur Tenda: drain fase berjalan untuk detik yang dilewati, tetapi Hunger
## dan Thirst tidak pernah turun di bawah sleep_min_value. Tidur juga memulihkan
## plafon Fatigue dan mengisi Fatigue sampai plafon barunya (bangun segar).
func _on_time_skipped(seconds: float) -> void:
	if seconds <= 0.0:
		return

	_ensure_state()
	_set_fatigue_cap(_fatigue_cap + config.sleep_fatigue_cap_restore)
	_apply_value(Need.FATIGUE, _fatigue_cap)
	var night := _is_night()
	var day := _day()
	var hunger_rate := config.hunger_night_drain if night else config.hunger_day_drain
	var thirst_rate := config.thirst_night_drain if night else config.thirst_day_drain
	hunger_rate *= config.hunger_drain_scale(day)
	thirst_rate *= config.thirst_drain_scale(day)
	_apply_sleep_drain(Need.HUNGER, hunger_rate * seconds)
	_apply_sleep_drain(Need.THIRST, thirst_rate * seconds)


func _apply_sleep_drain(need: int, amount: float) -> void:
	var current := _values[need]
	if current <= config.sleep_min_value:
		return
	_apply_value(need, maxf(current - amount, config.sleep_min_value))


func _on_sprint_state_changed(is_sprinting: bool) -> void:
	_is_sprinting = is_sprinting


## Sprint dikunci saat Fatigue <= low_threshold. Hanya can_sprint yang diubah;
## velocity dan base stats tetap milik Player/StatsComponent.
func _refresh_sprint_lock() -> void:
	if player == null or not ("can_sprint" in player):
		return
	if _values.is_empty():
		return
	player.can_sprint = _values[Need.FATIGUE] > config.low_threshold


## Mission 9: Hunger <= threshold memblokir sprint lewat Player.add_sprint_block().
func _refresh_hunger_sprint_lock() -> void:
	if player == null or _values.is_empty():
		return
	if not player.has_method(&"add_sprint_block"):
		return
	if _values[Need.HUNGER] <= config.hunger_sprint_lock_threshold:
		player.add_sprint_block(HUNGER_SPRINT_BLOCK)
	else:
		player.remove_sprint_block(HUNGER_SPRINT_BLOCK)


func is_hunger_sprint_locked() -> bool:
	_ensure_state()
	return _values[Need.HUNGER] <= config.hunger_sprint_lock_threshold


## Player tidak punya sinyal gerak, jadi velocity dibaca langsung bila tersedia.
## Stub/entity tanpa velocity dianggap diam.
func _is_moving() -> bool:
	if player == null or not ("velocity" in player):
		return false
	var velocity: Vector2 = player.velocity
	return velocity.length_squared() > 1.0


func _time_scale() -> float:
	if clock == null or not clock.has_method("get_time_scale"):
		if not _warned_no_clock:
			_warned_no_clock = true
			push_warning("NeedsComponent: DayNightManager tidak ditemukan; drain memakai time_scale 1.0.")
		return 1.0
	return clock.get_time_scale()


func _is_night() -> bool:
	if clock == null or not clock.has_method("is_night"):
		return false
	return clock.is_night()


func _day() -> int:
	if clock == null or not clock.has_method("get_current_day"):
		return 1
	return int(clock.get_current_day())


## Hook untuk HealthRegenComponent: multiplier min dari kurva Hunger/Thirst.
func get_hunger_value() -> float:
	return get_value(Need.HUNGER)


func get_thirst_value() -> float:
	return get_value(Need.THIRST)


func is_zero_tier(need: int) -> bool:
	return get_tier(need) == Tier.ZERO
