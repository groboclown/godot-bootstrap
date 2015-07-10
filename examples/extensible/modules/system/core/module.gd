# 


var _extpoints


func activate(extpoints):
	# Optional method
	_extpoints = extpoints

func deactivate():
	_extpoints = null

func init_game_data(game_data):
	game_data["player"] = {
		"health": 100,
		"food": 100,
		"inventory": [],
		"location": null
	}
	
func init_custom_data():
	return {}
