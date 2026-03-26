extends SquirtGun

var sfx_hit: AudioStream = preload("res://audio/sfx/battle/gags/squirt/AA_squirt_neonwatergun.ogg")

func action():
	# Start
	manager.s_focus_char.emit(user)
	var target = targets[0]
	user.set_animation('water-gun')
	user.face_position(target.global_position)
	
	# Place gun in hand
	var gun = load('res://models/props/gags/water_gun/water_gun.tscn').instantiate()
	user.toon.right_hand_bone.add_child(gun)
	gun.position = Vector3(-0.214,0.125,-0.025)
	gun.rotation_degrees = Vector3(180,90,270)
	gun.scale*=.85
	
	await manager.sleep(1.8)
	var total_hits := RandomService.randi_range_channel('true_random', 1, 25)
	
	manager.s_focus_char.emit(target)
	
	if Util.get_player().stats.abbie:
		total_hits == RandomService.randi_range_channel('true_random', 1, 15)
	
	for i in total_hits:
		# Make the squirt happen
		soak_opponent(target.head_node, gun.get_node('Barrel'), .05)
		
		# Cleanup
		await manager.sleep(0.2)
		
		manager.action_hit_rolls.erase(self)
		
		if manager.roll_for_accuracy(self) or target.lured:
			var was_lured: bool = target.lured
			AudioManager.play_sound(sfx_hit).pitch_scale = 1 + (i*0.1)
			manager.affect_target(target, damage)
			var splat = load("res://objects/battle/effects/splat/splat.tscn").instantiate()
			if Util.get_player().stats.has_item('Witch Hat'):
				splat.modulate = POISON_COLOR
			elif Util.get_player().stats.abbie:
				splat.modulate = BOILING_COLOR
			else:
				splat.modulate = Globals.SQUIRT_COLOR
			splat.set_text("SPLASH!")
			target.head_node.add_child(splat)
			if not get_immunity(target):
				if target.lured:
					manager.knockback_cog(target)
					do_dizzy_stars(target)
				else:
					target.set_animation('neutral')
					target.set_animation('squirt-small')
					do_dizzy_stars(target)
				apply_debuff(target)
				s_hit.emit()
				await Task.delay(0.5 * pow(0.9, i))
				if was_lured:
					await Task.delay(0.4)
			else:
				manager.battle_text(target, "IMMUNE")
			#await manager.barrier(target.animator.animation_finished, 5.0)
		else:
			AudioManager.play_sound(load("res://audio/sfx/battle/gags/squirt/AA_squirt_neonwatergun_miss.ogg"))
			target.set_animation('sidestep-left')
			manager.battle_text(target, "MISSED")
			await target.animator.animation_finished
	
	await Task.delay(0.4)
	manager.battle_text(target, "Drenched!", BattleText.colors.orange[0], BattleText.colors.orange[1])
	await manager.barrier(target.animator.animation_finished, 5.0)
	await manager.check_pulses(targets)
	# End
	
	gun.queue_free()
	user.face_position(manager.battle_node.global_position)
