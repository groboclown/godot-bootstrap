# Development Guide


As the bootstrap files are available under the CC0 license, you are free to
modify and make new components without contributing back to the community
(or even giving it any credit).  However, if you want to give back, here's how
you can help.


## Fork on GitHub

Fork the `godot-bootstrap` project into your own space through GitHub.

## Make Your Changes

Add your changes into the project.  This requires adding a new component
(or bug fixing existing code).  Components need to have a few special
considerations made - see the coding style guide for more information.

## Push Request

Make a push request for your changes back into the parent project.


# Coding Style Guide


## Resource Files

All resources should be stored in xml format (that means using the `x` prefix
on the extension).  `xscn` instead of `scn`, `xthm` instead of `thm`, etc.


## `res://` Paths

If you're using the XML formatted resource files, you must take care to
careful when specifying the resource paths encoded in the files.  Because
projects can remap where the bootstrap files end up, they need to conform
to the standard of `res://bootstrap/(category)/(rest of path)`.  The install.py
file will remap all the files with the `.x` extension prefix
(e.g. `.xthm`, `.xscn`) and `.gd` files.

GDScript files should use relative paths instead of absolute `res` paths.
However, there are some cases where one component needs a resource from another
category, in which case using the above standard is the only means available.
Make sure the resource string is encased in double quotes (`"`).


## GDScript Code Style

* Tabs instead of spaces.
* `underscore_separated_names` instead of `camelCaseNames`.
* Don't hard-define paths to use.  Allow the user to override if necessary.


## Python Code Style

The build files are all written in Python.

* Python3 standards.
* 4 spaces instead of tabs.
* `underscore_separated_names` instead of `camelCaseNames`.

