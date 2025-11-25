extends Object

var SettingsConfig = ModLoaderConfig.get_config("3ngrindworksmods-Difficulty_Enhancer_Plus_More_Proxies", "settings")

func spawn_cogs(chain: ModLoaderHookChain,cog_count := 1) -> void:
	var minimum_cogs = max(SettingsConfig.data["Minimum cog amount"], cog_count) 
	chain.execute_next([minimum_cogs])
