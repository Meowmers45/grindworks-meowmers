extends Resource
class_name PartnerItemList

## Settings for one Toon Partner (by position in the line)

## Preset look for this partner. Leave empty for random (1st partner falls back to the character's Partner Dna)
@export var dna: ToonDNA
## Preset name for this partner. Leave empty for random (1st partner falls back to the character's Partner Name)
@export var partner_name := ""
## Passive items this partner holds
@export var items: Array[Item] = []
## Gag turns per round. 0 = random 1-3, rolled once when the partner joins and kept for the run
@export_range(0, 10) var turns := 0
