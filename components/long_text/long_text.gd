

# A text label that scrolls on and on.

extends ScrollContainer


var _text

export var indent_spaces = 4
export var paragraph_separation = 1.5

func set_text(text):
	var indent = ""
	for i in range(0, indent_spaces):
		indent += " "
	var font = get_font("font", "Label")
	var font_height = font.get_height()
	var par_sep_height = font_height * paragraph_separation
	text = text.replace("\\n", "\n")
	print("Displaying [" + text + "]")
	var width = get_size().x
	var kid
	for kid in get_children():
		if kid extends Panel:
			remove_child(kid)
	var q = PanelContainer.new()
	add_child(q)
	var p = VBoxContainer.new()
	q.add_child(p)

	var remaining = text
	var is_newline = true
	var needs_linesep = false
	var height = 0
	while remaining.length() > 0:
		# create a single line of text
		var t = ""
		if is_newline:
			t = indent
			is_newline = false
		var is_linestart = true
		var is_space = false
		while remaining.length() > 0:
			var c = remaining.left(1)
			remaining = remaining.right(1)
			if c == "\n":
				# Forced newline
				if needs_linesep:
					kid = Control.new()
					kid.set_custom_minimum_size(Vector2(0, par_sep_height))
					height += par_sep_height
					p.add_child(kid)
					# this is set to true later
					#needs_linesep = false
				kid = Label.new()
				kid.set_text(t)
				p.add_child(kid)
				height += font_height
				is_newline = true
				needs_linesep = true
				break
			if c == " ":
				is_space = true
				continue
			elif is_space:
				if ! is_linestart:
					c = " " + c
			t = t + c
			is_space = false
			is_linestart = false
			var size_x = _get_size(font, t)
			if size_x > width:
				# strip back to previous word
				c = ""
				while c != " ":
					if t.length() <= 0:
						# TODO split the word artificially
						# ERROR BEEP BEEP
						print("too small for text")
						return
					c = t.right(t.length() - 1)
					remaining = c + remaining
					t = t.left(t.length() - 1)
				# strip off any trailing whitespace
				while true:
					c = t.right(t.length() - 1)
					if c != " ":
						break
					# don't need to add back to remaining
					t = t.left(t.length() - 1)
				#print("line [" + t + "]")
				if needs_linesep:
					kid = Control.new()
					kid.set_custom_minimum_size(Vector2(0, par_sep_height))
					height += par_sep_height
					p.add_child(kid)
					
					needs_linesep = false
				kid = Label.new()
				kid.set_text(t)
				p.add_child(kid)
				height += font_height
				break
		if remaining.empty() && ! t.empty():
			if needs_linesep:
				kid = Control.new()
				kid.set_custom_minimum_size(Vector2(0, par_sep_height))
				height += par_sep_height
				p.add_child(kid)
				# this is set to true later
				#needs_linesep = false
			kid = Label.new()
			kid.set_text(t)
			print("line [" + t + "]")
			p.add_child(kid)
			height += font_height
	
	var size = Vector2(width, height)
	q.set_size(size)
	p.set_size(size)


func _get_size(font, text):
	#var height = 0
	var width = 0
	var i
	for i in range(0, text.length()):
		var c = text.ord_at(i)
		var n = 0
		if i < text.length() - 1:
			n = text.ord_at(i + 1)
		var s = font.get_char_size(c, n)
		width += s.x
		#height = max(height, s.y)
	return width

