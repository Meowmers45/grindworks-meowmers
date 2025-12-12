@tool
extends Control

const STATIC_TIME := 3.0
const STATIC_FADE_TIME := 2.0
const ROLL_CHANCE := 10000

var meowmers_dancing_tween: Tween

@export_tool_button("Get to Schmooving") var dance_button = do_schmooves

@onready var meowmers_ref := %MeowmersReference
@onready var meowmers_tex := %MeowmersTex
@onready var meowmers_mus := %MeowmersMusic
@onready var fademusic1 := AudioManager.fade_music(0.0, 0.0, false)
@onready var fademusic2 := AudioManager.fade_music(1.0, STATIC_FADE_TIME, false)

func _ready() -> void:
	BattleService.s_battle_ending.connect(load_dance)

func _process(_delta: float) -> void:
	meowmers_tex.set_texture(get_texture(meowmers_ref))

func music_fadein() -> void:
	AudioManager.set_music_volume(0.0)
	AudioManager.fade_music(1.0, STATIC_FADE_TIME, false)
	
func music_fadeout() -> void:
	AudioManager.stop_music()

func get_texture(sprite: AnimatedSprite2D) -> Texture2D:
	return sprite.sprite_frames.get_frame_texture(sprite.animation, sprite.frame)

func do_schmooves() -> void:
	if meowmers_dancing_tween and meowmers_dancing_tween.is_running():
		meowmers_dancing_tween.kill()
	
	meowmers_dancing_tween = create_tween()
	
	# Play the anim and sound
	meowmers_dancing_tween.tween_callback(meowmers_tex.show)
	meowmers_dancing_tween.tween_callback(meowmers_ref.play)
	meowmers_dancing_tween.tween_callback(music_fadeout)
	meowmers_dancing_tween.tween_callback(meowmers_mus.play)
	meowmers_dancing_tween.tween_callback(meowmers_tex.show)
	meowmers_dancing_tween.tween_interval(8.0)
	# Fade Meowmers and the song out
	meowmers_dancing_tween.tween_property(meowmers_mus, 'volume_db', -INF, STATIC_FADE_TIME)
	meowmers_dancing_tween.parallel().tween_property(meowmers_tex, 'modulate:a', 0.0, STATIC_FADE_TIME)
	meowmers_dancing_tween.tween_callback(music_fadein)

	meowmers_dancing_tween.finished.connect(
		func():
			meowmers_dancing_tween.kill()
			meowmers_tex.hide()
			meowmers_tex.modulate.a = 1.0
			meowmers_mus.stop()
			meowmers_mus.volume_db = 0.0
			meowmers_ref.frame = 0
	)

func load_dance() -> void:
	if meowmers_dancing_tween and meowmers_dancing_tween.is_running():
		return
	do_schmooves()
