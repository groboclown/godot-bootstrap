# Contains the global modules.

extends Node

var _installed_modules


func _init():
	_installed_modules = preload("res://bootstrap/lib/modules.gd").new()
	_installed_modules.add_extension_point_type("2d", Vector2dType.new())


func scan_modules(root_node):
	var process = load("res://scenes/scan_modules.xscn").instance()
	process.modules = _installed_modules
	root_node.add_child(process)


func get_modules():
	return _installed_modules

func has_modules():
	return _installed_modules != null && ! _installed_modules.get_installed_modules().empty()

func get_invalid_modules():
	if _installed_modules == null:
		return []
	return _installed_modules.get_invalid_modules()

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
