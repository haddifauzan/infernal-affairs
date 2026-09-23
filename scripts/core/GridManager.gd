class_name GridManager
extends Node

signal grid_updated

enum TileType {
	GROUND = 0,    # Daratan vulkanik yang bisa dilewati
	OBSTACLE = 1,  # Dinding tebing / batu / kristal / pohon
	LAVA = 2,      # Sungai & kawah lava pijar (tidak bisa dilewati)
	BRIDGE = 3     # Jembatan penyeberangan di atas lava (bisa dilewati)
}

# UKURAN PETA: 44 x 28 petak (1408 x 896 piksel)
@export var width: int = 44
@export var height: int = 28
@export var tile_size: int = 32

var grid: Array = []

# Data struktur sungai & jembatan untuk renderer
var bridge_positions: Array[Vector2i] = []
var bridges_info: Array[Dictionary] = []
var pool_centers: Array[Vector2i] = []
var tree_positions: Array[Vector2i] = []

# Koordinat Ngarai Sungai Lava U-Shape
# Sungai Barat: x in [13, 14], y in [1..18]
# Sungai Bawah: x in [15..28], y in [19, 20]
# Sungai Timur: x in [29, 30], y in [1..18]
const RIVER_WEST_X: int = 13
const RIVER_EAST_X: int = 29
const RIVER_BOT_Y: int  = 19

func _ready() -> void:
	generate_new_map()

# -------------------------------------------------------------
# GENERATOR PETA CANYON DENGAN SUNGAI LAVA & 5 JEMBATAN
# -------------------------------------------------------------
func generate_new_map() -> void:
	grid.clear()
	bridge_positions.clear()
	bridges_info.clear()
	pool_centers.clear()

	# 1. Alas Daratan Penuh (GROUND)
	for y in range(height):
		var row: Array[int] = []
		for x in range(width):
			row.append(TileType.GROUND)
		grid.append(row)

	# 2. Dinding Tebing Batu Keliling Gua
	for x in range(width):
		grid[0][x] = TileType.OBSTACLE
		grid[height - 1][x] = TileType.OBSTACLE
	for y in range(height):
		grid[y][0] = TileType.OBSTACLE
		grid[y][width - 1] = TileType.OBSTACLE

	# Lekukan sudut tebing
	var corners = [
		[Vector2i(1, 1), Vector2i(2, 1), Vector2i(1, 2)],
		[Vector2i(width - 2, 1), Vector2i(width - 3, 1), Vector2i(width - 2, 2)],
		[Vector2i(1, height - 2), Vector2i(2, height - 2), Vector2i(1, height - 3)],
		[Vector2i(width - 2, height - 2), Vector2i(width - 3, height - 2), Vector2i(width - 2, height - 3)]
	]
	for c_group in corners:
		for pt in c_group:
			if randf() < 0.6:
				grid[pt.y][pt.x] = TileType.OBSTACLE

	# 3. Pahat Ngarai Sungai Lava U-Shape Mengitari Pulau Tengah
	# a. Sungai Barat (x=13..14, y=1..18)
	for y in range(1, RIVER_BOT_Y):
		grid[y][RIVER_WEST_X]     = TileType.LAVA
		grid[y][RIVER_WEST_X + 1] = TileType.LAVA

	# b. Sudut Bawah-Kiri (x=13..14, y=19..20)
	grid[RIVER_BOT_Y][RIVER_WEST_X]         = TileType.LAVA
	grid[RIVER_BOT_Y][RIVER_WEST_X + 1]     = TileType.LAVA
	grid[RIVER_BOT_Y + 1][RIVER_WEST_X]     = TileType.LAVA
	grid[RIVER_BOT_Y + 1][RIVER_WEST_X + 1] = TileType.LAVA

	# c. Sungai Bawah Horizontal (x=15..28, y=19..20)
	for x in range(RIVER_WEST_X + 2, RIVER_EAST_X):
		grid[RIVER_BOT_Y][x]     = TileType.LAVA
		grid[RIVER_BOT_Y + 1][x] = TileType.LAVA

	# d. Sudut Bawah-Kanan (x=29..30, y=19..20)
	grid[RIVER_BOT_Y][RIVER_EAST_X]         = TileType.LAVA
	grid[RIVER_BOT_Y][RIVER_EAST_X + 1]     = TileType.LAVA
	grid[RIVER_BOT_Y + 1][RIVER_EAST_X]     = TileType.LAVA
	grid[RIVER_BOT_Y + 1][RIVER_EAST_X + 1] = TileType.LAVA

	# e. Sungai Timur (x=29..30, y=1..18)
	for y in range(1, RIVER_BOT_Y):
		grid[y][RIVER_EAST_X]     = TileType.LAVA
		grid[y][RIVER_EAST_X + 1] = TileType.LAVA

	# 4. Pasang 5 Jembatan Strategis Melintasi Sungai
	# - West Bridge 1: Utara-Barat (y=6..7)
	# - West Bridge 2: Selatan-Barat (y=13..14)
	# - East Bridge 1: Utara-Timur (y=6..7)
	# - East Bridge 2: Selatan-Timur (y=13..14)
	# - South Bridge:  Tengah-Selatan (x=21..22, y=19..20)
	_build_bridge(RIVER_WEST_X, 6, 2, 2, "horizontal")
	_build_bridge(RIVER_WEST_X, 13, 2, 2, "horizontal")
	_build_bridge(RIVER_EAST_X, 6, 2, 2, "horizontal")
	_build_bridge(RIVER_EAST_X, 13, 2, 2, "horizontal")
	_build_bridge(21, RIVER_BOT_Y, 2, 2, "vertical")

	# 5. Pasang 2 Kawah Lava Bulat Alami (Sayap Barat & Sayap Timur)
	_place_lava_pools()

	# 6. Pasang Kluster Reruntuhan Kuno
	_place_ruin_clusters()

	# 7. Pasang Rintangan Pohon Neraka di Area Terbuka Secukupnya
	_place_scattered_trees()

	# 8. Verifikasi Konektivitas Penuh (Flood Fill)
	_ensure_connectivity()

	grid_updated.emit()

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

	# Pastikan jalan masuk dan keluar jembatan bersih dari rintangan
	if orientation == "horizontal":
		for dy in range(h):
			var cy = start_y + dy
			for offset in [-2, -1, w, w + 1]:
				var cx = start_x + offset
				if in_bounds(cx, cy) and grid[cy][cx] != TileType.LAVA:
					grid[cy][cx] = TileType.GROUND
	else:
		for dx in range(w):
			var cx = start_x + dx
			for offset in [-2, -1, h, h + 1]:
				var cy = start_y + offset
				if in_bounds(cx, cy) and grid[cy][cx] != TileType.LAVA:
					grid[cy][cx] = TileType.GROUND

# -------------------------------------------------------------
# PENEMPATAN KAWAH LAVA ALAMI
# -------------------------------------------------------------
func _place_lava_pools() -> void:
	# Kawah Barat
	var p_west = Vector2i(randi_range(5, 7), randi_range(9, 12))
	# Kawah Timur
	var p_east = Vector2i(randi_range(35, 37), randi_range(9, 12))

	pool_centers = [p_west, p_east]

	for pc in pool_centers:
		for dy in [0, 1]:
			for dx in [0, 1]:
				var cx = pc.x + dx
				var cy = pc.y + dy
				if in_bounds(cx, cy):
					grid[cy][cx] = TileType.LAVA

# -------------------------------------------------------------
# KLUSTER RERUNTUHAN KUIL & KRISTAL
# -------------------------------------------------------------
func _place_ruin_clusters() -> void:
	var templates = [
		[Vector2i(0, 0), Vector2i(1, 0), Vector2i(0, 1)], # L-shape
		[Vector2i(0, 0), Vector2i(1, 0), Vector2i(2, 0)], # Dinding 3 petak
		[Vector2i(0, 0), Vector2i(0, 1), Vector2i(0, 2)], # Pilar vertikal
		[Vector2i(0, 0), Vector2i(1, 0)],                # Pilar kembar
		[Vector2i(0, 0)]                                 # Batu monolit
	]

	var clusters_to_place = 12
	var attempts = 0

	while clusters_to_place > 0 and attempts < 150:
		attempts += 1
		var template = templates[randi() % templates.size()]
		var ox = randi_range(2, width - 4)
		var oy = randi_range(2, height - 3)

		var can_place = true
		for off in template:
			var cx = ox + off.x
			var cy = oy + off.y

			if not in_bounds(cx, cy) or grid[cy][cx] != TileType.GROUND:
				can_place = false
				break

			# Jangan halangi jembatan
			for bp in bridge_positions:
				if abs(cx - bp.x) + abs(cy - bp.y) <= 2:
					can_place = false
					break

			# Jangan timpa kawah lava
			for pc in pool_centers:
				if abs(cx - pc.x) + abs(cy - pc.y) <= 2:
					can_place = false
					break

			if not can_place:
				break

		if can_place:
			for off in template:
				grid[oy + off.y][ox + off.x] = TileType.OBSTACLE
			clusters_to_place -= 1

# -------------------------------------------------------------
# PENEMPATAN POHON NERAKA DI AREA KOSONG
# -------------------------------------------------------------
func _place_scattered_trees() -> void:
	tree_positions.clear()
	# Tempatkan 6-8 pohon neraka tersebar secara elegan di ruang terbuka
	var trees_to_place = randi_range(6, 8)
	var attempts = 0

	while trees_to_place > 0 and attempts < 120:
		attempts += 1
		var tx = randi_range(3, width - 4)
		var ty = randi_range(3, height - 4)

		# Harus berada di GROUND
		if grid[ty][tx] == TileType.GROUND:
			var valid = true

			# Jangan halangi jembatan (jarak minimal 3 petak)
			for bp in bridge_positions:
				if abs(tx - bp.x) + abs(ty - bp.y) <= 3:
					valid = false
					break

			# Jangan terlalu dekat dengan kawah lava
			if valid:
				for pc in pool_centers:
					if abs(tx - pc.x) + abs(ty - pc.y) <= 3:
						valid = false
						break

			# Jangan menempel ke obstacle lain agar pohon berdiri megah sendiri
			if valid:
				var dirs = [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1),
							Vector2i(1, 1), Vector2i(-1, -1), Vector2i(1, -1), Vector2i(-1, 1)]
				for d in dirs:
					var nx = tx + d.x
					var ny = ty + d.y
					if in_bounds(nx, ny) and grid[ny][nx] == TileType.OBSTACLE:
						valid = false
						break

			if valid:
				grid[ty][tx] = TileType.OBSTACLE
				tree_positions.append(Vector2i(tx, ty))
				trees_to_place -= 1

# -------------------------------------------------------------
# JAMINAN KONEKTIVITAS (FLOOD FILL)
# -------------------------------------------------------------
func _ensure_connectivity() -> void:
	if bridge_positions.is_empty():
		return
	var anchor = bridge_positions[0]
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

	for y in range(height):
		for x in range(width):
			if (grid[y][x] == TileType.GROUND or grid[y][x] == TileType.BRIDGE) and not visited.has(Vector2i(x, y)):
				grid[y][x] = TileType.OBSTACLE

# -------------------------------------------------------------
# NAVIGASI GRID
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
# TITIK SPAWN (PLAYER DI BARAT, DEMON DI TIMUR)
# -------------------------------------------------------------
func get_player_start_pos() -> Vector2i:
	var candidates: Array[Vector2i] = []
	var max_x = RIVER_WEST_X - 3
	for y in range(4, height - 4):
		for x in range(3, max_x):
			if grid[y][x] == TileType.GROUND:
				candidates.append(Vector2i(x, y))
	if candidates.size() > 0:
		return candidates[randi() % candidates.size()]
	return get_random_walkable_pos()

func get_demon_start_pos() -> Vector2i:
	var candidates: Array[Vector2i] = []
	var min_x = RIVER_EAST_X + 3
	for y in range(4, height - 4):
		for x in range(min_x, width - 3):
			if grid[y][x] == TileType.GROUND:
				candidates.append(Vector2i(x, y))
	if candidates.size() > 0:
		return candidates[randi() % candidates.size()]
	return get_random_walkable_pos()

func get_random_walkable_pos() -> Vector2i:
	var valid_positions: Array[Vector2i] = []
	for y in range(height):
		for x in range(width):
			if is_walkable(x, y):
				valid_positions.append(Vector2i(x, y))
	if valid_positions.size() > 0:
		return valid_positions[randi() % valid_positions.size()]
	return Vector2i(4, 4)
