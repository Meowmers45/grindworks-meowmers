extends ItemScript


func on_collect(_item: Item, _object: Node3D) -> void:
	setup()

func on_load(_item: Item) -> void:
	setup()

func setup() -> void:
	BattleService.s_battle_started.connect(on_battle_started)

func on_battle_started(manager: BattleManager) -> void:
	await get_tree().process_frame
	if Util.get_player().character.character_name == "Meowmers":
		Util.get_player().use_accuracy = 1
		Util.get_player().alt_gag_hotswap = true
		manager.battle_ui.refresh_tracks()
	elif Util.get_player().character.character_name == "Aaron":
		Util.get_player().use_accuracy = 1
		Util.get_player().alt_gag_hotswap = true
		manager.battle_ui.refresh_tracks()
	elif Util.get_player().character.character_name == "Bubbles" and Util.get_player().stats.abbie:
		Util.get_player().use_accuracy = 1
		Util.get_player().alt_gag_hotswap = true
		manager.battle_ui.refresh_tracks()
	else:
		return
