extends Node

# ! Comments prefixed with "!" mean they are extra info. Comments without them
# ! should be kept because they give your mod structure and make it easier to
# ! read by other modders
# ! Comments with "?" should be replaced by you with the appropriate information

# ! This template file is statically typed. You don't have to do that, but it can help avoid bugs
# ! You can learn more about static typing in the docs
# ! https://docs.godotengine.org/en/3.5/tutorials/scripting/gdscript/static_typing.html

# ? Brief overview of what your mod does...

const MOD_DIR := "Meowmers101-MeowmersGreenFolioEnhancement" # Name of the directory that this file is in
const LOG_NAME := "Meowmers101-MeowmersGreenFolioEnhancement:Main" # Full ID of the mod (AuthorName-ModName)

var mod_dir_path := ""
var extensions_dir_path := ""
var translations_dir_path := ""

var meowmers_butterfly = false

# ! your _ready func.
func _init() -> void:
	ModLoaderLog.info("Init", LOG_NAME)
	mod_dir_path = ModLoaderMod.get_unpacked_dir().path_join(MOD_DIR)

	# Add extensions
	install_script_extensions()


func install_script_extensions() -> void:
	# ! any script extensions should go in this directory, and should follow the same directory structure as vanilla
	extensions_dir_path = mod_dir_path.path_join("extensions")
	var dir = DirAccess.open("res://mods-unpacked/")
	if dir:
		# Check if the directory or a specific file within exists
		if dir.dir_exists("/alder-GreenFolio"):
			meowmers_butterfly = true
			ModLoaderMod.install_script_hooks("res://objects/items/custom/item_meowmers_setup.gd", extensions_dir_path.path_join("objects/items/custom/item_meowmers_setup.hooks.gd"))

func is_mod_installed():
	var dir = DirAccess.open("res://mods-unpacked/")
	if dir:
		# Check if the directory or a specific file within exists
		if dir.dir_exists("/alder-GreenFolio"):
			meowmers_butterfly = true
			extensions_dir_path = mod_dir_path.path_join("extensions")
			ModLoaderMod.install_script_hooks("res://objects/items/custom/item_meowmers_setup.gd", extensions_dir_path.path_join("objects/items/custom/item_meowmers_setup.hooks.gd"))
			return true
	return false

func _ready() -> void:
	ModLoaderLog.info("Ready", LOG_NAME)
	# ! This uses Godot's native `tr` func, which translates a string. You'll
	# ! find this particular string in the example CSV here: translations/modname.csv
