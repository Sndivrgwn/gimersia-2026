extends GutTest

## Mission 9: menu jeda harus benar-benar terlihat (sebelumnya CanvasLayer kosong).

const MENU := preload("res://src/ui/menus/pause_menu.gd")

var menu: PauseMenu


func before_each() -> void:
	menu = MENU.new() as PauseMenu
	add_child_autofree(menu)


func after_each() -> void:
	if menu != null and is_instance_valid(menu):
		menu.close()
	if get_tree() != null:
		get_tree().paused = false


func test_menu_builds_visible_panel_with_buttons() -> void:
	assert_not_null(menu.get_panel(), "panel jeda harus dibangun")
	var box := menu.get_panel().get_node_or_null("Box")
	assert_not_null(box, "panel punya VBox isi")
	var texts := PackedStringArray()
	for child in box.get_children():
		if child is Button:
			texts.append((child as Button).text)
	assert_eq(texts.size(), 4, "empat tombol: lanjut, pengaturan, bantuan, menu utama")
	assert_eq(texts[0], "Lanjutkan")
	assert_eq(texts[1], "Pengaturan")
	assert_eq(texts[2], "Bantuan")
	assert_eq(texts[3], "Menu Utama")


func test_open_shows_menu_and_pauses() -> void:
	assert_false(menu.is_open())
	assert_true(menu.open(), "menu boleh dibuka saat tidak ada panel lain")
	assert_true(menu.is_open())
	assert_true(menu.visible, "CanvasLayer terlihat")
	assert_true(get_tree().paused, "game beku selama menu jeda")


func test_close_hides_menu_and_resumes() -> void:
	menu.open()
	assert_true(get_tree().paused)
	menu.close()
	assert_false(menu.is_open())
	assert_false(menu.visible)
	assert_false(get_tree().paused, "game lanjut setelah menu ditutup")


func test_toggle_flips_state() -> void:
	menu.toggle()
	assert_true(menu.is_open())
	menu.toggle()
	assert_false(menu.is_open())
	assert_false(menu.visible)


func test_main_menu_button_requests_scene_change() -> void:
	watch_signals(menu)
	menu.open()
	menu.request_main_menu()
	assert_signal_emitted(menu, "main_menu_requested")
	assert_false(menu.is_open(), "menu ditutup sebelum pindah scene")
