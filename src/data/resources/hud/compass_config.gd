@tool
class_name CompassConfig
extends Resource

## Fase 2: ambang jarak penunjuk arah HUD (panah base dan penanda tas jatuh).
##
## Nilai jarak hanya memengaruhi kapan penunjuk tampil; tidak ada efek gameplay.

@export_group("Panah Base")
## Jarak (px) di atas mana panah base muncul. Di bawah ini base sudah terlihat
## di layar sehingga panah hanya mengganggu.
@export_range(0.0, 3000.0, 10.0) var camp_arrow_distance: float = 600.0

@export_group("Penanda Tas Jatuh")
## Jarak (px) di bawah mana penanda tas disembunyikan (tas sudah di dekat kaki).
@export_range(0.0, 500.0, 5.0) var loot_arrow_distance: float = 40.0
