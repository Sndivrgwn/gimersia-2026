extends CanvasLayer

## HUD read-only untuk InteractorComponent: prompt, progress bar, alasan blokir.
##
## HUD tidak menyimpan progres atau target; semuanya dibaca dari sinyal
## InteractorComponent (pola yang sama dengan NeedsHUD).

const PLAYER_GROUP := &"player"
const INTERACTOR_NAME := "InteractorComponent"

## Opsional; bila kosong dicari lewat grup "player" -> InteractorComponent.
@export var interactor: InteractorComponent

@onready var _panel: Control = $Root/Panel
@onready var _prompt: Label = $Root/Panel/Margin/VBox/Prompt
@onready var _bar: ProgressBar = $Root/Panel/Margin/VBox/Bar
@onready var _blocked: Label = $Root/Panel/Margin/VBox/Blocked


func _ready() -> void:
	if interactor == null:
		interactor = _find_interactor()
	if interactor == null:
		push_warning("InteractionHUD: InteractorComponent tidak ditemukan.")
		_panel.visible = false
		return

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


func _on_target_changed(target: Interactable) -> void:
	_panel.visible = target != null
	_blocked.text = ""
	_blocked.visible = false
	_prompt.text = "" if target == null else target.get_prompt(interactor)


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


func _find_interactor() -> InteractorComponent:
	var tree := get_tree()
	if tree == null:
		return null
	var player := tree.get_first_node_in_group(PLAYER_GROUP)
	if player == null:
		return null
	return player.get_node_or_null(INTERACTOR_NAME) as InteractorComponent
