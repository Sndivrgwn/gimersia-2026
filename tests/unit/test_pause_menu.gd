extends GutTest

## Mission 9: menu jeda harus benar-benar terlihat (sebelumnya CanvasLayer kosong).

const MENU := preload("res://src/ui/menus/pause_menu.gd")


class OpenPanel extends Control:
	func is_open() -> bool:
		return true


class ClosablePanel extends Control:
	var _open: bool = false

	func open() -> void:
		_open = true
		UiBackStack.register(self)

	func close() -> void:
		_open = false
		UiBackStack.unregister(self)

	func is_open() -> bool:
		return _open


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


## Mission 10 Phase 5: Esc menutup UI paling atas dulu, baru membuka Jeda.
func test_escape_closes_top_panel_before_opening_pause() -> void:
	var panel := ClosablePanel.new()
	add_child_autofree(panel)
	panel.open()
	var event := InputEventAction.new()
	event.action = &"ui_cancel"
	event.pressed = true
	menu._unhandled_input(event)
	assert_false(panel.is_open(), "Esc menutup panel paling atas")
	assert_false(menu.is_open(), "Jeda belum terbuka di tekan pertama")
	menu._unhandled_input(event)
	assert_true(menu.is_open(), "Esc kedua membuka Jeda")


func test_escape_hint_and_pause_button_visible_when_playing() -> void:
	assert_not_null(menu.get_esc_hint_label(), "label Esc: Jeda ada")
	assert_eq(menu.get_esc_hint_label().text, PauseMenu.ESC_HINT_TEXT)
	menu.open()
	menu._process(0.016)
	assert_false(menu.get_esc_hint_label().visible, "label disembunyikan saat Jeda tampil")
	menu.close()
	menu._process(0.016)
	assert_true(menu.get_esc_hint_label().visible)
	assert_not_null(menu.get_pause_button(), "tombol II ada")
	assert_eq(menu.get_pause_button().mouse_filter, Control.MOUSE_FILTER_STOP)


func test_pause_button_opens_menu() -> void:
	menu.get_pause_button().pressed.emit()
	assert_true(menu.is_open())


func test_base_hint_hud_does_not_block_pause() -> void:
	var hud := BaseHUD.new()
	add_child_autofree(hud)
	menu.blockers = [hud]
	assert_true(hud.is_showing(), "petunjuk base memang terlihat")
	assert_true(menu.open(), "teks HUD bukan panel modal: P tetap membuka Jeda")
	assert_true(menu.visible)


func test_open_panel_still_blocks_pause() -> void:
	var panel := OpenPanel.new()
	add_child_autofree(panel)
	menu.blockers = [panel]
	assert_false(menu.open(), "panel modal tetap memblokir Jeda")
	assert_false(menu.is_open())


func test_main_menu_button_requests_scene_change() -> void:
	watch_signals(menu)
	menu.open()
	menu.request_main_menu()
	assert_signal_emitted(menu, "main_menu_requested")
	assert_false(menu.is_open(), "menu ditutup sebelum pindah scene")
