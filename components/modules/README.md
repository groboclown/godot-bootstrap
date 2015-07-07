# Project Component: `modules`

An extremely simple yet robust installable module system for Godot.

The module system allows for scanning at runtime the installed modules,
specifying the order in which they should be loaded, and reporting errors
with said modules.  Once the modules are loaded, the API uses a single, simple
`get_implementation(String::extension_point)` method to access the extensible
parts that modules can implement.


**Category** `lib`
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
It must take a single argument in its `_init()` method.

If this value isn't specified, then the default `modules/module.md` class is
used instead.

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






## Using

The module system is designed around having only one active module list
at a time.



### Modules API


### OrderedModules API


