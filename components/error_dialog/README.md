# GUI element: `error_dialog`

Displays an error dialog to the user.  Allows the dialog to force a quit
if it's an unrecoverable error, or optionally additional actions.

**Category**: `gui`

## Usage

The general usage is to create a new instance, then run one of the `show_*`
functions.

```
var err_dialog = preload("bootstrap/gui/error_dialog.gd").new()
err_dialog.show_warning(self, "Horrible Error!", "There was a horrible error.", err_code)
```

This will add the dialog to the node (first parameter), and display it
in the center of the screen with a single **OK** button.


### func `show_warning(Node::node, String::title, String::error_type, Variant::details, String::callback = null)`

Simply displays the error dialog.  It has `title` as the dialog window title,
and the displayed text will be `(error_type): (details)`.  If the optional
`callback` parameter is given, the `node`'s function named `callback` will
be invoked when the **OK** button is pressed.  The dialog will close when
when the button is pressed.

### func `show_unrecoverable_error(Node::node, String::title, String::error_type, Variant::details)`

Displays the error dialog, and will quit the program when the **OK** button
is pressed.

