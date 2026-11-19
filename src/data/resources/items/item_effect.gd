class_name ItemEffect
extends Resource

## Efek satu item konsumsi.
##
## Angka di sini adalah delta instan saat item dipakai. Hunger/Thirst/Fatigue
## diterapkan InventoryComponent lewat NeedsComponent; HP lewat StatsComponent.
##
## Catatan Fatigue: NeedsComponent punya plafon Fatigue, jadi item tidak memanggil
## `add(Need.FATIGUE, ...)` (nilainya akan terpotong plafon). `fatigue` diterapkan
## lewat `restore_fatigue_capacity()`, yang menaikkan plafon sekaligus mengisi
## nilai Fatigue sebanyak itu - sesuai perilaku makan yang sudah berjalan.
##
## HoT (regen HP per detik) hanya DISIMPAN. Belum ada sistem status effect, jadi
## `regen_hp_per_second`/`regen_duration` tidak diterapkan oleh siapa pun.

## Hunger yang dipulihkan (boleh negatif).
@export var hunger: float = 0.0
## Thirst yang dipulihkan (boleh negatif, mis. Raw Meat -10).
@export var thirst: float = 0.0
## Fatigue yang dipulihkan saat item dipakai (delta instan).
@export var fatigue: float = 0.0
## HP instan (positif = heal, negatif = damage).
@export var hp: float = 0.0
## Regen HP per detik (HoT). Disimpan saja; belum diterapkan.
@export var regen_hp_per_second: float = 0.0
## Durasi HoT dalam detik. Disimpan saja; belum diterapkan.
@export var regen_duration: float = 0.0


func is_empty() -> bool:
	return is_zero_approx(hunger) and is_zero_approx(thirst) \
		and is_zero_approx(fatigue) and is_zero_approx(hp) \
		and is_zero_approx(regen_hp_per_second) and is_zero_approx(regen_duration)
