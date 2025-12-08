extends FloorModifier

const COG_OBJECT := preload('res://objects/cog/cog.tscn')

func modify_floor() -> void:
	BattleService.s_battle_spawned.connect(on_battle_spawned)

func on_battle_spawned(battle: BattleNode) -> void:
	var deficit = RandomService.randi_range_channel('overstaffed_random_number', 1, 4) #- chain.reference_object.cogs.size()
	if battle.get_script().resource_path.contains("dynamic"):
		for i in range(deficit):
			var new_cog := COG_OBJECT.instantiate()
			new_cog.position.x += battle.cogs[battle.cogs.size() - 1].position.x + battle.COG_DISTANCE
			battle.cogs.append(new_cog)
			battle.add_child(new_cog)

func get_mod_name() -> String:
	return "Overstaffed"

func get_mod_icon() -> Texture2D:
	return load("res://mods-unpacked/Meowmers101-Cog_Amount_Anomaly/extensions/ui_assets/player_ui/pause/overstaffed.png")

func get_description() -> String:
	return "Battles may have more than 4 cogs."

func get_mod_quality() -> ModType:
	return ModType.NEGATIVE
