class_name InputGuideGenerator
extends RefCounted

## Mission 9: panduan Input Map yang bisa dibaca manusia.
##
## Sumber kebenaran tombol = InputMap (diisi `InputSetup.ensure_actions()`),
## jadi menambah action di kode dan lupa menulis tujuannya akan menggagalkan
## `missing_purposes()` dan tes dokumentasi. Tujuan tiap tombol ditulis di
## PURPOSES di bawah — itulah bagian yang diedit manusia.

const BEGIN := "<!-- BEGIN GENERATED: PANDUAN_INPUT -->"
const END := "<!-- END GENERATED -->"

## action -> [bagian, fungsi]. Bagian menentukan grup tabel.
const PURPOSES: Dictionary = {
	# --- Bermain ---
	"move_up": ["main", "Jalan ke atas (W / panah atas)."],
	"move_down": ["main", "Jalan ke bawah (S / panah bawah)."],
	"move_left": ["main", "Jalan ke kiri (A / panah kiri)."],
	"move_right": ["main", "Jalan ke kanan (D / panah kanan)."],
	"sprint": ["main", "Lari selama fatigue masih ada; dikunci saat Fatigue rendah, Hunger <= 30, jongkok, atau di air."],
	"sneak": ["main", "Tahan untuk jongkok: gerak 0.55x, deteksi fauna 0.6x, sprint terkunci. Label JONGKOK muncul di atas pemain."],
	"interact": ["main", "Tahan untuk memanen, membangun, membuka koper, minum di sungai, menyalakan api (QTE), dan interaksi lain."],
	"repair": ["main", "Tahan untuk memperbaiki struktur camp yang rusak."],
	"attack_space": ["main", "Serang ke arah hadap (gamepad: X)."],
	"attack_click": ["main", "Serang ke arah kursor mouse."],
	"inventory_toggle": ["main", "Buka/tutup panel tas: Tab 1 (Tas + alat + tas), Tab 2 (Crafting), Tab 3 (Profisiensi)."],
	"hotbar_1": ["main", "Pilih slot hotbar 1 (item dibawa, tidak langsung dipakai)."],
	"hotbar_2": ["main", "Pilih slot hotbar 2 (item dibawa, tidak langsung dipakai)."],
	"hotbar_3": ["main", "Pilih slot hotbar 3 (item dibawa, tidak langsung dipakai)."],
	"hotbar_4": ["main", "Pilih slot hotbar 4 (item dibawa, tidak langsung dipakai)."],
	"hotbar_5": ["main", "Pilih slot hotbar 5 (item dibawa, tidak langsung dipakai)."],
	"hotbar_next": ["main", "Pilih slot hotbar berikutnya (scroll bawah)."],
	"hotbar_prev": ["main", "Pilih slot hotbar sebelumnya (scroll atas)."],
	"use_held": ["main", "Pakai item di slot terpilih (klik kanan / F); hanya consumable."],
	"base_place": ["main", "Tentukan lokasi base saat fase penentuan base (sekali)."],
	"pause_toggle": ["main", "Buka/tutup menu Jeda (Lanjutkan, Pengaturan, Bantuan, Menu Utama)."],
	"help_toggle": ["main", "Buka/tutup panel bantuan (daftar kontrol dan alur main)."],
	"ui_cancel": ["main", "Tutup panel yang sedang terbuka (tas, peti, bantuan, jeda)."],
	# --- Debug pulau ---
	"debug_island_toggle": ["debug_island", "Aktifkan/matikan mode debug pulau (menampilkan status debug)."],
	"debug_island_zone": ["debug_island", "Teleport ke zona berikutnya (pantai, hutan, sungai, tebing)."],
	"debug_island_morning": ["debug_island", "Lompat ke pagi hari berikutnya."],
	"debug_island_kit": ["debug_island", "Beri kit bahan crafting (kayu, batu, fiber, bambu, tulang, kulit, daging, beri)."],
	"debug_island_boar": ["debug_island", "Spawn babi hutan di dekat pemain."],
	"debug_island_deer": ["debug_island", "Spawn rusa di dekat pemain."],
	"debug_island_night": ["debug_island", "Lompat ke malam (uji raid dan Jaga Malam)."],
	"debug_island_heal": ["debug_island", "Pulihkan HP pemain penuh."],
	"debug_island_weapon": ["debug_island", "Siklus senjata di tangan (tangan kosong, tombak, kapak, ...)."],
	"debug_island_kill": ["debug_island", "Matikan pemain untuk menguji layar kematian dan perlindungan respawn."],
	"debug_island_rescue": ["debug_island", "Lompat ke fajar Hari 7 (urutan rescue/endgame)."],
	"debug_fauna_labels": ["debug_island", "Tampilkan label temperament/state di atas setiap fauna."],
	"debug_raid": ["debug_island", "Picu satu raid sekarang tanpa menunggu jadwal malam."],
	"debug_reload_assets": ["debug_island", "Muat ulang semua art aset tanpa restart game."],
	"debug_asset_boxes": ["debug_island", "Tampilkan kotak/garis bantu untuk setiap slot aset."],
	# --- Debug practice (sandbox) ---
	"debug_str_up": ["debug_practice", "Naikkan Strength 1 level (sandbox)."],
	"debug_str_down": ["debug_practice", "Turunkan Strength 1 level (sandbox)."],
	"debug_spd_up": ["debug_practice", "Naikkan Speed 1 level (sandbox)."],
	"debug_spd_down": ["debug_practice", "Turunkan Speed 1 level (sandbox)."],
	"debug_mas_up": ["debug_practice", "Naikkan Mastery 1 level (sandbox)."],
	"debug_mas_down": ["debug_practice", "Turunkan Mastery 1 level (sandbox)."],
	"debug_agi_up": ["debug_practice", "Naikkan Agility 1 level (sandbox)."],
	"debug_agi_down": ["debug_practice", "Turunkan Agility 1 level (sandbox)."],
	"debug_cycle_hunger": ["debug_practice", "Putar nilai Hunger (uji tier NORMAL/LOW/ZERO)."],
	"debug_cycle_thirst": ["debug_practice", "Putar nilai Thirst (uji tier NORMAL/LOW/ZERO)."],
	"debug_cycle_fatigue": ["debug_practice", "Putar nilai Fatigue (uji kunci sprint)."],
	"debug_eat": ["debug_practice", "Makan item uji untuk memulihkan Hunger."],
	"debug_heal": ["debug_practice", "Pulihkan HP penuh (sandbox)."],
	"debug_refill_needs": ["debug_practice", "Isi ulang Hunger/Thirst/Fatigue penuh."],
	"debug_reset": ["debug_practice", "Reset sandbox ke kondisi awal."],
	"debug_set_hp": ["debug_practice", "Set HP ke nilai uji berikutnya."],
	"debug_needs_toggle": ["debug_practice", "Tampilkan/sembunyikan HUD debug kebutuhan."],
	"debug_toggle_sprint": ["debug_practice", "Paksa mode sprint untuk uji drain fatigue."],
	"debug_toggle_zirah": ["debug_practice", "Pasang/lepas zirah uji (damage reduction)."],
}

const SECTION_TITLES: Dictionary = {
	"main": "Aksi permainan",
	"debug_island": "Debug pulau (`island.tscn`)",
	"debug_practice": "Debug sandbox (`practice1.tscn`)",
}

const SECTION_NOTES: Dictionary = {
	"main": "Tombol yang dipakai pemain sehari-hari. Action ini didaftarkan `InputSetup.ensure_actions()` dan berlaku di semua scene.",
	"debug_island": "Hanya berguna di `island.tscn`; dipasang `GatherDebug` dan diabaikan di scene lain.",
	"debug_practice": "Hanya untuk sandbox `practice1.tscn` (didaftarkan `project.godot`), tidak ada di build pemain.",
}


## Semua action yang didokumentasikan, urut sesuai tabel.
func actions() -> Array[String]:
	InputSetup.ensure_actions()
	var result: Array[String] = []
	for action in PURPOSES.keys():
		result.append(String(action))
	result.sort()
	return result


## Buat teks panduan lengkap.
func build_input_guide() -> String:
	var text := _intro()
	var grouped := {"main": [], "debug_island": [], "debug_practice": []}
	InputSetup.ensure_actions()
	for action in actions():
		var entry: Array = PURPOSES[action]
		var section := String(entry[0])
		if not grouped.has(section):
			section = "main"
		(grouped[section] as Array).append(action)

	text += "\n" + BEGIN + "\n"
	for section in ["main", "debug_island", "debug_practice"]:
		text += "\n## %s\n\n%s\n\n" % [SECTION_TITLES[section], SECTION_NOTES[section]]
		text += "| Action | Tombol | Fungsi |\n| --- | --- | --- |\n"
		for action in grouped[section]:
			var entry: Array = PURPOSES[action]
			text += "| `%s` | %s | %s |\n" % [action, keys_text(String(action)), entry[1]]
	text += "\n" + END + "\n"
	return _lf(text)


func _intro() -> String:
	return """# Panduan Input (Input Map)

Dokumen ini menjawab satu pertanyaan: **tombol ini fungsinya apa?**

## Menu, tab, dan panel

| Yang dibuka | Tombol | Isi |
| --- | --- | --- |
| Panel tas | Tab atau I (gamepad Y) | Tab 1 **Tas** (12 slot + senjata/alat/armor), Tab 2 **Crafting** (resep tersedia dan terkunci), Tab 3 **Profisiensi** (level, XP, dan passive Kekuatan/Kecepatan/Penguasaan/Kelincahan) |
| Menu Jeda | P (gamepad Start) | Lanjutkan, Pengaturan, Bantuan, Menu Utama |
| Panel bantuan | H | Ringkasan kontrol di layar (pemain, panel/menu, debug pulau) |
| Tutup panel | Esc | Menutup tas, peti, bantuan, dan menu Jeda |
| Debug pulau | F2 | F2 mode debug on/off; F3 zona, F4 pagi, F5 kit bahan, F6 babi, F7 rusa, F8 malam, F9 heal, F10 siklus senjata, F11 mati, F12 rescue |

## Cara membaca tabel di bawah

- Tabel di bawah DIBUAT dari Input Map yang hidup (`InputSetup.ensure_actions()`),
  jadi tombolnya tidak bisa berbeda dengan kode. Jangan edit bagian di antara
  penanda GENERATED: ubah `src/utils/input_setup.gd` (tombol) atau
  `PURPOSES` di `src/core/docs/input_guide_generator.gd` (fungsi), lalu jalankan
  `GODOT --headless --path . -s tools/generate_input_guide.gd`.
- Tombol memakai `physical_keycode`, jadi posisi tombol sama di keyboard
  QWERTY/AZERTY.
- Aksi `ui_cancel` adalah Esc; dipakai untuk menutup panel yang sedang terbuka.
- Kelompok debug hanya berguna saat menguji; pemain biasa tidak perlu tombolnya.
"""


## Tombol yang terdaftar di InputMap untuk satu action, mis. "A, Left".
func keys_text(action: String) -> String:
	if not InputMap.has_action(action):
		return "— (belum terdaftar)"
	var parts := PackedStringArray()
	for event in InputMap.action_get_events(action):
		var label := _event_text(event)
		if not label.is_empty() and not parts.has(label):
			parts.append(label)
	if parts.is_empty():
		return "— (belum ada tombol)"
	return ", ".join(parts)


func _event_text(event: InputEvent) -> String:
	var key_event := event as InputEventKey
	if key_event != null:
		return OS.get_keycode_string(key_event.physical_keycode)
	var mouse_event := event as InputEventMouseButton
	if mouse_event != null:
		return "Mouse %d" % int(mouse_event.button_index)
	var joy_button := event as InputEventJoypadButton
	if joy_button != null:
		return "Gamepad %s" % _joy_button_name(joy_button.button_index)
	var joy_motion := event as InputEventJoypadMotion
	if joy_motion != null:
		var stick := "kiri" if joy_motion.axis <= JOY_AXIS_LEFT_Y else "kanan"
		if joy_motion.axis == JOY_AXIS_LEFT_X or joy_motion.axis == JOY_AXIS_RIGHT_X:
			return "Stik %s (kiri/kanan)" % stick
		return "Stik %s (atas/bawah)" % stick
	return ""


func _joy_button_name(button: JoyButton) -> String:
	match button:
		JOY_BUTTON_A:
			return "A"
		JOY_BUTTON_B:
			return "B"
		JOY_BUTTON_X:
			return "X"
		JOY_BUTTON_Y:
			return "Y"
		JOY_BUTTON_LEFT_STICK:
			return "klik stik kiri"
		JOY_BUTTON_RIGHT_SHOULDER:
			return "RB"
		JOY_BUTTON_START:
			return "Start"
		JOY_BUTTON_DPAD_UP:
			return "D-pad atas"
		JOY_BUTTON_DPAD_DOWN:
			return "D-pad bawah"
		JOY_BUTTON_DPAD_LEFT:
			return "D-pad kiri"
		JOY_BUTTON_DPAD_RIGHT:
			return "D-pad kanan"
		_:
			return "tombol %d" % int(button)


## Action yang ada di InputMap tetapi belum punya tujuan di PURPOSES.
func missing_purposes() -> Array[String]:
	InputSetup.ensure_actions()
	var missing: Array[String] = []
	for action in InputMap.get_actions():
		var name := String(action)
		if name.begins_with("ui_"):
			continue
		if not PURPOSES.has(name):
			missing.append(name)
	missing.sort()
	return missing


static func write_file(path: String, text: String) -> bool:
	DirAccess.make_dir_recursive_absolute(path.get_base_dir())
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		return false
	file.store_string(text.replace("\r\n", "\n").replace("\n", "\r\n"))
	file.close()
	return true


func _lf(text: String) -> String:
	return text.replace("\r\n", "\n").replace("\r", "\n")
