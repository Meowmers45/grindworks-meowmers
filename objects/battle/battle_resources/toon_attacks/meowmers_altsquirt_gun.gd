extends SquirtGun

var sfx_hit: AudioStream = preload("res://audio/sfx/battle/gags/squirt/AA_squirt_neonwatergun.ogg")

const HIT_RANGE := Vector2i(1, 7)
const PITCH_INCREASE := 0.1
const PITCH_INCREASE_FUCK := 0.05

var sfx_fuck = preload("res://audio/sfx/battle/gags/drop/AA_drop_brick_funny.ogg")

var hit_count: Dictionary[Cog, int] = {}

var gun = load('res://models/props/gags/water_gun/water_gun.tscn').instantiate()

func action() -> void:
	var hits := RandomService.randi_range_channel('true_random', HIT_RANGE.x, HIT_RANGE.y)
	var hit_order: Array[Cog] = []
	for i in hits:
		hit_order.append(RandomService.array_pick_random('true_random', targets))
	
	for cog in targets:
		hit_count[cog] = 1

	# Start
	manager.s_focus_char.emit(user)
	var target = targets[0]
	user.set_animation('water-gun')
	user.face_position(target.global_position)
	
	# Place gun in hand
	user.toon.right_hand_bone.add_child(gun)
	gun.position = Vector3(-0.214,0.125,-0.025)
	gun.rotation_degrees = Vector3(180,90,270)
	gun.scale*=.85
	
	await manager.sleep(1.8)
	
	battle_node.focus_cogs()
	
	for i in hit_order.size():
		do_hit(hit_order.pop_back())
		if i == hits - 1:
			await Task.delay(7.5)
		else:
			await Task.delay(1.0)
	
	# End
	
	gun.queue_free()
	user.face_position(manager.battle_node.global_position)
	
func do_hit(cog: Cog) -> void:
	for i in HIT_RANGE:
		# Make the squirt happen
		soak_opponent(cog.head_node, gun.get_node('Barrel'), .05)
		
		# Cleanup
		await manager.sleep(0.2)
		
		manager.action_hit_rolls.erase(self)
		
		var was_lured: bool = cog.lured
		AudioManager.play_sound(sfx_hit).pitch_scale = 1 + (i*0.1)
		manager.affect_target(cog, damage)
		var splat = load("res://objects/battle/effects/splat/splat.tscn").instantiate()
		if Util.get_player().stats.has_item('Witch Hat'):
			splat.modulate = POISON_COLOR
		elif Util.get_player().stats.abbie:
			splat.modulate = BOILING_COLOR
		else:
			splat.modulate = Globals.SQUIRT_COLOR
		splat.set_text("SPLASH!")
		cog.head_node.add_child(splat)
		if not get_immunity(cog):
			if cog.lured:
				manager.knockback_cog(cog)
				do_dizzy_stars(cog)
			else:
				cog.set_animation('neutral')
				cog.set_animation('squirt-small')
				do_dizzy_stars(cog)
			apply_debuff(cog)
			s_hit.emit()
			await Task.delay(0.5 * pow(0.9, i))
			if was_lured:
				await Task.delay(0.4)
		else:
			manager.battle_text(cog, "IMMUNE")
			#await manager.barrier(cog.animator.animation_finished, 5.0)
	await Task.delay(2.5)
	manager.battle_text(cog, "Drenched!", BattleText.colors.orange[0], BattleText.colors.orange[1])
	await manager.barrier(cog.animator.animation_finished, 5.0)
	await manager.check_pulses(targets)
