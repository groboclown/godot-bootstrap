

# A text label that scrolls on and on.

extends Container


export(int, 0, 1000) var indent_pixels = 20 setget indent_spaces_changed
export(float, 0, 10) var paragraph_separation = 1.8 setget paragraph_separation_changed
export(float, 0, 10) var line_height = 1.5 setget line_height_changed
export(Color, RGBA) var color
export(Font) var font setget font_changed
export(String) var text setget text_changed

var _trtext
var _line_pos = []
var _height = 0
var _changed = false

const CH_SPACE = 32
const CH_TAB = 9
const CH_LF = 13
const CH_CR = 10
const CH_BACKSLASH = 92
const CH_N = 110
const CH_T = 116

func _init():
	connect("resized", self, "recalculate")
	connect("minimum_size_changed", self, "recalculate")
	connect("size_flags_changed", self, "recalculate")


func _ready():
	if get_parent() extends ScrollContainer:
		get_parent().connect("resized", self, "recalculate")
	if _changed:
		recalculate()



func _draw():
	if _changed:
		recalculate()
	var fnt = font
	if fnt == null:
		fnt = get_font("font", "Label")
	var c = color
	if c == null:
		c = get_color("font_color", "Label")
	for line in _line_pos:
		draw_string(fnt, line[1], line[0], c)

func indent_spaces_changed(newval):
	_changed = true

func paragraph_separation_changed(newval):
	_changed = true

func line_height_changed(newval):
	_changed = true

func font_changed(newval):
	_changed = true

func text_changed(newval):
	_changed = true
	_trtext = []
	var t = null
	if newval != null:
		t = tr(newval)
	if t == null:
		return
	# escape the text
	var esc = false
	var txt = ""
	var first = 0
	var i
	for i in range(0, t.length()):
		var ch = t.ord_at(i)
		if esc:
			esc = false
			if ch == CH_N:
				if i - 1 > first:
					txt += t.substring(first, i - 1)
				txt = txt.strip_edges()
				if txt.length() > 0:
					_trtext.append(txt)
				txt = ""
				first = i + 1
			elif ch == CH_T:
				# change to a space
				if i - 1 > first:
					txt += t.substring(first, i - 1)
				txt += ' '
				first = i + 1
			else:
				# Just use the un-escaped value
				first = i
		elif ch == CH_BACKSLASH:
			if i > first:
				txt += t.substr(first, i - first)
			esc = true
		elif (ch == CH_CR || ch == CH_LF):
			if i > first:
				txt += t.substr(first, i - first)
			txt = txt.strip_edges()
			if txt.length() > 0:
				_trtext.append(txt)
			txt = ""
			first = i + 1
		elif ch == CH_TAB:
			if i > first:
				txt += t.substr(first, i - first)
			txt += ' '
			first = i + 1
		# else ch is a normal character; it is just added to the
		# pending substring
	if t.length() > first:
		txt += t.right(first)
		txt = txt.strip_edges()
		if txt.length() > 0:
			_trtext.append(txt)


func recalculate():
	_changed = false
	
	var widget_width = max(get_minimum_size().x, get_size().x)
	if get_parent() != null && get_parent() extends ScrollContainer:
		var pw = get_parent().get_size().x
		if pw > 0:
			var k = get_parent().get_node("_v_scroll")
			if k != null:
				pw -= max(k.get_size().x, 10)
			if pw < widget_width:
				widget_width = pw
	
	var start_x = 0
	var fnt = font
	if fnt == null:
		fnt = get_font("font", "Label")
	var font_height = float(fnt.get_height())
	var psep = int(paragraph_separation * font_height)
	var lsep = int(line_height * font_height)
	_line_pos = []
	# We start drawing strings at the bottom of the string.
	var y_pos = -psep + lsep
	for txt in _trtext:
		# start of an explicit new line
		y_pos += psep
		var tlen = txt.length() - 1
		var tpos
		# We trim the lines, so that they start with non-whitespace
		# Therefore, the first character of a line is the start of the word.
		var linestart_pos = 0
		var wordstart_pos = 0
		var word_width = 0
		var wordend_pos = -1
		var on_space = false
		var x_pos = indent_pixels + start_x
		var width = indent_pixels
		print("line start: 0")
		for tpos in range(0, tlen + 1):
			var ch = txt.ord_at(tpos)
			if ch == CH_SPACE:
				if not on_space:
					print("word end: " + str(tpos))
					on_space = true
					wordend_pos = tpos
					wordstart_pos = -1
					word_width = 0
			else:
				if linestart_pos < 0:
					linestart_pos = tpos
					print("line start: " + str(tpos))
				if wordstart_pos < 0:
					print("word start: " + str(tpos))
					wordstart_pos = tpos
					word_width = 0
				on_space = false
			var cn = 0
			if tpos + 1 <= tlen:
				cn = txt.ord_at(tpos + 1)
			var cw = fnt.get_char_size(ch, cn).x
			width += cw
			word_width += cw
			if tpos >= tlen:
				# end of the line; stick everything into the end.
				# We trim the text, so the last character is non-whitespace.
				print("--eol[" + txt.right(linestart_pos) + "] " + str(width) + "/" + str(widget_width))
				_line_pos.append([
					# text
					txt.right(linestart_pos),
					
					# draw position
					Vector2(x_pos, y_pos)
				])
				# No need to change x_pos or the other loop variables
				y_pos += lsep
			elif width >= widget_width:
				# Soft end of line
				var next_linestart = wordstart_pos
				var next_wordstart = -1
				if wordend_pos < 0:
					# in the middle of the word.
					if wordstart_pos < 0:
						# No word in the line.  Just skip it
						width = 0
						x_pos = start_x
						print("skipped line")
						continue
					# only one word; cut this one at the break.
					# TODO add a hyphen
					wordend_pos = tpos
					next_linestart = tpos
					next_wordstart = tpos
					word_width = 0
					print("word end: " + str(tpos))
				
				print("--sle[" + txt.substr(linestart_pos, wordend_pos - linestart_pos) + "] " + str(width) + "/" + str(widget_width))
				
				# soft end of line
				_line_pos.append([
					# text
					txt.substr(linestart_pos, wordend_pos - linestart_pos),
					
					# draw position
					Vector2(x_pos, y_pos)
				])
				
				x_pos = start_x
				var next_word_width = word_width - width
				width = word_width
				word_width = next_word_width
				y_pos += lsep
				wordstart_pos = next_wordstart
				wordend_pos = -1
				linestart_pos = next_linestart
				print("line start: " + str(linestart_pos))
				print("word start: " + str(wordstart_pos))
				print("word end: -1")
	set_custom_minimum_size(Vector2(widget_width, y_pos))
	

