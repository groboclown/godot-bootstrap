
extends HBoxContainer

# member variables here, example:
# var a=2
# var b="textvar"

# TODO make the hover color be exported,
# and loaded from the theme.

var module
var _model
var _active
var _selected = false
var _hover = false

var errors = preload("res://bootstrap/lib/error_codes.gd")


func setup(md, selection_model, active):
	module = md
	_model = selection_model
	_active = active


func _ready():
	# Initialization here
	var name = module.name
	
	if module.error_code == OK:
		name += " v" + str(module.version[0]) + "." + str(module.version[1])
		if module.description.length() > 0:
			name += ": " + module.description
	else:
		name += ": " + tr(module.error_operation) + " " + module.error_details + " (" + tr(errors.to_string(module.error_code)) + ")"
	get_node("name").set_text(name)
	get_node("CheckBox").set_pressed(_active)
	
	connect("minimum_size_changed", self, "_on_resized")
	connect("item_rect_changed", self, "_on_resized")
	connect("resized", self, "_on_resized")
	connect("size_flags_changed", self, "_on_resized")
	
	_on_resized()


func _draw():
	var size = get_size()
	var red = 0.0
	if module.error_code != OK:
		red = 0.3
	var r = Rect2(0, 0, size.x, size.y)
	if _selected:
		if _hover:
			draw_rect(r, Color(0.5 + red, 0.5, 0.3))
		else:
			draw_rect(r, Color(0.3 + red, 0.3, 0.0))
	elif _hover:
		draw_rect(r, Color(0.5 + red, 0.5, 0))
	else:
		draw_rect(r, Color(0.1 + red, 0.1, 0.1))
	
	var c
	for c in get_children():
		c.update()


func _on_CheckBox_toggled( pressed ):
	_active = pressed
	_model.set_module_active_state(module, _active)


func _on_name_pressed():
	_model.set_selected_module_node(self)


func on_module_selected(md):
	_selected = md == module
	update()


func is_active_module():
	return _active


func _on_HBoxContainer_input_event( ev ):
	if ev.is_pressed():
		_model.set_selected_module_node(self)


func _on_HBoxContainer_mouse_enter():
	_hover = true
	update()


func _on_HBoxContainer_mouse_exit():
	_hover = false
	update()


func _on_resized():
	var p = get_parent()
	if p != null:
		# TODO change - to be the hbar width
		set_size(Vector2(p.get_size().x - 4, get_size().y))
