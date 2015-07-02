

# A text label that scrolls on and on.

extends ScrollContainer


var _text

export var indent = "    "


func set_text(text):
	var font = get_font("font", "Label")
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
				print("line [" + t + "]")
				kid = Label.new()
				kid.set_text(t)
				p.add_child(kid)
				height += font.get_height()
				is_newline = true
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
			var size = _get_size(font, t)
			if size.x > width:
				# strip back to previous word
				c = ""
				while c != " ":
					if t.length() <= 0:
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
				print("line [" + t + "]")
				kid = Label.new()
				kid.set_text(t)
				p.add_child(kid)
				height += size.y
				break
		if remaining.empty() && ! t.empty():
			kid = Label.new()
			kid.set_text(t)
			print("line [" + t + "]")
			p.add_child(kid)
			height += font.get_height()
	
	var size = Vector2(width, height)
	q.set_size(size)
	p.set_size(size)


func _get_size(font, text):
	var height = 0
	var width = 0
	var i
	for i in range(0, text.length()):
		var c = text.ord_at(i)
		var n = 0
		if i < text.length() - 1:
			n = text.ord_at(i + 1)
		var s = font.get_char_size(c, n)
		width += s.x
		height = max(height, s.y)
	return Vector2(width, height)
