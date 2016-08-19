# Project Component: `unit_tests`

Modern software is complex.  The horsepower of computers allows us to build
games with hundreds of systems.  This also means that there's many places
where the game can break.  To alleviate the problem of adding a whole QA team
to find the little issues, automated tests help to make sure small parts of
the system are working as intended.

**Category** `tests`

**Backwards incompatible change:** If you were using a previous version of the
`unit_tests` framework, there were two minor backwards incompatible changes from
the previous releases:

* If you explicitly were omitting tests from running in the `add_all` method,
  you will find that your skipped tests are now being run.  Now, you will either
  need to change your `add_all` call to `set_tests`, or call `skip` to list
  the tests you want to explicitly skip.
* If you were changing the behavior or the `run()` method, then your suite
  will now break.  The `run` method now takes a `result_collector` argument.
* Likewise, if you were explicitly reaching into the base test class' member
  fields, you'll find that they have changed.

## Writing Tests

First, create a new test file.  The tests are expected to live in your Godot
game folder, under the `tests` sub-directory - that's where the main test
runner searches for the test files.

The test file needs to be named with a `test_` prefix, and it needs to extend
the `unit_tests/base.gd` file.  This test file is called a *test suite*.

Each test needs to be a function whose name starts with `test_`.  That's how
Godot discovers which tests it needs to run.  Each of these test methods is
called a *test case*.

```(gdscript)
extends "res://bootstrap/tests/base.gd"

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

The test runner will recursively check for test files under
sub-directories in the `tests` directory, for any sub-directory whose
name ends with `_tests`.


### Fixture Setup and Tear Down

In many situations, your test class uses a common data configuration, called
a *fixture*.  To help with this common setup, you can override the methods
`setup()` and `teardown()`:

```(gdscript)
extends "res://bootstrap/tests/base.gd"

var tested

func setup():
	tested = require("res://my_scene").instance()
	print("- ran setup -")

func teardown():
	tested.remove_and_skip()
	tested.free()
	tested = null
	print("- ran teardown -")

func test_type():
	print("- running test_type -")
	check().that(tested.is_type("Container"), is(true))

func test_default_key():
	print("- running test_default_key -")
	check().that(tested.key, is("Please Select A Value"))
```

When the tests run (`test_type` and `test_default_key`), the test framework
will first run the `setup()` method, and after each test finishes, the test
framework runs `teardown()`.  Based on the code above, the output would look
something like:

```
- ran setup -
- running test_type -
- ran teardown -
- ran setup -
- running test_default_key -
- ran teardown -
```

Additionally, if you have some heavyweight fixtures that you only want to
setup once, you can use the `class_setup()` and `class_teardown()` methods,
which are invoked only once for the entire suite.

### Altering Which Test Cases Are Run

By default, the `unit_test` framework will run all the functions whose name
starts with `test_`.  However, you may not want to do that in all cases, or
perhaps you have some special snowflake test cases that use a different naming
convention.

You can explicitly alter the tests that are run with these methods:

* `add(names)` (and `add_all` as an alias) : The `names` argument can either
  be a string value or a list of string values.  Each method name added through
  this  method will be run during the test execution.  This is additive -
  existing registered tests will still be run.  Also, each added test will only
  be run once - duplicate values are omitted.
* `set_tests(names)` : Replaces the current list of test methods with the
  given list of tests (`names` may be a string or a list of strings).
* `skip(names)` : Removes tests from the list of tests to run (`names` may be
  a string or a list of strings).


## Running Tests

You need to make sure the `unit_test` component is in your project's
`bootstrap.config` file.

You run the Godot script execution from your game directory like so:

```
godot -s bootstrap/tests/main.gd
```

Your path will change depending on where you install the test scripts.


## Test API

Because all tests extend the `base.gd` file, they inherit the assertion
framework.  Currently, there are only two "assertion" methods.  these
are called "checks", because they do not stop the test from running
if the check fails.

### func `check_true(String::message, boolean::value)` : boolean

If the `boolean_value` is false, (checked with `! boolean_value`), an error
is reported.  Because Godot doesn't have strong exception mechanisms, this will
just return whether it failed (`false`) or passed (`true`).  If you want to
abort your test on the assertion, you'll need to explicitly check the return
value.

```(gdscript)
check_true("This should really fail", 1 == 0)
if ! check_true("Zero is really zero", 0 == 0):
	print("Zero is not really zero?")
```

This is particularly important if you have tests that must be true for the rest
of the test to work.  In other XUnit libraries, an exception would be thrown.
However, since GDScript doesn't provide an exception mechanism, an explicit
check must be made instead.

```(gdscript)
var result = my_obj.perform()
if ! check_true("Expected type should be a string array", typeof(result) == TYPE_STRING_ARRAY):
    return
if ! check_true("Not enough values in result", result.size() == 1)
var next = result[0]
```

Having the check return false when the check fails may seem like more typing,
because the usual use case is to only have an `if` statement when the check
fails.  However, the code "reads" better ("if not checked (result, expected), then")

### func `check_that(String::message, Variant::actual_value, Matcher::matcher)` : boolean

Uses the "matcher" (see below) object to check whether the `actual_value`
is an expected value.  Its return value and usage is like the `check_true`
method.

```(gdscript)
var value = 3 - 2
check_that("Did not compute correctly", value, is(1))
value = my_obj.perform(1)
check_that("Did not compute correctly", value, is_not(null))
```

### func `check(String::message = null)` : Checker

For a more verbose style of testing, and for possible future extensibility,
the `check(String)` method returns an object which allows for further
definition of the check.

Right now, the usage is very simple:

```(gdscript)
var value = 3 - 2
check("Computing 3 - 2").that(value, is(1))
```

the `that` method has arguments `(Variant::actual, Matcher::expected)`, and
returns a boolean - `false` if the check fails, and `true` if the check passes.

Additionally, the text on the `check` argument is optional, so this allows for
creating checks without the accompanied text.

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

You can either subclass the base `Matcher` class, or you can implement
a class that provides the `matches(Variant)` and `describe(Variant)`
methods.

### static func `is(Variant::expected_value)` : Matcher

Returns an `IsMatcher` instance that checks whether the actual value matches
the expected value.

```
check_that("should match", obj.get_value(), is(1))
```

The "is" function can also be used as a wrapper around another matcher to make
a more English-like sentence:

```
check().that(10.0 / 10.0, is(near(1.0)))
```

### static func `equals(Variant::expected_value)` : Matcher

### static func `is_not(Variant::expected_value)` : Matcher

Returns a `NotMatcher` instance that checks whether the actual value does not
match the expected value.  The expected value may also be another matcher, to
allow compounded constructions.

```
check_that("should not be between values",\
    obj.get_value(),\
	is_not( between(0,1) ))
```


### static func `between(float::lo, float::hi)` : Matcher

Returns a `BetweenMatcher` instance that checks whether the actual value is
between (inclusive) the given hi and lo values.  The values are expected to
be float values, and they are checked with a `>=` and `<=` value.

```
check_that("random float values are between 0 and 1", randf(), between(0,1))
```

### static func `near(float::value, epsilon=0.00001)` : Matcher

Returns a `NearMatcher` instance that checks whether the actual value is
within the given epsilon value to the expected value.

```
check_that("invalid stdev", obj.get_standard_deviation(), near(0.05))
```

### static func `contains(Variant::expected_value)` : Matcher

Returns a `ContainsMatcher` instance that checks whether the actual value
contains the expected value.

The actual value may be one of these types:

* `String` : checks whether the expected value is a substring of the actual value.
* `Array` : (any array type) checks whether the actual value contains the
  expected value.  If the expected value is itself an array, then the matcher
  will check if *every* expected value is in the actual value.
* `Dictionary` : if the expected value is an array, then the matcher will check
  that the dictionary contains *every* expected value in the actual dictionary's
  keys.  Otherwise, this will check that the dictionary contains the actual value
  as a key.
* `Rect2D` : if the expected value is another `Rect2D`, then this checks that
  the actual rectangle encloses the expected rectangle.  If the expected value is
  a `Vector2`, then this checks that the actual rectangle contains the
  expected point.
* `Plane` : checks whether the expected value (must be a `Vector3`) is on the
  plane.

### static func `empty()` : Matcher

Returns an `EmptyMatcher` instance that checks that the actual value is an
empty list or dictionary.  If the type of the actual value isn't a list or
dictionary, then this will fail.


## Test Suite Maintenance of Test Cases API

These methods maintain the list of which test cases are actually run during the test.

### func `add([String or StringArray]::names)`

Includes additional function names to run as part of the test suite

### func `add_all([String or StringArray]::names)`

An alias for `add`.

### func `set_tests([String or StringArray]::names)`

Clears out the existing registered tests, and reassigns it to the new list.

### func `skip([String or StringArray]::names)`

Removes the test names from the list of tests to run.


## Test Case Life Cycle API

Override these methods to insert code into the test case execution lifecycle.
Each one is optional to override.

There are other methods for the life cycle, but those are left undocumented,
because they may change in the future.

### func `setup()`

Executes before *every* test case runs.  Use this to setup common test fixtures.
If you perform a `check` inside the `setup()`, and the check fails, then the
test will not run.

### func `teardown()`

Executes after *every* test case runs.  Use this to close off open connections
or otherwise destroy fixtures that can keep hold on resources.

### func `class_setup()`

Executes before anything else in the test suite, and only once.  Use this to
setup fixtures that remain around for the entire execution of all the tests in
the suite.  Please note that it's really bad form to depend upon the execution
order of the test cases to properly modify the state of these fixtures.

This is not a static function.  You can modify the tests to run here.

### func `class_teardown()`

Executes after all the test cases run in a test suite.

### func `_init()`

A no-argument constructor.  Required, because the test framework will call
this blindly.

The default implementation inspects all the test methods, and loads all the
methods whose names start with `test_`.  You can modify the tests to run here.
In general, you should not provide an `_init()` function, and instead modify
the tests in the `class_setup()` method.
