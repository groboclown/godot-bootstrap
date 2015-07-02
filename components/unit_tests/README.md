# Project Component: `unit_tests`

Modern software is complex.  The horsepower of computers allows us to build
games with hundreds of systems.  This also means that there's many places
where the game can break.  To alleviate the problem of adding a whole QA team
to find the little issues, automated tests help to make sure small parts of
the system are working as intended.


## Writing Tests

First, create a new test file.  The tests are expected to live in your Godot
game folder, under the `tests` sub-directory - that's where the main test
runner searches for the test files.

The test file needs to extend the `unit_tests/base.gd` file.  Because
Godot doesn't have an API to inspect the names of the methods in a script,
you need to initialize the list of test names in the `_init()` function.
Finally, you need to write the test functions themselves.

```
extends "res://bootstrap/tests/base.gd"


func _init():
	add_all([
		"test_type_string",
		"test_type_array"
	])

func test_type_string():
	# use the "typeof" function to check if a string is a string.
	check_that("type of string",\
		typeof("a string"),\
		is(TYPE_STRING))


func test_type_array():
	var v = [1, 2]
	check_that("type of array",\
		typeof(v),\
		is(TYPE_ARRAY))
	v = "[]"
	check_that("not type of array",\
		typeof(v),\
		is_not(TYPE_ARRAY))
```

Right now, the test runner will not recursively check for test files under
sub-directories in the `tests` directory.  That may change in the future.



## Running Tests

You need to make sure the `unit_test` component is in your project's
`bootstrap.config` file.

You run the Godot script execution from your game directory like so:

```godot -s bootstrap/tests/main.gd```

Your path will change depending on where you install the test scripts.


## Test API

Because all tests extend the `base.gd` file, they inherit the assertion
framework.  Currently, there are only two "assertion" methods.

### func `check_true(message, boolean_value)` :: boolean

If the `boolean_value` is false, (checked with `! boolean_value`), an error
is reported.  Because Godot doesn't have strong exception mechanisms, this will
just return whether it failed (`false`) or passed (`true`).  If you want to
abort your test on the assertion, you'll need to explicitly check the return
value.

```
check_true("This should really fail", 1 == 0)
if ! check_true("Zero is really zero", 0 == 0):
	print("Zero is not really zero?")
```

### func `check_that(message, actual_value, matcher)` :: boolean

Uses the "matcher" (see below) object to check whether the `actual_value`
is an expected value.  Its return value and usage is like the `check_true`
method.

### class `Matcher`

The `Matcher` class provides a simple API to make descriptive failure messages
on any kind of condition.  This prevents the assertion API to expanding
as different conditions are discovered.  Instead, you can use matchers with
matchers to create elaborate conditions.  `Matcher` instances are passed to the
`check_that` method.

Simple example of a custom matcher:

```
class IsNullMatcher:
	func matches(value):
		return value == null
		
	func describe(value):
		return "expected null value, found [" + str(value) + "]"
```

Each built-in matcher includes a function to easily create the instance.

### func `is(expected_value)` :: Matcher

Returns an `IsMatcher` instance that checks whether the actual value matches
the expected value.

```
check_that("should match", obj.get_value(), is(1))
```


### func `is_not(expected_value)` :: Matcher

Returns a `NotMatcher` instance that checks whether the actual value does not
match the expected value.  The expected value may also be another matcher, to
allow compounded constructions.

```
check_that("should not be between values",\
    obj.get_value(),\
	is_not( between(0,1) ))
```


### func `between(lo, hi)` :: Matcher

Returns a `BetweenMatcher` instance that checks whether the actual value is
between (inclusive) the given hi and lo values.  The values are expected to
be float values, and they are checked with a `>=` and `<=` value.

```
check_that("random float values are between 0 and 1", randf(), between(0,1))
```

### func `near(value, epsilon=0.00001)` :: Matcher

Returns a `NearMatcher` instance that checks whether the actual value is
within the given epsilon value to the expected value.

```
check_that("invalid stdev", obj.get_standard_deviation(), near(0.05))
```




