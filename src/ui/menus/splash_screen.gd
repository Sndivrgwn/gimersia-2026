class_name SplashScreen
extends Control

## Layar pembuka (splash / loading screen) sebelum menu utama.
## Memutar urutan logo dari SplashConfig, memuat scene berikutnya di latar
## belakang lewat ResourceLoader threaded, lalu berpindah setelah selesai.
## Tidak menyentuh DayNightManager maupun time_scale.

signal entry_started(index: int)
signal finished(failed: bool)
signal transition_started
signal transition_finished

const DEFAULT_CONFIG_PATH := "res://src/data/configs/ui/splash_config.tres"
const BG_SLOT_KEY := &"ui_splash_bg"
const ENV_SKIP := "GIMERSIA_SKIP_SPLASH"
const ERROR_TEXT := "Gagal memuat game"

## True setelah splash selesai sekali pada sesi ini.
static var shown_this_session: bool = false


## Pembungkus tipis ResourceLoader threaded agar bisa di-stub di unit test.
class DefaultLoader extends RefCounted:
	func exists(path: String) -> bool:
		return not path.is_empty() and ResourceLoader.exists(path)

	func request(path: String) -> int:
		return ResourceLoader.load_threaded_request(path)

	func status(path: String) -> Dictionary:
		var progress: Array = []
		var state := ResourceLoader.load_threaded_get_status(path, progress)
		var value := float(progress[0]) if not progress.is_empty() else 0.0
		return {"state": state, "progress": value}

	func get_packed(path: String) -> PackedScene:
		return ResourceLoader.load_threaded_get(path) as PackedScene


@export var config: SplashConfig

## Loader yang bisa di-inject untuk unit test sebelum _ready().
var loader: RefCounted

@onready var _background: ColorRect = $Background
@onready var _background_texture: TextureRect = $BackgroundTexture
@onready var _center: CenterContainer = $Center
@onready var _logo_texture: TextureRect = $Center/LogoTexture
@onready var _fallback_label: Label = $Center/FallbackLabel
@onready var _loading_bar: ProgressBar = $LoadingBar
@onready var _loading_label: Label = $LoadingLabel

var _active_config: SplashConfig
var _sequencer: SplashSequencer
var _next_path: String = ""
var _preload_paths: PackedStringArray = PackedStringArray()
var _switched: bool = false
var _error_shown: bool = false
var _bypass_transition: bool = false
var _active_overlay: IrisOverlay


func _ready() -> void:
	_active_config = _resolve_config()
	if loader == null:
		loader = DefaultLoader.new()

	_apply_static_ui()
	_connect_viewport_resize()
	_update_logo_bounds()

	_sequencer = SplashSequencer.new()
	_sequencer.entry_started.connect(_on_entry_started)
	_sequencer.finished.connect(_on_sequencer_finished)
	_sequencer.setup(_active_config)

	var dev_or_env_skip := _active_config.dev_skip or OS.get_environment(ENV_SKIP) == "1"
	var session_skip := _active_config.skip_if_already_shown and SplashScreen.shown_this_session
	_bypass_transition = dev_or_env_skip or session_skip
	if _bypass_transition:
		_sequencer.force_skip_sequence()

	_start_threaded_loads()
	_apply_visual_state()


func _process(delta: float) -> void:
	if _switched or _error_shown or _sequencer == null:
		return
	_poll_loader()
	if _switched or _error_shown:
		return
	_sequencer.tick(delta)
	_apply_visual_state()


func _input(event: InputEvent) -> void:
	if _switched or _error_shown or _sequencer == null:
		return
	if _is_skip_event(event):
		_sequencer.skip()
		var viewport := get_viewport()
		if viewport != null:
			viewport.set_input_as_handled()


func get_sequencer() -> SplashSequencer:
	return _sequencer


# --- Overridable hooks (untuk unit test) ------------------------------------

func _change_scene(packed: PackedScene) -> void:
	var tree := get_tree()
	if tree == null or packed == null:
		return
	tree.change_scene_to_packed(packed)


func _change_scene_direct(path: String) -> int:
	var tree := get_tree()
	if tree == null or path.is_empty():
		return ERR_CANT_OPEN
	return tree.change_scene_to_file(path)


func _lookup_ui_texture(key: StringName) -> Texture2D:
	if String(key).is_empty():
		return null
	return Assets.ui_texture(key)


func _create_iris_overlay() -> IrisOverlay:
	return IrisOverlay.new()


func get_active_overlay() -> IrisOverlay:
	return _active_overlay if is_instance_valid(_active_overlay) else null


# --- Internal ---------------------------------------------------------------

func _resolve_config() -> SplashConfig:
	if config != null:
		return config
	if ResourceLoader.exists(DEFAULT_CONFIG_PATH):
		var loaded := ResourceLoader.load(DEFAULT_CONFIG_PATH) as SplashConfig
		if loaded != null:
			return loaded
	return SplashConfig.new()


func _apply_static_ui() -> void:
	_background.color = _active_config.background_color
	var bg_texture := _lookup_ui_texture(BG_SLOT_KEY)
	if bg_texture != null:
		_background_texture.texture = bg_texture
		_background_texture.visible = true
	else:
		_background_texture.texture = null
		_background_texture.visible = false

	_loading_label.text = _active_config.loading_label
	_loading_bar.min_value = 0.0
	_loading_bar.max_value = 1.0
	_loading_bar.value = 0.0
	_loading_bar.visible = _active_config.show_loading_bar
	_loading_label.visible = _active_config.show_loading_bar

	_logo_texture.visible = false
	_fallback_label.visible = false
	_logo_texture.modulate.a = 0.0
	_fallback_label.modulate.a = 0.0


func _connect_viewport_resize() -> void:
	var viewport := get_viewport()
	if viewport != null and not viewport.size_changed.is_connected(_update_logo_bounds):
		viewport.size_changed.connect(_update_logo_bounds)
	if not resized.is_connected(_update_logo_bounds):
		resized.connect(_update_logo_bounds)


func _update_logo_bounds() -> void:
	if _logo_texture == null or _active_config == null:
		return
	var viewport_size := size
	var viewport := get_viewport()
	if viewport != null:
		var visible_rect := viewport.get_visible_rect().size
		if visible_rect.x > 0.0 and visible_rect.y > 0.0:
			viewport_size = visible_rect
	if viewport_size.x <= 0.0 or viewport_size.y <= 0.0:
		viewport_size = Vector2(1280.0, 720.0)
	var ratio := clampf(_active_config.logo_max_size_ratio, 0.05, 1.0)
	_logo_texture.custom_minimum_size = viewport_size * ratio


func _start_threaded_loads() -> void:
	_next_path = _active_config.next_scene_path.strip_edges()
	_preload_paths.clear()
	var seen: Dictionary = {}

	if _next_path.is_empty() or not _path_exists(_next_path):
		push_warning("SplashScreen: next_scene_path tidak ditemukan: %s" % _next_path)
		_sequencer.notify_load_done(false)
		return

	seen[_next_path] = true
	var req_error: int = int(loader.call(&"request", _next_path))
	if req_error != OK:
		push_warning("SplashScreen: gagal memulai load %s (error %d)" % [_next_path, req_error])
		_sequencer.notify_load_done(false)
		return

	for raw_path in _active_config.preload_paths:
		var path := String(raw_path).strip_edges()
		if path.is_empty() or seen.has(path):
			continue
		if not _path_exists(path):
			push_warning("SplashScreen: preload_path tidak ditemukan, diabaikan: %s" % path)
			continue
		seen[path] = true
		var preload_err: int = int(loader.call(&"request", path))
		if preload_err == OK:
			_preload_paths.append(path)


func _path_exists(path: String) -> bool:
	if loader != null and loader.has_method(&"exists"):
		return bool(loader.call(&"exists", path))
	return ResourceLoader.exists(path)


func _poll_loader() -> void:
	if _next_path.is_empty():
		return
	var info: Dictionary = loader.call(&"status", _next_path)
	var status_code: int = int(info.get("state", ResourceLoader.THREAD_LOAD_INVALID_RESOURCE))
	var progress: float = float(info.get("progress", 0.0))
	if status_code == ResourceLoader.THREAD_LOAD_IN_PROGRESS:
		_sequencer.notify_load_progress(progress)
	elif status_code == ResourceLoader.THREAD_LOAD_LOADED:
		_sequencer.notify_load_progress(1.0)
		_sequencer.notify_load_done(true)
	elif status_code == ResourceLoader.THREAD_LOAD_FAILED or status_code == ResourceLoader.THREAD_LOAD_INVALID_RESOURCE:
		_sequencer.notify_load_done(false)

	for path in _preload_paths:
		loader.call(&"status", path)


func _on_entry_started(index: int) -> void:
	_show_entry(index)
	entry_started.emit(index)


func _show_entry(index: int) -> void:
	if _active_config == null or index < 0 or index >= _active_config.entries.size():
		_logo_texture.visible = false
		_fallback_label.visible = false
		return
	var entry := _active_config.entries[index]
	if entry == null:
		_logo_texture.visible = false
		_fallback_label.visible = false
		return
	var texture := _lookup_ui_texture(entry.asset_key)
	if texture != null:
		_logo_texture.texture = texture
		_logo_texture.visible = true
		_fallback_label.visible = false
		_update_logo_bounds()
	else:
		_logo_texture.texture = null
		_logo_texture.visible = false
		_fallback_label.text = entry.fallback_text
		_fallback_label.add_theme_font_size_override("font_size", maxi(entry.fallback_font_size, 8))
		_fallback_label.visible = true


func _apply_visual_state() -> void:
	if _sequencer == null or _error_shown:
		return
	var alpha := _sequencer.entry_alpha()
	_logo_texture.modulate.a = alpha
	_fallback_label.modulate.a = alpha
	if _loading_bar.visible:
		_loading_bar.value = _sequencer.progress_displayed()


func _on_sequencer_finished(did_fail: bool) -> void:
	if _switched:
		return
	_switched = true
	SplashScreen.shown_this_session = true
	finished.emit(did_fail)

	if not did_fail:
		var packed := loader.call(&"get_packed", _next_path) as PackedScene
		if packed != null:
			var overlay := _mount_transition_overlay()
			_change_scene(packed)
			if overlay != null:
				overlay.start_after_next_frame()
			return

	push_warning("SplashScreen: gagal memuat %s, mencoba pindah langsung." % _next_path)
	var direct_err := _change_scene_direct(_next_path)
	if direct_err != OK:
		_show_fatal_error()


func _mount_transition_overlay() -> IrisOverlay:
	if _active_config == null or not _active_config.transition_enabled or _bypass_transition:
		return null
	var tree := get_tree()
	if tree == null or tree.root == null:
		return null
	var overlay := _create_iris_overlay()
	if overlay == null:
		return null
	if not overlay.setup(_active_config):
		overlay.free()
		return null
	_active_overlay = overlay
	tree.root.add_child(overlay)
	overlay.finished.connect(_on_transition_finished, CONNECT_ONE_SHOT)
	transition_started.emit()
	return overlay


func _on_transition_finished() -> void:
	_active_overlay = null
	transition_finished.emit()


func _show_fatal_error() -> void:
	_error_shown = true
	_logo_texture.visible = false
	_fallback_label.text = ERROR_TEXT
	_fallback_label.add_theme_font_size_override("font_size", 32)
	_fallback_label.modulate.a = 1.0
	_fallback_label.visible = true
	_loading_bar.visible = false
	_loading_label.visible = false


func _is_skip_event(event: InputEvent) -> bool:
	if event == null:
		return false
	if event.is_action_pressed(&"ui_cancel"):
		return true
	if event is InputEventKey:
		var key := event as InputEventKey
		return key.pressed and not key.echo
	if event is InputEventMouseButton:
		return (event as InputEventMouseButton).pressed
	if event is InputEventJoypadButton:
		return (event as InputEventJoypadButton).pressed
	return false
