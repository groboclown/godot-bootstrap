

# All registered, active modules.  Allows for easy access to extension points.
# All the extension point logic is contained here.

var _callpoints = {}
var _modules = []
var _extension_point_types = {}

const ERR_MODULE_DEPENDENT_MODULE_VERSION = 50005
const ERR_MODULE_DEPENDENT_MODULE_ORDER = 50006
const ERR_MODULE_DEPENDENT_MODULE_NOT_LOADED = 50007
const ERR_MODULE_MISMATCHED_EXTENSION_POINT = 50008
const ERR_MODULE_MISMATCHED_IMPLEMENTATION = 50009
const ERR_MODULE_UNKNOWN_EXTENSION_POINT = 50010

const ACTIVATION_ERROR_START = ERR_MODULE_DEPENDENT_MODULE_VERSION
const ACTIVATION_ERROR_END = ERR_MODULE_UNKNOWN_EXTENSION_POINT

var errors = preload("../error_codes.gd")






func validate_ordered_modules(ordered_module_structs):
	# The modules should already be validated on their own (via the loader
	# and the validate_extensions call).

	var callpoints = {}
	var incorrect_modules = []
	var loaded_modules = []
	var ms

	for ms in ordered_module_structs:
		if ms.error_code >= ACTIVATION_ERROR_START && ms.error_code <= ACTIVATION_ERROR_END:
			# re-validate the module
			ms.error_code = OK
			ms.error_operation = null
			ms.error_details = null
		if ms.error_code != OK:
			incorrect_modules.append(ms)
			continue

		# Required modules - exist and are in the correct order
		var lm
		var req
		for req in ms.requires:
			var found = false
			for lm in loaded_modules:
				if lm.name == req.module:
					found = true
					if lm.version[0] < req["min"] || lm.version[0] > req["max"]:
						ms.error_code = ERR_MODULE_DEPENDENT_MODULE_VERSION
						ms.error_operation = "evaluate-modules"
						ms.error_details = lm.name
						incorrect_modules.append(ms)
					break
			if ! found:
				# See if the required module is even in the list
				for lm in ordered_module_structs:
					if lm.name == req.module:
						found = true
						ms.error_code = ERR_MODULE_DEPENDENT_MODULE_ORDER
						ms.error_operation = "evaluate-modules"
						ms.error_details = lm.name
						incorrect_modules.append(ms)
						break
				if ! found:
					found = true
					ms.error_code = ERR_MODULE_DEPENDENT_MODULE_NOT_LOADED
					ms.error_operation = "evaluate-modules"
					ms.error_details = req.module
					incorrect_modules.append(ms)
				break

		if ms.error_code != OK:
			continue

		# Extension points: if it is already registered, it matches a registered one.
		var cpkey
		for cpkey in ms.extension_points.keys():
			if cpkey in callpoints:
				if ! _validate_callpoint_matches(ms.extension_points[cpkey], callpoints[cpkey]):
					ms.error_code = ERR_MODULE_MISMATCHED_EXTENSION_POINT
					ms.error_operation = "evaluate-modules"
					ms.error_details = cpkey
					incorrect_modules.append(ms)
					break
			else:
				callpoints[cpkey] = ms.extension_points[cpkey]

		if ms.error_code != OK:
			continue

		# Implementation points: the extension is already registered, and they match.
		for cpkey in ms.implement_points.keys():
			if cpkey in callpoints:
				if ! _validate_callpoint_extension(callpoints[cpkey], ms.implement_points[cpkey]):
					ms.error_code = ERR_MODULE_MISMATCHED_IMPLEMENTATION
					ms.error_operation = "evaluate-modules"
					ms.error_details = cpkey
					incorrect_modules.append(ms)
					break
			else:
				ms.error_code = ERR_MODULE_UNKNOWN_EXTENSION_POINT
				ms.error_operation = "evaluate-modules"
				ms.error_details = cpkey
				incorrect_modules.append(ms)
				break

		loaded_modules.append(ms)

	return incorrect_modules



func set_modules(ordered_module_structs):
	# Reset the extension point registration.  The modules should all be
	# validated and valid.
	_unload_active_modules()
	_callpoints = {}
	_modules = ordered_module_structs
	var wrapper = ModuleWrapper.new(self)

	var ms
	var cpkey
	for ms in ordered_module_structs:
		print("Initializing " + ms.name)
		for cpkey in ms.extension_points.keys():
			if ! cpkey in _callpoints:
				_callpoints[cpkey] = {
					"point": ms.extension_points[cpkey],
					"impl": []
				}

		for cpkey in ms.implement_points.keys():
			_callpoints[cpkey].impl.append(ms)

		var xl
		for xl in ms.translations:
			TranslationServer.add_translation(xl)

		if ms.object.has_method("activate") && ms.object.has_method("deactivate"):
			ms.object.activate(wrapper)



func get_value_for(callback_name):
	var ret = []
	if callback_name in _callpoints:
		var type = _callpoints[callback_name].point.type
		var ms
		for ms in _callpoints[callback_name].impl:
			var point = ms.implement_points[callback_name]
			ret.append(_extension_point_types[type].convert_type(point, ms))
		ret = _extension_point_types[type].aggregate(_callpoints[callback_name].point, ret)
	return ret


func get_active_modules():
	return Array(_modules)


func _unload_active_modules():
	if _modules != null:
		var md
		var xl
		for md in _modules:
			for xl in md.translations:
				TranslationServer.remove_translation(xl)
			if md.object.has_method("deactivate"):
				md.object.deactivate()
	_modules = []
	_callpoints = {}


func _validate_callpoint_extension(extend_point, implement_point):
	if extend_point.type != implement_point.type:
		return false
	return true



func _validate_callpoint_matches(left, right):
	return left.type == right.type && left.order == right.order && \
		left.aggregate == right.aggregate
		# not necessary to match, but it should.
		# left.description == right.description


# ---------------------------------------------------------------------------


func _init(extension_point_types):
	errors.add_code(ERR_MODULE_DEPENDENT_MODULE_VERSION, "ERR_MODULE_DEPENDENT_MODULE_VERSION")
	errors.add_code(ERR_MODULE_DEPENDENT_MODULE_ORDER, "ERR_MODULE_DEPENDENT_MODULE_ORDER")
	errors.add_code(ERR_MODULE_DEPENDENT_MODULE_NOT_LOADED, "ERR_MODULE_DEPENDENT_MODULE_NOT_LOADED")
	errors.add_code(ERR_MODULE_MISMATCHED_EXTENSION_POINT, "ERR_MODULE_MISMATCHED_EXTENSION_POINT")
	errors.add_code(ERR_MODULE_MISMATCHED_IMPLEMENTATION, "ERR_MODULE_MISMATCHED_IMPLEMENTATION")
	errors.add_code(ERR_MODULE_UNKNOWN_EXTENSION_POINT, "ERR_MODULE_UNKNOWN_EXTENSION_POINT")

	var key
	for key in extension_point_types.keys():
		_extension_point_types[key] = extension_point_types[key]


class ModuleWrapper:
	var _active

	func _init(active):
		_active = active

	func get_implementation(extension_point_name):
		return _active.get_value_for(extension_point_name)
