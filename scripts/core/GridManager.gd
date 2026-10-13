class_name GridManager
extends Node

## Manages grid data, tile classification, pathfinding queries,
## and Expanded 2-Map 3-Zone layout for Infernal Affairs Tahap 3:
##   Map 1: Wilderness (South, y=22..44) - Fully connected winding river network, 9 stone bridges,
##          and large, neatly composed landmark rock formations & crystal spires.
##   Zone 2: Main river chasm & fortified gate.
##   Map 2: Grand Obsidian Castle & Boss Throne Room (North, y=1..16).

signal grid_updated

enum TileType {
	GROUND = 0,    # Walkable terrain
	OBSTACLE = 1,  # Fortified walls / boulders / crystals / trees / pillars
	LAVA = 2,      # Molten lava river & pools (impassable)
	BRIDGE = 3     # Stone crossings over lava (walkable)
}

# MAP DIMENSIONS: 44 x 46 tiles (1408 x 1472 px)
@export var width: int = 44
@export var height: int = 46
@export var tile_size: int = 32

var grid: Array = []

# Symmetry Axis
const CENTER_X: int = 21

# Vertical Key Zones
const THRONE_Y: int = 2
const BOSS_Y: int = 4
const CASTLE_Y_MAX: int = 16

const WALL_Y_TOP: int = 17
const GATE_Y: int = 18
const COURTYARD_Y: int = 19
const RIVER_Y_START: int = 20
const RIVER_Y_END: int = 21
const ZONE_WILDERNESS_Y_MIN: int = 22

# Map feature records for ArenaMap visual renderer
var bridge_positions: Array[Vector2i] = []
var bridges_info: Array[Dictionary] = []
var tree_positions: Array[Vector2i] = []
var castle_wall_positions: Array[Vector2i] = []
var castle_pillar_positions: Array[Vector2i] = []

# Wilderness obstacles: large landmark formations (2x2) and standalone accents (1x1)
var obstacles_2x2: Array[Vector2i] = []
var obstacles_1x1: Array[Vector2i] = []

func _ready() -> void:
	generate_new_map()

# -------------------------------------------------------------
# 2-MAP WORLD GENERATOR
# -------------------------------------------------------------
func generate_new_map() -> void:
	grid.clear()
	bridge_positions.clear()
	bridges_info.clear()
	tree_positions.clear()
	castle_wall_positions.clear()
	castle_pillar_positions.clear()
	obstacles_2x2.clear()
	obstacles_1x1.clear()

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

	# 3. ZONE 2 & 1: FULLY CONNECTED LAVA RIVER NETWORK
	_carve_connected_lava_river_system()

	# 4. STRATEGIC STONE BRIDGES (9 BRIDGES: 5 Main + 4 Wilderness)
	_build_all_stone_bridges()

	# 5. ZONE 2: FORTIFIED CASTLE FRONT WALL (y = 17..18) & CENTER GATE
	for wy in range(WALL_Y_TOP, GATE_Y + 1):
		for x in range(1, width - 1):
			if x == CENTER_X or x == CENTER_X + 1:
				if GameState.gate_is_open:
					grid[wy][x] = TileType.GROUND
				else:
					grid[wy][x] = TileType.OBSTACLE
			else:
				grid[wy][x] = TileType.OBSTACLE
				castle_wall_positions.append(Vector2i(x, wy))

	# 6. MAP 2 (CASTLE): SIDE WALLS & GRAND OBSIDIAN PILLARS
	for cy in range(1, WALL_Y_TOP):
		grid[cy][1] = TileType.OBSTACLE
		grid[cy][2] = TileType.OBSTACLE
		grid[cy][width - 2] = TileType.OBSTACLE
		grid[cy][width - 3] = TileType.OBSTACLE
		castle_wall_positions.append(Vector2i(1, cy))
		castle_wall_positions.append(Vector2i(2, cy))
		castle_wall_positions.append(Vector2i(width - 2, cy))
		castle_wall_positions.append(Vector2i(width - 3, cy))

	# Majestic 2-tile tall pillars in Boss Throne Chamber
	var pillar_cols = [8, 14, 28, 34]
	var pillar_rows = [6, 10, 14]
	for py in pillar_rows:
		for px in pillar_cols:
			if in_bounds(px, py):
				grid[py][px] = TileType.OBSTACLE
				grid[py + 1][px] = TileType.OBSTACLE
				castle_pillar_positions.append(Vector2i(px, py))
				castle_pillar_positions.append(Vector2i(px, py + 1))

	# Throne Ceremony Area (x=19..24, y=1..5) is always pristine
	for ty in range(1, 6):
		for tx in range(CENTER_X - 2, CENTER_X + 4):
			if in_bounds(tx, ty):
				grid[ty][tx] = TileType.GROUND

	# 7. MAP 1 (WILDERNESS): LARGE, NEAT LANDMARK ROCK FORMATIONS & CRYSTALS
	_place_curated_wilderness_formations()

	# 8. MAP 1 (WILDERNESS): STANDALONE ACCENT ROCKS & TREES
	_place_curated_standalone_props()

	# 9. FLOOD-FILL CONNECTIVITY GUARANTEE
	_ensure_connectivity()

	grid_updated.emit()

# -------------------------------------------------------------
# FULLY CONNECTED LAVA RIVER SYSTEM
# -------------------------------------------------------------
func _carve_connected_lava_river_system() -> void:
	# A. Main River: Spans entire map width (x = 0 .. 43) at y = 20..21
	# Flows in from off-map West and exits off-map East!
	for y in range(RIVER_Y_START, RIVER_Y_END + 1):
		for x in range(width):
			grid[y][x] = TileType.LAVA

	# B. West Connected Tributary:
	# Branches seamlessly south from main river at x = 8..9 from y = 21 down to y = 34
	for y in range(RIVER_Y_START, 35):
		grid[y][8] = TileType.LAVA
		grid[y][9] = TileType.LAVA

	# Curves horizontally West at y = 33..34 and exits out the West map border (x = 0..9)
	for y in [33, 34]:
		for x in range(0, 10):
			grid[y][x] = TileType.LAVA

	# C. East Connected Tributary:
	# Branches seamlessly south from main river at x = 34..35 from y = 21 down to y = 34
	for y in range(RIVER_Y_START, 35):
		grid[y][34] = TileType.LAVA
		grid[y][35] = TileType.LAVA

	# Curves horizontally East at y = 33..34 and exits out the East map border (x = 34..43)
	for y in [33, 34]:
		for x in range(34, width):
			grid[y][x] = TileType.LAVA

# -------------------------------------------------------------
# 9 STONE BRIDGES OVER LAVA
# -------------------------------------------------------------
func _build_all_stone_bridges() -> void:
	# 5 Main Bridges across the Main River Chasm (y = 20..21):
	_build_bridge(4, RIVER_Y_START, 2, 2, "vertical")
	_build_bridge(13, RIVER_Y_START, 2, 2, "vertical")
	_build_bridge(CENTER_X, RIVER_Y_START, 2, 2, "vertical") # Main Imperial Bridge (21..22)
	_build_bridge(29, RIVER_Y_START, 2, 2, "vertical")
	_build_bridge(38, RIVER_Y_START, 2, 2, "vertical")

	# 4 Bridges across the Wilderness Tributaries:
	# - West Tributary Bridge: x = 8..9, y = 27..28
	_build_bridge(8, 27, 2, 2, "vertical")
	# - East Tributary Bridge: x = 34..35, y = 27..28
	_build_bridge(34, 27, 2, 2, "vertical")
	# - West Outgoing River Bridge: x = 4..5, y = 33..34
	_build_bridge(4, 33, 2, 2, "vertical")
	# - East Outgoing River Bridge: x = 38..39, y = 33..34
	_build_bridge(38, 33, 2, 2, "vertical")

	# Ensure entrance and exit access lanes for all bridges are clean GROUND
	for b in bridges_info:
		var bx = b.x
		var by = b.y
		var bw = b.w
		var bh = b.h
		# North approach
		if in_bounds(bx, by - 1):
			for dx in range(bw): grid[by - 1][bx + dx] = TileType.GROUND
		# South approach
		if in_bounds(bx, by + bh):
			for dx in range(bw): grid[by + bh][bx + dx] = TileType.GROUND

func _build_bridge(start_x: int, start_y: int, w: int, h: int, orientation: String) -> void:
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
		"orientation": orientation
	})

# -------------------------------------------------------------
# CURATED LARGE LANDMARK FORMATIONS (2x2, BIG AS ORIGINAL)
# -------------------------------------------------------------
func _place_curated_wilderness_formations() -> void:
	# Deliberate, balanced placement: wide 4+ tile avenues between every landmark
	var curated_2x2 = [
		# Outer West Sector
		Vector2i(3, 25),
		# West-Central Sector (between West River and Center Avenue)
		Vector2i(15, 25),
		Vector2i(12, 31),
		Vector2i(16, 37),
		# East-Central Sector (between Center Avenue and East River)
		Vector2i(27, 25),
		Vector2i(30, 31),
		Vector2i(26, 37),
		# Outer East Sector
		Vector2i(39, 25),
		# Southern Flanks (flanking player spawn at x=21, y=42)
		Vector2i(11, 41),
		Vector2i(31, 41)
	]

	for pos in curated_2x2:
		var bx = pos.x
		var by = pos.y
		# Block all 4 cells solid in grid
		for dy in [0, 1]:
			for dx in [0, 1]:
				if in_bounds(bx + dx, by + dy) and grid[by + dy][bx + dx] == TileType.GROUND:
					grid[by + dy][bx + dx] = TileType.OBSTACLE
		obstacles_2x2.append(pos)

# -------------------------------------------------------------
# CURATED STANDALONE PROPS (1x1 ROCKS & TREES)
# -------------------------------------------------------------
func _place_curated_standalone_props() -> void:
	# Standalone boulders & crystal accents placed in generous clearings
	var curated_1x1 = [
		Vector2i(5, 29),
		Vector2i(14, 35),
		Vector2i(29, 35),
		Vector2i(38, 29),
		Vector2i(18, 29),
		Vector2i(25, 29),
		Vector2i(13, 23),
		Vector2i(30, 23)
	]

	for pos in curated_1x1:
		if in_bounds(pos.x, pos.y) and grid[pos.y][pos.x] == TileType.GROUND:
			grid[pos.y][pos.x] = TileType.OBSTACLE
			obstacles_1x1.append(pos)

	# Charred trees placed as atmospheric natural borders
	var curated_trees = [
		Vector2i(2, 28),
		Vector2i(6, 23),
		Vector2i(17, 23),
		Vector2i(26, 23),
		Vector2i(37, 23),
		Vector2i(41, 28),
		Vector2i(14, 40),
		Vector2i(29, 40)
	]

	for pos in curated_trees:
		if in_bounds(pos.x, pos.y) and grid[pos.y][pos.x] == TileType.GROUND:
			grid[pos.y][pos.x] = TileType.OBSTACLE
			tree_positions.append(pos)

# -------------------------------------------------------------
# FLOOD-FILL CONNECTIVITY GUARANTEE
# -------------------------------------------------------------
func _ensure_connectivity() -> void:
	var anchor = Vector2i(CENTER_X, RIVER_Y_START)
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

	for y in range(ZONE_WILDERNESS_Y_MIN, height - 1):
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
	var preferred = Vector2i(CENTER_X, height - 4)
	if is_walkable(preferred.x, preferred.y):
		return preferred
	for y in range(height - 3, ZONE_WILDERNESS_Y_MIN + 4, -1):
		for x in range(CENTER_X - 3, CENTER_X + 4):
			if is_walkable(x, y):
				return Vector2i(x, y)
	return get_random_walkable_pos()

func get_demon_start_pos() -> Vector2i:
	return Vector2i(CENTER_X, BOSS_Y)

func get_random_wilderness_pos() -> Vector2i:
	var candidates: Array[Vector2i] = []
	for y in range(ZONE_WILDERNESS_Y_MIN + 3, height - 2):
		for x in range(3, width - 3):
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
