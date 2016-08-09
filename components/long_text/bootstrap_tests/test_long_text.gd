

extends "../base.gd"

var long_text = preload("res://bootstrap/gui/long_text.gd")
var widget

func _init():
	add_all([
		"test_text_line_split",
		"test_recalculate_splitword"
	])


func test_text_line_split():
	widget.text_changed("1\n2\\n3\n   4\r\n	 5	 \n6")
	var split_lines = widget._trtext
	if ! check_that("split lines", split_lines, is_not(null)):
		return

	if ! check_that("split lines count", split_lines, SizeMatcher.new(6)):
		return
	var i = 0
	for line in split_lines:
		i += 1
		check_that("split line[" + str(i) + "]", line, is(str(i)))


func test_recalculate_splitword():
	# 1 character = 10 pixels.  This is 60 characters long.  The widget width
	# is 101 to 110 pixels.  10 characters = 1 line (the check is <=).
	# We set no indention.

	widget.indent_pixels = 0
	widget.paragraph_separation = 1
	widget.line_height = 1
	widget.text = "012345678901234567890123456789012345678901234567890123456789"
	if ! check_that("split lines", widget._trtext, is_not(null)):
		return

	for width in range(101,111):
		widget._actual_width = width
		widget.recalculate()
		#print(" --- " + str(widget._line_pos.size()))
		#for ln in widget._line_pos:
		#	print(" --- --- " + str(ln))

		# TODO FIX this broken test
		#if ! check_that("width cut lines count", widget._line_pos, SizeMatcher.new(6)):
		#	continue
		#var i = 0
		#for line_spec in widget._line_pos:
		#	i += 1
		#	check_that("line " + str(i) + " text", line_spec[0], is("0123456789"))
		#	check_that("line " + str(i) + " pos", line_spec[1], is(Vector2(0, i * 15)))



func setup():
	widget = long_text.new()
	widget._actual_width = 101
	widget.font = MockFont.new()



class SizeMatcher:
	#extends Matcher

	var expected_size

	func _init(size):
		expected_size = size

	func matches(value):
		return value != null && value.size() == expected_size

	func describe(value):
		return "expected " + str(expected_size) + " elements, found " + str(value)


class MockFont:
	var height = 15
	var width = 10

	func get_height():
		return height

	func get_char_size(ord1, ord2 = 0):
		return Vector2(width, height)
