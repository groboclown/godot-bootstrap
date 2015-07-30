
# Simple String utilities

static func format(format, value_dict, escape='%'):
	var ret = ""
	var part
	var first = true
	var prev_was_escape = false
	for part in format.split(escape, true):
		if first:
			# first string; may be empty
			ret += part
			first = false
		elif part.length() <= 0:
			if ! prev_was_escape:
				ret += escape
			# A "x%%%y" is split into x,,,y
			prev_was_escape = ! prev_was_escape
		else:
			prev_was_escape = false
			var ch = part.left(1)
			if ch in value_dict:
				ret += str(value_dict[ch])
				part = part.right(1)
			ret += part
	return ret
			

static func pad_number(number, min_length = 2, val='0'):
	var ret = str(abs(number))
	while ret.length() < min_length:
		ret = val + ret
	if number < 0:
		ret = '-' + ret
	return ret

