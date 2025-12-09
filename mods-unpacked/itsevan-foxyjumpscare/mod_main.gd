extends Node


const FOXY_DIR := "itsevan-foxyjumpscare"
const FOXY_LOG := "itsevan-foxyjumpscare:Main"

var mod_dir_path := ""
var extensions_dir_path := ""
var translations_dir_path := ""

func _init() -> void:
	mod_dir_path = ModLoaderMod.get_unpacked_dir().path_join(FOXY_DIR)

func _ready() -> void:
	ModLoaderLog.info("Ready!", FOXY_LOG)
	var foxy_jumpscare: Control = load(ModLoaderMod.get_unpacked_dir().path_join(FOXY_DIR).path_join("foxy_jumpscare.tscn")).instantiate()
	get_tree().get_root().add_child.call_deferred(foxy_jumpscare)
