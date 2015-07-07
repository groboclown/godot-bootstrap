
extends AcceptDialog

var bad_modules

func _init(modules):
	bad_modules = modules

func _ready():
	get_ok().connect("pressed", self, "_on_failure_confirmed")
	set_as_toplevel(true)
	var c = get_node("v/c/v")
	var md
	for md in bad_modules:
		var n = Label()
		n.set_text(md.name + " v" + str(md.version[0]) + "." + str(md.version[1]))
		c.add_child(n)
	show()
	popup_centered()
	set_exclusive(true)
	get_label().set_text("MODULE_LOAD_PROBLEM")


func _on_failure_confirmed():
	hide()
	get_parent().remove_child(self)

