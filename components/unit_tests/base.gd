# base test class

#extends Object

var _results = {}
var _current = null
var _error_count = 0
var _tests = []
var filename = "<unknown>"

func class_setup():
	pass


func class_teardown():
	pass


func setup():
	pass


func teardown():
	pass


# ------------------------------------------------------------------------


func add(test_name):
	_tests.append(test_name)


func add_all(all_tests):
	var t
	for t in all_tests:
		add(t)


# ------------------------------------------------------------------------


func check_true(text, bool_val):
	if ! bool_val:
		_current["errors"].append(text)
		printerr(_current["name"] + ": " + text)
		print_stack()
	return (! bool_val) == false

func check_that(text, actual, matcher):
	return check_true(text + ": " + matcher.describe(actual), matcher.matches(actual))




# ------------------------------------------------------------------------


func run():
	_results = {}
	_error_count = 0

	class_setup()

	var t
	for t in _tests:
		if has_method(t):
			run_test(t)
		else:
			_error_count += 1
			printerr("*** SETUP ERROR: '" + t + "' not a method")

	class_teardown()

	return _error_count


func run_test(name):
	print("Running " + filename + "." + name)
	_current = { "name": name, "errors": [] }
	setup()
	call(name)
	teardown()
	_results[name] = _current
	if _current["errors"].size() > 0:
		_error_count += _current["errors"].size()
		printerr(filename + "." + name + " failed")

# -------------------------------------------------------------------------


class Matcher:
	func matches(value):
		return false
	func describe(value):
		return ""
	func _as_str(value):
		if value == null:
			return "<null>"
		if typeof(value) == TYPE_DICTIONARY:
			return value.to_json()
		return "[" + str(value) + "]"
	func _is_list(value):
		return typeof(value) == TYPE_ARRAY || typeof(value) == TYPE_INT_ARRAY || typeof(value) == TYPE_REAL_ARRAY || typeof(value) == TYPE_STRING_ARRAY


class IsMatcher:
	extends Matcher
	var val

	func _init(v):
		val = v

	func matches(value):
		return _inner_match(val, value, [])

	func _inner_match(v1, v2, seen):
		seen.append(v2)
		# Check lists the same way
		if _is_list(v1) && _is_list(v2):
			if v1.size() != v2.size():
				return false
			var i
			for i in range(0, v1.size()):
				if v2[i] in seen:
					# This isn't a correct check; instead,
					# we need to ensure that the seen version of v2[i]
					# matches up with the corresponding seen version of v1[i]
					if v1[i] != v2[i]:
						return false
					# Else prevent infinite loop by just
					# saying it's right.
				elif ! _inner_match(v1[i], v2[i], seen):
					return false
			return true
		# Cannot perform a "==" if the types are different
		if typeof(v1) != typeof(v2):
			return false
		if v1 == v2:
			return true
		if typeof(v1) == TYPE_DICTIONARY:
			if v1.size() != v2.size():
				return false
			var k
			for k in v1:
				if not (k in v2):
					return false
				if v2[k] in seen:
					# This isn't a correct check; instead,
					# we need to ensure that the seen version of v2[i]
					# matches up with the corresponding seen version of v1[i]
					if v1[k] != v2[k]:
						return false
				elif ! _inner_match(v1[k], v2[k], seen):
					return false
			return true
		# Any other type should have == match right.
		return false

	func describe(value):
		return "expected " + _as_str(val) + ", found " + _as_str(value)



static func is(value):
	return IsMatcher.new(value)



class NotMatcher:
	var val

	func _init(v):
		if typeof(v) == TYPE_OBJECT && v extends Matcher:
			val = v
		else:
			val = IsMatcher.new(v)

	func matches(value):
		return ! val.matches(value)

	func describe(value):
		return "Expected not: " + val.describe(value)



static func is_not(value):
	return NotMatcher.new(value)



class BetweenMatcher:
	var lo
	var hi

	func _init(l, h):
		lo = float(l)
		hi = float(h)

	func matches(value):
		return value != null && float(value) >= lo && float(value) <= hi

	func describe(value):
		return "expected [" + str(lo) + ", " + str(hi) + "], found " + str(value)



static func between(lo, hi):
	return BetweenMatcher.new(lo, hi)


class NearMatcher:
	var _epsilon
	var _val

	func _init(val, epsilon = 0.00001):
		_epsilon = float(epsilon)
		_val = float(val)

	func matches(value):
		return abs(float(value) - _val) <= _epsilon

	func describe(value):
		return "expected " + str(_val) + " within " + str(_epsilon) + ", found " + str(value)


static func near(val, epsilon = 0.00001):
	return NearMatcher.new(val, epsilon)
