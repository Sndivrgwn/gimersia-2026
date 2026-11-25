class_name InventoryUiSkin
extends RefCounted

## Pembuat StyleBox dari aset UI di res://assets/textures/ui/.
##
## Semua tekstur dimuat lewat load() dengan pengecekan ResourceLoader.exists(),
## jadi bila sebuah file hilang fungsi mengembalikan null dan pemanggil jatuh ke
## theme biasa (tidak crash). Warna chip diambil dari 01_palette.

const ROOT := "res://assets/textures/ui/"
const PANEL_CREAM := ROOT + "02_panel/panel_cream_stitched.png"
const PANEL_WALNUT := ROOT + "02_panel/panel_walnut_stitched.png"
const BUTTON_DIR := ROOT + "03_button/"

## Lebar sudut 9-slice untuk panel besar (radius sudut + jahitan ~ 34 px).
const PANEL_MARGIN := Vector2(34, 34)
## Warna dasar panel gelap (palette_espresso_panel). Tekstur walnut dikalikan
## warna ini supaya jadi espresso seperti di desain.
const COLOR_ESPRESSO := Color8(51, 34, 25)
const COLOR_WALNUT := Color8(129, 91, 70)
const COLOR_HONEY := Color8(235, 194, 115)

const SLOT_NORMAL := ROOT + "05_slot/slot_item.png"
const SLOT_SELECTED := ROOT + "05_slot/slot_item_selected.png"
## Catatan: di aset, nama file tab terbalik dari tampilannya. tab_normal.png
## berwarna walnut (dipakai sebagai tab TERPILIH di desain), sedangkan
## tab_active.png berwarna krem (dipakai sebagai tab TIDAK terpilih).
const TAB_SELECTED := ROOT + "04_tab/tab_normal.png"
const TAB_UNSELECTED := ROOT + "04_tab/tab_active.png"

const COLOR_INK := Color8(62, 39, 26)
const COLOR_CREAM := Color8(247, 241, 229)
const COLOR_SAGE := Color8(163, 201, 133)
const COLOR_CORAL := Color8(229, 138, 115)

const BUTTON_STATES: Array[StringName] = [&"normal", &"hover", &"pressed", &"disabled"]


static func load_texture(path: String) -> Texture2D:
	if not ResourceLoader.exists(path):
		push_warning("UiSkin: tekstur tidak ditemukan: %s" % path)
		return null
	return load(path) as Texture2D


## 9-slice dari sebuah tekstur. `margin` = lebar sudut (px tekstur),
## `content` = padding isi (px layar).
## `tile` = sisi/tengah diulang (TILE_FIT) alih-alih diregangkan, supaya garis
## jahitan tidak memanjang pada panel besar.
static func texture_box(
	path: String,
	margin: Vector2,
	content: Vector2,
	region: Rect2 = Rect2(),
	tile: bool = false
) -> StyleBoxTexture:
	var texture := load_texture(path)
	if texture == null:
		return null
	var box := StyleBoxTexture.new()
	box.texture = texture
	if region.has_area():
		box.region_rect = region
	box.texture_margin_left = margin.x
	box.texture_margin_right = margin.x
	box.texture_margin_top = margin.y
	box.texture_margin_bottom = margin.y
	box.content_margin_left = content.x
	box.content_margin_right = content.x
	box.content_margin_top = content.y
	box.content_margin_bottom = content.y
	if tile:
		box.axis_stretch_horizontal = StyleBoxTexture.AXIS_STRETCH_MODE_TILE_FIT
		box.axis_stretch_vertical = StyleBoxTexture.AXIS_STRETCH_MODE_TILE_FIT
	return box


## Kartu resep (baris di tab Crafting).
static func recipe_card() -> StyleBoxTexture:
	return texture_box(PANEL_CREAM, PANEL_MARGIN, Vector2(28, 14), Rect2(), true)


## Bingkai luar panel tas (krem berjahit).
static func frame_panel() -> StyleBoxTexture:
	return texture_box(PANEL_CREAM, PANEL_MARGIN, Vector2(0, 0), Rect2(), true)


## Panel gelap tempat slot/resep. `top_gap` = jarak kosong antara tab dan panel:
## sisi atas yang tergambar digeser turun, isi diberi padding yang sama.
static func dark_panel(top_gap: float = 0.0) -> StyleBoxTexture:
	var box := texture_box(PANEL_WALNUT, PANEL_MARGIN, Vector2(28, 22), Rect2(), true)
	if box == null:
		return null
	box.modulate_color = Color(
		COLOR_ESPRESSO.r / COLOR_WALNUT.r, COLOR_ESPRESSO.g / COLOR_WALNUT.g, COLOR_ESPRESSO.b / COLOR_WALNUT.b
	)
	box.expand_margin_top = -top_gap
	box.content_margin_top += top_gap
	return box


## Pasang 4 state tombol dari 03_button/button_<kind>_<state>.png.
## kind: "primary", "secondary", "danger", "back". Mengembalikan false bila
## tekstur tidak ada (tombol tetap memakai theme).
static func style_button(button: Button, kind: StringName = &"primary") -> bool:
	var normal := texture_box("%sbutton_%s_normal.png" % [BUTTON_DIR, kind], Vector2(22, 22), Vector2(12, 6))
	if normal == null:
		return false
	for state in BUTTON_STATES:
		var box := normal
		if state != &"normal":
			box = texture_box(
				"%sbutton_%s_%s.png" % [BUTTON_DIR, kind, state], Vector2(22, 22), Vector2(12, 6)
			)
			if box == null:
				box = normal
		button.add_theme_stylebox_override(state, box)
	button.add_theme_stylebox_override(&"focus", StyleBoxEmpty.new())

	var text_color := COLOR_CREAM if kind != &"secondary" and kind != &"back" else COLOR_INK
	for color_name in [&"font_color", &"font_hover_color", &"font_pressed_color", &"font_disabled_color"]:
		button.add_theme_color_override(color_name, text_color)
	return true


## Lencana jumlah bahan: hijau (cukup) atau merah (kurang), garis tinta.
static func chip_box(good: bool) -> StyleBoxFlat:
	var box := StyleBoxFlat.new()
	box.bg_color = COLOR_SAGE if good else COLOR_CORAL
	box.border_color = COLOR_INK
	box.set_border_width_all(2)
	box.set_corner_radius_all(9)
	box.content_margin_left = 8.0
	box.content_margin_right = 8.0
	box.content_margin_top = 3.0
	box.content_margin_bottom = 3.0
	box.shadow_color = Color(COLOR_INK, 0.25)
	box.shadow_size = 2
	box.shadow_offset = Vector2(0, 2)
	return box


## Kotak slot tas; `selected` = bingkai kuning madu (dipakai saat hover).
static func slot_box(selected: bool = false) -> StyleBoxTexture:
	return texture_box(SLOT_SELECTED if selected else SLOT_NORMAL, Vector2(30, 30), Vector2(10, 8))


## Pasang gaya tab (walnut = terpilih, krem = lainnya) ke TabContainer.
## Harus di TabContainer, bukan di TabBar internalnya: TabContainer menimpa
## override TabBar dengan item theme miliknya sendiri.
static func style_tabs(tabs: TabContainer) -> bool:
	var selected := texture_box(TAB_SELECTED, Vector2(20, 20), Vector2(18, 10))
	var unselected := texture_box(TAB_UNSELECTED, Vector2(20, 20), Vector2(18, 10))
	if selected == null or unselected == null:
		return false
	tabs.add_theme_stylebox_override(&"tab_selected", selected)
	tabs.add_theme_stylebox_override(&"tab_unselected", unselected)
	tabs.add_theme_stylebox_override(&"tab_hovered", unselected)
	tabs.add_theme_stylebox_override(&"tab_disabled", unselected)
	tabs.add_theme_stylebox_override(&"tab_focus", StyleBoxEmpty.new())
	tabs.add_theme_color_override(&"font_selected_color", COLOR_CREAM)
	tabs.add_theme_color_override(&"font_unselected_color", COLOR_INK)
	tabs.add_theme_color_override(&"font_hovered_color", COLOR_INK)
	tabs.add_theme_color_override(&"font_disabled_color", COLOR_INK)
	return true
