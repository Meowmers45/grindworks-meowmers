extends Object

func randomize_objective(chain: ModLoaderHookChain) -> void:
	chain.reference_object.quota = RandomService.randi_range_channel('quests',chain.reference_object.OBJECTIVE_RANGE.x,chain.reference_object.OBJECTIVE_RANGE.y)
	var quotaf := float(chain.reference_object.quota)
	
	var quest_type = RandomService.randi_channel('cog_quest_types') % 3
	if quest_type == 1:
		quest_type = 2
	if quest_type == 1 and chain.reference_object.prev_quest_roll == 1:
		quest_type += 1 * RandomService.array_pick_random('cog_quest_types', [-1, 1])
	
	var minimum_level := maxi(1, min(4, Util.floor_number + 1))
	var maximum_level := maxi(2, min(7, Util.floor_number + 3))
	
	
	# 33% chance of department specific
	if quest_type == 0:
		chain.reference_object.department = chain.reference_object.goal_dept
	elif quest_type == 1:
		quest_type = 2
		#var cog_pool : CogPool
		#match chain.reference_object.goal_dept:
		#	CogDNA.CogDept.SELL:
		#		cog_pool = load('res://objects/cog/presets/pools/sellbot.tres')
		#	CogDNA.CogDept.CASH:
		#		cog_pool = load('res://objects/cog/presets/pools/cashbot.tres')
		#	CogDNA.CogDept.LAW:
		#		cog_pool = load('res://objects/cog/presets/pools/lawbot.tres')
		#	CogDNA.CogDept.BOSS:
		#		cog_pool = load('res://objects/cog/presets/pools/bossbot.tres')
				
		#chain.reference_object.specific_cog = cog_pool.cogs[RandomService.randi_range_channel("cog_quest_types", minimum_level, maximum_level)]
	
	# Reduce quotas for more specific quest types
	if not chain.reference_object.department == CogDNA.CogDept.NULL:
		quotaf /= 2.0
	elif chain.reference_object.specific_cog:
		quotaf /= 4.0
	
	# Level minimum objectives
#	if RandomService.randi_channel('cog_quest_types') % 3 == 0:
#		if chain.reference_object.specific_cog:
#			chain.reference_object.min_level = RandomService.randi_range_channel('cog_quest_types',chain.reference_object.specific_cog.level_low + 1,chain.reference_object.specific_cog.level_low + 3)
#			if chain.reference_object.min_level > chain.reference_object.specific_cog.level_high or chain.reference_object.min_level > maximum_level: 
#				chain.reference_object.min_level = 1
#		else:
#			chain.reference_object.min_level = RandomService.randi_range_channel('cog_quest_types',minimum_level,maximum_level)
	
#	if chain.reference_object.min_level > 1:
	#	chain.reference_object.quotaf /= maxf(chain.reference_object.min_level/4.0,1.25)
	
	chain.reference_object.quota = int(round(quotaf))
