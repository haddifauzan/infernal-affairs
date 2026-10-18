class_name GuardEntity
extends Node2D

## The Hell Gatekeeper - a stationary elite NPC guarding the castle gate.
## Only challengeable when player reaches Level 2.
## Stands in front of the gate and blocks passage.

@warning_ignore("unused_signal")
signal interaction_requested(guard: GuardEntity)

var grid_manager: GridManager
var grid_pos: Vector2i = Vector2i.ZERO
var is_active: bool = true
var is_defeated: bool = false
var guard_archetype: String = "Infernal Knight"

func set_guard_type(g_type: String) -> void:
	guard_archetype = g_type
	if is_instance_valid(anim_sprite):
		_setup_animations()
		_update_aura_color()

func _update_aura_color() -> void:
	if not aura_sprite:
		return
	var g_lower: String = guard_archetype.to_lower()
	if "shaman" in g_lower:
		aura_sprite.modulate = Color(0.7, 0.1, 0.9, 0.7)  # Void Purple
	elif "gargoyle" in g_lower:
		aura_sprite.modulate = Color(0.9, 0.15, 0.15, 0.7) # Blood Crimson
	else:
		aura_sprite.modulate = Color(1.0, 0.35, 0.1, 0.7)  # Infernal Flame

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
	var frames: SpriteFrames = SpriteFrames.new()

	for dir_name in ["down", "up", "left"]:
		frames.add_animation("idle_" + dir_name)
		frames.set_animation_loop("idle_" + dir_name, true)
		frames.set_animation_speed("idle_" + dir_name, 4.0)
		frames.add_animation("run_" + dir_name)
		frames.set_animation_loop("run_" + dir_name, true)
		frames.set_animation_speed("run_" + dir_name, 6.0)

	var tex_path: String = "res://assets/sprites/characters/guard/guard_knight.png"
	var g_lower: String = guard_archetype.to_lower()
	if "shaman" in g_lower and ResourceLoader.exists("res://assets/sprites/characters/guard/guard_shaman.png"):
		tex_path = "res://assets/sprites/characters/guard/guard_shaman.png"
	elif "gargoyle" in g_lower and ResourceLoader.exists("res://assets/sprites/characters/guard/guard_gargoyle.png"):
		tex_path = "res://assets/sprites/characters/guard/guard_gargoyle.png"
	var idle_tex: Texture2D = load(tex_path) as Texture2D

	if idle_tex:
		var dirs_order: Array[String] = ["down", "up", "left"]
		for row in range(3):
			for col in range(4):
				var frame: AtlasTexture = _slice_texture(idle_tex, col, row, 4, 4)
				frames.add_frame("idle_" + dirs_order[row], frame)
				frames.add_frame("run_"  + dirs_order[row], frame)

	anim_sprite.sprite_frames = frames
	anim_sprite.play("idle_down")
	anim_sprite.scale = Vector2(0.52, 0.52)

func _setup_aura() -> void:
	if not aura_sprite:
		return
	var aura_tex: Texture2D = load("res://assets/sprites/ui/effects/aura_demon.png") as Texture2D
	if aura_tex:
		aura_sprite.texture = aura_tex
	_update_aura_color()
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
	var tween: Tween = create_tween()
	tween.tween_property(self, "modulate:a", 0.0, 0.8)
	tween.tween_callback(queue_free)

func _update_aura(delta: float) -> void:
	if not aura_sprite:
		return
	pulse_time += delta * 2.5
	var pulse: float = 1.0 + sin(pulse_time) * 0.06
	var target_scale: Vector2 = AURA_BASE_SCALE * pulse
	aura_sprite.scale = aura_sprite.scale.lerp(target_scale, 0.12)
	aura_sprite.modulate.a = lerp(aura_sprite.modulate.a, 0.5, 0.10)
