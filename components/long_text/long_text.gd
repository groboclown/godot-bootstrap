

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

var _actual_width
var _minimum_width

const CH_SPACE = 32
const CH_TAB = 9
const CH_LF = 13
const CH_CR = 10
const CH_BACKSLASH = 92
const CH_N = 110
const CH_T = 116

func _init():
	connect("resized", self, "_on_resized")
	connect("minimum_size_changed", self, "_on_minimum_changed")
	connect("size_flags_changed", self, "_on_resized")
	connect("item_rect_changed", self, "_on_resized")


func _ready():
	if get_parent() extends ScrollContainer:
		get_parent().connect("resized", self, "recalculate")
	if _changed:
		recalculate()
	if _actual_width == null:
		_actual_width = get_minimum_size().x

		
func _on_minimum_changed():
	var size = get_minimum_size()
	if _minimum_width == null || size.x != _actual_width:
		# it hasn't been called, or was explicitly changed outside
		# of the below method.
		_minimum_width = size.x
		if _minimum_width > _actual_width:
			_actual_width = _minimum_width
			_changed = true
		

func _on_resized():
	# Prevents the explicit setting of the minimum size below from messing with
	# the actual size.
	var new_width = max(get_minimum_size().x, get_size().x)
	if _actual_width != new_width:
		_actual_width = new_width
		_changed = true
	

func _draw():
	if _changed:
		recalculate()
	var fnt = get_text_font()
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
				txt = txt.strip_edges()
				if txt.length() > 0:
					_trtext.append(txt)
				txt = ""
				first = i + 1
			elif ch == CH_T:
				# change to a space
				if i - 1 > first:
					txt += t.substr(first, i - 1)
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


func get_text_font():
	if font == null:
		return get_font("font", "Label")
	return font


func recalculate():
	_changed = false
	
	var widget_width = _actual_width
	if widget_width == null || widget_width <= 0:
		if _minimum_width == null:
			_minimum_width = get_minimum_size().x
		widget_width = max(get_size().x, _minimum_width)
	if get_parent() != null && get_parent() extends ScrollContainer:
		var pw = get_parent().get_size().x
		if pw > 0:
			var k = get_parent().get_node("_v_scroll")
			if k != null:
				pw -= max(k.get_size().x, 10)
			if pw < widget_width:
				widget_width = pw
	print("width: " + str(widget_width))
	
	var start_x = 0
	var fnt = get_text_font()
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
		for tpos in range(0, tlen + 1):
			var ch = txt.ord_at(tpos)
			if ch == CH_SPACE:
				if not on_space:
					on_space = true
					wordend_pos = tpos
					wordstart_pos = -1
					word_width = 0
			else:
				if linestart_pos < 0:
					linestart_pos = tpos
				if wordstart_pos < 0:
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
				var next_word_width = word_width - width
				if wordend_pos < 0:
					# in the middle of the word.
					if wordstart_pos < 0:
						# No word in the line.  Just skip it
						width = 0
						x_pos = start_x
						continue
					# only one word; cut this one at the break.
					# TODO add a hyphen
					wordend_pos = tpos
					next_linestart = tpos
					next_wordstart = tpos
					word_width = cw
					next_word_width = cw
				
				# soft end of line
				_line_pos.append([
					# text
					txt.substr(linestart_pos, wordend_pos - linestart_pos),
					
					# draw position
					Vector2(x_pos, y_pos)
				])
				
				x_pos = start_x
				width = word_width
				word_width = next_word_width
				y_pos += lsep
				wordstart_pos = next_wordstart
				wordend_pos = -1
				linestart_pos = next_linestart
				
	set_custom_minimum_size(Vector2(widget_width, y_pos))
	

