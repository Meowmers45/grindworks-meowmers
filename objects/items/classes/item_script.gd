extends Node
class_name ItemScript

## Script class that will be attached to the player as nodes


## Called when an item is first collected by the player
func on_collect(_item: Item, _object: Node3D) -> void:
	pass

## Called when an item is re-instanced on game-load
func on_load(_item: Item) -> void:
	pass

## Set when this script runs for a Toon Partner instead of the player (only its stat effects apply)
var partner_owner: Node = null

## Override to return true in scripts whose stat effects can be redirected to a Toon Partner
func supports_partner_owner() -> bool:
	return false

func is_partner_owned() -> bool:
	return partner_owner != null

## Stat multipliers of whoever owns this item (player or Toon Partner)
func get_owner_multipliers() -> Array[StatMultiplier]:
	if partner_owner:
		return partner_owner.stat_multipliers
	return Util.get_player().stats.multipliers

## Adds to a stat on whoever owns this item, including the ongoing battle's copy for the player
func add_owner_stat(stat: String, amount: float) -> void:
	if partner_owner:
		partner_owner.add_stat_offset(stat, amount)
		return
	var player := Util.get_player()
	player.stats[stat] += amount
	var battle := BattleService.ongoing_battle
	if is_instance_valid(battle) and player in battle.battle_stats:
		battle.battle_stats[player][stat] += amount

## Called if the item is removed from the Player
func on_item_removed() -> void:
	pass

## Adds an item script to the player
static func add_item_script(player: Player, item_script: Script) -> Node:
	var new_node := Node.new()
	new_node.set_script(item_script)
	player.get_node('Items').add_child(new_node)
	return new_node
