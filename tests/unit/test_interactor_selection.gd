extends GutTest

## Interactor harus memilih target yang bisa dipakai, bukan blueprint yang
## sudah dibangun di posisi yang sama. Target terblokir hanya fallback supaya
## InteractionHUD tetap menampilkan alasannya.

class StubTarget extends Interactable:
	var usable: bool = true

	func get_prompt(_interactor: Node) -> String:
		return "target"

	func get_hold_time(_interactor: Node) -> float:
		return 0.0

	func can_interact(_interactor: Node) -> bool:
		return usable

	func get_block_reason(_interactor: Node) -> String:
		return "" if usable else "Sudah dibangun"

	func interact(_interactor: Node) -> void:
		pass


var _player: Node2D
var _interactor: InteractorComponent


func before_each() -> void:
	_player = Node2D.new()
	add_child_autofree(_player)
	_player.global_position = Vector2.ZERO
	_interactor = InteractorComponent.new()
	_player.add_child(_interactor)
	_interactor.set_process(false)


func _target(position: Vector2, usable: bool) -> StubTarget:
	var target := StubTarget.new()
	target.usable = usable
	target.global_position = position
	add_child_autofree(target)
	return target


func test_usable_target_wins_over_closer_blocked_blueprint() -> void:
	var blocked := _target(Vector2(10.0, 0.0), false)
	var station := _target(Vector2(30.0, 0.0), true)
	var nearest := _interactor.call(&"_find_nearest") as Interactable
	assert_eq(nearest, station, "stasiun/peti yang bisa dipakai harus menang")
	assert_ne(nearest, blocked)


func test_blocked_target_is_fallback_when_nothing_is_usable() -> void:
	var blocked := _target(Vector2(12.0, 0.0), false)
	var far := _target(Vector2(500.0, 0.0), true)
	var nearest := _interactor.call(&"_find_nearest") as Interactable
	assert_eq(nearest, blocked, "tetap pilih target terdekat untuk menampilkan alasan blokir")
	assert_ne(nearest, far)
