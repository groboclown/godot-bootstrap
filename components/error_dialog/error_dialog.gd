
extends AcceptDialog


export var parent_margin_x = 30
export var parent_margin_y = 80


func show_warning(node, title, error_type, details, callback = null):
	set_title(title)
	warning(error_type, details, node, callback)
	_add_to_center(node)


func show_unrecoverable_error(node, title, error_type, details):
	set_title(title)
	unrecoverable_error(error_type, details)
	_add_to_center(node)


func unrecoverable_error(error_type, details):
	_setup(error_type, details, true, null, null)


func warning(error_type, details, node = null, callback = null):
	_setup(error_type, details, false, node, callback)


func problem(node, error_type, details, is_unrecoverable, callback = null):
	_setup(error_type, details, is_unrecoverable, node, callback)



# Unrecoverable errors can only ever be
# generated once, and from then on all
# errors are unrecoverable.
var _is_unrecoverable = false
var _text
var _callback_obj
var _callback_func


func _setup(error_type, details, is_unrecoverable, callback_obj, callback_func):
	_text = tr(str(error_type)) + " " + str(details)
	_is_unrecoverable = is_unrecoverable
	_callback_obj = callback_obj
	_callback_func = callback_func


func _ready():
	get_ok().connect("pressed", self, "_on_failure_confirmed")
	set_as_toplevel(true)
	show()
	popup_centered()
	set_exclusive(true)
	get_label().set_text(_text)


func _on_failure_confirmed():
	hide()
	if _is_unrecoverable:
		get_tree().quit()
	else:
		get_parent().remove_child(self)
		if _callback_obj != null && _callback_func != null && _callback_obj.has_method(_callback_func):
			_callback_obj.call(_callback_func)


func _add_to_center(node):
	var view = node.get_tree().get_root()
	view.add_child(self)
	var size = view.get_rect().size
	popup_centered(Vector2(size.x - parent_margin_x, size.y - parent_margin_y))
