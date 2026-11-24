class_name RunSummary
extends RefCounted

## Fase 5: ringkasan satu run untuk layar Game Over / Victory.
##
## Murni (tanpa SceneTree) supaya mudah dites: angka datang dari
## `DailyRunStats.get_totals()`, hari berjalan dari DayNightManager bila ada.
## Read-only terhadap gameplay.

const TITLE := "Ringkasan Perjalanan"
const STATS_NAME := "DailyRunStats"


## Empat baris ringkasan. `current_day` (opsional) ikut dihitung supaya
## kematian di tengah hari tidak tampil lebih kecil dari hari yang sudah lewat.
static func from_totals(totals: Dictionary, current_day: int = 0) -> String:
	var days := maxi(int(totals.get("days", 0)), 0)
	days = maxi(days, current_day)
	var lines := PackedStringArray()
	lines.append("Hari bertahan: %d" % days)
	lines.append("Sumber daya: %d" % maxi(int(totals.get("resources", 0)), 0))
	lines.append("Babi dibunuh: %d · Hewan lain: %d" % [
		maxi(int(totals.get("kills_boar", 0)), 0),
		maxi(int(totals.get("kills_other", 0)), 0),
	])
	lines.append("Kerusakan base: %d · Struktur hancur: %d" % [
		int(round(maxf(float(totals.get("base_damage", 0.0)), 0.0))),
		maxi(int(totals.get("structures_destroyed", 0)), 0),
	])
	return "\n".join(lines)


## Teks siap tempel untuk layar akhir: kosong bila DailyRunStats tidak ada.
static func block_for(context: Node) -> String:
	var stats := find_stats(context)
	if stats == null:
		return ""
	return "\n\n%s\n%s" % [TITLE, from_totals(stats.get_totals(), current_day(context))]


## Cari DailyRunStats lewat grup, lalu anak scene (layar bisa beda cabang tree).
static func find_stats(context: Node) -> DailyRunStats:
	if context == null:
		return null
	var tree := context.get_tree()
	if tree == null:
		return null
	var in_group := tree.get_first_node_in_group(DailyRunStats.GROUP)
	if in_group is DailyRunStats:
		return in_group as DailyRunStats
	if tree.current_scene != null:
		var node := tree.current_scene.find_child(STATS_NAME, true, false)
		if node is DailyRunStats:
			return node as DailyRunStats
	return null


static func current_day(context: Node) -> int:
	if context == null:
		return 0
	var clock := context.get_node_or_null("/root/DayNightManager")
	if clock == null or not clock.has_method(&"get_current_day"):
		return 0
	return int(clock.get_current_day())
