extends ItemScriptActive

const IFRAME_SUPER_TIME := 3.0
const supertransform = "res://audio/sfx/items/chaos_emeralds.ogg"

var r = 0
var g = 0
var b = 0

@export var tween_duration: float = 1.0
@export var colors: Array[Color] = [
	Color.RED,
	Color.ORANGE,
	Color.YELLOW,
	Color.GREEN,
	Color.BLUE,
	Color.INDIGO,
	Color.PURPLE
]

func use() -> void:
	AudioManager.play_sound(load(supertransform))
	player.do_invincibility_frames(75.0)
	do_iframe_tween_super(75.0)

var current_tween: Tween = null

func start_rainbow_tween():
	if current_tween:
		current_tween.kill() # Stop any existing tween on this node
		
	current_tween = create_tween()
	current_tween.set_loops() # Loop indefinitely

	for i in range(colors.size()):
		var next_color_index = (i + 1) % colors.size()
		var target_color = colors[next_color_index]
		current_tween.tween_property(self, "modulate", target_color, tween_duration)\
			.set_trans(Tween.TRANS_LINEAR)\
			.set_ease(Tween.EASE_IN_OUT)

	current_tween.play()

var player: Player:
	get: return Util.get_player()

var iframe_tween_super: Tween
@export var speed: float = 1.0
var color_timer: float = 0.0

func do_iframe_tween_super(time := IFRAME_SUPER_TIME) -> Tween:
	var toon = player.toon
	if player.iframe_tween:
		player.iframe_tween.kill()
	if iframe_tween_super:
		iframe_tween_super.kill()
	iframe_tween_super = create_tween()

	var delay := 0.9
	var delay_dec := 0.15 * (IFRAME_SUPER_TIME / time)
	var delay_minimum := 0.1
	var blink_time := 0.0
	var fade_strength := 0.4
	var delta: float


	color_timer += delta * speed

	# Use sine waves to smoothly oscillate RGB values between 0 and 1
	
	var SUPER_COLOR := Color(r, g, b, 1.0)

	# Apply the color to the sprite

	toon.color_overlay_mat.set_color(SUPER_COLOR)
	while delay > delay_minimum:
		r = sin(color_timer) * 0.5 + 0.5
		g = sin(color_timer + 2.0) * 0.5 + 0.5
		b = sin(color_timer + 4.0) * 0.5 + 0.5
		iframe_tween_super.tween_callback(toon.color_overlay_mat.fade_in.bind(toon, SUPER_COLOR, delay / 2.0, fade_strength))
		iframe_tween_super.tween_interval(delay / 2.0)
		iframe_tween_super.tween_callback(toon.color_overlay_mat.fade_out.bind(toon, SUPER_COLOR, delay / 2.0))
		iframe_tween_super.tween_interval(delay / 2.0)
		blink_time += delay
		delay -= delay_dec

	delay = delay_minimum
	while blink_time < time:
		r = sin(color_timer) * 0.5 + 0.5
		g = sin(color_timer + 2.0) * 0.5 + 0.5
		b = sin(color_timer + 4.0) * 0.5 + 0.5
		iframe_tween_super.tween_callback(toon.color_overlay_mat.fade_in.bind(toon, SUPER_COLOR, delay / 2.0, fade_strength))
		iframe_tween_super.tween_interval(delay / 2.0)
		iframe_tween_super.tween_callback(toon.color_overlay_mat.fade_out.bind(toon, SUPER_COLOR, delay / 2.0))
		iframe_tween_super.tween_interval(delay / 2.0)
		blink_time += delay

	iframe_tween_super.tween_callback(toon.legs.show)
	return iframe_tween_super
