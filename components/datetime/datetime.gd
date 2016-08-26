
# Date and time utilities
# Note: due to limitations of GDScript (static functions cannot reference the
# original script), this must be instantiated to be used.

# OS.get_time() returns: {
#   'hour': int, 'minute': int, 'second': int
# }
# OS.get_date() returns: {
#   'day': int, 'dst': boolean, 'month': int, 'weekday': int, 'year': int
# }

# Conforms to many of the Standard C (1989 version) datetime string format
# parameters.
# The name translations (weekday name, month name) must be provided, or the
# en_US version will be returned.

# Date calculations are based upon Gregorian Calendar.



static func date_to_str(format, date_obj=null):
	if date_obj == null:
		date_obj = OS.get_date()
	return preload("stringfunc.gd").format(format, preload("datetime/formats.gd").date_values({}, date_obj))


static func time_to_str(format, time_obj=null):
	if time_obj == null:
		time_obj = OS.get_time()
	return preload("stringfunc.gd").format(format, preload("datetime/formats.gd").time_values({}, time_obj))


static func datetime_to_str(format, date_obj=null, time_obj=null):
	if date_obj == null:
		date_obj = OS.get_date()
	if time_obj == null:
		time_obj = OS.get_time()
	var formats = preload("datetime/formats.gd")
	var vals = formats.date_values({}, date_obj)
	vals = formats.time_values(vals, time_obj)
	return preload("stringfunc.gd").format(format, vals)


const _DAYS_IN_MONTH = [-1, 31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31]

# number of days in 400 years
#   y = 401, y*365 + y/4 - y/100 + y/400
const _DAYS_IN_400Y = 146097
# number of days in 100 years
#   y = 101, y*365 + y/4 - y/100 + y/400
const _DAYS_IN_100Y = 36524
# number of days in 4 years
#   y = 5, y*365 + y/4 - y/100 + y/400
const _DAYS_IN_4Y = 1461

static func date_add(date_obj, days):
	# Adds the date delta (which is a get_date() structure, but only the
	# Month, day, and year matter).

	return _ord_to_date(_date_to_ord(date_obj) + days)




static func _is_leapyear(year):
	return year % 4 == 0 and (year % 100 != 0 or year % 400 == 0)

static func _date_to_ord(date_obj):
	# Converts a valid date object to days since Jan 1, year 1 (which is day 0).
	var month = int(date_obj["month"])
	var year = int(date_obj["year"])
	var day = int(date_obj["day"])
	assert(month >= 1 && month <= 12)

	var days_in_month
	if month == 2 and _is_leapyear(year):
		days_in_month = 29
	else:
		days_in_month = _DAYS_IN_MONTH[date_obj["month"]]
	assert(day >= 1 && day <= days_in_month)

	# Day 0 == Jan 1, so subtract a day
	day -= 1

	# Days before year:
	var y = year - 1
	day += y*365 + y/4 - y/100 + y/400

	# Days before month, for this year
	var i
	for i in range(1, month):
		if i == 2 and _is_leapyear(year):
			day += 29
		else:
			day += _DAYS_IN_MONTH[i]

	return day


static func _ord_to_date(ord):
	# Converts days since Jan 1, year 1, to a date object.
	# Note that day 0 is a Sunday.  We're not caring about the
	# Julian / Gegorian calendar changes.

	var ret = {
		"year": 0,
		"day": 0,
		"month": 0,
		"dst": false,
		# + 1 here because that's just how the calendar lines up once we're
		# in the modern era.
		"weekday": (ord + 1) % 7
	}

	var n400 = ord / _DAYS_IN_400Y
	var n = ord % _DAYS_IN_400Y
	var year = n400 * 400 + 1

	var n100 = n / _DAYS_IN_100Y
	n = n % _DAYS_IN_100Y

	var n4 = n / _DAYS_IN_4Y
	n = n % _DAYS_IN_4Y

	var n1 = n / 365
	n = n % 365

	year += n100 * 100 + n4 * 4 + n1
	if n1 == 4 or n100 == 4:
		assert(n != 0)
		ret["year"] = year - 1
		ret["month"] = 12
		ret["day"] = 31
		return ret
	ret["year"] = year

	var is_leapyear = _is_leapyear(year)
	var month = 1
	# n is base 0, so do >= comparison
	while n >= _DAYS_IN_MONTH[month]:
		n -= _DAYS_IN_MONTH[month]
		month += 1
		assert(month <= 12)
	ret["day"] = n + 1
	ret["month"] = month
	return ret
