
# Stores information that's global to all save games.
# It also is the gateway between the individual save data and the save system
# front-end.

# A "module" is an object with the following attributes:
#   "name": String (ro)
#   "version": int (ro)
#   "is_compatible_with": func(version_number):bool
#   "create_data": func(raw_data):Variant
#   "read_data": func(version, disk_data):[ ErrorCode, Variant ]

# Public variables.  Note possible bug when creating the directory.
var savedir = "user://"
var listfile_name = "saves.list"
var do_encryption = false
var encryption_key = OS.get_unique_ID()
var use_listfile = false

# Metadata about the save game.
var _saves = null

# Active modules that the system registers as usable.
var _modules = {}


func get_saves_info():
	var ret = []
	var key
	for key in _saves.keys():
		ret.append(_saves[key])
	return ret

func discover_saves(reload_cache = false):
	# Searches for the saves, and caches the results.  If the save files have
	# already been loaded, then the cache will only be reloaded if the
	# `reload_cache` argument is true.
	# Returns the error code.
	if ! reload_cache && _saves != null:
		return OK
	if use_listfile:
		var f = File.new()
		if ! f.file_exists(savedir.plus_file(listfile_name)):
			# okay if the file doesn't exist.  It means there haven't
			# been any saves yet.
			_saves = {}
			return OK
		var err = f.open(savedir.plus_file(listfile_name), File.READ)
		if err != OK:
			return err
		var text = f.get_as_text()
		err = f.get_error()
		if err != OK && err != ERR_FILE_EOF:
			return err
		f.close()
		_saves = {}
		err = _saves.parse_json(text)
		if err != OK:
			_saves = null
			return err
		return err
	else:
		# Scan the directory
		_saves = {}
		var dir = Directory.new()
		dir.open(savedir)
		dir.list_dir_begin()
		var file_name = dir.get_next()
		while file_name != "" && file_name != null:
			if file_name.right(file_name.length() - 4) == '.sav':
				var info = preload("save_data.gd").new(self)
				var full_name = savedir.plus_file(file_name)
				var err = info.from_existing(full_name)
				if err == OK:
					_saves[file_name] = info.get_header()
				else:
					# TODO report which file had the problem
					pass
					# But we DO NOT just give up.  We have an invalid save file,
					# and that won't be included in our list of valid saves.
					# dir.list_dir_end()
					# return err
					print("Ignoring save file " + full_name + " " + str(err))
			file_name = dir.get_next()
		dir.list_dir_end()
		return OK



func delete_save(filename):
	var fullname = savedir.plus_file(filename)
	var d = Directory.new()
	if ! d.file_exists(fullname):
		# work-around for directory class bug
		var f = File.new()
		if ! f.file_exists(fullname):
			print("could not find "+fullname)
			return ERR_FILE_NOT_FOUND
	var error_code = d.remove(fullname)
	if error_code != OK:
		return error_code
	# Reload the list file before we save it.
	if use_listfile:
		error_code = discover_saves(true)
		if error_code != OK:
			return error_code
	if _saves != null:
		_saves.erase(filename)
	return save_listfile()



# ----------------------------------------------------------------------------
# Setup functions



func add_module(module_info):
	_modules[module_info.name] = module_info


func remove_module(module_name):
	if module_name in _modules:
		_modules.erase(module_name)


func clear_modules():
	_modules = {}


# ---------------------------------------------------------------------------
# Used by save_data.gd


func get_module_defs():
	return _modules


func open_file(filename, mode):
	# Returns the file object (opened for reading).
	# It should be queried for an error before using (.get_error()).

	#if ! (filename in _saves):
	#   # An unknown save file
	#   return FakeFile.new(ERR_CANT_OPEN)

	var err = _ensure_savedir_exists()
	if err != OK:
		return FakeFile.new(err)
	var file_path = filename
	# TODO ensure that this is only ever called just one way, so that this
	# check isn't needed.
	if file_path.find("://") < 0:
		file_path = savedir.plus_file(filename)

	var f = File.new()
	if do_encryption && encryption_key != null:
		err = f.open_encrypted_with_pass(file_path, mode, encryption_key)
		#print("open encrypted "+file_path+"/"+str(mode)+"/"+str(encryption_key))
	else:
		err = f.open(file_path, mode)
		#print("open normal "+file_path+"/"+str(mode))
	#print("error on open? " + str(err))
	if err != OK:
		return FakeFile.new(err)
	return f


func validate_modules(module_defs):
	# Validates whether the module metadata definition is valid, which
	# is a dictionary of module name (String) to version number (int).
	var mod_name
	for mod_name in module_defs.keys():
		if ! (mod_name in _modules):
			return ERR_DOES_NOT_EXIST
		if ! _modules[mod_name].is_compatible_with(module_defs[mod_name]):
			return ERR_LINK_FAILED
	return OK


func read_saved_data(module_name, module_saved_data):
	# Translates the saved version of the data into a usable form of the data.
	# Should include validation of the data.
	# Returned value is an array, [ error code, actual data ].
	if typeof(module_saved_data) != TYPE_ARRAY || module_saved_data.size() != 2 || typeof(module_saved_data[0]) != TYPE_INT:
		return [ ERR_FILE_CORRUPT, null ]
	if ! (module_name in _modules):
		return [ ERR_DOES_NOT_EXIST, null ]
	if ! _modules[module_name].is_compatible_with(module_saved_data[0]):
		return [ ERR_LINK_FAILED, null ]
	return _modules[module_name].read_data(module_saved_data[0], module_saved_data[1])


func create_saved_data(module_name, module_data):
	# Translates the usable form of the data into a saved version of the data.
	# Internally (which doesn't need to be known by the caller), the saved
	# data includes the version number that was saved.
	return [ _modules[module_name].version, _modules[module_name].create_data(module_data) ]


func close_file(filename, mode):
	# update the list file
	if mode == File.WRITE:
		# TODO update _saves time/date.
		if use_listfile:
			return save_listfile()
	return OK



func new_save(save_name):
	# Creates a new entry for a save file.  Returns the new filename.
	if _saves == null:
		var err = discover_saves()
		if err != OK:
			return null

	# Find the new filename
	var i = -1
	var fname
	var invalid = true
	var testf = File.new()
	while true:
		i = i + 1
		fname = "save" + str(i) + ".sav"
		if fname in _saves:
			continue
		var file_path = savedir.plus_file(fname)
		if testf.file_exists(fname):
			continue
		break

	_saves[fname] = {
		"file": fname,
		"name": save_name,
		"time": OS.get_time(),
		"date": OS.get_date()
	}
	if use_listfile:
		save_listfile()
	return _saves[fname]



# -----------------------------------------------------------------------------

func save_listfile():
	if use_listfile:
		var err = _ensure_savedir_exists()
		if err != OK:
			return err
		# TODO save the list file
		var f = File.new()
		err = f.open(savedir.plus_file(listfile_name), File.WRITE)
		if err != OK:
			return err
		f.store_string(_saves.to_json())
		err = f.get_error()
		f.close()
		return err
	else:
		return OK


func _ensure_savedir_exists():
	var dtest = Directory.new()
	var err
	if ! _dir_exists(savedir):
		err = dtest.make_dir_recursive(savedir)
		if err != OK:
			print("Failed creating directory " + savedir)
			return err
	return OK

# Work-around for https://github.com/okamstudio/godot/issues/791
func _dir_exists(dirname):
	var d = Directory.new()
	if d.dir_exists(dirname):
		return true
	var p = dirname.get_base_dir()
	if p == dirname:
		# root
		return true
	var f = dirname.get_file()
	d.open(p)
	if d.dir_exists(f) || d.file_exists(f):
		return true
	# should be able to find it with list_dir
	return false


class FakeFile:
	var error

	func _init(err):
		error = err

	func get_error():
		return error

	func close():
		pass

