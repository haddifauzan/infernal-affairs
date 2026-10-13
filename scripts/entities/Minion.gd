class_name MinionEntity
extends Node2D

## Imp NPC that actively uses A* or UCS pathfinding for patrol and player pursuit.
## Switches algorithm dynamically when user swaps between A* and UCS.

signal defeated(minion: MinionEntity)

var grid_manager: GridManager
var player: PlayerEntity = null

var astar_solver: AStarSearch = AStarSearch.new()
var ucs_solver: UCSSearch     = UCSSearch.new()
var current_algorithm: String = "astar"

var grid_pos: Vector2i = Vector2i.ZERO
var target_world_pos: Vector2 = Vector2.ZERO
var patrol_target: Vector2i = Vector2i.ZERO

var move_speed: float = 140.0
var chase_interval: float = 0.45       # AI pathfinding update tick
var chase_timer: float = 0.0
var patrol_interval: float = 2.8       # Pick new patrol target
var patrol_timer: float = 0.0
var patrol_radius: int = 6             # Wander within 6 tiles of spawn
var detection_radius: int = 8          # Aggro distance to chase player
var is_active: bool = true
var is_defeated: bool = false
var is_chasing: bool = false

var spawn_origin: Vector2i = Vector2i.ZERO

# --- Sprite & Aura ---
@onready var anim_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var aura_sprite: Sprite2D = $AuraSprite

var last_dir: Vector2i = Vector2i(0, 1)

const AURA_BASE_SCALE := Vector2(0.20, 0.10)
const AURA_RUN_SCALE  := Vector2(0.14, 0.07)
var pulse_time: float = 0.0

func initialize(gm: GridManager, start_pos: Vector2i, p: PlayerEntity = null) -> void:
	grid_manager = gm
	player = p
	spawn_origin = start_pos
	patrol_target = start_pos
	set_grid_position(start_pos)

func set_algorithm(algo: String) -> void:
	current_algorithm = algo.to_lower()

func _ready() -> void:
	_setup_animations()
	_setup_aura()

func _setup_animations() -> void:
	if not anim_sprite:
		return
	var frames = SpriteFrames.new()

	for dir_name in ["down", "up", "left"]:
		frames.add_animation("idle_" + dir_name)
		frames.set_animation_loop("idle_" + dir_name, true)
		frames.set_animation_speed("idle_" + dir_name, 4.0)

		frames.add_animation("run_" + dir_name)
		frames.set_animation_loop("run_" + dir_name, true)
		frames.set_animation_speed("run_" + dir_name, 6.0)

	var idle_tex = load("res://assets/sprites/characters/minion/minion_imp.png")

	if idle_tex:
		var dirs_order = ["down", "up", "left"]
		for row in range(3):
			for col in range(4):
				var frame = _slice_texture(idle_tex, col, row, 4, 4)
				frames.add_frame("idle_" + dirs_order[row], frame)
				frames.add_frame("run_"  + dirs_order[row], frame)

	anim_sprite.sprite_frames = frames
	anim_sprite.play("idle_down")
	anim_sprite.scale = Vector2(0.38, 0.38)

func _setup_aura() -> void:
	if not aura_sprite:
		return
	var aura_tex = load("res://assets/sprites/ui/effects/aura_demon.png")
	if aura_tex:
		aura_sprite.texture = aura_tex
	aura_sprite.modulate = Color(1.0, 0.4, 0.1, 0.5)
	aura_sprite.scale = AURA_BASE_SCALE
	aura_sprite.position = Vector2(0, 10)
	aura_sprite.z_index = -1

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

func _physics_process(delta: float) -> void:
	if is_defeated:
		return

	# Pixel-perfect Dynamic Y-Sorting based on minion feet
	z_index = int(position.y + 10.0)

	position = position.move_toward(target_world_pos, move_speed * delta)
	var is_moving = position.distance_to(target_world_pos) > 1.5

	if is_moving:
		_play_anim("run", last_dir)
	else:
		_play_anim("idle", last_dir)

	_update_aura(delta, is_moving)

	if not is_active or not grid_manager:
		return

	# Aggro player check
	is_chasing = false
	if player and player.is_active:
		var dist = abs(grid_pos.x - player.grid_pos.x) + abs(grid_pos.y - player.grid_pos.y)
		if dist <= detection_radius:
			is_chasing = true

	# Patrol if player is not detected
	if not is_chasing:
		patrol_timer += delta
		if patrol_timer >= patrol_interval:
			patrol_timer = 0.0
			_pick_patrol_target()

	# AI Movement Tick (A* or UCS)
	chase_timer += delta
	if chase_timer >= chase_interval:
		chase_timer = 0.0
		_move_toward_target()

func _pick_patrol_target() -> void:
	var attempts := 0
	while attempts < 20:
		attempts += 1
		var ox = spawn_origin.x + randi_range(-patrol_radius, patrol_radius)
		var oy = spawn_origin.y + randi_range(-patrol_radius, patrol_radius)
		if grid_manager.is_valid(ox, oy) and oy >= GridManager.ZONE_WILDERNESS_Y_MIN:
			patrol_target = Vector2i(ox, oy)
			return

func _move_toward_target() -> void:
	var target = player.grid_pos if is_chasing and player else patrol_target
	var result: Dictionary = {}

	# Run active algorithm: UCS or A*
	if current_algorithm == "ucs":
		result = ucs_solver.search(grid_manager, grid_pos, target)
	else:
		result = astar_solver.search(grid_manager, grid_pos, target)

	var path = result.get("path", [])
	if path.size() > 1:
		var next_step: Vector2i = path[1]
		last_dir = next_step - grid_pos
		grid_pos = next_step
		if grid_manager:
			target_world_pos = grid_manager.grid_to_world(grid_pos)

func on_defeated() -> void:
	is_defeated = true
	is_active = false
	var tween = create_tween()
	tween.tween_property(self, "modulate:a", 0.0, 0.5)
	tween.tween_callback(queue_free)
	defeated.emit(self)

func _update_aura(delta: float, is_moving: bool) -> void:
	if not aura_sprite:
		return
	if is_moving:
		aura_sprite.scale = aura_sprite.scale.lerp(AURA_RUN_SCALE, 0.18)
		aura_sprite.modulate.a = lerp(aura_sprite.modulate.a, 0.4, 0.15)
	else:
		pulse_time += delta * 3.0
		var pulse = 1.0 + sin(pulse_time) * 0.05
		var target_scale = AURA_BASE_SCALE * pulse
		aura_sprite.scale = aura_sprite.scale.lerp(target_scale, 0.12)
		aura_sprite.modulate.a = lerp(aura_sprite.modulate.a, 0.35, 0.10)

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
