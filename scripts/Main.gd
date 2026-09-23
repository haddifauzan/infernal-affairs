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

func _ready() -> void:
	demon.path_updated.connect(_on_demon_path_updated)
	demon.caught_player.connect(_on_demon_caught_player)
	grid_manager.grid_updated.connect(_on_grid_updated)
	start_new_game()

func start_new_game() -> void:
	is_game_over = false

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
	camera.limit_left = 0
	camera.limit_top = 0
	camera.limit_right = grid_manager.width * grid_manager.tile_size
	camera.limit_bottom = grid_manager.height * grid_manager.tile_size

	_update_algo_label()
	info_label.text = "RUN!  WASD / Arrow Keys"

func _on_grid_updated() -> void:
	arena_map.build_map(grid_manager)

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		match event.keycode:
			KEY_R:     start_new_game()
			KEY_TAB:   _toggle_algorithm()
			KEY_1:     _set_algorithm("astar")
			KEY_2:     _set_algorithm("ucs")

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
		var nodes    = result.get("nodes_expanded", 0)
		var cost     = result.get("cost", 0)
		var time_ms  = result.get("execution_time_ms", 0.0)
		info_label.text = "Nodes: %d | Cost: %.0f | Time: %.2f ms\n[R] Reset  [Tab] Swap  [1] A*  [2] UCS" % [nodes, cost, time_ms]

func _on_demon_caught_player() -> void:
	is_game_over = true
	player.is_active = false
	demon.is_active  = false
	path_dot_visualizer.clear_path()
	info_label.text = "💀 TERTANGKAP!  Tekan [R] untuk Coba Lagi."
