

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


static func date_values(ret, date):
	var stringfunc = preload("../stringfunc.gd")
	ret['y'] = stringfunc.pad_number(int(date.year) % 100)
	ret['Y'] = str(int(date.year))
	ret['d'] = stringfunc.pad_number(int(date.day))
	ret['D'] = str(int(date.day))
	ret['m'] = stringfunc.pad_number(int(date.month))
	ret['w'] = str(int(date.weekday))
	ret['a'] = tr(['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'][int(date.weekday)])
	ret['A'] = tr(['Sunday', 'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday'][int(date.weekday)])
	ret['b'] = tr(['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'][int(date.month) - 1])
	ret['B'] = tr(['January', 'February', 'March', 'April', 'May', 'June', 'July', 'August', 'September', 'October', 'November', 'December'][int(date.month) - 1])
	return ret

static func time_values(ret, time):
	var stringfunc = preload("../stringfunc.gd")
	var ampm
	var hour = int(time.hour)
	var hour12
	if hour == 0:
		ampm = 'AM'
		hour12 = 12
	elif hour < 12:
		ampm = 'AM'
		hour12 = hour
	elif hour == 12:
		ampm = 'PM'
		hour12 = 12
	else:
		ampm = 'PM'
		hour12 = hour - 12

	ret['I'] = stringfunc.pad_number(hour12)
	ret['H'] = stringfunc.pad_number(hour)
	ret['M'] = stringfunc.pad_number(int(time.minute))
	ret['S'] = stringfunc.pad_number(int(time.second))
	ret['p'] = tr(ampm)
	return ret

