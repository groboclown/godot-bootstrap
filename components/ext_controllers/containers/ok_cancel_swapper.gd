
extends "split_container.gd"

# Sets the "ok" / "cancel" on the correct side.

func _ready():
	var ok = get_node("OK")
	var cancel = get_node("Cancel")
	if ok != null && cancel != null:
		remove_child(ok)
		remove_child(cancel)
		if OS.is_ok_left_and_cancel_right():
			add_child(ok)
			add_child(cancel)
		else:
			add_child(cancel)
			add_child(ok)
