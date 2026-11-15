extends ActionScript
class_name ToonPartnerAction

const BUFF_CHANCE := 0.075
const ALLOWED_TRACKS: Array[String] = ["Throw", "Squirt", "Sound", "Drop", "Lure", "Trap"]
const BUFF_STATS: Array[String] = ['damage', 'defense', 'evasiveness', 'luck']
const STAT_BOOST_REFERENCE := preload("res://objects/battle/battle_resources/status_effects/resources/status_effect_stat_boost.tres")


func action():
	if manager.cogs.is_empty():
		return
	var gags := get_available_gags()
	if gags.is_empty() or RNG.channel(RNG.ChannelTrueRandom).randf() < BUFF_CHANCE:
		await buff_player()
	else:
		await use_gag(RNG.channel(RNG.ChannelTrueRandom).pick_random(gags))
	if is_instance_valid(user):
		user.toon.show()
		user.face_position(manager.battle_node.global_position)
		user.set_animation('neutral')

## Every damaging Gag the player currently has unlocked
func get_available_gags() -> Array[ToonAttack]:
	var gags: Array[ToonAttack] = []
	var stats: PlayerStats = Util.get_player().stats
	for track: Track in stats.character.gag_loadout.loadout:
		if not track.track_name in ALLOWED_TRACKS:
			continue
		var unlocked: int = stats.gags_unlocked.get(track.track_name, 0)
		for i in mini(unlocked, track.gags.size()):
			var gag: ToonAttack = track.gags[i]
			if gag and (gag.damage > 0 or gag is GagLure):
				gags.append(gag)
	return gags.filter(func(g: ToonAttack): return not get_valid_cogs(g).is_empty())

## Cogs this gag would actually do something to (skips already lured/trapped Cogs)
func get_valid_cogs(gag: ToonAttack) -> Array:
	var player := Util.get_player()
	if gag is GagLure:
		return manager.cogs.filter(func(c: Cog): return not c.lured)
	if gag is GagTrap:
		return manager.cogs.filter(func(c: Cog): return not c.trap and not (c.lured and player.trap_needs_lure))
	return manager.cogs.duplicate()

func use_gag(base_gag: ToonAttack) -> void:
	var player := Util.get_player()
	var gag: ToonAttack = base_gag.duplicate(true)
	gag.user = user
	gag.manager = manager
	gag.battle_node = battle_node
	
	# Pick a random Cog to hit
	var cogs := manager.cogs
	var target: Cog = RNG.channel(RNG.ChannelTrueRandom).pick_random(get_valid_cogs(base_gag))
	var idx := cogs.find(target)
	match gag.target_type:
		ActionTarget.ENEMY_SPLASH:
			gag.reassess_splash_targets(idx, manager)
		ActionTarget.ENEMIES:
			gag.targets = cogs.duplicate()
			gag.main_target = cogs[idx]
		_:
			gag.targets = [cogs[idx]]
	if not gag.main_target:
		gag.main_target = gag.targets[0]
	
	manager.show_action_name("%s!" % gag.action_name, "Partner Attack")
	
	# Partner borrows the player's battle stats while the gag runs
	manager.battle_stats[user] = manager.battle_stats[player]
	var prev_action := manager.current_action
	manager.current_action = gag
	await gag.action()
	manager.current_action = prev_action
	manager.battle_stats.erase(user)

func buff_player() -> void:
	var player := Util.get_player()
	manager.s_focus_char.emit(user)
	manager.show_action_name("Partner Pass!", "Your partner passes their turn to help you!")
	user.face_position(player.global_position)
	user.set_animation('happy-dance')
	user.speak("You got this!")
	await manager.barrier(user.animator.animation_finished, 3.0)
	
	var boost: StatBoost = STAT_BOOST_REFERENCE.duplicate(true)
	boost.quality = StatusEffect.EffectQuality.POSITIVE
	boost.stat = RNG.channel(RNG.ChannelTrueRandom).pick_random(BUFF_STATS)
	boost.boost = 0.2
	boost.rounds = 2
	boost.target = player
	manager.add_status_effect(boost)
	
	manager.s_focus_char.emit(player)
	player.toon.speak("Thanks, pal!")
	await manager.sleep(1.5)
