#
# 
#

extends Object

var seed = null

var _rand_persist = load("rand_persist.gd")

func _init(seed_val = null)
	if seed != null:
		seed = seed_val
	else:
		seed = randf()

func rand_int_range(from, to):
	return _rand_persist.rand_int_range(from, to, self, "_seed")

func rand_float_range(from, to):
	return _rand_persist.rand_float_range(from, to, self, "_seed")
    
func rand_float():
	return _rand_persist.rand_float(self, "_seed")

func rand_int():
	return _rand_persist.rand_int(self, "_seed")
