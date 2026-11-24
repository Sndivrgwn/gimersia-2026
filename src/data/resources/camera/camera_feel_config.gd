@tool
class_name CameraFeelConfig
extends Resource

## Fase 3A: rasa kamera dan batas tepi pulau.
##
## Hanya memengaruhi kamera; posisi pemain, hitbox, dan gameplay tidak berubah.

@export_group("Look-ahead")
## Jarak kamera bergeser ke arah gerak (px).
@export_range(0.0, 120.0, 1.0) var look_ahead_px: float = 11.0
## Kecepatan lerp menuju offset target (makin besar makin responsif).
@export_range(0.1, 20.0, 0.1) var follow_speed: float = 3.2

@export_group("Zoom")
@export_range(1.0, 8.0, 0.05) var day_zoom: float = 3.0
@export_range(1.0, 8.0, 0.05) var night_zoom: float = 2.75
## Durasi tween zoom saat siang/malam berganti (detik nyata).
@export_range(0.0, 10.0, 0.1) var zoom_time: float = 1.4

@export_group("Batas Pulau")
## Jarak (px) batas kamera ditarik ke dalam dari tepi pulau. 0 = tepat di
## coastline, sehingga tidak ada area kosong di luar pulau yang terlihat.
@export_range(0.0, 400.0, 1.0) var camera_limit_margin: float = 0.0
