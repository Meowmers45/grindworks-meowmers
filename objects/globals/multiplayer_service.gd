extends Node

const DEFAULT_PORT := 8910
const MAX_PLAYERS := 4
const STATE_INTERVAL := 0.1
const JOIN_TIMEOUT_SECONDS := 15.0
const TOON_SCENE := "res://objects/toon/toon.tscn"

signal s_status_changed(message: String)
signal s_session_changed(connected: bool)
signal s_player_joined(peer_id: int)
signal s_player_left(peer_id: int)

var peer: ENetMultiplayerPeer
var peer_states: Dictionary[int, Dictionary] = {}
var remote_avatars: Dictionary[int, Node3D] = {}
var battle_players: Dictionary[int, Player] = {}
var network_run_seed := -1
var pending_battle_turns: Dictionary[String, Dictionary] = {}
var completed_battle_turns: Dictionary[String, Dictionary] = {}
var _state_timer := 0.0
var _local_player: Player
var _title_screen: Node
var _syncing_received_item := false
var _local_share_paths: Array[String] = []
var _started_linked_run := false
var _pending_linked_run := false
var _join_timeout_remaining := 0.0
var _session_handshake_pending := false

var is_connected_to_session: bool:
	get: return multiplayer.multiplayer_peer != null and multiplayer.multiplayer_peer.get_connection_status() == MultiplayerPeer.CONNECTION_CONNECTED

var is_host: bool:
	get: return multiplayer.is_server() and multiplayer.multiplayer_peer != null

var player_count: int:
	get: return 1 + multiplayer.get_peers().size() if multiplayer.multiplayer_peer else 1

func _ready() -> void:
	multiplayer.peer_connected.connect(_on_peer_connected)
	multiplayer.peer_disconnected.connect(_on_peer_disconnected)
	multiplayer.connected_to_server.connect(_on_connected_to_server)
	multiplayer.connection_failed.connect(_on_connection_failed)
	multiplayer.server_disconnected.connect(_on_server_disconnected)
	ItemService.s_item_applied.connect(_on_item_applied)

func host_game(port: int = DEFAULT_PORT) -> Error:
	if multiplayer.multiplayer_peer:
		disconnect_session()
	var new_peer := ENetMultiplayerPeer.new()
	var result := new_peer.create_server(port, MAX_PLAYERS - 1)
	if result != OK:
		return result
	peer = new_peer
	multiplayer.multiplayer_peer = peer
	peer_states[1] = _make_local_state()
	s_status_changed.emit("Hosting on port %d (share this address with friends)." % port)
	s_session_changed.emit(true)
	return OK

func join_game(address: String, port: int = DEFAULT_PORT) -> Error:
	if multiplayer.multiplayer_peer:
		disconnect_session()
	var clean_address := address.strip_edges()
	if clean_address.is_empty():
		return ERR_INVALID_PARAMETER
	var new_peer := ENetMultiplayerPeer.new()
	var result := new_peer.create_client(clean_address, port)
	if result != OK:
		return result
	peer = new_peer
	multiplayer.multiplayer_peer = peer
	_join_timeout_remaining = JOIN_TIMEOUT_SECONDS
	_session_handshake_pending = true
	s_status_changed.emit("Connecting to %s:%d…" % [clean_address, port])
	return OK

func disconnect_session() -> void:
	if multiplayer.multiplayer_peer:
		multiplayer.multiplayer_peer.close()
		multiplayer.multiplayer_peer = null
	peer = null
	_join_timeout_remaining = 0.0
	_session_handshake_pending = false
	peer_states.clear()
	pending_battle_turns.clear()
	completed_battle_turns.clear()
	_local_share_paths.clear()
	_started_linked_run = false
	_pending_linked_run = false
	for avatar: Node3D in remote_avatars.values():
		if is_instance_valid(avatar):
			avatar.queue_free()
	remote_avatars.clear()
	for battle_player: Player in battle_players.values():
		if is_instance_valid(battle_player): battle_player.queue_free()
	battle_players.clear()
	network_run_seed = -1
	s_status_changed.emit("Offline")
	s_session_changed.emit(false)

func register_title_screen(screen: Node) -> void:
	_title_screen = screen
	if _pending_linked_run and not _started_linked_run:
		_pending_linked_run = false
		_started_linked_run = true
		screen.start_linked_run(network_run_seed, RNG._str_seed, RNG.is_custom_seed)

func set_linked_run_active() -> void:
	_started_linked_run = true

func register_local_player(player_node: Player) -> void:
	_local_player = player_node
	var local_id := multiplayer.get_unique_id() if multiplayer.multiplayer_peer else 1
	peer_states[local_id] = _make_local_state()
	if is_host:
		_started_linked_run = true
	_local_share_paths = _local_item_paths()
	if not is_connected_to_session:
		return
	if is_host:
		for peer_id in multiplayer.get_peers():
			if _can_share_with(local_id, peer_id):
				_share_inventory_between(local_id, peer_id)
			_send_state(peer_id, 1, peer_states[1])
	else:
		rpc_id(1, "_rpc_receive_state", multiplayer.get_unique_id(), _make_local_state())

func _make_local_state() -> Dictionary:
	var state := {"name": "Player", "position": Vector3.ZERO, "rotation": 0.0, "animation": "neutral", "dna": {}, "stats": {}, "gag_loadout": [], "share_items": false, "items": [], "battle_id": ""}
	if not is_instance_valid(_local_player) or not is_instance_valid(_local_player.toon):
		return state
	state.name = _local_player.character.character_name if _local_player.character else "Player"
	state.position = _local_player.global_position
	state.rotation = _local_player.toon.global_rotation.y
	state.animation = _local_player.get_animation() if is_instance_valid(_local_player.animator) else "neutral"
	state.dna = _pack_dna(_local_player.toon.toon_dna)
	state.stats = _pack_player_stats(_local_player.stats)
	state.gag_loadout = _pack_gag_loadout(_local_player.character.gag_loadout)
	if is_instance_valid(BattleService.ongoing_battle):
		state.battle_id = get_battle_key(BattleService.ongoing_battle)
	state.share_items = SaveFileService.settings_file.multiplayer_item_sync
	for item: Item in _local_player.stats.items:
		if not item.resource_path.is_empty() and not state.items.has(item.resource_path):
			state.items.append(item.resource_path)
	return state

func _process(delta: float) -> void:
	if _session_handshake_pending:
		_join_timeout_remaining -= delta
		if _join_timeout_remaining <= 0.0:
			var timed_out_peer := multiplayer.multiplayer_peer
			var connection_status := timed_out_peer.get_connection_status() if timed_out_peer else MultiplayerPeer.CONNECTION_DISCONNECTED
			disconnect_session()
			if connection_status == MultiplayerPeer.CONNECTION_CONNECTED:
				s_status_changed.emit("Host did not respond. Check that the host is running the same game version.")
			else:
				s_status_changed.emit("Connection timed out. Check the host address, port, firewall, and network.")
			return
	if not is_connected_to_session:
		return
	_state_timer += delta
	if _state_timer >= STATE_INTERVAL:
		_state_timer = 0.0
		var previous_state: Dictionary = peer_states.get(multiplayer.get_unique_id(), {})
		var state := _make_local_state()
		var local_id := multiplayer.get_unique_id()
		peer_states[local_id] = state
		if is_host and not bool(previous_state.get("share_items", false)) and bool(state.get("share_items", false)):
			for peer_id in multiplayer.get_peers():
				if _can_share_with(local_id, peer_id):
					_share_inventory_between(local_id, peer_id)
		if is_host:
			for peer_id in multiplayer.get_peers():
				_send_state(peer_id, local_id, state)
		else:
			rpc_id(1, "_rpc_receive_state", local_id, state)
	for peer_id in remote_avatars:
		var state: Dictionary = peer_states.get(peer_id, {})
		var avatar: Node3D = remote_avatars[peer_id]
		if state.is_empty() or not is_instance_valid(avatar):
			continue
		avatar.global_position = avatar.global_position.lerp(state.position, 0.35)
		avatar.rotation.y = lerp_angle(avatar.rotation.y, float(state.rotation), 0.35)
		if avatar.has_meta("toon"):
			var toon: Toon = avatar.get_meta("toon")
			if is_instance_valid(toon) and toon.get_animation() != state.animation:
				toon.set_animation(state.animation)

func get_or_create_battle_player(player_id: int, manager: BattleManager) -> Player:
	if battle_players.has(player_id) and is_instance_valid(battle_players[player_id]):
		return battle_players[player_id]
	var player_scene := load("res://objects/player/player.tscn") as PackedScene
	var remote_player := player_scene.instantiate() as Player
	remote_player.set_script(load("res://objects/player/remote_battle_player.gd"))
	var state: Dictionary = peer_states.get(player_id, {})
	var DNA := _unpack_dna(state.get("dna", {}))
	var remote_character := PlayerCharacter.new()
	remote_character.character_name = state.get("name", "Player %d" % player_id)
	remote_character.dna = DNA
	remote_character.gag_loadout = _unpack_gag_loadout(state.get("gag_loadout", []))
	remote_player.stats = PlayerStats.new()
	remote_player.stats.character = remote_character
	var remote_stats: Dictionary = state.get("stats", {})
	remote_player.stats.max_hp = int(remote_stats.get("max_hp", Util.get_player().stats.max_hp))
	remote_player.stats.hp = int(remote_stats.get("hp", remote_player.stats.max_hp))
	remote_player.stats.turns = int(remote_stats.get("turns", Util.get_player().stats.turns))
	remote_player.stats.damage = float(remote_stats.get("damage", Util.get_player().stats.damage))
	remote_player.stats.defense = float(remote_stats.get("defense", Util.get_player().stats.defense))
	remote_player.stats.accuracy = float(remote_stats.get("accuracy", Util.get_player().stats.accuracy))
	remote_player.stats.evasiveness = float(remote_stats.get("evasiveness", Util.get_player().stats.evasiveness))
	remote_player.stats.speed = float(remote_stats.get("speed", Util.get_player().stats.speed))
	remote_player.stats.crit_mult = float(remote_stats.get("crit_mult", Util.get_player().stats.crit_mult))
	remote_player.stats.healing_effectiveness = float(remote_stats.get("healing_effectiveness", Util.get_player().stats.healing_effectiveness))
	remote_player.stats.gag_effectiveness = remote_stats.get("gag_effectiveness", Util.get_player().stats.gag_effectiveness).duplicate(true)
	remote_player.stats.mod_cog_dmg_mult = float(remote_stats.get("mod_cog_dmg_mult", Util.get_player().stats.mod_cog_dmg_mult))
	manager.battle_node.add_child(remote_player)
	remote_player.global_position = manager.battle_node.get_relative_position(manager.battle_node.player_pos + Vector3((player_id - 1) * 1.5, 0, 1))
	remote_player.state = Player.PlayerState.STOPPED
	battle_players[player_id] = remote_player
	return remote_player

func _pack_gag_loadout(loadout: GagLoadout) -> Array[Dictionary]:
	var packed: Array[Dictionary] = []
	if not is_instance_valid(loadout):
		return packed
	for track: Track in loadout.loadout:
		var gag_paths: Array[String] = []
		for gag: ToonAttack in track.gags:
			gag_paths.append(gag.resource_path)
		packed.append({"name": track.track_name, "gags": gag_paths})
	return packed

func _unpack_gag_loadout(packed: Array) -> GagLoadout:
	var loadout := GagLoadout.new()
	for entry: Dictionary in packed:
		var track := Track.new()
		track.track_name = entry.get("name", "")
		for gag_path: String in entry.get("gags", []):
			if gag_path.is_empty() or not ResourceLoader.exists(gag_path):
				continue
			var gag = load(gag_path)
			if gag is ToonAttack:
				track.gags.append(gag)
		loadout.loadout.append(track)
	if loadout.loadout.is_empty() and is_instance_valid(Util.get_player()):
		loadout.loadout = Util.get_player().character.gag_loadout.loadout.duplicate()
	return loadout

func _pack_player_stats(stats: PlayerStats) -> Dictionary:
	return {
		"hp": stats.hp, "max_hp": stats.max_hp, "turns": stats.turns,
		"damage": stats.damage, "defense": stats.defense, "accuracy": stats.accuracy,
		"evasiveness": stats.evasiveness, "speed": stats.speed, "crit_mult": stats.crit_mult,
		"healing_effectiveness": stats.healing_effectiveness,
		"gag_effectiveness": stats.gag_effectiveness.duplicate(true),
		"mod_cog_dmg_mult": stats.mod_cog_dmg_mult
	}

func get_battle_key(manager: BattleManager) -> String:
	var snapped_position := manager.battle_node.global_position.snapped(Vector3(0.25, 0.25, 0.25))
	var battle_name := manager.battle_node.name
	if peer_states.has(1):
		var host_battle_id: String = peer_states[1].get("battle_id", "")
		var host_parts := host_battle_id.split(":", false, 2)
		if host_parts.size() == 3 and host_parts[0] == str(Util.floor_number) and host_parts[1] == battle_name and host_parts[2] == str(snapped_position):
			return host_battle_id
	if is_host:
		return "%d:%s:%s" % [Util.floor_number, battle_name, str(snapped_position)]
	var local_id := "%d:%s:%s" % [Util.floor_number, battle_name, str(snapped_position)]
	var matched_keys: Array[String] = []
	for state: Dictionary in peer_states.values():
		var peer_battle_id: String = state.get("battle_id", "")
		if peer_battle_id.is_empty():
			continue
		var peer_parts := peer_battle_id.split(":", false, 2)
		if peer_parts.size() < 3 or peer_parts[0] != str(Util.floor_number) or peer_parts[1] != battle_name or peer_parts[2] != str(snapped_position):
			continue
		matched_keys.append(peer_parts[1])
	if matched_keys.is_empty():
		return local_id
	matched_keys.sort()
	return "%d:%s:%s" % [Util.floor_number, matched_keys[0], str(snapped_position)]

func coordinate_battle_turn(manager: BattleManager, actions: Array[ToonAttack]) -> Dictionary:
	if not is_connected_to_session:
		return {}
	var base_battle_key := get_battle_key(manager)
	var battle_key := "%s:%d" % [base_battle_key, manager.current_round + 1]
	var local_id := multiplayer.get_unique_id()
	if not peer_states.has(local_id):
		peer_states[local_id] = _make_local_state()
	peer_states[local_id]["battle_id"] = base_battle_key
	var submitted := _encode_battle_actions(manager, actions)
	if not is_host:
		rpc_id(1, "_rpc_receive_state", local_id, peer_states[local_id])
	if is_host:
		if not pending_battle_turns.has(battle_key): pending_battle_turns[battle_key] = {}
		pending_battle_turns[battle_key][local_id] = submitted
	else:
		rpc_id(1, "_rpc_submit_battle_turn", battle_key, submitted)
	var wait_started := Time.get_ticks_msec()
	while not completed_battle_turns.has(battle_key):
		if is_host:
			var expected: Array[int] = []
			for peer_id in multiplayer.get_peers():
				if peer_states.get(peer_id, {}).get("battle_id", "") == base_battle_key:
					expected.append(peer_id)
			if peer_states.get(1, {}).get("battle_id", "") == base_battle_key:
				expected.append(1)
			var expected_count := expected.size()
			var submissions: Dictionary = pending_battle_turns.get(battle_key, {})
			if expected_count > 0 and submissions.size() >= expected_count:
				_try_resolve_battle_turn(battle_key)
			elif Time.get_ticks_msec() - wait_started > 60000:
				_try_resolve_battle_turn(battle_key, true)
		elif Time.get_ticks_msec() - wait_started > 65000:
			completed_battle_turns[battle_key] = {local_id: submitted}
		await get_tree().create_timer(0.05).timeout
	var result: Dictionary = completed_battle_turns[battle_key].duplicate(true)
	pending_battle_turns.erase(battle_key)
	completed_battle_turns.erase(battle_key)
	if is_host:
		for peer_id in multiplayer.get_peers():
			if peer_states.get(peer_id, {}).get("battle_id", "") == base_battle_key:
				peer_states[peer_id]["battle_id"] = ""
	peer_states[local_id]["battle_id"] = ""
	return result

func _encode_battle_actions(manager: BattleManager, actions: Array[ToonAttack]) -> Array[Dictionary]:
	var encoded: Array[Dictionary] = []
	for action: ToonAttack in actions:
		var path := action.resource_path
		var is_fire := action is ToonAttackFire
		var target_indexes: Array[int] = []
		for target in action.targets:
			if target in manager.cogs:
				target_indexes.append(manager.cogs.find(target))
		var main_target_index := -1
		if action.main_target in manager.cogs:
			main_target_index = manager.cogs.find(action.main_target)
		encoded.append({"path": path, "fire": is_fire, "name": action.action_name, "targets": target_indexes, "main_target": main_target_index})
	return encoded

func rebuild_battle_actions(manager: BattleManager, encoded: Array) -> Array[ToonAttack]:
	var rebuilt: Array[ToonAttack] = []
	for entry: Dictionary in encoded:
		var action: ToonAttack
		if bool(entry.get("fire", false)):
			if not is_instance_valid(manager.battle_ui) or not is_instance_valid(manager.battle_ui.fire_action):
				continue
			action = manager.battle_ui.fire_action.duplicate(true)
		else:
			var path: String = entry.get("path", "")
			if not path.is_empty() and ResourceLoader.exists(path):
				var loaded = load(path)
				if loaded is ToonAttack:
					action = loaded.duplicate(true)
			if not action:
				var player_node := Util.get_player()
				if not is_instance_valid(player_node) or not is_instance_valid(player_node.character) or not is_instance_valid(player_node.character.gag_loadout):
					continue
				var wanted_name: String = entry.get("name", "")
				for track: Track in player_node.character.gag_loadout.loadout:
					for gag: ToonAttack in track.gags:
						if gag.action_name == wanted_name:
							action = gag.duplicate(true)
							break
					if action:
						break
			if not action: continue
		if not action: continue
		if not action.resource_path.is_empty() and ResourceLoader.exists(action.resource_path):
			var local_action = load(action.resource_path)
			if local_action is ToonAttack:
				action = local_action.duplicate(true)
		action.user = Util.get_player()
		action.targets.clear()
		for target_index: int in entry.get("targets", []):
			if target_index >= 0 and target_index < manager.cogs.size() and is_instance_valid(manager.cogs[target_index]):
				action.targets.append(manager.cogs[target_index])
		var main_index: int = entry.get("main_target", -1)
		if main_index >= 0 and main_index < manager.cogs.size():
			action.main_target = manager.cogs[main_index]
		rebuilt.append(action)
	return rebuilt

@rpc("any_peer", "call_remote", "reliable")
func _rpc_submit_battle_turn(battle_key: String, encoded: Array) -> void:
	if not is_host:
		return
	var sender_id := multiplayer.get_remote_sender_id()
	if not multiplayer.get_peers().has(sender_id):
		return
	var base_key := battle_key.substr(0, battle_key.rfind(":"))
	if peer_states.get(sender_id, {}).get("battle_id", "") != base_key:
		return
	if not pending_battle_turns.has(battle_key): pending_battle_turns[battle_key] = {}
	pending_battle_turns[battle_key][sender_id] = encoded
	_try_resolve_battle_turn(battle_key)

func _try_resolve_battle_turn(battle_key: String, timed_out := false) -> void:
	if not is_host or completed_battle_turns.has(battle_key): return
	var expected: Array[int] = []
	var base_key := battle_key.substr(0, battle_key.rfind(":"))
	for peer_id in multiplayer.get_peers():
		if peer_states.get(peer_id, {}).get("battle_id", "") == base_key:
			expected.append(peer_id)
	if peer_states.get(1, {}).get("battle_id", "") == base_key:
		expected.append(1)
	if expected.is_empty():
		return
	var submissions: Dictionary = pending_battle_turns.get(battle_key, {})
	for peer_id in expected:
		if not submissions.has(peer_id) and not timed_out:
			return
	completed_battle_turns[battle_key] = submissions.duplicate(true)
	for peer_id in expected:
		if peer_id != 1:
			rpc_id(peer_id, "_rpc_battle_turn_resolved", battle_key, completed_battle_turns[battle_key])

@rpc("authority", "call_remote", "reliable")
func _rpc_battle_turn_resolved(battle_key: String, submissions: Dictionary) -> void:
	completed_battle_turns[battle_key] = submissions

func _cleanup_battle_turn(battle_key: String) -> void:
	pending_battle_turns.erase(battle_key)
	completed_battle_turns.erase(battle_key)

func _pack_dna(dna: ToonDNA) -> Dictionary:
	if not dna:
		return {}
	var packed := {
		"body_type": dna.body_type, "leg_type": dna.leg_type, "species": dna.species,
		"head_index": dna.head_index, "eyelashes": dna.eyelashes, "skirt": dna.skirt,
		"head_color": dna.head_color.to_html(true), "torso_color": dna.torso_color.to_html(true),
		"leg_color": dna.leg_color.to_html(true), "shirt": "", "sleeves": "", "bottoms": "",
		"shirt_color": Color.WHITE.to_html(true), "sleeve_color": Color.WHITE.to_html(true), "bottoms_color": Color.WHITE.to_html(true)
	}
	if dna.shirt:
		packed.shirt = dna.shirt.shirt_texture.resource_path if dna.shirt.shirt_texture else ""
		packed.sleeves = dna.shirt.sleeve_texture.resource_path if dna.shirt.sleeve_texture else ""
		packed.shirt_color = dna.shirt.base_color.to_html(true)
		packed.sleeve_color = dna.shirt.sleeve_color.to_html(true)
	if dna.bottoms:
		packed.bottoms = dna.bottoms.texture.resource_path if dna.bottoms.texture else ""
		packed.bottoms_color = dna.bottoms.base_color.to_html(true)
	return packed

func _unpack_dna(packed: Dictionary) -> ToonDNA:
	var dna := ToonDNA.new()
	if packed.is_empty():
		return dna
	dna.body_type = int(packed.get("body_type", 0)) as ToonDNA.BodyType
	dna.leg_type = int(packed.get("leg_type", 0)) as ToonDNA.BodyType
	dna.species = int(packed.get("species", 2)) as ToonDNA.ToonSpecies
	dna.head_index = int(packed.get("head_index", 0))
	dna.eyelashes = bool(packed.get("eyelashes", true))
	dna.skirt = bool(packed.get("skirt", false))
	dna.head_color = Color(packed.get("head_color", "ffffff"))
	dna.torso_color = Color(packed.get("torso_color", "ffffff"))
	dna.leg_color = Color(packed.get("leg_color", "ffffff"))
	var shirt := ToonShirt.new()
	var shirt_path: String = packed.get("shirt", "")
	var sleeve_path: String = packed.get("sleeves", "")
	if ResourceLoader.exists(shirt_path): shirt.shirt_texture = load(shirt_path)
	if ResourceLoader.exists(sleeve_path): shirt.sleeve_texture = load(sleeve_path)
	shirt.base_color = Color(packed.get("shirt_color", "ffffff"))
	shirt.sleeve_color = Color(packed.get("sleeve_color", "ffffff"))
	dna.shirt = shirt
	var bottoms := ToonBottoms.new()
	var bottoms_path: String = packed.get("bottoms", "")
	if ResourceLoader.exists(bottoms_path): bottoms.texture = load(bottoms_path)
	bottoms.base_color = Color(packed.get("bottoms_color", "ffffff"))
	dna.bottoms = bottoms
	return dna

func _send_state(peer_id: int, player_id: int, state: Dictionary) -> void:
	if peer_id != player_id:
		rpc_id(peer_id, "_rpc_receive_state", player_id, state)

@rpc("any_peer", "call_remote", "reliable")
func _rpc_receive_state(player_id: int, state: Dictionary) -> void:
	var sender_id := multiplayer.get_remote_sender_id()
	if is_host:
		if sender_id != player_id or player_id == 1:
			return
		var previous_state: Dictionary = peer_states.get(player_id, {})
		var previous_items: Array = previous_state.get("items", [])
		peer_states[player_id] = state
		_spawn_or_update_avatar(player_id, state)
		for item_path: String in state.get("items", []):
			if not item_path in previous_items and bool(state.get("share_items", false)):
				_share_item_from_peer(player_id, item_path)
		for peer_id in multiplayer.get_peers():
			if peer_id != sender_id:
				_send_state(peer_id, player_id, state)
		if not bool(previous_state.get("share_items", false)) and bool(state.get("share_items", false)):
			_sync_inventory_with_peer(player_id)
	else:
		if sender_id != 1 or player_id == multiplayer.get_unique_id():
			return
		var previous_state: Dictionary = peer_states.get(player_id, {})
		peer_states[player_id] = state
		_spawn_or_update_avatar(player_id, state)
		if not bool(previous_state.get("share_items", false)) and bool(state.get("share_items", false)):
			_share_inventory_with(player_id)
	s_player_joined.emit(player_id)

@rpc("any_peer", "call_remote", "reliable")
func _rpc_request_session() -> void:
	if not is_host:
		return
	var sender_id := multiplayer.get_remote_sender_id()
	if not multiplayer.get_peers().has(sender_id):
		return
	for player_id in peer_states:
		_send_state(sender_id, player_id, peer_states[player_id])
	if is_instance_valid(_local_player):
		_send_state(sender_id, 1, _make_local_state())
	if network_run_seed >= 0:
		rpc_id(sender_id, "_rpc_start_run", network_run_seed, RNG._str_seed, RNG.is_custom_seed)
	rpc_id(sender_id, "_rpc_session_ready")

@rpc("authority", "call_remote", "reliable")
func _rpc_session_ready() -> void:
	if multiplayer.is_server():
		return
	_session_handshake_pending = false
	_join_timeout_remaining = 0.0
	s_status_changed.emit("Connected to host (%d/%d)." % [player_count, MAX_PLAYERS])

@rpc("authority", "call_remote", "reliable")
func _rpc_start_run(seed: int, seed_text: String, custom_seed: bool) -> void:
	if multiplayer.is_server() or _started_linked_run:
		return
	network_run_seed = seed
	if is_instance_valid(Util.get_player()):
		return
	RNG.reset()
	RNG.set_seed(seed)
	RNG._str_seed = seed_text
	RNG.is_custom_seed = custom_seed
	_pending_linked_run = true
	if is_instance_valid(_title_screen) and _title_screen.has_method("start_linked_run"):
		_pending_linked_run = false
		_started_linked_run = true
		_title_screen.start_linked_run(seed, seed_text, custom_seed)

@rpc("authority", "call_remote", "reliable")
func _rpc_set_run_seed(seed: int, seed_text: String, custom_seed: bool) -> void:
	if multiplayer.is_server():
		return
	network_run_seed = seed
	RNG.reset()
	RNG.set_seed(seed)
	RNG._str_seed = seed_text
	RNG.is_custom_seed = custom_seed

func broadcast_run_seed(seed: int, seed_text: String, custom_seed: bool) -> void:
	if not is_host:
		return
	network_run_seed = seed
	if multiplayer.get_peers().is_empty():
		return
	rpc("_rpc_start_run", seed, seed_text, custom_seed)

func _on_item_applied(item: Item) -> void:
	if _syncing_received_item or not SaveFileService.settings_file.multiplayer_item_sync or item.resource_path.is_empty():
		return
	if _local_share_paths.has(item.resource_path):
		return
	_local_share_paths.append(item.resource_path)
	if not is_connected_to_session:
		return
	if is_host:
		_broadcast_shared_item(item.resource_path, 1)
	else:
		rpc_id(1, "_rpc_share_item", item.resource_path)

@rpc("any_peer", "call_remote", "reliable")
func _rpc_share_item(item_path: String) -> void:
	if not is_host or not _valid_item_path(item_path):
		return
	var sender_id := multiplayer.get_remote_sender_id()
	if not peer_states.has(sender_id) or not bool(peer_states[sender_id].get("share_items", false)):
		return
	_share_item_from_peer(sender_id, item_path)

func _share_item_from_peer(sender_id: int, item_path: String) -> void:
	if not _valid_item_path(item_path):
		return
	for peer_id in multiplayer.get_peers():
		if peer_id != sender_id and _can_share_with(sender_id, peer_id):
			rpc_id(peer_id, "_rpc_receive_shared_item", item_path)
	if sender_id != 1 and _can_share_with(sender_id, 1):
		_apply_shared_inventory([item_path])

func _broadcast_shared_item(item_path: String, sender_id: int) -> void:
	for peer_id in multiplayer.get_peers():
		if peer_id != sender_id and _can_share_with(sender_id, peer_id):
			rpc_id(peer_id, "_rpc_receive_shared_item", item_path)

func _valid_item_path(item_path: String) -> bool:
	return item_path.begins_with("res://objects/items/") and ResourceLoader.exists(item_path) and load(item_path) is Item

func _can_share_with(sender_id: int, receiver_id: int) -> bool:
	var local_id := multiplayer.get_unique_id() if multiplayer.multiplayer_peer else 1
	if (sender_id == local_id or receiver_id == local_id) and not SaveFileService.settings_file.multiplayer_item_sync:
		return false
	return bool(peer_states.get(sender_id, {}).get("share_items", false)) and bool(peer_states.get(receiver_id, {}).get("share_items", false))

func _sync_inventory_with_peer(peer_id: int) -> void:
	for other_id in peer_states:
		if other_id != peer_id and _can_share_with(peer_id, other_id):
			_share_inventory_between(peer_id, other_id)

func _share_inventory_between(first_id: int, second_id: int) -> void:
	if first_id == second_id or not peer_states.has(first_id) or not peer_states.has(second_id) or not _can_share_with(first_id, second_id):
		return
	var first_paths: Array = _local_item_paths() if first_id == 1 else peer_states[first_id].get("items", [])
	var second_paths: Array = _local_item_paths() if second_id == 1 else peer_states[second_id].get("items", [])
	_send_inventory(second_id, first_paths)
	_send_inventory(first_id, second_paths)

func _share_inventory_with(peer_id: int) -> void:
	if not _can_share_with(multiplayer.get_unique_id(), peer_id):
		return
	if is_host:
		_share_inventory_between(1, peer_id)
	else:
		rpc_id(1, "_rpc_request_inventory_sync", peer_id)

func _local_item_paths() -> Array[String]:
	var paths: Array[String] = []
	if is_instance_valid(_local_player):
		for item: Item in _local_player.stats.items:
			if not item.resource_path.is_empty(): paths.append(item.resource_path)
	return paths

func _send_inventory(peer_id: int, paths: Array) -> void:
	if peer_id == multiplayer.get_unique_id():
		_apply_shared_inventory(paths)
	else:
		rpc_id(peer_id, "_rpc_receive_inventory", paths)

@rpc("authority", "call_remote", "reliable")
func _rpc_receive_inventory(paths: Array) -> void:
	if not SaveFileService.settings_file.multiplayer_item_sync:
		return
	if not is_host:
		_apply_shared_inventory(paths)
		return
	var sender_id := multiplayer.get_remote_sender_id()
	if not multiplayer.get_peers().has(sender_id) or not bool(peer_states.get(sender_id, {}).get("share_items", false)):
		return
	for peer_id in multiplayer.get_peers():
		if peer_id != sender_id and _can_share_with(sender_id, peer_id):
			_send_inventory(peer_id, paths)
	if _can_share_with(sender_id, 1):
		_apply_shared_inventory(paths)

@rpc("any_peer", "call_remote", "reliable")
func _rpc_request_inventory_sync(target_peer_id: int) -> void:
	if not is_host:
		return
	var sender_id := multiplayer.get_remote_sender_id()
	if not multiplayer.get_peers().has(sender_id) or not peer_states.has(target_peer_id) or not _can_share_with(sender_id, target_peer_id):
		return
	var sender_paths: Array = peer_states.get(sender_id, {}).get("items", [])
	var target_paths: Array = _local_item_paths() if target_peer_id == 1 else peer_states.get(target_peer_id, {}).get("items", [])
	rpc_id(sender_id, "_rpc_receive_inventory", target_paths)
	if target_peer_id != 1:
		rpc_id(target_peer_id, "_rpc_receive_inventory", sender_paths)

@rpc("authority", "call_remote", "reliable")
func _rpc_receive_shared_item(item_path: String) -> void:
	if not SaveFileService.settings_file.multiplayer_item_sync or not _valid_item_path(item_path):
		return
	var player_node := Util.get_player()
	if not is_instance_valid(player_node):
		return
	var item: Item = load(item_path)
	if player_node.stats.has_item(item.item_name):
		return
	_syncing_received_item = true
	item.duplicate(true).apply_item(player_node)
	_syncing_received_item = false

func _apply_shared_inventory(paths: Array) -> void:
	var player_node := Util.get_player()
	if not is_instance_valid(player_node): return
	_syncing_received_item = true
	for item_path: String in paths:
		if not _valid_item_path(item_path): continue
		var item: Item = load(item_path)
		if not player_node.stats.has_item(item.item_name):
			item.duplicate(true).apply_item(player_node)
	_syncing_received_item = false

func _spawn_or_update_avatar(player_id: int, state: Dictionary) -> void:
	if player_id == multiplayer.get_unique_id() or player_id == 1 and is_host:
		return
	var avatar: Node3D = remote_avatars.get(player_id)
	if not is_instance_valid(avatar):
		avatar = Node3D.new()
		avatar.name = "RemoteToon_%d" % player_id
		var toon: Toon = load(TOON_SCENE).instantiate()
		toon.name = "Toon"
		toon.toon_dna = _unpack_dna(state.get("dna", {}))
		avatar.add_child(toon)
		SceneLoader.add_persistent_node(avatar)
		toon.construct_toon(toon.toon_dna)
		remote_avatars[player_id] = avatar
		avatar.set_meta("toon", toon)
		avatar.set_meta("display_name", state.get("name", "Player"))
	avatar.global_position = state.get("position", Vector3.ZERO)
	avatar.rotation.y = float(state.get("rotation", 0.0))

func _on_peer_connected(peer_id: int) -> void:
	if not is_host:
		return
	if player_count > MAX_PLAYERS:
		multiplayer.multiplayer_peer.disconnect_peer(peer_id)
		return
	peer_states[1] = _make_local_state()
	if is_instance_valid(_local_player):
		_send_state(peer_id, 1, peer_states[1])
	for existing_id in peer_states:
		if existing_id != 1 and existing_id != peer_id:
			_send_state(peer_id, existing_id, peer_states[existing_id])
	s_status_changed.emit("Player connected (%d/%d)." % [player_count, MAX_PLAYERS])

func _on_peer_disconnected(peer_id: int) -> void:
	peer_states.erase(peer_id)
	if battle_players.has(peer_id):
		if is_instance_valid(battle_players[peer_id]): battle_players[peer_id].queue_free()
		battle_players.erase(peer_id)
	if remote_avatars.has(peer_id):
		remote_avatars[peer_id].queue_free()
		remote_avatars.erase(peer_id)
	s_player_left.emit(peer_id)
	s_status_changed.emit("Player disconnected (%d/%d)." % [player_count, MAX_PLAYERS])

func _on_connected_to_server() -> void:
	s_status_changed.emit("Connected. Syncing session…")
	s_session_changed.emit(true)
	rpc_id(1, "_rpc_request_session")
	if is_instance_valid(_local_player):
		rpc_id(1, "_rpc_receive_state", multiplayer.get_unique_id(), _make_local_state())

func _on_connection_failed() -> void:
	disconnect_session()
	s_status_changed.emit("Connection failed. Check the address and port.")

func _on_server_disconnected() -> void:
	disconnect_session()
	s_status_changed.emit("Host disconnected.")
