extends Node

# ! Comments prefixed with "!" mean they are extra info. Comments without them
# ! should be kept because they give your mod structure and make it easier to
# ! read by other modders
# ! Comments with "?" should be replaced by you with the appropriate information

# ! This template file is statically typed. You don't have to do that, but it can help avoid bugs
# ! You can learn more about static typing in the docs
# ! https://docs.godotengine.org/en/3.5/tutorials/scripting/gdscript/static_typing.html

# ? Brief overview of what your mod does...

const MOD_DIR := "Meowmers101-SingingLiquidator" # Name of the directory that this file is in
const LOG_NAME := "Meowmers101-SingingLiquidator:Main" # Full ID of the mod (AuthorName-ModName)

var mod_dir_path := ""
var extensions_dir_path := ""
var translations_dir_path := ""

func _init() -> void:
	mod_dir_path = ModLoaderMod.get_unpacked_dir().path_join(MOD_DIR)
	# Add extensions
	install_script_extensions()
	install_script_hook_files()

	# Add translations
	add_translations()


func install_script_extensions() -> void:
	extensions_dir_path = mod_dir_path.path_join("extensions")


func install_script_hook_files() -> void:
	extensions_dir_path = mod_dir_path.path_join("extensions")


func add_translations() -> void:
	translations_dir_path = mod_dir_path.path_join("translations")


func _ready() -> void:
	var singing_script = load(mod_dir_path.path_join("singing_liquidator.gd"))
	if singing_script:
		var singing = singing_script.new()
		add_child(singing)
		
	ModLoaderLog.info("Ready", LOG_NAME)
