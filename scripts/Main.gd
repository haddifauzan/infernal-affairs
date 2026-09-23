class_name MainScene
extends Node2D

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

# Battle system
var battle_manager: BattleManager
var battle_hud: BattleHUD

func _ready() -> void:
	demon.path_updated.connect(_on_demon_path_updated)
	demon.caught_player.connect(_on_demon_caught_player)
	grid_manager.grid_updated.connect(_on_grid_updated)

	# Create BattleManager node
	battle_manager = BattleManager.new()
	battle_manager.name = "BattleManager"
	add_child(battle_manager)

	battle_manager.battle_started.connect(_on_battle_started)
	battle_manager.battle_ended.connect(_on_battle_ended)

	start_new_game()

func start_new_game() -> void:
	is_game_over = false
	is_in_battle = false

	# Cleanup any lingering battle HUD
	if is_instance_valid(battle_hud):
		battle_hud.queue_free()
		battle_hud = null

	grid_manager.generate_new_map()
	# arena_map.build() dipanggil otomatis lewat signal grid_updated

	var p_pos = grid_manager.get_player_start_pos()
	var d_pos = grid_manager.get_demon_start_pos()

	player.set_grid_position(p_pos)
	player.is_active = true

	demon.set_grid_position(d_pos)
	demon.is_active = true
	demon.set_algorithm(current_algorithm)

	path_dot_visualizer.clear_path()
	frontier_visualizer.set_explored_nodes([])

	# Kamera mulai mengikuti player dengan batas wilayah peta
	camera.position = player.position
	camera.limit_left   = 0
	camera.limit_top    = 0
	camera.limit_right  = grid_manager.width  * grid_manager.tile_size
	camera.limit_bottom = grid_manager.height * grid_manager.tile_size

	_update_algo_label()
	info_label.text = "RUN!  WASD / Arrow Keys  |  [R] Reset  [Tab] Swap Algo"

func _on_grid_updated() -> void:
	arena_map.build_map(grid_manager)

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		match event.keycode:
			KEY_R:   start_new_game()
			KEY_TAB: _toggle_algorithm()
			KEY_1:   _set_algorithm("astar")
			KEY_2:   _set_algorithm("ucs")

func _toggle_algorithm() -> void:
	_set_algorithm("ucs" if current_algorithm == "astar" else "astar")

func _set_algorithm(algo: String) -> void:
	current_algorithm = algo
	demon.set_algorithm(current_algorithm)
	_update_algo_label()

func _update_algo_label() -> void:
	if algo_label:
		algo_label.text = "Algoritma: A* (Heuristic)" if current_algorithm == "astar" else "Algoritma: UCS (Dijkstra)"
		algo_label.modulate = Color("#00f5d4") if current_algorithm == "astar" else Color("#ffbe0b")

func _physics_process(_delta: float) -> void:
	# Kamera smooth follow player
	if player and camera:
		camera.position = camera.position.lerp(player.position, 0.08)

func _on_demon_path_updated(result: Dictionary) -> void:
	if is_in_battle:
		return

	# 1. Garis jejak titik-titik oranye
	var path: Array[Vector2i] = result.get("path", [])
	var world_points: Array[Vector2] = []
	for gp in path:
		world_points.append(grid_manager.grid_to_world(gp))
	path_dot_visualizer.update_path(world_points)

	# 2. Frontier (explored nodes) transparan kuning
	var explored: Array[Vector2i] = result.get("explored", [])
	frontier_visualizer.set_explored_nodes(explored)

	# 3. Update label metrik
	if not is_game_over:
		var nodes   = result.get("nodes_expanded", 0)
		var cost    = result.get("cost", 0)
		var time_ms = result.get("execution_time_ms", 0.0)
		info_label.text = "Nodes: %d | Cost: %.0f | Time: %.2f ms\n[R] Reset  [Tab] Swap  [1] A*  [2] UCS" % [nodes, cost, time_ms]

func _on_demon_caught_player() -> void:
	if is_in_battle or is_game_over:
		return
	# Freeze world while battle runs
	player.is_active = false
	demon.is_active  = false
	path_dot_visualizer.clear_path()
	frontier_visualizer.set_explored_nodes([])
	info_label.text = "⚔️  BATTLE INITIATED!"
	algo_label.text = ""

	# Small delay then start battle
	is_in_battle = true
	_start_battle_scene()

# ---------------------------------------------------------------
# BATTLE INTEGRATION
# ---------------------------------------------------------------
func _start_battle_scene() -> void:
	# Build HUD and connect it to the manager
	battle_hud = BattleHUD.new()
	battle_hud.name = "BattleHUD"
	add_child(battle_hud)
	battle_hud.init(battle_manager)

	# Start with full HP (or carry partial HP in future extension)
	battle_manager.start_battle(BattleState.MAX_HP, BattleState.MAX_HP)

func _on_battle_started(_state: BattleState) -> void:
	pass  # HUD handles its own refresh

func _on_battle_ended(winner: String, _final_state: BattleState) -> void:
	is_in_battle = false

	# Wait a moment then clean up HUD
	await get_tree().create_timer(2.0).timeout

	if is_instance_valid(battle_hud):
		battle_hud.queue_free()
		battle_hud = null

	if winner == "player":
		# Demon defeated — respawn it and continue
		var d_pos = grid_manager.get_demon_start_pos()
		demon.set_grid_position(d_pos)
		demon.is_active  = true
		player.is_active = true
		_update_algo_label()
		info_label.text = "🏆 Demon defeated! Keep running!  [R] Reset"
	else:
		# NPC wins — game over
		is_game_over = true
		path_dot_visualizer.clear_path()
		info_label.text = "💀 DEFEATED IN BATTLE!  Press [R] to try again."
		algo_label.text = ""
