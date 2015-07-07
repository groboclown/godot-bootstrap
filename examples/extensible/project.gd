
extends Panel

# member variables here, example:
# var a=2
# var b="textvar"

func _ready():
	# Setup buttons
	var menu = get_node("v/s/MenuButtons")
	menu.set_buttons([{
		"name": "Find Modules",
		"obj": self,
		"func": "_on_find_modules"
	}])
	

func _on_find_modules():
	var global_modules = get_tree().get_root().get_node("modules")
	global_modules.scan_modules(self)
