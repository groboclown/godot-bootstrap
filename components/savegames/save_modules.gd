

# Allows for using the "modules" component easily with save games.
# Use as a replacement for the "savegames" module.  It augments the
# returned values to include activating the correct modules when a
# game is loaded.

# Adds a new extension point to the modules - "module-data-exec".
# It is similar to the callback extension point, but it provides these
# methods instead of "exec":
# * `update`: update, in-place, the existing data that's in the
#        save game for this specific module.  The called object will
#        take, as arguments, (save game data for module, arg1, arg2, ...)
# * `create`: if no data is associated with the module in the save game
#        (the object is null), only then will the function be called on the
#        module.  No additional argument will be added to the call, but the
#        value returned by the call will be associated as the save data
#        for the module (passed into "update" and "replace" calls).
# * `initialize`: same as `create`, but will always be called, regardless of
#        whether the module already has data or not.
# * `replace`: a combination of `update` and `initialize` - the current data
#        that's stored with the module will be passed as the first argument
#        (followed by the other passed-in arguments), and the returned value
#        will be the new save data for the module.
# In order to use these methods, the first argument you pass in needs to be the
# save game object.

# The settings that control how and where the save games are stored.
# Member variables should be modified directly.
var settings = preload("savegames/metadata_handler.gd").new()


var _module_set
var _module_load_order = ModuleLoadOrderSave.new()
var _savegames = preload("savegames.gd").new()
var non_module_data_modules = []

func _init(module_set, non_module_data_names=null):
	# module_set: instance of /bootstrap/lib/modules
	# non_module_data_names: list of save game "modules" that are not associated
	# 		with the installable modules; used for global game data that is
	#		shared.  If any entry is a non-string, then it is assumed to be
	#		a Module object, supporting the upgrade capability; otherwise, it
	#		will be stored as a module with that name and version 0.
	_module_set = module_set
	_module_set.add_extension_point_type("module-data-exec", CallpointModuleData.new())
	_savegames.settings = settings
	non_module_data_modules = []
	if non_module_data_names != null:
		var mn
		for mn in non_module_data_names:
			if typeof(mn) == TYPE_STRING:
				non_module_data_modules.append(NonModuleSaveDef.new(mn))
			elif mn != null:
				non_module_data_modules.append(mn)


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
	_init_modules()
	return _savegames.get_savegame_infos(reload_cache)


func new_savefile(name, active_module_name_list, progress = null):
	# Returns [ error_code, save_data_obj, active_modules_obj ]
	_savegames.clear_modules()
	var err = _savegames.add_module(_module_load_order)
	if err != OK:
		#print("add module error: " + str(err))
		return [ err, null, null ]
	var active_modules = _module_set.create_active_module_list(active_module_name_list, progress)
	if ! active_modules.is_valid():
		#print("activate modules error")
		return [ ERR_CANT_CREATE, null, active_modules ]
	_module_load_order._module_list = active_module_name_list
	var mod
	for mod in active_modules.get_active_modules():
		err = _savegames.add_module(ModuleSaveDef.new(mod))
		if err != OK:
			#print("add module error: " + str(err))
			return [ err, null, active_modules ]
	for mod in non_module_data_modules:
		err = _savegames.add_module(mod)
		if err != OK:
			#print("add global module error: " + str(err))
			return [ err, null, active_modules ]
	var game_struct = _savegames.new_savefile(name)
	return [ game_struct[0], game_struct[1], active_modules ]


func save_as(new_name, save_obj):
	# Identical to original
	return _savegames.save_as(new_name, save_obj)


func load_savefile(filename):
	# Returns [ error_code, save_data_obj, active_modules_obj ]
	var err = _init_modules()
	if err != OK:
		return [ err, null, null ]
	var game_struct = _savegames.load_savefile(filename)
	if game_struct[0] != OK:
		return [ game_struct[0], null, null ]
	if ! (_module_load_order.name in game_struct[1].get_module_names()):
		# The required module order list is not in the save game.
		return [ ERR_INVALID_DATA, null, null ]
	var active_module_name_list = game_struct[1].get_data_for_module(_module_load_order.name)
	if active_module_name_list == null:
		return [ ERR_INVALID_DATA, null, null ]
	var active_modules = _module_set.create_active_module_list(active_module_name_list, null)
	if active_modules.is_invalid():
		return [ ERR_CANT_CREATE, game_struct[1], active_modules ]
	return [ OK, game_struct[1], active_modules ]


func delete_savefile(filename):
	# Identical to original
	return _savegames.delete_savefile(filename)
	
	
func _init_modules():
	_savegames.clear_modules()
	var err = _savegames.add_module(_module_load_order)
	if err != OK:
		return err
	var mod
	for mod in _module_set.get_installed_modules():
		if mod.error_code == OK:
			err = _savegames.add_module(ModuleSaveDef.new(mod))
			if err != OK:
				return err
	for mod in non_module_data_modules:
		_savegames.add_module(mod)
	return OK

# ----------------------------------------------------------------------------

class ModuleLoadOrderSave:
	var _module_list = []
	var name = "__module_load_order__"
	var version = 1
	
	
	func is_compatible_with(version_number):
		return version == version_number
	
	func create_data():
		return _module_list
	
	func read_data(version, disk_data):
		if typeof(disk_data) != TYPE_ARRAY:
			return [ ERR_FILE_CORRUPT, null ]
		var mod
		for mod in disk_data:
			if typeof(mod) != TYPE_STRING:
				return [ ERR_FILE_CORRUPT, null ]
		_module_list = disk_data
		return [ OK, disk_data ]


class ModuleSaveDef:
	var _module
	var name
	var version
	
	func _init(mod):
		#print("module: "+str(mod))
		_module = mod
		name = mod.name
		version = mod.version[0]
	
	func is_compatible_with(version_number):
		if _module.object != null && _module.object.has_method("is_compatible_with"):
			return _module.object.is_compatible_with(version_number)
		return version == version_number
	
	func create_data():
		if _module.object != null && _module.object.has_method("create_data"):
			return _module.object.create_data()
		return {}
	
	func read_data(version, disk_data):
		if _module.object != null && _module.object.has_method("read_data"):
			return _module.object.read_data(version, disk_data)
		return [ OK, disk_data ]



class NonModuleSaveDef:
	var name
	var version
	
	func _init(mod_name):
		name = mod_name
		version = 0
	
	func is_compatible_with(version_number):
		return version == version_number
	
	func create_data():
		return {}
	
	func read_data(version, disk_data):
		return [ OK, disk_data ]


class CallpointModuleData:
	# Copied mostly from the CallpointCallback.
	class ModExec:
		var _module
		var _name
		var _obj
		
		func _init(module_name, obj, name):
			_module = module_name
			_name = name
			_obj = obj
		
		func update(savegame, arg0 = null, arg1 = null, arg2 = null, arg3 = null, arg4 = null, arg5 = null, arg6 = null, arg7 = null, arg8 = null, arg9 = null):
			var save_data = savegame.get_data_for_module(_module)
			var args = [ save_data, arg0, arg1, arg2, arg3, arg4, arg5, arg6, arg7, arg8, arg9 ]
			for i in range(10, 1, -1):
				if args[i] != null:
					break
				args.resize(i)
			return _obj.callv(_name, args)
		
		func create(savegame, arg0 = null, arg1 = null, arg2 = null, arg3 = null, arg4 = null, arg5 = null, arg6 = null, arg7 = null, arg8 = null, arg9 = null):
			var save_data = savegame.get_data_for_module(_module)
			if save_data != null:
				# Already been created, nothing to do.
				return
			var args = [ arg0, arg1, arg2, arg3, arg4, arg5, arg6, arg7, arg8, arg9 ]
			#print("args: "+str(args))
			for i in range(9, 0, -1):
				if args[i] != null:
					break
				args.resize(i)
			#print("args: "+str(args))
			save_data = _obj.callv(_name, args)
			savegame.replace_data_for_module(_module, save_data)
		
		func initialize(savegame, arg0 = null, arg1 = null, arg2 = null, arg3 = null, arg4 = null, arg5 = null, arg6 = null, arg7 = null, arg8 = null, arg9 = null):
			var args = [ arg0, arg1, arg2, arg3, arg4, arg5, arg6, arg7, arg8, arg9 ]
			for i in range(9, 0, -1):
				if args[i] != null:
					break
				args.resize(i)
			var save_data = _obj.callv(_name, args)
			savegame.replace_data_for_module(_module, save_data)
		
		func replace(savegame, arg0 = null, arg1 = null, arg2 = null, arg3 = null, arg4 = null, arg5 = null, arg6 = null, arg7 = null, arg8 = null, arg9 = null):
			var save_data = savegame.get_data_for_module(_module)
			var args = [ save_data, arg0, arg1, arg2, arg3, arg4, arg5, arg6, arg7, arg8, arg9 ]
			for i in range(10, 1, -1):
				if args[i] != null:
					break
				args.resize(i)
			save_data = _obj.callv(_name, args)
			savegame.replace_data_for_module(_module, save_data)

	
	class Callback:
		var _values
		var _join_type
		
		func _init(values, join_type):
			# Join Type:
			#	0: call each one in-order, return the very last value.
			#   1: call each one in-order, with the result of the previous one as the first argument of the next one
			#      (initial previous value is null)
			#   2: call each one in order, put the result inside a list.
			_values = values
			_join_type = join_type
		
		func update(savegame, arg0 = null, arg1 = null, arg2 = null, arg3 = null, arg4 = null, arg5 = null, arg6 = null, arg7 = null, arg8 = null):
			var prev = null
			if _join_type == 2:
				prev = []
			var v
			for v in _values:
				if _join_type == 0:
					prev = v.update(savegame, arg0, arg1, arg2, arg3, arg4, arg5, arg6, arg7, arg8)
				elif _join_type == 1:
					prev = v.update(prev, savegame, arg0, arg1, arg2, arg3, arg4, arg5, arg6, arg7, arg8)
				elif _join_type == 2:
					prev.append(v.update(savegame, arg0, arg1, arg2, arg3, arg4, arg5, arg6, arg7, arg8))
				else:
					prev = null
			return prev
		
		func create(savegame, arg0 = null, arg1 = null, arg2 = null, arg3 = null, arg4 = null, arg5 = null, arg6 = null, arg7 = null, arg8 = null):
			var v
			for v in _values:
				v.create(savegame, arg0, arg1, arg2, arg3, arg4, arg5, arg6, arg7, arg8)
		
		func initialize(savegame, arg0 = null, arg1 = null, arg2 = null, arg3 = null, arg4 = null, arg5 = null, arg6 = null, arg7 = null, arg8 = null):
			var v
			for v in _values:
				v.initialize(savegame, arg0, arg1, arg2, arg3, arg4, arg5, arg6, arg7, arg8)
		
		func replace(savegame, arg0 = null, arg1 = null, arg2 = null, arg3 = null, arg4 = null, arg5 = null, arg6 = null, arg7 = null, arg8 = null):
			var v
			for v in _values:
				v.replace(savegame, arg0, arg1, arg2, arg3, arg4, arg5, arg6, arg7, arg8)



	func validate_call_decl(point):
		#print("point: " + str(point))
		return (point.aggregate in [ "none", "first", "last", "sequential", "chain", "list" ])

	func validate_implement(point, ms):
		return "function" in point && ms.object != null && ms.object.has_method(point["function"])

	func convert_type(point, ms):
		return ModExec.new(ms.name, ms.object, point['function'])

	func aggregate(point, values):
		if values.empty():
			return null
		if point.aggregate == "none" || point.aggregate == "first":
			return values[0]
		elif point.aggregate == "last":
			return values[values.size() - 1]
		elif point.aggregate == "sequential":
			return Callback.new(values, 0)
		elif point.aggregate == "chain":
			return Callback.new(values, 1)
		elif point.aggregate == "list":
			return Callback.new(values, 2)
		else:
			# invalid
			return null
	