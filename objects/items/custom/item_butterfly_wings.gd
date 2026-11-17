extends ItemScript

const EVASIVENESS_BOOST := 0.02

func on_collect(_item: Item, _object: Node3D) -> void:
	setup()

func on_load(_item: Item) -> void:
	setup()

func setup() -> void:
	BattleService.s_cog_dealt_damage.connect(_on_damage_dealt)

func _on_damage_dealt(action: BattleAction, target: Node3D, amount: int) -> void:
	if action is CogAttack and target == Util.get_player() and amount > 0:
		if not BattleService.cog_gives_credit(action.user): return
		add_owner_stat('evasiveness', EVASIVENESS_BOOST)
		if not is_partner_owned():
			Util.get_player().boost_queue.queue_text("Butterfly Boost!", Color("e4a9dd"))

## Stat effects also work when held by a Toon Partner
func supports_partner_owner() -> bool:
	return true
