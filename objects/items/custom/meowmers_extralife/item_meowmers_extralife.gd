extends ItemScriptActive

const SFX := preload("res://audio/sfx/doodle/speak_v1.ogg")
const SFX_LIVES := preload("res://audio/sfx/items/Holy_Mackerel.ogg")
const SFX_USE := preload("res://audio/sfx/items/laff_boost_pickup.ogg")
const SPLASH := preload("res://objects/battle/effects/rainbow_paint_splash/rainbow_paint_splash_effect.tscn")
const DISTANCE_LIMIT := 3.0
const CHEST = "res://objects/interactables/treasure_chest/treasure_chest.tscn"
const DOODLE := preload("res://objects/items/resources/passive/doodle.tres")
const EXTRA_LIFE := preload("res://objects/items/resources/passive/emergency_unite.tres")
const WORLD_ITEM = preload("res://objects/items/world_item/world_item.tscn")
const ACC_POOL = preload("res://objects/items/pools/accessories.tres")

func on_battle_end(_actions) -> void:
	for track : TrackElement in BattleService.ongoing_battle.battle_ui.gag_tracks.get_children():
		track.free = false

func use() -> void:
	var manager := BattleService.ongoing_battle
	if manager is not BattleManager:
		var player := Util.get_player()
		player.stats.extra_lives += RandomService.randi_range_channel('pocket_prank_meowmers_extra_life', 1, 3)
		AudioManager.play_sound(SFX_LIVES)
	if manager is BattleManager:
		# Makes this work in debug rooms
		var zone
		if is_instance_valid(Util.floor_manager):
			zone = Util.floor_manager.get_current_room()
		else:
			zone = SceneLoader
			
		for track : TrackElement in BattleService.ongoing_battle.battle_ui.gag_tracks.get_children():
			track.free = true
			track.refresh()
		BattleService.ongoing_battle.s_battle_ended.connect(on_battle_end)
		AudioManager.play_sound(SFX_USE)
