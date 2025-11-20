extends ItemCharSetup

const MEOWMERS_PRANK_PATH_FOLIO := "res://mods-unpacked/alder-GreenFolio/extensions/objects/items/resources/active/monarch_butterfly.tres"
const MEOWMERS_PRANK_PATH_FOLIO_2 := "res://mods-unpacked/alder-GreenFolio/extensions/objects/items/resources/active/turn_box.tres"

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
	player.stats.extra_jumps = 5
	for track in Util.get_player().stats.gag_balance.keys():
		Util.get_player().stats.gag_regeneration[track] += 3
	if player.stats.current_active_item:
		player.stats.current_active_item = null
	player.stats.current_active_item = GameLoader.load(MEOWMERS_PRANK_PATH_FOLIO).duplicate()
