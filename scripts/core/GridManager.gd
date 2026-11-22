class_name GridManager
extends Node

## Manages grid data, tile classification, pathfinding queries,
## and Expanded 52x56 Layout for Infernal Affairs Tahap 4:
##   - Map 2: Grand Obsidian Castle & Boss Throne (North, y=1..16).
##   - Zone 2: Fortified Gate & Courtyard (y=17..20).
##   - River Zone (y=29..34): Grand Molten Lava River spanned by 3 Strategic Bridges:
##       * 1 Central Shortcut Bridge (x=24..27, y=29..34) with periodic stochastic magma hazards.
##       * 2 Outer Safe Bridges (West x=6..9, East x=42..45) that are 100% hazard-free.
##   - Distinct Paved Roadways: Sturdy slate paver highway for Jalur Utama vs scorched volcanic basalt for Jalur Pintas.
##   - Rich Wilderness Obstacles: Trees, rocks, crystals, and watchtowers.
##   - South Zone (y=42..54): Dedicated Sacred Well Sanctuary (Area Sumur & Altar Elemen).

signal grid_updated

enum TileType {
	GROUND = 0,    # Walkable terrain / paved highway
	OBSTACLE = 1,  # Fortified walls / boulders / crystals / pillars / trees
	LAVA = 2,      # Molten liquid lava (impassable)
	BRIDGE = 3     # Stone crossings over lava (walkable)
}

# MAP DIMENSIONS: 52 x 56 tiles (1664 x 1792 px)
@export var width: int = 52
@export var height: int = 56
@export var tile_size: int = 32

var grid: Array = []

# Symmetry Axis
const CENTER_X: int = 25

# Key Vertical Zones
const THRONE_Y: int = 2
const BOSS_Y: int = 4
const CASTLE_Y_MAX: int = 16

const WALL_Y_TOP: int = 17
const GATE_Y: int = 18
const COURTYARD_Y: int = 20
const ZONE_WILDERNESS_Y_MIN: int = 21

const RIVER_Y_START: int = 29
const RIVER_Y_END: int = 34
const SANCTUARY_Y_START: int = 41

# Feature records for ArenaMap visual renderer
var bridge_positions: Array[Vector2i] = []
var bridges_info: Array[Dictionary] = []
var tree_positions: Array[Vector2i] = []
var rock_positions: Array[Vector2i] = []
var crystal_positions: Array[Vector2i] = []
var castle_wall_positions: Array[Vector2i] = []
var castle_pillar_positions: Array[Vector2i] = []

func _ready() -> void:
	generate_new_map()

# -------------------------------------------------------------
# TAHAP 4 MAP GENERATOR (RIVER & 3 BRIDGES)
# -------------------------------------------------------------
func generate_new_map() -> void:
	grid.clear()
	bridge_positions.clear()
	bridges_info.clear()
	tree_positions.clear()
	rock_positions.clear()
	crystal_positions.clear()
	castle_wall_positions.clear()
	castle_pillar_positions.clear()

	# 1. Initialize map as GROUND
	for y in range(height):
		var row: Array[int] = []
		for x in range(width):
			row.append(TileType.GROUND)
		grid.append(row)

	# 2. Outer Border Walls (Solid Perimeter)
	for x in range(width):
		grid[0][x] = TileType.OBSTACLE
		grid[height - 1][x] = TileType.OBSTACLE
	for y in range(height):
		grid[y][0] = TileType.OBSTACLE
		grid[y][width - 1] = TileType.OBSTACLE

	# 3. MAP 2 (CASTLE): SIDE WALLS & OBSIDIAN PILLARS (y = 1 .. 16)
	for cy in range(1, WALL_Y_TOP):
		grid[cy][1] = TileType.OBSTACLE
		grid[cy][2] = TileType.OBSTACLE
		grid[cy][width - 2] = TileType.OBSTACLE
		grid[cy][width - 3] = TileType.OBSTACLE
		castle_wall_positions.append(Vector2i(1, cy))
		castle_wall_positions.append(Vector2i(2, cy))
		castle_wall_positions.append(Vector2i(width - 2, cy))
		castle_wall_positions.append(Vector2i(width - 3, cy))

	# Majestic pillars in Boss Throne Chamber
	var pillar_cols = [10, 16, 35, 41]
	var pillar_rows = [6, 10, 14]
	for py in pillar_rows:
		for px in pillar_cols:
			if in_bounds(px, py):
				grid[py][px] = TileType.OBSTACLE
				grid[py + 1][px] = TileType.OBSTACLE
				castle_pillar_positions.append(Vector2i(px, py))
				castle_pillar_positions.append(Vector2i(px, py + 1))

	# Throne Ceremony Area (x=23..27, y=1..5) is always pristine
	for ty in range(1, 6):
		for tx in range(CENTER_X - 2, CENTER_X + 3):
			if in_bounds(tx, ty):
				grid[ty][tx] = TileType.GROUND

	# 4. ZONE 2: FORTIFIED CASTLE FRONT WALL (y = 17..18) & CENTER GATE (x = 24..27)
	for wy in range(WALL_Y_TOP, GATE_Y + 1):
		for x in range(1, width - 1):
			if x in [24, 25, 26, 27]:
				if GameState.gate_is_open:
					grid[wy][x] = TileType.GROUND
				else:
					grid[wy][x] = TileType.OBSTACLE
			else:
				grid[wy][x] = TileType.OBSTACLE
				castle_wall_positions.append(Vector2i(x, wy))

	# 5. THE GREAT MOLTEN LAVA RIVER (y = 29 .. 34)
	for ry in range(RIVER_Y_START, RIVER_Y_END + 1):
		for rx in range(1, width - 1):
			grid[ry][rx] = TileType.LAVA

	# 6. THREE STRATEGIC STONE BRIDGES (TileType.BRIDGE)
	# Bridge West Safe: x = 6..9, y = 29..34
	_build_bridge(6, RIVER_Y_START, 4, (RIVER_Y_END - RIVER_Y_START + 1), "West Safe Bridge")
	# Bridge East Safe: x = 42..45, y = 29..34
	_build_bridge(42, RIVER_Y_START, 4, (RIVER_Y_END - RIVER_Y_START + 1), "East Safe Bridge")
	# Bridge Center Shortcut: x = 24..27, y = 29..34 (Hazard Bridge)
	_build_bridge(24, RIVER_Y_START, 4, (RIVER_Y_END - RIVER_Y_START + 1), "Central Shortcut Bridge")

	# 7. RIVERBANK FORTRESS PARAPETS (LOW WALLS GUIDING TO BRIDGES)
	for py in [RIVER_Y_START - 1, RIVER_Y_END + 1]:
		for px in range(2, width - 2):
			# Leave bridge entrances open
			if px not in [5, 6, 7, 8, 9, 10, 23, 24, 25, 26, 27, 28, 41, 42, 43, 44, 45, 46]:
				grid[py][px] = TileType.OBSTACLE

	# 8. CURATED RICH WILDERNESS OBSTACLES (ROCKS, TREES, CRYSTALS)
	_place_curated_wilderness_assets()

	# 9. CONNECTIVITY GUARANTEE
	_ensure_connectivity()

	grid_updated.emit()

func _build_bridge(start_x: int, start_y: int, w: int, h: int, bridge_name: String) -> void:
	for dy in range(h):
		for dx in range(w):
			var cx = start_x + dx
			var cy = start_y + dy
			if in_bounds(cx, cy):
				grid[cy][cx] = TileType.BRIDGE
				bridge_positions.append(Vector2i(cx, cy))

	bridges_info.append({
		"x": start_x,
		"y": start_y,
		"w": w,
		"h": h,
		"name": bridge_name
	})

func _place_curated_wilderness_assets() -> void:
	# Charred Trees in open wilderness flanks
	var trees = [
		Vector2i(3, 24), Vector2i(12, 25), Vector2i(15, 22),
		Vector2i(36, 22), Vector2i(39, 25), Vector2i(48, 24),
		Vector2i(3, 37), Vector2i(13, 38), Vector2i(38, 38), Vector2i(48, 37)
	]
	for t in trees:
		if in_bounds(t.x, t.y) and grid[t.y][t.x] == TileType.GROUND:
			grid[t.y][t.x] = TileType.OBSTACLE
			tree_positions.append(t)

	# Boulders and Rock Formations
	var rocks = [
		Vector2i(18, 24), Vector2i(32, 24), Vector2i(18, 38), Vector2i(32, 38),
		Vector2i(14, 27), Vector2i(37, 27), Vector2i(14, 36), Vector2i(37, 36),
		Vector2i(2, 44), Vector2i(49, 44)
	]
	for r in rocks:
		if in_bounds(r.x, r.y) and grid[r.y][r.x] == TileType.GROUND:
			grid[r.y][r.x] = TileType.OBSTACLE
			rock_positions.append(r)

	# Glowing Crystals
	var crystals = [
		Vector2i(16, 26), Vector2i(35, 26), Vector2i(16, 37), Vector2i(35, 37),
		Vector2i(20, 26), Vector2i(31, 26), Vector2i(20, 37), Vector2i(31, 37),
		Vector2i(4, 48), Vector2i(47, 48)
	]
	for c in crystals:
		if in_bounds(c.x, c.y) and grid[c.y][c.x] == TileType.GROUND:
			grid[c.y][c.x] = TileType.OBSTACLE
			crystal_positions.append(c)

# -------------------------------------------------------------
# FLOOD-FILL CONNECTIVITY GUARANTEE
# -------------------------------------------------------------
func _ensure_connectivity() -> void:
	var anchor = Vector2i(CENTER_X, COURTYARD_Y)
	var queue: Array[Vector2i] = [anchor]
	var visited: Dictionary = {anchor: true}

	var dirs = [Vector2i(0, -1), Vector2i(1, 0), Vector2i(0, 1), Vector2i(-1, 0)]
	while not queue.is_empty():
		var curr = queue.pop_front()
		for d in dirs:
			var nx = curr.x + d.x
			var ny = curr.y + d.y
			if in_bounds(nx, ny):
				var cell = Vector2i(nx, ny)
				if not visited.has(cell) and (grid[ny][nx] == TileType.GROUND or grid[ny][nx] == TileType.BRIDGE):
					visited[cell] = true
					queue.append(cell)

	for y in range(WALL_Y_TOP + 1, height - 1):
		for x in range(1, width - 1):
			if (grid[y][x] == TileType.GROUND or grid[y][x] == TileType.BRIDGE) and not visited.has(Vector2i(x, y)):
				grid[y][x] = TileType.OBSTACLE

# -------------------------------------------------------------
# NAVIGATION & VALIDATION QUERIES
# -------------------------------------------------------------
func in_bounds(x: int, y: int) -> bool:
	return x >= 0 and x < width and y >= 0 and y < height

func is_walkable(x: int, y: int) -> bool:
	if not in_bounds(x, y):
		return false
	var t = grid[y][x]
	return t == TileType.GROUND or t == TileType.BRIDGE

func is_valid(x: int, y: int) -> bool:
	return is_walkable(x, y)

func get_neighbors(pos: Vector2i) -> Array[Dictionary]:
	var neighbors: Array[Dictionary] = []
	var dirs = [Vector2i(0, -1), Vector2i(1, 0), Vector2i(0, 1), Vector2i(-1, 0)]
	for d in dirs:
		var nx = pos.x + d.x
		var ny = pos.y + d.y
		if is_valid(nx, ny):
			neighbors.append({"pos": Vector2i(nx, ny), "cost": 1.0})
	return neighbors

func grid_to_world(grid_pos: Vector2i) -> Vector2:
	return Vector2(grid_pos.x * tile_size + tile_size / 2.0, grid_pos.y * tile_size + tile_size / 2.0)

func world_to_grid(world_pos: Vector2) -> Vector2i:
	return Vector2i(int(world_pos.x / tile_size), int(world_pos.y / tile_size))

# -------------------------------------------------------------
# SPAWN POINTS
# -------------------------------------------------------------
func get_player_start_pos() -> Vector2i:
	return Vector2i(CENTER_X, 45)

func get_demon_start_pos() -> Vector2i:
	return Vector2i(CENTER_X, BOSS_Y)

func get_random_wilderness_pos() -> Vector2i:
	var candidates: Array[Vector2i] = []
	for y in range(SANCTUARY_Y_START + 1, height - 2):
		for x in range(4, width - 4):
			if is_walkable(x, y):
				candidates.append(Vector2i(x, y))
	if candidates.size() > 0:
		return candidates[randi() % candidates.size()]
	return get_player_start_pos()

func get_random_walkable_pos() -> Vector2i:
	var valid_positions: Array[Vector2i] = []
	for y in range(height):
		for x in range(width):
			if is_walkable(x, y):
				valid_positions.append(Vector2i(x, y))
	if valid_positions.size() > 0:
		return valid_positions[randi() % valid_positions.size()]
	return Vector2i(CENTER_X, height - 4)
