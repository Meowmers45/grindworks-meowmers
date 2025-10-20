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
		manager.battle_stats[Util.get_player()].turns += 4
		manager.battle_ui.refresh_turns()
	elif Util.get_player().character.character_name == "Aaron":
		manager.battle_stats[Util.get_player()].turns += 2
		manager.battle_ui.refresh_turns()
	else:
		return
