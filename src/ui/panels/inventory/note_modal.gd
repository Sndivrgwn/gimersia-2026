class_name NoteModal
extends Control

## Modal baca catatan bergaya panel cokelat berjahit (sama dengan ItemTooltip).
##
## Memilah isi teks menjadi:
## - Title (ExtraBold): judul utama item & heading blok huruf kapital (mis. "LOG PENERBANGAN 07-G:")
## - Subjudul (Bold): baris kepala bagian yang diakhiri ":" (mis. "Catatan bertahan hidup:")
## - Teks biasa (Medium): paragraf dan daftar poin.

const FONT_EXTRABOLD: FontFile = preload("res://assets/fonts/nunito/Nunito-ExtraBold.ttf")
const FONT_BOLD: FontFile = preload("res://assets/fonts/nunito/Nunito-Bold.ttf")
const FONT_MEDIUM: FontFile = preload("res://assets/fonts/nunito/Nunito-Medium.ttf")

const COLOR_TITLE := Color(0.922, 0.788, 0.541, 1.0)
const COLOR_SUBTITLE := Color(0.969, 0.945, 0.898, 1.0)
const COLOR_BODY := Color(0.969, 0.945, 0.898, 0.9)

@onready var _icon: TextureRect = $Center/Card/VBox/Header/IconBox/Icon
@onready var _dummy_icon: Label = $Center/Card/VBox/Header/IconBox/DummyIcon
@onready var _title: Label = $Center/Card/VBox/Header/TitleCol/Title
@onready var _subtitle: Label = $Center/Card/VBox/Header/TitleCol/Subtitle
@onready var _body_box: VBoxContainer = $Center/Card/VBox/BodyBox
@onready var _close_button: Button = $Center/Card/VBox/Footer/CloseButton


func _ready() -> void:
	if _close_button != null and not _close_button.pressed.is_connected(close_modal):
		_close_button.pressed.connect(close_modal)


func open_item(item: ItemDefinition, body_text: String) -> void:
	if item == null:
		return
	_title.text = item.display_name
	_subtitle.text = ItemTooltip.category_label(item.category)

	var tex := item.get_icon()
	_icon.texture = tex
	_icon.visible = tex != null
	_dummy_icon.visible = tex == null
	_dummy_icon.text = item.display_name.left(1).to_upper() if tex == null else ""

	_rebuild_body(body_text)
	visible = true


func close_modal() -> void:
	visible = false


func _rebuild_body(body_text: String) -> void:
	for child in _body_box.get_children():
		_body_box.remove_child(child)
		child.free()

	for block in body_text.split("\n\n", false):
		var lines := block.split("\n", false)
		for raw_line in lines:
			var line := raw_line.strip_edges()
			if line.is_empty():
				continue
			_add_styled_line(line)


func _add_styled_line(line: String) -> void:
	var lbl := Label.new()
	lbl.text = line
	lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	lbl.custom_minimum_size = Vector2(484, 0)
	lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE

	if _is_major_heading(line):
		lbl.add_theme_font_override(&"font", FONT_EXTRABOLD)
		lbl.add_theme_font_size_override(&"font_size", 17)
		lbl.add_theme_color_override(&"font_color", COLOR_TITLE)
	elif _is_subtitle(line):
		lbl.add_theme_font_override(&"font", FONT_BOLD)
		lbl.add_theme_font_size_override(&"font_size", 15)
		lbl.add_theme_color_override(&"font_color", COLOR_SUBTITLE)
	else:
		lbl.add_theme_font_override(&"font", FONT_MEDIUM)
		lbl.add_theme_font_size_override(&"font_size", 14)
		lbl.add_theme_color_override(&"font_color", COLOR_BODY)

	_body_box.add_child(lbl)


func _is_major_heading(line: String) -> bool:
	return line.ends_with(":") and line == line.to_upper()


func _is_subtitle(line: String) -> bool:
	return line.ends_with(":") and not line.begins_with("-")
