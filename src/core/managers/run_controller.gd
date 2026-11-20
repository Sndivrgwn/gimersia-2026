class_name RunController
extends Node

## Titik masuk untuk alur antar-scene (Menu Utama / Mulai Baru).
##
## Perubahan scene sesungguhnya lewat `_change_scene()` supaya tes bisa
## menimpanya tanpa `change_scene_to_file`. Clock dibekukan saat keluar ke menu
## dan di-restart saat memulai run baru.

signal main_menu_requested
signal restart_requested

const MENU_SCENE := "res://src/ui/menus/main_menu.tscn"
const GAME_SCENE := "res://src/levels/island/island.tscn"

@export var clock: Node


func _ready() -> void:
	add_to_group(&"run_controller")
	if clock == null:
		clock = get_node_or_null("/root/DayNightManager")


## Keluar ke Menu Utama: bekukan jam game lalu minta pindah scene.
func request_main_menu() -> void:
	_freeze_clock()
	main_menu_requested.emit()
	_change_scene(MENU_SCENE)


## Mulai run baru: reset jam ke Hari 1 siang lalu minta pindah scene.
func request_restart() -> void:
	_restart_clock()
	restart_requested.emit()
	_change_scene(GAME_SCENE)


## Bisa ditimpa tes agar tidak benar-benar mengganti scene.
func _change_scene(path: String) -> void:
	var tree := get_tree()
	if tree != null:
		tree.change_scene_to_file(path)


func _freeze_clock() -> void:
	if clock != null and clock.has_method(&"set_time_scale"):
		clock.set_time_scale(0.0)


func _restart_clock() -> void:
	if clock != null and clock.has_method(&"restart"):
		clock.restart()
