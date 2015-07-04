
extends CenterContainer

var _button_name
var _button_obj
var _button_func
var _is_menu
var _parent

func _init(is_horizontal):
	if is_horizontal:
		set_anchor_and_margin(MARGIN_BOTTOM, ANCHOR_END, 0)
	else:
		set_anchor_and_margin(MARGIN_RIGHT, ANCHOR_END, 0)
		


func set_button(button, parent):
	_button_name = button["name"]
	_button_obj = button["obj"]
	_button_func = button["func"]
	if "type" in button && button["type"] == "menu":
		_is_menu = true
		_parent = parent
	else:
		_is_menu = false


func _on_Button_pressed():
	var res = _button_obj.call(_button_func)
	if _is_menu && _parent != null:
		_parent.on_menu(res)


func _ready():
	# On entered tree
	if _button_name != null:
		var button = Button.new()
		button.set_text(tr(_button_name))
		button.connect("pressed", self, "_on_Button_pressed")
		add_child(button)
