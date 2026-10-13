class_name MainScene
extends Node2D

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

# Battle system (Tahap 2 - kept as hook)
var battle_manager: BattleManager
var battle_hud: BattleHUD

# --- Tahap 3: NPC Entities ---
var minion_scene: PackedScene = preload("res://scenes/Minion.tscn")
var guard_scene: PackedScene  = preload("res://scenes/Guard.tscn")
var spawned_minions: Array[MinionEntity] = []
var guard_entity: GuardEntity = null
const MINION_COUNT: int = 5

# --- Tahap 3: Map Props (Gate, Throne, Warning Sign) ---
var gate_sprite: Sprite2D = null
var gate_closed_tex: Texture2D
var gate_open_tex: Texture2D
var warning_sign_sprite: Sprite2D = null
var throne_sprite: Sprite2D = null

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

	# Connect Demon Boss Pathfinding & Encounter signals
	demon.path_updated.connect(_on_demon_path_updated)
	demon.caught_player.connect(_on_demon_caught_player)

	# GameState signals
	GameState.level_changed.connect(_on_level_changed)
	GameState.gate_unlocked.connect(_on_gate_unlocked)
	GameState.key_obtained.connect(_on_key_obtained)

	# Create BattleManager node
	battle_manager = BattleManager.new()
	battle_manager.name = "BattleManager"
	add_child(battle_manager)
	battle_manager.battle_started.connect(_on_battle_started)
	battle_manager.battle_ended.connect(_on_battle_ended)

	# Build debug HUD
	_build_debug_hud()

	start_new_game()

func start_new_game() -> void:
	is_game_over = false
	is_in_battle = false
	boss_bgm_playing = false
	encounter_cooldown = 0.0

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
	_update_debug_hud()
	info_label.text = "Infernal Affairs - Tahap 3  |  [Tab/1/2] Algo A*/UCS  |  [R] Reset  [F3] Debug"

func _on_grid_updated() -> void:
	arena_map.build_map(grid_manager)

# ---------------------------------------------------------------
# NPC SPAWNING
# ---------------------------------------------------------------
func _spawn_minions() -> void:
	for i in range(MINION_COUNT):
		var minion: MinionEntity = minion_scene.instantiate() as MinionEntity
		minion.name = "Minion_%d" % i
		add_child(minion)

		var pos = grid_manager.get_random_wilderness_pos()
		# Initialize with GridManager, spawn position, and Player reference for chase AI!
		minion.initialize(grid_manager, pos, player)
		minion.set_algorithm(current_algorithm)
		spawned_minions.append(minion)

func _spawn_guard() -> void:
	guard_entity = guard_scene.instantiate() as GuardEntity
	guard_entity.name = "Guard"
	add_child(guard_entity)

	var ts: float = float(grid_manager.tile_size)
	guard_grid_pos = Vector2i(GridManager.CENTER_X, GridManager.COURTYARD_Y)
	guard_entity.initialize(grid_manager, guard_grid_pos)
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
	if not GameState.boss_defeated:
		_trigger_encounter("boss", demon)

# ---------------------------------------------------------------
# PLAYER MOVEMENT & ENCOUNTER CHECK
# ---------------------------------------------------------------
func _on_player_moved_tahap3(new_pos: Vector2i) -> void:
	if is_in_battle or is_game_over:
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

	# Warning check at locked gate
	if not GameState.gate_is_open:
		if new_pos.y == GridManager.COURTYARD_Y and (new_pos.x == GridManager.CENTER_X or new_pos.x == GridManager.CENTER_X + 1):
			if not GameState.can_challenge_guard():
				_show_floating_alert("Terlalu lemah! Capai Level 2 dulu!", Color(1.0, 0.35, 0.35))

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
	if encounter_cooldown > 0.0:
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

func _handle_minion_encounter(minion: MinionEntity) -> void:
	minion.on_defeated()
	var leveled_up := GameState.award_minion_exp()

	if leveled_up:
		_play_sfx(sfx_level_up)
		_show_floating_alert("LEVEL UP! Naik ke Level %d! Syarat Gerbang Terpenuhi!" % GameState.level, Color(1.0, 0.85, 0.0))
	else:
		_show_floating_alert("Minion Dikalahkan! +50 EXP (%d/100)" % GameState.exp, Color(0.3, 1.0, 0.5))

	_update_debug_hud()

func _handle_guard_encounter(guard: GuardEntity) -> void:
	if not GameState.can_challenge_guard():
		_show_floating_alert("Terlalu lemah! Capai Level 2 dulu!", Color(1.0, 0.3, 0.3))
		return

	guard.on_defeated()
	GameState.award_guard_victory()
	_play_sfx(sfx_level_up)
	_show_floating_alert("Penjaga Dikalahkan! Castle Key Diperoleh! Naik ke Level 3!", Color(1.0, 0.85, 0.0))
	_update_debug_hud()

func _handle_boss_encounter() -> void:
	if GameState.boss_defeated:
		return

	GameState.award_boss_victory()
	demon.is_active = false
	var tween = create_tween()
	tween.tween_property(demon, "modulate:a", 0.0, 1.0)

	path_dot_visualizer.clear_path()
	is_game_over = true
	_show_floating_alert("BOS NERAKA DIKALAHKAN! KEMENANGAN MUTLAK!", Color(1.0, 0.85, 0.0))
	info_label.text = "VICTORY! Istana Neraka Ditaklukkan! [R] Main Ulang"
	_update_debug_hud()

# ---------------------------------------------------------------
# GATE STATE CHANGES
# ---------------------------------------------------------------
func _on_gate_unlocked() -> void:
	_play_sfx(sfx_gate_unlock)
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
# DEBUG HUD (F3 to toggle)
# ---------------------------------------------------------------
func _build_debug_hud() -> void:
	debug_panel = PanelContainer.new()
	debug_panel.name = "DebugPanel"
	debug_panel.anchors_preset = Control.PRESET_BOTTOM_LEFT
	debug_panel.offset_left = 10
	debug_panel.offset_bottom = -10
	debug_panel.offset_top = -280
	debug_panel.offset_right = 320

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

	_add_debug_btn(btn_grid, "TP -> Throne", func():
		var tp_pos = Vector2i(GridManager.CENTER_X, 6)
		player.set_grid_position(tp_pos)
		player.position.x = (GridManager.CENTER_X + 1.0) * float(grid_manager.tile_size)
		_show_floating_alert("Teleport ke Ruang Tahta", Color(0.5, 0.8, 1.0))
	)

	$CanvasLayer.add_child(debug_panel)

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
		match event.keycode:
			KEY_R:   start_new_game()
			KEY_TAB: _toggle_algorithm()
			KEY_1:   _set_algorithm("astar")
			KEY_2:   _set_algorithm("ucs")
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
	if encounter_cooldown > 0.0:
		encounter_cooldown = maxf(0.0, encounter_cooldown - delta)

	# Camera smooth follow
	if player and camera:
		camera.position = camera.position.lerp(player.position, 0.08)

# ---------------------------------------------------------------
# HOOKS FOR TURN-BASED BATTLE
# ---------------------------------------------------------------
func _on_battle_started() -> void:
	is_in_battle = true
	player.is_active = false

func _on_battle_ended(_result: Dictionary) -> void:
	is_in_battle = false
	player.is_active = true
	_update_debug_hud()
