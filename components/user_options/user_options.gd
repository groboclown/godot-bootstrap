
extends Node


# Stores and updates user options.

var initialized = false
var _options
var _name = "user://user_options.json"



func load_options():
	if initialized:
		return
	var f = File.new()
	var err = f.open(_name, File.READ)
	if err == OK:
		var text = f.get_as_text()
		_options = {}
		_options.parse_json(text)
	else:
		# Error handling:
		# if there is an option load problem, then we
		# silently ignore it.  It's only with save that
		# we show an issue.
		#if err == ERR_FILE_NOT_FOUND || err == ERR_FILE_CANT_OPEN:
		#show_error(_name + " (" + str(err) + ")")
		pass
	
	# TODO check if options is also not a dictionary
	if _options == null || _options.keys().empty():
		# create new options
		
		initialized = true
		_options = {}
		set_master_volume(100)
		set_music_volume(100)
		set_fx_volume(100)
		set_module_order([])
	
	f.close()
	initialized = true

	_apply_option_values()


func set_master_volume(value):
	# Range between 0 and 100
	set_option("volume_master", _convert_percent(value))
	_apply_audio_values()

func get_master_volume():
	# Range between 0 and 100
	return _convert_percent(get_option("volume_master"))

func set_music_volume(value):
	# Range between 0 and 100
	set_option("volume_music", _convert_percent(value))
	_apply_audio_values()

func get_music_volume():
	# Range between 0 and 100
	return _convert_percent(get_option("volume_music"))

func set_fx_volume(value):
	# Range between 0 and 100
	set_option("volume_fx", _convert_percent(value))
	_apply_audio_values()

func get_fx_volume():
	# Range between 0 and 100
	return _convert_percent(get_option("volume_fx"))


func get_module_order():
	# Return a list of [ name, [version_major, version_minor] ]
	var order = get_option("active_modules")
	if order == null:
		order = []
	return order


func set_module_order(module_order):
	# Sets the option for the module order; does not actually affect
	# the module order.  That must be done through the
	# modules.set_module_order() method.
	var order = []
	if typeof(module_order) == TYPE_ARRAY:
		for ml in module_order:
			if typeof(ml) == TYPE_ARRAY && ml.size() == 2 && typeof(ml[0]) == TYPE_STRING && typeof(ml[1]) == TYPE_ARRAY && ml[1].size() == 2:
				order.append([ ml[0], [ int(ml[1][0]), int(ml[1][1]) ] ])
	set_option("active_modules", order)


func save_options():
	if initialized:
		var f = File.new()
		var err = f.open(_name, File.WRITE)
		if err == OK:
			f.store_line(_options.to_json())
		else:
			show_error(_name + " (" + str(err) + ")", false)
		f.close()


func get_option(name):
	if initialized and name in _options:
		#print("Option " + name + " = " + str(_options[name]))
		return _options[name]
	elif _options == null:
		print("Options are null")
		return null
	else:
		print("Option " + name + " not set")
		print_stack()
		return null

func set_option(name, value):
	if ! initialized:
		load_options()
	#print("Option " + name + " <- " + str(value))
	_options[name] = value
	#_apply_option_values()


func show_error(details, unrecoverable):
	var dialog = preload("res://scenes/common/error_dialog.xscn").instance()
	dialog.show_error(self, "ERROR_RESOURCE_LOADING", details, unrecoverable)




func _apply_option_values():
	# Apply the option version of the values to the system
	# settings
	
	_apply_audio_values()


func _apply_audio_values():
	# Apply the GUI version of the values to the system settings.
	var vol_master = float(get_master_volume()) / 100.0
	var vol_fx = vol_master * float(get_fx_volume()) / 100.0
	var vol_music = vol_master  * float(get_music_volume()) / 100.0
	AudioServer.set_fx_global_volume_scale(vol_fx)
	AudioServer.set_stream_global_volume_scale(vol_music)


func _convert_percent(val):
	if val == null:
		return 100.0
	else:
		val = convert(val, TYPE_REAL)
		if val == null:
			return 100.0
	return 1.0 * clamp(val, 0.0, 100.0)
