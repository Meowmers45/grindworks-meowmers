extends ItemScript

const PARTNER_SCENE := "res://objects/toon_partner/toon_partner.tscn"

var partner: ToonPartner


func on_collect(item: Item, _object: Node3D) -> void:
	var dna: ToonDNA
	var character: PlayerCharacter = Util.get_player().stats.character
	# Only the first partner uses the character's partner settings; extras are always random
	if has_other_partner():
		character = null
	if character and character.partner_dna:
		dna = character.partner_dna.duplicate(true)
	else:
		dna = ToonDNA.new()
		dna.randomize_dna()
	item.arbitrary_data['dna'] = dna
	var partner_name: String = character.partner_name if character else ""
	if partner_name.strip_edges().is_empty():
		partner_name = Globals.get_random_toon_name().strip_edges()
	item.arbitrary_data['name'] = partner_name
	item.item_name = partner_name
	var accessory_paths: Array[String] = []
	if character:
		for accessory: ItemAccessory in character.partner_accessories:
			if accessory and not accessory.resource_path.is_empty():
				accessory_paths.append(accessory.resource_path)
	item.arbitrary_data['accessories'] = accessory_paths
	var shoes_path := ""
	if character and character.partner_shoes:
		shoes_path = character.partner_shoes.resource_path
	item.arbitrary_data['shoes'] = shoes_path
	spawn_partner(dna, partner_name, accessory_paths, shoes_path)

func on_load(item: Item) -> void:
	var dna = item.arbitrary_data.get('dna')
	if not dna is ToonDNA:
		dna = ToonDNA.new()
		dna.randomize_dna()
		item.arbitrary_data['dna'] = dna
	var partner_name: String = item.arbitrary_data.get('name', "")
	if partner_name.is_empty():
		partner_name = Globals.get_random_toon_name().strip_edges()
		item.arbitrary_data['name'] = partner_name
	var accessory_paths: Array[String] = []
	accessory_paths.assign(item.arbitrary_data.get('accessories', []))
	var shoes_path: String = item.arbitrary_data.get('shoes', "")
	spawn_partner(dna, partner_name, accessory_paths, shoes_path)

func spawn_partner(dna: ToonDNA, partner_name: String, accessory_paths: Array[String], shoes_path := "") -> void:
	partner = load(PARTNER_SCENE).instantiate()
	partner.dna = dna
	partner.partner_name = partner_name
	for path in accessory_paths:
		var accessory := load(path) as ItemAccessory
		if accessory:
			partner.accessories.append(accessory)
	if not shoes_path.is_empty():
		partner.shoes = load(shoes_path) as ItemShoe
	SceneLoader.add_persistent_node(partner)
	Util.get_player().partners.append(partner)

## Whether another live Toon Partner already exists (ignores ones being cleared by a stats reset)
func has_other_partner() -> bool:
	for node in get_parent().get_children():
		if node != self and node.get_script() == get_script() and not node.is_queued_for_deletion() and is_instance_valid(node.partner):
			return true
	return false

func on_item_removed() -> void:
	remove_partner()

func _notification(what: int) -> void:
	if what == NOTIFICATION_PREDELETE:
		remove_partner()

func remove_partner() -> void:
	if not is_instance_valid(partner):
		return
	var player := Util.get_player()
	if is_instance_valid(player):
		player.partners.erase(partner)
	partner.queue_free()
	partner = null
