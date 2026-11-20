extends Node2D

## Root scene pulau minimum.
##
## Clock tidak diurus di sini: autoload DayNightManager sudah `auto_start`
## (sama seperti practice1). Scene ini hanya menaruh pemain menghadap utara
## sesuai spec; arah hadap bukan state gameplay yang perlu disimpan.
##
## Wiring endgame/death juga di sini supaya tiap node tetap punya satu tugas:
## DeathController memiliki state kematian, DeathScreen hanya UI, RunController
## yang memindahkan scene.

@export var player_path: NodePath = ^"Player"
@export var start_facing: Vector2 = Vector2.UP

@onready var _death: DeathController = get_node_or_null("DeathController") as DeathController
@onready var _death_screen: DeathScreen = get_node_or_null("DeathScreen") as DeathScreen
@onready var _run: RunController = get_node_or_null("RunController") as RunController
@onready var _endgame: EndgameController = get_node_or_null("EndgameController") as EndgameController
@onready var _beacon: SignalBeacon = get_node_or_null("Beacon") as SignalBeacon


func _ready() -> void:
	var player := get_node_or_null(player_path)
	if player != null:
		player.set("facing_direction", start_facing)
	_wire_endgame(player as Node2D)


func _wire_endgame(player: Node2D) -> void:
	if _run != null:
		_run.clock = get_node_or_null("/root/DayNightManager")

	if _endgame != null:
		_endgame.player = player
		_endgame.beacon = _beacon

	if _death != null:
		_death.player = player
		_death.died.connect(_on_player_died)

	if _death_screen != null:
		_death_screen.respawn_requested.connect(_on_respawn_requested)
		_death_screen.main_menu_requested.connect(_on_main_menu_requested)

	if _death != null and _death.game_over.is_connected(_on_game_over) == false:
		_death.game_over.connect(_on_game_over)


func _on_player_died(respawns_remaining: int) -> void:
	if _death_screen == null:
		return
	if respawns_remaining < 0:
		_death_screen.show_game_over()
	else:
		_death_screen.show_death(respawns_remaining)


func _on_game_over() -> void:
	if _death_screen != null:
		_death_screen.show_game_over()


func _on_respawn_requested() -> void:
	if _death == null:
		return
	if _death.respawn() and _death_screen != null:
		_death_screen.hide_screen()


func _on_main_menu_requested() -> void:
	if _run != null:
		_run.request_main_menu()
