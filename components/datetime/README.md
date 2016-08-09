# Library component: `datetime`

Utility functions to aid in the manipulation of date and time objects.


**Category** `lib`

## Usage

`datetime` must be instantiated at least once, but then can continue to be
reused.  Usually, you'll want to define it as a top-level variable in your
GDScript file:

```
var DATETIME = preload("res://bootstrap/lib/datetime.gd").new()
```

Then, in your code, you can invoke the functions directly:

```
var date = OS.get_date()
var time = OS.get_time()
print("The current time is: " + DATETIME.time_to_str('%H:%M:%s', time))
print("The current date is: " + DATETIME.date_to_str('%Y/%m/%d", date))
```

## Supported Formatting Language

The `datetime` module supports a subset of the Standard C library date
formatting language, specifically:

*Date*
 * *%y* - last 2 digits of the year.
 * *%Y* - full year.
 * *%d* - 0-padded 2 digit day of the month.
 * *%D* - day of the month.
 * *%m* - 0-padded 2 digit month.
 * *%w* - weekday index (Sunday is index 0).
 * *%a* - 3-character day of week (`Sun`, `Mon`, ..., `Sat`)
 * *%A* - Full name of the day of the week (`Sunday`, `Monday`, ..., `Saturday`)
 * *%b* - 3-character month name (`Jan`, `Feb`, ..., `Dec`)
 * *%B* - Full name of the month (`January`, `February`, ..., `December`)
 
*Time*
 * *%I* - 0-padded 2 digit 12 hour.
 * *%H* - 0-padded 2 digit 24 hour.
 * *%M* - 0-padded 2 digit minute.
 * *%S* - 0-padded 2 digit second.
 * *%p* - `AM` or `PM`.

Use *%%* to insert a `%` mark.
 
For the string values, they will be translated by using the `tr()` function.
You will want to supply translations for these strings if you support multiple
(or non-English) languages.


## API

### func `time_to_str(String::format, TimeDict::time=null)`

Translates the time (as returned by `OS.get_time()`) into a string using the
given format.  If the time argument is `null`, then the current time will
be queried.

```
print("Current time: " + DATETIME.time_to_str("%H:%M:%S"))
```

### func `date_to_str(String::format, DateDict::date=null)`

Translates the date (as returned by `OS.get_date()`) into a string using the
given format.  If the date argument is `null`, then the current date will
be queried.

```
print("Current date: " + DATETIME.date_to_str("%B, %A %d, %Y"))
```

### func `datetime_to_str(String::format, DateDict::date, TimeDict::time)`

Translates the time and date into a string using the
given format.  Unlike the other conversion functions, this does not allow for
`null` (or unspecified) arguments.

```
print("Current time and date: " + DATETIME.datetime_to_str("%B, %A %d, %Y %I:%M:%S %p"))
```

### func `date_add(DateDict::date, int::days)`

Adds the number of days to the `date` dictionary, and returns a new `DateDict`
corresponding to the advanced day count.  Subtraction of days is done by passing
in a negative `days` value.
