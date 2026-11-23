class_name ProtectionHUD
extends Control

## Mission 9: label baca-saja "Perlindungan N dtk" selama perlindungan respawn.
## Tidak menulis state gameplay apa pun; hanya membaca PlayerDamageReceiver.

const PREFIX := "Perlindungan"

@export var receiver: PlayerDamageReceiver

var _label: Label


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	visible = false
	_label = Label.new()
	_label.name = "ProtectionLabel"
	_label.add_theme_color_override("font_color", Color(0.7, 0.95, 1.0, 1.0))
	add_child(_label)
	_find_receiver()


func _process(delta: float) -> void:
	tick(delta)


func tick(_delta: float) -> void:
	_find_receiver()
	if receiver == null or not receiver.is_protected():
		visible = false
		return
	var seconds := int(ceil(receiver.get_protection_remaining()))
	_label.text = "%s %d dtk" % [PREFIX, maxi(seconds, 1)]
	visible = true


func get_text() -> String:
	return _label.text if _label != null else ""


func _find_receiver() -> void:
	if receiver != null and is_instance_valid(receiver):
		return
	var tree := get_tree()
	if tree == null:
		return
	var player := tree.get_first_node_in_group(&"player")
	if player == null:
		return
	receiver = player.get_node_or_null("PlayerDamageReceiver") as PlayerDamageReceiver
