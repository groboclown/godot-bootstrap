# base test class

#extends Object

var _tests = []
var filename = "<unknown>"
var _results = null

func _init():
	var t
	for t in get_method_list():
		# print(t.to_json())
		if t["name"].begins_with("test_") && t["args"].size() <= 0:
			add(t["name"])


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
	if test_name == null:
		return
	if typeof(test_name) == TYPE_STRING:
		if not(test_name in _tests):
			_tests.append(test_name)
	else:
		var t
		for t in test_name:
			if t != null && not(t in _tests):
				_tests.append(t)


func add_all(all_tests):
	add(all_tests)


func set_tests(test_names):
	_tests = []
	add(test_names)


func skip(test_name):
	if test_name == null:
		return
	if typeof(test_name) == TYPE_STRING:
		_tests.erase(test_name)
	else:
		var t
		for t in test_name:
			_tests.erase(test_name)


# ------------------------------------------------------------------------


func check_true(text, bool_val):
	if ! bool_val:
		if _results != null:
			_results.add_error(text)
		return false
	return true

func check_that(text, actual, matcher):
	return check_true(text + ": " + matcher.describe(actual), matcher.matches(actual))

func check(text = ""):
	return Checker.new(_results, text)




# ------------------------------------------------------------------------

# result_collector must implement these methods:
#   func start_suite(suite_name)
#   func end_suite()
#   func start_test(name)
#   func end_test()
#   func add_error(message)
#   func has_errors() (does the current suite have any errors?)


func run(result_collector):
	self._results = result_collector
	result_collector.start_suite(filename)
	class_setup()
	if result_collector.has_error():
		return

	var t
	for t in _tests:
		if has_method(t):
			run_test(t)
		else:
			result_collector.add_error("Setup Error: requested function does not exist: " + t)

	class_teardown()
	result_collector.end_suite()


func run_test(name):
	if _results != null:
		_results.start_test(name)
	setup()
	call(name)
	teardown()
	if _results != null:
		_results.end_test()


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
		# return typeof(value) == TYPE_ARRAY || typeof(value) == TYPE_INT_ARRAY || typeof(value) == TYPE_REAL_ARRAY || typeof(value) == TYPE_STRING_ARRAY
		# All the arrays are in this specific range.
		# This needs to be checked against future versions of Godot.
		var v = typeof(value)
		return v >= TYPE_ARRAY && v <= TYPE_COLOR_ARRAY


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
		if typeof(v1) == TYPE_REAL:
			# Closeness
			return abs(float(v1) - v2) <= 0.0000001
		# Any other type should have == match right.
		return false

	func describe(value):
		return "expected " + _as_str(val) + ", found " + _as_str(value)



static func is(value):
	# "is" can be used to make a clear English-like sentence.
	# So, if the value is a matcher, then just use that matcher instead of
	# adding another layer around "is".
	if typeof(value) == TYPE_OBJECT && value.has_method("matches") && value.has_method("describe"):
		return value
	# Need to wrap the value in an is check.
	return IsMatcher.new(value)


static func equals(value):
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
		return "expected not: " + val.describe(value)



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


class ContainsMatcher:
	extends Matcher
	var _val

	func _init(val):
		_val = val

	func matches(actual):
		if actual == null:
			return false
		if typeof(actual) == TYPE_STRING:
			# Expect a string to contain a sub-string
			return actual.find(_val) >= 0
		if _is_list(actual):
			if _is_list(_val):
				# each "val" must be in the actual list
				var v
				for v in _val:
					if ! (v in actual):
						return false
				return true
			return _val in actual
		if typeof(actual) == TYPE_RECT2:
			if typeof(_val) == TYPE_RECT2:
				return actual.encloses(_val)
			if typeof(_val) == TYPE_VECTOR2:
				return actual.has_point(_val)
			return false
		if typeof(actual) == TYPE_PLANE:
			if typeof(_val) == TYPE_VECTOR3:
				return actual.has_point(_val)
			return false
		if typeof(actual) == TYPE_DICTIONARY:
			if _is_list(_val):
				return actual.has_all(_val)
		 	return actual.has(_val)


		# These don't really make sense.

		# Object values should just be checked for equality.
		#if typeof(actual) == TYPE_OBJECT:
		#	return actual.get(_val) != null

		return false

	func describe(actual):
		return "expected " + _as_str(actual) + " to contain " + _as_str(_val)

static func contains(val):
	return ContainsMatcher.new(val)


class EmptyMatcher:
	extends Matcher

	func matches(actual):
		if _is_list(actual):
			return actual.size() <= 0
		if typeof(actual) == TYPE_DICTIONARY:
			return actual.keys().size() <= 0
		return false

	func describe(actual):
		if _is_list(actual):
			return "expected " + _as_str(actual) + " to be an empty list"
		if typeof(actual) == TYPE_DICTIONARY:
			return "expected " + _as_str(actual) + " to be an empty dictionary"
		return "expected " + _as_str(actual) + " to be an empty list or dictionary"

static func empty():
	return EmptyMatcher.new()


# ---------------------------------------------------------------------------

class Checker:
	var _text
	var _results

	func _init(results, text):
		_results = results
		_text = text

	func that(actual, matcher):
		var res
		var msg
		if typeof(matcher) == TYPE_BOOL:
			res = matcher
			msg = _text
		else:
			res = matcher.matches(actual)
			msg = _text + ": " + matcher.describe(actual)
		if ! res:
			if _results != null:
				_results.add_error(msg)
			return false
		return true
