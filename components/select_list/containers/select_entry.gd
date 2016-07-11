
extends Container


var is_hover = false
var is_selected = false


func _init(entry_node):
	add_user_signal('selected')
	add_user_signal('selection_changed', [{ 'name': 'is_selected', 'type': TYPE_BOOL }])
	add_user_signal('hover', [{ 'name': 'is_hover', 'type': TYPE_BOOL }])

	# connect("input_event", self, "_on_input_event")
	connect("mouse_enter", self, "_on_mouse_enter")
	connect("mouse_exit", self, "_on_mouse_exit")
	
	add_child(entry_node)


func get_entry_node():
	return get_child(0)


func get_size():
	return get_child(0).get_size()


func get_minimum_size():
	return get_child(0).get_minimum_size()


func _on_unselect():
	is_selected = false
	emit_signal('selection_changed', false)

#func _on_input_event(ev):
func _input_event(ev):
	if ev.is_pressed():
		is_selected = true
		emit_signal('selected')
		emit_signal('selection_changed', true)
		# Allow the event to continue down; don't consume it.

func _on_mouse_enter():
	is_hover = true
	emit_signal('hover', true)

func _on_mouse_exit():
	is_hover = false
	emit_signal('hover', false)
