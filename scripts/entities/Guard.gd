class_name GuardEntity
extends Node2D

## The Hell Gatekeeper - a stationary elite NPC guarding the castle gate.
## Only challengeable when player reaches Level 2.
## Stands in front of the gate and blocks passage.

signal interaction_requested(guard: GuardEntity)

var grid_manager: GridManager
var grid_pos: Vector2i = Vector2i.ZERO
var is_active: bool = true
var is_defeated: bool = false

# --- Sprite & Aura ---
@onready var anim_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var aura_sprite: Sprite2D = $AuraSprite

const AURA_BASE_SCALE := Vector2(0.30, 0.16)
var pulse_time: float = 0.0

func initialize(gm: GridManager, start_pos: Vector2i) -> void:
	grid_manager = gm
	set_grid_position(start_pos)

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

	var idle_tex = load("res://assets/sprites/characters/guard/guard_knight.png")

	if idle_tex:
		var dirs_order = ["down", "up", "left"]
		for row in range(3):
			for col in range(4):
				var frame = _slice_texture(idle_tex, col, row, 4, 4)
				frames.add_frame("idle_" + dirs_order[row], frame)
				frames.add_frame("run_"  + dirs_order[row], frame)

	anim_sprite.sprite_frames = frames
	anim_sprite.play("idle_down")
	anim_sprite.scale = Vector2(0.52, 0.52)

func _setup_aura() -> void:
	if not aura_sprite:
		return
	var aura_tex = load("res://assets/sprites/ui/effects/aura_demon.png")
	if aura_tex:
		aura_sprite.texture = aura_tex
	aura_sprite.modulate = Color(0.8, 0.2, 0.8, 0.6)
	aura_sprite.scale = AURA_BASE_SCALE
	aura_sprite.position = Vector2(0, 12)
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
		position = grid_manager.grid_to_world(grid_pos)
	else:
		position = Vector2(grid_pos.x * 32 + 16, grid_pos.y * 32 + 16)

func _physics_process(delta: float) -> void:
	if is_defeated:
		return
	# Pixel-perfect Dynamic Y-Sorting based on guard feet
	z_index = int(position.y + 12.0)
	_update_aura(delta)

func on_defeated() -> void:
	is_defeated = true
	is_active = false
	var tween = create_tween()
	tween.tween_property(self, "modulate:a", 0.0, 0.8)
	tween.tween_callback(queue_free)

func _update_aura(delta: float) -> void:
	if not aura_sprite:
		return
	pulse_time += delta * 2.5
	var pulse = 1.0 + sin(pulse_time) * 0.06
	var target_scale = AURA_BASE_SCALE * pulse
	aura_sprite.scale = aura_sprite.scale.lerp(target_scale, 0.12)
	aura_sprite.modulate.a = lerp(aura_sprite.modulate.a, 0.5, 0.10)
