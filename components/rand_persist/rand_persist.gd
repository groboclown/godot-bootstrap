#
# 
#

func rand_int_range(from, to, storage, key):
	var delta = to - from
	return from + (rand_int(storage, key) % delta)

func rand_float_range(from, to, storage, key):
	var delta = to - from
	return from + (rand_float(storage, key) * delta)
    
func rand_float(storage, key):
	# Random float value from 0 to 1
	return min(float(rand_int(storage, key)) / 2147483647.0, 1.0)

func rand_int(storage, key):
	# Random number from 0 to 2147483647
	var seed_val = null
	if storage != null and storage.has(key):
		seed_val = storage[key]
	else:
		seed_val = randf()
	var rv = rand_seed(seed_val)
	if storage != null:
		storage[key] = rv[1]
	return rv[0]
