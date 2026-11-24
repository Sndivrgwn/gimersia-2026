@tool
class_name WorldZoneType
extends RefCounted

## Enum zona yang aman dipakai skrip @tool (editor). Urutan dan nilai HARUS sama
## persis dengan IslandZones.Zone; tes menjaga keduanya tidak menyimpang.
## Isi kelas ini murni: tanpa autoload, tanpa akses scene.

enum Zone { CAMP, SOUTH_BEACH, EAST_BEACH, WEST_CLIFFS, RIVER, FOREST, OUTSIDE }


## Nama tampilan Indonesia untuk label editor/HUD.
static func label_id(zone: int) -> String:
	match zone:
		Zone.CAMP:
			return "Camp"
		Zone.SOUTH_BEACH:
			return "Pantai Selatan"
		Zone.EAST_BEACH:
			return "Pantai Timur"
		Zone.WEST_CLIFFS:
			return "Tebing Barat"
		Zone.RIVER:
			return "Sungai"
		Zone.FOREST:
			return "Hutan"
		_:
			return "Luar Pulau"


## Warna dasar zona (alpha diatur pemanggil: 0.35 area, 0.15 outline pulau).
static func color(zone: int) -> Color:
	match zone:
		Zone.CAMP:
			return Color(0.35, 0.4, 0.25)
		Zone.SOUTH_BEACH:
			return Color(0.78, 0.72, 0.5)
		Zone.EAST_BEACH:
			return Color(0.76, 0.7, 0.48)
		Zone.WEST_CLIFFS:
			return Color(0.4, 0.4, 0.45)
		Zone.RIVER:
			return Color(0.25, 0.45, 0.6)
		Zone.FOREST:
			return Color(0.22, 0.32, 0.2)
		_:
			return Color(0.5, 0.5, 0.5)


## Zona air/tepi tidak boleh dibangun; sisanya boleh (aturan per-area menimpa).
static func default_buildable(zone: int) -> bool:
	return zone != Zone.RIVER and zone != Zone.OUTSIDE
