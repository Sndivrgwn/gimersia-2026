class_name Interactable
extends Node2D

## Kontrak objek yang bisa di-hold-E (gather, bangun, loot, beacon, minum).
##
## Turunan menimpa method di bawah. Base class hanya menyediakan default aman
## dan mendaftarkan node ke grup `interactable` yang dibaca InteractorComponent.
## Node ini tidak menyimpan progres; progres dipegang InteractorComponent.

const GROUP := &"interactable"


func _enter_tree() -> void:
	add_to_group(GROUP)


## Teks prompt di InteractionHUD, mis. "Tahan E: Panen Beri".
func get_prompt(_interactor: Node) -> String:
	return ""


## Lama hold dalam detik nyata. 0 atau kurang berarti langsung sekali tekan.
func get_hold_time(_interactor: Node) -> float:
	return 1.0


## False = progres tidak jalan dan alasannya ditampilkan ke HUD.
func can_interact(_interactor: Node) -> bool:
	return true


## Alasan blokir; ditampilkan saat can_interact() false.
func get_block_reason(_interactor: Node) -> String:
	return ""


## Dipanggil sekali saat hold selesai.
func interact(_interactor: Node) -> void:
	pass
