class_name InventoryComponent
extends Node

## Inventory pemain: 12 slot tas (slot 0-4 = hotbar) plus slot peralatan
## WEAPON / ARMOR / TOOL.
##
## Pemilik tunggal isi inventory. Modul lain membaca getter / mendengar sinyal
## dan menambah item lewat `add_item()` / `add_or_drop()`; jangan menulis array
## slot dari luar.
##
## Pemakaian item memakai `use_slot()`: Hunger/Thirst lewat `NeedsComponent.add()`,
## HP lewat `StatsComponent`, Fatigue lewat
## `NeedsComponent.restore_fatigue_capacity()` (plafon Fatigue ikut naik, sesuai
## perilaku makan yang sudah berjalan; item tidak memanggil `add(FATIGUE, ...)`).
## HoT (`regen_*`) sengaja tidak diterapkan karena belum ada sistem status effect.
##
## Slot peralatan: WEAPON dan ARMOR menyimpan satu item. TOOL adalah set
## kepemilikan (Stone Axe + Stone Pickaxe), bukan satu item per slot.
## Armor memakai modifier StatsComponent dengan source_id tetap `equip_armor`.

## Satu slot tas berubah (isi dan/atau jumlahnya).
signal slot_changed(index: int)
## Slot peralatan berubah (ItemDefinition.EquipmentSlot).
signal equipment_changed(slot: int)
## Isi inventory berubah (sekali per aksi, bukan per slot).
signal inventory_changed()
## Mission 10: dipancarkan bila sebagian/semua item tidak muat (umpan ToastHUD).
signal add_blocked(item: ItemDefinition, remaining: int)

const DEFAULT_CONFIG: InventoryConfig = preload("res://src/data/configs/inventory_config.tres")
const ARMOR_SOURCE_ID := &"equip_armor"
const PICKUP_SCENE_PATH := "res://src/entities/props/item_pickup.tscn"
const PLAYER_GROUP := &"player"
const HOTBAR_ACTIONS: Array[StringName] = [
	&"hotbar_1",
	&"hotbar_2",
	&"hotbar_3",
	&"hotbar_4",
	&"hotbar_5",
]

## Angka tuning. Null berarti memakai InventoryConfig() bawaan.
@export var config: InventoryConfig = DEFAULT_CONFIG
## Opsional: diisi otomatis dari parent (Player) bila kosong.
@export var needs_component: NeedsComponent
@export var stats: StatsComponent
@export var player: Node

## Tombol 1-5 memakai slot hotbar. Matikan di scene tes bila input tidak ingin
## ikut aktif.
@export var hotbar_input_enabled: bool = true

var _slots: Array[ItemStack] = []
## EquipmentSlot (int) -> ItemDefinition.
var _equipment: Dictionary = {}
## Set kepemilikan tool: item id (StringName) -> true.
var _tools: Dictionary = {}
var _pickup_scene: PackedScene
var _bound: bool = false


func _ready() -> void:
	_bind()


# --- Setup ------------------------------------------------------------------

## Rangkai dependensi secara eksplisit (dipakai tes dan scene lain).
func setup(p_player: Node, p_needs: NeedsComponent = null, p_stats: StatsComponent = null) -> void:
	player = p_player
	needs_component = p_needs
	stats = p_stats
	if is_inside_tree():
		_bind()


func get_config() -> InventoryConfig:
	return config


# --- Read API ---------------------------------------------------------------

func get_capacity() -> int:
	return maxi(_config().bag_size, 0)


func get_hotbar_size() -> int:
	return mini(maxi(_config().hotbar_size, 0), get_capacity())


## ItemStack pada slot, atau null bila kosong / index tidak valid.
func get_slot(index: int) -> ItemStack:
	if not _is_valid_slot(index):
		return null
	return _slots[index]


func get_slot_item(index: int) -> ItemDefinition:
	var stack := get_slot(index)
	if stack == null:
		return null
	return stack.item


func get_slot_count(index: int) -> int:
	var stack := get_slot(index)
	if stack == null:
		return 0
	return stack.count


func is_slot_empty(index: int) -> bool:
	var stack := get_slot(index)
	return stack == null or stack.is_empty()


## Total item dengan id tertentu di seluruh tas.
func count_of(item: Variant) -> int:
	return ItemSlotStore.count_of(_slots, item)


## Alias lama: hitung berdasarkan id.
func count_item(item_id: StringName) -> int:
	return count_of(item_id)


func has_item(item: Variant, count: int = 1) -> bool:
	if count <= 0:
		return true
	return count_of(item) >= count


## Tas penuh bila tidak ada satu pun slot kosong.
func is_full() -> bool:
	return ItemSlotStore.is_full(_slots)


func get_equipped(slot: int) -> ItemDefinition:
	return _equipment.get(slot, null) as ItemDefinition


## TOOL adalah kepemilikan bersama; cek id tool apa pun di sini.
func has_tool(item: Variant) -> bool:
	var id := _id_of(item)
	return id != &"" and _tools.has(id)


# --- Write API --------------------------------------------------------------

## Masukkan item; mengembalikan sisa yang tidak muat (0 = semua masuk).
## Stack yang sama diisi lebih dulu (urutan slot), lalu slot kosong paling kiri.
## Urutan slot tidak pernah diacak.
func add_item(item: ItemDefinition, count: int = 1) -> int:
	if item == null or count <= 0:
		return maxi(count, 0)
	_ensure_slots()

	var touched: Array[int] = []
	var remaining := ItemSlotStore.add(_slots, item, count, touched)

	if touched.is_empty():
		if remaining > 0:
			add_blocked.emit(item, remaining)
			return remaining
		return 0
	for index in touched:
		slot_changed.emit(index)
	inventory_changed.emit()
	if remaining > 0:
		add_blocked.emit(item, remaining)
	return remaining


## Buang item; atomik (semua atau tidak sama sekali). `item` boleh
## ItemDefinition atau StringName id. True bila seluruh jumlah terbuang.
func remove_item(item: Variant, count: int = 1) -> bool:
	if count <= 0:
		return false
	_ensure_slots()
	var touched: Array[int] = []
	if not ItemSlotStore.remove(_slots, item, count, touched):
		return false

	for index in touched:
		slot_changed.emit(index)
	inventory_changed.emit()
	return true


## Ganti satu item di tas dengan varian lain tanpa menggeser urutan slot.
## Dipakai mengisi ulang Waterskin kosong menjadi penuh di sungai.
func replace_item(from_item: Variant, to_item: ItemDefinition) -> bool:
	if to_item == null:
		return false
	var from_id := _id_of(from_item)
	if from_id == &"":
		return false
	_ensure_slots()
	for index in _slots.size():
		var stack := _slots[index]
		if stack == null or stack.item == null or stack.item.id != from_id:
			continue
		stack.item = to_item
		slot_changed.emit(index)
		inventory_changed.emit()
		return true
	return false


## Pecah satu tumpukan jadi dua: separuh (dibulatkan ke atas) tetap di slot
## asal, sisanya pindah ke slot kosong pertama. True bila berhasil.
func split_slot(index: int) -> bool:
	if not _is_valid_slot(index):
		return false
	var stack := _slots[index]
	if stack == null or stack.item == null or stack.count <= 1:
		return false

	var target := -1
	for slot_index in _slots.size():
		if slot_index == index:
			continue
		var other := _slots[slot_index]
		if other == null or other.is_empty():
			target = slot_index
			break
	if target < 0:
		return false

	var moved := stack.count / 2
	stack.count -= moved
	_slots[target] = ItemStack.new(stack.item, moved)
	slot_changed.emit(index)
	slot_changed.emit(target)
	inventory_changed.emit()
	return true


## Urutkan tas: gabung stack item yang sama, lalu urut kategori -> id.
## Slot kosong selalu di belakang; equipment tidak disentuh. True bila ada
## slot yang benar-benar berubah.
func sort() -> bool:
	_ensure_slots()
	var totals: Dictionary = {}
	for stack in _slots:
		if stack == null or stack.item == null or stack.count <= 0:
			continue
		totals[stack.item] = int(totals.get(stack.item, 0)) + stack.count

	var items: Array[ItemDefinition] = []
	for item in totals.keys():
		items.append(item as ItemDefinition)
	items.sort_custom(_sort_before)

	var rebuilt: Array[ItemStack] = []
	for item in items:
		var remaining := int(totals[item])
		var stack_max := maxi(item.max_stack, 1)
		while remaining > 0:
			var take := mini(remaining, stack_max)
			rebuilt.append(ItemStack.new(item, take))
			remaining -= take

	var changed := false
	for index in _slots.size():
		var before := _slots[index]
		var after: ItemStack = rebuilt[index] if index < rebuilt.size() else null
		if _same_stack(before, after):
			continue
		_slots[index] = after
		slot_changed.emit(index)
		changed = true
	if changed:
		inventory_changed.emit()
	return changed


static func _sort_before(a: ItemDefinition, b: ItemDefinition) -> bool:
	if a.category != b.category:
		return a.category < b.category
	return String(a.id) < String(b.id)


static func _same_stack(a: ItemStack, b: ItemStack) -> bool:
	var a_empty := a == null or a.item == null or a.count <= 0
	var b_empty := b == null or b.item == null or b.count <= 0
	if a_empty or b_empty:
		return a_empty == b_empty
	return a.item.id == b.item.id and a.count == b.count


## Buang dari slot tertentu saja (dipakai transfer peti -> tas). Berbeda dari
## `remove_item()` yang mencari id dari slot terakhir, ini tidak menggeser isi
## slot lain saat pemain mengklik satu slot.
func remove_from_slot(index: int, count: int = 1) -> bool:
	if count <= 0 or not _is_valid_slot(index):
		return false
	var stack := _slots[index]
	if stack == null or stack.is_empty() or stack.count < count:
		return false
	stack.count -= count
	if stack.count <= 0:
		_slots[index] = null
	slot_changed.emit(index)
	inventory_changed.emit()
	return true


## Tambah sebanyak yang muat; sisa dijatuhkan sebagai ItemPickup di posisi
## pemilik (parent = current scene). Mengembalikan jumlah yang dijatuhkan.
func add_or_drop(item: ItemDefinition, count: int = 1) -> int:
	var leftover := add_item(item, count)
	if leftover <= 0 or item == null:
		return 0

	var parent := _drop_parent()
	if parent == null:
		push_warning("InventoryComponent: tidak ada scene untuk drop; item hilang.")
		return leftover

	var pickup := _get_pickup_scene().instantiate()
	if pickup == null:
		return leftover
	pickup.item = item
	pickup.count = leftover
	parent.add_child(pickup)
	if pickup is Node2D:
		(pickup as Node2D).global_position = _owner_position()
	return leftover


## Tukar dua slot, atau gabungkan bila item sama dan target masih punya ruang.
func move_slot(from: int, to: int) -> bool:
	if from == to or not _is_valid_slot(from) or not _is_valid_slot(to):
		return false
	var source := _slots[from]
	if source == null or source.is_empty():
		return false

	var target := _slots[to]
	if target == null or target.is_empty():
		_slots[to] = source
		_slots[from] = null
		slot_changed.emit(from)
		slot_changed.emit(to)
		inventory_changed.emit()
		return true

	if target.item != null and target.item.id == source.item.id:
		var stack_max := maxi(source.item.max_stack, 1)
		var space := stack_max - target.count
		if space <= 0:
			return false
		var moved := mini(space, source.count)
		target.count += moved
		source.count -= moved
		if source.count <= 0:
			_slots[from] = null
		slot_changed.emit(from)
		slot_changed.emit(to)
		inventory_changed.emit()
		return true

	_slots[to] = source
	_slots[from] = target
	slot_changed.emit(from)
	slot_changed.emit(to)
	inventory_changed.emit()
	return true


## Pakai item di slot. Hanya CONSUMABLE; item tetap terpakai walau stat sudah
## penuh. True bila item benar-benar dipakai. Item dengan `use_result` (mis.
## Waterskin) berubah menjadi varian itu di slot yang sama.
## Mission 7: hook additive setelah item berhasil dipakai.
signal item_used(item: ItemDefinition, slot_index: int)


func use_slot(index: int) -> bool:
	if is_slot_empty(index):
		return false
	var stack := _slots[index]
	var item := stack.item
	if item == null or not item.is_consumable():
		return false
	if needs_component == null and stats == null:
		push_warning("InventoryComponent: NeedsComponent/StatsComponent tidak ada; item tidak dipakai.")
		return false

	_apply_effect(item.consume_effect)
	_consume_one(index, item.use_result)
	item_used.emit(item, index)
	return true


## Pasang item ke slot peralatannya. WEAPON/ARMOR menggantikan isi slot,
## TOOL menambah kepemilikan. Duplikat diabaikan.
func equip(item: ItemDefinition) -> bool:
	if item == null:
		return false

	match item.equipment_slot:
		ItemDefinition.EquipmentSlot.WEAPON:
			_equipment[ItemDefinition.EquipmentSlot.WEAPON] = item
			equipment_changed.emit(ItemDefinition.EquipmentSlot.WEAPON)
			return true
		ItemDefinition.EquipmentSlot.ARMOR:
			_equipment[ItemDefinition.EquipmentSlot.ARMOR] = item
			_refresh_armor_modifiers()
			equipment_changed.emit(ItemDefinition.EquipmentSlot.ARMOR)
			return true
		ItemDefinition.EquipmentSlot.TOOL:
			if _tools.has(item.id):
				return true
			_tools[item.id] = true
			equipment_changed.emit(ItemDefinition.EquipmentSlot.TOOL)
			return true
		_:
			return false


func unequip(slot: int) -> bool:
	match slot:
		ItemDefinition.EquipmentSlot.WEAPON:
			if not _equipment.has(slot):
				return false
			_equipment.erase(slot)
			equipment_changed.emit(slot)
			return true
		ItemDefinition.EquipmentSlot.ARMOR:
			if not _equipment.has(slot):
				return false
			_equipment.erase(slot)
			_refresh_armor_modifiers()
			equipment_changed.emit(slot)
			return true
		ItemDefinition.EquipmentSlot.TOOL:
			if _tools.is_empty():
				return false
			_tools.clear()
			equipment_changed.emit(slot)
			return true
		_:
			return false


## Kosongkan tas. Slot peralatan tidak disentuh.
func clear() -> void:
	_ensure_slots()
	var touched: Array[int] = []
	var changed := ItemSlotStore.clear(_slots, touched)
	for index in touched:
		slot_changed.emit(index)
	if changed:
		inventory_changed.emit()


# --- Input ------------------------------------------------------------------

## Hotbar memakai action Input Map `hotbar_1..hotbar_5` yang terdaftar di
## `project.godot` [input]. Dibaca tiap frame, jadi tidak ada `_unhandled_input`
## dan tidak ada pencocokan raw keycode di sini.
func _process(_delta: float) -> void:
	if not hotbar_input_enabled or not _bound:
		return
	# Mission 10: mode pilih-item menggantikan "tekan angka = pakai".
	if _config().hotbar_select_mode:
		return
	for index in HOTBAR_ACTIONS.size():
		if Input.is_action_just_pressed(HOTBAR_ACTIONS[index]):
			use_slot(index)
			return


# --- Internal ---------------------------------------------------------------

func _config() -> InventoryConfig:
	if config == null:
		config = InventoryConfig.new()
	return config


func _bind() -> void:
	if player == null:
		player = get_parent()
	if needs_component == null and player != null:
		needs_component = player.get_node_or_null("NeedsComponent") as NeedsComponent
	if stats == null and player != null:
		stats = player.get_node_or_null("StatsComponent") as StatsComponent

	_ensure_slots()
	_bound = true
	InputSetup.ensure_actions()
	_refresh_armor_modifiers()


func _ensure_slots() -> void:
	ItemSlotStore.ensure_size(_slots, get_capacity())


func _is_valid_slot(index: int) -> bool:
	return index >= 0 and index < _slots.size()


func _id_of(item: Variant) -> StringName:
	return ItemSlotStore.resolve_id(item)


func _apply_effect(effect: ItemEffect) -> void:
	if effect == null:
		return
	if needs_component != null:
		if not is_zero_approx(effect.hunger):
			needs_component.add(NeedsComponent.Need.HUNGER, effect.hunger)
		if not is_zero_approx(effect.thirst):
			needs_component.add(NeedsComponent.Need.THIRST, effect.thirst)
		if effect.fatigue > 0.0:
			needs_component.restore_fatigue_capacity(effect.fatigue)
	if stats != null and not is_zero_approx(effect.hp):
		_apply_hp(effect.hp)
	# regen_hp_per_second / regen_duration sengaja tidak diterapkan:
	# belum ada sistem status effect (Bone Broth parsial).


func _apply_hp(amount: float) -> void:
	if amount > 0.0:
		stats.heal(amount)
	else:
		stats.get_max_hp()
		stats.set_hp(stats.current_hp + amount)


## Kurangi satu item di slot. Bila `replacement` diisi dan slot hanya berisi
## satu item, slot diganti varian itu (Waterskin penuh -> kosong).
func _consume_one(index: int, replacement: ItemDefinition = null) -> void:
	var stack := _slots[index]
	if replacement != null and stack.count <= 1:
		stack.item = replacement
		stack.count = 1
	else:
		stack.count -= 1
		if stack.count <= 0:
			_slots[index] = null
	slot_changed.emit(index)
	inventory_changed.emit()


## Hapus modifier armor lama lalu pasang yang baru (tidak pernah menumpuk).
func _refresh_armor_modifiers() -> void:
	if stats == null:
		return
	stats.remove_modifier(ARMOR_SOURCE_ID)

	var armor := get_equipped(ItemDefinition.EquipmentSlot.ARMOR)
	if armor == null:
		return
	if not is_zero_approx(armor.armor_damage_reduction):
		stats.add_modifier(
			ARMOR_SOURCE_ID,
			&"damage_reduction",
			StatModifier.Kind.PERCENT,
			armor.armor_damage_reduction
		)
	if not is_zero_approx(armor.armor_max_hp_bonus):
		stats.add_modifier(
			ARMOR_SOURCE_ID,
			&"max_hp",
			StatModifier.Kind.FLAT,
			armor.armor_max_hp_bonus
		)


func _get_pickup_scene() -> PackedScene:
	if _pickup_scene == null:
		_pickup_scene = load(PICKUP_SCENE_PATH) as PackedScene
	return _pickup_scene


func _drop_parent() -> Node:
	var tree := get_tree()
	if tree == null:
		return null
	if tree.current_scene != null:
		return tree.current_scene
	return tree.root


func _owner_position() -> Vector2:
	if player is Node2D:
		return (player as Node2D).global_position
	return Vector2.ZERO
