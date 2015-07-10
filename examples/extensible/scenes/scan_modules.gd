
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
	modules.reload_modules([ "res://modules/system", "res://modules/purchased", "res://modules/user_generated" ], progress)
	parent.remove_child(self)
	var bad_modules = modules.get_invalid_modules()
	if ! bad_modules.empty():
		var n = load("res://bootstrap/gui/modules/problem.xscn").instance()
		n.setup(bad_modules)
		parent.add_child(n)
	else:
		print("No errors found")
		for m in modules.get_installed_modules():
			print("found " + m.name)
