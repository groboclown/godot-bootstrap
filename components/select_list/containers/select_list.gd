
extends Container

var _selected_index = -1
var _focused_index = -1
var _hovered_index = -1
var _extra_listeners = []


# HORIZONTAL = 0
# VERTICAL = 1
export(int, 0, 1) var orientation = VERTICAL setget _on_ui_var_change

const ALIGN_BEGIN = 0
const ALIGN_CENTER = 1
const ALIGN_END = 2
const ALIGN_FILL = 3
const ALIGN_EXPAND_FILL = 4
export(int, 0, 4) var align = ALIGN_BEGIN setget _on_ui_var_change

export(String) var select_changed_callback
export(String) var focus_changed_callback
export(String) var hover_changed_callback

func _init():
	add_user_signal('selected', [{ 'name': 'index', 'type': TYPE_INT }])
	add_user_signal('focused', [{ 'name': 'index', 'type': TYPE_INT }])
	add_user_signal('hovered', [{ 'name': 'index', 'type': TYPE_INT }])
	set_focus_mode(FOCUS_ALL)

func set_selected_index(index):
	if typeof(index) == TYPE_INT && _selected_index != index:
		var selected = _valid_child(index)
		var currently_selected = _valid_child(_selected_index)
		_selected_index = index
		_run_callback(select_changed_callback, index)
		emit_signal('selected', index)
		update()

func get_selected_index():
	return _selected_index

func get_selected():
	if _valid_child(_selected_index):
		return get_child(_selected_index)
	return null

func has_selected():
	return _valid_child(_selected_index)

func is_first_selected():
	return _selected_index == 0

func is_last_selected():
	return _selected_index == get_child_count() - 1

func is_child_selected(child):
	return child != null && child.get_parent() == self && _selected_index == child.get_index()
	
func set_focused_index(index):
	if typeof(index) == TYPE_INT && _focused_index != index:
		_focused_index = index
		_run_callback(focus_changed_callback, index)
		emit_signal('focused', index)
		update()

func get_focused_index():
	return _focused_index

func get_focused():
	if _valid_child(_focused_index):
		return get_child(_focused_index)
	return null

func is_child_focused(child):
	return child != null && child.get_parent() == self && _focused_index == child.get_index()

func set_hovered_index(index):
	if typeof(index) == TYPE_INT && _hovered_index != index:
		_hovered_index = index
		_run_callback(hover_changed_callback, index)
		emit_signal('hovered', index)
		update()

func get_hovered_index():
	return _hovered_index

func get_hovered():
	if _valid_child(_hovered_index):
		return get_child(_hovered_index)
	return null

func is_child_hovered(child):
	return child != null && child.get_parent() == self && _hovered_index == child.get_index()

func add_state_change_listener(obj):
	if obj != null:
		_extra_listeners.append(weakref(obj))

func remove_state_change_listener(obj):
	var new_ref = []
	var ref
	for ref in _extra_listeners:
		var val = ref.get_ref()
		if val != null && val != obj:
			new_ref.append(ref)
	_extra_listeners = new_ref

func add_child(child):
	.add_child(child)
	update()

func remove_child(child):
	.remove_child(child)
	update()

func move_child(child, index):
	.move_child(child, index)
	update()
	
func _input_event(event):
	var child_count = get_child_count()
	if ((orientation == HORIZONTAL && event.is_action("ui_left")) || (orientation == VERTICAL && event.is_action("ui_up"))):
		if _focused_index <= 0:
			set_focused_index(child_count - 1)
		elif _focused_index >= child_count - 1:
			set_focused_index(0)
		else:
			set_focused_index(_focused_index - 1)
		accept_event()

	if ((orientation == HORIZONTAL && event.is_action("ui_right")) || (orientation == VERTICAL && event.is_action("ui_down"))):
		if _focused_index < 0 || _focused_index >= child_count - 1:
			set_focused_index(0)
		else:
			set_focused_index(_focused_index + 1)
		accept_event()
	
	if event.is_pressed() && (event.type != InputEvent.MOUSE_BUTTON || event.button_index == BUTTON_LEFT):
		var entry_index = _find_entry_index_at(event)
		if entry_index >= 0:
			set_selected_index(entry_index)
		# Do not accept the event; let it pass down to the children.
	
	if event.type == InputEvent.MOUSE_MOTION:
		var entry_index = _find_entry_index_at(event)
		if entry_index >= 0:
			set_hovered_index(entry_index)
		# Do not accept the event; let it pass down to the children.

func _draw():
	if orientation == null:
		orientation = VERTICAL
	var size_obj = get_size()
	var size = [ size_obj.x, size_obj.y ]
	var minsize_obj = get_combined_minimum_size()
	var minsize = [ minsize_obj.x, minsize_obj.y ]
	var button_sep = get_constant("button_separator")

	var sep = button_sep
	var ofs = 0
	var expand = 0

	if align == ALIGN_CENTER:
		ofs = floor((size[orientation] - minsize[orientation])/2)
	elif align == ALIGN_END:
		ofs = floor((size[orientation] - minsize[orientation]))
	elif align == ALIGN_FILL:
		if get_child_cound() > 1:
			sep += floor((size[orientation]- minsize[orientation])/(get_child_count()-1.0));
	elif align == ALIGN_EXPAND_FILL:
		expand = size[orientation] - minsize[orientation];
	
	var op_size = size[abs(orientation - 1)];

	var ch
	for ch in get_children():
		var ms_obj = ch.get_minimum_size()
		var ms = [ ms_obj.x, ms_obj.y ]
		var s = ms[orientation]
		if expand > 0:
			s = expand / get_children_count()
		
		var r
		if orientation == HORIZONTAL:
			r = Rect2(ofs, 0, s, op_size)
		else:
			r = Rect2(0, ofs, op_size, s)
		
		fit_child_in_rect(ch, r)
		ch.update()
		
		ofs += s + sep

func _on_ui_var_change(new_val):
	update()

func _valid_child(index):
	return index >= 0 && index < get_child_count()

func _run_callback(callback_name, index):
	var ref
	var b
	for ref in _extra_listeners:
		b = ref.get_ref()
		if b != null && b.has_method(callback_name):
			b.call(callback_name, index, false)

func _find_entry_index_at(pos):
	var location = _get_orientation_pos(pos)
	
	# TODO switch to the HBox / VBox constant
	var button_sep = get_constant("button_separator")
	var entry
	var pos = 0
	var index = 0
	for entry in get_children():
		pos += _get_orientation_pos(entry.get_size())
		if location <= pos:
			return entry.get_index()
		pos += button_sep
		if location <= pos:
			return -1
		index += 1
	return -1
	
	
func _get_orientation_pos(vec):
	if orientation == HORIZONTAL:
		return vec.x
	return vec.y
	