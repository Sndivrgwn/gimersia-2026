extends Node

## Pengendali animasi untuk MainMenuAnimated.
## Terpisah dari main_menu.gd agar seluruh logika navigasi, preload, dan overlay
## asli tetap utuh tanpa modifikasi.

const CRAB_MIN_X := 820.0
const CRAB_MAX_X := 1100.0
const CRAB_SPEED := 42.0

const HOVER_SCALE := Vector2(1.07, 1.07)
const HOVER_TINT := Color(1.12, 1.08, 1.0, 1.0)
const IDLE_TINT := Color(1.0, 1.0, 1.0, 1.0)
const TRANSITION_TIME := 0.18

@export var title_block_path: NodePath = ^"../TitleBlock"
@export var accent_line_path: NodePath = ^"../TitleBlock/EyebrowRow/AccentLine"
@export var aurora_back_path: NodePath = ^"../AnimatedVisuals/AuroraBack"
@export var aurora_front_path: NodePath = ^"../AnimatedVisuals/AuroraFront"
@export var water_waves_path: NodePath = ^"../AnimatedVisuals/WaterWaves"
@export var plane_smoke_path: NodePath = ^"../AnimatedVisuals/PlaneSmoke"
@export var beach_crab_path: NodePath = ^"../AnimatedVisuals/BeachCrab"

var _title_block: Control
var _accent_line: ColorRect
var _aurora_back: TextureRect
var _aurora_front: TextureRect
var _plane_smoke: CPUParticles2D
var _beach_crab: AnimatedSprite2D

var _title_base_y := 0.0
var _aurora_back_base := Vector2.ZERO
var _aurora_front_base := Vector2.ZERO
var _crab_base_y := 0.0
var _crab_dir := 1.0
var _time := 0.0

var _waves: Array[Control] = []
var _wave_base_pos: Array[Vector2] = []

var _buttons: Array[Button] = []
var _button_tweens: Dictionary = {}
var _button_active: Dictionary = {}
var _button_phase: Dictionary = {}


func _ready() -> void:
	_title_block = get_node_or_null(title_block_path) as Control
	_accent_line = get_node_or_null(accent_line_path) as ColorRect
	_aurora_back = get_node_or_null(aurora_back_path) as TextureRect
	_aurora_front = get_node_or_null(aurora_front_path) as TextureRect
	_plane_smoke = get_node_or_null(plane_smoke_path) as CPUParticles2D
	_beach_crab = get_node_or_null(beach_crab_path) as AnimatedSprite2D

	if _title_block != null:
		_title_base_y = _title_block.position.y
	if _aurora_back != null:
		_aurora_back_base = _aurora_back.position
	if _aurora_front != null:
		_aurora_front_base = _aurora_front.position
	if _plane_smoke != null:
		_plane_smoke.emitting = true
	if _beach_crab != null:
		_crab_base_y = _beach_crab.position.y
		_beach_crab.play(&"walk")

	var waves_container := get_node_or_null(water_waves_path)
	if waves_container != null:
		for child in waves_container.get_children():
			if child is Control:
				_waves.append(child)
				_wave_base_pos.append(child.position)

	_setup_buttons()


func _process(delta: float) -> void:
	_time += delta
	_animate_ambient()
	_animate_waves()
	_animate_crab(delta)
	_animate_idle_buttons()


func _animate_ambient() -> void:
	if _title_block != null:
		_title_block.position.y = _title_base_y + sin(_time * 1.4) * 3.0
	if _accent_line != null:
		_accent_line.modulate.a = 0.8 + sin(_time * 2.2) * 0.2
	# Aurora bergerak menyamping seperti aurora asli (layer belakang lebih redup)
	if _aurora_back != null:
		_aurora_back.position.x = _aurora_back_base.x + sin(_time * 0.45) * 44.0
		_aurora_back.position.y = _aurora_back_base.y + cos(_time * 0.35) * 5.0
		_aurora_back.modulate.a = 0.32 + sin(_time * 0.65) * 0.08
	if _aurora_front != null:
		_aurora_front.position.x = _aurora_front_base.x + sin(_time * 0.7 + 1.4) * 34.0
		_aurora_front.position.y = _aurora_front_base.y + cos(_time * 0.5) * 4.0
		_aurora_front.modulate.a = 0.66 + sin(_time * 0.85 + 0.8) * 0.14
	if _plane_smoke != null:
		_plane_smoke.gravity = Vector2(8.0 + sin(_time * 0.65) * 5.0, -6.0)


func _animate_waves() -> void:
	for i in _waves.size():
		var wave := _waves[i]
		var base := _wave_base_pos[i]
		var phase := float(i) * 1.7
		var speed := 1.1 + float(i) * 0.25
		wave.position.x = base.x + sin(_time * speed + phase) * 26.0
		wave.position.y = base.y + cos(_time * (speed * 1.3) + phase) * 3.0
		wave.modulate.a = 0.45 + sin(_time * 1.4 + phase) * 0.2


func _animate_crab(delta: float) -> void:
	if _beach_crab == null:
		return
	var next_x := _beach_crab.position.x + _crab_dir * CRAB_SPEED * delta
	if next_x >= CRAB_MAX_X:
		next_x = CRAB_MAX_X
		_crab_dir = -1.0
		_beach_crab.flip_h = true
	elif next_x <= CRAB_MIN_X:
		next_x = CRAB_MIN_X
		_crab_dir = 1.0
		_beach_crab.flip_h = false
	_beach_crab.position.x = next_x
	_beach_crab.position.y = _crab_base_y + absf(sin(_time * 5.0)) * -2.0


func _animate_idle_buttons() -> void:
	for btn in _buttons:
		if not is_instance_valid(btn):
			continue
		if bool(_button_active.get(btn, false)):
			continue
		var tween := _button_tweens.get(btn) as Tween
		if tween != null and tween.is_valid():
			continue
		var phase := float(_button_phase.get(btn, 0.0))
		var pulse := 1.0 + sin(_time * 2.1 + phase) * 0.015
		btn.scale = Vector2(pulse, pulse)


func _setup_buttons() -> void:
	var root := get_parent()
	if root == null:
		return
	var candidates: Array[String] = ["StartButton", "ControlsButton", "CreditsButton", "QuitButton"]
	for index in candidates.size():
		var btn := root.find_child(candidates[index], true, false) as Button
		if btn == null:
			continue
		_buttons.append(btn)
		_button_phase[btn] = float(index) * 0.85
		_button_active[btn] = btn.has_focus()
		_recenter_button_pivot(btn)
		btn.resized.connect(_recenter_button_pivot.bind(btn))
		btn.mouse_entered.connect(_on_button_state_changed.bind(btn))
		btn.mouse_exited.connect(_on_button_state_changed.bind(btn))
		btn.focus_entered.connect(_on_button_state_changed.bind(btn))
		btn.focus_exited.connect(_on_button_state_changed.bind(btn))
		if btn.has_focus():
			_tween_button(btn, true)


func _recenter_button_pivot(btn: Button) -> void:
	btn.pivot_offset = btn.size * 0.5


func _on_button_state_changed(btn: Button) -> void:
	var active := btn.is_hovered() or btn.has_focus()
	if bool(_button_active.get(btn, false)) == active:
		return
	_button_active[btn] = active
	_tween_button(btn, active)


func _tween_button(btn: Button, active: bool) -> void:
	var old_tween := _button_tweens.get(btn) as Tween
	if old_tween != null and old_tween.is_valid():
		old_tween.kill()
	var target_scale := HOVER_SCALE if active else Vector2.ONE
	var target_tint := HOVER_TINT if active else IDLE_TINT
	var tween := create_tween().set_parallel(true)
	tween.tween_property(btn, "scale", target_scale, TRANSITION_TIME).set_trans(Tween.TRANS_BACK if active else Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(btn, "modulate", target_tint, TRANSITION_TIME).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	_button_tweens[btn] = tween
