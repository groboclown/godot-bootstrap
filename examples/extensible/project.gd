
extends Panel

var current_module_order = null


func _ready():
	# Setup buttons
	var menu = get_node("v/s/MenuButtons")
	menu.set_buttons([{
		"name": "Scan for modules",
		"obj": self,
		"func": "_on_find_modules"
	}, {
		"name": "Start new game",
		"obj": self,
		"func": "_on_new_game"
	}])


func _on_find_modules():
	# Let the auto-load node scan for modules, and
	# report if it discovers any errors.
	var global_modules = get_tree().get_root().get_node("modules")
	global_modules.scan_modules(self)

func _on_new_game():
	# Each game defines its own module list.
	
	var global_modules = get_tree().get_root().get_node("modules")
	if ! global_modules.has_modules():
		var dialog = load("res://bootstrap/gui/error_dialog.gd").new()
		dialog.show_warning(self, "Modules", "No modules found, or they haven't been loaded yet.", null)
		return
	if ! global_modules.get_invalid_modules().empty():
		var n = load("res://bootstrap/gui/modules/problem.xscn").instance()
		n.setup(global_modules.get_invalid_modules())
		add_child(n)
		return

	var order_wrapper = get_node("module_order")
	var order = order_wrapper.get_node("Panel")
	order.setup(global_modules.get_modules(), self, "_on_order_updated", "_on_order_closed")
	order.show_modules()
	order_wrapper.show()

func _on_order_updated(module_order):
	current_module_order = module_order

func _on_order_closed(accepted):
	get_node("module_order").hide()
	var global_modules = get_tree().get_root().get_node("modules").get_modules()
	if accepted && current_module_order != null && current_module_order.size() > 0:
		var game_state = get_tree().get_root().get_node("game_state")
		if ! game_state.start_new_game(global_modules, current_module_order):
			var n = load("res://bootstrap/gui/modules/problem.xscn").instance()
			n.setup(game_state.get_invalid_modules())
			add_child(n)
			return
		# FIXME start game.
		pass
