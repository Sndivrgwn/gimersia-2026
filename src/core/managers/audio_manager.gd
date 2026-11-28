extends Node

## Autoload pengelola playback audio, bus mixer, ducking, dan crossfade ambience.
##
## Membaca kontrak cue dari `audio_registry.tres` (AudioRegistry) dan memetakan
## setiap key ke file `.ogg` sesuai pola `docs/editable/AUDIO_GUIDE.md`.
## Aman di mode headless/tes: cue yang belum punya file diabaikan tanpa error.

const REGISTRY_PATH := "res://src/data/audio/audio_registry.tres"
const BUS_MASTER := &"Master"
const BUS_MUSIC := &"Music"
const BUS_SFX := &"SFX"
const BUS_AMBIENCE := &"Ambience"
const BUS_UI := &"UI"

const SFX_POOL_SIZE := 16
const SPATIAL_POOL_SIZE := 16
const MAX_VARIANTS := 8

## Kecepatan transisi linear volume ambience (1.0 / 1.8 s ~= 1.8 detik crossfade penuh).
const AMBIENCE_FADE_SPEED := 0.56
const SILENT_DB := -60.0
const PAUSE_MUSIC_DUCK_DB := -6.0
const PAUSE_AMBIENCE_DUCK_DB := -4.0

## Jalur ambience tambahan untuk pantai (layer ocean + wind saat di pantai).
const EXTRA_AMBIENCE_PATHS := {
	&"ambience_beach_ocean": "res://assets/audio/ambience/ambience_beach_ocean.ogg",
	&"ambience_beach_wind": "res://assets/audio/ambience/ambience_beach_wind.ogg",
}

var _registry: AudioRegistry
var _stream_cache: Dictionary = {} # StringName -> Array[AudioStream]
var _last_variant: Dictionary = {} # StringName -> int
var _throttle_until: Dictionary = {} # StringName -> float

var _sfx_pool: Array[AudioStreamPlayer] = []
var _spatial_pool: Array[AudioStreamPlayer2D] = []
var _music_player: AudioStreamPlayer
var _sting_player: AudioStreamPlayer

## Ambience layers: key -> {player: AudioStreamPlayer, current: float, target: float, base_db: float}
var _ambience_layers: Dictionary = {}
var _ambience_active: bool = false
var _current_zone: int = IslandZones.Zone.CAMP
var _current_is_night: bool = false

var _pause_ducked: bool = false
var _sting_duck_remaining: float = 0.0
var _sting_duck_db: float = -6.0
var _rng := RandomNumberGenerator.new()


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_rng.randomize()
	_ensure_buses()
	_load_registry()
	_build_pools()
	_build_music_players()
	_build_ambience_layers()
	_hook_global_ui()


func _process(delta: float) -> void:
	if delta <= 0.0:
		return
	_tick_ambience(delta)
	_tick_ducking(delta)


# --- Public Playback API ----------------------------------------------------

## True bila setidaknya satu file `.ogg` ditemukan untuk key cue ini.
func has_cue_audio(key: StringName) -> bool:
	return not _get_streams(key).is_empty()


## Putar SFX / UI non-spasial. Mengembalikan player aktif atau null bila file belum ada.
func play(key: StringName, volume_db: float = 0.0, pitch_variance: float = 0.05) -> AudioStreamPlayer:
	var stream := _pick_stream(key)
	if stream == null:
		return null
	var player := _acquire_sfx_player()
	player.stream = stream
	player.bus = _bus_for_key(key)
	player.volume_db = volume_db
	player.pitch_scale = _random_pitch(pitch_variance)
	player.play()
	return player


## Putar SFX spasial 2D di koordinat dunia.
func play_at(
	key: StringName,
	world_position: Vector2,
	volume_db: float = 0.0,
	pitch_variance: float = 0.06,
	max_distance: float = 900.0
) -> AudioStreamPlayer2D:
	var stream := _pick_stream(key)
	if stream == null:
		return null
	var player := _acquire_spatial_player()
	player.stream = stream
	player.bus = _bus_for_key(key)
	player.global_position = world_position
	player.max_distance = max_distance
	player.volume_db = volume_db
	player.pitch_scale = _random_pitch(pitch_variance)
	player.play()
	return player


## Putar bunyi UI pada bus UI dengan variasi pitch sangat halus.
func play_ui(key: StringName, volume_db: float = 0.0) -> AudioStreamPlayer:
	return play(key, volume_db, 0.02)


## Putar cue dengan batas jarak waktu minimum agar tidak spam per frame.
func play_throttled(
	key: StringName,
	min_interval: float,
	volume_db: float = 0.0,
	pitch_variance: float = 0.04
) -> AudioStreamPlayer:
	var now := Time.get_ticks_msec() / 1000.0
	var until := float(_throttle_until.get(key, 0.0))
	if now < until:
		return null
	_throttle_until[key] = now + maxf(min_interval, 0.01)
	return play(key, volume_db, pitch_variance)


## Putar sting satu-tembak di bus Music (mis. layar tewas, game over, victory).
func play_sting(key: StringName, duck_music_db: float = -6.0, duck_seconds: float = 2.0) -> void:
	var stream := _pick_stream(key)
	if stream == null or _sting_player == null:
		return
	_sting_player.stop()
	_sting_player.stream = stream
	_sting_player.bus = BUS_MUSIC
	_sting_player.volume_db = 0.0
	_sting_player.play()
	_sting_duck_db = duck_music_db
	_sting_duck_remaining = maxf(duck_seconds, 0.1)


## Putar musik loop di bus Music (siap pakai begitu aset musik ditambahkan).
func play_music(key: StringName, volume_db: float = 0.0) -> void:
	var stream := _pick_stream(key, true)
	if stream == null or _music_player == null:
		return
	if _music_player.playing and _music_player.stream == stream:
		return
	_music_player.stream = stream
	_music_player.bus = BUS_MUSIC
	_music_player.volume_db = volume_db
	_music_player.play()


func stop_music() -> void:
	if _music_player != null:
		_music_player.stop()


## Buat AudioStreamPlayer2D loop spasial untuk objek dunia (mis. Campfire).
func create_spatial_loop(
	key: StringName,
	parent: Node2D,
	max_distance: float = 520.0,
	volume_db: float = -4.0
) -> AudioStreamPlayer2D:
	var stream := _pick_stream(key, true)
	if stream == null or parent == null:
		return null
	var player := AudioStreamPlayer2D.new()
	player.name = "AudioLoop_%s" % String(key)
	player.stream = stream
	player.bus = _bus_for_key(key)
	player.max_distance = max_distance
	player.attenuation = 1.6
	player.volume_db = volume_db
	parent.add_child(player)
	return player


# --- Ambience & Crossfade Zona ----------------------------------------------

## Perbarui target ambience berdasarkan zona pemain dan fase siang/malam.
## Hutan -> forest (`ambience_day`); Pantai -> ocean + wind dengan crossfade halus.
func set_ambience_state(zone: int, is_night: bool, instant: bool = false) -> void:
	_ambience_active = true
	_current_zone = zone
	_current_is_night = is_night

	var targets := _compute_ambience_targets(zone, is_night)
	for key in _ambience_layers:
		var layer: Dictionary = _ambience_layers[key]
		var target := float(targets.get(key, 0.0))
		layer["target"] = target
		if instant:
			layer["current"] = target
			_apply_layer_volume(layer)


## Hentikan semua ambience (mis. saat kembali ke Menu Utama).
func stop_ambience(instant: bool = false) -> void:
	_ambience_active = false
	for key in _ambience_layers:
		var layer: Dictionary = _ambience_layers[key]
		layer["target"] = 0.0
		if instant:
			layer["current"] = 0.0
			_apply_layer_volume(layer)


## Nilai target volume linear (0..1) untuk satu layer ambience (berguna untuk tes).
func get_ambience_target(key: StringName) -> float:
	if not _ambience_layers.has(key):
		return 0.0
	return float(_ambience_layers[key]["target"])


func get_ambience_current(key: StringName) -> float:
	if not _ambience_layers.has(key):
		return 0.0
	return float(_ambience_layers[key]["current"])


## Ducking saat game dijeda.
func set_pause_duck(paused: bool) -> void:
	_pause_ducked = paused
	_apply_bus_ducking()


# --- Internal: Ambience Logic -----------------------------------------------

func _compute_ambience_targets(zone: int, is_night: bool) -> Dictionary:
	var targets := {
		&"ambience_day": 0.0,
		&"ambience_beach_ocean": 0.0,
		&"ambience_beach_wind": 0.0,
		&"ambience_night": 0.0,
		&"river_loop": 0.0,
	}
	var is_beach := zone == IslandZones.Zone.SOUTH_BEACH or zone == IslandZones.Zone.EAST_BEACH
	var is_river := zone == IslandZones.Zone.RIVER
	var is_cliffs := zone == IslandZones.Zone.WEST_CLIFFS

	if is_night:
		targets[&"ambience_night"] = 1.0
		if is_beach:
			targets[&"ambience_beach_ocean"] = 0.45
			targets[&"ambience_beach_wind"] = 0.35
		elif is_river:
			targets[&"river_loop"] = 0.55
		elif is_cliffs:
			targets[&"ambience_beach_wind"] = 0.30
		return targets

	if is_beach:
		targets[&"ambience_beach_ocean"] = 0.85
		targets[&"ambience_beach_wind"] = 0.55
	elif is_river:
		targets[&"river_loop"] = 0.75
		targets[&"ambience_day"] = 0.45
	elif is_cliffs:
		targets[&"ambience_beach_wind"] = 0.65
		targets[&"ambience_day"] = 0.35
		targets[&"ambience_beach_ocean"] = 0.15
	else:
		# FOREST, CAMP, atau OUTSIDE -> suasana hutan siang
		targets[&"ambience_day"] = 0.85
	return targets


func _tick_ambience(delta: float) -> void:
	for key in _ambience_layers:
		var layer: Dictionary = _ambience_layers[key]
		var current := float(layer["current"])
		var target := float(layer["target"])
		if is_equal_approx(current, target):
			if target <= 0.001:
				var p: AudioStreamPlayer = layer["player"]
				if p.playing:
					p.stop()
			continue
		var next := move_toward(current, target, AMBIENCE_FADE_SPEED * delta)
		layer["current"] = next
		_apply_layer_volume(layer)


func _apply_layer_volume(layer: Dictionary) -> void:
	var player: AudioStreamPlayer = layer["player"]
	if player == null or player.stream == null:
		return
	var level := clampf(float(layer["current"]), 0.0, 1.0)
	if level <= 0.001:
		player.volume_db = SILENT_DB
		if player.playing:
			player.stop()
		return
	var base_db := float(layer["base_db"])
	player.volume_db = linear_to_db(level) + base_db
	if not player.playing:
		player.play()


# --- Internal: Ducking & Buses ----------------------------------------------

func _tick_ducking(delta: float) -> void:
	if _sting_duck_remaining <= 0.0:
		return
	_sting_duck_remaining = maxf(_sting_duck_remaining - delta, 0.0)
	_apply_bus_ducking()


func _apply_bus_ducking() -> void:
	var music_db := 0.0
	if _pause_ducked:
		music_db += PAUSE_MUSIC_DUCK_DB
	if _sting_duck_remaining > 0.0:
		music_db = minf(music_db, _sting_duck_db)
	var music_idx := AudioServer.get_bus_index(BUS_MUSIC)
	if music_idx >= 0:
		AudioServer.set_bus_volume_db(music_idx, music_db)

	var amb_db := PAUSE_AMBIENCE_DUCK_DB if _pause_ducked else 0.0
	var amb_idx := AudioServer.get_bus_index(BUS_AMBIENCE)
	if amb_idx >= 0:
		AudioServer.set_bus_volume_db(amb_idx, amb_db)


func _ensure_buses() -> void:
	for bus_name in [BUS_MUSIC, BUS_SFX, BUS_AMBIENCE, BUS_UI]:
		if AudioServer.get_bus_index(bus_name) != -1:
			continue
		var idx := AudioServer.bus_count
		AudioServer.add_bus(idx)
		AudioServer.set_bus_name(idx, bus_name)
		AudioServer.set_bus_send(idx, BUS_MASTER)
		if bus_name == BUS_UI:
			AudioServer.set_bus_volume_db(idx, -3.0)


# --- Internal: Registry & Stream Loading ------------------------------------

func _load_registry() -> void:
	if ResourceLoader.exists(REGISTRY_PATH):
		_registry = load(REGISTRY_PATH) as AudioRegistry


func _bus_for_key(key: StringName) -> StringName:
	if _registry != null:
		var cue := _registry.get_cue(key)
		if cue != null:
			return StringName(cue.bus_name())
	if EXTRA_AMBIENCE_PATHS.has(key):
		return BUS_AMBIENCE
	var text := String(key)
	if text.begins_with("ui_"):
		return BUS_UI
	if text.begins_with("music_"):
		return BUS_MUSIC
	if text.begins_with("ambience_") or text == "river_loop":
		return BUS_AMBIENCE
	return BUS_SFX


func _folder_for_key(key: StringName) -> String:
	if _registry != null:
		var cue := _registry.get_cue(key)
		if cue != null:
			return "res://assets/audio/%s/" % cue.category_key()
	var text := String(key)
	if text.begins_with("ui_"):
		return "res://assets/audio/ui/"
	if text.begins_with("music_"):
		return "res://assets/audio/music/"
	if text.begins_with("ambience_") or text == "river_loop":
		return "res://assets/audio/ambience/"
	return "res://assets/audio/sfx/"


func _get_streams(key: StringName) -> Array[AudioStream]:
	if _stream_cache.has(key):
		return _stream_cache[key]

	var found: Array[AudioStream] = []
	if EXTRA_AMBIENCE_PATHS.has(key):
		var extra_path: String = EXTRA_AMBIENCE_PATHS[key]
		var extra_stream := _load_stream(extra_path)
		if extra_stream != null:
			found.append(extra_stream)
	else:
		var folder := _folder_for_key(key)
		var base := "%s%s" % [folder, String(key)]
		for i in range(1, MAX_VARIANTS + 1):
			var variant_path := "%s_%d.ogg" % [base, i]
			var s := _load_stream(variant_path)
			if s != null:
				found.append(s)
		if found.is_empty():
			var single := _load_stream(base + ".ogg")
			if single != null:
				found.append(single)

	_stream_cache[key] = found
	return found


func _load_stream(path: String) -> AudioStream:
	if not ResourceLoader.exists(path):
		return null
	return load(path) as AudioStream


func _pick_stream(key: StringName, want_loop: bool = false) -> AudioStream:
	var streams := _get_streams(key)
	if streams.is_empty():
		return null
	var chosen_idx := 0
	if streams.size() > 1:
		var prev := int(_last_variant.get(key, -1))
		chosen_idx = _rng.randi_range(0, streams.size() - 1)
		if chosen_idx == prev:
			chosen_idx = (chosen_idx + 1) % streams.size()
		_last_variant[key] = chosen_idx
	var stream := streams[chosen_idx]
	if want_loop and stream is AudioStreamOggVorbis:
		var dup := stream.duplicate() as AudioStreamOggVorbis
		dup.loop = true
		return dup
	return stream


func _random_pitch(variance: float) -> float:
	if variance <= 0.0:
		return 1.0
	return _rng.randf_range(1.0 - variance, 1.0 + variance)


# --- Internal: Pools & Global UI Hook ---------------------------------------

func _build_pools() -> void:
	for i in SFX_POOL_SIZE:
		var p := AudioStreamPlayer.new()
		p.name = "SfxPlayer_%d" % i
		p.bus = BUS_SFX
		add_child(p)
		_sfx_pool.append(p)
	for i in SPATIAL_POOL_SIZE:
		var p2d := AudioStreamPlayer2D.new()
		p2d.name = "SpatialPlayer_%d" % i
		p2d.bus = BUS_SFX
		p2d.attenuation = 1.4
		add_child(p2d)
		_spatial_pool.append(p2d)


func _build_music_players() -> void:
	_music_player = AudioStreamPlayer.new()
	_music_player.name = "MusicPlayer"
	_music_player.bus = BUS_MUSIC
	add_child(_music_player)

	_sting_player = AudioStreamPlayer.new()
	_sting_player.name = "StingPlayer"
	_sting_player.bus = BUS_MUSIC
	add_child(_sting_player)


func _build_ambience_layers() -> void:
	var defs := [
		{&"key": &"ambience_day", &"base_db": -6.0},
		{&"key": &"ambience_beach_ocean", &"base_db": -6.0},
		{&"key": &"ambience_beach_wind", &"base_db": -8.0},
		{&"key": &"ambience_night", &"base_db": -6.0},
		{&"key": &"river_loop", &"base_db": -6.0},
	]
	for entry in defs:
		var key: StringName = entry[&"key"]
		var p := AudioStreamPlayer.new()
		p.name = "Ambience_%s" % String(key)
		p.bus = BUS_AMBIENCE
		p.volume_db = SILENT_DB
		p.stream = _pick_stream(key, true)
		add_child(p)
		_ambience_layers[key] = {
			"player": p,
			"current": 0.0,
			"target": 0.0,
			"base_db": float(entry[&"base_db"]),
		}


func _acquire_sfx_player() -> AudioStreamPlayer:
	for p in _sfx_pool:
		if not p.playing:
			return p
	return _sfx_pool[0]


func _acquire_spatial_player() -> AudioStreamPlayer2D:
	for p in _spatial_pool:
		if not p.playing:
			return p
	return _spatial_pool[0]


## Hubungkan semua BaseButton (klik & hover) secara otomatis di seluruh scene.
func _hook_global_ui() -> void:
	var tree := get_tree()
	if tree == null:
		return
	if not tree.node_added.is_connected(_on_tree_node_added):
		tree.node_added.connect(_on_tree_node_added)
	if tree.root != null:
		_scan_buttons(tree.root)


func _scan_buttons(node: Node) -> void:
	if node is BaseButton:
		_bind_button(node as BaseButton)
	for child in node.get_children():
		_scan_buttons(child)


func _on_tree_node_added(node: Node) -> void:
	if node is BaseButton:
		_bind_button(node as BaseButton)


func _bind_button(button: BaseButton) -> void:
	if button == null or button.has_meta(&"_audio_ui_bound"):
		return
	button.set_meta(&"_audio_ui_bound", true)
	button.pressed.connect(_on_ui_button_pressed)
	button.mouse_entered.connect(_on_ui_button_hovered)


func _on_ui_button_pressed() -> void:
	play_ui(&"ui_click")


func _on_ui_button_hovered() -> void:
	play_throttled(&"ui_hover", 0.06, -9.0, 0.02)
