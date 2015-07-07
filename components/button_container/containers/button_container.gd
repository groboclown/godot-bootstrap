
extends Container

# A container for a dynamic set of buttons.  The usage is:
#
# var my_buttons = [
#   { "name": "TRANSLATION_LOOKUP_NAME", "type": "TYPE", "obj": self, "func": "on_TLN_click" },
#   ...
# ]
# var button_container = preload("button_container.gd").instance()
# button_container.set_buttons(my_buttons)
# add_child(button_container)

# Auto-created buttons use the "button_instance.xscn" scene as the
# source button.  That's where you would skin the buttons.




# Create a sub-menu.  When clicked, it will perform:
#		var new_button_dict = button_dict["obj"].call(button_dict["func"])
# An additional "back" button will be added to return to the parent menu.
const BUTTON_TYPE__MENU = "menu"

# Use the given node stored in "obj" as the node to insert as a button.
# This allows for slide choosers and other custom stuff to be added.
const BUTTON_TYPE__NODE = "node"

# All other button "type" values will default to a normal button.
# Create a standard "on-click" button.  When clicked, it will perform:
#     button_dict["obj"].call(button_dict["func"])


export var back_button_text = "MENU_BACK_BUTTON"
export var horizontal_buttons = false
export var separation = -1

var _button_list_stack

func set_back_button_text(text):
	back_button_text = text


func set_buttons(button_list):
	_button_list_stack = [ button_list ]
	if is_inside_tree():
		_create_current_buttons()

func _init():
	set_focus_mode(Container.FOCUS_ALL)

func _ready():
	# Called when children added to the tree, and this was added to the tree.
	connect("focus_enter", self, "_on_focus_enter")
	var button_list
	if has_node("button_list"):
		remove_child(get_node("button_list"))
	if horizontal_buttons:
		button_list = HBoxContainer.new()
		button_list.set_anchor_and_margin(MARGIN_BOTTOM, ANCHOR_END, 0)
	else:
		button_list = VBoxContainer.new()
		button_list.set_anchor_and_margin(MARGIN_RIGHT, ANCHOR_END, 0)
	button_list.connect("resized", self, "_on_resize")
	button_list.connect("minimum_size_changed", self, "_on_resize")
	button_list.connect("size_flags_changed", self, "_on_resize")
	
	# this is a theme thing.
	if separation > 0:
		button_list.add_constant_override("separation", separation)
	
	button_list.set_name("button_list")
	button_list.set_custom_minimum_size(Vector2(0, 0))
	add_child(button_list)
	
	if _button_list_stack != null:
		_create_current_buttons()


func _create_current_buttons():
	var container = get_node("button_list")
	
	# Remove all button instance children
	var kid
	for kid in container.get_children():
		container.remove_child(kid)
	
	if _button_list_stack == null || _button_list_stack.size() <= 0:
		print("Bad state for button container: no buttons")
		print_stack()
		return
	
	# Add the lowest button-list in the stack.
	var button_list = _button_list_stack[_button_list_stack.size() - 1]
	var button
	for button in button_list:
		if "type" in button && button["type"] == BUTTON_TYPE__NODE:
			if ! ("obj" in button) || button["obj"] == null:
				print("Bad state for button list, button " + str(button["name"]) + " is a node, but does not have an 'obj'")
				print_stack()
			else:
				var obj = button["obj"]
				if (obj.is_inside_tree()):
					obj.get_parent().remove_child(obj)
				_add_kid(container, obj)
		else:
			# Normal or menu button.
			_add_kid_button(container, button)
	
	if _button_list_stack.size() > 1:
		# Add the "back" button
		button = {
			"name": back_button_text,
			"obj": self,
			"func": "_on_back_button_press"
		}
		_add_kid_button(container, button)
	
	# Make sure the child box is setup right
	if has_focus():
		_on_focus_enter()
	
	call_deferred("_setup_size")
	

func _on_back_button_press():
	if _button_list_stack != null && _button_list_stack.size() > 1:
		_button_list_stack.remove(_button_list_stack.size() - 1)
		# This was called by a child button, which we're removing.
		# So defer the call before freeing it.
		call_deferred("_create_current_buttons")


func on_menu(menu_result):
	if _button_list_stack != null:
		_button_list_stack.append(menu_result)
		# This was called by a child button, which we're removing.
		# So defer the call before freeing it.
		call_deferred("_create_current_buttons")


func _add_kid_button(container, button):
	var kid = preload("button_container/button_instance.gd").new(horizontal_buttons)
	kid.set_name(button["name"])
	kid.set_button(button, self)
	
	# These require paths, not node objects
	#if container.get_child_count() > 0:
	#	var n = container.get_child(container.get_child_count() - 1)
	#	kid.set_focus_neighbour(MARGIN_LEFT, n)
	#	kid.set_focus_neighbour(MARGIN_TOP, n)
	#	n.set_focus_neighbour(MARGIN_RIGHT, kid)
	#	n.set_focus_neighbour(MARGIN_BOTTOM, kid)
	
	_add_kid(container, kid)


func _add_kid(container, kid):
	var size = kid.get_minimum_size()
	#print(kid.get_name() + ": kid size: "+str(size)+"; self size: "+str(get_size()))
	if horizontal_buttons:
		size.y = get_size().y
	else:
		size.x = get_size().x
	kid.set_custom_minimum_size(size)
	container.add_child(kid)


func _on_resize():
	set_custom_minimum_size(get_node("button_list").get_size())


func _on_focus_enter():
	var container = get_node("button_list")
	if container.get_child_count() > 0:
		container.get_child(0).grab_focus()
