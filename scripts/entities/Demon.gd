class_name DemonEntity
extends Node2D

signal caught_player
signal path_updated(result: Dictionary)

@export var player_path: NodePath
@export var grid_manager_path: NodePath

var player: PlayerEntity
var grid_manager: GridManager

var grid_pos: Vector2i = Vector2i(22, 15)
var target_world_pos: Vector2 = Vector2.ZERO
var chase_interval: float = 0.28
var chase_timer: float = 0.0
var move_speed: float = 220.0
var is_active: bool = true

var current_algorithm: String = "astar"
var astar_solver: AStarSearch = AStarSearch.new()
var ucs_solver: UCSSearch = UCSSearch.new()
var latest_path_result: Dictionary = {}

# --- Sprite & Aura ---
@onready var anim_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var aura_sprite: Sprite2D = $AuraSprite

var last_dir: Vector2i = Vector2i(0, 1)

# --- Aura Dynamic Scaling ---
const AURA_BASE_SCALE := Vector2(0.32, 0.18)  # Sedang saat idle
const AURA_RUN_SCALE  := Vector2(0.22, 0.12)  # Mengecil saat lari
const AURA_SPAWN_SCALE:= Vector2(0.62, 0.34)  # Membesar saat spawn

var spawn_timer: float = 0.0
var pulse_time: float = 0.0

func _ready() -> void:
	if has_node(grid_manager_path):
		grid_manager = get_node(grid_manager_path) as GridManager
	elif get_parent().has_node("GridManager"):
		grid_manager = get_parent().get_node("GridManager") as GridManager

	if has_node(player_path):
		player = get_node(player_path) as PlayerEntity
	elif get_parent().has_node("Player"):
		player = get_parent().get_node("Player") as PlayerEntity

	set_grid_position(grid_pos)
	_setup_animations()
	_setup_aura()

	if player and not player.moved.is_connected(_on_player_moved):
		player.moved.connect(_on_player_moved)

func _setup_animations() -> void:
	if not anim_sprite:
		return
	var frames = SpriteFrames.new()

	for dir in ["down", "up", "left"]:
		frames.add_animation("idle_" + dir)
		frames.set_animation_loop("idle_" + dir, true)
		frames.set_animation_speed("idle_" + dir, 5.0)

		frames.add_animation("run_" + dir)
		frames.set_animation_loop("run_" + dir, true)
		frames.set_animation_speed("run_" + dir, 8.0)

	var idle_tex = load("res://assets/sprites/characters/demon/demon_idle.png")
	var run_tex  = load("res://assets/sprites/characters/demon/demon_run.png")

	if idle_tex and run_tex:
		var dirs_order = ["down", "up", "left"]
		for row in range(3):
			for col in range(4):
				var idle_frame = _slice_texture(idle_tex, col, row, 4, 4)
				var run_frame  = _slice_texture(run_tex,  col, row, 4, 4)
				frames.add_frame("idle_" + dirs_order[row], idle_frame)
				frames.add_frame("run_"  + dirs_order[row], run_frame)

	anim_sprite.sprite_frames = frames
	anim_sprite.play("idle_down")
	anim_sprite.scale = Vector2(0.55, 0.55)

func _setup_aura() -> void:
	if not aura_sprite:
		return
	var aura_tex = load("res://assets/sprites/ui/effects/aura_demon.png")
	if aura_tex:
		aura_sprite.texture = aura_tex
	aura_sprite.scale = AURA_SPAWN_SCALE
	aura_sprite.position = Vector2(0, 14)
	aura_sprite.z_index = -1
	spawn_timer = 0.65

func _slice_texture(tex: Texture2D, col: int, row: int, total_cols: int, total_rows: int) -> AtlasTexture:
	var atlas = AtlasTexture.new()
	atlas.atlas = tex
	var frame_w = tex.get_width()  / float(total_cols)
	var frame_h = tex.get_height() / float(total_rows)
	atlas.region = Rect2(col * frame_w, row * frame_h, frame_w, frame_h)
	return atlas

func set_grid_position(new_pos: Vector2i) -> void:
	grid_pos = new_pos
	if grid_manager:
		target_world_pos = grid_manager.grid_to_world(grid_pos)
	else:
		target_world_pos = Vector2(grid_pos.x * 32 + 16, grid_pos.y * 32 + 16)
	position = target_world_pos

	# Ledakan aura merah membesar saat spawn
	spawn_timer = 0.65
	if aura_sprite:
		aura_sprite.scale = AURA_SPAWN_SCALE
		aura_sprite.modulate.a = 1.0

func set_algorithm(algo: String) -> void:
	current_algorithm = algo.to_lower()
	recalculate_path()

func recalculate_path() -> Dictionary:
	if not grid_manager or not player:
		return {}
	var result: Dictionary = {}
	if current_algorithm == "ucs":
		result = ucs_solver.search(grid_manager, grid_pos, player.grid_pos)
	else:
		result = astar_solver.search(grid_manager, grid_pos, player.grid_pos)
	latest_path_result = result
	path_updated.emit(result)
	return result

func _on_player_moved(_new_player_pos: Vector2i) -> void:
	if is_active:
		recalculate_path()

func _physics_process(delta: float) -> void:
	# 1. Gerakkan Demon menuju target
	position = position.move_toward(target_world_pos, move_speed * delta)
	var is_moving = position.distance_to(target_world_pos) > 1.5

	# 2. Update animasi
	if is_moving:
		_play_anim("run", last_dir)
	else:
		_play_anim("idle", last_dir)

	# 3. Update aura dinamis (Spawn -> Run -> Idle)
	_update_aura(delta, is_moving)

	if not is_active or not player:
		return

	if grid_pos == player.grid_pos:
		is_active = false
		caught_player.emit()
		return

	# 4. Timer pencarian jalur AI
	chase_timer += delta
	if chase_timer >= chase_interval:
		chase_timer = 0.0
		var result = recalculate_path()
		var path: Array[Vector2i] = result.get("path", [])
		if path.size() > 1:
			var next_step = path[1]
			last_dir = next_step - grid_pos
			grid_pos = next_step
			if grid_manager:
				target_world_pos = grid_manager.grid_to_world(grid_pos)
			if grid_pos == player.grid_pos:
				is_active = false
				caught_player.emit()

func _update_aura(delta: float, is_moving: bool) -> void:
	if not aura_sprite:
		return

	if spawn_timer > 0.0:
		spawn_timer -= delta
		var t = clamp(1.0 - (spawn_timer / 0.65), 0.0, 1.0)
		var cur_target = AURA_BASE_SCALE.lerp(AURA_SPAWN_SCALE, 1.0 - t)
		aura_sprite.scale = aura_sprite.scale.lerp(cur_target, 0.20)
		aura_sprite.modulate.a = lerp(1.0, 0.8, t)
	elif is_moving:
		aura_sprite.scale = aura_sprite.scale.lerp(AURA_RUN_SCALE, 0.18)
		aura_sprite.modulate.a = lerp(aura_sprite.modulate.a, 0.9, 0.15)
	else:
		pulse_time += delta * 3.5
		var pulse = 1.0 + sin(pulse_time) * 0.05
		var target_scale = AURA_BASE_SCALE * pulse
		aura_sprite.scale = aura_sprite.scale.lerp(target_scale, 0.12)
		aura_sprite.modulate.a = lerp(aura_sprite.modulate.a, 0.75, 0.10)

func _play_anim(state: String, dir: Vector2i) -> void:
	if not anim_sprite:
		return

	var anim_name = "idle_down"
	if dir.y < 0:
		anim_name = state + "_up"
		anim_sprite.flip_h = false
	elif dir.y > 0:
		anim_name = state + "_down"
		anim_sprite.flip_h = false
	elif dir.x < 0:
		anim_name = state + "_left"
		anim_sprite.flip_h = false
	elif dir.x > 0:
		anim_name = state + "_left"
		anim_sprite.flip_h = true

	if anim_sprite.animation != anim_name:
		anim_sprite.play(anim_name)
