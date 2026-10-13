class_name ArenaMap
extends Node2D

## Visual renderer for Infernal Affairs Tahap 3 (Expanded 44x46 Layout):
##   - Seamless, connected lava river system with T-junctions & curved corners.
##   - 9 stone bridges spanning main chasm and wilderness tributaries.
##   - Imposing landmark rock formations, crystals, and enlarged charred trees.
##   - Pixel-perfect Y-sorting with characters and props.

# Environment textures
var ground_wilderness_tex: Texture2D
var ground_castle_tex: Texture2D
var river_h_tex: Texture2D
var river_v_tex: Texture2D
var river_t_junction_south_tex: Texture2D
var river_turn_nw_tex: Texture2D
var river_turn_ne_tex: Texture2D

# Modular fortress textures
var wall_straight_tex: Texture2D
var wall_corner_tex: Texture2D
var wall_pillar_tex: Texture2D
var wall_tower_tex: Texture2D

# Obstacle & shadow textures
var rock_large_tex: Texture2D
var rock_medium_tex: Texture2D
var rock_small_tex: Texture2D
var crystal_large_tex: Texture2D
var crystal_small_tex: Texture2D
var tree_large_tex: Texture2D
var shadow_oval_tex: Texture2D

var grid_manager: GridManager
var tile_size: int = 32
var rng := RandomNumberGenerator.new()

var spawned_nodes: Array[Node2D] = []

func _ready() -> void:
	texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED
	_load_textures()

func _load_textures() -> void:
	ground_wilderness_tex = load("res://assets/sprites/map/ground/ground_wilderness.png")
	if not ground_wilderness_tex:
		ground_wilderness_tex = load("res://assets/sprites/map/ground/ground_willderness.png")

	ground_castle_tex     = load("res://assets/sprites/map/ground/ground_castle.png")
	river_h_tex           = load("res://assets/sprites/map/lava/extracted/river_h.png")
	river_v_tex           = load("res://assets/sprites/map/lava/extracted/river_v.png")

	# Seamless junction & corner river tiles
	if FileAccess.file_exists("res://assets/sprites/map/lava/extracted/river_t_junction_south.png"):
		var tj_img = Image.load_from_file("res://assets/sprites/map/lava/extracted/river_t_junction_south.png")
		if tj_img:
			river_t_junction_south_tex = ImageTexture.create_from_image(tj_img)
	if not river_t_junction_south_tex:
		river_t_junction_south_tex = load("res://assets/sprites/map/lava/extracted/river_t_junction_south.png")

	river_turn_nw_tex     = load("res://assets/sprites/map/lava/extracted/river_c_left_to_up.png")
	river_turn_ne_tex     = load("res://assets/sprites/map/lava/extracted/river_c_right_to_up.png")

	wall_straight_tex     = load("res://assets/sprites/map/obstacles/wall_straight_large.png")
	wall_corner_tex       = load("res://assets/sprites/map/obstacles/wall_corner_large.png")
	wall_pillar_tex       = load("res://assets/sprites/map/obstacles/wall_pillar_large.png")
	wall_tower_tex        = load("res://assets/sprites/map/obstacles/wall_tower_large.png")

	rock_large_tex        = load("res://assets/sprites/map/obstacles/rock_large.png")
	rock_medium_tex       = load("res://assets/sprites/map/obstacles/rock_medium.png")
	rock_small_tex        = load("res://assets/sprites/map/obstacles/rock_small.png")
	crystal_large_tex     = load("res://assets/sprites/map/obstacles/crystal_large.png")
	crystal_small_tex     = load("res://assets/sprites/map/obstacles/crystal_small.png")
	tree_large_tex        = load("res://assets/sprites/map/obstacles/tree_large.png")
	shadow_oval_tex       = load("res://assets/sprites/map/obstacles/shadow_oval.png")

func build_map(gm: GridManager) -> void:
	grid_manager = gm
	tile_size = gm.tile_size
	rng.randomize()

	# Clear existing prop nodes
	for node in spawned_nodes:
		if is_instance_valid(node):
			node.queue_free()
	spawned_nodes.clear()

	# Redraw 2D canvas layers
	queue_redraw()

	# Spawn Y-sorted physical props
	_spawn_visual_elements()

func _draw() -> void:
	if not grid_manager or grid_manager.grid.is_empty():
		return

	var w = grid_manager.width
	var h = grid_manager.height
	var ts = float(tile_size)
	var split_y = GridManager.WALL_Y_TOP

	# 1. MAP 2 FLOOR: OBSIDIAN CASTLE INTERIOR (y = 0 .. 16)
	if ground_castle_tex:
		draw_texture_rect(ground_castle_tex, Rect2(0, 0, w * ts, split_y * ts), true)
		draw_rect(Rect2(0, 0, w * ts, split_y * ts), Color(0.01, 0.01, 0.03, 0.15), true)
	else:
		draw_rect(Rect2(0, 0, w * ts, split_y * ts), Color("#18151c"), true)

	# 2. MAP 1 FLOOR: VOLCANIC ASH WILDERNESS (y = 17 .. 45)
	if ground_wilderness_tex:
		draw_texture_rect(ground_wilderness_tex, Rect2(0, split_y * ts, w * ts, (h - split_y) * ts), true)
	else:
		draw_rect(Rect2(0, split_y * ts, w * ts, (h - split_y) * ts), Color("#201c1c"), true)

	# 3. ROYAL RED CARPET LEADING TO THRONE (Center = 22.0*ts = 704px)
	var carpet_x = 20.0 * ts
	var carpet_w = 4.0 * ts
	var carpet_y = 3.0 * ts
	var carpet_h = (split_y - 3.0) * ts
	draw_rect(Rect2(carpet_x, carpet_y, carpet_w, carpet_h), Color(0.55, 0.06, 0.10, 0.70), true)
	draw_line(Vector2(carpet_x, carpet_y), Vector2(carpet_x, carpet_y + carpet_h), Color(0.90, 0.75, 0.22, 0.85), 2.5)
	draw_line(Vector2(carpet_x + carpet_w, carpet_y), Vector2(carpet_x + carpet_w, carpet_y + carpet_h), Color(0.90, 0.75, 0.22, 0.85), 2.5)

	# 4. FULLY CONNECTED LAVA RIVER SYSTEM
	_draw_connected_lava_river_system()

	# 5. STONE BRIDGES DECKS (9 BRIDGES: 5 Main + 4 Wilderness)
	for b in grid_manager.bridges_info:
		_draw_stone_bridge_deck(b)

func _draw_connected_lava_river_system() -> void:
	var ts = float(tile_size)
	var w = float(grid_manager.width)

	var Xc_west: float = 8.0 * ts + 32.0   # 288.0 px (Center of West vertical tributary)
	var Xc_east: float = 34.0 * ts + 32.0  # 1120.0 px (Center of East vertical tributary)
	var Y_main: float  = 20.0 * ts + 32.0  # 672.0 px (Center of Main horizontal river)
	var Y_out: float   = 33.0 * ts + 32.0  # 1088.0 px (Center of Outgoing horizontal river)

	var tj_w_x: float  = Xc_west - 42.0
	var tj_e_x: float  = Xc_east - 42.0
	var tj_y: float    = Y_main - 26.5

	# A. Molten Lava Deep Underglow
	draw_rect(Rect2(0, Y_main - 24.0, w * ts, 48.0), Color(0.88, 0.20, 0.04, 0.95), true)
	draw_rect(Rect2(Xc_west - 24.0, Y_main, 48.0, Y_out - Y_main), Color(0.88, 0.20, 0.04, 0.95), true)
	draw_rect(Rect2(0, Y_out - 24.0, Xc_west, 48.0), Color(0.88, 0.20, 0.04, 0.95), true)
	draw_rect(Rect2(Xc_east - 24.0, Y_main, 48.0, Y_out - Y_main), Color(0.88, 0.20, 0.04, 0.95), true)
	draw_rect(Rect2(Xc_east, Y_out - 24.0, (w * ts - Xc_east), 48.0), Color(0.88, 0.20, 0.04, 0.95), true)

	# B. Straight Tiled River Sections (drawn under junctions for seamless blending)
	if river_h_tex:
		# Main horizontal river (3 segments separated by the 2 T-junctions)
		_tile_horizontal_lava(0, tj_w_x + 10.0, Y_main - 26.5)
		_tile_horizontal_lava(tj_w_x + 84.0, tj_e_x + 10.0, Y_main - 26.5)
		_tile_horizontal_lava(tj_e_x + 84.0, w * ts, Y_main - 26.5)

		# Outgoing horizontal rivers (exiting map borders)
		_tile_horizontal_lava(0, Xc_west - 53.0 + 10.0, Y_out - 26.5)
		_tile_horizontal_lava(Xc_east - 26.0 + 70.0, w * ts, Y_out - 26.5)

	if river_v_tex:
		# Vertical tributaries between T-junction and corner turns
		var y_v_start = tj_y + 75.0
		var y_v_end   = Y_out - 38.5 + 10.0
		_tile_vertical_lava(Xc_west - 26.5, y_v_start, y_v_end)
		_tile_vertical_lava(Xc_east - 26.5, y_v_start, y_v_end)

	# C. Dedicated Seamless T-Junctions (branching south)
	if river_t_junction_south_tex:
		draw_texture(river_t_junction_south_tex, Vector2(tj_w_x, tj_y))
		draw_texture(river_t_junction_south_tex, Vector2(tj_e_x, tj_y))

	# D. Dedicated Seamless Corner Turns (curving towards map border)
	if river_turn_nw_tex:
		draw_texture(river_turn_nw_tex, Vector2(Xc_west - 53.0, Y_out - 38.5))
	if river_turn_ne_tex:
		draw_texture(river_turn_ne_tex, Vector2(Xc_east - 26.0, Y_out - 38.5))

func _tile_horizontal_lava(start_x: float, end_x: float, y: float) -> void:
	if not river_h_tex or start_x >= end_x - 0.5:
		return
	var tex_w = float(river_h_tex.get_width())
	var tex_h = float(river_h_tex.get_height())
	var cx = start_x
	while cx < end_x - 0.5:
		var seg_w = min(tex_w, end_x - cx)
		if seg_w <= 0.0:
			break
		draw_texture_rect_region(river_h_tex, Rect2(cx, y, seg_w, tex_h), Rect2(0, 0, seg_w, tex_h))
		cx += tex_w

func _tile_vertical_lava(x: float, start_y: float, end_y: float) -> void:
	if not river_v_tex or start_y >= end_y - 0.5:
		return
	var tex_w = float(river_v_tex.get_width())
	var tex_h = float(river_v_tex.get_height())
	var cy = start_y
	while cy < end_y - 0.5:
		var seg_h = min(tex_h, end_y - cy)
		if seg_h <= 0.0:
			break
		draw_texture_rect_region(river_v_tex, Rect2(x, cy, tex_w, seg_h), Rect2(0, 0, tex_w, seg_h))
		cy += tex_h

func _draw_stone_bridge_deck(b: Dictionary) -> void:
	var ts = float(tile_size)
	var bx = float(b.x) * ts
	var by = float(b.y) * ts
	var bw = float(b.w) * ts
	var bh = float(b.h) * ts

	# Solid carved volcanic stone deck
	var deck_rect = Rect2(bx - 1.0, by - 2.0, bw + 2.0, bh + 4.0)
	draw_rect(deck_rect, Color(0.18, 0.16, 0.20, 1.0), true)
	# Stone masonry inner pavers
	draw_rect(Rect2(bx + 2.0, by, bw - 4.0, bh), Color(0.24, 0.22, 0.27, 0.95), true)

	# Paver mortar grid lines
	for dy in range(1, b.h):
		var ly = by + dy * ts
		draw_line(Vector2(bx + 2.0, ly), Vector2(bx + bw - 2.0, ly), Color(0.12, 0.10, 0.14, 0.8), 1.5)

	# Stone parapets / side railings (left & right)
	draw_line(Vector2(bx, by - 2.0), Vector2(bx, by + bh + 2.0), Color(0.42, 0.38, 0.46, 1.0), 3.5)
	draw_line(Vector2(bx + bw, by - 2.0), Vector2(bx + bw, by + bh + 2.0), Color(0.42, 0.38, 0.46, 1.0), 3.5)
	# Railing shadow
	draw_line(Vector2(bx + 3.0, by), Vector2(bx + 3.0, by + bh), Color(0.08, 0.06, 0.10, 0.6), 1.5)

func _spawn_visual_elements() -> void:
	if not grid_manager:
		return

	var w = grid_manager.width
	var h = grid_manager.height
	var ts = float(tile_size)

	# 1. STONE CORNER POSTS FOR ALL 9 BRIDGES
	for b in grid_manager.bridges_info:
		var bx = float(b.x) * ts
		var by = float(b.y) * ts
		var bw = float(b.w) * ts
		var bh = float(b.h) * ts
		var z_base = int(by + bh)

		_spawn_single_prop(rock_small_tex, Vector2(bx + 2.0, by + 2.0), 0.32, z_base, Color(1.20, 1.15, 1.10))
		_spawn_single_prop(rock_small_tex, Vector2(bx + bw - 2.0, by + 2.0), 0.32, z_base, Color(1.20, 1.15, 1.10))
		_spawn_single_prop(rock_small_tex, Vector2(bx + 2.0, by + bh - 2.0), 0.32, z_base, Color(1.20, 1.15, 1.10))
		_spawn_single_prop(rock_small_tex, Vector2(bx + bw - 2.0, by + bh - 2.0), 0.32, z_base, Color(1.20, 1.15, 1.10))

	# 2. FORTIFIED CASTLE FRONT WALL (y = 17..18) & SIDE TOWERS
	var wall_base_z = int((GridManager.GATE_Y + 1) * ts)
	for x in range(1, GridManager.CENTER_X - 1, 2):
		var wx = (x + 1.0) * ts
		var wy = (GridManager.WALL_Y_TOP + 1.0) * ts
		_spawn_single_prop(wall_straight_tex, Vector2(wx, wy), 0.25, wall_base_z, Color(1.15, 1.10, 1.20))
	for x in range(GridManager.CENTER_X + 2, w - 3, 2):
		var wx = (x + 1.0) * ts
		var wy = (GridManager.WALL_Y_TOP + 1.0) * ts
		_spawn_single_prop(wall_straight_tex, Vector2(wx, wy), 0.25, wall_base_z, Color(1.15, 1.10, 1.20))

	# Side Wall Towers
	for y in range(1, GridManager.WALL_Y_TOP, 2):
		var tw_z = int((y + 2.0) * ts)
		_spawn_single_prop(wall_tower_tex, Vector2(1.5 * ts, (y + 1.0) * ts), 0.25, tw_z, Color(1.10, 1.05, 1.15))
		_spawn_single_prop(wall_tower_tex, Vector2((w - 1.5) * ts, (y + 1.0) * ts), 0.25, tw_z, Color(1.10, 1.05, 1.15))

	# 3. CASTLE THRONE ROOM OBSIDIAN PILLARS
	var pillar_cols = [8, 14, 28, 34]
	var pillar_rows = [6, 10, 14]
	for py in pillar_rows:
		for px in pillar_cols:
			var pil_z = int((py + 2.0) * ts)
			_spawn_shadow(Vector2((px + 0.5) * ts, (py + 1.85) * ts), Vector2(0.55, 0.25))
			_spawn_single_prop(wall_pillar_tex, Vector2((px + 0.5) * ts, (py + 0.95) * ts), 0.25, pil_z, Color(1.20, 1.05, 1.05))

	# 4. LARGE LANDMARK FORMATIONS (2x2) - GRAND SCALE AS ORIGINAL
	for bp in grid_manager.obstacles_2x2:
		var cx = (bp.x + 1.0) * ts
		var base_z = int((bp.y + 2.0) * ts)

		# Ground shadow firmly anchored at the bottom of the 2x2 base
		_spawn_shadow(Vector2(cx, (bp.y + 2.0) * ts - 6.0), Vector2(0.72, 0.34))

		var is_crystal = (bp.x + bp.y) % 2 == 1
		var tex = crystal_large_tex if is_crystal else rock_large_tex
		var sc  = 0.54 if is_crystal else 0.52
		var mod_c = Color(1.25, 1.18, 1.10) if is_crystal else Color(1.20, 1.12, 1.06)

		# Sprite anchored at bottom edge
		var cy = (bp.y + 2.0) * ts - 38.0 if is_crystal else (bp.y + 2.0) * ts - 44.0
		_spawn_single_prop(tex, Vector2(cx, cy), sc, base_z, mod_c)

	# 5. STANDALONE ACCENT ROCKS & CRYSTALS (1x1)
	for sp_pos in grid_manager.obstacles_1x1:
		var sx = (sp_pos.x + 0.5) * ts
		var base_z = int((sp_pos.y + 1.0) * ts)

		_spawn_shadow(Vector2(sx, (sp_pos.y + 1.0) * ts - 4.0), Vector2(0.44, 0.22))

		var is_crystal = (sp_pos.x * 3 + sp_pos.y) % 3 == 0
		var tex = crystal_small_tex if is_crystal else rock_medium_tex
		var sc  = 0.46 if is_crystal else 0.36
		var mod_c = Color(1.22, 1.15, 1.08)

		var sy = (sp_pos.y + 1.0) * ts - 16.0 if is_crystal else (sp_pos.y + 1.0) * ts - 21.0
		_spawn_single_prop(tex, Vector2(sx, sy), sc, base_z, mod_c)

	# 6. CHARRED TREES (ENLARGED IMPOSING SCALE: 83 x 116 px)
	for tp in grid_manager.tree_positions:
		var tx = (tp.x + 0.5) * ts
		var base_z = int((tp.y + 1.0) * ts)

		# Broad root shadow
		_spawn_shadow(Vector2(tx, (tp.y + 1.0) * ts - 6.0), Vector2(0.75, 0.35))
		# Enlarge tree_large to 0.65 scale (83.2 x 115.7 px) with root anchored at base_z
		var ty = (tp.y + 1.0) * ts - 56.0
		_spawn_single_prop(tree_large_tex, Vector2(tx, ty), 0.65, base_z, Color(1.25, 1.15, 1.08))

	# 7. PERIMETER BORDER CLIFF ROCKS
	for y in range(h):
		for x in range(w):
			if x == 0 or x == w - 1 or y == 0 or y == h - 1:
				var roll = rng.randf()
				var tex = rock_large_tex if roll < 0.65 else rock_medium_tex
				var sc = rng.randf_range(0.45, 0.52)
				var base_z = int((y + 1.0) * ts)
				_spawn_single_prop(tex, Vector2((x + 0.5) * ts, (y + 0.4) * ts), sc, base_z, Color(1.15, 1.10, 1.05))

func _spawn_shadow(pos: Vector2, sc: Vector2) -> void:
	if not shadow_oval_tex:
		return
	var sp = Sprite2D.new()
	sp.texture = shadow_oval_tex
	sp.position = pos
	sp.scale = sc
	sp.z_index = 0
	sp.modulate = Color(0, 0, 0, 0.45)
	add_child(sp)
	spawned_nodes.append(sp)

func _spawn_single_prop(tex: Texture2D, pos: Vector2, prop_scale: float, z_idx: int, mod_color: Color = Color.WHITE) -> Sprite2D:
	if not tex:
		return null
	var sp = Sprite2D.new()
	sp.texture = tex
	sp.position = pos
	sp.scale = Vector2(prop_scale, prop_scale)
	sp.z_index = z_idx
	sp.modulate = mod_color
	add_child(sp)
	spawned_nodes.append(sp)
	return sp
