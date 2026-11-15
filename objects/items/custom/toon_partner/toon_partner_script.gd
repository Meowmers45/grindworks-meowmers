extends ItemScript

const PARTNER_SCENE := "res://objects/toon_partner/toon_partner.tscn"

var partner: ToonPartner


func on_collect(item: Item, _object: Node3D) -> void:
	var dna: ToonDNA
	var character: PlayerCharacter = Util.get_player().stats.character
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
	spawn_partner(dna, partner_name)

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
	spawn_partner(dna, partner_name)

func spawn_partner(dna: ToonDNA, partner_name: String) -> void:
	partner = load(PARTNER_SCENE).instantiate()
	partner.dna = dna
	partner.partner_name = partner_name
	SceneLoader.add_persistent_node(partner)
	Util.get_player().partners.append(partner)

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
