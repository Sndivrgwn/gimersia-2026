extends Node

const ScreenFade := preload("res://src/ui/fx/screen_fade.gd")

## Mission 9 polish: momen Victory = kilat putih + kamera menjauh.
## Panel Victory tetap muncul seketika (tes lama tidak berubah).

const VICTORY_ZOOM := 2.6
const FLASH := Color(1.0, 0.97, 0.86, 0.8)

var _endgame: EndgameController
var _pcam: Node


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_endgame = get_parent().get_node_or_null("EndgameController") as EndgameController
	if _endgame != null:
		_endgame.victory.connect(_on_victory)
	var scene := get_tree().current_scene
	if scene != null:
		_pcam = scene.find_child("PhantomCamera2D", true, false)


func _on_victory() -> void:
	var root := get_parent()
	ScreenFade.flash(root, FLASH, 0.45)
	if _pcam == null or DisplayServer.get_name() == "headless":
		return
	var tween := create_tween()
	tween.tween_property(_pcam, "zoom", Vector2(VICTORY_ZOOM, VICTORY_ZOOM), 1.6).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
