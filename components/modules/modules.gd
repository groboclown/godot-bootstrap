
# Keeps track of the modules installed for the game.  This handles
# the top-level access points to discover all installed modules, and to
# access the active modules.

# At initialization time, it discovers the modules, and reads in their
# meta-data.

var _initialized = false
var _defined_modules = []
var _last_module_paths = []
var _extension_point_types = {
	# built-in types
	"string": CallpointString.new(),
	"path": CallpointPath.new(),
	"callback": CallpointCallback.new()
}
var _loaded = false
var _active_modules = null


const MODULE_LIST_FILENAME = "module-list.txt"

# Duplicated from loader.gd
const MODULE_DESCRIPTION_FILENAME = "module.json"


const ERR_MODULE_NOT_FOUND = 50001


var errors = preload("error_codes.gd")




func get_installed_modules():
	# Returns all the modules that are installed.  Some of these may have
	# an error in their definition.
	return Array(_defined_modules)


func get_installed_module(module_name, min_major_version, max_major_version, allow_errors = false):
	for md in _defined_modules:
		if (allow_errors || md.error_code == OK) && md.name == module_name && md.version[0] >= min_major_version && md.version[0] <= max_major_version:
			return md
	return null


func get_invalid_modules():
	# Returns all the installed modules marked as invalid.
	var ret = []
	var md
	for md in _defined_modules:
		if md.error_code != OK:
			ret.append(md)
	return ret


func create_active_module_list(module_names, progress = null):
	# There can only be one active module list at a time.  This is a limitation
	# with the translation server.
	unload_active_modules()
	_active_modules = OrderedModules.new(self, module_names, progress)
	return _active_modules


func unload_active_modules():
	if _active_modules != null:
		_active_modules.unload()
		_active_modules = null


func add_extension_point_type(type_name, type_obj):
	if type_name == null || typeof(type_name) != TYPE_STRING || type_name in _extension_point_types:
		print("Bad type name: " + str(type_name))
		return
	if type_obj == null || typeof(type_name) != TYPE_OBJECT:
		print("Bad type object: " + str(type_name))
		return
	var mname
	for mname in [ "validate_call_decl", "validate_implement", "convert_type", "aggregate" ]:
		if ! type_obj.has_method(mname):
			print("type " + type_name + " does not implement " + mname)
			return
	_extension_point_types[type_name] = type_obj



# --------------------------------------------------------------------------
# Initialization methods



func initialize(module_paths, progress = null):
	# Finds and loads the installed modules.
	var progress = preload("progress_listener.gd").new(progress)
	if ! _initialized:
		progress.set_value(0.0)
		var cprog = progress.create_child(0.0, 0.95)
		_load_modules(module_paths, cprog)
	progress.set_value(1.0)



func reload_modules(module_paths = null, progress = null):
	unload_active_modules()
	_initialized = false
	_defined_modules = []
	if module_paths == null:
		module_paths = _last_module_paths
		if module_paths == null:
			print("ERROR: did not ever initialize with module paths")
			return
	initialize(module_paths, progress)

# --------------------------------------------------------------------------

func _init():
	errors.add_code(ERR_MODULE_NOT_FOUND, "ERR_MODULE_NOT_FOUND")


func _load_modules(module_paths, progress):
	# Loads the list of modules and information about them.
	# This is intended to run as a background process, and so takes
	# a "progress_listener" or "Range" UI element as an argument.

	if _initialized:
		return
	print("Initializing modules")
	_last_module_paths = module_paths
	
	# Create a child-able progress listener, to allow for flexibility and
	# avoiding null checks.
	progress = preload("progress_listener.gd").new(progress)
	progress.set_value(0.0)
	
	var module_dirs = []
	var path
	var cprog = progress.create_child(0.0, 0.4)
	cprog.set_steps(module_paths.size())
	var index = 0
	for path in module_paths:
		_find_modules_for(path, module_dirs)
		index += 1
		cprog.set_value(index)
	
	cprog = progress.create_child(0.4, 1.0)
	cprog.set_steps(module_dirs.size() * 2)
	index = 0
	var loader = preload("modules/loader.gd").new()
	for mod_dir in module_dirs:
		var config = loader.load_module(mod_dir, _extension_point_types)
		if config.error_code == OK && config.class_object != null:
			# Object creation must be done here, because it takes this object as
			# the first argument.
			#print("creating " + module.classname + " " + str(module.class_object))
			config.object = config.class_object.new(self)
			if config.object == null:
				config.error_code = errors.ERR_MODULE_INVALID_DEFINITION
				config.error_operation = "instance"
				config.error_details = config.classname + ".new()"
		cprog.set_value(index)
		index += 1
		
		_defined_modules.append(config)
		cprog.set_value(index)
		index += 1
	
	_initialized = true
	_loaded = false



func _find_modules_for(path, module_dirs):
	# Load modules that are in the given path.
	# It can also load the modules from a single file to avoid directory
	# scanning.
	if _initialized:
		return
	
	
	var ftest = File.new()
	var f = File.new()
	var err = f.open(path.plus_file(MODULE_LIST_FILENAME), File.READ)
	if err == OK:
		# Read from the file
		while true:
			var line = f.get_line()
			if f.get_error() != OK:
				break
			if line != null:
				var dir_name = path + line.strip_edges()
				if ftest.file_exists(dir_name.plus_file(MODULE_DESCRIPTION_FILENAME)):
					module_dirs.append(dir_name)
				else:
					printerr("Could not find module " + dir_name)
	else:
		# Scan the directory
		var dir = Directory.new()
		dir.open(path)
		dir.list_dir_begin()
		var file_name = dir.get_next()
		while file_name != "" && file_name != null:
			var dir_name = path.plus_file(file_name)
			if ftest.file_exists(dir_name.plus_file(MODULE_DESCRIPTION_FILENAME)):
				module_dirs.append(dir_name)
			file_name = dir.get_next()
		dir.list_dir_end()
	f.close()
	ftest.close()

	
	

# ---------------------------------------------------------------------------


class OrderedModules:
	var _invalid = []
	var _order = []
	var _active = null
	
	func _init(module_obj, module_names, progress):
		# Takes the list of module names, and sets them as the current order of
		# the underlying `_active` object
		
		progress = preload("progress_listener.gd").new(progress)
		progress.set_value(0.0)
		
		var loader = preload("modules/loader.gd").new()
		var order = []
		var name
		for name in module_names:
			var found = false
			var md
			for md in module_obj._defined_modules:
				if md["name"] == name:
					found = true
					order.append(md)
					break
			if ! found:
				md = loader._create_struct("")
				md.error_code = module_obj.ERR_MODULE_NOT_FOUND
				md.error_operation = "order"
				md.error_details = name
				order.append(md)
		
		_active = preload("modules/active.gd")
		_invalid = _active.validate_ordered_modules(order)
		if _invalid.empty():
			_active.set_modules(order)
		else:
			_active.set_modules([])
		
		return _invalid
	

	func get_implementation(extension_point_name):
		if is_valid():
			return _active.get_value_for(extension_point_name)
		return null

		
	func is_valid():
		return _active != null && _invalid.empty()
	
	func is_invalid():
		return ! is_valid()

	func get_invalid_modules():
		# Returns all the active modules marked as invalid.
		return _invalid

	func get_active_modules():
		if _active == null:
			return []
		return _active.get_active_modules()
	
	func unload()
		if _active != null:
			_active._unload_active_modules()
			_active = null


# ---------------------------------------------------------------------------


class CallpointString:
	var val_name = "value"

	func validate_call_decl(point):
		return point.aggregate in [ "none", "first", "last", "list", "set" ]

	func validate_implement(point, ms):
		if ! (val_name in point):
			return false
		if typeof(point[val_name]) == TYPE_STRING:
			return true
		if typeof(point[val_name]) == TYPE_ARRAY:
			var s
			for s in point[val_name]:
				if typeof(s) != TYPE_STRING:
					return false
		return true

	func convert_type(point, ms):
		if typeof(point[val_name]) == TYPE_STRING:
			return [ point[val_name] ]
		return point[val_name]


	func aggregate(point, values):
		values = _join_array_of_arrays(values, point.order)
		
		if point.aggregate == "none" || point.aggregate == "first":
			return values[0]
		elif point.aggregate == "last":
			return values[values.size() - 1]
		elif point.aggregate == "list":
			return values
		elif point.aggregate == "set":
			var ret = {}
			var v
			for v in values:
				ret[v] = true
			return ret.keys()
		else:
			# invalid
			return null


	func _join_array_of_arrays(aoa, order):
		var a
		var b
		var ret = []
		for a in aoa:
			for b in a:
				ret.append(b)
		return _sort(ret, order)


	func _sort(list, order):
		if order == "reverse":
			list.invert()
		elif order == "asc":
			list.sort()
		elif order == "desc":
			list.sort()
			list.invert()
		return list


# ---------------------------------------------------------------------------


class CallpointPath:
	extends CallpointString
	
	func _init():
		val_name = "path"


	func convert_type(point, ms):
		var vals
		if typeof(point.path) == TYPE_STRING:
			vals = [ point.path ]
		else:
			vals = point.path
		var ret = []
		var v
		for v in vals:
			ret.append(ms.dir.plus_file(v))
		return ret


# ---------------------------------------------------------------------------

class CallpointCallback:
	func validate_call_decl(point):
		#print("point: " + str(point))
		return point.aggregate in [ "none", "first", "last", "sequential", "chain" ]

	func validate_implement(point, ms):
		#print("f: " + point["function"] + ", " + ms.classname + ", " + str(ms.object.has_method(point["function"])))
		return "function" in point && ms.object != null && ms.object.has_method(point["function"])

	func convert_type(point, ms):
		return funcref(ms.object, point['function'])

	func aggregate(point, values):
		if point.order == "reverse":
			values.invert()
		
		if point.aggregate == "none" || point.aggregate == "first":
			return values[0]
		elif point.aggregate == "last":
			return values[values.size() - 1]
		elif point.aggregate == "sequential":
			var c = Callback(values, false)
			return funcref(c, "invoke")
		elif point.aggregate == "chain":
			var c = Callback(values, true)
			return funcref(c, "invoke")
		else:
			# invalid
			return null


class Callback:
	var _values
	var _add_result
	
	func _init(values, add_result):
		_values = values
		_add_result = add_result
	
	func invoke(args):
		var prev = null
		var v
		for v in _values:
			if _add_result:
				prev = v.exec(prev, args)
			else:
				prev = v.exec(args)
		return prev
