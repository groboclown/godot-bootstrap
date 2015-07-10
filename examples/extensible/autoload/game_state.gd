# Contains the game save state.  Also knows how to perform
# scene transitions, because loading a save game involves
# transitioning to the new scene.

extends Node

var _active_modules
var _save_game_data
var _current_scene
var _invalid_modules


func is_game_active():
	return _save_game_data != null

func is_valid():
	return is_game_active() && _invalid_modules == null

func get_invalid_modules():
	return _invalid_modules

func start_new_game(modules, module_order):
	_save_game_data = null
	_active_modules = modules.create_active_module_list(module_order)
	if ! _active_modules.is_valid():
		_invalid_modules = _active_modules.get_invalid_modules()
		_active_modules = null
		return false
	
	_invalid_modules = null
	_save_game_data = {}
	
	# Initialize the save game data based on the modules.
	_active_modules.get_implementation("init/game-data").exec(_save_game_data)
	
	# first scene based on modules

	load_scene(_active_modules.get_implementation("init/first-scene")[0])



func load_scene(next_scene):
	_current_scene = _active_modules.get_implementation("init/first-scene")[0]
	print("TODO load the scene")
	
	
	