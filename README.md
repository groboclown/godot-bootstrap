# Godot Bootstrap

*Godot Bootstrap* provides basic components to make setting up an
initial [Godot](//http://www.godotengine.org)
game much faster, by providing much of the boiler plate code to get you
started.  Best of all, you can decide which components to use, and which
to ignore.



## Components

Some of the components that bootstrap provides:

* [Modules](`components/modules`) a system for allowing user mods, or
  developer-provided DLC, to extend the basic game.
* [User Configuration](`components/user_config`) tools for storing and
  retrieving user-set configuration values.
* [Save Games](`components/save_game`) components for maintaining saved
  games.
* [Automated Testing](`components/unit_tests`) allows for writing tests in
  GDScript, and executing them in an automated way.
* [Extended GUI controllers](`components/ext_controllers`) GUI controllers to help
  make the UI aspects work nicely together.



## Using Bootstrap

Bootstrap provides a set of components to provide basic functionality to
your game, and the tools to import those components into your game.  Bootstrap
requires [Python 3](https://www.python.org/downloads/release) to run.

To use bootstrap, first pull the files from Github.

Then, you need to add a `bootstrap.config` file into your project directory,
and configure it with a few simple steps:

```
# The bootstrap config file for the project.
config = {
    # the directory to copy the bootstrap files.  These need to be inside the
	# Godot game directory (at or a sub-directory of the "engine.cfg" file),
	# or you'll need a custom build system to move them there.
	# If this isn't given, it defaults to "bootstrap".
	bootstrap: "game/boostrap",
	
	# All the components that the project uses.  These will be copied into the
	# bootstrap directory.  If a component depends upon another component, those
	# will be added implicitly (you don't need to reference it).
	components: [ unit_tests, error_codes ],
	
	# If you want to map the bootstrap file categories to a different location,
	# this gives you that flexibility.  See each component for the categories
	# it uses, and for whether directory remapping is supported.
	dirmap: {
		"lib": "src/library_files",
		"tests": "../tests"
	}
}
```

To install the files, run the downloaded bootstrap `build/install.py` file
from the project directory:

```
$ cd my_project
$ python3 (godot-bootstrap-dir)/build/install.py
```

Note that running the install will remove files that are no longer specified
in the components, and overwrite existing files, you shouldn't modify them
from your installed directory.  If you want to make customizations, copy them
to a separate location.


## Contributing

*Godot Bootstrap* is still very much under development.  You can use the
GitHub project for pull requests your local changes.  Be sure to have a
look at the [development guide](docs/developing.md) for coding standards.

All contributions must be made available under the [CC0](LICENSE) license.



