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

enum PartnerState { FOLLOW, BATTLE }
var state := PartnerState.FOLLOW

@onready var toon: Toon = $Toon
@onready var head_node: Node3D = $Head

var dna: ToonDNA
var animator: AnimationPlayer
var trail_points: Array[Vector3] = []
var trail_anims: Array[String] = []
var prev_hp := -1

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

func _physics_process(_delta: float) -> void:
	if not is_instance_valid(player) or not player.is_inside_tree():
		return
	_check_passive_heal()
	if state != PartnerState.FOLLOW:
		return
	visible = player.visible
	_follow_trail()

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
		set_animation('neutral')
		return
	
	face_position(target)
	global_position = global_position.lerp(target, 0.35)
	var anim := trail_anims[idx]
	if not anim in TRAIL_ANIMS:
		anim = 'run' if step > 0.3 else 'walk'
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
