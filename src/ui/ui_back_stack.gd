class_name UiBackStack
extends RefCounted

## Mission 10 Phase 5: satu registry UI yang bisa ditutup (Esc).
## Panel mendaftar saat terbuka dan melepas saat tertutup; urutan grup =
## urutan dibuka, jadi elemen terakhir adalah yang paling atas.

const GROUP := &"closable_ui"


static func register(node: Node) -> void:
	if node != null:
		node.add_to_group(GROUP)


static func unregister(node: Node) -> void:
	if node != null:
		node.remove_from_group(GROUP)


## Node yang sedang terbuka, urut sesuai waktu pendaftaran.
static func open_nodes(context: Node) -> Array[Node]:
	var result: Array[Node] = []
	var tree := context.get_tree() if context != null else null
	if tree == null:
		return result
	for node in tree.get_nodes_in_group(GROUP):
		if node == null or not is_instance_valid(node) or not node.is_inside_tree():
			continue
		if node.has_method(&"is_open") and not bool(node.call(&"is_open")):
			continue
		result.append(node)
	return result


static func has_open(context: Node, except_node: Node = null) -> bool:
	for node in open_nodes(context):
		if node != except_node:
			return true
	return false


## Tutup UI paling atas. False bila tidak ada yang terbuka.
static func close_top(context: Node) -> bool:
	var nodes := open_nodes(context)
	if nodes.is_empty():
		return false
	var top: Node = nodes[nodes.size() - 1]
	if top.has_method(&"close"):
		top.call(&"close")
		return true
	return false
