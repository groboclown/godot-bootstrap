
# 


extends "../base.gd"

var stringfunc = preload("res://bootstrap/lib/stringfunc.gd")


func _init():
	add_all([
		"test_format_1",
		"test_format_2",
		"test_padding_1",
		"test_padding_2",
		"test_padding_3",
		"test_padding_4",
		"test_padding_5",
		"test_padding_6",
		"test_padding_7"
	])

func test_format_1():
	var replace_vals = {
		'a': 'A',
		'b': 'B',
		'd': 'D'
	}
	# Note that a variable that is not in the mapping is an error, and the
	# leading escape is removed.
	check_that("format", stringfunc.format("abc!a!b!d!!e!f!", replace_vals, '!'), is("abcABD!ef!"))

func test_format_2():
	var replace_vals = {
		'a': 'A',
		'b': 'B',
		'd': 'D'
	}
	# Note that a variable that is not in the mapping is an error, and the
	# leading escape is removed.
	check_that("format", stringfunc.format("%abc%a%b%%%d%%e%f%", replace_vals), is("AbcAB%D%ef%"))

func test_padding_1():
	check_that("padding", stringfunc.pad_number(100), is("100"))

func test_padding_2():
	check_that("padding", stringfunc.pad_number(1, 3, ' '), is("  1"))

func test_padding_3():
	check_that("padding", stringfunc.pad_number(1, 4), is("0001"))

func test_padding_4():
	check_that("padding", stringfunc.pad_number(1), is("01"))

func test_padding_5():
	check_that("padding", stringfunc.pad_number(0), is("00"))

func test_padding_6():
	check_that("padding", stringfunc.pad_number(-20, 4), is("-0020"))

func test_padding_7():
	check_that("padding", stringfunc.pad_number(20.01, 6), is("020.01"))
