class_name MainScene
extends Node2D

const PreBattleLoadingOverlayScript = preload("res://scripts/UI/PreBattleLoadingOverlay.gd")
const PreBattleBriefingModalScript = preload("res://scripts/UI/PreBattleBriefingModal.gd")

## Main scene orchestrator for Infernal Affairs - Tahap 3 (Expanded 44x46 Layout).
## Manages 2-map 3-zone world, NPC entities (Minion, Guard, Boss), encounter flow,
## player state progression, active A*/UCS search logic & live visualizations.

@onready var grid_manager: GridManager          = $GridManager
@onready var arena_map: ArenaMap                = $ArenaMap
@onready var frontier_visualizer: FrontierVisualizer = $FrontierVisualizer
@onready var path_dot_visualizer: PathDotVisualizer  = $PathDotVisualizer
@onready var player: PlayerEntity               = $Player
@onready var demon: DemonEntity                 = $Demon
@onready var camera: Camera2D                   = $Camera2D
@onready var info_label: Label                  = $CanvasLayer/InfoPanel/VBox/InfoLabel
@onready var algo_label: Label                  = $CanvasLayer/InfoPanel/VBox/AlgoLabel

var current_algorithm: String = "astar"
var is_game_over: bool = false
var is_in_battle: bool = false

# Battle system (Tahap 2 & Tahap 3 integrated)
var battle_manager: BattleManager
var battle_hud: BattleHUD

# --- Tahap 3: CSP Solver & Configuration ---
var csp_solver: CSPSolver = CSPSolver.new()
var csp_result: Dictionary = {}

# --- Tahap 3: NPC Entities ---
var minion_scene: PackedScene = preload("res://scenes/Minion.tscn")
var guard_scene: PackedScene  = preload("res://scenes/Guard.tscn")
var spawned_minions: Array[MinionEntity] = []
var guard_entity: GuardEntity = null
const MINION_COUNT: int = 5

# --- Tahap 3: Map Props (Gate, Throne, Warning Sign, CSP Seal) ---
var gate_sprite: Sprite2D = null
var gate_seal_sprite: Sprite2D = null
var gate_seal_label: Label = null
var gate_closed_tex: Texture2D
var gate_open_tex: Texture2D
var warning_sign_sprite: Sprite2D = null
var throne_sprite: Sprite2D = null
var pre_battle_briefing_modal: PreBattleBriefingModal = null

# --- Tahap 3: Audio ---
var sfx_level_up: AudioStream
var sfx_encounter_alert: AudioStream
var sfx_gate_unlock: AudioStream
var bgm_boss_chamber: AudioStream
var audio_player: AudioStreamPlayer
var bgm_player: AudioStreamPlayer
var boss_bgm_playing: bool = false

# --- Tahap 3: Debug HUD ---
var debug_panel: PanelContainer
var debug_label: RichTextLabel
var debug_visible: bool = true

# --- Tahap 3: Player Stats HUD (Bottom Left) ---
var player_hud_panel: PanelContainer
var hud_avatar_rect: TextureRect
var hud_level_badge: Label
var hud_hp_bar: ProgressBar
var hud_hp_label: Label
var hud_exp_bar: ProgressBar
var hud_exp_label: Label
var hud_stats_label: Label
var hud_key_badge: Label
var hud_key_icon: TextureRect
var hud_gate_badge: Label
var hud_cheat_btn: Button
var hud_auto_btn: Button
var cheat_auto_level_enabled: bool = false

# --- Tahap 3: Gate Scouting Modal ---
var gate_scout_modal: PanelContainer = null
var scout_cooldown: float = 0.0

# --- Tahap 3: Roaming Pause & Concept Presentation ---
var is_game_paused: bool = false
var pause_modal: Control = null
var hud_pause_btn: Button

# --- Tahap 3: Floating Alert ---
var floating_label: Label = null

# --- Tahap 3: Encounter Cooldowns ---
var encounter_cooldown: float = 0.0
const ENCOUNTER_COOLDOWN_TIME: float = 1.2

# --- Tahap 3: Key Grid Positions ---
var gate_grid_pos: Vector2i = Vector2i(GridManager.CENTER_X, GridManager.GATE_Y)
var guard_grid_pos: Vector2i = Vector2i(GridManager.CENTER_X, GridManager.COURTYARD_Y)
var throne_grid_pos: Vector2i = Vector2i(GridManager.CENTER_X, GridManager.THRONE_Y)
var boss_grid_pos: Vector2i = Vector2i(GridManager.CENTER_X, GridManager.BOSS_Y)

func _ready() -> void:
	randomize()
	# Load audio
	sfx_level_up = load("res://assets/audio/sfx_level_up.wav")
	sfx_encounter_alert = load("res://assets/audio/sfx_encounter_alert.wav")
	sfx_gate_unlock = load("res://assets/audio/sfx_gate_unlock.wav")
	bgm_boss_chamber = load("res://assets/audio/bgm_boss_chamber.ogg")
	gate_closed_tex = load("res://assets/sprites/map/obstacles/gate_hell_closed.png")
	gate_open_tex = load("res://assets/sprites/map/obstacles/gate_hell_open.png")

	# Audio players
	audio_player = AudioStreamPlayer.new()
	audio_player.name = "SFXPlayer"
	add_child(audio_player)

	bgm_player = AudioStreamPlayer.new()
	bgm_player.name = "BGMPlayer"
	bgm_player.volume_db = -6.0
	add_child(bgm_player)

	# Connect Grid & Player signals
	grid_manager.grid_updated.connect(_on_grid_updated)
	player.moved.connect(_on_player_moved_tahap3)

	# Process modes for pause handling (Main stays active to manage UI & inputs)
	process_mode = Node.PROCESS_MODE_ALWAYS
	if player: player.process_mode = Node.PROCESS_MODE_PAUSABLE
	if demon: demon.process_mode = Node.PROCESS_MODE_PAUSABLE
	if has_node("ArenaMap"): $ArenaMap.process_mode = Node.PROCESS_MODE_PAUSABLE
	if has_node("FrontierVisualizer"): $FrontierVisualizer.process_mode = Node.PROCESS_MODE_PAUSABLE
	if has_node("PathDotVisualizer"): $PathDotVisualizer.process_mode = Node.PROCESS_MODE_PAUSABLE
	if has_node("CanvasLayer"): $CanvasLayer.process_mode = Node.PROCESS_MODE_ALWAYS

	# Connect Demon Boss Pathfinding & Encounter signals
	demon.path_updated.connect(_on_demon_path_updated)
	demon.caught_player.connect(_on_demon_caught_player)

	# GameState signals
	GameState.level_changed.connect(_on_level_changed)
	GameState.hp_changed.connect(func(_hp): _update_player_stats_hud())
	GameState.exp_changed.connect(func(_exp): _update_player_stats_hud())
	GameState.gate_unlocked.connect(_on_gate_unlocked)
	GameState.key_obtained.connect(_on_key_obtained)

	# Create BattleManager node
	battle_manager = BattleManager.new()
	battle_manager.name = "BattleManager"
	add_child(battle_manager)
	battle_manager.battle_started.connect(_on_battle_started)
	battle_manager.battle_ended.connect(_on_battle_ended)

	# Build Player Stats HUD (Bottom Left)
	_build_player_stats_hud()

	# Build debug HUD (Bottom Right, F3)
	_build_debug_hud()

	# Connect window resize to dynamically maintain HUD bottom anchoring
	if get_viewport():
		get_viewport().size_changed.connect(_reposition_hud_panels)
	_reposition_hud_panels()

	start_new_game()

func start_new_game() -> void:
	is_game_over = false
	is_in_battle = false
	is_game_paused = false
	get_tree().paused = false
	boss_bgm_playing = false
	encounter_cooldown = 0.0

	# Cleanup modals if open
	if is_instance_valid(pause_modal):
		pause_modal.queue_free()
		pause_modal = null
	if is_instance_valid(gate_scout_modal):
		gate_scout_modal.queue_free()
		gate_scout_modal = null
	if is_instance_valid(pre_battle_briefing_modal):
		pre_battle_briefing_modal.queue_free()
		pre_battle_briefing_modal = null

	# Stop BGM
	if bgm_player:
		bgm_player.stop()

	# Reset GameState
	GameState.reset_state()

	# Cleanup
	if is_instance_valid(battle_hud):
		battle_hud.queue_free()
		battle_hud = null
	_cleanup_npcs()
	_cleanup_map_props()

	# Solve CSP for Castle Defense Assignment (Triplets <X, D, C> with MRV, LCV, AC-3)
	csp_result = csp_solver.solve(true, true, true, true)
	GameState.gate_req_level = csp_result.get("gate_req", 2)
	if is_instance_valid(guard_entity):
		guard_entity.set_guard_config(csp_result.get("guard_type", "Infernal Knight"), csp_result.get("guard_strategy", "Aggressive"), csp_result.get("gate_seal", "Seal of Flame"))

	# Generate expanded 2-map 3-zone layout
	grid_manager.generate_new_map()

	var ts: float = float(grid_manager.tile_size)
	var center_x_world: float = (GridManager.CENTER_X + 1.0) * ts

	# Place player in Map 1 (Wilderness)
	var p_pos = grid_manager.get_player_start_pos()
	player.set_grid_position(p_pos)
	player.position.x = center_x_world
	player.is_active = true

	# Place Boss (Demon) in Map 2 (Castle) - ACTIVATE AI
	boss_grid_pos = grid_manager.get_demon_start_pos()
	demon.grid_manager = grid_manager
	demon.set_grid_position(boss_grid_pos)
	demon.position.x = center_x_world
	demon.is_active = true
	demon.modulate.a = 1.0
	demon.set_algorithm(current_algorithm)
	demon.set_boss_config(csp_result.get("boss_weapon", "Flame Scythe"), csp_result.get("boss_strategy", "Tactical"))

	# Spawn Minions with Player reference and active algorithm
	_spawn_minions()

	# Spawn Guard at the gate courtyard (Zone 2)
	_spawn_guard()

	# Place map props (Gate, Warning Sign, Throne)
	_place_map_props()

	# Camera limits & setup
	camera.position = player.position
	camera.limit_left   = 0
	camera.limit_top    = 0
	camera.limit_right  = grid_manager.width  * grid_manager.tile_size
	camera.limit_bottom = grid_manager.height * grid_manager.tile_size

	_update_algo_label()
	_update_player_stats_hud()
	_update_debug_hud()
	info_label.text = "Infernal Affairs - Tahap 3  |  [L] Cheat Lv-Up  |  [K] Auto-Lv  |  [Tab] A*/UCS  |  [F3] Debug  |  [R] Reset"

func _on_grid_updated() -> void:
	arena_map.build_map(grid_manager)

# ---------------------------------------------------------------
# NPC SPAWNING
# ---------------------------------------------------------------
func _spawn_minions() -> void:
	for i in range(MINION_COUNT):
		var minion: MinionEntity = minion_scene.instantiate() as MinionEntity
		minion.name = "Minion_%d" % i
		minion.process_mode = Node.PROCESS_MODE_PAUSABLE
		add_child(minion)

		var pos = grid_manager.get_random_wilderness_pos()
		# Initialize with GridManager, spawn position, and Player reference for chase AI!
		minion.initialize(grid_manager, pos, player)
		minion.set_algorithm(current_algorithm)
		spawned_minions.append(minion)

func _spawn_guard() -> void:
	guard_entity = guard_scene.instantiate() as GuardEntity
	guard_entity.name = "Guard"
	guard_entity.process_mode = Node.PROCESS_MODE_PAUSABLE
	add_child(guard_entity)

	var ts: float = float(grid_manager.tile_size)
	guard_grid_pos = Vector2i(GridManager.CENTER_X, GridManager.COURTYARD_Y)
	guard_entity.initialize(grid_manager, guard_grid_pos)
	guard_entity.set_guard_config(csp_result.get("guard_type", "Infernal Knight"), csp_result.get("guard_strategy", "Aggressive"), csp_result.get("gate_seal", "Seal of Flame"))
	guard_entity.position.x = (GridManager.CENTER_X + 1.0) * ts

func _cleanup_npcs() -> void:
	for m in spawned_minions:
		if is_instance_valid(m):
			m.queue_free()
	spawned_minions.clear()
	if is_instance_valid(guard_entity):
		guard_entity.queue_free()
		guard_entity = null

func _cleanup_map_props() -> void:
	if is_instance_valid(gate_sprite):
		gate_sprite.queue_free()
		gate_sprite = null
	if is_instance_valid(gate_seal_sprite):
		gate_seal_sprite.queue_free()
		gate_seal_sprite = null
	if is_instance_valid(gate_seal_label):
		gate_seal_label.queue_free()
		gate_seal_label = null
	if is_instance_valid(warning_sign_sprite):
		warning_sign_sprite.queue_free()
		warning_sign_sprite = null
	if is_instance_valid(throne_sprite):
		throne_sprite.queue_free()
		throne_sprite = null

# ---------------------------------------------------------------
# MAP PROPS (GATE, WARNING SIGN, THRONE)
# ---------------------------------------------------------------
func _place_map_props() -> void:
	var ts: float = float(grid_manager.tile_size)
	var center_x_world: float = (GridManager.CENTER_X + 1.0) * ts

	# 1. Giant Gate of Hell
	gate_grid_pos = Vector2i(GridManager.CENTER_X, GridManager.GATE_Y)
	gate_sprite = Sprite2D.new()
	gate_sprite.texture = gate_closed_tex
	gate_sprite.position = Vector2(center_x_world, (GridManager.GATE_Y - 0.2) * ts)
	gate_sprite.scale = Vector2(0.30, 0.30)
	gate_sprite.z_index = int((GridManager.GATE_Y + 1.0) * ts)
	add_child(gate_sprite)

	# 1b. Gate Magical Seal (CSP Relational Visual from seals_gate_sheet.png)
	var seal_sheet = load("res://assets/sprites/map/obstacles/seals_gate_sheet.png")
	if seal_sheet and not GameState.gate_is_open:
		var seal_name: String = csp_result.get("gate_seal", "Seal of Flame")
		var col_idx: int = 0
		var seal_glow: Color = Color(1.0, 0.45, 0.15, 0.95)
		if "shadow" in seal_name.to_lower():
			col_idx = 1
			seal_glow = Color(0.75, 0.2, 1.0, 0.95)
		elif "blood" in seal_name.to_lower():
			col_idx = 2
			seal_glow = Color(1.0, 0.15, 0.25, 0.95)

		var frame_w = 413.0 / 3.0
		var atlas = AtlasTexture.new()
		atlas.atlas = seal_sheet
		atlas.region = Rect2(col_idx * frame_w, 0, frame_w, 138)

		gate_seal_sprite = Sprite2D.new()
		gate_seal_sprite.texture = atlas
		gate_seal_sprite.position = Vector2(center_x_world, (GridManager.GATE_Y - 0.25) * ts)
		gate_seal_sprite.scale = Vector2(0.32, 0.32)
		gate_seal_sprite.z_index = int((GridManager.GATE_Y + 1.0) * ts) + 2
		gate_seal_sprite.modulate = seal_glow
		add_child(gate_seal_sprite)

		gate_seal_label = Label.new()
		gate_seal_label.text = "✦ %s ✦" % seal_name.to_upper()
		gate_seal_label.add_theme_font_size_override("font_size", 9)
		gate_seal_label.add_theme_color_override("font_color", seal_glow)
		gate_seal_label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.95))
		gate_seal_label.add_theme_constant_override("shadow_offset_x", 1)
		gate_seal_label.add_theme_constant_override("shadow_offset_y", 1)
		gate_seal_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		gate_seal_label.position = Vector2(center_x_world - 80, (GridManager.GATE_Y - 1.35) * ts)
		gate_seal_label.size = Vector2(160, 20)
		gate_seal_label.z_index = gate_seal_sprite.z_index + 1
		add_child(gate_seal_label)

	# 2. Gate Warning Sign
	var warn_tex = load("res://assets/sprites/map/obstacles/gate_warning_sign.png")
	if warn_tex:
		warning_sign_sprite = Sprite2D.new()
		warning_sign_sprite.texture = warn_tex
		warning_sign_sprite.position = Vector2((GridManager.CENTER_X - 2.5) * ts, (GridManager.COURTYARD_Y + 0.4) * ts)
		warning_sign_sprite.scale = Vector2(0.20, 0.20)
		warning_sign_sprite.z_index = int((GridManager.COURTYARD_Y + 1.0) * ts)
		add_child(warning_sign_sprite)

	# 3. Boss Throne (Centered on Royal Carpet)
	throne_grid_pos = Vector2i(GridManager.CENTER_X, GridManager.THRONE_Y)
	var throne_tex = load("res://assets/sprites/map/obstacles/throne_boss.png")
	if throne_tex:
		throne_sprite = Sprite2D.new()
		throne_sprite.texture = throne_tex
		throne_sprite.position = Vector2(center_x_world, 2.8 * ts)
		throne_sprite.scale = Vector2(0.38, 0.38)
		throne_sprite.z_index = int((GridManager.THRONE_Y + 2.0) * ts)
		add_child(throne_sprite)

# ---------------------------------------------------------------
# DEMON BOSS AI PATH & ENCOUNTER HANDLERS
# ---------------------------------------------------------------
func _on_demon_path_updated(result: Dictionary) -> void:
	var path = result.get("path", [])
	if path.size() > 1:
		var world_pts: Array[Vector2] = []
		for p in path:
			world_pts.append(grid_manager.grid_to_world(p))
		path_dot_visualizer.update_path(world_pts)
	else:
		path_dot_visualizer.clear_path()

	# Show explored search frontier
	var explored = result.get("explored", [])
	frontier_visualizer.set_explored_nodes(explored)

	# Update HUD with live AI search metrics
	var algo_name = "A* (Heuristic)" if current_algorithm == "astar" else "UCS (Uniform Cost)"
	var cost = result.get("cost", 0.0)
	var nodes = result.get("nodes_expanded", 0)
	var time_ms = result.get("execution_time_ms", 0.0)
	if not is_game_over:
		info_label.text = "AI: %s | Nodes: %d | Cost: %.0f | Time: %.2f ms | Minions: %d" % [
			algo_name, nodes, cost, time_ms, _count_alive_minions()
		]

func _on_demon_caught_player() -> void:
	if not GameState.boss_defeated and not is_game_paused:
		_trigger_encounter("boss", demon)

# ---------------------------------------------------------------
# PLAYER MOVEMENT & ENCOUNTER CHECK
# ---------------------------------------------------------------
func _on_player_moved_tahap3(new_pos: Vector2i) -> void:
	if is_in_battle or is_game_over or is_game_paused:
		return

	# Proximity check with Minions (Wilderness)
	for minion in spawned_minions:
		if is_instance_valid(minion) and not minion.is_defeated:
			if _grid_distance(new_pos, minion.grid_pos) <= 1:
				_trigger_encounter("minion", minion)
				return

	# Proximity check with Guard (Gate Courtyard)
	if is_instance_valid(guard_entity) and not guard_entity.is_defeated:
		if _grid_distance(new_pos, guard_grid_pos) <= 1:
			_trigger_encounter("guard", guard_entity)
			return

	# Warning check at locked gate & Warning Sign scouting
	if not GameState.gate_is_open:
		if new_pos.y == GridManager.COURTYARD_Y and (new_pos.x == GridManager.CENTER_X or new_pos.x == GridManager.CENTER_X + 1):
			if not GameState.can_challenge_guard():
				_show_floating_alert("Terlalu lemah! Syarat Gerbang (CSP): Minimal Level %d! (Level kamu: %d)" % [
					GameState.gate_req_level, GameState.level
				], Color(1.0, 0.35, 0.35))
		elif new_pos.y == GridManager.COURTYARD_Y and (new_pos.x == GridManager.CENTER_X - 2 or new_pos.x == GridManager.CENTER_X - 3):
			_show_gate_scouting_modal()

	# Entering Castle -> Play Boss BGM
	if GameState.gate_is_open and new_pos.y <= GridManager.CASTLE_Y_MAX and not boss_bgm_playing:
		_play_bgm(bgm_boss_chamber)
		boss_bgm_playing = true
		_show_floating_alert("Memasuki Ruang Tahta Bos Neraka!", Color(1.0, 0.45, 0.2))

	# Proximity check with Boss (Demon)
	if not GameState.boss_defeated and GameState.gate_is_open:
		if _grid_distance(new_pos, demon.grid_pos) <= 1:
			_trigger_encounter("boss", demon)
			return

func _trigger_encounter(enemy_type: String, enemy_node: Node2D) -> void:
	if encounter_cooldown > 0.0 or is_in_battle or is_game_over:
		return
	encounter_cooldown = ENCOUNTER_COOLDOWN_TIME

	_play_sfx(sfx_encounter_alert)

	match enemy_type:
		"minion":
			_handle_minion_encounter(enemy_node as MinionEntity)
		"guard":
			_handle_guard_encounter(enemy_node as GuardEntity)
		"boss":
			_handle_boss_encounter()

# ---------------------------------------------------------------
# TAHAP 3 ENCOUNTER FLOW (Turn-Based Duel + Pre-Battle Balancer)
# ---------------------------------------------------------------
func _handle_minion_encounter(minion: MinionEntity) -> void:
	var p_stats: Dictionary = GameState.get_status_summary()
	var minion_config := {
		"enemy_type": "minion",
		"enemy_name": "Hell Minion (Imp)",
		"npc_hp": 60,
		"npc_max_hp": 60,
		"npc_atk": 10,
		"npc_heavy_atk": 20,
		"npc_potions": 1,
		"npc_potion_heal": 20,
		"minimax_depth": 1,
		"player_hp": p_stats.get("hp", 100),
		"player_max_hp": p_stats.get("max_hp", 100),
		"player_potions": p_stats.get("potions", 1),
		"player_atk": p_stats.get("attack", 12),
		"player_heavy_atk": int(p_stats.get("attack", 12) * 1.8),
		"player_potion_heal": 30
	}

	_start_battle_encounter(minion_config, func(winner: String):
		if winner == "player":
			minion.on_defeated()
			var leveled_up := GameState.award_minion_exp()
			if leveled_up:
				_play_sfx(sfx_level_up)
				_show_floating_alert("LEVEL UP! Naik ke Level %d! Syarat Gerbang Terpenuhi!" % GameState.level, Color(1.0, 0.85, 0.0))
			else:
				_show_floating_alert("Minion Dikalahkan! +50 EXP (%d/100)" % GameState.exp, Color(0.3, 1.0, 0.5))
		elif winner == "retreat":
			GameState.hp = maxi(20, int(GameState.max_hp * 0.5))
			GameState.hp_changed.emit(GameState.hp)
			_show_floating_alert("Kamu mundur dari Minion untuk memulihkan diri! (HP 50%)", Color(1.0, 0.65, 0.2))
		else:
			GameState.hp = maxi(20, int(GameState.max_hp * 0.5))
			GameState.hp_changed.emit(GameState.hp)
			_show_floating_alert("Kamu dipukul mundur oleh Minion! (HP 50%)", Color(1.0, 0.35, 0.35))
	)

func _handle_guard_encounter(guard: GuardEntity) -> void:
	if not GameState.can_challenge_guard():
		_show_floating_alert("Terlalu lemah! Syarat Gerbang (CSP): Minimal Level %d! (Level kamu: %d)" % [
			GameState.gate_req_level, GameState.level
		], Color(1.0, 0.35, 0.35))
		return

	_show_pre_battle_briefing("guard", guard)

func _handle_boss_encounter() -> void:
	if GameState.boss_defeated:
		return
	if not GameState.gate_is_open:
		_show_floating_alert("Pintu Tahta Terkunci! Kalahkan Penjaga Gerbang terlebih dahulu!", Color(1.0, 0.35, 0.35))
		return

	_show_pre_battle_briefing("boss", demon)

func _show_pre_battle_briefing(type: String, enemy_node: Node2D) -> void:
	is_in_battle = true
	player.is_active = false
	if demon:
		demon.is_active = false
	if is_instance_valid(player_hud_panel):
		player_hud_panel.visible = false

	if is_instance_valid(pre_battle_briefing_modal):
		pre_battle_briefing_modal.queue_free()

	pre_battle_briefing_modal = PreBattleBriefingModalScript.new()
	var enemy_title: String
	var enemy_elem: String
	var enemy_wep: String
	var csp_extra: Dictionary = {}

	if type == "guard":
		var g_type: String = csp_result.get("guard_type", "Infernal Knight")
		enemy_title = "Hell Guard (%s)" % g_type
		enemy_elem = csp_result.get("guard_element", "Fire")
		enemy_wep = "Beban Segel: %s" % csp_result.get("gate_seal", "Seal of Flame")
		csp_extra = csp_result.duplicate()
		csp_extra["strategy"] = csp_result.get("guard_strategy", "Aggressive")
		csp_extra["strategy_desc"] = csp_result.get("guard_strategy_desc", "")
		csp_extra["eval_func"] = csp_result.get("guard_eval_func", 1)
		csp_extra["action_order"] = csp_result.get("guard_action_order", 1)
	else: # "boss"
		var b_wep: String = csp_result.get("boss_weapon", "Flame Scythe")
		enemy_title = "Demon Lord (%s)" % b_wep
		enemy_elem = csp_result.get("boss_element", "Fire")
		enemy_wep = b_wep
		csp_extra = csp_result.duplicate()
		csp_extra["strategy"] = csp_result.get("boss_strategy", "Tactical")
		csp_extra["strategy_desc"] = csp_result.get("boss_strategy_desc", "")
		csp_extra["eval_func"] = csp_result.get("boss_eval_func", 3)
		csp_extra["action_order"] = csp_result.get("boss_action_order", 0)

	pre_battle_briefing_modal.setup_briefing(type, enemy_title, enemy_elem, enemy_wep, csp_extra)

	pre_battle_briefing_modal.continue_to_battle.connect(func():
		_open_pre_battle_overlay(type, enemy_node)
	)

	pre_battle_briefing_modal.cancelled.connect(func():
		is_in_battle = false
		player.is_active = true
		if demon and not GameState.boss_defeated:
			demon.is_active = true
		if is_instance_valid(player_hud_panel):
			player_hud_panel.visible = true
			_update_player_stats_hud()
		encounter_cooldown = ENCOUNTER_COOLDOWN_TIME
	)

	add_child(pre_battle_briefing_modal)

func _open_pre_battle_overlay(type: String, _enemy_node: Node2D) -> void:
	is_in_battle = true
	player.is_active = false
	if demon:
		demon.is_active = false
	if is_instance_valid(player_hud_panel):
		player_hud_panel.visible = false

	var overlay = PreBattleLoadingOverlayScript.new()
	var enemy_title: String
	var enemy_elem: String
	var enemy_wep: String
	var csp_extra: Dictionary = {}

	if type == "guard":
		var g_type: String = csp_result.get("guard_type", "Infernal Knight")
		enemy_title = "Hell Guard (%s)" % g_type
		enemy_elem = csp_result.get("guard_element", "Fire")
		enemy_wep = "Beban Segel: %s" % csp_result.get("gate_seal", "Seal of Flame")
		csp_extra = csp_result.duplicate()
		csp_extra["strategy"] = csp_result.get("guard_strategy", "Aggressive")
		csp_extra["strategy_desc"] = csp_result.get("guard_strategy_desc", "")
		csp_extra["eval_func"] = csp_result.get("guard_eval_func", 1)
		csp_extra["action_order"] = csp_result.get("guard_action_order", 1)
	else: # "boss"
		var b_wep: String = csp_result.get("boss_weapon", "Flame Scythe")
		enemy_title = "Demon Lord (%s)" % b_wep
		enemy_elem = csp_result.get("boss_element", "Fire")
		enemy_wep = b_wep
		csp_extra = csp_result.duplicate()
		csp_extra["strategy"] = csp_result.get("boss_strategy", "Tactical")
		csp_extra["strategy_desc"] = csp_result.get("boss_strategy_desc", "")
		csp_extra["eval_func"] = csp_result.get("boss_eval_func", 3)
		csp_extra["action_order"] = csp_result.get("boss_action_order", 0)

	overlay.setup_encounter(type, enemy_title, enemy_elem, enemy_wep, GameState.get_status_summary(), csp_extra)

	overlay.proceed_to_battle.connect(func(optimized_config: Dictionary):
		_start_battle_encounter(optimized_config, func(winner: String):
			if type == "guard":
				if winner == "player":
					if is_instance_valid(guard_entity):
						guard_entity.on_defeated()
					GameState.award_guard_victory()
					_play_sfx(sfx_level_up)
					_show_floating_alert("Penjaga Dikalahkan! Castle Key Diperoleh! Naik ke Level 3! Gerbang Terbuka!", Color(1.0, 0.85, 0.0))
				elif winner == "retreat":
					GameState.hp = maxi(30, int(GameState.max_hp * 0.5))
					GameState.hp_changed.emit(GameState.hp)
					_show_floating_alert("Kamu mundur dari Penjaga Gerbang untuk mengatur ulang strategi! (HP 50%)", Color(1.0, 0.65, 0.2))
				else:
					GameState.hp = maxi(30, int(GameState.max_hp * 0.5))
					GameState.hp_changed.emit(GameState.hp)
					_show_floating_alert("Kamu dipukul mundur oleh Penjaga Gerbang! (HP 50%)", Color(1.0, 0.35, 0.35))
			elif type == "boss":
				if winner == "player":
					GameState.award_boss_victory()
					demon.is_active = false
					var tween = create_tween()
					tween.tween_property(demon, "modulate:a", 0.0, 1.0)
					path_dot_visualizer.clear_path()
					is_game_over = true
					_play_sfx(sfx_level_up)
					_show_floating_alert("BOS NERAKA DIKALAHKAN! KEMENANGAN MUTLAK!", Color(1.0, 0.85, 0.0))
					info_label.text = "VICTORY! Istana Neraka Ditaklukkan! [R] Main Ulang"
				elif winner == "retreat":
					GameState.hp = maxi(40, int(GameState.max_hp * 0.5))
					GameState.hp_changed.emit(GameState.hp)
					_show_floating_alert("Kamu mundur dari Bos Neraka untuk mengatur ulang strategi! (HP 50%)", Color(1.0, 0.65, 0.2))
				else:
					GameState.hp = maxi(40, int(GameState.max_hp * 0.5))
					GameState.hp_changed.emit(GameState.hp)
					_show_floating_alert("Kamu dipukul mundur oleh Bos Neraka! (HP 50%)", Color(1.0, 0.35, 0.35))
		)
	)

	overlay.cancelled.connect(func():
		is_in_battle = false
		player.is_active = true
		if demon and not GameState.boss_defeated:
			demon.is_active = true
		if is_instance_valid(player_hud_panel):
			player_hud_panel.visible = true
			_update_player_stats_hud()
		encounter_cooldown = 1.0
	)

	add_child(overlay)

func test_direct_battle(enemy_t: String, guard_arch: String = "") -> void:
	if is_in_battle:
		return
	var config: Dictionary = {}
	var p_stats: Dictionary = GameState.get_player_combat_stats()
	var def_cb: Callable = func(_winner: String):
		is_in_battle = false
		player.is_active = true
		if demon and not GameState.boss_defeated:
			demon.is_active = true
		if is_instance_valid(player_hud_panel):
			player_hud_panel.visible = true
			_update_player_stats_hud()
		encounter_cooldown = 1.0

	match enemy_t:
		"minion":
			config = {
				"enemy_type": "minion",
				"enemy_name": "Lesser Imp",
				"npc_hp": 60, "npc_max_hp": 60,
				"npc_atk": 12, "npc_heavy_atk": 22, "npc_def": 2,
				"npc_potions": 1, "npc_potion_heal": 20, "minimax_depth": 2,
				"player_hp": p_stats.get("hp", 100), "player_max_hp": p_stats.get("max_hp", 100),
				"player_potions": p_stats.get("potions", 1), "player_atk": p_stats.get("attack", 20),
				"player_heavy_atk": int(p_stats.get("attack", 20) * 1.8), "player_potion_heal": 30,
				"gate_seal": "", "boss_weapon": "", "enemy_strategy": "AGGRESSIVE",
				"gate_seal_effect": "", "boss_weapon_effect": "",
				"ai_eval_func": MinimaxSolver.EvalFunc.AGGRESSIVE, "ai_action_order": MinimaxSolver.ActionOrder.AGGRESSIVE
			}
		"guard":
			var g_name: String = guard_arch if guard_arch.length() > 0 else str(csp_result.get("guard_type", "Infernal Knight"))
			var seal: String = "Seal of Flame"
			var strat: String = "AGGRESSIVE"
			if "shaman" in g_name.to_lower():
				seal = "Seal of Shadow"
				strat = "DEFENSIVE"
			elif "gargoyle" in g_name.to_lower():
				seal = "Seal of Blood"
				strat = "TACTICAL"
			config = {
				"enemy_type": "guard",
				"enemy_name": "Hell Guard (%s)" % g_name,
				"npc_hp": 120, "npc_max_hp": 120,
				"npc_atk": 18, "npc_heavy_atk": 30, "npc_def": 5,
				"npc_potions": 1, "npc_potion_heal": 25, "minimax_depth": 3,
				"player_hp": p_stats.get("hp", 100), "player_max_hp": p_stats.get("max_hp", 100),
				"player_potions": p_stats.get("potions", 1), "player_atk": p_stats.get("attack", 20),
				"player_heavy_atk": int(p_stats.get("attack", 20) * 1.8), "player_potion_heal": 30,
				"gate_seal": seal, "boss_weapon": "", "enemy_strategy": strat,
				"gate_seal_effect": "Medan Segel %s Aktif" % seal, "boss_weapon_effect": "",
				"ai_eval_func": MinimaxSolver.EvalFunc.DEFENSIVE if strat == "DEFENSIVE" else MinimaxSolver.EvalFunc.WEIGHTED,
				"ai_action_order": MinimaxSolver.ActionOrder.DEFAULT
			}
		"boss":
			var b_wep: String = csp_result.get("boss_weapon", "Flame Scythe")
			config = {
				"enemy_type": "boss",
				"enemy_name": "Demon Boss (%s)" % b_wep,
				"npc_hp": 180, "npc_max_hp": 180,
				"npc_atk": 25, "npc_heavy_atk": 42, "npc_def": 6,
				"npc_potions": 2, "npc_potion_heal": 35, "minimax_depth": 3,
				"player_hp": p_stats.get("hp", 100), "player_max_hp": p_stats.get("max_hp", 100),
				"player_potions": p_stats.get("potions", 1), "player_atk": p_stats.get("attack", 20),
				"player_heavy_atk": int(p_stats.get("attack", 20) * 1.8), "player_potion_heal": 30,
				"gate_seal": "", "boss_weapon": b_wep, "enemy_strategy": "AGGRESSIVE",
				"gate_seal_effect": "", "boss_weapon_effect": "Infernal Burn Active",
				"ai_eval_func": MinimaxSolver.EvalFunc.AGGRESSIVE, "ai_action_order": MinimaxSolver.ActionOrder.AGGRESSIVE
			}
	_start_battle_encounter(config, def_cb)

func _start_battle_encounter(config: Dictionary, on_finished_cb: Callable) -> void:
	is_in_battle = true
	player.is_active = false
	if demon:
		demon.is_active = false
	if is_instance_valid(player_hud_panel):
		player_hud_panel.visible = false

	if is_instance_valid(battle_hud):
		battle_hud.queue_free()

	battle_hud = BattleHUD.new()
	battle_hud.name = "BattleHUD"
	battle_hud.init(battle_manager)

	battle_hud.restart_requested.connect(func():
		is_in_battle = false
		start_new_game()
	)

	battle_hud.battle_hud_closed.connect(func(winner: String):
		is_in_battle = false
		player.is_active = true
		if demon and not GameState.boss_defeated:
			demon.is_active = true
		if is_instance_valid(player_hud_panel):
			player_hud_panel.visible = true
			_update_player_stats_hud()
		encounter_cooldown = ENCOUNTER_COOLDOWN_TIME
		on_finished_cb.call(winner)
		_update_debug_hud()
	)

	add_child(battle_hud)
	battle_manager.start_battle_custom(config)

# ---------------------------------------------------------------
# GATE STATE CHANGES
# ---------------------------------------------------------------
func _on_gate_unlocked() -> void:
	_play_sfx(sfx_gate_unlock)
	if is_instance_valid(gate_seal_sprite):
		var stw = create_tween()
		stw.tween_property(gate_seal_sprite, "scale", Vector2(0.65, 0.65), 0.45).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		stw.parallel().tween_property(gate_seal_sprite, "modulate:a", 0.0, 0.45)
		if is_instance_valid(gate_seal_label):
			stw.parallel().tween_property(gate_seal_label, "modulate:a", 0.0, 0.35)
		stw.tween_callback(func():
			if is_instance_valid(gate_seal_sprite):
				gate_seal_sprite.queue_free()
				gate_seal_sprite = null
			if is_instance_valid(gate_seal_label):
				gate_seal_label.queue_free()
				gate_seal_label = null
		)

	if gate_sprite and gate_open_tex:
		gate_sprite.texture = gate_open_tex

	# Unblock castle front gate tiles
	var gx = GridManager.CENTER_X
	for wy in range(GridManager.WALL_Y_TOP, GridManager.GATE_Y + 1):
		for dx in [0, 1]:
			if grid_manager.in_bounds(gx + dx, wy):
				grid_manager.grid[wy][gx + dx] = GridManager.TileType.GROUND

	# Immediately recalculate demon path now that gate is open!
	if demon and demon.is_active:
		demon.recalculate_path()

	_show_floating_alert("Gerbang Istana Neraka Terbuka!", Color(0.3, 1.0, 0.6))

func _on_key_obtained() -> void:
	_show_floating_alert("Castle Key diperoleh!", Color(1.0, 0.75, 0.0))

func _on_level_changed(_new_level: int) -> void:
	_update_debug_hud()

# ---------------------------------------------------------------
# FLOATING ALERT NOTIFICATION
# ---------------------------------------------------------------
func _show_floating_alert(text: String, color: Color = Color.WHITE) -> void:
	if is_instance_valid(floating_label):
		floating_label.queue_free()

	floating_label = Label.new()
	floating_label.text = text
	floating_label.add_theme_font_size_override("font_size", 16)
	floating_label.add_theme_color_override("font_color", color)
	floating_label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.9))
	floating_label.add_theme_constant_override("shadow_offset_x", 2)
	floating_label.add_theme_constant_override("shadow_offset_y", 2)
	floating_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	floating_label.anchors_preset = Control.PRESET_CENTER_TOP
	floating_label.position = Vector2(grid_manager.width * grid_manager.tile_size * 0.5 - 250, 80)
	floating_label.size = Vector2(500, 36)
	$CanvasLayer.add_child(floating_label)

	var tween = create_tween()
	tween.tween_property(floating_label, "modulate:a", 0.0, 2.0).set_delay(1.0)
	tween.tween_callback(func():
		if is_instance_valid(floating_label):
			floating_label.queue_free()
	)

# ---------------------------------------------------------------
# DEBUG HUD (F3 to toggle - Positioned Bottom-Right)
# ---------------------------------------------------------------
func _build_debug_hud() -> void:
	debug_panel = PanelContainer.new()
	debug_panel.name = "DebugPanel"
	$CanvasLayer.add_child(debug_panel)
	debug_panel.visible = false
	debug_panel.z_index = 20

	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.05, 0.03, 0.08, 0.88)
	style.border_color = Color(0.9, 0.35, 0.1, 0.8)
	style.set_border_width_all(2)
	style.set_corner_radius_all(6)
	style.set_content_margin_all(10)
	debug_panel.add_theme_stylebox_override("panel", style)

	var vbox = VBoxContainer.new()
	vbox.name = "VBox"
	debug_panel.add_child(vbox)

	var title = Label.new()
	title.text = "Debug HUD - Tahap 3"
	title.add_theme_font_size_override("font_size", 14)
	title.add_theme_color_override("font_color", Color(1.0, 0.65, 0.15))
	vbox.add_child(title)

	debug_label = RichTextLabel.new()
	debug_label.bbcode_enabled = true
	debug_label.fit_content = true
	debug_label.scroll_active = false
	debug_label.add_theme_font_size_override("normal_font_size", 12)
	vbox.add_child(debug_label)

	var sep = HSeparator.new()
	vbox.add_child(sep)

	var btn_grid = GridContainer.new()
	btn_grid.columns = 2
	vbox.add_child(btn_grid)

	_add_debug_btn(btn_grid, "+50 EXP", func():
		GameState.exp += 50
		GameState.exp_changed.emit(GameState.exp)
		if GameState.exp >= GameState.EXP_PER_LEVEL and GameState.level < GameState.MAX_LEVEL:
			GameState._level_up()
			_play_sfx(sfx_level_up)
			_show_floating_alert("LEVEL UP! Level %d!" % GameState.level, Color(1.0, 0.85, 0.0))
		_update_debug_hud()
	)

	_add_debug_btn(btn_grid, "Unlock Gate", func():
		if not GameState.gate_is_open:
			GameState.gate_is_open = true
			GameState.has_castle_key = true
			GameState.guard_defeated = true
			_on_gate_unlocked()
			_show_floating_alert("Gate force-unlocked!", Color(0.5, 1.0, 0.5))
		_update_debug_hud()
	)

	_add_debug_btn(btn_grid, "TP -> Gate", func():
		var tp_pos = Vector2i(GridManager.CENTER_X, GridManager.COURTYARD_Y)
		player.set_grid_position(tp_pos)
		player.position.x = (GridManager.CENTER_X + 1.0) * float(grid_manager.tile_size)
		_show_floating_alert("Teleport ke Depan Gerbang", Color(0.5, 0.8, 1.0))
	)

	_add_debug_btn(btn_grid, "Re-solve CSP", func():
		csp_result = csp_solver.solve(true, true, true, true)
		GameState.gate_req_level = csp_result.get("gate_req", 2)
		if is_instance_valid(guard_entity):
			guard_entity.set_guard_config(csp_result.get("guard_type", "Infernal Knight"), csp_result.get("guard_strategy", "Aggressive"), csp_result.get("gate_seal", "Seal of Flame"))
		if is_instance_valid(demon):
			demon.set_boss_config(csp_result.get("boss_weapon", "Flame Scythe"), csp_result.get("boss_strategy", "Tactical"))
		if not GameState.gate_is_open:
			_cleanup_map_props()
			_place_map_props()
		_show_floating_alert("CSP Baru: %s [%s] | %s | %s [%s]" % [
			csp_result.get("guard_type", ""), csp_result.get("guard_strategy", ""),
			csp_result.get("gate_seal", ""),
			csp_result.get("boss_weapon", ""), csp_result.get("boss_strategy", "")
		], Color(0.2, 1.0, 0.8))
		_update_debug_hud()
	)

	# Overworld Guard & Teleport Buttons
	_add_debug_btn(btn_grid, "[TP] To Guard", func():
		if is_instance_valid(player) and is_instance_valid(guard_entity):
			player.set_grid_position(guard_grid_pos + Vector2i(0, 1))
			_show_floating_alert("Teleport ke Gerbang Istana (Hell Guard)", Color(0.3, 0.9, 1.0))
	)

	_add_debug_btn(btn_grid, "Guard: Knight", func():
		csp_result = csp_solver.solve(true, true, true, false, {"guard_type": "Infernal Knight"})
		if is_instance_valid(guard_entity): guard_entity.set_guard_config("Infernal Knight", csp_result.get("guard_strategy", "Aggressive"), csp_result.get("gate_seal", "Seal of Flame"))
		if is_instance_valid(demon): demon.set_boss_config(csp_result.get("boss_weapon", "Flame Scythe"), csp_result.get("boss_strategy", "Tactical"))
		if not GameState.gate_is_open: _cleanup_map_props(); _place_map_props()
		_show_floating_alert("Guard Diubah: Infernal Knight (Api) | Segel: %s" % csp_result.get("gate_seal", ""), Color(1.0, 0.4, 0.1))
		_update_debug_hud()
	)

	_add_debug_btn(btn_grid, "Guard: Shaman", func():
		csp_result = csp_solver.solve(true, true, true, false, {"guard_type": "Abyssal Shaman"})
		if is_instance_valid(guard_entity): guard_entity.set_guard_config("Abyssal Shaman", csp_result.get("guard_strategy", "Tactical"), csp_result.get("gate_seal", "Seal of Shadow"))
		if is_instance_valid(demon): demon.set_boss_config(csp_result.get("boss_weapon", "Blood Trident"), csp_result.get("boss_strategy", "Aggressive"))
		if not GameState.gate_is_open: _cleanup_map_props(); _place_map_props()
		_show_floating_alert("Guard Diubah: Abyssal Shaman (Void) | Segel: %s" % csp_result.get("gate_seal", ""), Color(0.8, 0.4, 1.0))
		_update_debug_hud()
	)

	_add_debug_btn(btn_grid, "Guard: Gargoyle", func():
		csp_result = csp_solver.solve(true, true, true, false, {"guard_type": "Obsidian Gargoyle"})
		if is_instance_valid(guard_entity): guard_entity.set_guard_config("Obsidian Gargoyle", csp_result.get("guard_strategy", "Defensive"), csp_result.get("gate_seal", "Seal of Blood"))
		if is_instance_valid(demon): demon.set_boss_config(csp_result.get("boss_weapon", "Flame Scythe"), csp_result.get("boss_strategy", "Tactical"))
		if not GameState.gate_is_open: _cleanup_map_props(); _place_map_props()
		_show_floating_alert("Guard Diubah: Obsidian Gargoyle (Batu) | Segel: %s" % csp_result.get("gate_seal", ""), Color(0.9, 0.2, 0.2))
		_update_debug_hud()
	)

	# Direct Battle Test Buttons (Testing All Portraits & VFX Instantly!)
	_add_debug_btn(btn_grid, "[TEST] Duel Minion", func():
		test_direct_battle("minion")
	)

	_add_debug_btn(btn_grid, "[TEST] Duel Knight", func():
		test_direct_battle("guard", "Infernal Knight")
	)

	_add_debug_btn(btn_grid, "[TEST] Duel Shaman", func():
		test_direct_battle("guard", "Abyssal Shaman")
	)

	_add_debug_btn(btn_grid, "[TEST] Duel Gargoyle", func():
		test_direct_battle("guard", "Obsidian Gargoyle")
	)

	_add_debug_btn(btn_grid, "[TEST] Duel Boss", func():
		test_direct_battle("boss")
	)

	_add_debug_btn(btn_grid, "Auto-Lv Cheat", func():
		_toggle_cheat_auto_level()
	)

func _add_debug_btn(parent: Node, text: String, callback: Callable) -> void:
	var btn = Button.new()
	btn.text = text
	btn.add_theme_font_size_override("font_size", 11)
	btn.custom_minimum_size = Vector2(140, 28)
	btn.pressed.connect(callback)
	parent.add_child(btn)

func _update_debug_hud() -> void:
	if not debug_label:
		return
	var s = GameState.get_status_summary()
	var key_str = "[color=lime]YES[/color]" if s.has_key else "[color=red]NO[/color]"
	var gate_str = "[color=lime]OPEN[/color]" if s.gate_open else "[color=red]LOCKED[/color]"
	var boss_str = "[color=lime]DEFEATED[/color]" if s.boss_defeated else "[color=yellow]ALIVE[/color]"

	debug_label.text = "[color=cyan]Level:[/color] %d  |  [color=red]HP:[/color] %d/%d\n[color=green]EXP:[/color] %d/%d  |  [color=magenta]Potions:[/color] %d\n[color=orange]Atk:[/color] %d  |  [color=cyan]Def:[/color] %d\n[color=yellow]Castle Key:[/color] %s\n[color=yellow]Gate:[/color] %s  |  [color=red]Boss:[/color] %s\n[color=gray]Minions alive: %d[/color]" % [
		s.level, s.hp, s.max_hp,
		s.exp, s.exp_needed, s.potions,
		s.attack, s.defense,
		key_str, gate_str, boss_str,
		_count_alive_minions()
	]

	var csp_g: String = "%s [%s] (%s)" % [
		csp_result.get("guard_type", "-"),
		csp_result.get("guard_strategy", "-"),
		csp_result.get("guard_element", "-")
	]
	var csp_b: String = "%s [%s] (%s)" % [
		csp_result.get("boss_weapon", "-"),
		csp_result.get("boss_strategy", "-"),
		csp_result.get("boss_element", "-")
	]
	var csp_seal: String = "%s" % csp_result.get("gate_seal", "-")
	debug_label.text += "\n[color=yellow]-- CSP Assignment (Tahap 3) --[/color]\nGuard: [color=cyan]%s[/color]\nGate Seal: [color=orange]%s[/color]\nBoss: [color=red]%s[/color]\nGate Req: [color=yellow]Lvl %d[/color] | Potions: %d (G:%d, B:%d)\n[color=gray]Checks: %d | Backtracks: %d (%0.2f ms)[/color]" % [
		csp_g, csp_seal, csp_b,
		csp_result.get("gate_req", 2), csp_result.get("castle_potions", 3),
		csp_result.get("guard_potions", 1), csp_result.get("boss_potions", 2),
		csp_result.get("consistency_checks", 0), csp_result.get("backtracks_count", 0),
		csp_result.get("time_ms", 0.0)
	]

func _count_alive_minions() -> int:
	var count := 0
	for m in spawned_minions:
		if is_instance_valid(m) and not m.is_defeated:
			count += 1
	return count

# ---------------------------------------------------------------
# AUDIO HELPERS
# ---------------------------------------------------------------
func _play_sfx(stream: AudioStream) -> void:
	if stream and audio_player:
		audio_player.stream = stream
		audio_player.play()

func _play_bgm(stream: AudioStream) -> void:
	if stream and bgm_player:
		bgm_player.stream = stream
		bgm_player.play()

# ---------------------------------------------------------------
# DISTANCE HELPER
# ---------------------------------------------------------------
func _grid_distance(a: Vector2i, b: Vector2i) -> int:
	return abs(a.x - b.x) + abs(a.y - b.y)

# ---------------------------------------------------------------
# INPUT & PROCESS
# ---------------------------------------------------------------
func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if is_in_battle:
			return

		# P key or Escape key to toggle Pause / Concept briefing
		if event.keycode == KEY_P:
			_toggle_pause_game()
			return

		if event.keycode == KEY_ESCAPE:
			if is_instance_valid(gate_scout_modal):
				gate_scout_modal.queue_free()
				gate_scout_modal = null
				return
			if is_game_paused:
				_resume_game()
				return
			else:
				_pause_game()
				return

		if event.keycode == KEY_SPACE and is_instance_valid(gate_scout_modal):
			gate_scout_modal.queue_free()
			gate_scout_modal = null
			return

		# If game is currently paused, ignore normal roaming shortcuts except restart
		if is_game_paused:
			if event.keycode == KEY_R:
				_resume_game()
				start_new_game()
			return

		match event.keycode:
			KEY_R:   start_new_game()
			KEY_TAB: _toggle_algorithm()
			KEY_1:   _set_algorithm("astar")
			KEY_2:   _set_algorithm("ucs")
			KEY_L, KEY_C:
				_cheat_level_up()
			KEY_K:
				_toggle_cheat_auto_level()
			KEY_F3:
				debug_visible = not debug_visible
				if debug_panel:
					debug_panel.visible = debug_visible

func _toggle_algorithm() -> void:
	_set_algorithm("ucs" if current_algorithm == "astar" else "astar")

func _set_algorithm(algo: String) -> void:
	current_algorithm = algo
	_update_algo_label()

	# Update Demon Boss algorithm
	if demon:
		demon.set_algorithm(algo)

	# Update all active Minions algorithms
	for m in spawned_minions:
		if is_instance_valid(m) and not m.is_defeated:
			m.set_algorithm(algo)

func _update_algo_label() -> void:
	if algo_label:
		algo_label.text = "Algoritma: A* (Heuristic)" if current_algorithm == "astar" else "Algoritma: UCS (Dijkstra)"
		algo_label.modulate = Color("#00f5d4") if current_algorithm == "astar" else Color("#ffbe0b")

func _physics_process(delta: float) -> void:
	if is_game_paused:
		return

	if encounter_cooldown > 0.0:
		encounter_cooldown = maxf(0.0, encounter_cooldown - delta)
	if scout_cooldown > 0.0:
		scout_cooldown = maxf(0.0, scout_cooldown - delta)

	# Auto-level up cheat: ensures player level is always at least gate requirement
	if cheat_auto_level_enabled and GameState.level < GameState.gate_req_level:
		_cheat_level_up()

	# Gate seal magical pulse
	if is_instance_valid(gate_seal_sprite):
		var spulse: float = 0.82 + sin(float(Time.get_ticks_msec()) / 220.0) * 0.18
		gate_seal_sprite.modulate.a = spulse

	# Camera smooth follow
	if player and camera:
		camera.position = camera.position.lerp(player.position, 0.08)

# ---------------------------------------------------------------
# PLAYER STATS HUD (BOTTOM-LEFT CORNER)
# ---------------------------------------------------------------
func _build_player_stats_hud() -> void:
	player_hud_panel = PanelContainer.new()
	player_hud_panel.name = "PlayerStatsHUD"
	$CanvasLayer.add_child(player_hud_panel)
	player_hud_panel.z_index = 15

	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.04, 0.03, 0.08, 0.92)
	style.border_color = Color(0.0, 0.85, 0.75, 0.85)
	style.set_border_width_all(2)
	style.set_corner_radius_all(8)
	style.set_content_margin_all(8)
	player_hud_panel.add_theme_stylebox_override("panel", style)

	var hbox := HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 10)
	player_hud_panel.add_child(hbox)

	# Left Column: Avatar + Level Badge
	var left_vbox := VBoxContainer.new()
	left_vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	left_vbox.add_theme_constant_override("separation", 4)
	hbox.add_child(left_vbox)

	hud_avatar_rect = TextureRect.new()
	var p_tex = load("res://assets/sprites/characters/player/player_avatar.png")
	if p_tex:
		hud_avatar_rect.texture = p_tex
	hud_avatar_rect.custom_minimum_size = Vector2(46, 46)
	hud_avatar_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	hud_avatar_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	left_vbox.add_child(hud_avatar_rect)

	hud_level_badge = Label.new()
	hud_level_badge.text = "LV. 1"
	hud_level_badge.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hud_level_badge.add_theme_font_size_override("font_size", 11)
	hud_level_badge.add_theme_color_override("font_color", Color(1.0, 0.85, 0.2))
	var badge_s := StyleBoxFlat.new()
	badge_s.bg_color = Color(0.12, 0.08, 0.2, 0.9)
	badge_s.border_color = Color(1.0, 0.8, 0.2, 0.8)
	badge_s.set_border_width_all(1)
	badge_s.set_corner_radius_all(4)
	badge_s.set_content_margin_all(2)
	hud_level_badge.add_theme_stylebox_override("panel", badge_s)
	left_vbox.add_child(hud_level_badge)

	# Right Column: Bars and Stats
	var right_vbox := VBoxContainer.new()
	right_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	right_vbox.add_theme_constant_override("separation", 3)
	hbox.add_child(right_vbox)

	# Row 1: Player Name + Cheat Buttons
	var r1 := HBoxContainer.new()
	right_vbox.add_child(r1)

	var p_name := Label.new()
	p_name.text = "LOST SOUL KNIGHT"
	p_name.add_theme_font_size_override("font_size", 11)
	p_name.add_theme_color_override("font_color", Color(0.0, 0.95, 0.85))
	p_name.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	r1.add_child(p_name)

	hud_auto_btn = Button.new()
	hud_auto_btn.text = "Auto-Lv: OFF"
	hud_auto_btn.tooltip_text = "Toggle Auto Level-Up Cheat (Shortcut: K)"
	hud_auto_btn.add_theme_font_size_override("font_size", 9)
	hud_auto_btn.custom_minimum_size = Vector2(75, 20)
	hud_auto_btn.pressed.connect(_toggle_cheat_auto_level)
	r1.add_child(hud_auto_btn)

	hud_cheat_btn = Button.new()
	hud_cheat_btn.text = "⚡ +LV [L]"
	hud_cheat_btn.tooltip_text = "Cheat Instant Level Up (Shortcut: L)"
	hud_cheat_btn.add_theme_font_size_override("font_size", 9)
	hud_cheat_btn.custom_minimum_size = Vector2(62, 20)
	var cheat_s := StyleBoxFlat.new()
	cheat_s.bg_color = Color(0.85, 0.45, 0.05, 0.95)
	cheat_s.set_corner_radius_all(4)
	hud_cheat_btn.add_theme_stylebox_override("normal", cheat_s)
	hud_cheat_btn.pressed.connect(_cheat_level_up)
	r1.add_child(hud_cheat_btn)

	hud_pause_btn = Button.new()
	hud_pause_btn.text = "⏸ Pause [P]"
	hud_pause_btn.tooltip_text = "Pause Game & Briefing Konsep AI (Shortcut: P / ESC)"
	hud_pause_btn.add_theme_font_size_override("font_size", 9)
	hud_pause_btn.custom_minimum_size = Vector2(74, 20)
	var pause_s := StyleBoxFlat.new()
	pause_s.bg_color = Color(0.18, 0.42, 0.85, 0.95)
	pause_s.set_corner_radius_all(4)
	hud_pause_btn.add_theme_stylebox_override("normal", pause_s)
	hud_pause_btn.pressed.connect(_toggle_pause_game)
	r1.add_child(hud_pause_btn)

	# Row 2: HP Bar
	var hp_box := HBoxContainer.new()
	right_vbox.add_child(hp_box)
	hud_hp_bar = ProgressBar.new()
	hud_hp_bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hud_hp_bar.custom_minimum_size = Vector2(0, 11)
	hud_hp_bar.show_percentage = false
	var hp_s := StyleBoxFlat.new()
	hp_s.bg_color = Color(0.0, 0.85, 0.5, 0.9)
	hp_s.set_corner_radius_all(3)
	hud_hp_bar.add_theme_stylebox_override("fill", hp_s)
	hp_box.add_child(hud_hp_bar)

	hud_hp_label = Label.new()
	hud_hp_label.text = "100/100"
	hud_hp_label.add_theme_font_size_override("font_size", 10)
	hud_hp_label.add_theme_color_override("font_color", Color(0.0, 0.95, 0.85))
	hp_box.add_child(hud_hp_label)

	# Row 3: EXP Bar
	var exp_box := HBoxContainer.new()
	right_vbox.add_child(exp_box)
	hud_exp_bar = ProgressBar.new()
	hud_exp_bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hud_exp_bar.custom_minimum_size = Vector2(0, 8)
	hud_exp_bar.show_percentage = false
	var exp_s := StyleBoxFlat.new()
	exp_s.bg_color = Color(0.65, 0.25, 0.95, 0.9)
	exp_s.set_corner_radius_all(3)
	hud_exp_bar.add_theme_stylebox_override("fill", exp_s)
	exp_box.add_child(hud_exp_bar)

	hud_exp_label = Label.new()
	hud_exp_label.text = "EXP: 0/100"
	hud_exp_label.add_theme_font_size_override("font_size", 9)
	hud_exp_label.add_theme_color_override("font_color", Color(0.8, 0.6, 1.0))
	exp_box.add_child(hud_exp_label)

	# Row 4: Stats Badges
	hud_stats_label = Label.new()
	hud_stats_label.text = "⚔️ Atk: 12  🛡️ Def: 5  🧪 Pot: 1"
	hud_stats_label.add_theme_font_size_override("font_size", 10)
	hud_stats_label.add_theme_color_override("font_color", Color(0.85, 0.85, 0.9))
	right_vbox.add_child(hud_stats_label)

	# Row 5: Key Badge + Icon
	var key_row := HBoxContainer.new()
	key_row.add_theme_constant_override("separation", 6)
	right_vbox.add_child(key_row)

	hud_key_icon = TextureRect.new()
	var key_tex = load("res://assets/sprites/ui/skills/icon_castle_key.png")
	if key_tex:
		hud_key_icon.texture = key_tex
		hud_key_icon.custom_minimum_size = Vector2(16, 16)
		hud_key_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		hud_key_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		hud_key_icon.modulate = Color(0.4, 0.4, 0.4, 0.6)
	key_row.add_child(hud_key_icon)

	hud_key_badge = Label.new()
	hud_key_badge.text = "Castle Key: [LOCKED]"
	hud_key_badge.add_theme_font_size_override("font_size", 9)
	hud_key_badge.add_theme_color_override("font_color", Color(0.6, 0.6, 0.6))
	key_row.add_child(hud_key_badge)

	# Row 6: Gate Objective & CSP Seal
	hud_gate_badge = Label.new()
	hud_gate_badge.text = "🏰 Gerbang: Syarat Lv. %d | Segel: %s" % [
		GameState.gate_req_level,
		csp_result.get("gate_seal", "Seal of Flame")
	]
	hud_gate_badge.add_theme_font_size_override("font_size", 9)
	hud_gate_badge.add_theme_color_override("font_color", Color(1.0, 0.75, 0.2))
	right_vbox.add_child(hud_gate_badge)

	_update_player_stats_hud()
	_reposition_hud_panels()

func _reposition_hud_panels() -> void:
	var vp := get_viewport()
	if not vp:
		return
	var vp_size: Vector2 = vp.get_visible_rect().size

	if is_instance_valid(player_hud_panel):
		var hud_w: float = 445.0
		var hud_h: float = 165.0
		player_hud_panel.custom_minimum_size = Vector2(hud_w, hud_h)
		player_hud_panel.size = Vector2(hud_w, hud_h)
		player_hud_panel.position = Vector2(16.0, maxf(16.0, vp_size.y - hud_h - 16.0))

	if is_instance_valid(debug_panel):
		var dbg_w: float = 340.0
		var dbg_h: float = 420.0
		debug_panel.custom_minimum_size = Vector2(dbg_w, dbg_h)
		debug_panel.size = Vector2(dbg_w, dbg_h)
		debug_panel.position = Vector2(maxf(16.0, vp_size.x - dbg_w - 16.0), maxf(16.0, vp_size.y - dbg_h - 16.0))

func _update_player_stats_hud() -> void:
	if not is_instance_valid(player_hud_panel):
		return

	# Only visible when not in battle
	player_hud_panel.visible = not is_in_battle
	if player_hud_panel.visible:
		_reposition_hud_panels()

	var s: Dictionary = GameState.get_status_summary()
	if hud_level_badge:
		hud_level_badge.text = "LV. %d" % s.level
	if hud_hp_bar:
		hud_hp_bar.max_value = float(s.max_hp)
		hud_hp_bar.value = float(s.hp)
	if hud_hp_label:
		hud_hp_label.text = "%d/%d" % [s.hp, s.max_hp]
	if hud_exp_bar:
		hud_exp_bar.max_value = float(s.exp_needed)
		hud_exp_bar.value = float(s.exp) if s.level < GameState.MAX_LEVEL else float(s.exp_needed)
	if hud_exp_label:
		hud_exp_label.text = "EXP: %d/%d" % [s.exp, s.exp_needed] if s.level < GameState.MAX_LEVEL else "MAX LEVEL"
	if hud_stats_label:
		hud_stats_label.text = "⚔️ Atk: %d  🛡️ Def: %d  🧪 Pot: %d" % [s.attack, s.defense, s.potions]
	if hud_key_badge:
		if s.has_key:
			hud_key_badge.text = "Castle Key: [ACQUIRED!]"
			hud_key_badge.add_theme_color_override("font_color", Color(1.0, 0.85, 0.1))
			if hud_key_icon: hud_key_icon.modulate = Color(1.0, 0.85, 0.2, 1.0)
		else:
			hud_key_badge.text = "Castle Key: [LOCKED]"
			hud_key_badge.add_theme_color_override("font_color", Color(0.6, 0.6, 0.6))
			if hud_key_icon: hud_key_icon.modulate = Color(0.4, 0.4, 0.4, 0.6)

	if hud_gate_badge:
		hud_gate_badge.text = "🏰 Gerbang: Syarat Lv. %d | Segel: %s" % [
			GameState.gate_req_level,
			csp_result.get("gate_seal", "Seal of Flame")
		]

	if hud_pause_btn:
		hud_pause_btn.text = "▶ Resume [P]" if is_game_paused else "⏸ Pause [P]"

# ---------------------------------------------------------------
# CHEAT LEVEL-UP (INSTANT & AUTO)
# ---------------------------------------------------------------
func _cheat_level_up() -> void:
	var prev_lvl: int = GameState.level
	GameState.cheat_level_up()
	_play_sfx(sfx_level_up)
	if GameState.level > prev_lvl:
		_show_floating_alert("⚡ CHEAT LEVEL UP! Player sekarang Level %d! (+Full HP & Stat Boost)" % GameState.level, Color(1.0, 0.85, 0.1))
	else:
		_show_floating_alert("⚡ PLAYER MAX LEVEL (Level 3)! HP dipulihkan & Potion terisi!", Color(0.2, 1.0, 0.5))
	_update_player_stats_hud()
	_update_debug_hud()

func _toggle_cheat_auto_level() -> void:
	cheat_auto_level_enabled = not cheat_auto_level_enabled
	if hud_auto_btn:
		hud_auto_btn.text = "Auto-Lv: ON" if cheat_auto_level_enabled else "Auto-Lv: OFF"
		hud_auto_btn.add_theme_color_override("font_color", Color(0.2, 1.0, 0.5) if cheat_auto_level_enabled else Color(0.8, 0.8, 0.8))
	var status_text = "DIAKTIFKAN (Auto memenuhi syarat gerbang)" if cheat_auto_level_enabled else "DINONAKTIFKAN"
	_show_floating_alert("⚡ Cheat Auto Level-Up %s!" % status_text, Color(1.0, 0.7, 0.2))
	if cheat_auto_level_enabled and GameState.level < GameState.gate_req_level:
		_cheat_level_up()

# ---------------------------------------------------------------
# HOOKS FOR TURN-BASED BATTLE
# ---------------------------------------------------------------
func _on_battle_started(_state: BattleState = null) -> void:
	is_in_battle = true
	player.is_active = false
	if demon:
		demon.is_active = false

func _on_battle_ended(_winner: String = "", _final_state: BattleState = null) -> void:
	# Handled cleanly via BattleHUD.battle_hud_closed signal
	pass

# ---------------------------------------------------------------
# GATE SCOUTING MODAL (INTEL & CSP DEDUCTION CARD)
# ---------------------------------------------------------------
func _show_gate_scouting_modal() -> void:
	if is_instance_valid(gate_scout_modal) or scout_cooldown > 0.0 or is_in_battle:
		return
	scout_cooldown = 2.5

	gate_scout_modal = PanelContainer.new()
	gate_scout_modal.name = "GateScoutModal"
	gate_scout_modal.z_index = 25
	$CanvasLayer.add_child(gate_scout_modal)

	var vp_size: Vector2 = get_viewport().get_visible_rect().size
	var m_width: float = 460.0
	var m_height: float = 275.0
	gate_scout_modal.custom_minimum_size = Vector2(m_width, m_height)
	gate_scout_modal.size = Vector2(m_width, m_height)
	gate_scout_modal.position = (vp_size - Vector2(m_width, m_height)) / 2.0

	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.04, 0.03, 0.08, 0.96)
	style.border_color = Color(1.0, 0.75, 0.2, 0.95)
	style.set_border_width_all(2)
	style.set_corner_radius_all(8)
	style.set_content_margin_all(10)
	gate_scout_modal.add_theme_stylebox_override("panel", style)

	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 6)
	gate_scout_modal.add_child(vb)

	# Header with warning sign icon
	var hdr := HBoxContainer.new()
	hdr.add_theme_constant_override("separation", 8)
	vb.add_child(hdr)

	var sign_icon := TextureRect.new()
	var s_tex = load("res://assets/sprites/map/obstacles/gate_warning_sign.png")
	if s_tex:
		sign_icon.texture = s_tex
		sign_icon.custom_minimum_size = Vector2(26, 26)
		sign_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		sign_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	hdr.add_child(sign_icon)

	var title_lbl := Label.new()
	title_lbl.text = "PAPAN PERINGATAN GERBANG: INTEL & DEDUKSI CSP"
	title_lbl.add_theme_font_size_override("font_size", 11)
	title_lbl.add_theme_color_override("font_color", Color(1.0, 0.85, 0.2))
	title_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hdr.add_child(title_lbl)

	var btn_close := Button.new()
	btn_close.text = "X"
	btn_close.custom_minimum_size = Vector2(24, 22)
	btn_close.pressed.connect(func():
		if is_instance_valid(gate_scout_modal):
			gate_scout_modal.queue_free()
			gate_scout_modal = null
	)
	hdr.add_child(btn_close)

	var sep := HSeparator.new()
	vb.add_child(sep)

	# Visual Cards Row (Penjaga | Segel | Bos)
	var cards_row := HBoxContainer.new()
	cards_row.add_theme_constant_override("separation", 8)
	cards_row.alignment = BoxContainer.ALIGNMENT_CENTER
	vb.add_child(cards_row)

	var g_type: String = str(csp_result.get("guard_type", "Infernal Knight"))
	var g_strat: String = str(csp_result.get("guard_strategy", "Aggressive"))
	var g_elem: String = str(csp_result.get("guard_element", "Fire"))
	var seal_name: String = str(csp_result.get("gate_seal", "Seal of Flame"))
	var seal_eff: String = str(csp_result.get("gate_seal_effect", "Efek Medan Aktif"))
	var b_wep: String = str(csp_result.get("boss_weapon", "Flame Scythe"))
	var b_strat: String = str(csp_result.get("boss_strategy", "Tactical"))
	var b_eff: String = str(csp_result.get("boss_weapon_effect", "Efek Senjata"))

	# Card 1: Penjaga
	var c1 := _make_scout_card("PENJAGA GERBANG", g_type, "[%s | %s]" % [g_elem, g_strat], _get_scout_guard_portrait(g_type, seal_name), Color(0.9, 0.45, 0.2))
	cards_row.add_child(c1)

	# Card 2: Segel Gerbang
	var c2 := _make_scout_card("SEGEL GERBANG", seal_name, seal_eff, _get_scout_seal_texture(seal_name), Color(0.7, 0.35, 1.0))
	cards_row.add_child(c2)

	# Card 3: Resonansi Bos
	var c3 := _make_scout_card("SENJATA BOS", b_wep, "[%s | %s]" % [b_strat, b_eff], _get_scout_boss_weapon_texture(b_wep), Color(1.0, 0.3, 0.4))
	cards_row.add_child(c3)

	# Deductive Narrative Box
	var desc_lbl := RichTextLabel.new()
	desc_lbl.bbcode_enabled = true
	desc_lbl.fit_content = true
	desc_lbl.scroll_active = false
	desc_lbl.add_theme_font_size_override("normal_font_size", 9)
	desc_lbl.text = "[color=#00f5d4][b]HASIL DEDUKSI CONSTRAINT SATISFACTION (AC-3):[/b][/color]\n"
	desc_lbl.text += "• [color=yellow]Afinitas Elemen (C1-C2):[/color] Penjaga [b]%s[/b] terikat dengan [b]%s[/b], mewajibkan doktrin tempur [b]%s[/b].\n" % [g_type, seal_name, g_strat]
	desc_lbl.text += "• [color=yellow]Resonansi Tahta (C3-C5):[/color] Segel memproyeksikan Bos Neraka bersenjatakan [b]%s[/b] dengan doktrin [b]%s[/b].\n" % [b_wep, b_strat]
	var req_met: bool = GameState.level >= GameState.gate_req_level
	var req_color: String = "lime" if req_met else "red"
	desc_lbl.text += "• [color=yellow]Syarat Gerbang (C6):[/color] Minimal Level [color=%s][b]%d[/b][/color] (Level kamu saat ini: [color=%s][b]%d[/b][/color])" % [req_color, GameState.gate_req_level, req_color, GameState.level]
	vb.add_child(desc_lbl)

	# Bottom Action Button
	var btn_ok := Button.new()
	btn_ok.text = "Siap Tempur (Tutup Intel / ESC / Spasi)"
	btn_ok.add_theme_font_size_override("font_size", 10)
	btn_ok.custom_minimum_size = Vector2(0, 24)
	btn_ok.pressed.connect(func():
		if is_instance_valid(gate_scout_modal):
			gate_scout_modal.queue_free()
			gate_scout_modal = null
	)
	vb.add_child(btn_ok)

func _make_scout_card(title_t: String, name_t: String, sub_t: String, icon_tex: Texture2D, border_c: Color) -> PanelContainer:
	var p := PanelContainer.new()
	p.custom_minimum_size = Vector2(136, 68)
	var st := StyleBoxFlat.new()
	st.bg_color = Color(0.06, 0.05, 0.11, 0.9)
	st.border_color = border_c
	st.set_border_width_all(1)
	st.set_corner_radius_all(6)
	st.set_content_margin_all(4)
	p.add_theme_stylebox_override("panel", st)

	var vb := VBoxContainer.new()
	vb.alignment = BoxContainer.ALIGNMENT_CENTER
	vb.add_theme_constant_override("separation", 2)
	p.add_child(vb)

	var tl := Label.new()
	tl.text = title_t
	tl.add_theme_font_size_override("font_size", 7)
	tl.add_theme_color_override("font_color", Color(0.7, 0.7, 0.8))
	tl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vb.add_child(tl)

	if icon_tex:
		var tr := TextureRect.new()
		tr.texture = icon_tex
		tr.custom_minimum_size = Vector2(26, 26)
		tr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		tr.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		vb.add_child(tr)

	var nl := Label.new()
	nl.text = name_t
	nl.add_theme_font_size_override("font_size", 8)
	nl.add_theme_color_override("font_color", border_c)
	nl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	nl.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	vb.add_child(nl)

	var sl := Label.new()
	sl.text = sub_t
	sl.add_theme_font_size_override("font_size", 7)
	sl.add_theme_color_override("font_color", Color(0.8, 0.8, 0.85))
	sl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sl.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	vb.add_child(sl)

	return p

func _get_scout_guard_portrait(g_name: String, seal_name: String) -> Texture2D:
	const GRID_PATH := "res://assets/sprites/characters/guard/avatar_grid_9guards.png"
	if ResourceLoader.exists(GRID_PATH):
		var grid_tex = load(GRID_PATH) as Texture2D
		if grid_tex:
			var row := 0
			var gl := g_name.to_lower()
			if "shaman" in gl: row = 1
			elif "gargoyle" in gl: row = 2
			var col := 0
			var sl := seal_name.to_lower()
			if "shadow" in sl or "void" in sl: col = 1
			elif "blood" in sl: col = 2
			var atlas := AtlasTexture.new()
			atlas.atlas = grid_tex
			var cell_w := grid_tex.get_width() / 3.0
			var cell_h := grid_tex.get_height() / 3.0
			atlas.region = Rect2(col * cell_w, row * cell_h, cell_w, cell_h)
			return atlas
	return null

func _get_scout_seal_texture(seal_name: String) -> Texture2D:
	const PATH := "res://assets/sprites/map/obstacles/seals_gate_sheet.png"
	if not ResourceLoader.exists(PATH): return null
	var sheet: Texture2D = load(PATH) as Texture2D
	if not sheet: return null
	var col := 0
	var s_lower := seal_name.to_lower()
	if "shadow" in s_lower or "void" in s_lower: col = 1
	elif "blood" in s_lower: col = 2
	var atlas := AtlasTexture.new()
	atlas.atlas = sheet
	var w := sheet.get_width() / 3.0
	atlas.region = Rect2(col * w, 0, w, sheet.get_height())
	return atlas

func _get_scout_boss_weapon_texture(weapon_name: String) -> Texture2D:
	const PATH := "res://assets/sprites/characters/demon/weapons_boss_sheet.png"
	if not ResourceLoader.exists(PATH): return null
	var sheet: Texture2D = load(PATH) as Texture2D
	if not sheet: return null
	var col := 0
	var w_lower := weapon_name.to_lower()
	if "cursed" in w_lower or "shadow" in w_lower: col = 1
	elif "trident" in w_lower or "blood" in w_lower: col = 2
	var atlas := AtlasTexture.new()
	atlas.atlas = sheet
	var w := sheet.get_width() / 3.0
	atlas.region = Rect2(col * w, 0, w, sheet.get_height())
	return atlas

# ---------------------------------------------------------------
# ROAMING PAUSE & AI CONCEPT PRESENTATION MODAL
# ---------------------------------------------------------------
func _toggle_pause_game() -> void:
	if is_in_battle or is_game_over:
		return
	if is_game_paused:
		_resume_game()
	else:
		_pause_game()

func _pause_game() -> void:
	if is_game_paused or is_in_battle or is_game_over:
		return
	is_game_paused = true
	get_tree().paused = true

	# Explicitly freeze movement of entities
	if player: player.is_active = false
	if demon: demon.is_active = false
	for m in spawned_minions:
		if is_instance_valid(m):
			m.is_active = false

	if is_instance_valid(gate_scout_modal):
		gate_scout_modal.queue_free()
		gate_scout_modal = null

	_build_pause_modal()
	_update_player_stats_hud()

func _resume_game() -> void:
	if not is_game_paused:
		return
	is_game_paused = false
	get_tree().paused = false

	# Restore entity activity
	if player and not is_in_battle and not is_game_over:
		player.is_active = true
	if demon and not is_in_battle and not GameState.boss_defeated:
		demon.is_active = true
	for m in spawned_minions:
		if is_instance_valid(m) and not m.is_defeated:
			m.is_active = true

	if is_instance_valid(pause_modal):
		pause_modal.queue_free()
		pause_modal = null

	_update_player_stats_hud()

func _build_pause_modal() -> void:
	if is_instance_valid(pause_modal):
		pause_modal.queue_free()

	pause_modal = Control.new()
	pause_modal.name = "PauseModalRoot"
	pause_modal.set_anchors_preset(Control.PRESET_FULL_RECT)
	pause_modal.process_mode = Node.PROCESS_MODE_ALWAYS
	$CanvasLayer.add_child(pause_modal)

	# 1. Dark Backdrop
	var backdrop := ColorRect.new()
	backdrop.set_anchors_preset(Control.PRESET_FULL_RECT)
	backdrop.color = Color(0.02, 0.02, 0.04, 0.88)
	pause_modal.add_child(backdrop)

	var bg_tex := TextureRect.new()
	bg_tex.set_anchors_preset(Control.PRESET_FULL_RECT)
	var bg_img = load("res://assets/sprites/ui/panel_loading_bg.png")
	if bg_img:
		bg_tex.texture = bg_img
		bg_tex.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		bg_tex.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
		bg_tex.modulate = Color(1.0, 1.0, 1.0, 0.22)
	pause_modal.add_child(bg_tex)

	# 2. Main Centered Card
	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	pause_modal.add_child(center)

	var panel := PanelContainer.new()
	var card_w := 780.0
	var card_h := 500.0
	panel.custom_minimum_size = Vector2(card_w, card_h)
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.04, 0.03, 0.09, 0.98)
	style.border_color = Color(1.0, 0.65, 0.15, 0.95)
	style.set_border_width_all(2)
	style.set_corner_radius_all(10)
	style.set_content_margin_all(14)
	panel.add_theme_stylebox_override("panel", style)
	center.add_child(panel)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 8)
	panel.add_child(vbox)

	# --- TOP HEADER ---
	var hdr := HBoxContainer.new()
	hdr.add_theme_constant_override("separation", 10)
	vbox.add_child(hdr)

	var chip_icon := TextureRect.new()
	var c_tex = load("res://assets/sprites/ui/skills/icon_algorithm_chip.png")
	if c_tex:
		chip_icon.texture = c_tex
		chip_icon.custom_minimum_size = Vector2(36, 36)
		chip_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		chip_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	hdr.add_child(chip_icon)

	var title_vbox := VBoxContainer.new()
	title_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title_vbox.add_theme_constant_override("separation", 2)
	hdr.add_child(title_vbox)

	var title_lbl := Label.new()
	title_lbl.text = "GAME PAUSED  |  BRIEFING ARSITEKTUR & KONSEP AI (TUBES TAHAP 3)"
	title_lbl.add_theme_font_size_override("font_size", 13)
	title_lbl.add_theme_color_override("font_color", Color(1.0, 0.80, 0.2))
	title_vbox.add_child(title_lbl)

	var subtitle_lbl := Label.new()
	subtitle_lbl.text = "Infernal Affairs: Integrasi Pathfinding, Adversarial Minimax, CSP, & Local Search"
	subtitle_lbl.add_theme_font_size_override("font_size", 10)
	subtitle_lbl.add_theme_color_override("font_color", Color(0.75, 0.75, 0.85))
	title_vbox.add_child(subtitle_lbl)

	var btn_resume_top := Button.new()
	btn_resume_top.text = " ▶ Lanjutkan [P / ESC] "
	btn_resume_top.add_theme_font_size_override("font_size", 11)
	btn_resume_top.custom_minimum_size = Vector2(160, 32)
	var r_style := StyleBoxFlat.new()
	r_style.bg_color = Color(0.15, 0.65, 0.35, 0.95)
	r_style.set_corner_radius_all(6)
	btn_resume_top.add_theme_stylebox_override("normal", r_style)
	btn_resume_top.pressed.connect(_resume_game)
	hdr.add_child(btn_resume_top)

	# --- LIVE WORLD STATUS STRIP ---
	var status_strip := PanelContainer.new()
	var ss_style := StyleBoxFlat.new()
	ss_style.bg_color = Color(0.08, 0.06, 0.14, 0.9)
	ss_style.border_color = Color(0.3, 0.2, 0.5, 0.8)
	ss_style.set_border_width_all(1)
	ss_style.set_corner_radius_all(6)
	ss_style.set_content_margin_all(6)
	status_strip.add_theme_stylebox_override("panel", ss_style)
	vbox.add_child(status_strip)

	var ss_hbox := HBoxContainer.new()
	ss_hbox.add_theme_constant_override("separation", 16)
	status_strip.add_child(ss_hbox)

	var p_sum: Dictionary = GameState.get_status_summary()
	var zone_name: String = "Wilderness (Hutan Minion)"
	if player:
		if player.grid_pos.y <= GridManager.CASTLE_Y_MAX:
			zone_name = "Throne Room (Ruang Tahta Bos)"
		elif player.grid_pos.y <= GridManager.COURTYARD_Y + 1:
			zone_name = "Gate Courtyard (Depan Gerbang)"

	var s_player_info := Label.new()
	s_player_info.text = "👤 Player: Lv. %d | HP: %d/%d | Exp: %d/%d | Pot: %d" % [
		p_sum.level, p_sum.hp, p_sum.max_hp, p_sum.exp, p_sum.exp_needed, p_sum.potions
	]
	s_player_info.add_theme_font_size_override("font_size", 9)
	s_player_info.add_theme_color_override("font_color", Color(0.0, 0.95, 0.85))
	ss_hbox.add_child(s_player_info)

	var s_gate_info := Label.new()
	s_gate_info.text = "🏰 Segel: [%s] | Syarat: Lv. %d" % [
		csp_result.get("gate_seal", "Seal of Flame"), GameState.gate_req_level
	]
	s_gate_info.add_theme_font_size_override("font_size", 9)
	s_gate_info.add_theme_color_override("font_color", Color(1.0, 0.75, 0.2))
	ss_hbox.add_child(s_gate_info)

	var s_zone_info := Label.new()
	s_zone_info.text = "📍 Zona: %s" % zone_name
	s_zone_info.add_theme_font_size_override("font_size", 9)
	s_zone_info.add_theme_color_override("font_color", Color(0.85, 0.5, 1.0))
	s_zone_info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	s_zone_info.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	ss_hbox.add_child(s_zone_info)

	# --- 3 AI ARCHITECTURE CARDS (TAHAP 1, 2, 3) ---
	var cards_row := HBoxContainer.new()
	cards_row.size_flags_vertical = Control.SIZE_EXPAND_FILL
	cards_row.add_theme_constant_override("separation", 8)
	vbox.add_child(cards_row)

	# Card 1: Tahap 1 Pathfinding
	var c1 := _make_concept_card(
		"TAHAP 1: PATHFINDING",
		"A* & UCS (Dijkstra)",
		Color(0.0, 0.95, 0.85),
		"[color=#00f5d4][b]• Algoritma Navigasi:[/b][/color] Menggunakan A* (Heuristik Manhattan) & UCS.\n" +
		"[color=#00f5d4][b]• NPC Patrol & Chase:[/b][/color] Minion berpatroli acak di Wilderness. Bos mengejar saat terdeteksi.\n" +
		"[color=#00f5d4][b]• Visualizer Real-Time:[/b][/color] Garis ungu (titik lintasan) & area kuning (simpul terbuka/frontier).\n" +
		"[color=#00f5d4][b]• Dynamic Switch:[/b][/color] Tekan [TAB] atau [1/2] untuk beralih A* / UCS kapan saja."
	)
	cards_row.add_child(c1)

	# Card 2: Tahap 2 Adversarial Search
	var c2 := _make_concept_card(
		"TAHAP 2: ADVERSARIAL",
		"Minimax + Alpha-Beta",
		Color(0.85, 0.45, 1.0),
		"[color=#d884ff][b]• Turn-Based Duel:[/b][/color] Pertarungan taktis (Attack, Heavy, Defend, Potion).\n" +
		"[color=#d884ff][b]• Alpha-Beta Pruning:[/b][/color] Memangkas cabang pohon yang tidak optimal secara eksponensial.\n" +
		"[color=#d884ff][b]• Heuristic Eval Func:[/b][/color] HP Difference, Aggressive, Defensive, & Weighted.\n" +
		"[color=#d884ff][b]• Live Debug Sidebar:[/b][/color] Tekan [D] saat duel untuk memantau pohon & performa pencarian."
	)
	cards_row.add_child(c2)

	# Card 3: Tahap 3 CSP & Local Search
	var c3 := _make_concept_card(
		"TAHAP 3: CSP & BALANCING",
		"AC-3 & Simulated Annealing",
		Color(1.0, 0.65, 0.15),
		"[color=#ffbe0b][b]• Formulasi CSP (AC-3):[/b][/color] Graf 7-variabel mengatur Penjaga, Segel, Senjata Bos, & Doktrin.\n" +
		"[color=#ffbe0b][b]• Efek Pasif Aktif:[/b][/color] Burn DoT, Lifesteal, dan Armor Pierce terikat pada senjata & segel.\n" +
		"[color=#ffbe0b][b]• Local Search Balancer:[/b][/color] Optimasi stat musuh pra-duel via Simulated Annealing (winrate 55%).\n" +
		"[color=#ffbe0b][b]• Intel Scouting:[/b][/color] Periksa papan gerbang untuk deduksi taktis sebelum menantang Penjaga."
	)
	cards_row.add_child(c3)

	# --- PRESENTATION SHORTCUTS BAR ---
	var sc_panel := PanelContainer.new()
	var sc_style := StyleBoxFlat.new()
	sc_style.bg_color = Color(0.02, 0.02, 0.05, 0.85)
	sc_style.border_color = Color(0.4, 0.4, 0.5, 0.6)
	sc_style.set_border_width_all(1)
	sc_style.set_corner_radius_all(5)
	sc_style.set_content_margin_all(5)
	sc_panel.add_theme_stylebox_override("panel", sc_style)
	vbox.add_child(sc_panel)

	var sc_lbl := Label.new()
	sc_lbl.text = "Shortcut Presenter:  [P / ESC] Pause/Resume  |  [TAB] A*/UCS  |  [F3] Debug HUD  |  [L] Instant Level Up  |  [K] Auto-Level  |  [R] Reset"
	sc_lbl.add_theme_font_size_override("font_size", 9)
	sc_lbl.add_theme_color_override("font_color", Color(0.7, 0.7, 0.8))
	sc_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sc_panel.add_child(sc_lbl)

	# --- BOTTOM ACTION BUTTONS ---
	var bot_row := HBoxContainer.new()
	bot_row.add_theme_constant_override("separation", 10)
	vbox.add_child(bot_row)

	var btn_intel := Button.new()
	btn_intel.text = " 📜 Buka Intel Gerbang (CSP) "
	btn_intel.add_theme_font_size_override("font_size", 10)
	btn_intel.custom_minimum_size = Vector2(180, 30)
	btn_intel.pressed.connect(func():
		_resume_game()
		_show_gate_scouting_modal()
	)
	bot_row.add_child(btn_intel)

	var btn_cheat := Button.new()
	btn_cheat.text = " ⚡ +1 Level Up (L) "
	btn_cheat.add_theme_font_size_override("font_size", 10)
	btn_cheat.custom_minimum_size = Vector2(130, 30)
	btn_cheat.pressed.connect(func():
		_cheat_level_up()
		_build_pause_modal() # Refresh modal
	)
	bot_row.add_child(btn_cheat)

	var spc := Control.new()
	spc.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	bot_row.add_child(spc)

	var btn_restart := Button.new()
	btn_restart.text = " 🔄 Restart Game (R) "
	btn_restart.add_theme_font_size_override("font_size", 10)
	btn_restart.custom_minimum_size = Vector2(140, 30)
	btn_restart.pressed.connect(func():
		_resume_game()
		start_new_game()
	)
	bot_row.add_child(btn_restart)

	var btn_resume_bot := Button.new()
	btn_resume_bot.text = " ▶ Lanjutkan Bermain "
	btn_resume_bot.add_theme_font_size_override("font_size", 11)
	btn_resume_bot.custom_minimum_size = Vector2(160, 30)
	var res_style := StyleBoxFlat.new()
	res_style.bg_color = Color(0.9, 0.45, 0.1, 0.95)
	res_style.set_corner_radius_all(6)
	btn_resume_bot.add_theme_stylebox_override("normal", res_style)
	btn_resume_bot.pressed.connect(_resume_game)
	bot_row.add_child(btn_resume_bot)

func _make_concept_card(title_t: String, sub_t: String, col: Color, bb_desc: String) -> PanelContainer:
	var p := PanelContainer.new()
	p.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	p.size_flags_vertical = Control.SIZE_EXPAND_FILL
	var st := StyleBoxFlat.new()
	st.bg_color = Color(0.04, 0.03, 0.08, 0.92)
	st.border_color = col
	st.set_border_width_all(1)
	st.set_corner_radius_all(6)
	st.set_content_margin_all(8)
	p.add_theme_stylebox_override("panel", st)

	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 4)
	p.add_child(vb)

	var tl := Label.new()
	tl.text = title_t
	tl.add_theme_font_size_override("font_size", 10)
	tl.add_theme_color_override("font_color", col)
	vb.add_child(tl)

	var sl := Label.new()
	sl.text = sub_t
	sl.add_theme_font_size_override("font_size", 8)
	sl.add_theme_color_override("font_color", Color(0.8, 0.8, 0.85))
	vb.add_child(sl)

	var sep := HSeparator.new()
	vb.add_child(sep)

	var rtl := RichTextLabel.new()
	rtl.bbcode_enabled = true
	rtl.size_flags_vertical = Control.SIZE_EXPAND_FILL
	rtl.fit_content = false
	rtl.scroll_active = false
	rtl.add_theme_font_size_override("normal_font_size", 8)
	rtl.text = bb_desc
	vb.add_child(rtl)

	return p
