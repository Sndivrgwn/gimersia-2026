extends SceneTree

## Generator tabel slot aset.
## Jalankan: GODOT --headless --path . -s tools/generate_asset_registry.gd
##
## Menulis ulang src/data/assets/asset_registry.tres (file ini MILIK generator
## ini; edit tangan akan tertimpa). Sumber kebenaran tabel ada di file ini.

const OUTPUT_PATH := "res://src/data/assets/asset_registry.tres"

const CHARACTER_STATES: PackedStringArray = ["idle", "walk", "hurt", "death"]
const RESOURCE_STATES: PackedStringArray = ["full", "depleted"]
const DIRS4 := AssetSlotDefinition.Direction.FOUR
const DIRS1 := AssetSlotDefinition.Direction.NONE
const CENTER := AssetSlotDefinition.Pivot.CENTER
const BOTTOM := AssetSlotDefinition.Pivot.BOTTOM_CENTER


func _init() -> void:
	var registry := AssetRegistry.new()
	registry.slots = _all_slots()

	var dir_path := OUTPUT_PATH.get_base_dir()
	DirAccess.make_dir_recursive_absolute(dir_path)
	var error := ResourceSaver.save(registry, OUTPUT_PATH)
	if error != OK:
		printerr("generate_asset_registry: gagal menyimpan %s (error %d)" % [OUTPUT_PATH, error])
		quit(1)
		return

	var priority1 := 0
	for slot in registry.slots:
		if slot.priority == 1:
			priority1 += 1
	print("generate_asset_registry: %d slot (%d prioritas 1) -> %s" % [
		registry.slots.size(), priority1, OUTPUT_PATH
	])
	quit(0)


func _all_slots() -> Array[AssetSlotDefinition]:
	var slots: Array[AssetSlotDefinition] = []
	slots.append_array(_character_slots())
	slots.append_array(_resource_slots())
	slots.append_array(_camp_slots())
	slots.append_array(_world_slots())
	slots.append_array(_effect_slots())
	slots.append_array(_ui_slots())
	return slots


# --- Characters -------------------------------------------------------------

func _character_slots() -> Array[AssetSlotDefinition]:
	var slots: Array[AssetSlotDefinition] = []

	slots.append(_slot(&"player", &"characters", "characters/player", ["idle", "walk", "sprint", "attack", "hurt", "death"], {
		"dirs": DIRS4,
		"size": Vector2(26.0, 30.0),
		"priority": 1,
		"recommended": Vector2i(32, 32),
		"loop": ["idle", "walk", "sprint"],
		"fps": {"idle": 6.0, "walk": 10.0, "sprint": 12.0, "attack": 14.0, "hurt": 10.0, "death": 10.0},
		"used_by": "src/entities/player/player.tscn (Player)",
		"description": "Pemain yang dikendalikan; 4 arah.",
		"notes": "State attack/hurt/death tidak berulang.",
	}))

	slots.append(_slot(&"wild_boar", &"characters", "characters/wild_boar", ["idle", "walk", "telegraph", "dash", "bite", "death"], {
		"dirs": DIRS4,
		"size": Vector2(34.0, 24.0),
		"priority": 1,
		"recommended": Vector2i(48, 32),
		"loop": ["idle", "walk"],
		"fps": {"idle": 6.0, "walk": 10.0, "telegraph": 8.0, "dash": 14.0, "bite": 14.0, "death": 10.0},
		"used_by": "src/entities/fauna/wild_boar/wild_boar.tscn",
		"description": "Babi hutan: mengembara, menyerbu, menggigit.",
		"notes": "telegraph = saat garis dash merah; dash = serudukan.",
	}))

	slots.append(_slot(&"island_deer", &"characters", "characters/island_deer", ["idle", "walk", "flee", "death"], {
		"dirs": DIRS4,
		"size": Vector2(36.0, 30.0),
		"priority": 1,
		"recommended": Vector2i(48, 40),
		"loop": ["idle", "walk", "flee"],
		"fps": {"idle": 6.0, "walk": 10.0, "flee": 12.0, "death": 10.0},
		"used_by": "src/entities/fauna/island_deer/island_deer.tscn",
		"description": "Rusa pulau yang selalu kabur.",
		"notes": "",
	}))
	return slots


# --- Resource nodes ---------------------------------------------------------

func _resource_slots() -> Array[AssetSlotDefinition]:
	var slots: Array[AssetSlotDefinition] = []
	var specs := [
		{"key": &"twig", "size": Vector2(26.0, 18.0), "rec": Vector2i(32, 24), "desc": "Ranting kecil di tanah."},
		{"key": &"small_tree", "size": Vector2(40.0, 52.0), "rec": Vector2i(48, 64), "desc": "Pohon kecil yang bisa ditebang."},
		{"key": &"tree", "size": Vector2(60.0, 76.0), "rec": Vector2i(64, 80), "desc": "Pohon besar; animasi tumbang tetap dari kode."},
		{"key": &"small_rock", "size": Vector2(28.0, 22.0), "rec": Vector2i(32, 24), "desc": "Batu kecil; butuh pickaxe."},
		{"key": &"big_rock", "size": Vector2(46.0, 34.0), "rec": Vector2i(48, 40), "desc": "Batu besar; butuh pickaxe."},
		{"key": &"fiber_bush", "size": Vector2(34.0, 26.0), "rec": Vector2i(40, 32), "desc": "Semak serat."},
		{"key": &"berry_bush", "size": Vector2(34.0, 28.0), "rec": Vector2i(40, 32), "desc": "Semak berry."},
		{"key": &"coconut_palm", "size": Vector2(60.0, 84.0), "rec": Vector2i(64, 96), "desc": "Pohon kelapa di pesisir."},
		{"key": &"bamboo_clump", "size": Vector2(38.0, 68.0), "rec": Vector2i(48, 80), "desc": "Rumpun bambu."},
	]
	for spec in specs:
		var key: StringName = spec["key"]
		slots.append(_slot(key, &"resources", "props/" + String(key), RESOURCE_STATES, {
			"size": spec["size"],
			"pivot": BOTTOM,
			"priority": 1,
			"recommended": spec["rec"],
			"loop": [],
			"fps": {"full": 6.0, "depleted": 6.0},
			"used_by": "src/entities/props/resource_node/resource_node.tscn (definisi di src/data/gathering/)",
			"description": spec["desc"],
			"notes": "state depleted hanya terlihat bila node masih tampil; node yang habis tetap disembunyikan seperti sekarang.",
		}))
	return slots


# --- Camp -------------------------------------------------------------------

func _camp_slots() -> Array[AssetSlotDefinition]:
	var slots: Array[AssetSlotDefinition] = []

	slots.append(_slot(&"campfire", &"camp", "props/campfire", ["lit", "ember", "cold"], {
		"size": Vector2(44.0, 34.0),
		"priority": 1,
		"recommended": Vector2i(48, 40),
		"loop": ["lit", "ember"],
		"fps": {"lit": 8.0, "ember": 6.0, "cold": 6.0},
		"used_by": "src/entities/camp/campfire/campfire.tscn",
		"description": "Api unggun menyala / bara / dingin.",
		"notes": "Cahaya PointLight2D tetap memakai radius dari CampfireConfig.",
	}))

	slots.append(_slot(&"workbench", &"camp", "props/workbench", ["default"], {
		"size": Vector2(56.0, 44.0),
		"pivot": BOTTOM,
		"priority": 1,
		"recommended": Vector2i(64, 48),
		"used_by": "src/entities/camp/workbench/workbench.tscn",
		"description": "Meja kerja.",
	}))

	slots.append(_slot(&"chest", &"camp", "props/chest", ["closed", "open"], {
		"size": Vector2(52.0, 40.0),
		"pivot": BOTTOM,
		"priority": 1,
		"recommended": Vector2i(56, 48),
		"loop": [],
		"fps": {"closed": 6.0, "open": 6.0},
		"used_by": "src/entities/camp/chest/chest.tscn",
		"description": "Peti penyimpanan; open saat panel peti terbuka.",
	}))

	slots.append(_slot(&"tent", &"camp", "props/tent", ["default", "sleeping"], {
		"size": Vector2(68.0, 50.0),
		"pivot": BOTTOM,
		"priority": 1,
		"recommended": Vector2i(80, 56),
		"loop": [],
		"fps": {"default": 6.0, "sleeping": 6.0},
		"used_by": "src/entities/camp/tent/tent.tscn",
		"description": "Tenda daun; sleeping singkat setelah tidur.",
	}))

	slots.append(_slot(&"fence_segment", &"camp", "props/fence_segment", ["default"], {
		"size": Vector2(40.0, 40.0),
		"priority": 2,
		"recommended": Vector2i(40, 40),
		"used_by": "src/levels/camp/fence_ring.gd (FenceSegment)",
		"description": "Satu segmen pagar.",
	}))

	for structure_id in ["campfire", "workbench", "chest", "tent", "fence_segment"]:
		slots.append(_slot(StringName("blueprint_" + structure_id), &"camp", "props/blueprint_" + structure_id, ["default"], {
			"size": Vector2(44.0, 44.0),
			"priority": 2,
			"recommended": Vector2i(48, 48),
			"used_by": "src/entities/camp/blueprint_slot.gd",
			"description": "Garis besar blueprint %s saat slot belum dibangun." % structure_id,
			"notes": "Dipakai hanya saat slot kosong.",
		}))

	slots.append(_slot(&"light_campfire", &"camp", "fx/light", ["default"], {
			"size": Vector2(128.0, 128.0),
			"priority": 2,
			"recommended": Vector2i(256, 256),
			"used_by": "src/entities/camp/campfire/campfire.gd (PointLight2D)",
			"description": "Tekstur cahaya api (gradient radial bawaan sebagai fallback).",
			"notes": "Radius cahaya tetap dari config; tekstur hanya diskalakan.",
			"stem": "campfire_light",
	}))
	return slots


# --- World ------------------------------------------------------------------

func _world_slots() -> Array[AssetSlotDefinition]:
	var slots: Array[AssetSlotDefinition] = []
	var zones := [
		{"key": &"ground_camp", "stem": "camp", "desc": "Tanah lapangan kamp."},
		{"key": &"ground_south_beach", "stem": "south_beach", "desc": "Pasir pantai selatan."},
		{"key": &"ground_east_beach", "stem": "east_beach", "desc": "Pasir pantai timur."},
		{"key": &"ground_west_cliffs", "stem": "west_cliffs", "desc": "Karst tebing barat."},
		{"key": &"ground_river", "stem": "river", "desc": "Air sungai."},
		{"key": &"ground_forest", "stem": "forest", "desc": "Lantai hutan."},
	]
	for zone in zones:
		slots.append(_slot(zone["key"], &"world", "world/ground", ["default"], {
			"size": Vector2(32.0, 32.0),
			"priority": 1,
			"recommended": Vector2i(32, 32),
			"tiled": true,
			"tile": Vector2(32.0, 32.0),
			"stem": zone["stem"],
			"used_by": "src/levels/island/island.tscn (node Ground)",
			"description": zone["desc"],
			"notes": "Ubin seamless; diulang per 32 px dunia.",
		}))

	slots.append(_slot(&"world_water", &"world", "world/ground", ["default"], {
		"size": Vector2(32.0, 32.0),
		"priority": 3,
		"recommended": Vector2i(32, 32),
		"tiled": true,
		"tile": Vector2(32.0, 32.0),
		"stem": "water",
		"optional": true,
		"used_by": "opsional, di belakang semua ground",
		"description": "Air laut di luar pulau.",
		"notes": "Belum ada node-nya di island.tscn; slot disiapkan untuk nanti.",
	}))

	slots.append(_slot(&"plane_wreckage", &"world", "props/plane_wreckage", ["default"], {
		"size": Vector2(140.0, 70.0),
		"priority": 1,
		"recommended": Vector2i(160, 80),
		"used_by": "src/levels/island/island.tscn (Wreckage/Visual)",
		"description": "Badan pesawat yang menabrak pulau.",
	}))

	slots.append(_slot(&"emergency_suitcase", &"world", "props/emergency_suitcase", ["closed", "open"], {
		"size": Vector2(40.0, 32.0),
		"priority": 1,
		"recommended": Vector2i(48, 40),
		"loop": [],
		"fps": {"closed": 6.0, "open": 6.0},
		"used_by": "src/entities/props/suitcase/emergency_suitcase.tscn",
		"description": "Koper darurat; open setelah diambil.",
	}))

	slots.append(_slot(&"signal_beacon", &"world", "props/signal_beacon", ["idle", "active"], {
		"size": Vector2(40.0, 48.0),
		"priority": 1,
		"recommended": Vector2i(48, 56),
		"loop": ["active"],
		"fps": {"idle": 6.0, "active": 10.0},
		"used_by": "src/entities/props/beacon/signal_beacon.gd (node Beacon di island.tscn)",
		"description": "Beacon suar; active saat fase rescue.",
	}))

	slots.append(_slot(&"river_edge", &"world", "props/river_edge", ["default"], {
		"size": Vector2(22.0, 22.0),
		"priority": 3,
		"recommended": Vector2i(24, 24),
		"optional": true,
		"used_by": "src/entities/props/river_edge/river_edge.tscn",
		"description": "Penanda tepi sungai.",
	}))

	slots.append(_slot(&"loot_bag", &"world", "props/loot_bag", ["default"], {
		"size": Vector2(30.0, 22.0),
		"priority": 2,
		"recommended": Vector2i(32, 24),
		"used_by": "src/entities/props/loot_bag/loot_bag.gd",
		"description": "Karung loot di lokasi kematian.",
	}))

	slots.append(_slot(&"item_pickup_shadow", &"world", "props/item_pickup_shadow", ["default"], {
		"size": Vector2(20.0, 10.0),
		"priority": 3,
		"recommended": Vector2i(24, 12),
		"optional": true,
		"used_by": "src/entities/props/item_pickup.gd",
		"description": "Bayangan di bawah item pickup.",
		"notes": "Dipakai sebagai texture ikon pickup bila ada.",
	}))
	return slots


# --- Effects ----------------------------------------------------------------

func _effect_slots() -> Array[AssetSlotDefinition]:
	var slots: Array[AssetSlotDefinition] = []

	slots.append(_slot(&"fx_slash", &"effects", "fx/slash", ["default"], {
		"size": Vector2(48.0, 48.0),
		"priority": 2,
		"recommended": Vector2i(64, 64),
		"used_by": "src/components/combat/combat_feedback.gd (arc slash)",
		"description": "Busur tebasan senjata.",
	}))

	slots.append(_slot(&"fx_hit_spark", &"effects", "fx/hit_spark", ["default"], {
		"size": Vector2(8.0, 8.0),
		"priority": 2,
		"recommended": Vector2i(8, 8),
		"used_by": "src/components/combat/combat_feedback.gd (pecahan hit)",
		"description": "Percikan saat hit.",
	}))

	slots.append(_slot(&"fx_chip", &"effects", "fx/chip", ["default"], {
		"size": Vector2(6.0, 6.0),
		"priority": 2,
		"recommended": Vector2i(8, 8),
		"used_by": "src/entities/props/resource_node/chop_feedback.gd (serpihan)",
		"description": "Serpihan kayu saat menebang.",
	}))

	slots.append(_slot(&"fx_dust", &"effects", "fx/dust", ["default"], {
		"size": Vector2(8.0, 8.0),
		"priority": 3,
		"recommended": Vector2i(8, 8),
		"optional": true,
		"used_by": "src/entities/fauna/fauna_base.gd (debu saat kabur)",
		"description": "Debu langkah.",
		"notes": "Opsional; tanpa art tidak ada yang berubah.",
	}))
	return slots


# --- UI ---------------------------------------------------------------------

func _ui_slots() -> Array[AssetSlotDefinition]:
	var slots: Array[AssetSlotDefinition] = []
	var nine := Vector4(8.0, 8.0, 8.0, 8.0)
	var nine_bar := Vector4(4.0, 4.0, 4.0, 4.0)

	slots.append(_ui_slot(&"ui_font_main", "ui/fonts", "main", Vector2(16.0, 16.0), 2, "Font teks utama UI.", "Hanya .ttf/.otf, dimuat lewat ResourceLoader.", "main"))
	slots.append(_ui_slot(&"ui_font_bold", "ui/fonts", "bold", Vector2(16.0, 16.0), 2, "Font tebal (judul/tekanan).", "Hanya .ttf/.otf.", "bold"))

	slots.append(_ui_slot(&"ui_panel", "ui", "panel", Vector2(256.0, 128.0), 1, "Panel dasar HUD/panel.", "Nine-slice 8 px.", "panel", nine))
	slots.append(_ui_slot(&"ui_button_normal", "ui", "button_normal", Vector2(160.0, 40.0), 2, "Tombol: normal.", "Nine-slice 8 px.", "button_normal", nine))
	slots.append(_ui_slot(&"ui_button_hover", "ui", "button_hover", Vector2(160.0, 40.0), 2, "Tombol: hover.", "Nine-slice 8 px.", "button_hover", nine))
	slots.append(_ui_slot(&"ui_button_pressed", "ui", "button_pressed", Vector2(160.0, 40.0), 2, "Tombol: ditekan.", "Nine-slice 8 px.", "button_pressed", nine))
	slots.append(_ui_slot(&"ui_button_disabled", "ui", "button_disabled", Vector2(160.0, 40.0), 3, "Tombol: nonaktif.", "Nine-slice 8 px.", "button_disabled", nine))
	slots.append(_ui_slot(&"ui_slot_frame", "ui", "slot_frame", Vector2(48.0, 48.0), 2, "Bingkai slot inventori/hotbar.", "Nine-slice 8 px.", "slot_frame", nine))
	slots.append(_ui_slot(&"ui_bar_bg", "ui", "bar_bg", Vector2(120.0, 12.0), 2, "Latar bar kebutuhan/HP.", "Nine-slice 4 px.", "bar_bg", nine_bar))

	var bars := [
		{"key": &"ui_bar_fill_hunger", "stem": "bar_fill_hunger", "desc": "Isi bar Hunger."},
		{"key": &"ui_bar_fill_thirst", "stem": "bar_fill_thirst", "desc": "Isi bar Thirst."},
		{"key": &"ui_bar_fill_fatigue", "stem": "bar_fill_fatigue", "desc": "Isi bar Fatigue."},
		{"key": &"ui_bar_fill_hp", "stem": "bar_fill_hp", "desc": "Isi bar HP."},
	]
	for bar in bars:
		slots.append(_ui_slot(bar["key"], "ui", bar["stem"], Vector2(120.0, 12.0), 2, bar["desc"], "Nine-slice 4 px.", bar["stem"], nine_bar))

	var icons := [
		{"key": &"ui_icon_hunger", "stem": "hunger", "desc": "Ikon Hunger."},
		{"key": &"ui_icon_thirst", "stem": "thirst", "desc": "Ikon Thirst."},
		{"key": &"ui_icon_fatigue", "stem": "fatigue", "desc": "Ikon Fatigue."},
		{"key": &"ui_icon_hp", "stem": "hp", "desc": "Ikon HP."},
	]
	for icon in icons:
		slots.append(_ui_slot(icon["key"], "ui/icons", icon["stem"], Vector2(16.0, 16.0), 2, icon["desc"], "Ditampilkan hanya bila art ada.", icon["stem"]))

	slots.append(_ui_slot(&"ui_logo", "ui", "logo", Vector2(480.0, 160.0), 2, "Logo di menu utama.", "", "logo"))
	slots.append(_ui_slot(&"ui_bg_main_menu", "ui", "bg_main_menu", Vector2(1280.0, 720.0), 2, "Latar menu utama.", "Ditampilkan hanya bila ada.", "bg_main_menu"))
	slots.append(_ui_slot(&"ui_bg_death", "ui", "bg_death", Vector2(1280.0, 720.0), 3, "Latar layar mati.", "", "bg_death"))
	slots.append(_ui_slot(&"ui_bg_game_over", "ui", "bg_game_over", Vector2(1280.0, 720.0), 3, "Latar game over.", "", "bg_game_over"))
	slots.append(_ui_slot(&"ui_bg_victory", "ui", "bg_victory", Vector2(1280.0, 720.0), 3, "Latar kemenangan.", "", "bg_victory"))
	slots.append(_ui_slot(&"ui_vignette_low_hp", "ui", "vignette_low_hp", Vector2(1280.0, 720.0), 3, "Vignette saat HP rendah.", "Overlay layar penuh, opsional.", "vignette_low_hp"))
	return slots


# --- Builder ----------------------------------------------------------------

func _slot(key: StringName, category: StringName, folder: String, states: Array, opts: Dictionary) -> AssetSlotDefinition:
	var slot := AssetSlotDefinition.new()
	slot.key = key
	slot.category = category
	slot.folder = folder
	slot.states = PackedStringArray(states)
	slot.directions = opts.get("dirs", DIRS1)
	slot.display_size = opts.get("size", Vector2(32.0, 32.0))
	slot.pivot = opts.get("pivot", CENTER)
	slot.offset = opts.get("offset", Vector2.ZERO)
	slot.loop_states = PackedStringArray(opts.get("loop", []))
	slot.fps = opts.get("fps", {})
	slot.tiled = opts.get("tiled", false)
	slot.tile_size = opts.get("tile", Vector2.ZERO)
	slot.priority = opts.get("priority", 3)
	slot.recommended_px = opts.get("recommended", Vector2i.ZERO)
	slot.optional = opts.get("optional", false)
	slot.used_by = opts.get("used_by", "")
	slot.description_id = opts.get("description", "")
	slot.notes = opts.get("notes", "")
	slot.file_stem = opts.get("stem", "")
	slot.nine_slice = opts.get("nine_slice", Vector4.ZERO)
	return slot


func _ui_slot(key: StringName, folder: String, _stem: String, size: Vector2, priority: int, description: String, notes: String, file_stem: String, nine_slice: Vector4 = Vector4.ZERO) -> AssetSlotDefinition:
	return _slot(key, &"ui", folder, ["default"], {
		"size": size,
		"priority": priority,
		"stem": file_stem,
		"description": description,
		"notes": notes,
		"used_by": "src/ui/ui_skin.gd (UiSkin)",
		"nine_slice": nine_slice,
	})
