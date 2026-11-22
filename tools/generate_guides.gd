extends SceneTree

## Menulis ulang docs/editable/ASSET_GUIDE.md dan CONFIG_GUIDE.md dari resource
## yang hidup di repo. Deterministik: urut, tanpa timestamp.
## Jalankan: GODOT --headless --path . -s tools/generate_guides.gd

const GeneratorScript = preload("res://src/core/docs/guides_generator.gd")
const ASSET_GUIDE := "res://docs/editable/ASSET_GUIDE.md"
const CONFIG_GUIDE := "res://docs/editable/CONFIG_GUIDE.md"


func _init() -> void:
	var generator = GeneratorScript.new()
	var asset_ok := GeneratorScript.write_file(ASSET_GUIDE, generator.build_asset_guide())
	var config_ok := GeneratorScript.write_file(CONFIG_GUIDE, generator.build_config_guide())
	if not asset_ok or not config_ok:
		printerr("generate_guides: gagal menulis panduan")
		quit(1)
		return
	print("generate_guides: %s dan %s diperbarui" % [ASSET_GUIDE, CONFIG_GUIDE])
	quit(0)
