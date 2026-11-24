extends GutTest

## Mission 11 Block A: PhysicsTraceRecorder (island, OFF by default).
## Fungsi CSV murni dites tanpa menulis file.

const PLAYER_ROW := {
	"frame": 0, "slot": 0, "kind": "player", "state": -1,
	"x": 1.5, "y": -2.25, "vx": 0.0, "vy": 0.0,
	"ai_vx": 0.0, "ai_vy": 0.0, "overlap": 0.0,
	"sep_x": 0.0, "sep_y": 0.0, "player_gap": 0.0,
}
const BOAR_ROW := {
	"frame": 0, "slot": 1, "kind": "wild_boar", "state": 0,
	"x": 30.0, "y": 0.0, "vx": 57.5, "vy": 0.0,
	"ai_vx": 57.5, "ai_vy": 0.0, "overlap": 0.5,
	"sep_x": -1.0, "sep_y": 0.0, "player_gap": 24.0,
}


func test_csv_header_then_one_row_per_body() -> void:
	var lines := PhysicsTraceRecorder.build_csv([PLAYER_ROW, BOAR_ROW]).split("\n")
	assert_eq(lines[0], PhysicsTraceRecorder.CSV_HEADER)
	assert_eq(lines[1], "0,0,player,-1,1.50,-2.25,0.00,0.00,0.00,0.00,0.00,0.00,0.00,0.00")
	assert_eq(lines[2], "0,1,wild_boar,0,30.00,0.00,57.50,0.00,57.50,0.00,0.50,-1.00,0.00,24.00")
	assert_eq(lines.size(), 4, "baris terakhir kosong setelah newline")
	assert_eq(lines[3], "")


func test_csv_without_rows_is_header_only() -> void:
	assert_eq(PhysicsTraceRecorder.build_csv([]), PhysicsTraceRecorder.CSV_HEADER + "\n")


func test_recorder_is_off_by_default() -> void:
	var recorder := PhysicsTraceRecorder.new()
	add_child_autofree(recorder)
	assert_false(recorder.is_recording(), "tidak merekam sampai tombol ditekan")
	assert_true(recorder.get_rows().is_empty())
	assert_eq(recorder.record_seconds, 6.0)
