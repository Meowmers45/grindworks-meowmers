@tool
extends Control

const STATIC_TIME := 3.0
const STATIC_FADE_TIME := 2.0
const ROLL_CHANCE := 10000

@onready var meowmers_ref := %MeowmersReference
@onready var meowmers_tex := %MeowmersTex
@onready var timer := %DanceTimer

var meowmers_dancing_tween: Tween

func _process(_delta: float) -> void:
	meowmers_tex.set_texture(get_texture(meowmers_ref))
	if BattleManager:
		BattleService.s_battle_ending.connect(on_battle_ending)
	else:
		return

func get_texture(sprite: AnimatedSprite2D) -> Texture2D:
	return sprite.sprite_frames.get_frame_texture(sprite.animation, sprite.frame)

func do_schmooves() -> void:
	if meowmers_dancing_tween and meowmers_dancing_tween.is_running():
		meowmers_dancing_tween.kill()
	
	meowmers_dancing_tween = create_tween()
	
	# Play the anim and sound
	meowmers_dancing_tween.tween_callback(meowmers_tex.show)
	meowmers_dancing_tween.tween_callback(meowmers_ref.play)
	meowmers_dancing_tween.tween_interval(0.5)

	meowmers_dancing_tween.finished.connect(
		func():
			meowmers_dancing_tween.kill()
			meowmers_ref.frame = 0
	)

func on_battle_ending() -> void:
	if meowmers_dancing_tween and meowmers_dancing_tween.is_running():
		return
	do_schmooves()
