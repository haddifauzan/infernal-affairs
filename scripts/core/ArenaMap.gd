class_name ArenaMap
extends Node2D

## Visual renderer for Infernal Affairs Tahap 4 (Expanded 52x56 Layout with River & 3 Bridges):
##   - Grand Obsidian Castle interior with red carpet and throne (North).
##   - Fortified Gate and Courtyard.
##   - The Great Molten Lava River spanned by 3 Strategic Bridges.
##   - Distinct Paved Highways: Slate stone cobblestone for Jalur Utama vs scorched volcanic basalt for Jalur Pintas.
##   - Rich wilderness obstacles: Trees, rocks, crystals, and watchtowers.
##   - Dedicated Southern Sanctuary for elemental altars.
##   - Pixel-perfect Y-sorting with characters and props.

# Environment textures
var ground_wilderness_tex: Texture2D
var ground_castle_tex: Texture2D
var river_grand_tex: Texture2D
var river_h_tex: Texture2D
var bridge_stone_tex: Texture2D
var cliff_edge_tex: Texture2D

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
var lava_pool_s_tex: Texture2D
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
	river_grand_tex       = load("res://assets/sprites/map/lava/extracted/river_grand_horizontal.png")
	river_h_tex           = load("res://assets/sprites/map/lava/extracted/river_h.png")
	bridge_stone_tex      = load("res://assets/sprites/map/ground/bridge_stone.png")
	cliff_edge_tex        = load("res://assets/sprites/map/ground/cliff_edge.png")
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
	lava_pool_s_tex       = load("res://assets/sprites/map/lava/lava_pool_small.png")
	shadow_oval_tex       = load("res://assets/sprites/map/obstacles/shadow_oval.png")

func build_map(gm: GridManager) -> void:
	grid_manager = gm
	tile_size = gm.tile_size
	rng.randomize()

	for node in spawned_nodes:
		if is_instance_valid(node):
			node.queue_free()
	spawned_nodes.clear()

	queue_redraw()
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

	# 2. MAP 1 FLOOR: VOLCANIC ASH WILDERNESS & SANCTUARY (y = 17 .. 55)
	if ground_wilderness_tex:
		draw_texture_rect(ground_wilderness_tex, Rect2(0, split_y * ts, w * ts, (h - split_y) * ts), true)
	else:
		draw_rect(Rect2(0, split_y * ts, w * ts, (h - split_y) * ts), Color("#201c1c"), true)

	# 3. ROYAL RED CARPET LEADING TO THRONE (Center x = 24..27)
	var carpet_x = 24.0 * ts
	var carpet_w = 4.0 * ts
	var carpet_y = 3.0 * ts
	var carpet_h = (split_y - 3.0) * ts
	draw_rect(Rect2(carpet_x, carpet_y, carpet_w, carpet_h), Color(0.55, 0.06, 0.10, 0.70), true)
	draw_line(Vector2(carpet_x, carpet_y), Vector2(carpet_x, carpet_y + carpet_h), Color(0.90, 0.75, 0.22, 0.85), 2.5)
	draw_line(Vector2(carpet_x + carpet_w, carpet_y), Vector2(carpet_x + carpet_w, carpet_y + carpet_h), Color(0.90, 0.75, 0.22, 0.85), 2.5)

	# 4. PAVED ROADWAYS ("KAYA ASPAL / JEMBATAN KE JALAN TERSEBUT")
	# A. Jalur Utama (Safe Cobblestone Paving - West & East)
	var safe_road_col = Color(0.18, 0.16, 0.22, 0.88)
	var safe_kerb_col = Color(0.42, 0.38, 0.52, 0.90)

	# West Highway:
	draw_rect(Rect2(6.0 * ts, 20.0 * ts, 4.0 * ts, 23.0 * ts), safe_road_col, true)
	draw_rect(Rect2(6.0 * ts, 20.0 * ts, 4.0 * ts, 23.0 * ts), safe_kerb_col, false, 2.0)
	draw_rect(Rect2(10.0 * ts, 20.0 * ts, 14.0 * ts, 2.0 * ts), safe_road_col, true)
	draw_rect(Rect2(6.0 * ts, 41.0 * ts, 19.0 * ts, 2.0 * ts), safe_road_col, true)

	# East Highway:
	draw_rect(Rect2(42.0 * ts, 20.0 * ts, 4.0 * ts, 23.0 * ts), safe_road_col, true)
	draw_rect(Rect2(42.0 * ts, 20.0 * ts, 4.0 * ts, 23.0 * ts), safe_kerb_col, false, 2.0)
	draw_rect(Rect2(28.0 * ts, 20.0 * ts, 14.0 * ts, 2.0 * ts), safe_road_col, true)
	draw_rect(Rect2(25.0 * ts, 41.0 * ts, 21.0 * ts, 2.0 * ts), safe_road_col, true)

	# Decorative Cobblestone Pavers on Safe Roads
	for py in range(21, 42, 3):
		draw_line(Vector2(6.0 * ts + 2.0, float(py) * ts), Vector2(10.0 * ts - 2.0, float(py) * ts), Color(0.10, 0.08, 0.14, 0.60), 1.5)
		draw_line(Vector2(42.0 * ts + 2.0, float(py) * ts), Vector2(46.0 * ts - 2.0, float(py) * ts), Color(0.10, 0.08, 0.14, 0.60), 1.5)

	# B. Jalur Pintas (Scorched Volcanic Basalt Highway - DIBUAT LEBIH BEDA & BERBAHAYA!)
	var sc_road_col = Color(0.14, 0.06, 0.08, 0.95)
	var sc_kerb_col = Color(0.95, 0.28, 0.08, 0.95)
	draw_rect(Rect2(24.0 * ts, 21.0 * ts, 4.0 * ts, 21.0 * ts), sc_road_col, true)
	draw_rect(Rect2(24.0 * ts, 21.0 * ts, 4.0 * ts, 21.0 * ts), sc_kerb_col, false, 2.0)

	# 5. THE GREAT MOLTEN LAVA RIVER (y = 29 .. 34)
	var river_rect = Rect2(1.0 * ts, float(GridManager.RIVER_Y_START) * ts, (w - 2.0) * ts, float(GridManager.RIVER_Y_END - GridManager.RIVER_Y_START + 1) * ts)
	# Fiery molten underglow
	draw_rect(river_rect, Color(0.95, 0.25, 0.04, 1.0), true)
	draw_rect(river_rect.grow(-3.0), Color(1.0, 0.55, 0.08, 0.90), true)

	# Tiled seamless horizontal grand river texture (zero internal rock stripes!)
	var river_tex_to_use = river_grand_tex if river_grand_tex else river_h_tex
	if river_tex_to_use:
		var tex_w = float(river_tex_to_use.get_width())
		var tex_h = float(river_tex_to_use.get_height())
		var cx = river_rect.position.x
		while cx < river_rect.end.x:
			var seg_w = min(tex_w, river_rect.end.x - cx)
			draw_texture_rect_region(river_tex_to_use, Rect2(cx, river_rect.position.y, seg_w, river_rect.size.y), Rect2(0, 0, seg_w, tex_h))
			cx += tex_w

	draw_rect(river_rect, Color(0.14, 0.08, 0.10, 0.95), false, 2.5)

	# 6. THREE BRIDGES DECKS
	for b in grid_manager.bridges_info:
		_draw_stone_bridge_deck(b)

func _draw_stone_bridge_deck(b: Dictionary) -> void:
	var ts = float(tile_size)
	var bx = float(b.x) * ts
	var by = float(b.y) * ts
	var bw = float(b.w) * ts
	var bh = float(b.h) * ts
	var bname: String = str(b.get("name", ""))

	var is_shortcut: bool = ("Shortcut" in bname or b.x == 24)

	if bridge_stone_tex:
		# Draw textured stone pavers and parapets from modular tileset
		# bridge_stone.png is 128x64 (4x2 tiles of 32x32)
		# (0,0): Normal Pavers, (32,0): Scorched Basalt, (64,0): Top Rail, (96,0): Bottom Rail
		# (0,32): Left Rail, (32,32): Right Rail, (64,32): Spire Pillar, (96,32): Ramp Slope
		var tile_rect = Rect2(32.0, 0.0, 32.0, 32.0) if is_shortcut else Rect2(0.0, 0.0, 32.0, 32.0)
		for dy in range(b.h):
			for dx in range(b.w):
				var px = bx + dx * ts
				var py = by + dy * ts
				var dest_rect = Rect2(px, py, ts, ts)
				draw_texture_rect_region(bridge_stone_tex, dest_rect, tile_rect)
				
				# Edge parapet railings
				if dx == 0:
					draw_texture_rect_region(bridge_stone_tex, dest_rect, Rect2(0.0, 32.0, 32.0, 32.0))
				elif dx == b.w - 1:
					draw_texture_rect_region(bridge_stone_tex, dest_rect, Rect2(32.0, 32.0, 32.0, 32.0))
		
		# Corner spire pillar accents
		var pillar_rect = Rect2(64.0, 32.0, 32.0, 32.0)
		draw_texture_rect_region(bridge_stone_tex, Rect2(bx - 2.0, by, ts, ts), pillar_rect)
		draw_texture_rect_region(bridge_stone_tex, Rect2(bx + bw - ts + 2.0, by, ts, ts), pillar_rect)
		draw_texture_rect_region(bridge_stone_tex, Rect2(bx - 2.0, by + bh - ts, ts, ts), pillar_rect)
		draw_texture_rect_region(bridge_stone_tex, Rect2(bx + bw - ts + 2.0, by + bh - ts, ts, ts), pillar_rect)
	else:
		if is_shortcut:
			# Scorched Volcanic Iron Bridge
			var deck_rect = Rect2(bx - 1.0, by, bw + 2.0, bh)
			draw_rect(deck_rect, Color(0.14, 0.08, 0.10, 1.0), true)
			draw_rect(Rect2(bx + 2.0, by, bw - 4.0, bh), Color(0.20, 0.12, 0.14, 0.95), true)
			draw_line(Vector2(bx, by), Vector2(bx, by + bh), Color(0.85, 0.30, 0.15, 1.0), 4.0)
			draw_line(Vector2(bx + bw, by), Vector2(bx + bw, by + bh), Color(0.85, 0.30, 0.15, 1.0), 4.0)
		else:
			# Sturdy Ancient Stone Viaduct
			var deck_rect = Rect2(bx - 1.0, by, bw + 2.0, bh)
			draw_rect(deck_rect, Color(0.18, 0.16, 0.21, 1.0), true)
			draw_rect(Rect2(bx + 2.0, by, bw - 4.0, bh), Color(0.25, 0.23, 0.29, 0.95), true)
			draw_line(Vector2(bx, by), Vector2(bx, by + bh), Color(0.55, 0.50, 0.62, 1.0), 4.0)
			draw_line(Vector2(bx + bw, by), Vector2(bx + bw, by + bh), Color(0.55, 0.50, 0.62, 1.0), 4.0)

func _spawn_visual_elements() -> void:
	if not grid_manager:
		return

	var w = grid_manager.width
	var h = grid_manager.height
	var ts = float(tile_size)

	# 1. CASTLE FRONT WALL (y = 17..18)
	var wall_base_z = int((GridManager.GATE_Y + 1) * ts)
	for x in range(1, GridManager.CENTER_X - 2, 2):
		var wx = (x + 1.0) * ts
		var wy = (GridManager.WALL_Y_TOP + 1.0) * ts
		_spawn_single_prop(wall_straight_tex, Vector2(wx, wy), 0.25, wall_base_z, Color(1.15, 1.10, 1.20))
	for x in range(GridManager.CENTER_X + 3, w - 3, 2):
		var wx = (x + 1.0) * ts
		var wy = (GridManager.WALL_Y_TOP + 1.0) * ts
		_spawn_single_prop(wall_straight_tex, Vector2(wx, wy), 0.25, wall_base_z, Color(1.15, 1.10, 1.20))

	# Side Wall Towers
	for y in range(1, GridManager.WALL_Y_TOP, 3):
		var tw_z = int((y + 2.0) * ts)
		_spawn_single_prop(wall_tower_tex, Vector2(1.5 * ts, (y + 1.0) * ts), 0.25, tw_z, Color(1.10, 1.05, 1.15))
		_spawn_single_prop(wall_tower_tex, Vector2((w - 1.5) * ts, (y + 1.0) * ts), 0.25, tw_z, Color(1.10, 1.05, 1.15))

	# 2. CASTLE OBSIDIAN PILLARS
	for pos in grid_manager.castle_pillar_positions:
		if pos.y % 2 == 0:
			var pil_z = int((pos.y + 2.0) * ts)
			_spawn_shadow(Vector2((pos.x + 0.5) * ts, (pos.y + 1.85) * ts), Vector2(0.55, 0.25))
			_spawn_single_prop(wall_pillar_tex, Vector2((pos.x + 0.5) * ts, (pos.y + 0.95) * ts), 0.25, pil_z, Color(1.20, 1.05, 1.05))

	# 3. RIVERBANK WATCHTOWERS & LOW WALLS
	var r_top_z = int(GridManager.RIVER_Y_START * ts)
	var r_bot_z = int((GridManager.RIVER_Y_END + 2) * ts)
	for bx in [5, 10, 23, 28, 41, 46]:
		_spawn_single_prop(wall_tower_tex, Vector2((bx + 0.5) * ts, (GridManager.RIVER_Y_START - 0.2) * ts), 0.22, r_top_z, Color(1.10, 1.05, 1.15))
		_spawn_single_prop(wall_tower_tex, Vector2((bx + 0.5) * ts, (GridManager.RIVER_Y_END + 1.5) * ts), 0.22, r_bot_z, Color(1.10, 1.05, 1.15))

	# 4. CHARRED TREES IN WILDERNESS FLANKS
	for tp in grid_manager.tree_positions:
		var tx = (tp.x + 0.5) * ts
		var base_z = int((tp.y + 1.0) * ts)
		_spawn_shadow(Vector2(tx, (tp.y + 1.0) * ts - 6.0), Vector2(0.75, 0.35))
		_spawn_single_prop(tree_large_tex, Vector2(tx, (tp.y + 1.0) * ts - 56.0), 0.65, base_z, Color(1.20, 1.12, 1.06))

	# 5. ROCKS AND BOULDERS
	for rp in grid_manager.rock_positions:
		var rx = (rp.x + 0.5) * ts
		var base_z = int((rp.y + 1.0) * ts)
		_spawn_shadow(Vector2(rx, (rp.y + 1.0) * ts - 4.0), Vector2(0.55, 0.28))
		_spawn_single_prop(rock_large_tex, Vector2(rx, (rp.y + 1.0) * ts - 24.0), 0.42, base_z, Color(1.15, 1.10, 1.05))

	# 6. GLOWING ELEMENTAL CRYSTALS
	for cp in grid_manager.crystal_positions:
		var cx = (cp.x + 0.5) * ts
		var base_z = int((cp.y + 1.0) * ts)
		_spawn_shadow(Vector2(cx, (cp.y + 1.0) * ts - 4.0), Vector2(0.44, 0.22))
		_spawn_single_prop(crystal_large_tex, Vector2(cx, (cp.y + 1.0) * ts - 18.0), 0.46, base_z, Color(1.25, 1.18, 1.10))

	# 7. PERIMETER CLIFF ROCKS
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
