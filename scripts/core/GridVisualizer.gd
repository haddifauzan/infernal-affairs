class_name GridVisualizer
extends Node2D

@export var grid_manager_path: NodePath
var grid_manager: GridManager

# Warna inferno sesuai spesifikasi README.md
var floor_color: Color = Color("#1e1e24") # Walkable abu gelap
var grid_line_color: Color = Color("#2e1824") # Garis petak retakan samar
var wall_color: Color = Color("#0d0d11") # Obsidian wall hitam pekat
var lava_border_color: Color = Color("#ff4d00") # Aksen lava oranye-merah

func _ready() -> void:
	if has_node(grid_manager_path):
		grid_manager = get_node(grid_manager_path) as GridManager
	elif get_parent().has_node("GridManager"):
		grid_manager = get_parent().get_node("GridManager") as GridManager

func _draw() -> void:
	if not grid_manager or grid_manager.grid.is_empty():
		return
		
	var ts = grid_manager.tile_size
	var w = grid_manager.width
	var h = grid_manager.height
	
	# Background dasar lantai arena
	draw_rect(Rect2(0, 0, w * ts, h * ts), floor_color, true)
	
	for y in range(h):
		for x in range(w):
			var rect = Rect2(x * ts, y * ts, ts, ts)
			# Garis petak tipis
			draw_rect(rect, grid_line_color, false, 1.0)
			
			if y < grid_manager.grid.size() and x < grid_manager.grid[y].size():
				if grid_manager.grid[y][x] == 1:
					# Petak rintangan (Obsidian Wall / Lava)
					draw_rect(rect, wall_color, true)
					draw_rect(Rect2(x * ts + 2, y * ts + 2, ts - 4, ts - 4), lava_border_color, false, 1.5)
