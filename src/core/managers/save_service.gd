class_name SaveService
extends RefCounted

## Layanan simpan-lanjut ringan (non-autoload) di user://save_run.json.
##
## Membaca dan memulihkan state run lewat API publik komponen yang sudah ada
## tanpa mengubah struktur/kontrak modul. Toleran terhadap file hilang/rusak.

const SAVE_PATH := "user://save_run.json"
const FORMAT_VERSION := 1

static var _pending_load: bool = false


# --- Pending load handoff (MainMenu -> Island) ------------------------------

static func request_load_on_next_island() -> void:
	_pending_load = true


static func cancel_pending_load() -> void:
	_pending_load = false


static func consume_pending_load() -> bool:
	var flag := _pending_load
	_pending_load = false
	return flag


# --- File helpers -----------------------------------------------------------

static func has_save(path: String = SAVE_PATH) -> bool:
	return not read_raw(path).is_empty()


static func read_summary(path: String = SAVE_PATH) -> Dictionary:
	var data := read_raw(path)
	if data.is_empty():
		return {}
	var clock_data: Dictionary = data.get("clock", {})
	return {
		"day": int(clock_data.get("day", 1)),
		"phase": int(clock_data.get("phase", 0)),
	}


static func clear_save(path: String = SAVE_PATH) -> void:
	if FileAccess.file_exists(path):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(path))


static func read_raw(path: String = SAVE_PATH) -> Dictionary:
	if not FileAccess.file_exists(path):
		return {}
	var text := FileAccess.get_file_as_string(path)
	if text.is_empty():
		return {}
	var parser := JSON.new()
	if parser.parse(text) != OK:
		return {}
	var parsed: Variant = parser.data
	if not (parsed is Dictionary):
		return {}
	var data: Dictionary = parsed
	if int(data.get("version", 0)) != FORMAT_VERSION:
		return {}
	return data


static func save_island(island: Node, path: String = SAVE_PATH, clock: Node = null) -> bool:
	if island == null:
		return false
	var data := capture_island(island, clock)
	if data.is_empty():
		return false
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		return false
	file.store_string(JSON.stringify(data))
	file.close()
	return true


static func load_island(island: Node, path: String = SAVE_PATH, clock: Node = null) -> bool:
	if island == null:
		return false
	var data := read_raw(path)
	if data.is_empty():
		return false
	return apply_to_island(island, data, clock)


# --- Capture ----------------------------------------------------------------

static func capture_island(island: Node, clock_override: Node = null) -> Dictionary:
	var player := island.get_node_or_null("Player") as Node2D
	if player == null:
		return {}
	var clock: Node = clock_override if clock_override != null else island.get_node_or_null("/root/DayNightManager")
	var data := {
		"version": FORMAT_VERSION,
		"player": {"x": player.global_position.x, "y": player.global_position.y},
	}

	if clock != null and clock.has_method(&"get_current_day"):
		data["clock"] = {
			"day": int(clock.call(&"get_current_day")),
			"phase": int(clock.call(&"get_phase")) if clock.has_method(&"get_phase") else 0,
			"phase_elapsed": float(clock.call(&"get_phase_elapsed")) if clock.has_method(&"get_phase_elapsed") else 0.0,
			"rescue_triggered": bool(clock.get("rescue_triggered")),
		}

	var stats := player.get_node_or_null("StatsComponent") as StatsComponent
	if stats != null:
		data["stats"] = {
			"hp": stats.current_hp,
			"strength": stats.strength_level,
			"speed": stats.speed_level,
			"mastery": stats.mastery_level,
			"agility": stats.agility_level,
		}

	var needs := player.get_node_or_null("NeedsComponent") as NeedsComponent
	if needs != null:
		data["needs"] = {
			"hunger": needs.get_value(NeedsComponent.Need.HUNGER),
			"thirst": needs.get_value(NeedsComponent.Need.THIRST),
			"fatigue": needs.get_value(NeedsComponent.Need.FATIGUE),
			"fatigue_cap": needs.get_fatigue_cap(),
		}

	var prof := player.get_node_or_null("ProficiencyComponent") as ProficiencyComponent
	if prof != null:
		var xp_arr: Array = []
		var max_arr: Array = []
		for i in ProficiencyComponent.PROF_COUNT:
			xp_arr.append(prof.get_xp(i))
			max_arr.append(prof.get_max_reached_level(i))
		data["proficiency"] = {"xp": xp_arr, "max_reached": max_arr}

	var death := island.get_node_or_null("DeathController") as DeathController
	if death != null:
		data["death"] = {"respawns_remaining": death.get_respawns_remaining()}

	var inv := player.get_node_or_null("InventoryComponent") as InventoryComponent
	if inv != null:
		data["inventory"] = _capture_inventory(inv)

	data["camp"] = _capture_camp(island)
	return data


static func _capture_inventory(inv: InventoryComponent) -> Dictionary:
	var slots_out: Array = []
	for i in inv.get_capacity():
		var item := inv.get_slot_item(i)
		var count := inv.get_slot_count(i)
		if item != null and count > 0:
			slots_out.append({"id": String(item.id), "count": count})
		else:
			slots_out.append(null)
	var weapon := inv.get_equipped(ItemDefinition.EquipmentSlot.WEAPON)
	var armor := inv.get_equipped(ItemDefinition.EquipmentSlot.ARMOR)
	var tools_out: Array = []
	for candidate in [ItemCatalog.STONE_AXE, ItemCatalog.STONE_PICKAXE]:
		if inv.has_tool(candidate):
			tools_out.append(String(candidate.id))
	return {
		"slots": slots_out,
		"weapon": "" if weapon == null else String(weapon.id),
		"armor": "" if armor == null else String(armor.id),
		"tools": tools_out,
	}


static func _capture_camp(island: Node) -> Dictionary:
	var result := {"founded": false, "center_x": 0.0, "center_y": 0.0, "fence_rotation": 0.0, "structures": []}
	var anchor := CampAnchor.find_anchor(island)
	if anchor != null and anchor.is_founded():
		var c := anchor.get_center()
		result["founded"] = true
		result["center_x"] = c.x
		result["center_y"] = c.y
		result["fence_rotation"] = anchor.get_fence_rotation()
	var camp := island.get_node_or_null("CampController") as CampController
	if camp != null:
		var structs: Array = []
		for s in camp.get_structures():
			var entry := {
				"id": String(s.get_id()),
				"hp": s.get_current_hp(),
			}
			if s is Campfire:
				var fire := s as Campfire
				entry["fuel"] = fire.get_fuel()
				entry["lit"] = fire.is_lit()
				entry["has_been_lit"] = fire.has_been_lit
			structs.append(entry)
		result["structures"] = structs
	return result


# --- Apply ------------------------------------------------------------------

static func apply_to_island(island: Node, data: Dictionary, clock_override: Node = null) -> bool:
	var player := island.get_node_or_null("Player") as Node2D
	if player == null:
		return false

	var clock: Node = clock_override if clock_override != null else island.get_node_or_null("/root/DayNightManager")
	if clock != null and data.has("clock") and clock.has_method(&"restore_state"):
		var cd: Dictionary = data["clock"]
		clock.call(
			&"restore_state",
			int(cd.get("day", 1)),
			int(cd.get("phase", 0)),
			float(cd.get("phase_elapsed", 0.0)),
			bool(cd.get("rescue_triggered", false))
		)

	if data.has("player"):
		var pd: Dictionary = data["player"]
		player.global_position = Vector2(float(pd.get("x", 0.0)), float(pd.get("y", 64.0)))

	var stats := player.get_node_or_null("StatsComponent") as StatsComponent
	if stats != null and data.has("stats"):
		var sd: Dictionary = data["stats"]
		stats.strength_level = int(sd.get("strength", 1))
		stats.speed_level = int(sd.get("speed", 1))
		stats.mastery_level = int(sd.get("mastery", 1))
		stats.agility_level = int(sd.get("agility", 1))
		stats.set_hp(float(sd.get("hp", stats.get_max_hp())))

	var needs := player.get_node_or_null("NeedsComponent") as NeedsComponent
	if needs != null and data.has("needs"):
		var nd: Dictionary = data["needs"]
		needs.set_value(NeedsComponent.Need.HUNGER, float(nd.get("hunger", 100.0)))
		needs.set_value(NeedsComponent.Need.THIRST, float(nd.get("thirst", 100.0)))
		if nd.has("fatigue_cap"):
			needs.set("_fatigue_cap", clampf(float(nd["fatigue_cap"]), 0.0, 100.0))
		needs.set_value(NeedsComponent.Need.FATIGUE, float(nd.get("fatigue", 100.0)))

	var prof := player.get_node_or_null("ProficiencyComponent") as ProficiencyComponent
	if prof != null and data.has("proficiency"):
		var prd: Dictionary = data["proficiency"]
		var xp_arr: Array = prd.get("xp", [])
		var max_arr: Array = prd.get("max_reached", [])
		var xp_typed: Array[float] = [0.0, 0.0, 0.0, 0.0]
		var max_typed: Array[int] = [1, 1, 1, 1]
		for i in ProficiencyComponent.PROF_COUNT:
			if i < xp_arr.size():
				xp_typed[i] = maxf(float(xp_arr[i]), 0.0)
			if i < max_arr.size():
				max_typed[i] = maxi(int(max_arr[i]), 1)
		prof.set("_xp", xp_typed)
		prof.set("_max_reached", max_typed)

	var death := island.get_node_or_null("DeathController") as DeathController
	if death != null and data.has("death"):
		death.respawns_remaining = maxi(int(data["death"].get("respawns_remaining", DeathController.RESPAWN_TOKENS)), 0)

	var inv := player.get_node_or_null("InventoryComponent") as InventoryComponent
	if inv != null and data.has("inventory"):
		_apply_inventory(inv, data["inventory"])

	if data.has("camp"):
		_apply_camp(island, data["camp"])

	return true


static func _apply_inventory(inv: InventoryComponent, inv_data: Dictionary) -> void:
	inv.clear_all() if inv.has_method(&"clear_all") else _clear_inventory_slots(inv)
	var slots_in: Array = inv_data.get("slots", [])
	var raw_slots: Array[ItemStack] = inv.get_slots()
	for i in mini(slots_in.size(), raw_slots.size()):
		var entry: Variant = slots_in[i]
		if entry is Dictionary:
			var item := ItemCatalog.get_by_id(StringName(str(entry.get("id", ""))))
			var count := int(entry.get("count", 0))
			if item != null and count > 0:
				raw_slots[i] = ItemStack.new(item, count)
				inv.slot_changed.emit(i)
	var weapon_id := str(inv_data.get("weapon", ""))
	if not weapon_id.is_empty():
		var w := ItemCatalog.get_by_id(StringName(weapon_id))
		if w != null:
			inv.equip(w)
	var armor_id := str(inv_data.get("armor", ""))
	if not armor_id.is_empty():
		var a := ItemCatalog.get_by_id(StringName(armor_id))
		if a != null:
			inv.equip(a)
	for tid in inv_data.get("tools", []):
		var tool_item := ItemCatalog.get_by_id(StringName(str(tid)))
		if tool_item != null:
			inv.equip(tool_item)
	inv.inventory_changed.emit()


static func _clear_inventory_slots(inv: InventoryComponent) -> void:
	var raw_slots: Array[ItemStack] = inv.get_slots()
	for i in raw_slots.size():
		if raw_slots[i] != null:
			raw_slots[i] = null
			inv.slot_changed.emit(i)


static func _apply_camp(island: Node, camp_data: Dictionary) -> void:
	var anchor := CampAnchor.find_anchor(island)
	if anchor != null and bool(camp_data.get("founded", false)):
		var center := Vector2(float(camp_data.get("center_x", 0.0)), float(camp_data.get("center_y", 0.0)))
		anchor.found(center, float(camp_data.get("fence_rotation", 0.0)))
	var camp := island.get_node_or_null("CampController") as CampController
	if camp == null:
		return
	var slots_by_id: Dictionary = {}
	for slot in camp.get_slots():
		if slot != null and slot.definition != null:
			slots_by_id[String(slot.definition.id)] = slot
	for entry in camp_data.get("structures", []):
		if not (entry is Dictionary):
			continue
		var sid := str(entry.get("id", ""))
		var slot: BlueprintSlot = slots_by_id.get(sid)
		if slot == null:
			continue
		var built := slot.build_from_save()
		if built == null:
			continue
		if entry.has("hp") and built.has_method(&"set_hp"):
			built.call(&"set_hp", float(entry["hp"]))
		if built is Campfire:
			var fire := built as Campfire
			if entry.has("fuel"):
				fire.set_fuel(float(entry["fuel"]))
			if bool(entry.get("lit", false)) and fire.can_ignite():
				fire.ignite()
			elif bool(entry.get("has_been_lit", false)):
				fire.has_been_lit = true
