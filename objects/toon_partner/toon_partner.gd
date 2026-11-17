extends Actor
class_name ToonPartner

## Trail-following (Tails style) values
const RECORD_STEP := 0.1
const MAX_HISTORY := 120
const SNAP_DISTANCE := 15.0
const RUN_SPEED := 8.0
const GROUND_ANIMS: Array[String] = ['walk', 'run']
const AIR_IDLE_ANIM := 'jump-zhang'
const AIR_MOVING_ANIM := 'zhang'

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

## Long idle behaviour (seconds of the player standing still)
const ROAM_START_TIME := 60.0
const IMPATIENT_TIME := 180.0
const AWAY_TIME := 300.0
const ROAM_RADIUS := 6.0
const ROAM_SPEED := 2.0
const ROAM_PAUSE := Vector2(2.0, 5.0)
const BORED_INTERVAL := Vector2(15.0, 25.0)
const BORED_DURATION := 4.0
const IMPATIENT_LINES: Array[String] = ["*sigh*", "Any day now...", "Helloooo?", "Are we there yet?"]
const RETURN_QUIPS: Array[String] = [
	"Oh, NOW you move?",
	"Took you long enough!",
	"I aged like three years back there.",
	"Wow. Riveting adventure so far.",
	"Did you fall asleep at the keyboard?",
	"Great, I was just about to file a missing Toon report.",
	"Finally! The Cogs were starting to feel sorry for me.",
]

## Idle games between partners (tag / pie toss)
const GAME_COOLDOWN := Vector2(8.0, 16.0)
const TAG_DURATION := 14.0
const TAG_RUN_SPEED := 3.6
const TAG_CHASE_SPEED := 4.0
const TAG_CATCH_DISTANCE := 0.7
const TAG_START_LINES: Array[String] = ["Can't catch me!", "Bet you can't tag me!", "Wanna play tag?"]
const TAG_LINES: Array[String] = ["Tag! You're it!", "Gotcha! You're it!", "Tag!"]
const PIE_TOSSES := 4
const PIE_TOSS_DISTANCE := 3.0
const PIE_GAG := preload("res://objects/battle/battle_resources/gag_loadouts/gags/throw/cream_pie_slice.tres")
const SPLAT_SCENE := "res://objects/battle/effects/splat/splat.tscn"
const PIE_START_LINES: Array[String] = ["Think fast!", "Pie fight!", "Heads up!"]
const PIE_HIT_LINES: Array[String] = ["Hey!", "Mmm, cream!", "Right in the kisser!", "You'll pay for that!", "Ha ha ha!"]

## Floor clear team dance
const DANCE_ANIM := 'happy-dance'
const DANCE_START_DELAY := 1.6
const DANCE_SPACING := 0.9

## Entrance
const ENTRANCE_PHRASES: Array[String] = ["Hi, pal!", "I'm here!", "Let's go!", "Ready when you are!"]

## Goodbye
const LOSE_GOODBYES: Array[String] = ["Oh no! I'll catch you next time!", "We'll get 'em next time, pal!", "Don't give up! See ya!"]
const GOODBYE_WAVE_TIME := 2.0

## Nameplate
const NAMEPLATE_HEIGHT := 1.0

## Floor chatter
const FLOOR_CHAT_DELAY := 2.5
const FLOOR_LINES: Array[String] = [
	"Tip: Lure a Cog before you Trap it!",
	"Tip: Throw at a lured Cog to knock it back!",
	"Tip: Squirt and Throw make a great combo!",
	"Tip: Keep an eye on your Laff meter!",
	"Tip: Sound gags hit more than one Cog!",
	"Tip: Save some beans for the shop.",
	"Why did the Cog cross the road? It was outsourced!",
	"What's a Cog's favorite dance? The Robot!",
	"Cogs can't take a joke... let's give them a few!",
	"I told a Flunky a joke. He filed it for later!",
	"Knock knock! Who's there? Not the Cogs for long!",
	"This floor looks Toontastic!",
	"Let's show these Cogs who's boss!",
]

enum PartnerState { FOLLOW, BATTLE, CUTSCENE }
var state := PartnerState.FOLLOW

@onready var toon: Toon = $Toon
@onready var head_node: Node3D = $Head
@onready var nameplate: Label3D = $Nameplate

var dna: ToonDNA
var partner_name := ""
## Stays dormant (hidden, silent) until the player first gains control, so it sits out opening sequences
var active := false
var entering := false
## Set once the partner has said goodbye; it stays gone for the rest of the run
var departed := false
var accessories: Array[ItemAccessory] = []
var shoes: ItemShoe
var idle_time := 0.0
var animator: AnimationPlayer
var trail_points: Array[Vector3] = []
var trail_anims: Array[String] = []
var prev_hp := -1
var prev_gag_total := -1
var tracked_stats: PlayerStats
var cheering := false

## Long idle state
var last_player_pos := Vector3.ZERO
var player_moved := false
var still_time := 0.0
var roam_target := Vector3.ZERO
var has_roam_target := false
var roam_pause := 0.0
var bored_timer := 0.0
var away := false
var teleporting := false
var in_game := false
var game_cooldown := 10.0

var player: Player:
	get: return Util.get_player()
## Who this partner trails: the player, or the Toon Partner directly ahead in line
var leader: Node3D:
	get:
		var prev: Node3D = player
		for p in player.partners:
			if p == self:
				break
			if p is ToonPartner and is_instance_valid(p) and not p.is_queued_for_deletion() and not p.departed:
				prev = p
		return prev
## Only the front partner does chatter, so several partners don't talk over each other
var is_lead_partner: bool:
	get: return leader == player
## Follow distance comes from the settings slider
var follow_spacing: float:
	get: return SaveFileService.settings_file.partner_follow_distance
## Partner's own accuracy multiplier on top of the player's (character setting)
var accuracy_mult: float:
	get:
		if is_instance_valid(player) and player.stats and player.stats.character:
			return player.stats.character.partner_accuracy
		return 1.0
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
	for accessory in accessories:
		accessory.place_accessory(toon)
	if shoes:
		shoes.place_shoes(toon)
	BattleService.s_cog_died.connect(_on_cog_died)
	Util.s_floor_started.connect(_on_floor_started)
	Globals.s_elevator_entered.connect(_on_elevator_entered)
	if is_instance_valid(player):
		player.s_dying.connect(say_goodbye)

func _process(_delta: float) -> void:
	if toon.head_bone:
		nameplate.global_position = Vector3(global_position.x, toon.head_bone.global_position.y + NAMEPLATE_HEIGHT, global_position.z)

func _physics_process(delta: float) -> void:
	if not is_instance_valid(player) or not player.is_inside_tree() or departed:
		return
	if is_selecting_floor():
		_floor_select_tick()
		return
	if not active:
		_dormant_tick()
		return
	_check_passive_heal()
	_check_gag_unlocks()
	if state != PartnerState.FOLLOW:
		return
	if entering:
		return
	_update_idle(delta)
	if away:
		if not teleporting:
			hide()
		return
	visible = player.visible
	if still_time >= ROAM_START_TIME:
		if in_game:
			return
		_roam(delta)
		_maybe_start_game(delta)
	else:
		_follow_trail()
		_check_idle_emote(delta)

func player_has_control() -> bool:
	return player.visible and player.controller.current_state.accepts_interaction()

func is_selecting_floor() -> bool:
	return SceneLoader.current_scene is ElevatorScene

## Hidden while picking a floor; rejoin the line fresh afterwards
func _floor_select_tick() -> void:
	hide()
	state = PartnerState.FOLLOW
	trail_points.clear()
	trail_anims.clear()
	_reset_idle()
	away = false

## Keep baselines current without reacting, and wake up once the player can move
func _dormant_tick() -> void:
	hide()
	if stats:
		prev_hp = stats.hp
		tracked_stats = null
		_check_gag_unlocks()
	if state == PartnerState.FOLLOW and player_has_control():
		active = true
		snap_to_player()
		show()
		do_entrance()

## Pops up out of a teleport hole and waves hello
func do_entrance() -> void:
	entering = true
	face_position(player.global_position)
	await toon.teleport_in()
	entering = false
	if state != PartnerState.FOLLOW:
		return
	face_position(player.global_position)
	speak(ENTRANCE_PHRASES.pick_random())
	play_emote('wave', EMOTE_DURATION, Toon.Emotion.DELIGHTED)

## Waves, then teleports out when the player goes sad
func say_goodbye() -> void:
	if departed:
		return
	departed = true
	if not active or not visible:
		hide()
		return
	cheering = true
	entering = false
	face_position(player.global_position)
	speak(LOSE_GOODBYES.pick_random())
	set_animation('wave')
	toon.set_emotion(Toon.Emotion.SAD)
	await Task.delay(GOODBYE_WAVE_TIME)
	await toon.teleport_out()
	hide()

#region Following

func _follow_trail() -> void:
	var lead := leader
	var ppos := lead.global_position
	if trail_points.is_empty() or global_position.distance_to(ppos) > SNAP_DISTANCE:
		snap_to_player()
		return
	
	# Record the leader's path, along with what they were doing
	if trail_points.back().distance_to(ppos) >= RECORD_STEP:
		trail_points.append(ppos)
		trail_anims.append(lead.get_animation())
		if trail_points.size() > MAX_HISTORY:
			trail_points.pop_front()
			trail_anims.pop_front()
	
	var idx := _get_trail_index()
	var target := trail_points[idx]
	var flat_step := Vector2(target.x - global_position.x, target.z - global_position.z).length()
	var grounded := is_on_ground()
	if global_position.distance_to(target) < 0.02:
		if not cheering:
			set_animation('neutral' if grounded else AIR_IDLE_ANIM)
		return
	
	if flat_step > 0.02:
		face_position(target)
	global_position = global_position.lerp(target, 0.35)
	if cheering:
		return
	var anim: String
	if not grounded:
		anim = AIR_MOVING_ANIM if flat_step > 0.02 else AIR_IDLE_ANIM
	else:
		anim = trail_anims[idx]
		if not anim in GROUND_ANIMS:
			anim = 'run' if flat_step > 0.3 else 'walk'
	set_animation(anim)

## Walks back along the recorded path until we're follow_spacing behind the leader
func _get_trail_index() -> int:
	var dist := 0.0
	var last := leader.global_position
	for i in range(trail_points.size() - 1, -1, -1):
		dist += last.distance_to(trail_points[i])
		last = trail_points[i]
		if dist >= follow_spacing:
			return i
	return 0

## Snaps in line behind the leader (player or the partner ahead)
func snap_to_player() -> void:
	var lead := leader
	var ppos := lead.global_position
	var lead_toon: Node3D = lead.toon
	var behind: Vector3 = ppos - lead_toon.global_basis.z.normalized() * follow_spacing
	behind.y = ppos.y
	trail_points = [behind, ppos]
	trail_anims = ['neutral', 'neutral']
	global_position = behind
	reset_physics_interpolation()
	face_position(ppos)
	set_animation('neutral')

func _raycast(from: Vector3, to: Vector3) -> Dictionary:
	var query := PhysicsRayQueryParameters3D.create(from, to, player.collision_mask, [player.get_rid()])
	return get_world_3d().direct_space_state.intersect_ray(query)

func is_on_ground() -> bool:
	return not _raycast(global_position + Vector3.UP * 0.2, global_position + Vector3.DOWN * 0.2).is_empty()

#endregion

#region Long idle (roam / impatient / away)

func _update_idle(delta: float) -> void:
	var ppos := player.global_position
	player_moved = ppos.distance_to(last_player_pos) > 0.01
	last_player_pos = ppos
	if player_moved:
		if still_time >= ROAM_START_TIME:
			_return_to_line()
		still_time = 0.0
	elif player_has_control():
		still_time += delta
		if still_time >= AWAY_TIME and not away:
			_go_away()

func _reset_idle() -> void:
	still_time = 0.0
	has_roam_target = false
	roam_pause = 0.0
	bored_timer = 0.0

func _roam(delta: float) -> void:
	if cheering:
		return
	if still_time >= IMPATIENT_TIME:
		bored_timer -= delta
		if bored_timer <= 0.0:
			bored_timer = RNG.channel(RNG.ChannelTrueRandom).randf_range(BORED_INTERVAL.x, BORED_INTERVAL.y)
			if is_lead_partner:
				speak(IMPATIENT_LINES.pick_random())
			play_emote('bored', BORED_DURATION)
			return
	if roam_pause > 0.0:
		roam_pause -= delta
		set_animation('neutral')
		return
	if not has_roam_target:
		has_roam_target = _pick_roam_point()
		if not has_roam_target:
			roam_pause = 1.0
			return
	var to := roam_target - global_position
	to.y = 0.0
	if to.length() < 0.1:
		has_roam_target = false
		roam_pause = RNG.channel(RNG.ChannelTrueRandom).randf_range(ROAM_PAUSE.x, ROAM_PAUSE.y)
		set_animation('neutral')
		return
	face_position(roam_target)
	var next := global_position + to.normalized() * minf(ROAM_SPEED * delta, to.length())
	var ground := _raycast(next + Vector3.UP * 1.0, next + Vector3.DOWN * 2.0)
	if ground.is_empty():
		has_roam_target = false
		return
	next.y = ground.position.y
	global_position = next
	set_animation('walk')

## Picks a reachable spot on the ground near the player
func _pick_roam_point() -> bool:
	var rng := RNG.channel(RNG.ChannelTrueRandom)
	var center := player.global_position
	for i in 8:
		var angle := rng.randf() * TAU
		var radius := rng.randf_range(1.5, ROAM_RADIUS)
		var candidate := center + Vector3(cos(angle) * radius, 0.0, sin(angle) * radius)
		if not _raycast(global_position + Vector3.UP * 0.5, candidate + Vector3.UP * 0.5).is_empty():
			continue
		var hit := _raycast(candidate + Vector3.UP * 1.5, candidate + Vector3.DOWN * 3.0)
		if hit.is_empty() or absf(hit.position.y - center.y) > 1.0:
			continue
		roam_target = hit.position
		return true
	return false

func _go_away() -> void:
	away = true
	teleporting = true
	await toon.teleport_out()
	teleporting = false
	if away:
		hide()
	else:
		_reappear()

func _reappear() -> void:
	snap_to_player()
	show()
	entering = true
	await toon.teleport_in()
	entering = false

func _return_to_line() -> void:
	var was_away := away
	_reset_idle()
	away = false
	if was_away and not teleporting:
		_reappear()
	if is_lead_partner:
		await Task.delay(1.2 if not was_away else 2.0)
		if active and not departed and state == PartnerState.FOLLOW:
			speak(RETURN_QUIPS.pick_random())

#endregion

#region Idle games

## Partners pair up in line order: 1st & 2nd, 3rd & 4th...
func _get_game_buddy() -> ToonPartner:
	var line: Array[ToonPartner] = []
	for p in player.partners:
		if p is ToonPartner and is_instance_valid(p) and not p.is_queued_for_deletion() and not p.departed:
			line.append(p)
	var idx := line.find(self)
	if idx < 0 or idx % 2 == 1 or idx + 1 >= line.size():
		return null
	return line[idx + 1]

func _can_play() -> bool:
	return is_inside_tree() and active and not departed and not away and not entering \
		and state == PartnerState.FOLLOW and still_time >= ROAM_START_TIME

func _game_ok(buddy: ToonPartner) -> bool:
	return is_instance_valid(buddy) and _can_play() and buddy._can_play()

func _maybe_start_game(delta: float) -> void:
	if in_game or cheering:
		return
	game_cooldown -= delta
	if game_cooldown > 0.0:
		return
	var rng := RNG.channel(RNG.ChannelTrueRandom)
	game_cooldown = rng.randf_range(GAME_COOLDOWN.x, GAME_COOLDOWN.y)
	var buddy := _get_game_buddy()
	if not buddy or buddy.in_game or buddy.cheering or not _game_ok(buddy):
		return
	in_game = true
	buddy.in_game = true
	if rng.randf() < 0.5:
		await _play_tag(buddy)
	else:
		await _play_pie_toss(buddy)
	for p: ToonPartner in [self, buddy]:
		if is_instance_valid(p):
			p.in_game = false
			p.has_roam_target = false
			if p.state == PartnerState.FOLLOW and not p.cheering:
				p.set_animation('neutral')

## Moves toward a point on the ground near the player; returns false if blocked
func _step_toward(target: Vector3, speed: float, delta: float, anim := 'run') -> bool:
	var to := target - global_position
	to.y = 0.0
	if to.length() < 0.05:
		return true
	var next := global_position + to.normalized() * minf(speed * delta, to.length())
	if next.distance_to(player.global_position) > ROAM_RADIUS + 1.5:
		return false
	if not _raycast(global_position + Vector3.UP * 0.5, next + Vector3.UP * 0.5).is_empty():
		return false
	var ground := _raycast(next + Vector3.UP * 1.0, next + Vector3.DOWN * 2.0)
	if ground.is_empty():
		return false
	next.y = ground.position.y
	face_position(target)
	global_position = next
	set_animation(anim)
	return true

## A reachable roam point as far from `threat` as possible
func _pick_point_away_from(threat: Vector3) -> Vector3:
	var best := global_position
	var best_dist := -1.0
	for i in 6:
		if _pick_roam_point() and roam_target.distance_to(threat) > best_dist:
			best = roam_target
			best_dist = roam_target.distance_to(threat)
	has_roam_target = false
	return best

func _play_tag(buddy: ToonPartner) -> void:
	var chaser: ToonPartner = self
	var runner: ToonPartner = buddy
	runner.speak(TAG_START_LINES.pick_random())
	var flee_target := runner._pick_point_away_from(chaser.global_position)
	var elapsed := 0.0
	var wait := 0.8
	while elapsed < TAG_DURATION and _game_ok(buddy):
		await get_tree().physics_frame
		var delta := get_physics_process_delta_time()
		elapsed += delta
		if runner.global_position.distance_to(flee_target) < 0.4 or not runner._step_toward(flee_target, TAG_RUN_SPEED, delta):
			flee_target = runner._pick_point_away_from(chaser.global_position)
		if wait > 0.0:
			# The new "it" counts to one before chasing
			wait -= delta
			chaser.face_position(runner.global_position)
			chaser.set_animation('neutral')
			continue
		chaser._step_toward(runner.global_position, TAG_CHASE_SPEED, delta)
		if chaser.global_position.distance_to(runner.global_position) < TAG_CATCH_DISTANCE:
			chaser.speak(TAG_LINES.pick_random())
			var tagged := runner
			runner = chaser
			chaser = tagged
			wait = 1.2
			flee_target = runner._pick_point_away_from(chaser.global_position)

func _play_pie_toss(buddy: ToonPartner) -> void:
	# Find a clear spot across from us for the buddy to stand
	var spot := Vector3.ZERO
	var found := false
	var rng := RNG.channel(RNG.ChannelTrueRandom)
	for i in 8:
		var angle := rng.randf() * TAU
		var candidate := global_position + Vector3(cos(angle), 0.0, sin(angle)) * PIE_TOSS_DISTANCE
		if candidate.distance_to(player.global_position) > ROAM_RADIUS:
			continue
		if not _raycast(global_position + Vector3.UP * 0.8, candidate + Vector3.UP * 0.8).is_empty():
			continue
		var hit := _raycast(candidate + Vector3.UP * 1.5, candidate + Vector3.DOWN * 3.0)
		if hit.is_empty():
			continue
		spot = hit.position
		found = true
		break
	if not found:
		return
	set_animation('neutral')
	var walk_time := 0.0
	while buddy.global_position.distance_to(spot) > 0.15 and walk_time < 6.0 and _game_ok(buddy):
		await get_tree().physics_frame
		walk_time += get_physics_process_delta_time()
		if not buddy._step_toward(spot, ROAM_SPEED * 1.5, get_physics_process_delta_time(), 'walk'):
			break
	if not _game_ok(buddy):
		return
	speak(PIE_START_LINES.pick_random())
	var thrower: ToonPartner = self
	var catcher: ToonPartner = buddy
	for i in PIE_TOSSES:
		if not _game_ok(buddy):
			return
		await _toss_pie(thrower, catcher, buddy)
		var swap := thrower
		thrower = catcher
		catcher = swap
		await Task.delay(0.6)

func _toss_pie(thrower: ToonPartner, catcher: ToonPartner, buddy: ToonPartner) -> void:
	thrower.face_position(catcher.global_position)
	catcher.face_position(thrower.global_position)
	catcher.set_animation('neutral')
	var pie: Node3D = PIE_GAG.model.instantiate()
	thrower.toon.right_hand_bone.add_child(pie)
	pie.scale *= PIE_GAG.scale
	pie.rotation_degrees.y += 180.0
	thrower.set_animation('pie-throw')
	await Task.delay(2.545)
	if not _game_ok(buddy) or not is_instance_valid(pie):
		if is_instance_valid(pie):
			pie.queue_free()
		return
	AudioManager.play_sound(PIE_GAG.throw_sfx if PIE_GAG.throw_sfx else GagThrow.FALLBACK_THROW_SFX)
	await Task.delay(0.1)
	var head: Node3D = catcher.toon.head_bone if catcher.toon.head_bone else catcher.head_node
	pie.top_level = true
	var tween := pie.create_tween()
	tween.tween_property(pie, 'global_position', head.global_position, 0.3)
	await tween.finished
	pie.queue_free()
	if not is_instance_valid(catcher):
		return
	var splat: Node3D = load(SPLAT_SCENE).instantiate()
	splat.modulate = PIE_GAG.splat_color
	catcher.head_node.add_child(splat)
	if PIE_GAG.splat_sfx:
		AudioManager.play_sound(PIE_GAG.splat_sfx)
	catcher.set_animation('cringe')
	catcher.toon.set_emotion(Toon.Emotion.LAUGH)
	catcher.speak(PIE_HIT_LINES.pick_random())
	await Task.delay(1.5)
	if is_instance_valid(catcher):
		catcher.toon.set_emotion(Toon.Emotion.NEUTRAL)

#endregion

#region Floor clear team dance

func _on_elevator_entered(elevator: Elevator) -> void:
	if not active or departed or away or state != PartnerState.FOLLOW or not is_instance_valid(elevator.player_pos):
		return
	state = PartnerState.CUTSCENE
	var start_ms := Time.get_ticks_msec()
	_reset_idle()
	show()
	var spot: Node3D = elevator.player_pos
	var index := 0
	for p in player.partners:
		if p == self:
			break
		if p is ToonPartner:
			index += 1
	var side := -1.0 if index % 2 == 0 else 1.0
	var offset := DANCE_SPACING * float(index / 2 + 1) * side
	var pos := spot.to_global(Vector3(offset, 0.0, 0.0))
	if global_position.distance_to(pos) > SNAP_DISTANCE:
		global_position = pos
		reset_physics_interpolation()
	else:
		var tween := move_to(pos, DANCE_START_DELAY - 0.2)
		await tween.finished
		tween.kill()
	set_animation('neutral')
	var toon_scale := toon.scale
	toon.global_rotation.y = spot.global_rotation.y
	toon.scale = toon_scale
	# Everyone starts on the same beat, regardless of how far they ran
	var elapsed := float(Time.get_ticks_msec() - start_ms) / 1000.0
	await Task.delay(maxf(DANCE_START_DELAY - elapsed, 0.01))
	if state == PartnerState.CUTSCENE:
		cheering = false
		set_animation(DANCE_ANIM)
		toon.set_emotion(Toon.Emotion.DELIGHTED)

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
	if not is_instance_valid(player) or player.stats.hp <= 0 or away:
		return
	var amount := ceili(player.stats.max_hp * HEAL_PERCENT)
	speak(HEAL_PHRASES.pick_random())
	AudioManager.play_sound(HEAL_SFX)
	player.quick_heal(amount)
	prev_hp = player.stats.hp

#endregion

#region Floor chatter

func _on_floor_started(_game_floor) -> void:
	state = PartnerState.FOLLOW
	toon.set_emotion(Toon.Emotion.NEUTRAL)
	# Wait out any floor intro before chatting
	await Task.delay(FLOOR_CHAT_DELAY)
	var waited := 0.0
	while waited < 30.0 and not (active and is_instance_valid(player) and player_has_control()):
		await Task.delay(0.25)
		waited += 0.25
	await Task.delay(1.0)
	if is_inside_tree() and visible and active and not departed and is_lead_partner and state == PartnerState.FOLLOW:
		speak(RNG.channel(RNG.ChannelTrueRandom).pick_random(FLOOR_LINES))

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
	if not is_inside_tree() or not visible or not active or departed or away:
		return
	if is_lead_partner:
		speak(phrase)
		if with_sfx:
			AudioManager.play_sound(CHEER_SFX)
	# Don't interrupt the partner mid-gag in battle
	if state == PartnerState.BATTLE and get_animation() != 'neutral':
		return
	if state == PartnerState.CUTSCENE:
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
	if player_moved or cheering or not player_has_control():
		if player_moved or not player_has_control():
			idle_time = 0.0
		return
	idle_time += delta
	if idle_time < IDLE_EMOTE_TIME:
		return
	idle_time = -RNG.channel(RNG.ChannelTrueRandom).randf_range(IDLE_EMOTE_COOLDOWN.x, IDLE_EMOTE_COOLDOWN.y)
	var emote: Dictionary = IDLE_EMOTES.pick_random()
	face_position(player.global_position)
	if not emote['phrase'].is_empty():
		speak(emote['phrase'])
	play_emote(emote['anim'], EMOTE_DURATION, emote['emotion'])

#endregion

#region Battle

func battle_started(battle: BattleNode) -> void:
	state = PartnerState.BATTLE
	_reset_idle()
	if away or not active:
		away = false
		active = true
		snap_to_player()
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

func move_to(pos: Vector3, max_time := -1.0) -> Tween:
	var time := maxf(global_position.distance_to(pos) / RUN_SPEED, 0.2)
	if max_time > 0.0:
		time = minf(time, max_time)
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
	if dialogue_enabled():
		toon.speak(phrase)

static func dialogue_enabled() -> bool:
	return SaveFileService.settings_file.partner_dialogue

func quick_heal(amount: int, allow_iframes := true) -> void:
	if is_instance_valid(player):
		player.quick_heal(amount, allow_iframes)

#endregion
