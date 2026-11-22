extends Node2D

const ScreenFade := preload("res://src/ui/fx/screen_fade.gd")

## Root scene pulau minimum.
##
## Clock tidak diurus di sini: autoload DayNightManager sudah `auto_start`
## (sama seperti practice1). Scene ini hanya menaruh pemain menghadap utara
## sesuai spec; arah hadap bukan state gameplay yang perlu disimpan.
##
## Wiring endgame/death juga di sini supaya tiap node tetap punya satu tugas:
## DeathController memiliki state kematian, DeathScreen hanya UI, RunController
## yang memindahkan scene.

@export var player_path: NodePath = ^"Player"
@export var start_facing: Vector2 = Vector2.UP

@onready var _death: DeathController = get_node_or_null("DeathController") as DeathController
@onready var _death_screen: DeathScreen = get_node_or_null("DeathScreen") as DeathScreen
@onready var _game_over_screen: GameOverScreen = get_node_or_null("GameOverScreen") as GameOverScreen
@onready var _run: RunController = get_node_or_null("RunController") as RunController
@onready var _endgame: EndgameController = get_node_or_null("EndgameController") as EndgameController
@onready var _endgame_hud: EndgameHUD = get_node_or_null("EndgameHUD") as EndgameHUD
@onready var _beacon: SignalBeacon = get_node_or_null("Beacon") as SignalBeacon


func _wire_hud(player: Node) -> void:
	var spawner := find_child("NightSpawner", true, false)
	var quota := find_child("FaunaQuota", true, false)
	var death := find_child("DeathController", true, false)
	var endgame := find_child("EndgameController", true, false)
	var banner := find_child("NightBanner", true, false) as NightBanner
	if banner != null:
		banner.endgame = endgame
	var survival := find_child("NightSurvivalHUD", true, false) as NightSurvivalHUD
	if survival != null:
		survival.spawner = spawner
		survival.quota = quota
		if spawner != null:
			survival.scaling = spawner.get("scaling") as NightScalingConfig
	var recap := find_child("RespawnRecapHUD", true, false) as RespawnRecapHUD
	if death != null and recap != null and death.has_signal(&"debuff_applied"):
		death.debuff_applied.connect(recap.show_recap)
	var prof_hud := find_child("ProficiencyHUD", true, false) as ProficiencyHUD
	if death != null and prof_hud != null and death.has_signal(&"debuff_applied"):
		death.debuff_applied.connect(prof_hud.flash_rows)


## Mission 10: toast, angka damage, dan busur arah serangan (semua read-only).
func _wire_feedback_hud(player: Node) -> void:
	for node_name in ["ToastHUD", "DamageNumbers", "HitDirection"]:
		var hud := get_node_or_null(node_name)
		if hud != null and hud.has_method(&"bind_player"):
			hud.call(&"bind_player", player)


func _wire_chest_panel(player: Node) -> void:
	var panel := get_node_or_null("ChestPanel") as ChestPanel
	if panel == null or player == null:
		return
	panel.inventory = player.get_node_or_null("InventoryComponent") as InventoryComponent
	panel.player = player as Node2D
	panel.bag_panel = find_child("BagPanel", true, false)


func _wire_pause_menu() -> void:
	var menu := get_node_or_null("PauseMenu") as PauseMenu
	if menu == null:
		return
	var names := ["BaseHUD", "FireStarterHUD", "BagPanel", "ChestPanel", "DeathScreen", "GameOverScreen", "EndgameHUD"]
	var blockers: Array[Node] = []
	for node_name in names:
		var node := find_child(node_name, true, false)
		if node != null:
			blockers.append(node)
	menu.blockers = blockers
	var settings := get_node_or_null("SettingsService") as SettingsService
	var settings_panel := get_node_or_null("PauseMenu/SettingsPanel") as SettingsPanel
	var help_panel := get_node_or_null("PauseMenu/HelpPanel") as HelpPanel
	var hint_manager := get_node_or_null("HintManager") as HintManager
	if settings != null:
		if settings_panel != null:
			settings_panel.setup(settings)
		if hint_manager != null:
			hint_manager.settings = settings
	if settings_panel != null:
		menu.settings_requested.connect(settings_panel.open)
	if help_panel != null:
		menu.help_requested.connect(help_panel.toggle)


func _ready() -> void:
	var player := get_node_or_null(player_path)
	if player != null:
		player.set("facing_direction", start_facing)
	_attach_world_visuals()
	_wire_endgame(player as Node2D)
	_wire_pause_menu()
	_wire_chest_panel(player)
	_wire_hud(player)
	_wire_feedback_hud(player)
	UiSkin.apply_all(self)
	ScreenFade.fade_in(self)


## Satu baris attach per slot world; tanpa art tidak ada yang berubah.
func _attach_world_visuals() -> void:
	var ground := get_node_or_null("Ground")
	if ground != null:
		VisualSlot.attach(ground, &"ground_forest", [ground.get_node_or_null("Forest")])
		VisualSlot.attach(ground, &"ground_south_beach", [ground.get_node_or_null("SouthBeach")])
		VisualSlot.attach(ground, &"ground_east_beach", [ground.get_node_or_null("EastBeach")])
		VisualSlot.attach(ground, &"ground_west_cliffs", [ground.get_node_or_null("WestCliffs")])
		VisualSlot.attach(ground, &"ground_river", [ground.get_node_or_null("River")])
		VisualSlot.attach(ground, &"ground_camp", [ground.get_node_or_null("Camp")])
	var wreckage := get_node_or_null("Wreckage")
	if wreckage != null:
		VisualSlot.attach(wreckage, &"plane_wreckage", [wreckage.get_node_or_null("Visual")])


func _wire_endgame(player: Node2D) -> void:
	if _run != null:
		_run.clock = get_node_or_null("/root/DayNightManager")

	if _endgame != null:
		_endgame.player = player
		_endgame.beacon = _beacon

	if _death != null:
		_death.player = player
		_death.died.connect(_on_player_died)

	if _death_screen != null:
		_death_screen.respawn_requested.connect(_on_respawn_requested)
		_death_screen.main_menu_requested.connect(_on_main_menu_requested)

	if _game_over_screen != null:
		_game_over_screen.restart_requested.connect(_on_restart_requested)
		_game_over_screen.main_menu_requested.connect(_on_main_menu_requested)

	if _endgame_hud != null:
		_endgame_hud.restart_requested.connect(_on_restart_requested)
		_endgame_hud.main_menu_requested.connect(_on_main_menu_requested)

	if _death != null and _death.game_over.is_connected(_on_game_over) == false:
		_death.game_over.connect(_on_game_over)


func _on_player_died(respawns_remaining: int) -> void:
	if _death_screen == null:
		return
	if respawns_remaining < 0:
		_on_game_over()
	else:
		_death_screen.show_death(respawns_remaining)


func _on_game_over() -> void:
	if _death_screen != null:
		_death_screen.hide_screen()
	if _game_over_screen != null:
		_game_over_screen.show_screen()
	elif _death_screen != null:
		_death_screen.show_game_over()


func _on_respawn_requested() -> void:
	if _death == null:
		return
	if _death.respawn() and _death_screen != null:
		_death_screen.hide_screen()


func _on_restart_requested() -> void:
	if _run != null:
		_run.request_restart()


func _on_main_menu_requested() -> void:
	if _run != null:
		_run.request_main_menu()
