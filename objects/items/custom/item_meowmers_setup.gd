extends ItemCharSetup

const MEOWMERS_PRANK_PATH := "res://objects/items/resources/active/doodle_chest.tres"
const MEOWMERS_PRANK_PATH_TEST := "res://objects/items/resources/active/anomaly_tester.tres"


func first_time_setup(player : Player) -> void:
	var stats := player.stats
	player.stats.gags_unlocked['Sound'] = 2
	player.stats.gags_unlocked['Throw'] = 2
	player.stats.gag_effectiveness['Squirt'] = 1.0
	player.stats.funny_dance = true
	player.stats.pink_slips = 5
	player.stats.gag_cap = 20
	player.stats.debug_gag_points = false
	player.stats.meowmersdragonwings = true
	player.stats.shop_discount = 15
	player.stats.luck = 0.25
	player.use_accuracy = 1
	for track in Util.get_player().stats.gag_balance.keys():
		Util.get_player().stats.gag_regeneration[track] += 3
