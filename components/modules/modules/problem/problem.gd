
extends AcceptDialog

var bad_modules

var errors = preload("res://bootstrap/lib/error_codes.gd")

func setup(modules):
	bad_modules = modules

func _ready():
	get_ok().connect("pressed", self, "_on_failure_confirmed")
	set_as_toplevel(true)
	var c = get_node("v/c/v")
	var md
	for md in bad_modules:
		var n = Label.new()
		n.set_text(md.name + " v" + str(md.version[0]) + "." + str(md.version[1]))
		c.add_child(n)
		n = Label.new()
		# note that the details are not translated.
		n.set_text(" --> " + tr(errors.to_string(md.error_code)) + " - " + tr(md.error_operation) + " " + md.error_details)
		c.add_child(n)
	show()
	popup_centered()
	set_exclusive(true)


func _on_failure_confirmed():
	hide()
	get_parent().remove_child(self)

