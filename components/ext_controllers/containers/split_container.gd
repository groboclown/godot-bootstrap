
extends Container

# A very specific kind of container that holds exactly 2 child nodes.
# They are aligned such that both take up the same amount of space within
# the container, and are aligned across the center.

export var separation = 40



func _ready():
	connect("minimum_size_changed", self, "_on_resized")
	connect("item_rect_changed", self, "_on_resized")
	connect("resized", self, "_on_resized")
	connect("size_flags_changed", self, "_on_resized")
	
	_on_resized()


func _on_resized():
	var size = get_size()
	var pos = get_pos()
	var mid_x = pos.x + (size.x / 2)
	var c0 = get_child(0)
	var c0s = c0.get_size()
	var c1 = get_child(1)
	var c1s = c1.get_size()
	var min_size = get_minimum_size()
	#min_size.x = size.x
	min_size.y = max(c0s.y, c1s.y)
	set_custom_minimum_size(min_size)
	
	_set_kid_size(c0, c0s, size, mid_x - (separation / 2) - c0s.x)
	_set_kid_size(c1, c1s, size, mid_x + (separation / 2))

func _set_kid_size(child, child_size, size, width):
	var min_size = child.get_minimum_size()
	if min_size.x > 0:
		child.set_size(Vector2(min_size.x, size.y))
	else:
		child.set_size(Vector2(child_size.x, size.y))
	child.set_pos(Vector2(width, 0))
