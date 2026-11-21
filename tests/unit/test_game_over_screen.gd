extends GutTest

const GAME_OVER_SCENE := preload("res://src/ui/menus/game_over_screen.tscn")


func test_starts_hidden_and_toggles() -> void:
	var screen := GAME_OVER_SCENE.instantiate() as GameOverScreen
	add_child_autofree(screen)
	assert_false(screen.is_showing(), "Layar harus tersembunyi saat siap")
	screen.show_screen()
	assert_true(screen.is_showing(), "show_screen harus menampilkan panel")
	screen.hide_screen()
	assert_false(screen.is_showing(), "hide_screen harus menyembunyikan panel")


func test_show_game_over_alias() -> void:
	var screen := GAME_OVER_SCENE.instantiate() as GameOverScreen
	add_child_autofree(screen)
	screen.show_game_over()
	assert_true(screen.is_showing(), "show_game_over harus menampilkan panel")


func test_buttons_emit_signals() -> void:
	var screen := GAME_OVER_SCENE.instantiate() as GameOverScreen
	add_child_autofree(screen)

	var restart_button := screen.get_node("Panel/Column/RestartButton") as Button
	var menu_button := screen.get_node("Panel/Column/MenuButton") as Button
	assert_not_null(restart_button, "Tombol Mulai Baru harus ada")
	assert_not_null(menu_button, "Tombol Menu Utama harus ada")
	assert_eq(restart_button.text, "Mulai Baru")
	assert_eq(menu_button.text, "Menu Utama")

	watch_signals(screen)
	restart_button.pressed.emit()
	assert_signal_emitted(screen, "restart_requested")
	menu_button.pressed.emit()
	assert_signal_emitted(screen, "main_menu_requested")
