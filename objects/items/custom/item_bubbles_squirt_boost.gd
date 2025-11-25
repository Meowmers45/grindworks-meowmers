extends ItemScript

const BOILING_EFFECT := preload("res://objects/battle/battle_resources/status_effects/resources/status_effect_boiling.tres")
const EFFECT_RATIO := 0.4

func setup() -> void:
	BattleService.s_round_started.connect(on_round_started)

func on_round_started(actions : Array[BattleAction]) -> void:
	for action in actions:
		if action is GagSquirt:
			action.s_hit.connect(squirt_hit.bind(action))

func squirt_hit(action : GagSquirt) -> void:
	var gag_damage := BattleService.ongoing_battle.get_damage(action.damage, action, action.targets[0])
	var cog: Cog = action.targets[0]
	if cog.stats.hp > 0:
		apply_boiling_effect(cog, get_damage(gag_damage))

func apply_boiling_effect(cog : Cog, damage : int) -> void:
	var boiling_effect := BOILING_EFFECT.duplicate(true)
	boiling_effect.target = cog
	boiling_effect.amount = damage
	boiling_effect.rounds = -1
	boiling_effect.icon = load("res://ui_assets/battle/statuses/fire_sale_dot.png")
	BattleService.ongoing_battle.add_status_effect(boiling_effect)

func get_damage(gag_damage : int) -> int:
	return ceili(gag_damage * EFFECT_RATIO)

func on_collect(_item : Item, _model : Node3D) -> void:
	setup()

func on_load(_item : Item) -> void:
	setup()
