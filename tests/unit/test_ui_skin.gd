extends GutTest

## Tes UiSkin (dengan/tanpa art), nine-slice, get_icon, dan konsumen ikon
## (BagSlot) yang menampilkan ikon hanya bila art ada.

const ROOT := "user://test_assets"
const BAG_SLOT_SCENE: PackedScene = preload("res://src/ui/panels/inventory/bag_slot.tscn")
const PLAYER_SCENE: PackedScene = preload("res://src/entities/player/player.tscn")
const WOOD: ItemDefinition = preload("res://src/data/items/wood.tres")


func before_each() -> void:
	_clean_root()
	Assets.set_roots(PackedStringArray([ROOT]))
	UiSkin.reset()


func after_each() -> void:
	UiSkin.reset()
	Assets.reset_roots()
	Assets.reload_assets()
	_clean_root()


func test_theme_is_null_without_art() -> void:
	assert_null(UiSkin.theme())
	var root := Control.new()
	add_child_autofree(root)
	UiSkin.apply(root)
	assert_null(root.theme)


func test_theme_builds_from_art_with_nine_slice() -> void:
	_write_image("ui/panel.png", 64, 64)
	_write_image("ui/button_normal.png", 64, 40)
	_write_image("ui/bar_bg.png", 32, 12)
	_write_image("ui/bar_fill_hp.png", 32, 12)

	var theme := UiSkin.theme()
	assert_not_null(theme)
	var panel := theme.get_stylebox(&"panel", &"PanelContainer") as StyleBoxTexture
	assert_not_null(panel)
	assert_almost_eq(panel.texture_margin_left, 8.0, 0.001)
	assert_almost_eq(panel.texture_margin_top, 8.0, 0.001)
	var button := theme.get_stylebox(&"normal", &"Button") as StyleBoxTexture
	assert_not_null(button)
	assert_not_null(theme.get_stylebox(&"background", &"ProgressBar"))
	assert_not_null(theme.get_stylebox(&"fill_hp", &"ProgressBar"))


func test_apply_assigns_theme_to_control() -> void:
	_write_image("ui/panel.png", 64, 64)
	var root := Control.new()
	add_child_autofree(root)
	UiSkin.apply(root)
	assert_not_null(root.theme)


func test_apply_all_reaches_control_inside_canvas_layer() -> void:
	_write_image("ui/panel.png", 64, 64)
	var holder := Node.new()
	add_child_autofree(holder)
	var layer := CanvasLayer.new()
	holder.add_child(layer)
	var control := Control.new()
	layer.add_child(control)
	UiSkin.apply_all(holder)
	assert_not_null(control.theme)


func test_item_icon_fallback_chain() -> void:
	assert_null(WOOD.get_icon())
	_write_image("icons/items/wood.png", 16, 16)
	Assets.reload_assets()
	assert_not_null(WOOD.get_icon())

	var custom := ItemDefinition.new()
	custom.id = &"wood"
	var texture := ImageTexture.create_from_image(_image(8, 8))
	custom.icon = texture
	assert_eq(custom.get_icon(), texture)


func test_bag_slot_shows_icon_only_when_art_exists() -> void:
	var player := PLAYER_SCENE.instantiate() as Player
	add_child_autofree(player)
	var inventory := InventoryComponent.new()
	inventory.name = "InventoryComponent"
	inventory.setup(player)
	player.add_child(inventory)
	inventory.add_item(WOOD, 1)

	var slot := BAG_SLOT_SCENE.instantiate() as BagSlot
	slot.slot_index = 0
	slot.inventory = inventory
	add_child_autofree(slot)
	await wait_frames(1)
	var icon := slot.get_node("VBox/Icon") as TextureRect
	assert_false(icon.visible)
	assert_eq(slot.get_label_text(), WOOD.display_name)

	_write_image("icons/items/wood.png", 16, 16)
	Assets.reload_assets()
	slot.refresh()
	assert_true(icon.visible)
	assert_not_null(icon.texture)


# --- Fixtures ---------------------------------------------------------------

func _image(width: int, height: int) -> Image:
	var image := Image.create(width, height, false, Image.FORMAT_RGBA8)
	image.fill(Color(0.9, 0.9, 0.9, 1.0))
	return image


func _write_image(relative: String, width: int, height: int) -> void:
	var path := ROOT + "/" + relative
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(path.get_base_dir()))
	_image(width, height).save_png(path)


func _clean_root() -> void:
	var absolute := ProjectSettings.globalize_path(ROOT)
	if not DirAccess.dir_exists_absolute(absolute):
		return
	_remove_dir(absolute)


func _remove_dir(path: String) -> void:
	var dir := DirAccess.open(path)
	if dir == null:
		return
	for name in dir.get_files():
		DirAccess.remove_absolute(path + "/" + name)
	for sub in dir.get_directories():
		_remove_dir(path + "/" + sub)
	DirAccess.remove_absolute(path)
