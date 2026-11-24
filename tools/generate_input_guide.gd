extends SceneTree

## Mission 9: menulis docs/editable/PANDUAN_INPUT.md dari InputMap yang hidup.
## Jalankan: GODOT --headless --path . -s tools/generate_input_guide.gd
##
## Tujuan setiap action ditulis tangan di PURPOSES; tombolnya dibaca dari
## InputSetup sehingga dokumen tidak bisa basi sendiri. Action baru tanpa tujuan
## akan muncul sebagai "belum didokumentasikan" dan menggagalkan tes dokumentasi.

const GUIDE_PATH := "res://docs/editable/PANDUAN_INPUT.md"
const GeneratorScript = preload("res://src/core/docs/input_guide_generator.gd")


func _init() -> void:
	var generator = GeneratorScript.new()
	var text: String = generator.build_input_guide()
	var missing: Array = generator.missing_purposes()
	if not missing.is_empty():
		printerr("generate_input_guide: action tanpa tujuan: %s" % ", ".join(missing))
	var ok: bool = GeneratorScript.write_file(GUIDE_PATH, text)
	if not ok:
		printerr("generate_input_guide: gagal menulis %s" % GUIDE_PATH)
		quit(1)
		return
	print("generate_input_guide: %s diperbarui" % GUIDE_PATH)
	quit(0)
