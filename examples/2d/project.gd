
extends Panel

# member variables here, example:
# var a=2
# var b="textvar"

func _ready():
	# Initialization here
	var menu = get_node("menu/ButtonMenu")
	menu.set_buttons([
		{
			"name": "Show Error Dialog",
			"obj": self,
			"func": "_on_Show_Error_Dialog"
		},
		{
			"name": "Show scroll text",
			"obj": self,
			"func": "_on_BigText_display"
		},
		{
			"name": "Show side-by-side",
			"obj": self,
			"func": "_on_SideBySide_display"
		},
		{
			"name": "No-op sub-menu example",
			"obj": self,
			"type": "menu",
			"func": "_create_show_submenu"
		}
	])


func _on_Show_Error_Dialog():
	var error_dialog = preload("boot/error_dialog.gd").new()
	error_dialog.show_warning(self, "Example Error Dialog", "BigError", "clicked", "_on_BigError")

func _on_BigError():
	print("BigError cleanup")

func _on_BigText_display():
	get_node("BigText/text").set_text("Take a seat and have a drink.  I'm going to tell you a story\nOnce there was a girl.\nShe lived in a castle.\nThe was eaten by a really large werewolf, but she survived in its belly.  It was really warm in there.  She made it into a cozy home.\nShe then wrote a game using Godot, and it became wildly popular.  Unfortunately, she was trapped inside the belly of a werewolf, and didn't know what people thought of it.\nThen she escaped and became queen of the world.\nThe end.")
	get_node("BigText").show()

func _on_SideBySide_display():
	get_node("SideBySide").show()

func _on_BigText_OK_pressed():
	get_node("BigText").hide()


func _on_SideBySide_OK_pressed():
	get_node("SideBySide").hide()

func _create_show_submenu():
	var ret = []
	for i in range(0, 15):
		ret.append({ "name": "show " + str(i), "obj": self, "func": "_noop" })
	return ret
	
func _noop():
	pass
