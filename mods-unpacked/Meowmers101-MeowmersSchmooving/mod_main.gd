extends Node


const MOD_DIR := "Meowmers101-MeowmersSchmooving"
const LOG_NAME := "Meowmers101-MeowmersSchmooving:Main"

var mod_dir_path := ""
var extensions_dir_path := ""
var translations_dir_path := ""


func _init() -> void:
	mod_dir_path = ModLoaderMod.get_unpacked_dir().path_join(MOD_DIR)

func _ready() -> void:
	ModLoaderLog.info("Ready!", LOG_NAME)
	var meowmers_jumpscare: Control = load(ModLoaderMod.get_unpacked_dir().path_join(MOD_DIR).path_join("meowmers_jumpscare.tscn")).instantiate()
	get_tree().get_root().add_child.call_deferred(meowmers_jumpscare)
