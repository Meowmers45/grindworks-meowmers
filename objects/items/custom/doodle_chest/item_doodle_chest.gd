extends ItemScriptActive

const SFX := preload("res://audio/sfx/doodle/speak_v1.ogg")
const SPLASH := preload("res://objects/battle/effects/rainbow_paint_splash/rainbow_paint_splash_effect.tscn")
const DISTANCE_LIMIT := 3.0
const CHEST = "res://objects/interactables/treasure_chest/treasure_chest.tscn"
const DOODLE := preload("res://objects/items/resources/passive/doodle.tres")
const WORLD_ITEM = preload("res://objects/items/world_item/world_item.tscn")
const ACC_POOL = preload("res://objects/items/pools/accessories.tres")
const MEOWMERS_EXTRALIFE_PATH := preload("res://objects/items/resources/active/meowmers_extralife.tres")

func use() -> void:
	# Makes this work in debug rooms
	var zone
	if is_instance_valid(Util.floor_manager):
		zone = Util.floor_manager.get_current_room()
	else:
		zone = SceneLoader
	
	# OoOoooOooO look away from position calculations oOoOoOoo
	var rel_basis = Util.get_player().toon.global_basis
	var rel_pos = Util.get_player().global_position + (rel_basis * Vector3(0, 0, 3))
	var raycast_check = Util.get_player().get_world_3d().direct_space_state.intersect_ray(PhysicsRayQueryParameters3D.create(Util.get_player().global_position, rel_pos, 0b0001))
	if raycast_check:
		rel_pos = raycast_check.position - (rel_basis * Vector3(0,0,.5))
	
	var item_count = RandomService.randi_range_channel('pocket_prank_summon_doodles', 1, 4)
	var extralife_count = 1
	
	for i in item_count:
		var item = WORLD_ITEM.instantiate()
		item.override_replacement_rolls = true
		item.item = DOODLE
		zone.add_child(item)
		item.global_position = rel_pos + (rel_basis * Vector3(-1 * i, 0.25, 0))
		var dust_cloud = Globals.DUST_CLOUD.instantiate()
		zone.add_child(dust_cloud)
		dust_cloud.scale *= item.scale
		dust_cloud.global_position = item.global_position
		await Task.delay(0.1)
		AudioManager.play_sound(SFX)
	
	if Util.get_player().stats.lostmode == true:
		for i in extralife_count:
			var item = WORLD_ITEM.instantiate()
			item.override_replacement_rolls = true
			item.item = MEOWMERS_EXTRALIFE_PATH
			zone.add_child(item)
			item.global_position = Vector3(0, 0, 2) + rel_pos + (rel_basis * Vector3(-1 * i, 0.25, 0))
			var dust_cloud = Globals.DUST_CLOUD.instantiate()
			zone.add_child(dust_cloud)
			dust_cloud.scale *= item.scale
			dust_cloud.global_position = item.global_position
			await Task.delay(0.1)
			
		
	attempt_disconnect()
	Util.get_player().stats.current_active_item = null
