extends GutTest

## Mission 10 feedback: toast channel, angka damage, busur arah serangan.

const TOAST_PATH := "res://src/ui/hud/toast/toast_hud.gd"
const NUMBERS_PATH := "res://src/ui/hud/fx/damage_numbers.gd"
const ARROW_PATH := "res://src/ui/hud/fx/hit_direction.gd"


func _make_item(id: StringName, display: String, max_stack: int) -> ItemDefinition:
	var item := ItemDefinition.new()
	item.id = id
	item.display_name = display
	item.max_stack = max_stack
	return item


func test_toast_caps_visible_rows() -> void:
	var toast: CanvasLayer = load(TOAST_PATH).new()
	add_child_autofree(toast)
	for text in ["A", "B", "C", "D"]:
		toast.call(&"show_toast", text)
	var texts: Array[String] = toast.call(&"get_visible_texts")
	assert_eq(texts.size(), 3, "maksimal 3 toast")
	assert_eq(texts[-1], "D", "yang terbaru tetap terlihat")


func test_toast_dedupes_identical_message() -> void:
	var toast: CanvasLayer = load(TOAST_PATH).new()
	add_child_autofree(toast)
	toast.call(&"show_toast", "Bahan kurang")
	toast.call(&"show_toast", "Bahan kurang")
	var texts: Array[String] = toast.call(&"get_visible_texts")
	assert_eq(texts.size(), 1, "pesan sama tidak menumpuk")


func test_toast_expires() -> void:
	var toast: CanvasLayer = load(TOAST_PATH).new()
	add_child_autofree(toast)
	toast.call(&"show_toast", "Api unggun padam")
	toast.call(&"tick", 3.0)
	var texts: Array[String] = toast.call(&"get_visible_texts")
	assert_eq(texts.size(), 0)


func test_inventory_emits_add_blocked_when_full() -> void:
	var inventory := InventoryComponent.new()
	add_child_autofree(inventory)
	var item := _make_item(&"test_stack", "Uji", 1)
	watch_signals(inventory)
	var leftover := inventory.add_item(item, 30)
	assert_gt(leftover, 0, "sebagian tidak muat")
	assert_signal_emitted(inventory, "add_blocked")


func test_toast_reports_inventory_full() -> void:
	var player := Node.new()
	add_child_autofree(player)
	var inventory := InventoryComponent.new()
	inventory.name = "InventoryComponent"
	player.add_child(inventory)
	var toast: CanvasLayer = load(TOAST_PATH).new()
	add_child_autofree(toast)
	toast.call(&"bind_player", player)
	inventory.add_item(_make_item(&"test_stack", "Kayu", 1), 30)
	var texts: Array[String] = toast.call(&"get_visible_texts")
	assert_eq(texts.size(), 1)
	assert_string_contains(texts[0], "Tas penuh")


func test_damage_numbers_appear_and_expire() -> void:
	var numbers: CanvasLayer = load(NUMBERS_PATH).new()
	add_child_autofree(numbers)
	numbers.call(&"show_damage", Vector2(100, 100), 12.4)
	assert_eq(numbers.call(&"get_active_count"), 1)
	assert_eq(numbers.call(&"get_last_text"), "12", "dibulatkan ke bilangan bulat")
	numbers.call(&"tick", 0.7)
	assert_eq(numbers.call(&"get_active_count"), 0, "angka hilang setelah LIFE")


func test_hit_direction_tracks_angle_and_expires() -> void:
	var arrow: CanvasLayer = load(ARROW_PATH).new()
	add_child_autofree(arrow)
	arrow.call(&"show_from", Vector2.ZERO, Vector2(100, 0))
	assert_true(arrow.call(&"is_active"))
	assert_almost_eq(float(arrow.call(&"get_angle")), 0.0, 0.01, "serangan dari kanan")
	arrow.call(&"tick", 1.0)
	assert_false(arrow.call(&"is_active"), "busur memudar")


func test_craft_cancel_toast_through_wiring() -> void:
	var player := Node.new()
	add_child_autofree(player)
	var crafting := CraftingComponent.new()
	crafting.name = "CraftingComponent"
	player.add_child(crafting)
	var toast: CanvasLayer = load(TOAST_PATH).new()
	add_child_autofree(toast)
	toast.call(&"bind_player", player)
	crafting.craft_cancelled.emit(null, "Bahan kurang")
	var texts: Array[String] = toast.call(&"get_visible_texts")
	assert_eq(texts.size(), 1, "craft batal memunculkan toast")
	assert_eq(texts[0], "Crafting batal: Bahan kurang")


func test_campfire_fuel_toasts_through_wiring() -> void:
	var toast: CanvasLayer = load(TOAST_PATH).new()
	add_child_autofree(toast)
	var campfire := (load("res://src/entities/camp/campfire/campfire.tscn") as PackedScene).instantiate() as Campfire
	add_child_autofree(campfire)
	await wait_process_frames(1)

	campfire.fuel_changed.emit(30.0)
	var texts: Array[String] = toast.call(&"get_visible_texts")
	assert_eq(texts.size(), 1, "bahan bakar rendah memberi toast")
	assert_eq(texts[0], "Bahan bakar api hampir habis")

	campfire.fuel_depleted.emit()
	texts = toast.call(&"get_visible_texts")
	assert_eq(texts.size(), 2)
	assert_eq(texts[1], "Api unggun padam — isi bahan bakar")


func test_kill_popup_is_marker_not_zero() -> void:
	var numbers: CanvasLayer = load(NUMBERS_PATH).new()
	add_child_autofree(numbers)
	numbers.call(&"show_damage", Vector2(50, 50), 7.0)
	assert_eq(numbers.call(&"get_last_text"), "7")

	var player := Node.new()
	add_child_autofree(player)
	var combat := CombatComponent.new()
	combat.name = "CombatComponent"
	combat.player = player
	player.add_child(combat)
	numbers.call(&"bind_player", player)

	var victim := Node2D.new()
	add_child_autofree(victim)
	combat.enemy_killed.emit(victim)
	assert_eq(numbers.call(&"get_last_text"), "KO", "kill memakai penanda netral, bukan 0")
	assert_ne(numbers.call(&"get_last_text"), "0")
