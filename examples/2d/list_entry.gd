
extends HBoxContainer

# member variables here, example:
# var a=2
# var b="textvar"

var _selected = false
var _hover = false
var _focus = false
var _switched = false



func setup(name, container):
	get_node("title").set_text(str(name))
	_selected = container.is_child_selected(self)
	_hover = container.is_child_hovered(self)
	_focus = container.is_child_focused(self)
	container.connect('selected', self, '_on_selection_changed')
	container.connect('hovered', self, '_on_hover_changed')
	container.connect('focused', self, '_on_focus_changed')

func _on_selection_changed():
	_selected = get_parent().is_child_selected(self)
	update()

func _on_hover_changed():
	_hover = get_parent().is_child_selected(self)
	update()

func _on_focus_changed():
	_focus = get_parent().is_child_focused(self)
	update()


func _on_Remove_pressed():
	call_deferred("_on_remove_self")


func _on_remove_self():
	get_parent().remove_child(self)


func _draw():
	var size = get_size()
	var red = 0.0
	var green = 0.0
	var blue = 0.0
	if get_index() % 2 == 1:
		green += 0.2
		red += 0.2
		blue += 0.2
	if _switched:
		blue += 0.3
	if _hover:
		green += 0.2
	if _selected:
		red += 0.3
	var r = Rect2(0, 0, size.x, size.y)
	draw_rect(r, Color(red, green, blue))
	
	var c
	for c in get_children():
		c.update()


func _on_CheckBox_toggled(pressed):
	_switched = (pressed == true)
	update()
