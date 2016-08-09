
#


extends "../base.gd"

var datetime = preload("res://bootstrap/lib/datetime.gd")


func _init():
	add_all([
		"test_date_padding",
		"test_date_nopadding",
		"test_time_12am",
		"test_time_12pm",
		"test_time_am",
		"test_time_pm",
		"test_datetime",
		"test_os"
	])

func test_date_padding():
	var date = {
		'day': 5, 'dst': true, 'month': 3, 'weekday': 6, 'year': 1900
	}
	check_that("date_to_str", datetime.date_to_str("@%y.%Y/%d,%m-%w%%%a^%A$%b*%B+", date), is("@00.1900/05,03-6%Sat^Saturday$Mar*March+"))

func test_date_nopadding():
	var date = {
		'day': 13, 'dst': false, 'month': 12, 'weekday': 6, 'year': 2013
	}
	check_that("date_to_str", datetime.date_to_str("@%y.%Y/%d,%m-%b*%B+", date), is("@13.2013/13,12-Dec*December+"))

func test_time_12am():
	var time = {
		'hour': 0, 'minute': 12, 'second': 59
	}
	check_that("time_to_str", datetime.time_to_str("-%I:%H:%M:%S@%p-", time), is("-12:00:12:59@AM-"))

func test_time_12pm():
	var time = {
		'hour': 12, 'minute': 2, 'second': 0
	}
	check_that("time_to_str", datetime.time_to_str("-%I:%H:%M:%S@%p-", time), is("-12:12:02:00@PM-"))

func test_time_am():
	var time = {
		'hour': 2, 'minute': 59, 'second': 1
	}
	check_that("time_to_str", datetime.time_to_str("-%I:%H:%M:%S@%p-", time), is("-02:02:59:01@AM-"))

func test_time_pm():
	var time = {
		# Test leap seconds!
		'hour': 13, 'minute': 0, 'second': 60
	}
	check_that("time_to_str", datetime.time_to_str("%I:%H:%M:%S@%p-", time), is("01:13:00:60@PM-"))

func test_datetime():
	pass

func test_os():
	pass
