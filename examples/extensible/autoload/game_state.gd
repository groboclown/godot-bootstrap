# Contains the game save state.  Also knows how to perform
# scene transitions, because loading a save game involves
# transitioning to the new scene.

# Modules are tied with the game state, so those are handled
# here as well.

extends Node

# final fields
var _installed_modules
var _savegames

# game state variables
var _active_modules
var _invalid_modules

var _save_game
var _current_scene

var errors = preload("res://bootstrap/lib/error_codes.gd")

# -------------------------------------------------------
# Constructor

func _init():
	# One time setup.
	_installed_modules = preload("res://bootstrap/lib/modules.gd").new()
	_installed_modules.add_extension_point_type("2d", Vector2dType.new())
	
	# Create our savegame repository using the
	# module set.  Also, define a global, shared
	# space for the modules to share saved data
	# called "$".
	_savegames = preload("res://bootstrap/lib/save_modules.gd").new(_installed_modules, [ "$" ])
	_savegames.settings.do_encryption = false
	_savegames.settings.use_listfile = true

# -------------------------------------------------------
# Save game management


func is_game_active():
	return _save_game != null

func is_game_valid():
	return is_game_active() && _invalid_modules == null

func get_invalid_save_modules():
	if _invalid_modules == null:
		return []
	return _invalid_modules

func start_new_game(name, module_order):
	_save_game = null
	_active_modules = null
	_invalid_modules = null
	_current_scene = null
	
	var result = _savegames.new_savefile(name, module_order)
	_save_game = result[1]
	_active_modules = result[2]
	if _active_modules != null && ! _active_modules.is_valid():
		_invalid_modules = _active_modules.get_invalid_modules()
		_active_modules = null
	if result[0] != OK:
		print("TODO report error: " + errors.to_string(result[0]))
		return false
	
	# Initialize our global data
	replace_data({})
	
	# Special game logic to handle the initialization of
	# the global shared data, as well as the per-module data.
	
	var global_data = get_data()
	_active_modules.get_implementation("init/game-data").create(_save_game, global_data)
	
	# first scene based on modules

	load_scene(_active_modules.get_implementation("init/first-scene")[0])

	return true


func load_game(filename):
	pass


# --------------------------------------------------------
# Current game data

func get_data(module_name=null):
	if is_game_valid():
		if module_name == null:
			module_name = "$"
		return _save_game.get_data_for_module(module_name)
	return null


func replace_data(data, module_name=null):
	if is_game_valid():
		if module_name == null:
			module_name = "$"
		_save_game.replace_data_for_module(module_name, data)


func load_scene(next_scene):
	_current_scene = _active_modules.get_implementation("init/first-scene")[0]
	print("TODO load the scene")


# --------------------------------------------------------
# Module methods


func scan_modules(root_node):
	var process = load("res://scenes/scan_modules.xscn").instance()
	process.modules = _installed_modules
	root_node.add_child(process)


func get_modules():
	return _installed_modules

func has_modules():
	return _installed_modules != null && ! _installed_modules.get_installed_modules().empty()

func get_invalid_installed_modules():
	if _installed_modules == null:
		return []
	return _installed_modules.get_invalid_modules()


# --------------------------------------------------------
# Module extension types

class Vector2dType:
	func validate_call_decl(point):
		return (!("order" in point) || point.order in [ "normal", "reverse" ]) && (point.aggregate in [ "none", "first", "last" ])
	
	
	func validate_implement(point, ms):
		return "point" in point && typeof(point.point) == TYPE_ARRAY && point.point.size() == 2 && typeof(point.point[0]) == TYPE_REAL && typeof(point.point[1]) == TYPE_REAL

	func convert_type(point, ms):
		# Convert the extension point implementation (under the "calls" group)
		# into the expected value.
		return Vector2(point.point[0], point.point[1])

	func aggregate(point, values):
		# Aggregate the list of values from the convert_type return value
		# into a new value.
		if point.order == "reverse":
			values.invert()
		
		if point.aggregate == "none" || point.aggregate == "first":
			return values[0]
		elif point.aggregate == "last":
			return values[values.size() - 1]
		else:
			# invalid
			return null
