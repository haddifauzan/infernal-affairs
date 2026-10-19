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
var guard_strategy: String = "Aggressive"
var gate_seal: String = "Seal of Flame"
var overhead_badge: Control = null
var weapon_sprite: Sprite2D = null
var seal_sprite: Sprite2D = null

func set_guard_config(g_type: String, g_strat: String = "Aggressive", g_seal: String = "Seal of Flame") -> void:
	guard_archetype = g_type
	guard_strategy = g_strat
	gate_seal = g_seal
	if is_instance_valid(anim_sprite):
		_setup_animations()
		_update_aura_color()
	_setup_overhead_badge()
	_setup_weapon_sprite()
	_setup_seal_sprite()

func set_guard_type(g_type: String) -> void:
	set_guard_config(g_type, guard_strategy, gate_seal)

func _update_aura_color() -> void:
	if not aura_sprite:
		return
	var s_lower: String = gate_seal.to_lower()
	if "shadow" in s_lower or "void" in s_lower:
		aura_sprite.modulate = Color(0.75, 0.2, 1.0, 0.75) # Void Purple
	elif "blood" in s_lower:
		aura_sprite.modulate = Color(1.0, 0.15, 0.25, 0.75) # Blood Crimson
	else:
		aura_sprite.modulate = Color(1.0, 0.45, 0.15, 0.75) # Infernal Flame

func _setup_weapon_sprite() -> void:
	if not weapon_sprite:
		weapon_sprite = Sprite2D.new()
		weapon_sprite.name = "WeaponSprite"
		add_child(weapon_sprite)

	var wep_sheet = load("res://assets/sprites/characters/guard/weapons_guard_sheet.png")
	if wep_sheet:
		var frame_w = 412.0 / 3.0 # ~137.33
		var col_idx = 0
		var g_lower = guard_archetype.to_lower()
		if "shaman" in g_lower:
			col_idx = 1 # Void Staff
		elif "gargoyle" in g_lower:
			col_idx = 2 # Chaos Mace
		else:
			col_idx = 0 # Greatsword

		var atlas = AtlasTexture.new()
		atlas.atlas = wep_sheet
		atlas.region = Rect2(col_idx * frame_w, 0, frame_w, 138)
		weapon_sprite.texture = atlas
		weapon_sprite.scale = Vector2(0.20, 0.20)
		weapon_sprite.position = Vector2(16, -10)
		weapon_sprite.z_index = 1

func _setup_seal_sprite() -> void:
	if not seal_sprite:
		seal_sprite = Sprite2D.new()
		seal_sprite.name = "SealSprite"
		add_child(seal_sprite)

	var seal_sheet = load("res://assets/sprites/map/obstacles/seals_gate_sheet.png")
	if seal_sheet:
		var frame_w = 413.0 / 3.0
		var col_idx = 0
		var s_lower = gate_seal.to_lower()
		var seal_glow := Color(1.0, 0.45, 0.15, 0.95)
		if "shadow" in s_lower or "void" in s_lower:
			col_idx = 1
			seal_glow = Color(0.75, 0.2, 1.0, 0.95)
		elif "blood" in s_lower:
			col_idx = 2
			seal_glow = Color(1.0, 0.15, 0.25, 0.95)

		var atlas = AtlasTexture.new()
		atlas.atlas = seal_sheet
		atlas.region = Rect2(col_idx * frame_w, 0, frame_w, 138)
		seal_sprite.texture = atlas
		seal_sprite.scale = Vector2(0.18, 0.18)
		seal_sprite.position = Vector2(0, -56)
		seal_sprite.modulate = seal_glow
		seal_sprite.z_index = 2

func _setup_overhead_badge() -> void:
	if overhead_badge and is_instance_valid(overhead_badge):
		overhead_badge.queue_free()

	overhead_badge = Control.new()
	overhead_badge.name = "OverheadBadge"
	overhead_badge.position = Vector2(0, -36)
	add_child(overhead_badge)

	var panel = PanelContainer.new()
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.04, 0.02, 0.08, 0.88)

	var badge_col = Color(1.0, 0.45, 0.15) # Flame
	var s_lower := gate_seal.to_lower()
	if "shadow" in s_lower or "void" in s_lower:
		badge_col = Color(0.75, 0.2, 1.0)
	elif "blood" in s_lower:
		badge_col = Color(1.0, 0.15, 0.25)

	style.border_color = badge_col
	style.set_border_width_all(1)
	style.set_corner_radius_all(4)
	style.set_content_margin_all(3)
	panel.add_theme_stylebox_override("panel", style)
	overhead_badge.add_child(panel)

	var lbl = Label.new()
	lbl.text = "%s\n[%s | %s]" % [guard_archetype, gate_seal, guard_strategy.to_upper()]
	lbl.add_theme_font_size_override("font_size", 8)
	lbl.add_theme_color_override("font_color", badge_col)
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	panel.add_child(lbl)

	panel.position = Vector2(-panel.size.x / 2.0, -panel.size.y)
	panel.resized.connect(func():
		panel.position = Vector2(-panel.size.x / 2.0, -panel.size.y)
	)

# --- Sprite & Aura ---
@onready var anim_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var aura_sprite: Sprite2D = $AuraSprite

const AURA_BASE_SCALE := Vector2(0.30, 0.16)
var pulse_time: float = 0.0

func initialize(gm: GridManager, start_pos: Vector2i) -> void:
	grid_manager = gm
	set_grid_position(start_pos)

func _ready() -> void:
	_setup_overhead_badge()
	_setup_weapon_sprite()
	_setup_seal_sprite()
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
	if is_instance_valid(weapon_sprite):
		weapon_sprite.position.y = -10.0 + sin(pulse_time * 2.0) * 2.0
	if is_instance_valid(seal_sprite):
		seal_sprite.position.y = -56.0 + sin(pulse_time * 2.0) * 2.5

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
