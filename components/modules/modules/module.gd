# Represents a single module.
# Each module can extend this, or just use its own version.  This
# class is here to indicate the expected top-level objects.

var _extpoints


func activate(extpoints):
	# optional method.  Called when the module is added into an active
	# module list.
	# modules: the "modules" singleton object.  Used for extension point
	# 	invocation.
	_extpoints = extpoints

func deactivate():
	# optional method, but required in order for activate to run.
	_extpoints = null
