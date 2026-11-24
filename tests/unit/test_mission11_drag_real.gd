extends GutTest

## Mission 11 Block A: fauna tidak boleh terseret saat pemain menempel & jalan.
## Memakai scene sungguhan (player.tscn, wild_boar.tscn, island_deer.tscn) dan
## jalur input asli (Input.action_press -> Player._physics_process).
##
## Angka frame diringkas (press 6 + hold 14 frame, bukan 1 s + 2 s) supaya
## beban file kecil; kecepatan pemain tetap 160/240 px per detik.

const PRESS_FRAMES := 6
const HOLD_FRAMES := 14
const SLIDE_FRAMES := 24
const CONTACT_EPSILON := 0.05
const MAX_CONTACT_DRIFT := 1.0

var _rig: DragRig


func before_each() -> void:
	_rig = DragRig.new()
	add_child(_rig)
	_rig.setup(&"boar")


func after_each() -> void:
	if is_instance_valid(_rig):
		_rig.cleanup()


## Boar: WANDER (non-chasing) dengan target di seberang pemain, jadi AI-nya
## memang ingin bergerak. Deer: ALERT (non-chasing, diam) karena rusa selalu
## waspada saat pemain dekat.
func _non_chasing_state(kind: StringName) -> StringName:
	return &"idle" if kind == &"boar" else &"alert"


func _run_press(kind: StringName, dir_name: StringName, sprint: bool, with_wall: bool) -> Dictionary:
	var dir: Vector2 = DragRig.DIRS[dir_name]
	_rig.reset_case(kind, dir, with_wall)
	_rig.force_state(_non_chasing_state(kind))
	if kind == &"boar":
		_rig.set_wander_target(dir * 400.0)
	await get_tree().physics_frame
	_rig.press(dir_name, sprint)
	await _rig.step_frames(PRESS_FRAMES)
	await _rig.step_frames(HOLD_FRAMES, true)
	var result := {
		"ratio": _rig.drag_ratio(0, _rig.samples.size() - 1, dir),
		"drift": _rig.animal_displacement(0),
		"overlap": _rig.max_overlap(0),
	}
	_rig.release_input()
	await get_tree().physics_frame
	return result


func test_non_chasing_fauna_is_never_dragged() -> void:
	for kind in [&"boar", &"deer"]:
		for dir_name in [&"right", &"down", &"up", &"left"]:
			var walked := await _run_press(kind, dir_name, false, false)
			assert_lt(walked["ratio"], CONTACT_EPSILON, "%s/%s walk tidak terseret" % [kind, dir_name])
			assert_lt(walked["drift"], MAX_CONTACT_DRIFT, "%s/%s walk tidak bergeser" % [kind, dir_name])
			assert_lt(walked["overlap"], 1.0, "%s/%s tidak bertumpuk" % [kind, dir_name])
		var sprinted := await _run_press(kind, &"right", true, false)
		assert_lt(sprinted["ratio"], CONTACT_EPSILON, "%s sprint tidak terseret" % kind)
		assert_lt(sprinted["drift"], MAX_CONTACT_DRIFT, "%s sprint tidak bergeser" % kind)
		var walled := await _run_press(kind, &"right", false, true)
		assert_lt(walled["ratio"], CONTACT_EPSILON, "%s + dinding tidak terseret" % kind)
		assert_lt(walled["drift"], MAX_CONTACT_DRIFT, "%s + dinding tidak bergeser" % kind)


func test_contact_rules_hold() -> void:
	# Regresi penyebab (CAUSE: E3): AI non-chasing berhenti saat menempel, lalu
	# jalan lagi setelah pemain menjauh.
	_rig.reset_case(&"boar", Vector2.RIGHT, false)
	_rig.force_state(&"idle")
	_rig.set_wander_target(Vector2.RIGHT * 400.0)
	await get_tree().physics_frame
	var start := _rig.animal.global_position
	await _rig.step_frames(20)
	assert_lt(_rig.animal.global_position.distance_to(start), MAX_CONTACT_DRIFT, "menempel = AI berhenti")
	_rig.player.global_position += Vector2.LEFT * 200.0
	await _rig.step_frames(20)
	assert_gt(_rig.animal.global_position.distance_to(start), 10.0, "setelah pemain jauh AI jalan lagi")

	# Pemain terjepit (fauna + dinding) selalu bisa keluar.
	for kind in [&"boar", &"deer"]:
		_rig.reset_case(kind, Vector2.RIGHT, true)
		_rig.force_state(_non_chasing_state(kind))
		await get_tree().physics_frame
		await _rig.step_frames(3)
		var start_y := _rig.player.global_position.y
		_rig.press(&"down")
		await _rig.step_frames(SLIDE_FRAMES)
		assert_gt(_rig.player.global_position.y - start_y, 15.0, "%s: pemain bisa keluar dari jepitan" % kind)
		_rig.release_input()
		await get_tree().physics_frame

	# Dua fauna tidak menumpuk.
	_rig.reset_case(&"boar", Vector2.RIGHT, false)
	_rig.force_state(&"idle")
	_rig.animal.global_position = _rig.origin + Vector2(300.0, 0.0)
	var second := DragRig.BOAR_SCENE.instantiate() as WildBoar
	second.player = _rig.player
	second.clock = _rig.clock
	_rig.add_child(second)
	second.global_position = _rig.origin + Vector2(310.0, 0.0)
	second.ensure_ready()
	second.forced_hostile = false
	second._wander_pause = 9999.0
	await _rig.step_frames(40)
	assert_gte(_rig.animal.global_position.distance_to(second.global_position), 24.0 - 2.0, "dua babi tidak menumpuk")
	second.free()

	# Babi HOSTILE mengejar: berhenti di jarak kontak, pemain tidak didorong.
	_rig.reset_case(&"boar", Vector2.RIGHT, false)
	# 85 px dari pemain: di bawah dash_min_distance (110) jadi murni CHASE.
	_rig.animal.global_position = _rig.origin + Vector2(60.0, 0.0)
	_rig.force_state(&"hostile_chase")
	_rig.animal.forced_hostile = true
	await get_tree().physics_frame
	var player_start := _rig.player.global_position
	var contact := _rig.animal.get_contact_distance_to_player()
	var closest := 9999.0
	for _index in 70:
		await get_tree().physics_frame
		closest = minf(closest, _rig.animal.global_position.distance_to(_rig.player.global_position))
	assert_gte(closest, contact - 3.0, "tidak menembus jarak kontak")
	assert_lte(closest, contact + 3.0, "benar-benar sampai jarak kontak")
	assert_lt(_rig.player.global_position.distance_to(player_start), 1.0, "pemain tidak didorong")
