extends Object

func vanilla_816431232_action(chain: ModLoaderHookChain) -> void:
	var user_cog : Cog = chain.reference_object.user
	
	chain.reference_object.battle_node.focus_character(user_cog)
	await chain.reference_object.manager.sleep(3.0)
	
	var new_cogs : Array[Cog] = []
	
	# Create our new Cog objects
	for i in chain.reference_object.cog_amount:
		var new_cog = chain.reference_object.COG_OBJECT.instantiate()
		new_cogs.append(new_cog)
		new_cog.hide()
		chain.reference_object.battle_node.add_child(new_cog)
		new_cog.battle_start()
		BattleService.ongoing_battle.add_cog(new_cog)
	
	for cog : Cog in chain.reference_object.battle_node.cogs:
		if cog in new_cogs:
			cog.global_position = chain.reference_object.battle_node.get_cog_position(cog)
			chain.reference_object.battle_node.face_battle_center(cog)
			cog.fly_in(20.0, 0.0)
			cog.show()
		else:
			cog.move_to(chain.reference_object.battle_node.get_cog_position(cog)).finished.connect(func(): chain.reference_object.battle_node.face_battle_center(cog))
	
	chain.reference_object.battle_node.focus_cogs()
	chain.reference_object.battle_node.battle_cam.position.z += 2.0
	await chain.reference_object.manager.sleep(5.0)


# ModLoader Hooks - The following code has been automatically added by the Godot Mod Loader.


func action(chain: ModLoaderHookChain):
	if _ModLoaderHooks.any_mod_hooked:
		await _ModLoaderHooks.call_hooks_async(vanilla_816431232_action, [chain], 1604151486)
	else:
		await vanilla_816431232_action(chain)
