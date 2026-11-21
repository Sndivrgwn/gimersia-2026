extends GutTest

const IslandHarness = preload("res://tests/integration/island_harness.gd")

var _harness: IslandHarness


func before_each() -> void:
	_harness = IslandHarness.new()
	_harness.setup(self)


func after_each() -> void:
	if _harness != null:
		_harness.teardown()
		_harness = null


func test_s5_endgame_loop() -> void:
	var beacon := _harness.beacon
	var inter := _harness.interactor
	var inv := _harness.inventory
	var endgame := _harness.endgame
	var clock := _harness.clock
	var death := _harness.death
	var stats := _harness.stats

	# 1. Before rescue: beacon refuses interaction
	assert_false(beacon.can_interact(inter), "Sebelum rescue, beacon tidak boleh bisa diinteraksi")
	assert_eq(beacon.get_block_reason(inter), SignalBeacon.BLOCK_NO_RESCUE, "Alasan blokir harus 'Belum waktunya'")

	# 2. Jump to rescue (clock skip)
	_harness.jump_to_rescue()
	assert_true(clock.rescue_triggered, "Clock rescue_triggered harus true")
	assert_true(endgame.is_rescue_active(), "EndgameController harus menandai rescue aktif")

	# 3. During rescue without flare: beacon still refuses
	assert_false(beacon.can_interact(inter), "Tanpa suar darurat, beacon tidak bisa diinteraksi")
	assert_eq(beacon.get_block_reason(inter), SignalBeacon.BLOCK_NO_FLARE, "Alasan blokir harus 'Butuh Suar Darurat'")

	# 4. A death during rescue keeps the beacon indicator active after respawn
	watch_signals(death)
	stats.set_hp(0.0)
	assert_signal_emitted(death, "died")
	assert_true(death.respawn(), "Respawn saat rescue harus berhasil")
	assert_true(endgame.is_rescue_active(), "Rescue harus tetap aktif setelah respawn")
	assert_gt(endgame.get_beacon_distance(), 0.0, "Indikator jarak beacon harus valid (> 0)")

	# 5. Give signal_flare and use SignalBeacon
	inv.add_item(ItemCatalog.SIGNAL_FLARE, 1)
	assert_true(beacon.can_interact(inter), "Dengan suar darurat saat rescue, beacon harus bisa diinteraksi")
	assert_eq(beacon.get_block_reason(inter), "", "Tidak boleh ada alasan blokir")

	watch_signals(endgame)
	watch_signals(beacon)

	# First interaction triggers victory
	beacon.interact(inter)
	assert_signal_emitted(beacon, "victory_triggered")
	assert_signal_emitted(endgame, "victory")

	# Assert victory state / signal fires once
	var victory_signal_count: int = get_signal_emit_count(endgame, "victory")
	assert_eq(victory_signal_count, 1, "Sinyal victory harus dipancarkan tepat sekali")

	# Second interaction must not re-trigger victory
	beacon.interact(inter)
	assert_eq(get_signal_emit_count(endgame, "victory"), 1, "Sinyal victory tidak boleh dipancarkan ulang")
