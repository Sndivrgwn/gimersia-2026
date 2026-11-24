class_name HeldItemConfig
extends Resource

## Mission 10 Phase 3: pose item di tangan. Semua angka di sini invented
## (lihat laporan) dan ditulis oleh tools/generate_held_item_data.gd.

@export var hand_offset_down: Vector2 = Vector2(10.0, -2.0)
@export var hand_offset_up: Vector2 = Vector2(-10.0, -8.0)
@export var hand_offset_left: Vector2 = Vector2(-10.0, -2.0)
@export var hand_offset_right: Vector2 = Vector2(10.0, -2.0)
@export var hand_size: Vector2 = Vector2(14.0, 14.0)
@export var walk_bob: float = 1.0
@export var swing_arc_degrees: float = 70.0
@export var swing_seconds: float = 0.12
@export var use_bob_seconds: float = 0.25
@export var show_tool_while_gathering: bool = true
