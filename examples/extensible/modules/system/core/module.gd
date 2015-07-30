# 


var _extpoints


func activate(extpoints):
	# Optional method
	_extpoints = extpoints

func deactivate():
	_extpoints = null

func init_game_data(global_data):
	global_data["player"] = {
		"health": 100,
		"food": 100,
		"inventory": [],
		"location": null
	}
	return {}

