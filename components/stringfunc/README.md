# Library component: `stringfunc`

Utility functions to aid in the manipulation of strings.


**Category** `lib`

## Usage

`stringfunc` is used in an entirely static way.  Usually, you'll want to define
it as a top-level variable in your GDScript file:

```
var STRINGFUNC = preload("res://bootstrap/lib/stringfunc.gd")
```

Then, in your code, you can invoke the functions directly:

```
print(STRINGFUNC.format('I like %n.', { 'n': 'Godot' }))
```


## API

### static func `format(String::format, Dictionary::values, String::escape='%')`

Translates the `%x` like expressions in the format, by replacing the % and
character with the character in the values dictionary.  Note that this only
works with single character keys.  Additionally, the escape character
(defaults to `%`) will always show itself if it is doubled.

```
print(STRINGFUNC.format('I like %n, but not %x %p%% of the time.', { 'n': 'Godot', 'x': 'Unity', 'p': 100 }))
```

would display the text `I like Godot, but not Unity 100% of the time.`

### static func `pad_number(Number::number, Integer::min_size=2, String::padding='0')`

Pads a number (`int` or `float`) with leading `0` characters by default, or any
other text of your choosing, up to the total length of the `min_size` argument.
If the number is negative, the negative sign is added as the first character
of the string.
