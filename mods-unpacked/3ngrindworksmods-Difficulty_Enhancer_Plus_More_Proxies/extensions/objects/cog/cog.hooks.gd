extends Object

var SettingsConfig = ModLoaderConfig.get_config("3ngrindworksmods-Difficulty_Enhancer_Plus_More_Proxies", "settings")
var HealthMultSettings = [1.0, 1.20, 1.40, 1.60, 1.80, 2.0, 2.25, 2.5, 2.75, 3, 4, 5, 6, 7, 8, 0.8]
var DamageMultSettings = [1.0, 1.20, 1.40, 1.60, 1.80, 2.0, 2.25, 2.5, 2.75, 3, 4, 100, 0.8]	

func roll_for_dna(chain: ModLoaderHookChain) -> void:
	if chain.reference_object.use_mod_cogs_pool == true and chain.reference_object.health_mod > 1.19:
		chain.reference_object.health_mod /= Util.get_mod_cog_health_mod()
	if SettingsConfig.data["All Proxies"] > 0:
		chain.reference_object.use_mod_cogs_pool = true
	chain.execute_next()
#func roll_for_attributes(chain: ModLoaderHookChain) -> void:
#	if SettingsConfig.data["All Proxies"] > 0:
#		chain.reference_object.use_mod_cogs_pool = true
#	chain.execute_next()


func set_up_stats(chain: ModLoaderHookChain) -> void:
	chain.execute_next()
	print(chain.reference_object.stats.max_hp, " on the ", chain.reference_object.dna.cog_name)
	chain.reference_object.stats.max_hp *= HealthMultSettings[SettingsConfig.data["Health Modifier"]]
	chain.reference_object.stats.hp *= HealthMultSettings[SettingsConfig.data["Health Modifier"]]
	chain.reference_object.stats.damage = 0.4 + (chain.reference_object.level * 0.1) * HealthMultSettings[SettingsConfig.data["Damage Multiplier"]]
	
