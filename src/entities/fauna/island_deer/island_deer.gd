class_name IslandDeer
extends FaunaBase

## Rusa pulau: selalu PASSIVE, tidak menyerang. Kabur 175 px/s selama 5 detik
## saat pemain dalam 130 px atau setelah terkena serangan.
## Mission 9 fase 4: sebelum kabur rusa berhenti WASPADA sejenak (tanda visual)
## dan radius deteksinya diperkecil bila pemain jongkok.

signal alerted

## Mission 10 Phase 4: WANDER -> ALERT -> STARTLE -> FLEE. STARTLE memberi
## jaminan minimal satu serangan bisa mendarat sebelum rusa berlari.
enum State { WANDER, FLEE, ALERT, STARTLE }

var state: int = State.WANDER
var _alert_remaining: float = 0.0
var _startle_remaining: float = 0.0
## Mission 10 Phase 4: serangan pertama memaku rusa sesaat (jendela hit kedua).
var _hit_stun_remaining: float = 0.0
var _flee_speed_now: float = 0.0
## Waktu gerak kabur (hit-stun tidak dihitung) untuk ramp kecepatan.
var _flee_accel_elapsed: float = 0.0
## Tell waspada: "!" di atas kepala rusa, dibuat runtime (tanpa aset).
var _alert_mark: Label


func _ready() -> void:
	super()
	ensure_ready()
	temperament = Temperament.PASSIVE
	_ensure_alert_mark()


func get_state() -> int:
	return state


func visual_key() -> StringName:
	return &"island_deer"


## True saat rusa sedang menegakkan kepala (belum kabur).
func is_alerted() -> bool:
	return state == State.ALERT


func get_alert_remaining() -> float:
	return _alert_remaining


## Label "!" di atas rusa (visible hanya saat waspada).
func get_alert_mark() -> Label:
	return _alert_mark


func is_alert_mark_visible() -> bool:
	return _alert_mark != null and _alert_mark.visible


## Radius deteksi efektif terhadap pemain (jongkok memperkecil).
func get_effective_detect_radius() -> float:
	return _deer_config().flee_trigger_radius * get_detection_multiplier(_find_player())


func _update_behavior(delta: float) -> void:
	var deer := _deer_config()
	var target := _find_player()
	if target is Node2D:
		var distance := global_position.distance_to((target as Node2D).global_position)
		var detect := maxf(deer.flee_trigger_radius * get_detection_multiplier(target), deer.sneak_notice_floor_px)
		if state == State.STARTLE:
			_tick_startle(deer, delta, (target as Node2D).global_position)
			return
		if state == State.FLEE:
			_tick_flee(delta)
			return
		var alert_radius := detect * maxf(deer.alert_radius_factor, 1.0)
		if distance <= alert_radius:
			_tick_alert(deer, delta)
			return
	state = State.WANDER
	_alert_remaining = 0.0
	_startle_remaining = 0.0
	_flee_speed_now = 0.0
	clear_provoke()
	_set_alert_mark(false)
	_wander(delta)


## Berhenti dan "menegakkan kepala"; sinyal `alerted` hanya sekali per waspada.
func _tick_alert(deer: DeerConfig, delta: float) -> void:
	# Berhenti total setiap tick waspada (art `idle` = kepala terangkat).
	velocity = Vector2.ZERO
	move_and_slide()
	_set_alert_mark(true)
	if state != State.ALERT:
		state = State.ALERT
		_alert_remaining = deer.alert_time
		alerted.emit()
		return
	_alert_remaining = maxf(_alert_remaining - delta, 0.0)
	if is_zero_approx(_alert_remaining):
		# Tetap terlihat: masuk STARTLE (terpaku), bukan langsung kabur.
		state = State.STARTLE
		_startle_remaining = deer.startle_seconds


## Rusa terpaku dan tetap bisa dipukul; setelah timer habis baru kabur.
func _tick_startle(deer: DeerConfig, delta: float, threat: Vector2) -> void:
	velocity = Vector2.ZERO
	move_and_slide()
	_set_alert_mark(true)
	_startle_remaining = maxf(_startle_remaining - delta, 0.0)
	if not is_zero_approx(_startle_remaining):
		return
	_set_alert_mark(false)
	begin_flee(threat, deer.flee_duration)
	state = State.FLEE


func is_startling() -> bool:
	return state == State.STARTLE


func get_startle_remaining() -> float:
	return _startle_remaining


func get_hit_stun_remaining() -> float:
	return _hit_stun_remaining


## Kecepatan kabur saat ini (0 di awal FLEE, lalu naik linear sampai penuh).
func get_current_flee_speed() -> float:
	return _flee_speed_now


func _ensure_alert_mark() -> void:
	if _alert_mark != null:
		return
	_alert_mark = Label.new()
	_alert_mark.name = "AlertMark"
	_alert_mark.text = "!"
	_alert_mark.position = Vector2(-4.0, -44.0)
	_alert_mark.add_theme_color_override("font_color", Color(1.0, 0.85, 0.3, 1.0))
	_alert_mark.visible = false
	add_child(_alert_mark)


func _set_alert_mark(value: bool) -> void:
	if _alert_mark != null and _alert_mark.visible != value:
		_alert_mark.visible = value


func _deer_config() -> DeerConfig:
	var deer := config as DeerConfig
	return deer if deer != null else DeerConfig.new()


## Damage di WANDER/ALERT/STARTLE langsung ke FLEE + hit-stun singkat, sehingga
## serangan kedua masih bisa mendarat sebelum rusa benar-benar berlari.
## Setiap mulai kabur, ramp dimulai dari nol lagi.
func begin_flee(from_position: Vector2, duration: float) -> void:
	super(from_position, duration)
	_flee_accel_elapsed = 0.0


func _on_provoked(source: Node) -> void:
	var from := global_position
	if source is Node2D:
		from = (source as Node2D).global_position
	var deer := _deer_config()
	begin_flee(from, deer.flee_duration)
	state = State.FLEE
	_hit_stun_remaining = maxf(deer.hit_stun, 0.0)
	_flee_speed_now = 0.0
	_set_alert_mark(false)


func _tick_flee(delta: float) -> void:
	state = State.FLEE
	_set_alert_mark(false)
	var deer := _deer_config()
	_flee_remaining = maxf(_flee_remaining - delta, 0.0)
	_flee_elapsed += delta
	var target := _find_player()
	var far_enough := target is Node2D and global_position.distance_to((target as Node2D).global_position) >= config.flee_despawn_distance
	if far_enough or _flee_elapsed >= config.flee_despawn_timeout:
		despawn()
		return
	# Hit-stun: terpaku dulu, jadi serangan kedua masih dalam jangkauan.
	if _hit_stun_remaining > 0.0:
		_hit_stun_remaining = maxf(_hit_stun_remaining - delta, 0.0)
		_flee_speed_now = 0.0
		move_in_direction(Vector2.ZERO, 0.0, delta)
		return
	# Ramp linear 0 -> flee_speed selama flee_accel_seconds.
	_flee_accel_elapsed += delta
	var ramp := 1.0
	if deer.flee_accel_seconds > 0.0:
		ramp = clampf(_flee_accel_elapsed / deer.flee_accel_seconds, 0.0, 1.0)
	_flee_speed_now = deer.flee_speed * ramp
	move_in_direction(_flee_direction, _flee_speed_now, delta)
	if _flee_remaining <= 0.0:
		state = State.WANDER
		_hit_stun_remaining = 0.0
		_flee_speed_now = 0.0
		clear_provoke()
