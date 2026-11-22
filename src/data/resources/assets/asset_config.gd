class_name AssetConfig
extends Resource

## Konfigurasi global sistem aset.
##
## Tidak ada nilai aset yang ditanam di project.godot: filter pixel-art diatur
## per sprite dari file ini.

## Filter nearest (pixel-art) untuk semua sprite hasil slot.
@export var pixel_art: bool = true
## Fallback kiri<->right (flip horizontal) saat art arah tertentu tidak ada.
@export var mirror_fallback: bool = true
## fps default per nama state bila slot tidak mengisi fps-nya sendiri.
@export var default_fps: Dictionary = {
	"idle": 6.0,
	"walk": 10.0,
	"run": 12.0,
	"sprint": 12.0,
	"attack": 14.0,
	"hurt": 10.0,
	"death": 10.0,
	"default": 6.0,
}


## fps efektif untuk satu state (fallback ke "default", lalu 6).
func fps_for(state: String) -> float:
	if default_fps.has(state):
		return float(default_fps[state])
	if default_fps.has("default"):
		return float(default_fps["default"])
	return 6.0
