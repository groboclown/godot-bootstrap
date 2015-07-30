
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
