extends Node

const ScreenFade := preload("res://src/ui/fx/screen_fade.gd")

## Mission 9 polish: urutan kematian singkat (slow-mo + kamera mendekat).
## DeathScreen tetap muncul seketika; efek ini hanya "rasa" di belakang panel.
## Di headless tidak ada yang dijalankan, jadi tes tidak terpengaruh waktu.
## Slow-mo ikut setelan "Guncangan layar": bila dimatikan, urutan dilewati.

const SLOW_SCALE := 0.25
const SLOW_TIME := 0.18
const DEATH_ZOOM := 3.55
const NORMAL_ZOOM := 3.0

var _death: DeathController
var _player: Node
var _stats: StatsComponent
var _pcam: Node
var _dying: bool = false


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	set_process(false)
	_death = get_parent().get_node_or_null("DeathController") as DeathController
	if _death != null:
		_death.died.connect(_on_died)
	_player = get_tree().get_first_node_in_group(&"player")
	if _player != null:
		_stats = _player.get_node_or_null("StatsComponent") as StatsComponent
	var scene := get_tree().current_scene
	if scene != null:
		_pcam = scene.find_child("PhantomCamera2D", true, false)


func _process(_delta: float) -> void:
	if not _dying or _stats == null:
		return
	if _stats.current_hp > 0.0:
		_reset()


func is_dying() -> bool:
	return _dying


func _exit_tree() -> void:
	if _dying:
		Engine.time_scale = 1.0


## Dipakai tes: apakah slow-mo/zoom kematian diizinkan setelan pemain.
func is_slow_mo_enabled() -> bool:
	var service := SettingsService.find_service(self)
	return service == null or service.is_screenshake_enabled()


func _on_died(_respawns_remaining: int) -> void:
	if _dying or DisplayServer.get_name() == "headless" or not is_slow_mo_enabled():
		return
	_dying = true
	set_process(true)
	_slow_mo()
	_tween_zoom(DEATH_ZOOM, 0.45)


func _reset() -> void:
	_dying = false
	set_process(false)
	Engine.time_scale = 1.0
	_tween_zoom(NORMAL_ZOOM, 0.6)


func _slow_mo() -> void:
	var tween := create_tween()
	tween.set_ignore_time_scale(true)
	tween.tween_property(Engine, "time_scale", SLOW_SCALE, 0.06)
	tween.tween_interval(SLOW_TIME)
	tween.tween_property(Engine, "time_scale", 1.0, 0.14)


func _tween_zoom(value: float, duration: float) -> void:
	if _pcam == null:
		return
	var tween := create_tween()
	tween.set_ignore_time_scale(true)
	tween.tween_property(_pcam, "zoom", Vector2(value, value), duration).set_trans(Tween.TRANS_SINE)
