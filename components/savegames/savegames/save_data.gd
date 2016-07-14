

# A single save game.

# Save games have a minimal header section, which can be read independent
# of the rest of the file.  This allows for quick scanning of saved games.
# The rest of the file is split by "module" group.  These "module" groups
# are just a way of compartmentalizing the data, and for versioning them
# (so that loading a saved game from an earlier build can still work
# correctly).



var _metadata_handler
var _filename = null

# Header data
var _module_metadata = null
var _name = null
var _savetime = null
var _savedate = null

# Module data
var _data = null


const MAGIC_NUMBER = 3735928559


func _init(metadata_handler):
	_metadata_handler = metadata_handler


func is_loaded():
	return _data != null


func get_header():
	# Gets the hader information.  If the header hasn't been loaded, or it
	# hasn't ever been setup, then it returns null.
	if _savetime == null:
		return null
	return {
		"name": _name,
		"file": _filename,
		"time": _savetime,
		"date": _savedate
	}


func get_module_names():
	return _module_metadata.keys()


func is_initialized():
	return _filename != null


# -----------------------------------------------------------------------------
# Setup

func create_new(save_name):
	if is_initialized():
		return ERR_ALREADY_IN_USE
	var md = _metadata_handler.new_save(save_name)
	if md == null:
		return ERR_FILE_CANT_OPEN
	_module_metadata = _metadata_handler.get_module_defs()
	_filename = md.file
	_name = md.name
	_savetime = md.time
	_savedate = md.date
	_data = {}
	return write_data()


func from_existing(filename, load_all_data = false):
	if is_initialized():
		return ERR_ALREADY_IN_USE
	_filename = filename
	if load_all_data:
		return load_data()
	else:
		return load_header()


# -----------------------------------------------------------------------------
# Save / Load

func load_header():
	# Load just the header data from the file.
	var f = _metadata_handler.open_file(_filename, File.READ)
	var err = _read_header(f)

	f.close()
	_metadata_handler.close_file(_filename, File.READ)

	return err


func load_data():
	# Load all of the data in the file.
	var f = _metadata_handler.open_file(_filename, File.READ)
	var err = _read_header(f)
	if err != OK:
		err = _read_data(f)

	f.close()
	_metadata_handler.close_file(_filename, File.READ)

	return err


func write_data():
	var f = _metadata_handler.open_file(_filename, File.WRITE)
	var err = _write_header(f)
	if err == OK:
		err = _write_data(f)

	f.close()
	_metadata_handler.close_file(_filename, File.WRITE)

	return err


# ----------------------------------------------------------------------------
# Module data

func get_stored_modules():
	return _module_metadata


func get_data_for_module(module_name):
	if module_name in _data:
		return _data[module_name]
	return null


func replace_data_for_module(module_name, data):
	if module_name in _module_metadata:
		_data[module_name] = data




# ----------------------------------------------------------------------------
#

func _write_header(f):
	if f.get_error() != OK:
		return f.get_error()

	f.store_32(MAGIC_NUMBER)
	if f.get_error() != OK:
		return f.get_error()

	var mod_md = []
	var mod
	for mod in _module_metadata.keys():
		mod_md.append([ mod, _module_metadata[mod] ])

	var header_data = {
		"d": _savedate["day"],
		"M": _savedate["month"],
		"Y": _savedate["year"],
		"Z": _savedate["dst"],
		"H": _savetime["hour"],
		"m": _savetime["minute"],
		"s": _savetime["second"],
		"n": _name,
		"o": mod_md
	}

	f.store_var(header_data)
	if f.get_error() != OK:
		return f.get_error()

	return OK



func _read_header(f):
	# Caller must close the file.

	if f.get_error() != OK:
		return f.get_error()
	var magic = f.get_32()
	if f.get_error() != OK:
		return f.get_error()
	if magic != MAGIC_NUMBER:
		return ERR_FILE_UNRECOGNIZED

	var header_data = f.get_var()
	if f.get_error() != OK && f.get_error() != ERR_FILE_EOF:
		return f.get_error()
	if header_data == null || typeof(header_data) != TYPE_DICTIONARY:
		return ERR_FILE_CORRUPT

	var date = {}
	var time = {}
	var name = null
	var module_metadata = {}

	if "d" in header_data && typeof(header_data["d"]) == TYPE_REAL:
		date["day"] = int(header_data["d"])
	else:
		return ERR_FILE_CORRUPT
	if "M" in header_data && typeof(header_data["M"]) == TYPE_REAL:
		date["month"] = int(header_data["M"])
	else:
		return ERR_FILE_CORRUPT
	if "Y" in header_data && typeof(header_data["Y"]) == TYPE_REAL:
		date["year"] = int(header_data["Y"])
	else:
		return ERR_FILE_CORRUPT
	if "Z" in header_data && typeof(header_data["Z"]) == TYPE_BOOL:
		date["dst"] = header_data["Z"]
	else:
		return ERR_FILE_CORRUPT
	if "H" in header_data && typeof(header_data["H"]) == TYPE_REAL:
		time["hour"] = int(header_data["H"])
	else:
		return ERR_FILE_CORRUPT
	if "m" in header_data && typeof(header_data["m"]) == TYPE_REAL:
		time["minute"] = int(header_data["m"])
	else:
		return ERR_FILE_CORRUPT
	if "s" in header_data && typeof(header_data["s"]) == TYPE_REAL:
		time["second"] = int(header_data["s"])
	else:
		return ERR_FILE_CORRUPT
	if "n" in header_data && typeof(header_data["n"]) == TYPE_STRING:
		name = header_data["n"]
	else:
		return ERR_FILE_CORRUPT
	if "o" in header_data && typeof(header_data["o"]) == TYPE_ARRAY:
		var mod
		for mod in header_data["o"]:
			if typeof(mod) == TYPE_ARRAY && mod.size() == 2 && typeof(mod[0]) == TYPE_STRING && typeof(mod[1]) == TYPE_REAL:
				module_metadata[mod[0]] = int(mod[1])
			else:
				return ERR_FILE_CORRUPT

	# Header is now read and mostly validated.

	var err = _metadata_handler.validate_modules(module_metadata)
	if err != OK:
		return err

	# Header is fully validated

	_module_metadata = module_metadata
	_name = name
	_savetime = time
	_savedate = date

	return OK



# ----------------------------------------------------------------------------
#

func _write_data(f):
	# Caller must close the file.

	if _data == null:
		return ERR_INVALID_DATA

	if f.get_error() != OK:
		return f.get_error()

	var modname
	for modname in _module_metadata.keys():
		if modname in _data:
			var val = [ modname,
				_metadata_handler.create_saved_data(modname, _data[modname]) ]
			f.store_var(val)
			if f.get_error() != OK:
				return f.get_error()
	return OK


func _read_data(f):
	# Caller must close the file.

	if f.get_error() != OK:
		return f.get_error()

	var data = {}
	while f.get_error() == OK:
		var r = f.get_var()
		if f.get_error() != OK && f.get_error() != ERR_FILE_EOF:
			break
		if r == null || typeof(r) != TYPE_ARRAY || r.size() != 2 || typeof(r[0]) != TYPE_STRING:
			return ERR_FILE_CORRUPT
		var x = _metadata_handler.read_saved_data(r[0], r[1])
		if x[0] != OK:
			return x[0]
		data[r.m] = x[1]

	# All the data is read and validated.  The data should also be upgraded
	# to the current version of the module data.



	if f.get_error() == ERR_FILE_EOF:
		return OK
	return f.get_error()

