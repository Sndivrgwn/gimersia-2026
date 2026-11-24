extends SceneTree

## Menulis ulang docs/editable/ASSET_GUIDE.md, CONFIG_GUIDE.md, AUDIO_GUIDE.md
## dan WORLD_BUILDING_GUIDE.md
## dari resource yang hidup di repo. Deterministik: urut, tanpa timestamp.
## Jalankan: GODOT --headless --path . -s tools/generate_guides.gd

const GeneratorScript = preload("res://src/core/docs/guides_generator.gd")
const AudioGeneratorScript = preload("res://src/core/docs/audio_guide_generator.gd")
const WorldGeneratorScript = preload("res://src/core/docs/world_guide_generator.gd")
const ASSET_GUIDE := "res://docs/editable/ASSET_GUIDE.md"
const CONFIG_GUIDE := "res://docs/editable/CONFIG_GUIDE.md"
const AUDIO_GUIDE := "res://docs/editable/AUDIO_GUIDE.md"
const WORLD_GUIDE := "res://docs/editable/WORLD_BUILDING_GUIDE.md"


func _init() -> void:
	var generator = GeneratorScript.new()
	var asset_ok := GeneratorScript.write_file(ASSET_GUIDE, generator.build_asset_guide())
	var config_ok := GeneratorScript.write_file(CONFIG_GUIDE, generator.build_config_guide())
	var audio = AudioGeneratorScript.new()
	var audio_ok := GeneratorScript.write_file(AUDIO_GUIDE, audio.build_audio_guide())
	var world = WorldGeneratorScript.new()
	var world_ok := WorldGeneratorScript.write_file(WORLD_GUIDE, world.build_guide())
	if not asset_ok or not config_ok or not audio_ok or not world_ok:
		printerr("generate_guides: gagal menulis panduan")
		quit(1)
		return
	print("generate_guides: %s, %s, %s dan %s diperbarui" % [ASSET_GUIDE, CONFIG_GUIDE, AUDIO_GUIDE, WORLD_GUIDE])
	quit(0)
