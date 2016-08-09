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

func shuffle(list, storage, key):
	# Randomly shuffle the items within the list,
	# and update the storage seed.  Returns the passed-in list.
	var i
	for i in range(0, list.size() - 1):
		list[i] = rand_int_range(i + 1, list.size(), storage, key)
	return list

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
