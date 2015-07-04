
extends Theme

func _init():
	setup_stylebox("normal")
	setup_stylebox("pressed")
	setup_stylebox("hover")
	setup_stylebox("disabled")
	setup_stylebox("focus")
	
	# Setting up button colors:
	#set_color("font_color", "Button", Color(1,1,1,1))
	#set_color("font_color_pressed", "Button", Color(0.6,0.4,0,1))
	#set_color("font_color_hover", "Button", Color(1,0.7,0,1))
	#set_color("font_color_disabled", "Button", Color(0.5,0.5,0.5,1))
	#set_color("font_color_focus", "Button", Color(0.6,0.4,0,1))
	



func setup_stylebox(mode):
	var sb = StyleBoxFlat.new()
	var c = Color(0,0,0,0)
	sb.set_bg_color(c)
	sb.set_border_size(2)
	sb.set_dark_color(c)
	sb.set_light_color(c)
	sb.set_border_blend(false)
	sb.set_default_margin(MARGIN_LEFT, 4)
	sb.set_default_margin(MARGIN_RIGHT, 4)
	sb.set_default_margin(MARGIN_BOTTOM, 4)
	sb.set_default_margin(MARGIN_TOP, 4)
	sb.set_draw_center(true)
	
	set_stylebox(mode, "Button", sb)
