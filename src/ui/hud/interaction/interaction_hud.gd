extends CanvasLayer

## HUD read-only untuk InteractorComponent: prompt, progress bar, alasan blokir.
##
## HUD tidak menyimpan progres atau target; semuanya dibaca dari sinyal
## InteractorComponent (pola yang sama dengan NeedsHUD).

const PLAYER_GROUP := &"player"
const INTERACTOR_NAME := "InteractorComponent"

## Opsional; bila kosong dicari lewat grup "player" -> InteractorComponent.
@export var interactor: InteractorComponent
## Opsional; bila kosong dicari lewat grup "player" -> RepairComponent.
## Panel repair hanya muncul saat ada struktur rusak dalam jangkauan.
@export var repair_component: RepairComponent

@onready var _panel: Control = $Root/Panel
@onready var _prompt: Label = $Root/Panel/Margin/VBox/PromptRow/Prompt
@onready var _bar: ProgressBar = $Root/Panel/Margin/VBox/Bar
@onready var _blocked: Label = $Root/Panel/Margin/VBox/Blocked
var _repair_panel: Control
var _repair_label: Label
var _repair_bar: ProgressBar
var _repair_blocked: Label


func _ready() -> void:
	if interactor == null:
		interactor = _find_interactor()
	if interactor == null:
		push_warning("InteractionHUD: InteractorComponent tidak ditemukan.")
		_panel.visible = false
	else:
		interactor.target_changed.connect(_on_target_changed)
		interactor.progress_changed.connect(_on_progress_changed)
		interactor.interaction_blocked.connect(_on_blocked)
		interactor.interaction_completed.connect(_on_finished)
		interactor.interaction_cancelled.connect(_on_finished)

		_bar.max_value = 1.0
		_bar.value = 0.0
		_bar.visible = false
		_on_target_changed(interactor.get_target())
		_on_progress_changed(interactor.get_progress_ratio())

	_setup_repair()


func _on_target_changed(target: Interactable) -> void:
	_panel.visible = target != null
	_blocked.text = ""
	_blocked.visible = false
	_prompt.text = "" if target == null else _format_prompt(target.get_prompt(interactor))


func _format_prompt(raw: String) -> String:
	var text := raw.strip_edges()
	for prefix in ["Tahan E: ", "Tekan E: ", "Tahan E - ", "Tekan E - ", "E: ", "E - "]:
		if text.begins_with(prefix):
			return text.substr(prefix.length()).strip_edges()
	return text


func _on_progress_changed(ratio: float) -> void:
	_bar.value = clampf(ratio, 0.0, 1.0)
	_bar.visible = _bar.value > 0.0


func _on_blocked(_target: Interactable, reason: String) -> void:
	_blocked.text = reason
	_blocked.visible = not reason.is_empty()


func _on_finished(_target: Interactable) -> void:
	_bar.value = 0.0
	_bar.visible = false
	_blocked.text = ""
	_blocked.visible = false


# --- Repair (additive) ------------------------------------------------------

func _setup_repair() -> void:
	_build_repair_ui()
	if repair_component == null:
		repair_component = _find_repair_component()
	if repair_component == null:
		return

	repair_component.target_changed.connect(_on_repair_target_changed)
	repair_component.progress_changed.connect(_on_repair_progress)
	repair_component.repair_completed.connect(_on_repair_finished)
	repair_component.repair_blocked.connect(_on_repair_blocked)
	_on_repair_target_changed(repair_component.get_target())


func _build_repair_ui() -> void:
	if _repair_panel != null:
		return
	var root := get_node_or_null("Root") as Control
	if root == null:
		return

	_repair_panel = Control.new()
	_repair_panel.name = "RepairPanel"
	_repair_panel.position = Vector2(20.0, 218.0)
	_repair_panel.size = Vector2(320.0, 56.0)
	_repair_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_repair_panel.visible = false
	root.add_child(_repair_panel)

	_repair_label = Label.new()
	_repair_label.name = "Prompt"
	_repair_label.size = Vector2(300.0, 18.0)
	_repair_label.add_theme_font_size_override("font_size", 12)
	_repair_panel.add_child(_repair_label)

	_repair_bar = ProgressBar.new()
	_repair_bar.name = "Bar"
	_repair_bar.position = Vector2(0.0, 20.0)
	_repair_bar.size = Vector2(160.0, 10.0)
	_repair_bar.max_value = 1.0
	_repair_bar.value = 0.0
	_repair_bar.show_percentage = false
	_repair_bar.visible = false
	_repair_panel.add_child(_repair_bar)

	_repair_blocked = Label.new()
	_repair_blocked.name = "Blocked"
	_repair_blocked.position = Vector2(0.0, 32.0)
	_repair_blocked.size = Vector2(300.0, 18.0)
	_repair_blocked.add_theme_font_size_override("font_size", 11)
	_repair_blocked.add_theme_color_override("font_color", Color(1.0, 0.55, 0.45, 1.0))
	_repair_panel.add_child(_repair_blocked)


func _on_repair_target_changed(structure: CampStructure) -> void:
	if _repair_panel == null:
		return
	_repair_panel.visible = structure != null
	if _repair_label != null:
		_repair_label.text = "" if structure == null else repair_component.get_target_prompt()
	if _repair_blocked != null:
		_repair_blocked.text = ""
		_repair_blocked.visible = false
	if _repair_bar != null:
		_repair_bar.value = 0.0
		_repair_bar.visible = false


func _on_repair_progress(ratio: float) -> void:
	if _repair_bar == null:
		return
	_repair_bar.value = clampf(ratio, 0.0, 1.0)
	_repair_bar.visible = _repair_bar.value > 0.0


func _on_repair_blocked(_structure: CampStructure, reason: String) -> void:
	if _repair_blocked == null:
		return
	_repair_blocked.text = reason
	_repair_blocked.visible = not reason.is_empty()


func _on_repair_finished(_structure: CampStructure) -> void:
	if _repair_bar == null:
		return
	_repair_bar.value = 0.0
	_repair_bar.visible = false
	if _repair_blocked != null:
		_repair_blocked.text = ""
		_repair_blocked.visible = false


func _find_repair_component() -> RepairComponent:
	var tree := get_tree()
	if tree == null:
		return null
	var player := tree.get_first_node_in_group(PLAYER_GROUP)
	if player == null:
		return null
	return player.get_node_or_null("RepairComponent") as RepairComponent


func _find_interactor() -> InteractorComponent:
	var tree := get_tree()
	if tree == null:
		return null
	var player := tree.get_first_node_in_group(PLAYER_GROUP)
	if player == null:
		return null
	return player.get_node_or_null(INTERACTOR_NAME) as InteractorComponent
