class_name DemonEntity
extends Node2D

signal caught_player
signal path_updated(result: Dictionary)

@export var player_path: NodePath
@export var grid_manager_path: NodePath

var player: PlayerEntity
var grid_manager: GridManager

var grid_pos: Vector2i = Vector2i(21, 4)
var target_world_pos: Vector2 = Vector2.ZERO
var chase_interval: float = 0.35
var chase_timer: float = 0.0
var move_speed: float = 210.0
var is_active: bool = true

var current_algorithm: String = "astar"
var astar_solver: AStarSearch = AStarSearch.new()
var ucs_solver: UCSSearch     = UCSSearch.new()
var latest_path_result: Dictionary = {}

# Patrol around throne when player is unreachable (e.g. gate closed)
var throne_origin: Vector2i = Vector2i(21, 4)
var patrol_timer: float = 0.0
var patrol_interval: float = 2.5

# --- CSP Boss Weapons & Strategy Display ---
var boss_weapon: String = "Flame Scythe"
var boss_strategy: String = "Tactical"
var weapon_sprite: Sprite2D = null
var overhead_badge: Control = null

func set_boss_config(wep_name: String, strat_name: String) -> void:
	boss_weapon = wep_name
	boss_strategy = strat_name
	_update_boss_aura_color()
	_setup_boss_weapon_sprite()
	_setup_boss_overhead_badge()

func _update_boss_aura_color() -> void:
	if not aura_sprite:
		return
	var bw_lower = boss_weapon.to_lower()
	if "cursed" in bw_lower:
		aura_sprite.modulate = Color(0.7, 0.15, 0.95, 0.85) # Void Purple
	elif "blood" in bw_lower or "trident" in bw_lower:
		aura_sprite.modulate = Color(0.95, 0.15, 0.25, 0.85) # Blood Crimson
	else:
		aura_sprite.modulate = Color(1.0, 0.45, 0.1, 0.85) # Infernal Flame

func _setup_boss_weapon_sprite() -> void:
	if not weapon_sprite:
		weapon_sprite = Sprite2D.new()
		weapon_sprite.name = "BossWeaponSprite"
		add_child(weapon_sprite)

	var wep_sheet = load("res://assets/sprites/characters/demon/weapons_boss_sheet.png")
	if wep_sheet:
		var frame_w = 412.0 / 3.0
		var col_idx = 0
		var bw_lower = boss_weapon.to_lower()
		if "cursed" in bw_lower:
			col_idx = 1 # Cursed Blade
		elif "blood" in bw_lower or "trident" in bw_lower:
			col_idx = 2 # Blood Trident
		else:
			col_idx = 0 # Flame Scythe

		var atlas = AtlasTexture.new()
		atlas.atlas = wep_sheet
		atlas.region = Rect2(col_idx * frame_w, 0, frame_w, 138)
		weapon_sprite.texture = atlas
		weapon_sprite.scale = Vector2(0.24, 0.24)
		weapon_sprite.position = Vector2(20, -14)
		weapon_sprite.z_index = 1

func _setup_boss_overhead_badge() -> void:
	if overhead_badge and is_instance_valid(overhead_badge):
		overhead_badge.queue_free()

	overhead_badge = Control.new()
	overhead_badge.name = "BossOverheadBadge"
	overhead_badge.position = Vector2(0, -42)
	add_child(overhead_badge)

	var panel = PanelContainer.new()
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.04, 0.02, 0.08, 0.90)

	var badge_col = Color(1.0, 0.35, 0.2)
	if boss_strategy == "Defensive":
		badge_col = Color(0.2, 0.7, 1.0)
	elif boss_strategy == "Tactical":
		badge_col = Color(0.8, 0.4, 1.0)

	style.border_color = badge_col
	style.set_border_width_all(1)
	style.set_corner_radius_all(4)
	style.set_content_margin_all(3)
	panel.add_theme_stylebox_override("panel", style)
	overhead_badge.add_child(panel)

	var lbl = Label.new()
	lbl.text = "DEMON LORD\n[%s | %s]" % [boss_weapon, boss_strategy.to_upper()]
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

var last_dir: Vector2i = Vector2i(0, 1)

# --- Aura Dynamic Scaling ---
const AURA_BASE_SCALE := Vector2(0.32, 0.18)
const AURA_RUN_SCALE  := Vector2(0.22, 0.12)
const AURA_SPAWN_SCALE:= Vector2(0.62, 0.34)

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
	throne_origin = new_pos
	if grid_manager:
		target_world_pos = grid_manager.grid_to_world(grid_pos)
	else:
		target_world_pos = Vector2(grid_pos.x * 32 + 16, grid_pos.y * 32 + 16)
	position = target_world_pos

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
	# Pixel-perfect Dynamic Y-Sorting based on demon feet
	z_index = int(position.y + 14.0)

	position = position.move_toward(target_world_pos, move_speed * delta)
	var is_moving = position.distance_to(target_world_pos) > 1.5

	if is_moving:
		_play_anim("run", last_dir)
	else:
		_play_anim("idle", last_dir)

	_update_aura(delta, is_moving)
	if is_instance_valid(weapon_sprite):
		weapon_sprite.position.y = -14.0 + sin(pulse_time * 2.2) * 2.2

	if not is_active or not player:
		return

	if grid_pos == player.grid_pos:
		is_active = false
		caught_player.emit()
		return

	# AI Pathfinding & Movement Tick
	chase_timer += delta
	if chase_timer >= chase_interval:
		chase_timer = 0.0
		var result = recalculate_path()
		var path = result.get("path", [])

		if path.size() > 1:
			# Player is reachable! Take next step along calculated path
			var next_step: Vector2i = path[1]
			last_dir = next_step - grid_pos
			grid_pos = next_step
			if grid_manager:
				target_world_pos = grid_manager.grid_to_world(grid_pos)
			if grid_pos == player.grid_pos:
				is_active = false
				caught_player.emit()
		else:
			# Player is unreachable (gate closed). Idle patrol around throne room
			patrol_timer += chase_interval
			if patrol_timer >= patrol_interval:
				patrol_timer = 0.0
				_idle_patrol_step()

func _idle_patrol_step() -> void:
	if not grid_manager:
		return
	var candidates: Array[Vector2i] = []
	for dy in [-1, 0, 1]:
		for dx in [-2, -1, 0, 1, 2]:
			var check_pos = throne_origin + Vector2i(dx, dy)
			if grid_manager.is_valid(check_pos.x, check_pos.y) and check_pos.y <= GridManager.CASTLE_Y_MAX:
				candidates.append(check_pos)
	if candidates.size() > 0:
		var dest = candidates[randi() % candidates.size()]
		var res = astar_solver.search(grid_manager, grid_pos, dest)
		var p = res.get("path", [])
		if p.size() > 1:
			var step: Vector2i = p[1]
			last_dir = step - grid_pos
			grid_pos = step
			target_world_pos = grid_manager.grid_to_world(grid_pos)

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
		var pulse = 1.0 + sin(pulse_time) * 0.06
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
