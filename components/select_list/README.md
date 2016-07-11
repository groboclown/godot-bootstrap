# GUI elements: `select_list`

A list of selectable elements.  Similar to the `ButtonGroup`, but with more
versatile entries.

A `ButtonGroup` is can be used to implement a list of objects to select.
Unfortunately, it has the restriction that any button added will be considered
one of the items to list.  So, if you have a more complex UI where the list
items need to contain a button to perform an operation, then this UI component
is no longer of help.

**Category**: `gui`

## `select_entry`

A simple `Container` that is aware of being selected, and its current state.
These should usually be created through the `select_list` or subclass.
If you want to change the display of the child element based on the entry
state, then you will need to connect to its 3 main signals.

### signal `selected`

Emitted when the entry is "selected", i.e. the user has clicked on it.

### signal `selection_changed(boolean::is_selected)`

Emitted when the entry has its selection state change, either when it changes
from unselected to selected (argument is `true`), or from selected to unselected
(argument is `false`).

### signal `hover(boolean::is_hover)`

Emitted when the hover state for this entry changes.

### var `boolean::is_hover`

### var `boolean::is_selected`


### func `new(Node::obj) : select_entry`

The constructor, which takes the contained object as the argument.  This should
not be directly called if you are using `select_list` or one of its subclasses.

### func `get_entry_node() : Node`

Returns the entry node object that was passed into the constructor.


## `select_list`

`select_list` is a simple container that keeps track of the selected entries.
You will need to manage the entities manually.  All the other lists extend
this object.

### signal `selected(Node::node)`

Emitted when the currently selected entry is changed.  The currently selected
entry node is passed as the argument.

### func `create_entry(Node::node) : selected_entry`

Creates and wires up a new entry that can be inserted into this list.

### func `get_selected_node() : Node`

Returns the node that is currently selected.  The node here is the object passed
to the `create_entry()` method.  If nothing is currently selected, returns
`null`.

### func `get_selected_entry() : selected_entry`

Returns the entry that is currently selected.

## `v_select_list`

`v_select_list` displays the set of entries vertically.


