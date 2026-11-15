extends ItemCharSetup

func first_time_setup(player : Player) -> void:
	var stats := player.stats
	player.stats.gag_cap = 15
	player.stats.debug_gag_points = false
	player.stats.shop_discount = 7
	player.use_accuracy = 1
	player.alt_gag_hotswap = true
	for track in Util.get_player().stats.gag_balance.keys():
		Util.get_player().stats.gag_regeneration[track] += 4
	#if player.stats.current_active_item:
	#	player.stats.current_active_item = null
	#player.stats.current_active_item = GameLoader.load(AARON_PRANK_PATH).duplicate()
