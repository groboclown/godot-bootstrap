
extends 'select_list.gd'

func _init():
	._init()

	var ch = VBoxContainer.new()
	ch.set_name("box")
	ch.set_anchor_and_margin(MARGIN_RIGHT, ANCHOR_END, 0)
	ch.set_anchor_and_margin(MARGIN_BOTTOM, ANCHOR_END, 0)
	add_child(ch)

	
func get_lines():
	return get_child(0).get_children()


func get_line_nodes():
	var ret = []
	var ch
	for ch in get_lines():
		ret.append(ch.get_line_node())
	return ret


func get_selected_line_node():
	return get_selected_node()


func get_selected_line():
	return get_selected_entry()


func get_selected_index():
	var entry = get_selected_entry()
	if entry == null:
		return -1
	return entry.get_index()

func is_first_selected():
	return get_selected_entry() == 0

func is_last_selected():
	return get_selected_entry() >= get_lines().size() - 1

func add_line(obj):
	var line = create_entry(obj)
	get_child(0).add_child(line)
	return line


func move_line_node(line_node, to_pos):
	var ch = get_line_for_node(line_node)
	if ch != null:
		get_child(0).move_child(ch, to_pos)

func remove_line_node(line_node):
	var ch = get_line_for_node(line_node)
	if ch != null:
		get_child(0).remove_child(ch)
		return true
	return false


func get_line_for_node(line_node):
	var p = get_child(0)
	var ch
	for ch in p.get_children():
		if ch.get_entry_node() == line_node:
			return ch
	return null


func clear_lines():
	var p = get_child(0)
	var ch
	for ch in p.get_children():
		p.remove_child(ch)


func _on_line_selected(line):
	var ch
	for ch in get_lines():
		if ch != line:
			line._on_unselect()
	emit_signal('selected')
