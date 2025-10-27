extends Node

var hold_time := 0.0
const HOLD_DURATION := 5.0
var label: Label
var alreadydone = false

func _ready() -> void:
	create_countdown()
	add_reload_action()
	add_reload_action_fixcamera()

func _process(delta: float) -> void:
	if Input.is_action_pressed("load-singer"):
		hold_time += delta
		var remaining = HOLD_DURATION - hold_time
		label.text = "Loading Talking Liquidator in %.1f..." % max(remaining, 0)
		
		if hold_time >= HOLD_DURATION:
			reload()
			clear()
	else:
		clear()
	if Input.is_action_pressed("fix-singer"):
		fixcamera()

func clear() -> void:
	hold_time = 0.0
	if label:
		label.text = ""

func add_reload_action() -> void:
	var action_name = "load-singer"
	var key_event := InputEventKey.new()
	key_event.keycode = KEY_L
	
	# prevent dupes
	if not InputMap.has_action(action_name):
		InputMap.add_action(action_name)
	
	InputMap.action_erase_events(action_name) # remove old
	InputMap.action_add_event(action_name, key_event)

func add_reload_action_fixcamera() -> void:
	var action_name = "fix-singer"
	var key_event := InputEventKey.new()
	key_event.keycode = KEY_TAB
	
	# prevent dupes
	if not InputMap.has_action(action_name):
		InputMap.add_action(action_name)
	
	InputMap.action_erase_events(action_name) # remove old
	InputMap.action_add_event(action_name, key_event)


func create_countdown() -> void:
	var font = load("res://fonts/impress-bt.ttf") as Font
	
	label = Label.new()
	
	# styling
	label.add_theme_color_override("font_color", Color.DARK_RED)
	label.add_theme_font_override("font", font)
	label.add_theme_font_size_override("font_size", 28)
	
	# mimic timer settings
	label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.5))
	label.add_theme_constant_override("shadow_offset_x", 1)
	label.add_theme_constant_override("shadow_offset_y", 1)
	label.add_theme_constant_override("shadow_size", 6)
	
	# placement (below timer)
	label.set_anchors_and_offsets_preset(Control.PRESET_TOP_LEFT)
	label.offset_top = 64
	label.offset_left = 7
	
	label.text = ""
	add_child(label)
	label.show()


func reload() -> void:
	if SceneLoader:
		if SceneLoader.has_node("SuperSecretFeatureTest"):
			var title_screen = "res://scenes/title_screen/title_screen.tscn"
			SceneLoader.load_into_scene(title_screen)
			AudioServer.set_bus_mute(0, false)
			AudioManager.stop_music(true)
		else:
			var talking_liquidator = "res://scenes/tool_scenes/super_secret_testing_for_incredible_feature/super_secret_feature_test.tscn"
			SceneLoader.load_into_scene(talking_liquidator)
			
func fixcamera() -> void:
	if SceneLoader:
		var hehefunny = preload("res://mods-unpacked/Meowmers101-SingingLiquidator/audio/hehefunny.ogg")
		var hehefunny2 = preload("res://mods-unpacked/Meowmers101-SingingLiquidator/audio/hehefunny2.ogg")
		if AudioManager.is_audio_playing(hehefunny) == false and AudioManager.is_audio_playing(hehefunny2) == false and SceneLoader.has_node("SuperSecretFeatureTest") and alreadydone == false:
			var camera = SceneLoader.get_node("SuperSecretFeatureTest/Camera3D")
			camera.global_position = Vector3(0, 6.832, -24.614)
			var audioplayer = SceneLoader.get_node("SuperSecretFeatureTest/AudioStreamPlayer")
			audioplayer.bus = "Music"
			AudioManager.stop_music(true)
			AudioServer.set_bus_mute(0, false)
			AudioServer.add_bus(1)
			AudioManager.play_sound(hehefunny, 5.0, "SFX")
			##AudioManager.play_sound(hehefunny2, 1.0, "Music")
			alreadydone = true
		if AudioManager.is_audio_playing(hehefunny) != false and AudioManager.is_audio_playing(hehefunny2) != false and alreadydone != false:
			AudioManager.stop_music(true)
			alreadydone = false
