extends Node2D

## Root scene pulau minimum.
##
## Clock tidak diurus di sini: autoload DayNightManager sudah `auto_start`
## (sama seperti practice1). Scene ini hanya menaruh pemain menghadap utara
## sesuai spec; arah hadap bukan state gameplay yang perlu disimpan.

@export var player_path: NodePath = ^"Player"
@export var start_facing: Vector2 = Vector2.UP


func _ready() -> void:
	var player := get_node_or_null(player_path)
	if player == null:
		return
	player.set("facing_direction", start_facing)
