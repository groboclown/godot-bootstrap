
extends VBoxContainer

# member variables here, example:
# var a=2
# var b="textvar"

func _ready():
	var options = _get_options()
	get_node("v0/master").set_val(options.get_master_volume())
	get_node("v1/music").set_val(options.get_music_volume())
	get_node("v2/fx").set_val(options.get_fx_volume())
	_setup_split(get_node("v0"))
	_setup_split(get_node("v1"))
	_setup_split(get_node("v2"))




func _on_master_value_changed( value ):
	var options = _get_options()
	options.set_master_volume(value)
	options.save_options()


func _on_music_value_changed( value ):
	var options = _get_options()
	options.set_music_volume(value)
	options.save_options()


func _on_fx_value_changed( value ):
	var options = _get_options()
	options.set_fx_volume(value)
	options.save_options()


func _get_options():
	return get_tree().get_root().get_node("user_options")


func _setup_split(node):
	# Setup the basic container so that it correctly sizes
	# A split should have exactly 2 elements.
	var size = node.get_size()
	var pos = node.get_pos()
	var c0 = node.get_child(0)
	var c1 = node.get_child(1)
	var box0 = Rect2(pos.x, pos.y, (size.x / 2) - 20, size.y)
	var box1 = Rect2(pos.x + (size.x / 2) + 20, pos.y, (size.x / 2) - 20, size.y)
	node.fit_child_in_rect(c0, box0)
	node.fit_child_in_rect(c1, box1)
	
