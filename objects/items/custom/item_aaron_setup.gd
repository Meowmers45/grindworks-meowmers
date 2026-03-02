extends ItemCharSetup

const AARON_PRANK_PATH := "res://objects/items/resources/active/gag_button.tres"

func first_time_setup(player : Player) -> void:
	var stats := player.stats
	player.stats.gags_unlocked['Sound'] = 2
	player.stats.gags_unlocked['Drop'] = 1
	player.stats.luck = 0.15
	player.stats.crit_mult = 1.25
	player.stats.funny_dance = true
	player.stats.pink_slips = 2
	player.stats.gag_cap = 15
	player.stats.debug_gag_points = false
	player.stats.shop_discount = 7
	player.use_accuracy = 1
	Util.get_player().alt_gag_hotswap = true
	player.stats.extra_jumps = 5
	for track in Util.get_player().stats.gag_balance.keys():
		Util.get_player().stats.gag_regeneration[track] += 3
	#if player.stats.current_active_item:
	#	player.stats.current_active_item = null
	#player.stats.current_active_item = GameLoader.load(AARON_PRANK_PATH).duplicate()
