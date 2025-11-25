extends Object
var SettingsConfig = ModLoaderConfig.get_config("3ngrindworksmods-Difficulty_Enhancer_Plus_More_Proxies", "settings")
	
var ProxyMultSettings = [1.0, 1.25, 1.5, 1.75, 2.0, 2.5, 3.0, 4.0, 0.5]
var MinimumCogsSettings = [1, 2, 3, 4, 5, 6, 10, 15]
func _ready(chain: ModLoaderHookChain) -> void:
	if not chain.reference_object.boss_battle:
		var COG_OBJECT = load('res://objects/cog/cog.tscn')
		var deficit = MinimumCogsSettings[SettingsConfig.data["Minimum cog amount"]] - chain.reference_object.cogs.size()
		# Add cogs for each deficit
		for i in range(deficit):
			var new_cog = COG_OBJECT.instantiate()
			new_cog.position.x += chain.reference_object.cogs[chain.reference_object.cogs.size() - 1].position.x + chain.reference_object.COG_DISTANCE
			chain.reference_object.cogs.append(new_cog)
			chain.reference_object.add_child(new_cog)
	chain.execute_next()

func get_mod_cog_chance(chain: ModLoaderHookChain) -> float:
	var force_proxy = SettingsConfig.data["All Proxies"] * 999
	var val = chain.execute_next()
	return val * ProxyMultSettings[SettingsConfig.data["Proxy chance multiplier"]] + force_proxy
	
