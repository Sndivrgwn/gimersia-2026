class_name InputSetup
extends RefCounted

## Mendaftarkan action Input Map yang dipakai modul player.
## Idempotent: aman dipanggil dari banyak scene dan tidak menduplikasi event.
## Memakai physical_keycode agar tetap sama di layout keyboard berbeda.

const MOVE_LEFT := &"move_left"
const MOVE_RIGHT := &"move_right"
const MOVE_UP := &"move_up"
const MOVE_DOWN := &"move_down"
const SPRINT := &"sprint"
## Mission 9 fase 4: tahan Ctrl untuk jongkok (lebih lambat, lebih samar).
const SNEAK := &"sneak"
const INVENTORY_TOGGLE := &"inventory_toggle"
## Hold E untuk gather/bangun/loot/beacon (InteractorComponent).
const INTERACT := &"interact"
## Hold R untuk memperbaiki struktur camp (RepairComponent).
const REPAIR := &"repair"
const PAUSE_TOGGLE := &"pause_toggle"
const HELP_TOGGLE := &"help_toggle"
## Debug khusus island (GatherDebug): F2 aktifkan, F3 zona berikutnya, F4 pagi berikutnya,
## F5 kit uji bahan crafting.
const DEBUG_ISLAND_TOGGLE := &"debug_island_toggle"
const DEBUG_ISLAND_ZONE := &"debug_island_zone"
const DEBUG_ISLAND_MORNING := &"debug_island_morning"
## F5: beri kit bahan uji crafting (island only).
const DEBUG_ISLAND_KIT := &"debug_island_kit"
## F6-F10 (island only): spawn fauna, lompat ke malam, heal, siklus senjata.
const DEBUG_ISLAND_BOAR := &"debug_island_boar"
const DEBUG_ISLAND_DEER := &"debug_island_deer"
const DEBUG_ISLAND_NIGHT := &"debug_island_night"
const DEBUG_ISLAND_HEAL := &"debug_island_heal"
const DEBUG_ISLAND_WEAPON := &"debug_island_weapon"
## F11: matikan pemain (uji death screen). F12: lompat ke fajar Hari 7 (rescue).
const DEBUG_ISLAND_KILL := &"debug_island_kill"
const DEBUG_ISLAND_RESCUE := &"debug_island_rescue"
## Insert (island debug): tampilkan label temperament/state di atas setiap fauna.
const DEBUG_FAUNA_LABELS := &"debug_fauna_labels"
## Mission 9: backtick / Home (island debug): muat ulang art aset, tampilkan kotak slot
## aset. Pindah dari F1 karena F1 sudah dipakai debug_needs_toggle (practice).
const DEBUG_RELOAD_ASSETS := &"debug_reload_assets"
## Mission 9: J (island debug): picu raid sekarang juga.
const DEBUG_RAID := &"debug_raid"
const DEBUG_ASSET_BOXES := &"debug_asset_boxes"
## B: tentukan lokasi base (BasePlacementController).
const BASE_PLACE := &"base_place"
## Fase 4C: Q memutar ring pagar preview base 15° (Shift+Q arah sebaliknya).
const BASE_ROTATE := &"base_rotate"
## Mission 11: K (island debug): rekam 6 detik jejak fisika pemain + 2 fauna
## terdekat ke CSV user:// (laporan "fauna masih terseret").
const DEBUG_DRAG_TRACE := &"debug_drag_trace"
## Mission 12: lompat ke awal periode jam berikutnya (Pagi/Siang/Sore/Malam).
const DEBUG_ISLAND_PERIOD := &"debug_island_period"
## Mission 13 (blok H): overlay debug dunia (island only). O belum dipakai.
const DEBUG_WORLD_OVERLAY := &"debug_world_overlay"

## Mission 10 Phase 3: hotbar memilih item; use_held memakainya.
const HOTBAR_NEXT := &"hotbar_next"
const HOTBAR_PREV := &"hotbar_prev"
const USE_HELD := &"use_held"

## Serangan manual: klik kiri (arah kursor) dan Space (arah hadap).
const ATTACK_CLICK := &"attack_click"
const ATTACK_SPACE := &"attack_space"

## Tombol 1-5 memakai slot hotbar InventoryComponent.
## Action gerak; dipakai Player, dan oleh komponen yang membatalkan aksi saat
## pemain bergerak (CraftingComponent, NightWatchController).
const MOVE_ACTIONS: Array[StringName] = [
	&"move_left",
	&"move_right",
	&"move_up",
	&"move_down",
]
const HOTBAR_ACTIONS: Array[StringName] = [
	&"hotbar_1",
	&"hotbar_2",
	&"hotbar_3",
	&"hotbar_4",
	&"hotbar_5",
]
const HOTBAR_KEYS: Array[Key] = [KEY_1, KEY_2, KEY_3, KEY_4, KEY_5]

## Tab dan I membuka panel tas (BagPanel).
const INVENTORY_TOGGLE_KEYS: Array[Key] = [KEY_TAB, KEY_I]


static func ensure_actions() -> void:
	_ensure_action(MOVE_LEFT)
	_ensure_key(MOVE_LEFT, KEY_A)
	_ensure_key(MOVE_LEFT, KEY_LEFT)

	_ensure_action(MOVE_RIGHT)
	_ensure_key(MOVE_RIGHT, KEY_D)
	_ensure_key(MOVE_RIGHT, KEY_RIGHT)

	_ensure_action(MOVE_UP)
	_ensure_key(MOVE_UP, KEY_W)
	_ensure_key(MOVE_UP, KEY_UP)

	_ensure_action(MOVE_DOWN)
	_ensure_key(MOVE_DOWN, KEY_S)
	_ensure_key(MOVE_DOWN, KEY_DOWN)

	_ensure_action(SPRINT)
	_ensure_key(SPRINT, KEY_SHIFT)

	_ensure_action(SNEAK)
	_ensure_key(SNEAK, KEY_CTRL)

	_ensure_action(INVENTORY_TOGGLE)
	for key in INVENTORY_TOGGLE_KEYS:
		_ensure_key(INVENTORY_TOGGLE, key)

	_ensure_action(INTERACT)
	_ensure_key(INTERACT, KEY_E)

	_ensure_action(REPAIR)
	_ensure_key(REPAIR, KEY_R)

	_ensure_action(PAUSE_TOGGLE)
	_ensure_key(PAUSE_TOGGLE, KEY_P)

	_ensure_action(HELP_TOGGLE)
	_ensure_key(HELP_TOGGLE, KEY_H)

	# Esc bawaan Godot hanya punya keycode, bukan physical_keycode. Didaftarkan
	# eksplisit supaya "tutup panel" tetap sama di semua layout keyboard.
	_ensure_action(&"ui_cancel")
	_ensure_key(&"ui_cancel", KEY_ESCAPE)

	_ensure_action(DEBUG_ISLAND_TOGGLE)
	_ensure_key(DEBUG_ISLAND_TOGGLE, KEY_F2)
	_ensure_action(DEBUG_ISLAND_ZONE)
	_ensure_key(DEBUG_ISLAND_ZONE, KEY_F3)
	_ensure_action(DEBUG_ISLAND_MORNING)
	_ensure_key(DEBUG_ISLAND_MORNING, KEY_F4)
	_ensure_action(DEBUG_ISLAND_KIT)
	_ensure_key(DEBUG_ISLAND_KIT, KEY_F5)
	_ensure_action(DEBUG_ISLAND_BOAR)
	_ensure_key(DEBUG_ISLAND_BOAR, KEY_F6)
	_ensure_action(DEBUG_ISLAND_DEER)
	_ensure_key(DEBUG_ISLAND_DEER, KEY_F7)
	_ensure_action(DEBUG_ISLAND_NIGHT)
	_ensure_key(DEBUG_ISLAND_NIGHT, KEY_F8)
	_ensure_action(DEBUG_ISLAND_HEAL)
	_ensure_key(DEBUG_ISLAND_HEAL, KEY_F9)
	_ensure_action(DEBUG_ISLAND_WEAPON)
	_ensure_key(DEBUG_ISLAND_WEAPON, KEY_F10)
	_ensure_action(DEBUG_ISLAND_KILL)
	_ensure_key(DEBUG_ISLAND_KILL, KEY_F11)
	_ensure_action(DEBUG_ISLAND_RESCUE)
	_ensure_key(DEBUG_ISLAND_RESCUE, KEY_F12)

	_ensure_action(DEBUG_FAUNA_LABELS)
	_ensure_key(DEBUG_FAUNA_LABELS, KEY_INSERT)

	_ensure_action(DEBUG_RAID)
	_ensure_key(DEBUG_RAID, KEY_J)

	_ensure_action(DEBUG_RELOAD_ASSETS)
	_ensure_key(DEBUG_RELOAD_ASSETS, KEY_QUOTELEFT)
	_ensure_action(DEBUG_ASSET_BOXES)
	_ensure_key(DEBUG_ASSET_BOXES, KEY_HOME)

	_ensure_action(BASE_PLACE)
	_ensure_key(BASE_PLACE, KEY_B)

	_ensure_action(BASE_ROTATE)
	_ensure_key(BASE_ROTATE, KEY_Q)

	_ensure_action(DEBUG_DRAG_TRACE)
	_ensure_key(DEBUG_DRAG_TRACE, KEY_K)
	_ensure_action(DEBUG_ISLAND_PERIOD)
	_ensure_key(DEBUG_ISLAND_PERIOD, KEY_Y)
	_ensure_action(DEBUG_WORLD_OVERLAY)
	_ensure_key(DEBUG_WORLD_OVERLAY, KEY_O)

	_ensure_action(ATTACK_SPACE)
	_ensure_key(ATTACK_SPACE, KEY_SPACE)
	_ensure_action(ATTACK_CLICK)
	_ensure_mouse_button(ATTACK_CLICK, MOUSE_BUTTON_LEFT)

	_ensure_action(HOTBAR_NEXT)
	_ensure_mouse_button(HOTBAR_NEXT, MOUSE_BUTTON_WHEEL_DOWN)
	_ensure_action(HOTBAR_PREV)
	_ensure_mouse_button(HOTBAR_PREV, MOUSE_BUTTON_WHEEL_UP)
	_ensure_action(USE_HELD)
	_ensure_key(USE_HELD, KEY_F)
	_ensure_mouse_button(USE_HELD, MOUSE_BUTTON_RIGHT)

	for index in HOTBAR_ACTIONS.size():
		_ensure_action(HOTBAR_ACTIONS[index])
		_ensure_key(HOTBAR_ACTIONS[index], HOTBAR_KEYS[index])

	_ensure_gamepad()


## Gamepad (Mission 9 polish): stik kiri untuk gerak, A interaksi, X serang,
## Y tas, START jeda, RB sprint, D-pad untuk hotbar 1-4.
static func _ensure_gamepad() -> void:
	_ensure_joy_axis(MOVE_LEFT, JOY_AXIS_LEFT_X, -1.0)
	_ensure_joy_axis(MOVE_RIGHT, JOY_AXIS_LEFT_X, 1.0)
	_ensure_joy_axis(MOVE_UP, JOY_AXIS_LEFT_Y, -1.0)
	_ensure_joy_axis(MOVE_DOWN, JOY_AXIS_LEFT_Y, 1.0)
	_ensure_joy_button(SPRINT, JOY_BUTTON_RIGHT_SHOULDER)
	_ensure_joy_button(SNEAK, JOY_BUTTON_LEFT_STICK)
	_ensure_joy_button(INTERACT, JOY_BUTTON_A)
	_ensure_joy_button(ATTACK_SPACE, JOY_BUTTON_X)
	_ensure_joy_button(INVENTORY_TOGGLE, JOY_BUTTON_Y)
	_ensure_joy_button(PAUSE_TOGGLE, JOY_BUTTON_START)
	_ensure_joy_button(HOTBAR_ACTIONS[0], JOY_BUTTON_DPAD_UP)
	_ensure_joy_button(HOTBAR_ACTIONS[1], JOY_BUTTON_DPAD_DOWN)
	_ensure_joy_button(HOTBAR_ACTIONS[2], JOY_BUTTON_DPAD_LEFT)
	_ensure_joy_button(HOTBAR_ACTIONS[3], JOY_BUTTON_DPAD_RIGHT)


## True bila salah satu action gerak sedang ditekan (polling, bukan event).
static func is_movement_pressed() -> bool:
	for action in MOVE_ACTIONS:
		if Input.is_action_pressed(action):
			return true
	return false


static func _ensure_action(action: StringName) -> void:
	if not InputMap.has_action(action):
		InputMap.add_action(action)


static func _ensure_key(action: StringName, key: Key) -> void:
	if _has_physical_key(action, key):
		return

	var event := InputEventKey.new()
	event.physical_keycode = key
	InputMap.action_add_event(action, event)


static func _ensure_joy_button(action: StringName, button: JoyButton) -> void:
	for event in InputMap.action_get_events(action):
		var joy_event := event as InputEventJoypadButton
		if joy_event != null and joy_event.button_index == button:
			return
	var created := InputEventJoypadButton.new()
	created.button_index = button
	InputMap.action_add_event(action, created)


static func _ensure_joy_axis(action: StringName, axis: JoyAxis, value: float) -> void:
	for event in InputMap.action_get_events(action):
		var motion := event as InputEventJoypadMotion
		if motion != null and motion.axis == axis and is_equal_approx(motion.axis_value, value):
			return
	var created := InputEventJoypadMotion.new()
	created.axis = axis
	created.axis_value = value
	InputMap.action_add_event(action, created)


static func _ensure_mouse_button(action: StringName, button: MouseButton) -> void:
	for event in InputMap.action_get_events(action):
		var mouse_event := event as InputEventMouseButton
		if mouse_event != null and mouse_event.button_index == button:
			return
	var created := InputEventMouseButton.new()
	created.button_index = button
	InputMap.action_add_event(action, created)


static func _has_physical_key(action: StringName, key: Key) -> bool:
	for event in InputMap.action_get_events(action):
		var key_event := event as InputEventKey
		if key_event != null and key_event.physical_keycode == key:
			return true
	return false
