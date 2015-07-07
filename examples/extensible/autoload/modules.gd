# Contains the global modules.

extends Node

var _installed_modules


func _init():
	_installed_modules = preload("res://bootstrap/lib/modules.gd").new()


func scan_modules(root_node):
	var process = load("res://scenes/scan_modules.xscn").instance()
	process.modules = _installed_modules
	root_node.add_child(process)
