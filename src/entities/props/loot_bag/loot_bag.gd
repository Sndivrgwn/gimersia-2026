class_name LootBag
extends Interactable

## Loot bag di lokasi kematian. Menyimpan ItemStack sampai diambil dengan hold-E.
## Satu bag per kematian; beberapa bag boleh ada bersamaan (spec §7.6).

signal looted

const HOLD_TIME := 1.0
const PROMPT := "Tahan E: Ambil Loot Bag"

var stacks: Array[ItemStack] = []

var _label: Label


func _enter_tree() -> void:
	super._enter_tree()
	add_to_group(&"loot_bag")


func _ready() -> void:
	_build_visual()


func setup(p_stacks: Array[ItemStack]) -> void:
	stacks = p_stacks
	_refresh_label()


func get_stack_count() -> int:
	return stacks.size()


func get_total_items() -> int:
	var total := 0
	for stack in stacks:
		if stack != null:
			total += stack.count
	return total


# --- Interactable -----------------------------------------------------------

func get_prompt(_interactor: Node) -> String:
	if stacks.is_empty():
		return ""
	return PROMPT


func get_hold_time(_interactor: Node) -> float:
	return HOLD_TIME


func can_interact(_interactor: Node) -> bool:
	return not stacks.is_empty()


func get_block_reason(_interactor: Node) -> String:
	return "Loot bag kosong" if stacks.is_empty() else ""


func interact(interactor: Node) -> void:
	if interactor == null or not interactor.has_method(&"get_inventory"):
		return
	var inventory := interactor.get_inventory() as InventoryComponent
	if inventory == null:
		return

	var remaining: Array[ItemStack] = []
	for stack in stacks:
		if stack == null or stack.item == null or stack.count <= 0:
			continue
		var leftover := inventory.add_item(stack.item, stack.count)
		if leftover > 0:
			var rest := ItemStack.new()
			rest.item = stack.item
			rest.count = leftover
			remaining.append(rest)
	stacks = remaining
	_refresh_label()
	looted.emit()
	if stacks.is_empty():
		queue_free()


# --- Visual -----------------------------------------------------------------

func _build_visual() -> void:
	var visual := Polygon2D.new()
	visual.name = "Visual"
	visual.color = Color(0.72, 0.58, 0.3, 0.9)
	visual.polygon = PackedVector2Array([
		Vector2(-12, -6), Vector2(12, -6), Vector2(14, 8), Vector2(-14, 8)
	])
	add_child(visual)

	_label = Label.new()
	_label.name = "Label"
	_label.position = Vector2(-40, 10)
	_label.size = Vector2(80, 16)
	_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_label.add_theme_font_size_override("font_size", 10)
	_label.text = "Loot"
	add_child(_label)


func _refresh_label() -> void:
	if _label == null:
		return
	_label.text = "Loot (%d)" % get_total_items()
