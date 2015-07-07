
extends Panel

var modules


func _ready():
	if modules != null:
		set_process(true)

func _process(delta):
	var parent = get_parent()
	set_process(false)
	if modules == null:
		return
	
	var progress = get_node("c/v/progress")
	modules.reload_modules([ "res://modules" ], progress)
	parent.remove_child(self)
	var bad_modules = modules.get_invalid_modules()
	if ! bad_modules.empty():
		var n = load("res://bootstrap/gui/modules/problem.xscn")
		parent.add_child(n)
	else:
		print("No errors found")
		#var n = load("res://bootstrap/gui/error_dialog.gd").new()
		#n.show_warning(parent, "Module Load", "No problems found in modules.", "")
		
		var n = load("res://bootstrap/gui/modules/module_order.xscn").instance()
		
		# TODO setup the order
		n.setup(modules, self, "_on_order_set", [])
		parent.add_child(n)

func _on_order_set(new_order):
	pass