

extends "../base.gd"

var errors = preload("res://bootstrap/lib/error_codes.gd")

func _init():
	add_all([
		"test_builtin",
		"test_extend"
	])


func test_builtin():
	check_that("did not encode OK message", errors.to_string(OK), is("OK"))
	
func test_extend():
	errors.add_code(-100, "MY_CUSTOM_ERROR")
	check_that("did not encode custom error", errors.to_string(-100), is("MY_CUSTOM_ERROR"))

