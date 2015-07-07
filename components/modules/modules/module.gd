# Represents a single module.
# Each module can extend this, or just use its own version.  This
# class is here to indicate the expected top-level objects.

var _active_modules


func _init(modules):
	# modules: the "modules" singleton object.  Used for extension point
	# 	invocation.
	_active_modules = modules
