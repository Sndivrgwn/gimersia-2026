class_name ResolvedVisual
extends RefCounted

## Hasil Assets.resolve(): tekstur satu frame ATAU SpriteFrames untuk strip.
## `found == false` berarti pemanggil harus memakai placeholder.

var key: StringName = &""
var found: bool = false
var texture: Texture2D
var sprite_frames: SpriteFrames
var flip_h: bool = false
var from_fallback: bool = false
var state: StringName = &""
var dir: StringName = &""
var path: String = ""
var frame_count: int = 1
var fps: float = 6.0
var loop: bool = true
var slot: AssetSlotDefinition
## Mission 12: animasi SpriteFrames yang terpilih ("" untuk strip PNG).
var animation: StringName = &""
## True bila hasil berasal dari file .tres SpriteFrames.
var from_spriteframes: bool = false

var _art_size: Vector2 = Vector2.ZERO


## Ukuran art asli dalam piksel sumber.
func texture_size() -> Vector2:
	if _art_size != Vector2.ZERO:
		return _art_size
	if sprite_frames != null:
		var anim := animation if not String(animation).is_empty() else &"default"
		var first := sprite_frames.get_frame_texture(anim, 0)
		if first != null:
			return first.get_size()
		return Vector2.ZERO
	if texture != null:
		return texture.get_size()
	return Vector2.ZERO


## True bila hasil berupa strip animasi PNG.
func is_animated() -> bool:
	return sprite_frames != null and frame_count > 1 and not from_spriteframes


## True bila hasil berasal dari SpriteFrames (.tres).
func is_sprite_frames() -> bool:
	return from_spriteframes and sprite_frames != null


func set_art_size(size: Vector2) -> void:
	_art_size = size
