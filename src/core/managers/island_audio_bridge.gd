class_name IslandAudioBridge
extends Node

## Penghubung sinyal gameplay pulau ke autoload AudioManager.
##
## Dipasang oleh `island.gd` sehingga komponen gameplay tetap terisolasi dan
## mudah dites tanpa bergantung langsung pada playback audio.
## Mengelola:
## - Transisi ambience per zona (hutan <-> pantai ocean+wind, sungai, malam)
## - Langkah kaki pemain per zona (pasir, rumput, air, wading)
## - Irama menambang batu (`gathering_mine_hit`)
## - Semua hook sinyal SFX, UI, dan sting kematian/respawn/endgame yang sudah ada.

const STEP_DISTANCE_WALK := 48.0
const STEP_DISTANCE_SPRINT := 38.0
const MINE_HIT_INTERVAL := 0.24

var _island: Node
var _player: Node2D
var _clock: Node
var _interactor: InteractorComponent
var _inventory: InventoryComponent

var _last_zone: int = -1
var _last_is_night: bool = false
var _ambience_initialized: bool = false

var _step_accum: float = 0.0
var _last_player_pos: Vector2 = Vector2.ZERO
var _has_last_pos: bool = false

var _mine_timer: float = 0.0
var _hold_ratio: float = 0.0

var _last_inventory_total: int = 0
var _suppress_pickup_until: float = 0.0
var _hotbar_ready: bool = false


func setup(island: Node, player: Node2D) -> void:
	_island = island
	_player = player


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	if _island == null:
		_island = get_parent()
	if _player == null and _island != null:
		_player = _island.get_node_or_null("Player") as Node2D
	_clock = get_node_or_null("/root/DayNightManager")

	_bind_player()
	_bind_island_controllers()
	_scan_subtree(_island)

	var tree := get_tree()
	if tree != null and not tree.node_added.is_connected(_on_node_added):
		tree.node_added.connect(_on_node_added)

	_update_ambience(true)
	if _player != null:
		_last_player_pos = _player.global_position
		_has_last_pos = true


func _exit_tree() -> void:
	var tree := get_tree()
	if tree != null and tree.node_added.is_connected(_on_node_added):
		tree.node_added.disconnect(_on_node_added)
	var audio := _audio()
	if audio != null:
		audio.stop_ambience()
		audio.set_pause_duck(false)


func _process(delta: float) -> void:
	_update_ambience(false)
	var tree := get_tree()
	if tree != null and tree.paused:
		return
	_tick_mining(delta)


func _physics_process(_delta: float) -> void:
	var tree := get_tree()
	if tree != null and tree.paused:
		return
	_tick_footsteps()


# --- Ambience & Crossfade ---------------------------------------------------

func _update_ambience(instant: bool) -> void:
	var audio := _audio()
	if audio == null or _player == null or not is_instance_valid(_player):
		return
	var zone := IslandZones.zone_at(_player.global_position)
	var is_night := _clock != null and _clock.has_method(&"is_night") and bool(_clock.call(&"is_night"))
	if not _ambience_initialized or zone != _last_zone or is_night != _last_is_night:
		_ambience_initialized = true
		_last_zone = zone
		_last_is_night = is_night
		audio.set_ambience_state(zone, is_night, instant)


# --- Footsteps & Mining Rhythm ----------------------------------------------

func _tick_footsteps() -> void:
	if _player == null or not is_instance_valid(_player) or not _player.visible:
		return
	if _player.process_mode == Node.PROCESS_MODE_DISABLED:
		return
	if not _has_last_pos:
		_last_player_pos = _player.global_position
		_has_last_pos = true
		return

	var delta_dist := _player.global_position.distance_to(_last_player_pos)
	_last_player_pos = _player.global_position
	# Abaikan teleport / respawn loncatan jauh
	if delta_dist <= 0.25 or delta_dist > 120.0:
		return

	_step_accum += delta_dist
	var sprinting := _player.has_method(&"is_sprinting") and bool(_player.call(&"is_sprinting"))
	var threshold := STEP_DISTANCE_SPRINT if sprinting else STEP_DISTANCE_WALK
	if _step_accum < threshold:
		return
	_step_accum -= threshold

	var audio := _audio()
	if audio == null:
		return
	var sneaking := _player.has_method(&"is_sneaking") and bool(_player.call(&"is_sneaking"))
	var wading := _player.has_method(&"is_wading") and bool(_player.call(&"is_wading"))
	var zone := IslandZones.zone_at(_player.global_position)

	var cue := &"player_footstep_grass"
	if wading:
		cue = &"player_footstep_wade"
	elif zone == IslandZones.Zone.RIVER:
		cue = &"player_footstep_water"
	elif zone == IslandZones.Zone.SOUTH_BEACH or zone == IslandZones.Zone.EAST_BEACH:
		cue = &"player_footstep_sand"

	var vol := -10.0 if sneaking else (-3.0 if sprinting else -5.0)
	audio.play_at(cue, _player.global_position, vol, 0.08, 700.0)


func _tick_mining(delta: float) -> void:
	if _interactor == null or not is_instance_valid(_interactor) or _hold_ratio <= 0.0:
		_mine_timer = 0.0
		return
	if _interactor.is_waiting_for_release():
		_mine_timer = 0.0
		return
	var target := _interactor.get_target()
	if not (target is ResourceNode):
		_mine_timer = 0.0
		return
	var res_node := target as ResourceNode
	if res_node.definition == null or res_node.definition.item == null:
		_mine_timer = 0.0
		return
	if res_node.definition.item.id != &"stone":
		_mine_timer = 0.0
		return

	_mine_timer += delta
	if _mine_timer >= MINE_HIT_INTERVAL:
		_mine_timer -= MINE_HIT_INTERVAL
		var audio := _audio()
		if audio != null:
			audio.play_at(&"gathering_mine_hit", res_node.global_position, -2.0, 0.08)


# --- Player Binding ---------------------------------------------------------

func _bind_player() -> void:
	if _player == null:
		return

	var combat := _player.get_node_or_null("CombatComponent") as CombatComponent
	if combat != null:
		_connect_once(combat, &"swing", _on_combat_swing)
		_connect_once(combat, &"hit_dealt", _on_combat_hit_dealt)

	var feedback := _player.get_node_or_null("CombatFeedback") as CombatFeedback
	if feedback != null:
		_connect_once(feedback, &"feedback_event", _on_combat_feedback)

	_inventory = _player.get_node_or_null("InventoryComponent") as InventoryComponent
	if _inventory != null:
		_last_inventory_total = _count_inventory_items(_inventory)
		_connect_once(_inventory, &"item_used", _on_item_used)
		_connect_once(_inventory, &"inventory_changed", _on_inventory_changed)

	var hotbar := _player.get_node_or_null("HotbarSelectionComponent") as HotbarSelectionComponent
	if hotbar != null:
		_connect_once(hotbar, &"selected_changed", _on_hotbar_changed)
		call_deferred(&"_enable_hotbar_sound")

	_interactor = _player.get_node_or_null("InteractorComponent") as InteractorComponent
	if _interactor != null:
		_connect_once(_interactor, &"interaction_blocked", _on_interaction_blocked)
		_connect_once(_interactor, &"progress_changed", _on_interact_progress)

	var crafting := _player.get_node_or_null("CraftingComponent") as CraftingComponent
	if crafting != null:
		_connect_once(crafting, &"craft_completed", _on_craft_completed)

	var repair := _player.get_node_or_null("RepairComponent") as RepairComponent
	if repair != null:
		_connect_once(repair, &"repair_completed", _on_repair_completed)

	var prof := _player.get_node_or_null("ProficiencyComponent") as ProficiencyComponent
	if prof != null:
		_connect_once(prof, &"level_changed", _on_proficiency_level_up)
		_connect_once(prof, &"passive_unlocked", _on_proficiency_passive)


func _enable_hotbar_sound() -> void:
	_hotbar_ready = true


# --- Island Controllers & UI Binding ----------------------------------------

func _bind_island_controllers() -> void:
	if _island == null:
		return

	var pause_menu := _island.get_node_or_null("PauseMenu") as PauseMenu
	if pause_menu != null:
		_connect_once(pause_menu, &"paused", _on_pause_opened)
		_connect_once(pause_menu, &"resumed", _on_pause_resumed)

	var station_panel := _island.get_node_or_null("StationPanel") as StationPanel
	if station_panel != null:
		_connect_once(station_panel, &"opened", _on_station_opened)
		_connect_once(station_panel, &"closed", _on_station_closed)

	var chest_panel := _island.get_node_or_null("ChestPanel") as ChestPanel
	if chest_panel != null:
		_connect_once(chest_panel, &"closed", _on_chest_panel_closed)

	var hint_mgr := _island.get_node_or_null("HintManager") as HintManager
	if hint_mgr != null:
		_connect_once(hint_mgr, &"hint_shown", _on_hint_shown)

	var death := _island.get_node_or_null("DeathController") as DeathController
	if death != null:
		_connect_once(death, &"died", _on_player_died)
		_connect_once(death, &"game_over", _on_game_over)

	var endgame := _island.get_node_or_null("EndgameController") as EndgameController
	if endgame != null:
		_connect_once(endgame, &"rescue_ready", _on_rescue_ready)
		_connect_once(endgame, &"victory", _on_victory)
		_connect_once(endgame, &"banner_shown", _on_banner_shown)

	var beacon := _island.get_node_or_null("Beacon") as SignalBeacon
	if beacon != null:
		_connect_once(beacon, &"victory_triggered", _on_beacon_activated.bind(beacon))

	var run_ctrl := _island.get_node_or_null("RunController") as RunController
	if run_ctrl != null:
		_connect_once(run_ctrl, &"main_menu_requested", _on_main_menu_requested)

	var base_place := _island.find_child("BasePlacementController", true, false) as BasePlacementController
	if base_place != null:
		_connect_once(base_place, &"base_placed", _on_base_placed)
		_connect_once(base_place, &"preview_changed", _on_base_preview_changed)


# --- Dynamic World Node Binding ---------------------------------------------

func _scan_subtree(root: Node) -> void:
	if root == null:
		return
	_bind_world_node(root)
	for child in root.get_children():
		_scan_subtree(child)


func _on_node_added(node: Node) -> void:
	if _island == null or not is_instance_valid(_island):
		return
	if not _island.is_ancestor_of(node):
		return
	_bind_world_node(node)


func _bind_world_node(node: Node) -> void:
	if node == null or node.has_meta(&"_audio_world_bound"):
		return

	if node is ChopFeedback:
		node.set_meta(&"_audio_world_bound", true)
		_connect_once(node, &"feedback_event", _on_chop_feedback)
	elif node is ResourceNode:
		node.set_meta(&"_audio_world_bound", true)
		_connect_once(node, &"gathered", _on_resource_gathered.bind(node))
	elif node is LootBag or node is EmergencySuitcase:
		node.set_meta(&"_audio_world_bound", true)
		_connect_once(node, &"looted", _on_loot_bag_looted)
	elif node is BlueprintSlot:
		node.set_meta(&"_audio_world_bound", true)
		_connect_once(node, &"built", _on_blueprint_built)
	elif node is Campfire:
		node.set_meta(&"_audio_world_bound", true)
		_bind_campfire(node as Campfire)
		_connect_once(node, &"destroyed", _on_structure_destroyed.bind(node))
	elif node is FenceSegment:
		node.set_meta(&"_audio_world_bound", true)
		_connect_once(node, &"damaged", _on_fence_damaged.bind(node))
		_connect_once(node, &"destroyed", _on_fence_destroyed.bind(node))
	elif node is Chest:
		node.set_meta(&"_audio_world_bound", true)
		_connect_once(node, &"interaction_requested", _on_chest_opened.bind(node))
		_connect_once(node, &"destroyed", _on_structure_destroyed.bind(node))
	elif node is CampStructure:
		node.set_meta(&"_audio_world_bound", true)
		_connect_once(node, &"destroyed", _on_structure_destroyed.bind(node))


func _bind_campfire(campfire: Campfire) -> void:
	var audio := _audio()
	if audio == null:
		return
	var loop_player: AudioStreamPlayer2D = audio.create_spatial_loop(&"campfire_loop", campfire, 540.0, -4.0) as AudioStreamPlayer2D
	if loop_player == null:
		return
	if campfire.is_lit():
		loop_player.play()
	campfire.lit_changed.connect(func(is_lit: bool) -> void:
		if not is_instance_valid(loop_player):
			return
		if is_lit:
			if not loop_player.playing:
				loop_player.play()
		else:
			loop_player.stop()
	)


# --- Signal Handlers --------------------------------------------------------

func _on_combat_swing(_aim: Vector2, _hits: int) -> void:
	var audio := _audio()
	if audio != null and _player != null:
		audio.play_at(&"player_attack_swing", _player.global_position, -2.0, 0.08)


func _on_combat_hit_dealt(target: Node, _damage: float) -> void:
	var audio := _audio()
	if audio == null:
		return
	var pos := (target as Node2D).global_position if target is Node2D else (_player.global_position if _player != null else Vector2.ZERO)
	audio.play_at(&"player_hit_flesh", pos, 0.0, 0.07)


func _on_combat_feedback(kind: StringName, _pos: Vector2) -> void:
	var audio := _audio()
	if audio == null:
		return
	match kind:
		&"player_hurt":
			audio.play(&"player_hurt", 0.0, 0.06)
		&"dodge":
			audio.play(&"player_dodge", -2.0, 0.06)


func _on_item_used(item: ItemDefinition, _slot_index: int) -> void:
	var audio := _audio()
	if audio == null or item == null or item.effect == null:
		return
	var fx: ItemEffect = item.effect as ItemEffect
	if fx == null:
		return
	if fx.regen_hp_per_second > 0.0 or (fx.hp > 0.0 and fx.hunger <= 0.0 and fx.thirst <= 0.0):
		audio.play(&"player_bandage", -1.0, 0.04)
	elif fx.thirst > 0.0 and fx.thirst >= fx.hunger:
		audio.play(&"player_drink", -1.0, 0.05)
	elif fx.hunger > 0.0:
		audio.play(&"player_eat", -1.0, 0.05)


func _on_inventory_changed() -> void:
	if _inventory == null:
		return
	var total := _count_inventory_items(_inventory)
	var gained := total > _last_inventory_total
	_last_inventory_total = total
	if not gained:
		return
	var now := Time.get_ticks_msec() / 1000.0
	if now < _suppress_pickup_until:
		return
	var audio := _audio()
	if audio != null:
		audio.play_throttled(&"item_pickup", 0.08, -2.0, 0.06)


func _on_hotbar_changed(_index: int, _stack: ItemStack) -> void:
	if not _hotbar_ready:
		return
	var audio := _audio()
	if audio != null:
		audio.play_throttled(&"player_swap_held", 0.05, -6.0, 0.04)


func _on_interaction_blocked(_target: Interactable, _reason: String) -> void:
	var audio := _audio()
	if audio != null:
		audio.play_throttled(&"ui_error", 0.3, -2.0, 0.02)


func _on_interact_progress(ratio: float) -> void:
	_hold_ratio = clampf(ratio, 0.0, 1.0)
	if _hold_ratio <= 0.0:
		_mine_timer = 0.0


func _on_craft_completed(_recipe: RecipeDefinition) -> void:
	_suppress_pickup_until = Time.get_ticks_msec() / 1000.0 + 0.15
	var audio := _audio()
	if audio != null:
		audio.play(&"craft_done", -1.0, 0.03)


func _on_repair_completed(structure: CampStructure) -> void:
	var audio := _audio()
	if audio != null and structure != null:
		audio.play_at(&"repair_done", structure.global_position, -1.0, 0.03)


func _on_proficiency_level_up(_prof: int, _level: int) -> void:
	var audio := _audio()
	if audio != null:
		audio.play(&"proficiency_level_up", 0.0, 0.0)


func _on_proficiency_passive(_prof: int, _level: int) -> void:
	var audio := _audio()
	if audio != null:
		audio.play(&"proficiency_passive_unlocked", 0.0, 0.0)


func _on_chop_feedback(kind: StringName, pos: Vector2) -> void:
	var audio := _audio()
	if audio == null:
		return
	match kind:
		&"chop_hit":
			audio.play_at(&"gathering_chop_hit", pos, -2.0, 0.08)
		&"tree_fall":
			audio.play_at(&"gathering_tree_fall", pos, 0.0, 0.05)


func _on_resource_gathered(definition: ResourceNodeDefinition, _amount: int, _interactor: Node, node: ResourceNode) -> void:
	var audio := _audio()
	if audio == null or definition == null or definition.item == null:
		return
	if definition.item.id == &"stone" and is_instance_valid(node):
		audio.play_at(&"gathering_rock_break", node.global_position, 0.0, 0.06)


func _on_loot_bag_looted() -> void:
	_suppress_pickup_until = Time.get_ticks_msec() / 1000.0 + 0.15
	var audio := _audio()
	if audio != null:
		audio.play(&"loot_bag", -1.0, 0.04)


func _on_blueprint_built(structure: CampStructure) -> void:
	var audio := _audio()
	if audio != null and structure != null:
		audio.play_at(&"build_done", structure.global_position, 0.0, 0.03)


func _on_fence_damaged(_amount: float, _source: Node, fence: Node2D) -> void:
	var audio := _audio()
	if audio != null and is_instance_valid(fence):
		audio.play_at(&"fence_hit", fence.global_position, -2.0, 0.06)


func _on_fence_destroyed(fence: Node2D) -> void:
	var audio := _audio()
	if audio != null and is_instance_valid(fence):
		audio.play_at(&"fence_break", fence.global_position, 0.0, 0.05)


func _on_structure_destroyed(structure: Node2D) -> void:
	var audio := _audio()
	if audio != null and is_instance_valid(structure):
		audio.play_at(&"structure_destroyed", structure.global_position, 0.0, 0.05)


func _on_chest_opened(_interactor: Node, chest: Node2D) -> void:
	var audio := _audio()
	if audio != null and is_instance_valid(chest):
		audio.play_at(&"chest_open", chest.global_position, -1.0, 0.04)


func _on_base_placed(_center: Vector2) -> void:
	var audio := _audio()
	if audio != null:
		audio.play(&"base_place_confirm", 0.0, 0.0)


func _on_base_preview_changed(valid: bool, _reason: String) -> void:
	if valid:
		return
	var audio := _audio()
	if audio != null:
		audio.play_throttled(&"base_place_invalid", 0.25, -3.0, 0.02)


func _on_pause_opened() -> void:
	var audio := _audio()
	if audio != null:
		audio.play_ui(&"ui_pause_on")
		audio.set_pause_duck(true)


func _on_pause_resumed() -> void:
	var audio := _audio()
	if audio != null:
		audio.play_ui(&"ui_pause_off")
		audio.set_pause_duck(false)


func _on_station_opened(_station: Node) -> void:
	var audio := _audio()
	if audio != null:
		audio.play_ui(&"station_open")


func _on_station_closed(_station: Node) -> void:
	var audio := _audio()
	if audio != null:
		audio.play_ui(&"station_close")


func _on_chest_panel_closed() -> void:
	var audio := _audio()
	if audio != null:
		audio.play_ui(&"ui_panel_close")


func _on_hint_shown(_id: StringName, _text: String) -> void:
	var audio := _audio()
	if audio != null:
		audio.play_ui(&"ui_hint", -2.0)


func _on_player_died(respawns_remaining: int) -> void:
	var audio := _audio()
	if audio == null:
		return
	audio.play(&"player_death", 0.0, 0.03)
	if respawns_remaining >= 0:
		audio.play_sting(&"music_death_sting")


func _on_game_over() -> void:
	var audio := _audio()
	if audio != null:
		audio.play_sting(&"music_game_over")


func _on_rescue_ready() -> void:
	var audio := _audio()
	if audio != null:
		audio.play(&"flare_launch", 0.0, 0.02)


func _on_victory() -> void:
	var audio := _audio()
	if audio != null:
		audio.play_sting(&"music_victory")


func _on_banner_shown(_text: String) -> void:
	var audio := _audio()
	if audio != null:
		audio.play_ui(&"ui_banner")


func _on_beacon_activated(beacon: Node2D) -> void:
	var audio := _audio()
	if audio != null and is_instance_valid(beacon):
		audio.play_at(&"beacon_activate", beacon.global_position, 0.0, 0.0)


func _on_main_menu_requested() -> void:
	var audio := _audio()
	if audio != null:
		audio.stop_ambience()
		audio.set_pause_duck(false)


# --- Helpers ----------------------------------------------------------------

func _audio() -> Node:
	return get_node_or_null("/root/AudioManager")


func _connect_once(emitter: Object, sig: StringName, handler: Callable) -> void:
	if emitter == null or not emitter.has_signal(sig):
		return
	if not emitter.is_connected(sig, handler):
		emitter.connect(sig, handler)


func _count_inventory_items(inv: InventoryComponent) -> int:
	var total := 0
	for i in inv.get_capacity():
		var stack := inv.get_slot(i)
		if stack != null and not stack.is_empty():
			total += stack.count
	return total
