class_name PlayerEntity
extends Node2D

signal moved(new_pos: Vector2i)

@export var grid_manager_path: NodePath
var grid_manager: GridManager

var grid_pos: Vector2i = Vector2i(2, 2)
var target_world_pos: Vector2 = Vector2.ZERO
var move_interval: float = 0.13
var move_timer: float = 0.0
var move_speed: float = 260.0
var is_active: bool = true

# --- Sprite & Anim ---
@onready var anim_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var aura_sprite: Sprite2D = $AuraSprite

var last_direction: Vector2i = Vector2i(0, 1) # default hadap bawah

# --- Aura Dynamic Scaling ---
const AURA_BASE_SCALE := Vector2(0.28, 0.15)  # Ukuran sedang (Idle)
const AURA_RUN_SCALE  := Vector2(0.18, 0.10)  # Mengecil saat lari
const AURA_SPAWN_SCALE:= Vector2(0.55, 0.30)  # Membesar saat spawn

var spawn_timer: float = 0.0
var pulse_time: float = 0.0

func _ready() -> void:
	if has_node(grid_manager_path):
		grid_manager = get_node(grid_manager_path) as GridManager
	elif get_parent().has_node("GridManager"):
		grid_manager = get_parent().get_node("GridManager") as GridManager

	set_grid_position(grid_pos)
	_setup_animations()
	_setup_aura()

func _setup_animations() -> void:
	if not anim_sprite:
		return
	var frames = SpriteFrames.new()

	for dir in ["down", "up", "left"]:
		frames.add_animation("idle_" + dir)
		frames.set_animation_loop("idle_" + dir, true)
		frames.set_animation_speed("idle_" + dir, 6.0)

		frames.add_animation("run_" + dir)
		frames.set_animation_loop("run_" + dir, true)
		frames.set_animation_speed("run_" + dir, 10.0)

	var idle_tex = load("res://assets/sprites/characters/player/player_idle.png")
	var run_tex  = load("res://assets/sprites/characters/player/player_run.png")

	if idle_tex and run_tex:
		# Row 0: Down, Row 1: Up, Row 2: Left (Right dihasilkan via flip_h dari Left)
		var dirs_order = ["down", "up", "left"]
		for row in range(3):
			for col in range(4):
				var idle_frame = _slice_texture(idle_tex, col, row, 4, 4)
				var run_frame  = _slice_texture(run_tex,  col, row, 4, 4)
				frames.add_frame("idle_" + dirs_order[row], idle_frame)
				frames.add_frame("run_"  + dirs_order[row], run_frame)

	anim_sprite.sprite_frames = frames
	anim_sprite.play("idle_down")
	anim_sprite.scale = Vector2(0.5, 0.5)

func _setup_aura() -> void:
	if not aura_sprite:
		return
	var aura_tex = load("res://assets/sprites/ui/effects/aura_player.png")
	if aura_tex:
		aura_sprite.texture = aura_tex
	aura_sprite.modulate = Color(0.0, 0.96, 0.83, 0.8)
	aura_sprite.scale = AURA_SPAWN_SCALE
	aura_sprite.position = Vector2(0, 12)
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

	# Efek ledakan aura membesar saat spawn / reset
	spawn_timer = 0.65
	if aura_sprite:
		aura_sprite.scale = AURA_SPAWN_SCALE
		aura_sprite.modulate.a = 1.0

func _physics_process(delta: float) -> void:
	# 1. Gerakkan karakter menuju target posisi di dunia
	position = position.move_toward(target_world_pos, move_speed * delta)
	var is_moving = position.distance_to(target_world_pos) > 1.5

	# 2. Update animasi berdasarkan status gerak
	if is_moving:
		_play_anim("run", last_direction)
	else:
		_play_anim("idle", last_direction)

	# 3. Update ukuran dinamis aura (Spawn -> Lari -> Idle)
	_update_aura(delta, is_moving)

	if not is_active:
		return

	# 4. Baca input keyboard untuk melangkah ke petak berikutnya
	move_timer += delta
	if move_timer < move_interval:
		return

	var dx: int = 0
	var dy: int = 0

	if Input.is_key_pressed(KEY_LEFT)  or Input.is_key_pressed(KEY_A): dx = -1
	elif Input.is_key_pressed(KEY_RIGHT) or Input.is_key_pressed(KEY_D): dx = 1
	elif Input.is_key_pressed(KEY_UP)    or Input.is_key_pressed(KEY_W): dy = -1
	elif Input.is_key_pressed(KEY_DOWN)  or Input.is_key_pressed(KEY_S): dy = 1

	if dx != 0 or dy != 0:
		last_direction = Vector2i(dx, dy)
		var target_grid = grid_pos + last_direction
		if grid_manager and grid_manager.is_valid(target_grid.x, target_grid.y):
			grid_pos = target_grid
			target_world_pos = grid_manager.grid_to_world(grid_pos)
			move_timer = 0.0
			moved.emit(grid_pos)

func _update_aura(delta: float, is_moving: bool) -> void:
	if not aura_sprite:
		return

	if spawn_timer > 0.0:
		# KETIKA SPAWN: Aura mekar besar lalu menyusut halus ke ukuran normal
		spawn_timer -= delta
		var t = clamp(1.0 - (spawn_timer / 0.65), 0.0, 1.0)
		var cur_target = AURA_BASE_SCALE.lerp(AURA_SPAWN_SCALE, 1.0 - t)
		aura_sprite.scale = aura_sprite.scale.lerp(cur_target, 0.20)
		aura_sprite.modulate.a = lerp(1.0, 0.75, t)
	elif is_moving:
		# KETIKA BERLARI: Aura mengecil (ramping tertiup angin saat lari)
		aura_sprite.scale = aura_sprite.scale.lerp(AURA_RUN_SCALE, 0.18)
		aura_sprite.modulate.a = lerp(aura_sprite.modulate.a, 0.85, 0.15)
	else:
		# KETIKA IDLE: Ukuran sedang dengan denyut halus alami
		pulse_time += delta * 3.5
		var pulse = 1.0 + sin(pulse_time) * 0.05
		var target_scale = AURA_BASE_SCALE * pulse
		aura_sprite.scale = aura_sprite.scale.lerp(target_scale, 0.12)
		aura_sprite.modulate.a = lerp(aura_sprite.modulate.a, 0.70, 0.10)

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
		# Ke KANAN: Gunakan animasi _left yang dibalik secara horizontal (flip_h = true)
		# Menghilangkan bug lari bolak-balik kanan-kiri
		anim_name = state + "_left"
		anim_sprite.flip_h = true

	if anim_sprite.animation != anim_name:
		anim_sprite.play(anim_name)
