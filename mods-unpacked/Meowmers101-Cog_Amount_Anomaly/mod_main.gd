extends Node

# ! Comments prefixed with "!" mean they are extra info. Comments without them
# ! should be kept because they give your mod structure and make it easier to
# ! read by other modders
# ! Comments with "?" should be replaced by you with the appropriate information

# ! This template file is statically typed. You don't have to do that, but it can help avoid bugs
# ! You can learn more about static typing in the docs
# ! https://docs.godotengine.org/en/3.5/tutorials/scripting/gdscript/static_typing.html

# ? Brief overview of what your mod does...

const MOD_DIR := "Meowmers101-Cog_Amount_Anomaly" # Name of the directory that this file is in
const LOG_NAME := "Meowmers101-Cog_Amount_Anomaly:Main" # Full ID of the mod (AuthorName-ModName)

var mod_dir_path := ""
var extensions_dir_path := ""
var translations_dir_path := ""


# ! your _ready func.
func _init() -> void:
	ModLoaderLog.info("Init", LOG_NAME)
	mod_dir_path = ModLoaderMod.get_unpacked_dir().path_join(MOD_DIR)


func _ready() -> void:
	ModLoaderLog.info("Ready", LOG_NAME)

	var anomaly_paths := {
		"positive": [],
		"negative": [
			"res://mods-unpacked/Meowmers101-Cog_Amount_Anomaly/extensions/scenes/game_floor/floor_modifiers/scripts/anomalies/floor_mod_overstaffed.gd",
		],
		"neutral": [],
	}
	
	for anomaly in anomaly_paths["positive"]:
		if anomaly not in FloorVariant.ANOMALIES_POSITIVE:
			FloorVariant.ANOMALIES_POSITIVE.append(anomaly)
			print("Added positive anomaly: %s" % anomaly)
			
	for anomaly in anomaly_paths["neutral"]:
		if anomaly not in FloorVariant.ANOMALIES_NEUTRAL:
			FloorVariant.ANOMALIES_NEUTRAL.append(anomaly)
			print("Added neutral anomaly: %s" % anomaly)
			
	for anomaly in anomaly_paths["negative"]:
		if anomaly not in FloorVariant.ANOMALIES_NEGATIVE:
			FloorVariant.ANOMALIES_NEGATIVE.append(anomaly)
			print("Added negative anomaly: %s" % anomaly)
