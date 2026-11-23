class_name DeathController
extends Node

## Kematian, respawn, loot bag, dan debuff proficiency (spesifikasi V8 §7.6).
##
## Pemilik `respawns_remaining` (3 token; kematian keempat = game over).
## HP tetap milik StatsComponent; komponen ini hanya memanggil set_hp().
## Mission 9 (keputusan owner): saat mati seluruh game DIBEKUKAN lewat
## FreezeController alasan &"death"; jam game berhenti selama layar mati.
## Layar/popup tetap jalan karena process_mode ALWAYS. Logika rescue untuk
## kematian saat fajar Hari 7 tetap berlaku.
##
## Loot bag dijatuhkan di posisi mati dari seluruh 12 slot tas; equipment tetap
## terpasang. Debuff memakai `ProficiencyComponent.apply_death_debuff()`.

signal died(respawns_remaining: int)
## Mission 7: rincian debuff yang diterapkan saat respawn.
signal debuff_applied(changes: Array)

var _last_debuff_changes: Array = []
signal respawned
signal game_over

const RESPAWN_POSITION := Vector2(0.0, 64.0)
## Spec §7.6: 3 kesempatan respawn, kematian ke-4 permanen.
const RESPAWN_TOKENS := 3
## Spec: respawn dengan 70% HP, Hunger 60, Thirst 60, Fatigue 80.
const RESPAWN_HP_RATIO := 0.7
const RESPAWN_HUNGER := 60.0
const RESPAWN_THIRST := 60.0
const RESPAWN_FATIGUE := 80.0
const LOOT_BAG_SCENE: PackedScene = preload("res://src/entities/props/loot_bag/loot_bag.tscn")
const DAMAGE_RECEIVER_NAME := "PlayerDamageReceiver"

@export var stats: StatsComponent
@export var player: Node
@export var needs: NeedsComponent
@export var inventory: InventoryComponent
@export var proficiency: ProficiencyComponent
## Mission 9: lama perlindungan respawn (null = angka bawaan RunConfig).
@export var run_config: RunConfig

var respawns_remaining: int = RESPAWN_TOKENS
var is_dead: bool = false
var last_loot_bag: Node

var _bound: bool = false


func _ready() -> void:
	_bind()


func setup(p_player: Node) -> void:
	player = p_player
	_bound = false
	_bind()


# --- Read API ---------------------------------------------------------------

func get_respawns_remaining() -> int:
	return respawns_remaining


func can_respawn() -> bool:
	return respawns_remaining >= 0


func get_last_loot_bag() -> Node:
	return last_loot_bag if is_instance_valid(last_loot_bag) else null


# --- Kontrol ----------------------------------------------------------------

## Respawn ke kamp. False bila token habis (game over permanen).
func get_last_debuff_changes() -> Array:
	return _last_debuff_changes


func respawn() -> bool:
	_bind()
	if not can_respawn() or not is_dead:
		return false

	is_dead = false
	_restore_player()
	if player is Node2D:
		(player as Node2D).global_position = CampAnchor.respawn_position_of(self)

	if stats != null:
		stats.get_max_hp()
		stats.set_hp(stats.get_max_hp() * RESPAWN_HP_RATIO)
	if needs != null:
		needs.set_value(NeedsComponent.Need.HUNGER, RESPAWN_HUNGER)
		needs.set_value(NeedsComponent.Need.THIRST, RESPAWN_THIRST)
		needs.set_value(NeedsComponent.Need.FATIGUE, RESPAWN_FATIGUE)
	if proficiency != null:
		var before: Array[int] = []
		for prof in ProficiencyComponent.PROF_COUNT:
			before.append(proficiency.get_level(prof))
		var changed: Array[int] = proficiency.apply_death_debuff()
		_last_debuff_changes = []
		for prof in changed:
			_last_debuff_changes.append({
				"prof": prof,
				"from_level": before[prof] if prof < before.size() else 0,
				"to_level": proficiency.get_level(prof),
			})
		debuff_applied.emit(_last_debuff_changes)

	_release_freeze()
	_start_protection()
	respawned.emit()
	return true


# --- Internal ---------------------------------------------------------------

func _bind() -> void:
	if _bound:
		return
	if player == null:
		var tree := get_tree()
		if tree != null:
			player = tree.get_first_node_in_group(&"player")
	if player != null:
		if stats == null:
			stats = player.get_node_or_null("StatsComponent") as StatsComponent
		if needs == null:
			needs = player.get_node_or_null("NeedsComponent") as NeedsComponent
		if inventory == null:
			inventory = player.get_node_or_null("InventoryComponent") as InventoryComponent
		if proficiency == null:
			proficiency = player.get_node_or_null("ProficiencyComponent") as ProficiencyComponent
	if stats != null and not stats.hp_changed.is_connected(_on_hp_changed):
		stats.hp_changed.connect(_on_hp_changed)
	_bound = true


func _on_hp_changed(current: float, _max_value: float) -> void:
	if is_dead or current > 0.0:
		return
	_die()


func _die() -> void:
	is_dead = true
	respawns_remaining -= 1
	# Mission 9: beku sebelum layar mati tampil (jam berhenti).
	var freezer := FreezeController.find_controller(self)
	if freezer != null:
		freezer.request(FreezeController.REASON_DEATH)
	_drop_loot()
	_disable_player()
	died.emit(respawns_remaining)
	if respawns_remaining < 0:
		game_over.emit()


func _disable_player() -> void:
	if player == null:
		return
	player.process_mode = Node.PROCESS_MODE_DISABLED
	if player is Node2D:
		(player as Node2D).velocity = Vector2.ZERO
		(player as Node2D).visible = false


func _release_freeze() -> void:
	var freezer := FreezeController.find_controller(self)
	if freezer != null:
		freezer.release(FreezeController.REASON_DEATH)


## Mission 9: perlindungan respawn (timer nyata, mulai setelah beku dilepas).
func _start_protection() -> void:
	if player == null:
		return
	var receiver := player.get_node_or_null(DAMAGE_RECEIVER_NAME) as PlayerDamageReceiver
	if receiver == null:
		return
	if run_config != null:
		receiver.run_config = run_config
	receiver.start_protection()


func _restore_player() -> void:
	if player == null:
		return
	player.process_mode = Node.PROCESS_MODE_INHERIT
	if player is Node2D:
		(player as Node2D).visible = true


## Jatuhkan seluruh isi tas di posisi mati. Equipment tidak ikut.
func _drop_loot() -> void:
	if inventory == null:
		return
	var stacks: Array[ItemStack] = []
	for index in inventory.get_capacity():
		var stack := inventory.get_slot(index)
		if stack == null or stack.is_empty():
			continue
		var copy := ItemStack.new()
		copy.item = stack.item
		copy.count = stack.count
		stacks.append(copy)
	if stacks.is_empty():
		return

	var parent := _loot_parent()
	if parent == null:
		return
	var bag := LOOT_BAG_SCENE.instantiate() as LootBag
	if bag == null:
		return
	parent.add_child(bag)
	bag.setup(stacks)
	if player is Node2D:
		bag.global_position = (player as Node2D).global_position
	last_loot_bag = bag
	inventory.clear()


func _loot_parent() -> Node:
	var tree := get_tree()
	if tree == null:
		return null
	var owner_node := get_parent()
	if owner_node != null and owner_node.is_inside_tree():
		return owner_node
	if tree.current_scene != null:
		return tree.current_scene
	return tree.root
