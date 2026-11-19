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
# FULLY CONNECTED LAVA RIVER & CHASM SYSTEM (TAHAP 4 USER SKETCH)
# -------------------------------------------------------------
func _carve_connected_lava_river_system() -> void:
	# Enforce Castle Wall Footing at y = 19 so horizontal passage is strictly via Bridge 'd'
	for x in range(1, width - 1):
		if x != CENTER_X and x != CENTER_X + 1:
			# Keep platform 1 and 2 access
			if x != 5 and x != 6 and x != 37 and x != 38:
				grid[COURTYARD_Y][x] = TileType.OBSTACLE
				castle_wall_positions.append(Vector2i(x, COURTYARD_Y))

	# 1. Outer West Lava: x = 1 .. 4, y = 20 .. 34
	for y in range(20, 35):
		for x in range(1, 5):
			grid[y][x] = TileType.LAVA

	# 2. Inner West Lava Basin: x = 7 .. 20, y = 20 .. 34
	# Note: Bridge 'd' at y = 20..21 will cross over this basin
	for y in range(20, 35):
		for x in range(7, 21):
			grid[y][x] = TileType.LAVA

	# 3. Inner East Lava Basin: x = 23 .. 36, y = 20 .. 34
	# Note: Bridge 'd' at y = 20..21 will cross over this basin
	for y in range(20, 35):
		for x in range(23, 37):
			grid[y][x] = TileType.LAVA

	# 4. Outer East Lava: x = 39 .. 42, y = 20 .. 34
	for y in range(20, 35):
		for x in range(39, width - 1):
			grid[y][x] = TileType.LAVA

	# 5. Clear Safe Paths 'a', Central High Road, and Ground 'c'
	# - Left Path 'a' (Altar 1 to Ground 'c'): x = 5..6, y = 20..34
	for y in range(20, 35):
		for x in [5, 6]:
			grid[y][x] = TileType.GROUND

	# - Central Road (Collection Point 4 to Ground 'c'): x = 21..22, y = 19..34
	for y in range(COURTYARD_Y, 35):
		for x in [21, 22]:
			grid[y][x] = TileType.GROUND

	# - Right Path 'a' (Altar 2 to Ground 'c'): x = 37..38, y = 20..34
	for y in range(20, 35):
		for x in [37, 38]:
			grid[y][x] = TileType.GROUND

	# - Ground 'c' (Entire southern expanse): x = 1 .. 42, y = 35 .. 44
	for y in range(35, height - 1):
		for x in range(1, width - 1):
			grid[y][x] = TileType.GROUND

# -------------------------------------------------------------
# TAHAP 4: 2 DANGEROUS SHORTCUT BRIDGES OVER LAVA (JEMBATAN 'd')
# -------------------------------------------------------------
func _build_all_stone_bridges() -> void:
	# Bridge Left 'd': connects Altar 1 (x=6) to Collection Point 4 (x=21) across West Basin
	# x = 7 .. 20 (w = 14), y = 20 .. 21 (h = 2)
	_build_bridge(7, 20, 14, 2, "horizontal")

	# Bridge Right 'd': connects Collection Point 4 (x=22) to Altar 2 (x=37) across East Basin
	# x = 23 .. 36 (w = 14), y = 20 .. 21 (h = 2)
	_build_bridge(23, 20, 14, 2, "horizontal")

	# Ensure bridge entrances and exits connect cleanly to GROUND
	for b in bridges_info:
		var bx = b.x
		var by = b.y
		var bw = b.w
		var bh = b.h
		# West entrance
		if in_bounds(bx - 1, by):
			for dy in range(bh):
				grid[by + dy][bx - 1] = TileType.GROUND
		# East entrance
		if in_bounds(bx + bw, by):
			for dy in range(bh):
				grid[by + dy][bx + bw] = TileType.GROUND

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
# CURATED LARGE LANDMARK FORMATIONS (GROUND 'c' & FLANKS)
# -------------------------------------------------------------
func _place_curated_wilderness_formations() -> void:
	# Landmarks placed south of Resource 3 (y=38) and in ground 'c' clearings
	# Safe corridor y=35..37 across x=5..38 is left completely unobstructed
	var curated_2x2 = [
		Vector2i(10, 41),
		Vector2i(32, 41),
		Vector2i(2, 38),
		Vector2i(40, 38),
		Vector2i(15, 43),
		Vector2i(27, 43)
	]

	for pos in curated_2x2:
		var bx = pos.x
		var by = pos.y
		for dy in [0, 1]:
			for dx in [0, 1]:
				if in_bounds(bx + dx, by + dy) and grid[by + dy][bx + dx] == TileType.GROUND:
					grid[by + dy][bx + dx] = TileType.OBSTACLE
		obstacles_2x2.append(pos)

# -------------------------------------------------------------
# CURATED STANDALONE PROPS (GROUND 'c' ACCENTS)
# -------------------------------------------------------------
func _place_curated_standalone_props() -> void:
	var curated_1x1 = [
		Vector2i(8, 39),
		Vector2i(34, 39),
		Vector2i(17, 42),
		Vector2i(25, 42)
	]

	for pos in curated_1x1:
		if in_bounds(pos.x, pos.y) and grid[pos.y][pos.x] == TileType.GROUND:
			grid[pos.y][pos.x] = TileType.OBSTACLE
			obstacles_1x1.append(pos)

	# Charred trees placed as atmospheric borders
	var curated_trees = [
		Vector2i(2, 35),
		Vector2i(41, 35),
		Vector2i(6, 42),
		Vector2i(37, 42),
		Vector2i(12, 44),
		Vector2i(30, 44)
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
