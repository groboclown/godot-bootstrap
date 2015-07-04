# Adding Bootstrap Components

This directory includes Python 3 files that install and clean-up the bootstrap
components into your project.


## Setting Up Components to Install

To select which components you want to install, add them into your
`bootstrap.config` file.

```
config = {
	"components": [ unit_tests, error_codes ]
}
```

Just list out the component names inside the square brackets.  They also
don't need to be encased in quotes.

To change the directory that different components install into, add those
remappings into your `bootstrap.config` file.

```
config = {
	...
	"dirmap": {
		"tests": "../tests"
	}
}
```

The directory names need to be in quotes.  Also, these paths are relative to the
`"bootstrap"` setting, so mapping tests to `"../tests"`, with a bootstrap
directory `"boot"` will put the tests directory at the parent tree level.

Note that the `bootstrap.config` file is really a Python file in disguise.
You can add any Python syntax you want into it, but it must, in the end,
define the `config` variable.



## Installing Components

To install selected components into your project, run:

```
$ cd my_project_dir
$ python3 (bootstrapdir)/build/install.py
```

You may not want these installed files to be added to your source control.
You can add them into your ignore file, or you can remove these installed
files before checking in.

```
$ cd my_project_dir
$ python3 (bootstrapdir)/build/clean.py
```
