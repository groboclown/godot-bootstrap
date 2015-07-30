
# Save game handler.  Should be made as a member of an autoloaded Node.
# 
# 

# The settings that control how and where the save games are stored.
# Member variables should be modified directly.
var settings = preload("savegames/metadata_handler.gd").new()

var _modules = {}


# ---------------------------------------------------------------------------
# Initialization methods.

func add_module(module):
	# Add a module that stores its associated save data.  Only one module
	# with a given name can exist.
	# Returns `OK` if the module is not already registered,
	# else an error code is returned.
	#
	# A "module" is an object with the following attributes:
	#	"name": String (ro)
	#	"version": int (ro)
	#	"is_compatible_with": func(version_number):bool
	#	"create_data": func(raw_data):Variant
	#	"read_data": func(version, disk_data):[ ErrorCode, Variant ]
	if module.name in _modules:
		return ERR_ALREADY_IN_USE
	_modules[module.name] = module
	settings.add_module(module)
	return OK


func clear_modules():
	settings.clear_modules()
	_modules = {}
	

# ---------------------------------------------------------------------------
# Save game listing

func get_savegame_infos(reload_cache=false):
	# Get the list of all the saved games' information (not the full data).
	# Returns [ error_code, game_header_list ].
	# 
	# A game info is a dictionary that contains these elements:
	#   {
	#     "file": file name (relative to the save directory; auto-generated and unique),
	#     "name": save name (provided by callers),
	#     "time": OS.get_time() for when the game was saved,
	#     "date": OS.get_date() for when the game was saved
	#   }
	var error_code = settings.discover_saves(reload_cache)
	if error_code != OK:
		return [ error_code, [] ]
	var save_headers = settings.get_saves_info()
	return [ OK, save_headers ]


func get_savegame_infos_named(name, reload_cache=false):
	# Returns all the saved games' info which have the given name.
	# If there are no saved games with the given name, then an empty list is
	# returned.
	# Returns [ error_code, game_header_list ]
	var save_ret = get_savegame_infos(reload_cache)
	if save_ret[0] != OK:
		return [ save_ret[0], [] ]
	var ret = []
	var sinfo
	for sinfo in save_ret[0]:
		if sinfo.name == name:
			ret.append(sinfo)
	return [ OK, ret ]


# ---------------------------------------------------------------------------
# Save game management

func new_savefile(name):
	# Create a new save game with the given name.
	# Returns [ error_code, save_data obj ]
	var ret = preload("savegames/save_data.gd").new(settings)
	var error_code = ret.create_new(name)
	# creating the new game will also save it for us.
	if error_code != OK:
		ret = null
	return [ error_code, ret ]

	
func save_as(new_name, save_obj):
	# Save as a new game (possibly under the same name).
	# Returns [ error_code, save_data obj ]
	if ! save_obj.is_initialized():
		return [ ERR_CANT_AQUIRE_RESOURCE, null ]
	var ret_vals = new_save(new_name)
	if ret_vals[0] != OK:
		return [ ret_vals[0], null ]
	
	# Note that we store the data in the new save game modules.
	var mod
	for mod in ret_vals[1].get_stored_modules():
		ret_vals[1].store_data_for_module(mod.name, save_obj.get_data_for_module(mod.name))
	
	# Write the data out to disk
	ret_vals[0] = ret_vals[1].write_data()
	if ret_vals[0] != OK:
		ret_vals[1] = null
	return ret_vals
	

func load_savefile(filename):
	# Loads the save game data from the file with the given (relative)
	# file name.  The file name should be taken from the `get_savegame_infos()`
	# method.
	# Returns [ error_code, save_data obj ]
	var ret = preload("savegames/save_data.gd").new(settings)
	var error_code = ret.from_existing(filename, true)
	if error_code != OK:
		ret = null
	return [ error_code, ret ]


func delete_savefile(filename):
	# Deletes the given save game.
	# Returns the error code.
	return settings.delete_save(filename)

