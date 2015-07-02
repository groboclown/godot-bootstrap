# A "progress bar" listener type.  It has some similar API to the "Range"
# UI element, so that the called-objects can use them in the same way.
#
# By default, the "value" will be a straight value between 0 and 1.  If you
# call "set_steps" with a positive value, then the algorithm will
# instead use the "value" as an integer count between 0 and "step_count".
#
# Additionally, child listeners can be created which represent a small sub-set
# of the total range, and translate their full range to the sub-range within the
# parent.


var _min
var _max
var _parent
var _value
var _steps = 0



static func dummy():
	# Create a dummy progress listener, for use with classes that require a
	# listener (for simplicity of code - not littered with null checks),
	# but there isn't a corresponding UI element.
	return new(null, 0, 1)


func _init(parent, min_val = null, max_val = null):
	# Converts the local value (between 0 and 1) to fit within a parent
	# range.  The parent object can either be another progress_listener,
	# or the "Range" UI element.
	
	if parent != null:
		if min_val == null:
			min_val = parent.get_min()
		if max_val == null:
			max_val = parent.get_max()
	else:
		if min_val == null:
			min_val = 0.0
		if max_val == null:
			max_val = 1.0
	
	var n = min(min_val, max_val)
	var x = max(min_val, max_val)
	if parent != null:
		n = max(n, parent.get_min())
		x = min(x, parent.get_max())
	_min = n
	_max = x
	_parent = parent
	_value = 0


func create_child_to(max_val):
	# Creates a new instance of this class, which maps 0 to the current
	# value, and 1 to the "max_val" argument.
	return create_child(get_value(), max_val)


func create_child(min_val, max_val):
	# Creates a new instance of this class, which maps 0 to the "min" argument,
	# and 1 to the "max_val" argument.
	if min_val == null || min_val < get_min():
		min_val = get_min()
	if max_val == null || max_val > get_max():
		max_val = get_max()
	return get_script().new(self, min_val, max_val)


func get_steps():
	return _steps


func set_steps(step_count):
	_steps = int(step_count)


func get_min():
	return 0


func get_max():
	if _steps > 0:
		_steps
	return 1

	
func get_val():
	return get_value()


func get_value():
	if _steps > 0:
		return int(_value * _steps)
	return _value

	
func set_val(value):
	set_value(value)


func set_value(value):
	if _steps > 0:
		# convert to a 0-1 value
		value = float(int(value)) / float(_steps)
	_value = value
	
	# Calculate the parent range value.
	# Because value is essentially a % number, multiplying it by the
	# range gives us that % number within that range.
	if _parent != null:
		var pv = (value * (get_max() - get_min())) + get_min()
		_parent.set_value(pv)
	

