# A GUI overlay component that displays the load game screen.
# It is called through the game_state root node.

# Before the panel is shown, the `setup(savegames)` method must be
# called, or no games will be shown.  Additionally, the
# `reload_games()` method should be called each time before showing
# the UI.


extends Panel


var _savegames
var _filelist = []

var DATETIME = preload("res://bootstrap/lib/datetime.gd")
var ERROR_CODES = preload("res://bootstrap/lib/error_codes.gd")

func _init():
	add_user_signal('cancelled')
	add_user_signal('load', [
		{ 'name': 'filename', 'type': TYPE_STRING }
	])
	connect('visibility_changed', self, '_reload_games', [true])


func setup(savegames):
	# savegames: either a savegames.gd or save_modules.md instance.
	_savegames = savegames


func _ready():
	# Called when this and child nodes are attached to the tree.
	reload_games(false)
	
	# Make sure the scroll list is expanded properly
	var ln = get_node("v/games/games/v")
	ln.connect("minimum_size_changed", self, "_on_gamelist_resized")
	ln.connect("item_rect_changed", self, "_on_gamelist_resized")
	ln.connect("resized", self, "_on_gamelist_resized")
	ln.connect("size_flags_changed", self, "_on_gamelist_resized")
	


func reload_games(reload_cache=true):
	if is_hidden():
		return
	if _savegames == null:
		#print("**USAGE ERROR** Did not initialize load_game")
		return
	var list_node = get_node("v/games/games/v")
	var node
	for node in list_node.get_children():
		list_node.remove_child(node)
	var games_struct = _savegames.get_savegame_infos(reload_cache)
	if games_struct[0] != OK:
		var dialog = load("res://bootstrap/gui/error_dialog.gd").new()
		dialog.show_warning(self, "LOAD_GAME_LIST_ERROR_TITLE", tr("LOAD_GAME_LIST_ERROR_TEXT") + ERROR_CODES.to_string(games_struct[0]), null)
		return
	var game
	var first = true
	_filelist = []
	for game in games_struct[1]:
		_filelist.append(game.file)
		var gn = _create_game_entry(game)
		list_node.add_child(gn)
		if first:
			get_node("v/games/games").set_pressed_button(gn)
			gn.grab_focus()
			first = false



func _create_game_entry(game_md):
	var game_node = CheckButton.new()
	var text = _get_game_button_text(game_md)
	game_node.set_text(text)
	return game_node


func _get_game_button_text(game_md):
	return game_md.name + DATETIME.datetime_to_str(" (%Y-%b-%d %H:%M:%S)", game_md.date, game_md.time)



func _on_load_page_Cancel_pressed():
	# Close the loading screen, which should be just a panel
	# on top of the actual root screen.
	emit_signal('cancelled')


func _get_selected_filename():
	var index = get_node("v/games/games").get_pressed_button_index()
	print("selected game index: "+str(index))
	if index < 0 || index >= _filelist.size():
		# Nothing selected
		return null
	print("selected game: "+_filelist[index])
	return _filelist[index]


func _on_delete_button_pressed():
	var filename = _get_selected_filename()
	if filename == null:
		return
	var err = _savegames.delete_savefile(filename)
	if err != OK:
		var dialog = load("res://bootstrap/gui/error_dialog.gd").new()
		dialog.show_warning(self, "LOAD_GAME_DELETE_ERROR_TITLE", tr("LOAD_GAME_DELETE_ERROR_TEXT") + ERROR_CODES.to_string(err), null)
		#print("failed to delete: " + ERROR_CODES.to_string(err))


func _on_load_button_pressed():
	var filename = _get_selected_filename()
	if filename != null:
		emit_signal('load', filename)


func _on_gamelist_resized():
	var ln = get_node("v/games/games/v")
	var ln_size = ln.get_size()
	var g = get_node("v/games/games")
	var g_size = g.get_size()
	
	g.set_custom_minimum_size(Vector2(max(g_size.x, ln_size.x), ln_size.y))
