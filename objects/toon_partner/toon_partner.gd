extends Actor
class_name ToonPartner

## Trail-following (Tails style) values
const FOLLOW_SPACING := 1.6
const RECORD_STEP := 0.1
const MAX_HISTORY := 80
const SNAP_DISTANCE := 15.0
const RUN_SPEED := 8.0
const TRAIL_ANIMS: Array[String] = ['walk', 'run', 'jump']

## Passive out-of-battle healing
const HEAL_CHANCE := 0.075
const HEAL_PERCENT := 0.1
const HEAL_SFX := preload("res://audio/sfx/battle/gags/toonup/AA_heal_happydance.ogg")
const HEAL_PHRASES: Array[String] = ["Hang in there!", "I got you!", "Toon-Up!", "Feel better!"]

## Cheering
const COG_CHEERS: Array[String] = ["Nice one!", "Gotcha!", "Woo-hoo!", "Take that, Cog!", "Toontastic!"]
const GAG_CHEERS: Array[String] = ["A new Gag! Awesome!", "Ooh, shiny new Gag!", "Look at you go!", "Gag power up!"]
const CHEER_ANIM := 'happy-dance'
const CHEER_SFX := preload("res://audio/sfx/battle/gags/toonup/AA_heal_happydance.ogg")

## Idle emotes (when the player stands still)
const IDLE_EMOTE_TIME := 4.0
const IDLE_EMOTE_COOLDOWN := Vector2(6.0, 10.0)
const IDLE_EMOTES: Array[Dictionary] = [
	{'anim': 'wave', 'phrase': "Hi there!", 'emotion': Toon.Emotion.DELIGHTED},
	{'anim': 'wave', 'phrase': "Hello!", 'emotion': Toon.Emotion.DELIGHTED},
	{'anim': 'applause', 'phrase': "Ha ha ha!", 'emotion': Toon.Emotion.LAUGH},
	{'anim': 'shrug', 'phrase': "Hee hee!", 'emotion': Toon.Emotion.LAUGH},
	{'anim': 'happy-dance', 'phrase': "", 'emotion': Toon.Emotion.DELIGHTED},
	{'anim': 'victory-dance', 'phrase': "", 'emotion': Toon.Emotion.DELIGHTED},
]
const EMOTE_DURATION := 2.5

## Nameplate
const NAMEPLATE_HEIGHT := 1.0

enum PartnerState { FOLLOW, BATTLE }
var state := PartnerState.FOLLOW

@onready var toon: Toon = $Toon
@onready var head_node: Node3D = $Head
@onready var nameplate: Label3D = $Nameplate

var dna: ToonDNA
var partner_name := ""
var idle_time := 0.0
var last_player_pos := Vector3.ZERO
var animator: AnimationPlayer
var trail_points: Array[Vector3] = []
var trail_anims: Array[String] = []
var prev_hp := -1
var prev_gag_total := -1
var tracked_stats: PlayerStats
var cheering := false

var player: Player:
	get: return Util.get_player()
## Partner uses the player's stats & gag modifiers so gags behave like the player's own
var stats: PlayerStats:
	get: return player.stats if is_instance_valid(player) else null
var throw_heals: int:
	get: return 0
var trap_needs_lure: int:
	get: return player.trap_needs_lure if is_instance_valid(player) else 0
var inverted_sound_damage: int:
	get: return player.inverted_sound_damage if is_instance_valid(player) else 0


func _ready() -> void:
	if not dna:
		dna = ToonDNA.new()
		dna.randomize_dna()
	toon.construct_toon(dna)
	animator = toon.body.animator
	set_animation('neutral')
	nameplate.text = partner_name
	nameplate.visible = not partner_name.is_empty()
	BattleService.s_cog_died.connect(_on_cog_died)

func _process(_delta: float) -> void:
	if toon.head_bone:
		nameplate.global_position = Vector3(global_position.x, toon.head_bone.global_position.y + NAMEPLATE_HEIGHT, global_position.z)

func _physics_process(delta: float) -> void:
	if not is_instance_valid(player) or not player.is_inside_tree():
		return
	_check_passive_heal()
	_check_gag_unlocks()
	if state != PartnerState.FOLLOW:
		return
	visible = player.visible
	_follow_trail()
	_check_idle_emote(delta)

#region Following

func _follow_trail() -> void:
	var ppos := player.global_position
	if trail_points.is_empty() or global_position.distance_to(ppos) > SNAP_DISTANCE:
		snap_to_player()
		return
	
	# Record the player's path, along with what they were doing
	if trail_points.back().distance_to(ppos) >= RECORD_STEP:
		trail_points.append(ppos)
		trail_anims.append(player.get_animation())
		if trail_points.size() > MAX_HISTORY:
			trail_points.pop_front()
			trail_anims.pop_front()
	
	var idx := _get_trail_index()
	var target := trail_points[idx]
	var step := global_position.distance_to(target)
	if step < 0.02:
		if not cheering:
			set_animation('neutral')
		return
	
	face_position(target)
	global_position = global_position.lerp(target, 0.35)
	var anim := trail_anims[idx]
	if not anim in TRAIL_ANIMS:
		anim = 'run' if step > 0.3 else 'walk'
	if not cheering:
		set_animation(anim)

## Walks back along the recorded path until we're FOLLOW_SPACING behind the player
func _get_trail_index() -> int:
	var dist := 0.0
	var last := player.global_position
	for i in range(trail_points.size() - 1, -1, -1):
		dist += last.distance_to(trail_points[i])
		last = trail_points[i]
		if dist >= FOLLOW_SPACING:
			return i
	return 0

func snap_to_player() -> void:
	var ppos := player.global_position
	var behind := ppos - player.toon.global_basis.z.normalized() * FOLLOW_SPACING
	behind.y = ppos.y
	trail_points = [behind, ppos]
	trail_anims = ['neutral', 'neutral']
	global_position = behind
	reset_physics_interpolation()
	face_position(ppos)
	set_animation('neutral')

#endregion

#region Passive heal

func _check_passive_heal() -> void:
	var s := stats
	if not s:
		return
	var hp := s.hp
	if prev_hp >= 0 and hp < prev_hp and hp > 0 and not is_instance_valid(BattleService.ongoing_battle):
		if RNG.channel(RNG.ChannelTrueRandom).randf() < HEAL_CHANCE:
			heal_player.call_deferred()
	prev_hp = hp

func heal_player() -> void:
	if not is_instance_valid(player) or player.stats.hp <= 0:
		return
	var amount := ceili(player.stats.max_hp * HEAL_PERCENT)
	toon.speak(HEAL_PHRASES.pick_random())
	AudioManager.play_sound(HEAL_SFX)
	player.quick_heal(amount)
	prev_hp = player.stats.hp

#endregion

#region Cheering

func _on_cog_died(_cog: Cog) -> void:
	cheer(COG_CHEERS.pick_random(), false)

func _check_gag_unlocks() -> void:
	var s := stats
	if not s:
		return
	var total := 0
	for track in s.gags_unlocked.keys():
		total += s.gags_unlocked[track]
	# Re-baseline when the stats object is swapped (new run / character setup)
	if s != tracked_stats:
		tracked_stats = s
		prev_gag_total = total
		return
	if total > prev_gag_total:
		cheer(GAG_CHEERS.pick_random(), true)
	prev_gag_total = total

func cheer(phrase: String, with_sfx: bool) -> void:
	if not is_inside_tree() or not visible:
		return
	toon.speak(phrase)
	if with_sfx:
		AudioManager.play_sound(CHEER_SFX)
	# Don't interrupt the partner mid-gag in battle
	if state == PartnerState.BATTLE and get_animation() != 'neutral':
		return
	play_emote(CHEER_ANIM, 2.0)

## Plays a one-off animation that the follow logic won't override
func play_emote(anim: String, duration: float, emotion := Toon.Emotion.NEUTRAL) -> void:
	if cheering:
		return
	cheering = true
	set_animation(anim)
	if emotion != Toon.Emotion.NEUTRAL:
		toon.set_emotion(emotion)
	await Task.delay(duration)
	cheering = false
	toon.set_emotion(Toon.Emotion.NEUTRAL)
	if get_animation() == anim:
		set_animation('neutral')

func _check_idle_emote(delta: float) -> void:
	var ppos := player.global_position
	var standing_still: bool = ppos.distance_to(last_player_pos) < 0.01 and player.controller.current_state.accepts_interaction()
	last_player_pos = ppos
	if not standing_still or cheering:
		if not standing_still:
			idle_time = 0.0
		return
	idle_time += delta
	if idle_time < IDLE_EMOTE_TIME:
		return
	idle_time = -RNG.channel(RNG.ChannelTrueRandom).randf_range(IDLE_EMOTE_COOLDOWN.x, IDLE_EMOTE_COOLDOWN.y)
	var emote: Dictionary = IDLE_EMOTES.pick_random()
	face_position(ppos)
	if not emote['phrase'].is_empty():
		toon.speak(emote['phrase'])
	play_emote(emote['anim'], EMOTE_DURATION, emote['emotion'])

#endregion

#region Battle

func battle_started(battle: BattleNode) -> void:
	state = PartnerState.BATTLE
	show()
	var pos := battle.get_partner_position(player.partners.find(self))
	var tween := move_to(pos)
	tween.finished.connect(func():
		tween.kill()
		face_position(battle.global_position)
		set_animation('neutral')
		s_battle_ready.emit()
	)
	battle.s_battle_ending.connect(battle_ending, CONNECT_ONE_SHOT)
	battle.s_battle_end.connect(battle_ended, CONNECT_ONE_SHOT)

func get_attack() -> BattleAction:
	var action := ToonPartnerAction.new()
	action.action_name = "Toon Partner"
	action.user = self
	action.targets = [player]
	return action

func battle_ending() -> void:
	set_animation('victory-dance')

func battle_ended() -> void:
	state = PartnerState.FOLLOW
	trail_points.clear()
	trail_anims.clear()

#endregion

#region Actor helpers (mirrors Player so gag movies can use the partner)

func move_to(pos: Vector3) -> Tween:
	var time := maxf(global_position.distance_to(pos) / RUN_SPEED, 0.2)
	set_animation('run')
	face_position(pos)
	var tween := create_tween()
	tween.tween_property(self, 'global_position', pos, time)
	return tween

func face_position(pos: Vector3) -> void:
	var flat := Vector3(pos.x, toon.global_position.y, pos.z)
	if toon.global_position.distance_to(flat) < 0.01:
		return
	toon.look_at(flat, Vector3.UP, true)

func set_animation(anim: String) -> void:
	if animator and get_animation() != anim:
		toon.set_animation(anim)

func get_animation() -> String:
	return animator.current_animation if animator else ""

func speak(phrase: String) -> void:
	toon.speak(phrase)

func quick_heal(amount: int, allow_iframes := true) -> void:
	if is_instance_valid(player):
		player.quick_heal(amount, allow_iframes)

#endregion
