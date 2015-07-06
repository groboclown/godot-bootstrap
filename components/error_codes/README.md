# Library: `error_codes`

This library provides custom error code extensions beyond what the standard
Godot core provides (used by other components in *Bootstrap*), as well as
a way to get a usable error message, rather than a cryptic guru meditation
code.

**Category**: `lib`

## Usage

`error_codes` is used in a static context.  Usually, you'll want to define 
it as a top-level variable in your GDScript file:

```
var ERROR_CODES = preload("res://bootstrap/lib/error_codes.gd")
```

Then, in your code, you can translate the error codes into messages like:

```
var err = file.open(filename, File.READ)
if err != OK:
  error_label.set_text(tr("ERROR_FOUND_MESSAGE") + tr(ERROR_CODES.to_string(err)))
  return
```

The message text returned by `to_string(int)` will be the same as the constant
name for the error (such as `ERR_FILE_NOT_FOUND`), which makes creating a
translation into human-readable text possible by adding the error code into
the translation file.


## API

### static func `add_code(int::value, string::text)`

If you have custom error codes with their own messages, you can add them into
the internal dictionary by invoking this method.

```
ERROR_CODES.add_code(ERR_CUSTOM_VALUE, "ERR_CUSTOM_VALUE")
```


### static func `to_string(int::value) : String`

Returns the internal string mapping for the error code.  By default, this is
the GDScript constant name as a string.

