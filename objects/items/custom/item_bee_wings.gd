extends ItemScript

var multiplier: StatMultiplier

func on_collect(_item: Item, _object: Node3D) -> void:
	setup()

func on_load(_item: Item) -> void:
	setup()

func setup() -> void:
	if not Util.get_player():
		await Util.s_player_assigned
	var player := Util.get_player()
	player.stats.s_speed_changed.connect(on_speed_changed)
	create_multiplier()
	on_speed_changed(player.stats.speed)

func on_item_removed() -> void:
	get_owner_multipliers().erase(multiplier)

## Sync multipliers to current speed amount
func on_speed_changed(speed: float) -> void:
	multiplier.amount = maxf(0.0, (speed - 1.0) * 0.5)

func create_multiplier() -> void:
	multiplier = StatMultiplier.new()
	multiplier.stat = 'crit_mult'
	multiplier.amount = 0.0
	multiplier.additive = true
	get_owner_multipliers().append(multiplier)

## Stat effects also work when held by a Toon Partner
func supports_partner_owner() -> bool:
	return true
