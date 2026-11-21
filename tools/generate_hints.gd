extends SceneTree

## Mission 7: generator resource hint (teks Indonesia).

const OUT_DIR := "res://src/data/hints"
const HINTS := {
	&"base_place": "Tekan B untuk menentukan lokasi base.",
	&"gather": "Tahan E untuk mengumpulkan.",
	&"dusk": "Malam hampir tiba. Nyalakan api unggun dan siapkan pertahanan.",
	&"need_low": "Makan atau minum sebelum terlalu lemah.",
	&"repair": "Tahan R untuk memperbaiki struktur.",
	&"campfire_cold": "Api padam. Tahan E lalu tekan E tepat waktu untuk menggesek batu.",
	&"crafting": "Buka Tab atau I, lalu tab Crafting untuk membuat item.",
	&"fence": "Bangun pagar di sekitar base.",
	&"neutral_hit": "Menyerang hewan netral membuatnya menyerang balik.",
}


func _init() -> void:
	DirAccess.make_dir_recursive_absolute(OUT_DIR)
	for id in HINTS:
		var definition := HintDefinition.new()
		definition.id = id
		definition.text = HINTS[id]
		var path := "%s/%s.tres" % [OUT_DIR, String(id)]
		var error := ResourceSaver.save(definition, path)
		if error != OK:
			push_error("gagal menyimpan %s: %d" % [path, error])
	print("hints generated: %d" % HINTS.size())
	quit()
