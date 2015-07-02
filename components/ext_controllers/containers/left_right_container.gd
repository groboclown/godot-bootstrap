
extends Container

# A very specific kind of container that holds exactly 2 child nodes.
# The left child is aligned on the left margin, and the right child on the
# right margin.

export var right_fixed_width = true


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
	min_size.y = max(c0s.y, c1s.y)
	set_custom_minimum_size(min_size)
	
	if right_fixed_width:
		c0s = _get_opposite_size(size.x, c1, c0)
	else:
		c1s = _get_opposite_size(size.x, c0, c1)
	
	_set_kid_size(c0, c0s, size, pos.x)
	_set_kid_size(c1, c1s, size, pos.x + size.x - c1s.x)


func _set_kid_size(child, child_size, size, width):
	var min_size = child.get_minimum_size()
	#if min_size.x > 0:
	#	child.set_size(Vector2(min_size.x, size.y))
	#else:
	#	child.set_size(Vector2(child_size.x, size.y))
	child.set_size(Vector2(max(min_size.x, child_size.x), size.y))
	child.set_pos(Vector2(width, 0))

func _get_opposite_size(parent_width, priority_child, other_child):
	var pwidth = max(priority_child.get_minimum_size().x, priority_child.get_size().x)
	var owidth = parent_width - pwidth
	var osize = other_child.get_size()
	var oxwidth = max(other_child.get_minimum_size().x, owidth)
	return Vector2(oxwidth, osize.y)

