@tool
class_name StitchFrame
extends ColorRect

## Menyisipkan ukuran node ke shader jahitan, supaya panjang dash tetap
## konstan berapa pun tinggi kartu. Node ini diletakkan di atas panel
## (StyleBoxTexture hanya untuk border dan isi).

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	if material != null:
		material = material.duplicate()
	_apply_size()
	resized.connect(_apply_size)


func _apply_size() -> void:
	var shader_material := material as ShaderMaterial
	if shader_material != null:
		shader_material.set_shader_parameter(&"frame_size", size)
