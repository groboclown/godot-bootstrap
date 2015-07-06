# Library class: `progress_listener`

A wrapper class around a progress bar or texture progress bar, to make progress
announcements easier to code.

**Category**: `lib`

## Usage

The progress listener was designed to allow for splitting up the progress
advancement across multiple functions and classes.

You first create a new instance from an existing progress bar:

```
var progress_bar = get_node("my progress bar")
var progress = preload("bootstrap/lib/progress_listener.gd").new(progress_bar)
```

Then split the progress bar up for each of the sub-functions.

```
var child = progress.create_child(0.0, 0.4)
child.set_steps(sub_processes.size())
var index = 0
for sub in sub_processes:
	var child2 = child.create_child(index, index + 1)
	sub.process(child2)
	child2.set_val(index + 1)
```

Each sub-process can then use the child process as though it has a range of
0 to 1, without needing to worry about the parent range.

So, if you call:

```
var parent = preload("bootstrap/lib/progress_listener.gd").new(progress_bar)
var child1 = progress.create_child(0.2, 0.8)
var child2 = child1.create_child(0.4, 1)
child2.set_value(0.5)
```

This will cause `child2` to set its value to `0.5`, which will in turn call
`child1.set_value(0.7)` (0.7 = 0.4 + (1 - 0.4) * 0.5).  This in turn will call
`parent.set_value(0.62)` (0.62 = 0.2 + (0.8 - 0.2) * 0.7).

In cases where the processing may not have access to a progress bar, the
progress listener class can use a null value, so that the code doesn't need
to be sprinkled with null checks.


## API

The API is designed to mirror the `Range` API.


### static func `dummy()` : `progress_listener`

Constructor that creates a progress listener with no parent progress bar.

```
var progress = preload("bootstrap/lib/progress_listener.gd").dummy()
```

Creates a new progress listener that simply stores the values set, and allows
for creating child progress listeners.  This is most effective when code can
optionally expect a progress bar, but it isn't necessary, as it will keep the
code from having constant null checks.


### func `_init(Variant::parent, double::min_val = 0, double::max_val = 0)` : `progress_listener`

Default constructor.  It takes a parent, which must conform to the
`Range` class API, so it can be a progress bar or a progress listener,
and optionally a minimum value and a maximum value, which are used as the range
in the parent.

```
var progress = preload("bootstrap/lib/progress_listener.gd").new(progress_bar, 0.3, 0.6)
```

This creates a progress listener instance that maps the value 0 to 0.3 in the
parent progress bar, and 1 to 0.6 in the parent progress bar.


### func `create_child_to(double::max_val) : progress_listener`

Creates a child progress listener instance that maps 0 to the current
value of the progress listener, and 1 to the maximum value.


### func `create_child(double::min_val, double::max_val) : progress_listener`

Creates a child progress listener instance that maps 0 to the minimum value,
and 1 to the maximum value.


### func `set_steps(int::step_count)`

Set the number of values that the progress listener counts up to.  This will
internally map each integer value to a value between 0 and 1.  If the value is
non-positive, then the progress listener will go back to interpreting the
values between 0 and 1.

This can be set at any time after creation.


### func `get_steps() : int`

Returns 0 if the step count is disabled (and values are between 0 and 1), or
the number of steps set in `set_steps()`.


### func `get_min() : double`

Returns 0.


### func `get_max() : double`

If the step value is positive, returns that value, otherwise returns 1.


### func `get_val() : double`

Returns the current value of this progress.


### func `get_value() : double`

Returns the current value of this progress.


### func `set_val(double::value)`

Sets the current progress value.  If there is a parent, it sets the parent
value.


### func `set_value(double::value)`

Sets the current progress value.  If there is a parent, it sets the parent
value.
