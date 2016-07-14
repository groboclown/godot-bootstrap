# Project Component: `modules`

An extremely simple yet robust installable module system for Godot.

The module system allows for scanning at runtime the installed modules,
specifying the order in which they should be loaded, and reporting errors
with said modules.  Once the modules are loaded, the API uses a single, simple
`get_implementation(String::extension_point)` method to access the extensible
parts that modules can implement.

The component includes default GUI components for showing errors in module
loading, and for selecting the module order.

**Category** `lib`, `gui`
**Requires** `error_codes, progress_listener, error_dialog`


## Root Module Layout

The modules component expects the modules to be accessible either through
the built-in game directories (`res://`) or through the user directory
(`user://`).  You should declare one directory in at least one of these
places as being the designated "module" directory (which we'll call
*root module directories*).

The module directory contains a list of directories which should each be a
separate module.   The modules themselves need to have a `module.json` object
that describes the metadata regarding itself.

The root module directories can contain a file named `module-list.txt` which
lists, once per line, each sub-directory which is a designated module.  This
helps with systems that have slow or not-supported file system scanning.  If
the file doesn't exist, then each sub-directory is checked for the `module.json`
file, indicating a module.

## Module Layout

Each module directory is free to store whatever it needs within its directory.
All that's required is the `module.json` metadata file.

### module.json

The `module.json` file is a JSon formatted file that must have several
defined parts, with some optional parts.  If a keyword is not known,
then it's assumed to be a comment (there are two exceptions to this, marked
clearly below).

Example file:
```
{
	"name": "core extensions",
	"version": [ 1, 0 ],
	"description": "Core program extensible parts.",
	
	"classname": "core_module.gd",
	"translations": [
		"translations.en.xl",
		"translations.es.xl"
	],
	
	"requires": [
		{
			"module": "core",
			"min": 1,
			"max": 2
		}
	],
	
	
	"calls-description": "Parts of this module that other modules can implement, or parts that this module requires that other modules implement.  These are essentially 'callouts'.",
	"calls": {
		
		"init/game": {
			"description": "adds data to a game when this module is added.",
			"type": "callback",
			"aggregate": "sequential"
		},
		
		
		"init/scene": {
			"description": "initial game-start UI (scene file)",
			"type": "path",
			"aggregate": "none"
		},


		"start-game/intro-text": {
			"description": "the informational text when starting a new game",
			"type": "string",
			"aggregate": "first"
		}
		
	},
	
	
	
	"implements-description": "Existing callout points that this extends.",
	"implements": {
		"init/game": {
			"type": "callback",
			"function": "_on_init_game"
		},
		
		
		"init/scene": {
			"type": "path",
			"path": "scenes/init.xscn"
		},

		"start-game/intro-text": {
			"type": "string",
			"value": "INTRO_TEXT"
		}
	}
}
```

Parts of the file:

#### name - `String`, required

The name of the module.  It generally matches the directory name, but doesn't
have to.  This is the form of the module name that the user will see when
ordering modules or viewing errors.

#### version - `[ int, int ]`, required

A list of 2 integers representing the major and minor version numbers.  The
version numbers represent the major and minor revision number, respectively.
The major version number is used by other modules when specifying the required
version number ranges.

Other parts of the game that use the version number should keep to looking at
the major version number.

#### description - `String`, optional

A textual description for the purpose of the module.  Used to display more
information to the user.

#### classname - `String`, optional

The GDScript file name of the object that processes the module logic.
It must be within the module directory directly, and not in a sub-directory.

If this value isn't specified, then the default `modules/module.md` class is
used instead.

The class object can provide the `deactivate()` and `activate(ext_point_access)`
methods.  Note that the `activate` method will only be called if the
`deactivate` method exists.  When the module is loaded into an ordered active
set, the `activate` method will be called with a single parameter object
that provides the one method `get_implementation(String::extension_point_name) : Variant`.
If the module caches this object, then the cached version *must* be cleared
out when `deactivate` is called.

The class object is also used for `callback` extension points, and is available
for custom extension point types to use.

The class will be created using a simple `new()` operation, so any `_init()`
function on the class *must* have zero arguments.

#### translations - `[ String, ... ]`, optional

An array of translation files that this module uses.  These names are relative
to the module directory.  When the module is loaded into the active list, its
translation is also loaded; likewise, when it is unloaded as active, its
translation is also unloaded.

#### requires - `[ {}, ... ]`, optional

A list of dictionaries that declares which required modules need to be installed
and ordered before this one.  Each element in the `requires` array is a
dictionary with these fields:

* **module** (String, required) - the required module name (as set by that module's metadata.
* **min** (int, optional) - minimum major version number of the required module name.
* **max** (int, optional) - maximum major version number of the required module name.

If `min` is not specified, then the minimum version defaults to 0.  If `max`
is not specified, then the maximum version defaults to 2147483646.

If the module's requirements are not fulfilled by the installed modules, then
the component will report that module as *invalid*.

#### calls - `{ String: {}, ... }`, optional

Defines an extension point that the module calls into.  Extension points have a
name (which is passed to the top-level `get_implementation(String)` function),
and a definition of the returned value type.  These are how the modules define
where other modules can extend the functionality.

Every key in this dictionary indicates an extension point; there is no ignored
key in this structure.

The key in the dictionary declares a new extension point.  The names can take
any form, but the standard approach is to split it like a directory name.
Each extension point defines these attributes:

* **description** (String, required) - a textual description for what the
  extension point does.
* **type** (String, required) - one of the list of supported types.
* **aggregate** (String, optional) - how the type handles multiple modules
  implementing the same extension point.
* **order** (String, optional) - how to sort results generated by multiple
  modules implementing the extension point.

The modules component provides a set of built-in types, but these can be
expanded upon by invoking `add_extension_point_type()`.  The meaning of the
*order* and *aggregate* attributes depends upon the type.

If multiple modules define the same extension point, then they must both match,
or the last one loaded is marked as invalid.

#### implements - `{ String: {}, ... }`, optional

Lists the extension points that this module implements.  The listed extension
points must match the type of the declared call point.

Every key in this dictionary indicates an extension point; there is no ignored
key in this structure.

The key of the dictionary declares which extension point it implements.  The
value must contain the `type` entry, which must match the type of the extension
point.  The other values in the dictionary must conform to the requirements of
that type.

### Extension point types

There are some default extension point types, but you can also register your
own extension point type.

#### Extension point type `string`

Associates a list of strings with the extension point.

The type `order` value can be "reverse", "asc", "desc", and "normal" (defaults
to "normal").  The type `aggregate` value can be "none", "first", "last",
"list", and "set".  When the list of strings from all the modules is grouped
together, they are ordered by the `order` value, then aggregated.  So, if
one module returns a list of 5 strings, then the second one returns a list of
3 strings, the total grouping of strings passed into ordering is all 8 strings
in a single list, in the order returned by the modules.

The `string` implementation has the additional key-value pair, `value`, which
is either a String or an array of Strings.

##### Order values

* `normal`: does not change the order of the values.
* `reverse`: reverses the order of the values.
* `asc`: sorts the values ascending (alphabetical, A-Z)
* `desc`: sorts the values descending (reverse alphabetical, Z-A)

##### Aggregate Values

* `first` and `none`: returns one string, the first value in the ordered list.
* `last`: returns one string, the last value in the ordered list.
* `list`: returns all the values in the the ordered list.
* `set`: returns the unique values from the list (no duplicates, order is not
  guaranteed).


#### Extension point type `path`

A path type works just like the `string` type, except that the module directory
is prepended to each value.  So, if the module "res://modules/core-module"
specifies a `path` implementation value "scenes/first.xscn", the resulting value
is "res://modules/core-module/scenes/first.xscn".

The path implementation uses the key-value pair `path`.  The value can be either
a string or an array of strings.


#### Extension point type `callback`

Defines a function on the module object (defined by the `classname` above)
to return.  The extension point will return a lsit of funtion reference values.

The type declaration's `order` value can be "reverse" and "normal" (defaults
to "normal").  The type `aggregate` value can be "none", "first", "last",
"sequential", and "chain".  When the list of functions from all the modules is
grouped together, they are ordered by the `order` value, then aggregated.

##### Aggregate Values

* `first` and `none`: returns the first function reference in the ordered list.
* `last`: returns the last function reference in the ordered list.
* `sequential`: returns a function reference that in turn calls each ordered
  function sequentially.
* `chain`: same as `sequential`, but it passes the returned value from the
  previous call as the first argument into the next call.  This allows for
  augmenting or vetoing results.



#### Extension point type Custom

Custom extension point types can be registered through the module class's
`add_extension_point_type(String::type_name, Variant::type_obj)` method.
They need to be registered under a unique type name, and the type object
must implement these functions:

```
class MyCustomCallpointType:
	
	func validate_call_decl(point):
		# Ensure the extension point declaration (under the "calls" group) is
		# valid.  Returns a boolean value.
		return (!("order" in point) || point.order in [ "normal", "reverse" ])\
			&& (point.aggregate in [ "none", "first", "last" ])
	
	
	func validate_implement(ext, ms):
		# Checks whether the extension point implementation (under the "calls"
		# group) is valid.  Returns a boolean value.
		return ms.object.has_method("convert") && \
			"position" in ext && typeof(ext.position) == TYPE_ARRAY && \
			ext.position.size() == 2 && typeof(ext.position[0]) == TYPE_INT && \
			typeof(ext.position[1]) == TYPE_INT

	func convert_type(ext, ms):
		# Convert the extension point implementation (under the "calls" group)
		# into the expected value.
		return ms.object.convert(Vector2(ext.position[0], ext.position[1]))

	func aggregate(point, values):
		# Aggregate the list of values from the convert_type return value
		# into a new value.
		if point.order == "reverse":
			values.invert()
		
		if point.aggregate == "none" || point.aggregate == "first":
			return values[0]
		elif point.aggregate == "last":
			return values[values.size() - 1]
		else:
			# invalid
			return null
```




## Using

The modules object needs to be created and initialized.

```
var modules = preload("res://bootstrap/lib/modules.gd").new()
modules.add_extension_point_type("custom_type", CustomTypeCallpoint.new())
```

Then, the modules object needs to scan for installed modules:

```
modules.reload_modules(["res://modules", "user://modules"], progress_bar)
```

Some of the modules might be invalid.  You can use the GUI module to display
the error message.

```
var invalid_modules = modules.get_invalid_modules()
if ! invalid_modules.empty():
	var n = load("res://bootstrap/gui/modules/problem.xscn").instance()
	n.setup(bad_modules)
	parent.add_child(n)
```

At some point, the code will need to be aware of the correct module ordering.
Once this is discovered, and the modules should be activated, you can
load the modules.

```
var all_modules = modules.get_installed_modules()
if modules.get_installed_module("core", 0, 5) == null:
	show_error("core module (version 0 to 5) does not exist or is invalid!")
	return
var order = [ "core", "dlc", "user-gui-mod" ]
var active_modules = modules.create_active_module_list(order, progress_bar)
if active_modules.is_invalid():
	show_error("problems loading modules")
	return
```

The module system is designed around having only one active module list
at a time (due to the translation services).  If you need to reload the modules,
you can invoke `create_active_module_list` again, and the first list will become
invalid.



### Modules API

#### func `_init()`

Creates a new modules instance.  Even though you can create multiple of these,
you should take care to use only one - activating modules registers
translations, which could lead to trouble if multiple instances of the same
module are loaded or unloaded.

#### func `add_extension_point_type(String::type_name, Variant::type_obj)`

Registers a new extension point type for modules to use.

#### func `initialize(Array[String]::module_paths, Range::progress = null)`

Initializes the list of installed modules.  If the modules are already loaded,
then this will not do anything.

#### func `reload_modules(Array[String]::module_paths = null, Range::progress = null)`

Reloads the modules, reusing the existing module path.  If the modules are
already loaded, this will unload them and rescan for modules.  Be careful with
this method - it can cause active modules to be wiped out.

#### func `get_installed_modules() : Array[ModuleStruct]`

Returns the list of all the modules that were found through the `initialize()`
method.  These may or may not be valid modules.  The returned structure has
the following values:

* `name` (String) - name of the module
* `dir` (String) - directory where the module lives.
* `raw_name` (String) - name of the module directory
* `version` (`[int,int]`)- list of 2 ints, the major (index 0) and minor (index 1) version.
* `description` (String) - textual long description of the module.
* `classname` (String) - resource location for the module (a GDScript file)
* `error_code` (int) - error code.  `OK` if the module is valid.
* `error_operation` (String) - part of the module loading that discovered the issue.
  `null` if `error_code` is `OK`.
* `error_details` (String) - details about what caused the module loading issue.
* `translations` ([String,...]) - list of all the translation resource files
  that the module uses.
* `requires` ([{...}, ...]) - list of required modules.
* `extension_points` (`{...}`) - dictionary of declared extension points.
* `implement_points` (`{...}`) - dictionary of implemented extension points.
* `class_object` (Resource) - loaded resource of the `classname` value.
* `object` (Variant) - instantiated `class_object`.

#### func `get_installed_module(String::module_name, int::min_major_version, int::max_major_version, boolean::allow_errors = false) : ModuleStruct`

Returns the installed module with the given name, whose major version number
is in the range `[ min_major_version, max_major_version ]` (inclusive).  If
`allow_errors` is false, then the module's `error_code` value must be `OK`,
otherwise the module can be returned if it isn't valid.  If no matching
module is found, returns null.

#### func `get_invalid_modules() : Array[ModuleStruct]`

Returns all modules that have an `error_code` value unequal to `OK`.

#### func `create_active_module_list(Array[String]::module_names, Range::progress = null) : OrderedModules`

Adds all the modules in the `module_names` list into an `OrderedModules` object,
registers them, and returns the object for use.

If there is currently an active modules list, it is first unloaded.

#### func `unload_active_modules()`

### OrderedModules API

The object that allows access to the currently active and registered modules.

#### func `get_implementation(String::extension_point_name) : Variant`

Returns the value for the extension point name, as returned by the modules.
The actual value is dependent upon the extension point type.

#### func `is_valid() : boolean`

Returns `false` if the active modules was unloaded, or if there is at least one
module that is invalid, otherwise `true`.

#### func `is_invalid() : boolean`

Returns `true` if the active modules was unloaded, or if there is at least one
module that is invalid, otherwise `false`.

#### func `get_invalid_modules() : Array[ModuleStruct]`

Returns the list of all the modules that have an error.

#### func `get_active_modules() : Array[ModuleStruct]`

Returns the ordered list of all the active modules.

#### func `unload()`

Unloads this active module and makes it invalid.



