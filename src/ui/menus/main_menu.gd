extends Control

## Menu utama memakai latar dan tombol dari assets/textures/ui lewat
## src/ui/theme/ui_theme.tres (StyleBoxTexture 9-slice + font Nunito).
const ScreenFade := preload("res://src/ui/fx/screen_fade.gd")

## Menu Utama placeholder. Scene ini BUKAN main scene (project tetap memakai
## practice1.tscn); dibuka dari DeathScreen / RunController.
##
## "MULAI"   : restart siklus hari lalu pindah ke island.tscn.
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
const FADE_TIME := 0.45

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


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_info_overlay.visible = false
	_recenter_pivot()
	_info_card.resized.connect(_recenter_pivot)

	_start_button.pressed.connect(_start_game)
	_controls_button.pressed.connect(_show_controls)
	_credits_button.pressed.connect(_show_credits)
	_info_back.pressed.connect(close_info)
	_quit_button.pressed.connect(_quit)
	_version_label.text = _version_text()

	# Layar sempat gelap lalu memudar masuk saat menu dibuka.
	_screen_fade.visible = true
	_screen_fade.modulate.a = 1.0
	_fade_screen_to(0.0, FADE_TIME, _hide_screen_fade)


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
	_build()
	_ensure_settings_ui()
	UiSkin.apply(self)
	UiSkin.add_background(self, &"ui_bg_main_menu")
	UiSkin.add_logo(self)
	ScreenFade.fade_in(self)


## Mission 7: panel pengaturan dipakai ulang di menu utama.
func _ensure_settings_ui() -> void:
	var service := get_node_or_null("SettingsService") as SettingsService
	if service == null:
		service = SettingsService.new()
		service.name = "SettingsService"
		add_child(service)
	var panel := get_node_or_null("SettingsPanel") as SettingsPanel
	if panel == null:
		panel = SettingsPanel.new()
		panel.name = "SettingsPanel"
		add_child(panel)
	panel.setup(service)
	if find_child("SettingsButton", true, false) != null:
		return
	_kill(_overlay_tween)
	_overlay_tween = create_tween().set_parallel(true)
	_overlay_tween.tween_property(_info_dim, "color:a", 0.0, OVERLAY_TIME * 0.8)
	_overlay_tween.tween_property(_info_card, "modulate:a", 0.0, OVERLAY_TIME * 0.8)
	_overlay_tween.tween_property(_info_card, "scale", Vector2(0.97, 0.97), OVERLAY_TIME * 0.8)
	_overlay_tween.chain().tween_callback(_hide_info)
	_start_button.grab_focus()


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
	_fade_screen_to(1.0, FADE_TIME, _enter_game)


func _enter_game() -> void:
	var clock := get_node_or_null("/root/DayNightManager")
	if clock != null and clock.has_method(&"restart"):
		clock.restart()
	var tree := get_tree()
	ScreenFade.fade_out_then(tree, func() -> void: tree.change_scene_to_file(GAME_SCENE))


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
