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
	spawn_partner(dna)

func on_load(item: Item) -> void:
	var dna = item.arbitrary_data.get('dna')
	if not dna is ToonDNA:
		dna = ToonDNA.new()
		dna.randomize_dna()
		item.arbitrary_data['dna'] = dna
	spawn_partner(dna)

func spawn_partner(dna: ToonDNA) -> void:
	partner = load(PARTNER_SCENE).instantiate()
	partner.dna = dna
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
