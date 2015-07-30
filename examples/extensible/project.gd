
extends Panel

var current_module_order = null

var ERROR_CODES = preload("res://bootstrap/lib/error_codes.gd")

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
	}, {
		"name": "Load game",
		"obj": self,
		"func": "_on_load_game"
	}])
	var load_game = get_node("load_game/Panel")
	load_game.connect("cancelled", self, "_on_load_cancelled")
	load_game.connect("load", self, "_on_load_game_success")


func _on_find_modules():
	# Let the auto-load node scan for modules, and
	# report if it discovers any errors.
	var global_modules = get_tree().get_root().get_node("game_state")
	global_modules.scan_modules(self)

# --------------------------------------------------------------
# New Game


func _on_new_game():
	# Each game defines its own module list.
	
	var global_modules = get_tree().get_root().get_node("game_state")
	if ! global_modules.has_modules():
		var dialog = load("res://bootstrap/gui/error_dialog.gd").new()
		dialog.show_warning(self, "Modules", "No modules found, or they haven't been loaded yet.", null)
		return
	#if ! global_modules.get_invalid_installed_modules().empty():
	#	var n = load("res://bootstrap/gui/modules/problem.xscn").instance()
	#	n.setup(global_modules.get_invalid_installed_modules())
	#	add_child(n)
	#	return

	var order_wrapper = get_node("module_order")
	var order = order_wrapper.get_node("Panel")
	order.setup(global_modules.get_modules(), self, "_on_order_updated", "_on_order_closed")
	order.show_modules()
	order_wrapper.show()

func _on_order_updated(module_order):
	current_module_order = module_order

func _on_order_closed(accepted):
	get_node("module_order").hide()
	var global_modules = get_tree().get_root().get_node("game_state").get_modules()
	if accepted && current_module_order != null && current_module_order.size() > 0:
		var game_state = get_tree().get_root().get_node("game_state")
		# FIXME include adding an entry for the file name.
		if ! game_state.start_new_game("1", current_module_order):
			var n = load("res://bootstrap/gui/modules/problem.xscn").instance()
			n.setup(game_state.get_invalid_save_modules())
			add_child(n)
			return
		# FIXME start game.
		pass


# --------------------------------------------------------------
# Load game

func _on_load_game():
	var global_modules = get_tree().get_root().get_node("game_state")
	if ! global_modules.has_modules():
		var dialog = load("res://bootstrap/gui/error_dialog.gd").new()
		dialog.show_warning(self, "Modules", "No modules found, or they haven't been loaded yet.", null)
		return

	var loader_wrapper = get_node("load_game")
	var loader = loader_wrapper.get_node("Panel")
	loader.setup(global_modules._savegames)
	loader.reload_games()
	loader_wrapper.show()


func _on_load_cancelled():
	var loader_wrapper = get_node("load_game")
	loader_wrapper.hide()


func _on_load_game_success(filename):
	var loader_wrapper = get_node("load_game")
	loader_wrapper.hide()
	var global_modules = get_tree().get_root().get_node("game_state")
	var err = global_modules.load_game(filename)
	if err != OK:
		var dialog = load("res://bootstrap/gui/error_dialog.gd").new()
		dialog.show_warning(self, "Load Game Failed", "Encountered a problem loading the game: " + ERROR_CODES.to_string(err), null)
		return
