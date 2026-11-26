extends Control

## Menu utama memakai latar dan tombol dari assets/textures/ui lewat
## src/ui/theme/ui_theme.tres (StyleBoxTexture 9-slice + font Nunito).
const SETTINGS_SCENE := preload("res://src/ui/menus/settings_panel.tscn")

## Menu utama: scene ini ADALAH `run/main_scene`; juga dibuka dari DeathScreen /
## RunController. Pulau dipreload di latar belakang sejak `_ready`.
##
## "MULAI"   : restart siklus hari lalu pindah ke island.tscn (preload digenapkan).
## "KONTROL" : overlay berisi daftar kontrol (HelpPanel.HELP_LINES).
## "KREDIT"  : overlay berisi kredit.
## "KELUAR"  : menutup aplikasi.

const GAME_SCENE := "res://src/levels/island/island.tscn"

const CREDIT_LINES: Array[String] = [
	"Dirancang dan dikembangkan oleh tim Gimersia.",
	"Dibuat dengan Godot Engine 4.",
	"Font Nunito oleh Vernon Adams dkk. — SIL Open Font License 1.1.",
	"Terima kasih sudah bermain.",
]

const DIM_ALPHA := 0.55
const OVERLAY_TIME := 0.18
const OVERLAY_SCALE := 0.94
const FADE_TIME := 0.22
## Mulai game: cukup gelap sesaat. Transisinya dilanjutkan zoom kamera di pulau,
## jadi layar tidak perlu menahan hitam lama.
const START_FADE_TIME := 0.16

@onready var _start_button: Button = %StartButton
@onready var _controls_button: Button = %ControlsButton
@onready var _credits_button: Button = %CreditsButton
@onready var _quit_button: Button = %QuitButton
@onready var _version_label: Label = %VersionLabel
@onready var _info_overlay: Control = %InfoOverlay
@onready var _info_dim: ColorRect = _info_overlay.get_node("Dim")
@onready var _info_card: PanelContainer = _info_overlay.get_node("Center/Card")
@onready var _info_title: Label = %InfoTitleLabel
@onready var _info_text: Label = %InfoTextLabel
@onready var _info_back: Button = %InfoBackButton
@onready var _screen_fade: ColorRect = %ScreenFade

var _overlay_tween: Tween
var _screen_tween: Tween
var _starting := false
## True selama permintaan muat-pulau di latar belakang masih hidup.
var _game_preloading := false
var _loading_scene := false
var _fade_done := false
var _loading_box: VBoxContainer
var _loading_bar: ProgressBar
var _loading_label: Label


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	var clock := get_node_or_null("/root/DayNightManager")
	if clock != null and clock.has_method(&"set_time_scale"):
		clock.set_time_scale(0.0)
	_info_overlay.visible = false
	_recenter_pivot()
	_info_card.resized.connect(_recenter_pivot)

	_start_button.pressed.connect(_start_game)
	_controls_button.pressed.connect(_show_controls)
	_credits_button.pressed.connect(_show_credits)
	_info_back.pressed.connect(close_info)
	_quit_button.pressed.connect(_quit)
	_version_label.text = _version_text()
	_ensure_settings_ui()
	_start_game_preload()
	_build_loading_ui()

	# Layar sempat gelap lalu memudar masuk saat menu dibuka.
	_screen_fade.visible = true
	_screen_fade.modulate.a = 1.0
	_fade_screen_to(0.0, FADE_TIME, _hide_screen_fade)


func _process(delta: float) -> void:
	if not _loading_scene:
		return
	var progress: Array = []
	var status := ResourceLoader.load_threaded_get_status(GAME_SCENE, progress)
	var target := 100.0
	if status == ResourceLoader.THREAD_LOAD_IN_PROGRESS and not progress.is_empty():
		target = clampf(float(progress[0]) * 100.0, 5.0, 95.0)
	elif status == ResourceLoader.THREAD_LOAD_LOADED:
		target = 100.0
	elif status == ResourceLoader.THREAD_LOAD_FAILED or status == ResourceLoader.THREAD_LOAD_INVALID_RESOURCE:
		_loading_scene = false
		_finish_enter_game(null)
		return

	if _loading_bar != null:
		_loading_bar.value = move_toward(_loading_bar.value, target, delta * 260.0)

	if status == ResourceLoader.THREAD_LOAD_LOADED and _fade_done and (_loading_bar == null or _loading_bar.value >= 99.5):
		_loading_scene = false
		var scene := ResourceLoader.load_threaded_get(GAME_SCENE) as PackedScene
		_finish_enter_game(scene)


# --- API --------------------------------------------------------------------

## Overlay informasi dipakai bersama oleh "Kontrol" dan "Kredit".
func open_info(title: String, lines: Array[String]) -> void:
	_info_title.text = title
	_info_text.text = "\n".join(PackedStringArray(lines))
	_info_overlay.visible = true

	_kill(_overlay_tween)
	_info_dim.color.a = 0.0
	_info_card.modulate.a = 0.0
	_info_card.scale = Vector2(OVERLAY_SCALE, OVERLAY_SCALE)
	_overlay_tween = create_tween().set_parallel(true)
	_overlay_tween.tween_property(_info_dim, "color:a", DIM_ALPHA, OVERLAY_TIME)
	_overlay_tween.tween_property(_info_card, "modulate:a", 1.0, OVERLAY_TIME)
	(
		_overlay_tween
		.tween_property(_info_card, "scale", Vector2.ONE, OVERLAY_TIME + 0.08)
		.set_trans(Tween.TRANS_QUAD)
		.set_ease(Tween.EASE_OUT)
	)
	_info_back.grab_focus()


func close_info() -> void:
	if not _info_overlay.visible:
		return
	_kill(_overlay_tween)
	_overlay_tween = create_tween().set_parallel(true)
	_overlay_tween.tween_property(_info_dim, "color:a", 0.0, OVERLAY_TIME * 0.8)
	_overlay_tween.tween_property(_info_card, "modulate:a", 0.0, OVERLAY_TIME * 0.8)
	_overlay_tween.tween_property(_info_card, "scale", Vector2(0.97, 0.97), OVERLAY_TIME * 0.8)
	_overlay_tween.chain().tween_callback(_hide_info)
	_start_button.grab_focus()


## Mission 7: panel pengaturan dipakai ulang di menu utama.
func _ensure_settings_ui() -> void:
	var service := get_node_or_null("SettingsService") as SettingsService
	if service == null:
		service = SettingsService.new()
		service.name = "SettingsService"
		add_child(service)
	var panel := get_node_or_null("SettingsPanel") as SettingsPanel
	if panel == null:
		panel = SETTINGS_SCENE.instantiate() as SettingsPanel
		panel.name = "SettingsPanel"
		add_child(panel)
	panel.setup(service)
	var settings_btn := find_child("SettingsButton", true, false) as Button
	if settings_btn != null and not settings_btn.pressed.is_connected(panel.open):
		settings_btn.pressed.connect(panel.open)


# --- Internal ---------------------------------------------------------------

## Versi diambil dari ProjectSettings supaya label dan project.godot tidak
## pernah berbeda angka.
func _version_text() -> String:
	var version := str(ProjectSettings.get_setting("application/config/version", "1.0.0"))
	if version.begins_with("v") or version.begins_with("V"):
		return version
	return "v%s" % version


func _unhandled_input(event: InputEvent) -> void:
	if _info_overlay.visible and event.is_action_pressed(&"ui_cancel"):
		close_info()
		get_viewport().set_input_as_handled()


func _show_controls() -> void:
	open_info("Kontrol", HelpPanel.HELP_LINES)


func _show_credits() -> void:
	open_info("Kredit", CREDIT_LINES)


func _start_game() -> void:
	if _starting:
		return
	_starting = true
	_fade_done = false
	_loading_scene = true
	_start_game_preload()
	if _loading_box != null:
		_loading_box.visible = not is_game_preloaded()
		_loading_bar.value = 100.0 if is_game_preloaded() else 5.0
	_fade_screen_to(1.0, START_FADE_TIME, func() -> void: _fade_done = true)


func _finish_enter_game(scene: PackedScene) -> void:
	var clock := get_node_or_null("/root/DayNightManager")
	if clock != null and clock.has_method(&"restart"):
		clock.restart()
	var tree := get_tree()
	if tree == null:
		return
	if scene != null:
		_game_preloading = false
		tree.change_scene_to_packed(scene)
	else:
		tree.change_scene_to_file(GAME_SCENE)


# --- Preload pulau ----------------------------------------------------------

## Pulau memuat ~200 skrip; kompilasinya puluhan detik di mesin lambat. Mulai
## permintaan di latar belakang saat menu tampil, jadi sebagian besar biaya itu
## habis selagi pemain masih di menu.
func _start_game_preload() -> void:
	if _game_preloading or ResourceLoader.load_threaded_request(GAME_SCENE) == OK:
		_game_preloading = true


## True bila pulau sudah siap dipasang tanpa menunggu sama sekali.
func is_game_preloaded() -> bool:
	return _game_preloading and ResourceLoader.load_threaded_get_status(GAME_SCENE) == ResourceLoader.THREAD_LOAD_LOADED


func _build_loading_ui() -> void:
	_loading_box = VBoxContainer.new()
	_loading_box.name = "LoadingBox"
	_loading_box.visible = false
	_loading_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_loading_box.add_theme_constant_override("separation", 6)
	_loading_box.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_RIGHT)
	_loading_box.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	_loading_box.grow_vertical = Control.GROW_DIRECTION_BEGIN
	_loading_box.offset_left = -280.0
	_loading_box.offset_top = -68.0
	_loading_box.offset_right = -32.0
	_loading_box.offset_bottom = -28.0
	add_child(_loading_box)

	_loading_label = Label.new()
	_loading_label.name = "LoadingLabel"
	_loading_label.text = "Memuat pulau..."
	_loading_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_loading_label.add_theme_font_size_override("font_size", 12)
	_loading_label.add_theme_color_override("font_color", Color(0.968627, 0.945098, 0.898039, 0.9))
	_loading_box.add_child(_loading_label)

	_loading_bar = ProgressBar.new()
	_loading_bar.name = "LoadingBar"
	_loading_bar.min_value = 0.0
	_loading_bar.max_value = 100.0
	_loading_bar.value = 0.0
	_loading_bar.show_percentage = false
	_loading_bar.custom_minimum_size = Vector2(248.0, 8.0)
	_loading_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE

	var bg := StyleBoxFlat.new()
	bg.bg_color = Color(0.14, 0.1, 0.08, 0.85)
	bg.set_corner_radius_all(4)
	_loading_bar.add_theme_stylebox_override("background", bg)

	var fill := StyleBoxFlat.new()
	fill.bg_color = Color(0.922, 0.761, 0.451, 1.0)
	fill.set_corner_radius_all(4)
	_loading_bar.add_theme_stylebox_override("fill", fill)
	_loading_box.add_child(_loading_bar)


func _quit() -> void:
	if _starting:
		return
	_starting = true
	_fade_screen_to(1.0, FADE_TIME * 0.7, func() -> void: get_tree().quit())


# --- Animasi ----------------------------------------------------------------

func _recenter_pivot() -> void:
	_info_card.pivot_offset = _info_card.size * 0.5


func _hide_info() -> void:
	_info_overlay.visible = false
	_info_card.scale = Vector2.ONE
	_info_card.modulate.a = 1.0
	_info_dim.color.a = DIM_ALPHA


func _fade_screen_to(alpha: float, time: float, on_done: Callable = Callable()) -> void:
	_kill(_screen_tween)
	_screen_fade.visible = true
	_screen_tween = create_tween()
	_screen_tween.tween_property(_screen_fade, "modulate:a", alpha, time).set_trans(Tween.TRANS_SINE)
	if on_done.is_valid():
		_screen_tween.tween_callback(on_done)


func _hide_screen_fade() -> void:
	_screen_fade.visible = false


func _kill(tween: Tween) -> void:
	if tween != null and tween.is_valid():
		tween.kill()
