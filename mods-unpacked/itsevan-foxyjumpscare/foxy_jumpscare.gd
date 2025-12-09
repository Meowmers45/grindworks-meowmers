@tool
extends Control

const STATIC_TIME := 3.0
const STATIC_FADE_TIME := 2.0
const ROLL_CHANCE := 10000

@export_tool_button("Do Jumpscare") var jumpscare_button = do_jumpscare

@onready var foxy_ref := %FoxyReference
@onready var foxy_tex := %FoxyTex
@onready var static_ref := %StaticReference
@onready var static_tex := %StaticTex
@onready var sfx_scream := %ScreamSFX
@onready var sfx_static := %StaticSFX
@onready var timer := %ScareTimer

var scare_tween: Tween


func _process(_delta: float) -> void:
	foxy_tex.set_texture(get_texture(foxy_ref))
	static_tex.set_texture(get_texture(static_ref))

func get_texture(sprite: AnimatedSprite2D) -> Texture2D:
	return sprite.sprite_frames.get_frame_texture(sprite.animation, sprite.frame)

func do_jumpscare() -> void:
	if scare_tween and scare_tween.is_running():
		scare_tween.kill()
	
	scare_tween = create_tween()
	
	# Play the anim and sound
	scare_tween.tween_callback(sfx_scream.play)
	scare_tween.tween_callback(foxy_tex.show)
	scare_tween.tween_callback(foxy_ref.play)
	scare_tween.tween_interval(0.5)
	
	# Hide foxy and show static
	scare_tween.tween_callback(sfx_scream.stop)
	scare_tween.tween_callback(foxy_tex.hide)
	scare_tween.tween_callback(static_tex.show)
	scare_tween.tween_callback(sfx_static.play)
	scare_tween.tween_interval(STATIC_TIME)
	
	# Fade out static
	scare_tween.tween_property(sfx_static, 'volume_db', -40.0, STATIC_FADE_TIME)
	scare_tween.parallel().tween_property(static_tex, 'modulate:a', 0.0, STATIC_FADE_TIME)
	
	scare_tween.finished.connect(
		func():
			scare_tween.kill()
			static_tex.hide()
			static_tex.modulate.a = 1.0
			sfx_static.stop()
			sfx_static.volume_db = 0.0
			foxy_ref.frame = 0
	)

func on_timeout() -> void:
	var foxy_roll := RandomService.randi_channel('true_random') % ROLL_CHANCE
	if scare_tween and scare_tween.is_running():
		return
	
	if foxy_roll == 0:
		do_jumpscare()
