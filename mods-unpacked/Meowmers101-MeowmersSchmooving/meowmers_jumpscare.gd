@tool
extends Control

const STATIC_TIME := 3.0
const STATIC_FADE_TIME := 2.0
const ROLL_CHANCE := 10000

@onready var meowmers_ref := %MeowmersReference
@onready var meowmers_tex := %MeowmersTex
@onready var timer := %ScareTimer

var scare_tween: Tween

func _ready() -> void:
	BattleService.s_battle_ending.connect(on_battle_ending)

func _process(_delta: float) -> void:
	meowmers_tex.set_texture(get_texture(meowmers_ref))

func get_texture(sprite: AnimatedSprite2D) -> Texture2D:
	return sprite.sprite_frames.get_frame_texture(sprite.animation, sprite.frame)

func do_schmooves() -> void:
	if scare_tween and scare_tween.is_running():
		scare_tween.kill()
	
	scare_tween = create_tween()
	
	# Play the anim and sound
	scare_tween.tween_callback(meowmers_tex.show)
	scare_tween.tween_callback(meowmers_ref.play)
	scare_tween.tween_interval(0.5)
	
	# Hide meowmers and show static
	scare_tween.tween_callback(meowmers_tex.hide)

	scare_tween.finished.connect(
		func():
			scare_tween.kill()
			meowmers_ref.frame = 0
	)

func on_battle_ending() -> void:
	if scare_tween and scare_tween.is_running():
		return
	do_schmooves()
