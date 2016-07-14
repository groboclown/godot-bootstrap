
# Handles loading modules and ensuring that they are valid.



const MODULE_DESCRIPTION_FILENAME = "module.json"

const ERR_JSON_FORMAT = 10001
const ERR_MODULE_INVALID_DEFINITION = 50002
const ERR_MODULE_INVALID_EXTENSION_POINT = 50003
const ERR_MODULE_INVALID_IMPLEMENTATION_POINT = 50004


var errors = preload("../error_codes.gd")


func load_module(module_dir, extension_points, safe_path = true):
	# Load the details for a single module based in the given directory.
	# The returned structure will be a dictionary with information about
	# the module, including any errors encountered with the load.  It will
	# not return null.

	# "safe_path": allow for some modules to be marked as "safe" for loading
	# executable code.  This helps prevent modules from accessing OS.exec,
	# for example.

	var ret = _create_struct(module_dir)

	var f = File.new()
	var json_path = module_dir + "/" + MODULE_DESCRIPTION_FILENAME
	var err = f.open(json_path, File.READ)

	if err != OK:
		ret.error_code = err
		ret.error_operation = "open"
		ret.error_details = json_path
		printerr("Could not open module " + str(module_dir) + ": no " + MODULE_DESCRIPTION_FILENAME + " present (" + str(err) + ")")
		f.close()
		return ret

	var contents = f.get_as_text()
	err = f.get_error()
	if err != OK && err != ERR_FILE_EOF:
		ret.error_code = err
		ret.error_operation = "read"
		ret.error_details = json_path
		printerr("Could not read module " + str(module_dir) + " (" + str(err) + ")")
		f.close()
		return ret

	f.close()
	err = f.get_error()
	if err != OK && err != ERR_FILE_EOF && err != ERR_UNCONFIGURED:
		ret.error_code = err
		ret.error_operation = "close"
		ret.error_details = json_path
		printerr("Could not close module " + str(module_dir) + " (" + str(err) + ")")
		return ret

	# If the JSON data is badly formatted, then this will cause a console
	# error, but we won't be able to detect the error from the code.
	# The best we can manage is detecting an empty set after loading.
	var metadata = {}
	err = metadata.parse_json(contents)
	if err != OK:
		ret.error_code = ERR_JSON_FORMAT
		ret.error_operation = "close"
		ret.error_details = json_path
		printerr("Could not parse module file " + str(json_path) + ": " + errors.to_str(err))
		return ret


	_process_module(ret, metadata, extension_points, safe_path)
	#print(str(ret))
	return ret


func _process_module(module, md, extension_points, safe_path):
	# Processes a loaded module data structure to ensure its validity, and to
	# extract data from the json file into a usable form.

	# This essentially sanitizes the input data for other parts of the system
	# to use.

	if ! ("name" in md) || typeof(md.name) != TYPE_STRING:
		module.error_code = ERR_MODULE_INVALID_DEFINITION
		module.error_operation = "process"
		module.error_details = "name"
		return
	print("Initializing " + md.name)
	module.name = md.name

	if ! ("version" in md) || typeof(md.version) != TYPE_ARRAY || md.version.size() != 2 || \
			(typeof(md.version[0]) != TYPE_INT && typeof(md.version[0]) != TYPE_REAL) || \
			(typeof(md.version[1]) != TYPE_INT && typeof(md.version[1]) != TYPE_REAL):
		#if "version" in md && typeof(md.version) == TYPE_ARRAY:
		#   print("version: " + str(md.version.size()) + "; " + str(md.version))
		module.error_code = ERR_MODULE_INVALID_DEFINITION
		module.error_operation = "process"
		module.error_details = "version"
		return
	module.version = [ int(md.version[0]), int(md.version[1]) ]

	if "description" in md:
		if typeof(md.description) != TYPE_STRING:
			module.error_code = ERR_MODULE_INVALID_DEFINITION
			module.error_operation = "process"
			module.error_details = "description"
			return
		module.description = md.description

	if safe_path and "classname" in md:
		if typeof(md.classname) != TYPE_STRING || md.classname.find("/") >= 0:
			module.error_code = ERR_MODULE_INVALID_DEFINITION
			module.error_operation = "process"
			module.error_details = "classname"
			return
		module.classname = module.dir + "/" + md.classname
	module.class_object = load(module.classname)
	if module.class_object == null:
		module.error_code = ERR_MODULE_INVALID_DEFINITION
		module.error_operation = "process"
		module.error_details = "classname"
		return
	module.object = module.class_object.new()
	if module.object == null:
		module.error_code = ERR_MODULE_INVALID_DEFINITION
		module.error_operation = "process"
		module.error_details = "classname.new"
		return



	if "translations" in md:
		if typeof(md.translations) != TYPE_ARRAY:
			module.error_code = ERR_MODULE_INVALID_DEFINITION
			module.error_operation = "process"
			module.error_details = "translations"
			return
		var tname
		for tname in md.translations:
			if typeof(tname) != TYPE_STRING:
				module.error_code = ERR_MODULE_INVALID_DEFINITION
				module.error_operation = "process"
				module.error_details = "translations[" + str(tname) + "]"
				return
			var tpath = module.dir + "/" + tname
			var xl = load(tpath)
			if xl == null:
				module.error_code = ERR_MODULE_INVALID_DEFINITION
				module.error_operation = "import"
				module.error_details = tpath
				return
			elif ! xl extends Translation:
				module.error_code = ERR_MODULE_INVALID_DEFINITION
				module.error_operation = "process"
				module.error_details = tpath
				return
			else:
				module.translations.append(xl)



	if "requires" in md:
		if typeof(md.requires) != TYPE_ARRAY:
			module.error_code = ERR_MODULE_INVALID_DEFINITION
			module.error_operation = "process"
			module.error_details = "requires"
			return
		var req
		var index = 0
		for req in md.requires:
			if typeof(req) != TYPE_DICTIONARY || \
					! ("module" in req) || \
					typeof(req.module) != TYPE_STRING:
				module.error_code = ERR_MODULE_INVALID_DEFINITION
				module.error_operation = "process"
				module.error_details = "requires[" + str(index) + "]"
				return
			var r = {
				"module": req.module,
				"min": 0,
				"max": 2147483646
			}
			if "min" in req:
				if typeof(req["min"]) != TYPE_INT && typeof(req["min"]) != TYPE_REAL:
					module.error_code = ERR_MODULE_INVALID_DEFINITION
					module.error_operation = "process"
					module.error_details = "requires[" + str(index) + "][min]"
					return
				r["min"] = int(req["min"])
			if "max" in req:
				if typeof(req["max"]) != TYPE_INT && typeof(req["max"]) != TYPE_REAL:
					module.error_code = ERR_MODULE_INVALID_DEFINITION
					module.error_operation = "process"
					module.error_details = "requires[" + str(index) + "][max]"
					return
				r["max"] = int(req["max"])
			module.requires.append(r)
			index += 1


	if "calls" in md:
		#print(md.name + ": " + str(md.calls))
		if typeof(md.calls) != TYPE_DICTIONARY:
			module.error_code = ERR_MODULE_INVALID_DEFINITION
			module.error_operation = "process"
			module.error_details = "calls"
			return
		var key
		for key in md.calls.keys():
			var val = md.calls[key]
			if typeof(key) != TYPE_STRING || typeof(val) != TYPE_DICTIONARY:
				module.error_code = ERR_MODULE_INVALID_DEFINITION
				module.error_operation = "process"
				module.error_details = "calls[" + str(key) + "]"
				return

			# required values
			if "description" in val && typeof(val.description) == TYPE_STRING && \
					"type" in val && typeof(val.type) == TYPE_STRING:
				if "aggregate" in val:
					if typeof(val.aggregate) != TYPE_STRING:
						module.error_code = ERR_MODULE_INVALID_DEFINITION
						module.error_operation = "process"
						module.error_details = "calls[" + str(key) + "][aggregate]"
						return
				else:
					val["aggregate"] = "none"

				if "order" in val:
					if typeof(val.order) != TYPE_STRING:
						module.error_code = ERR_MODULE_INVALID_DEFINITION
						module.error_operation = "process"
						module.error_details = "calls[" + str(key) + "][order]"
						return
				else:
					val["order"] = "normal"

			else:
				module.error_code = ERR_MODULE_INVALID_DEFINITION
				module.error_operation = "process"
				module.error_details = "calls[" + str(key) + "]"
				return

			if ! (val.type in extension_points):
				module.error_code = ERR_MODULE_INVALID_EXTENSION_POINT
				module.error_operation = "process"
				module.error_details = "calls[" + key + "]"
				return
			if ! extension_points[val.type].validate_call_decl(val):
				module.error_code = ERR_MODULE_INVALID_EXTENSION_POINT
				module.error_operation = "process"
				module.error_details = "calls[" + key + "]"
				return

			#print(" - " + key)

			module.extension_points[key] = {
				"description": val.description,
				"type": val.type,
				"aggregate": val.aggregate,
				"order": val.order
			}
	#else:
	#   print("!!! no 'calls' in " + str(md))


	if "implements" in md:
		if typeof(md.implements) != TYPE_DICTIONARY:
			module.error_code = ERR_MODULE_INVALID_DEFINITION
			module.error_operation = "process"
			module.error_details = "implements"
			return
		var key
		for key in md.implements.keys():
			var val = md.implements[key]

			if typeof(key) != TYPE_STRING || typeof(val) != TYPE_DICTIONARY:
				module.error_code = ERR_MODULE_INVALID_DEFINITION
				module.error_operation = "process"
				module.error_details = "implements[" + str(key) + "]"
				return

			# required values
			if ! ("type" in val) || typeof(val.type) != TYPE_STRING:
				module.error_code = ERR_MODULE_INVALID_DEFINITION
				module.error_operation = "process"
				module.error_details = "implements[" + str(key) + "][type]"
				return

			if ! (val.type in extension_points):
				module.error_code = ERR_MODULE_INVALID_IMPLEMENTATION_POINT
				module.error_operation = "process"
				module.error_details = "implements[" + str(key) + "][!type]"
				return
			if ! extension_points[val.type].validate_implement(val, module):
				module.error_code = ERR_MODULE_INVALID_IMPLEMENTATION_POINT
				module.error_operation = "process"
				module.error_details = "implements[" + str(key) + "][type]"
				return

			module.implement_points[key] = { "type": val.type }

			var k2
			for k2 in val.keys():
				if k2 in module.implement_points[key]:
					continue
				if typeof(k2) != TYPE_STRING || val[k2] == null:
					# All we can ensure is that the keys are strings and the values
					# are non-null.  Everything else is done in the extension
					# point validation.
					module.error_code = ERR_MODULE_INVALID_DEFINITION
					module.error_operation = "process"
					module.error_details = "implements[" + str(key) + "][" + str(k2) + "]"
					return

				module.implement_points[key][k2] = val[k2]

	#print("md: " + str(md) + "; module: " + str(module))


func _init():
	errors.add_code(ERR_JSON_FORMAT, "ERR_JSON_FORMAT")
	errors.add_code(ERR_MODULE_INVALID_DEFINITION, "ERR_MODULE_INVALID_DEFINITION")
	errors.add_code(ERR_MODULE_INVALID_EXTENSION_POINT, "ERR_MODULE_INVALID_EXTENSION_POINT")
	errors.add_code(ERR_MODULE_INVALID_IMPLEMENTATION_POINT, "ERR_MODULE_INVALID_IMPLEMENTATION_POINT")



func _create_struct(module_dir):
	return {
		# Sanitized input
		"dir": module_dir,
		"name": module_dir.get_file(),
		"raw_name": module_dir.get_file(),
		"version": [ 0, 0 ],
		"description": "",
		"classname": "res://bootstrap/lib/modules/module.gd",
		"error_code": OK,
		"error_operation": null,
		"error_details": null,
		"translations": [],
		"requires": [],
		"extension_points": {},
		"implement_points": {},
		"class_object": null,
		"object": null
	}

