class_name FrontierVisualizer
extends Node2D

var explored_nodes: Array[Vector2i] = []
var tile_size: int = 32
var frontier_color: Color = Color(1.0, 0.82, 0.4, 0.35) # Translucent soul-yellow #ffd166

func set_explored_nodes(nodes: Array[Vector2i]) -> void:
	explored_nodes = nodes
	queue_redraw()

func _draw() -> void:
	for gp in explored_nodes:
		var rect = Rect2(gp.x * tile_size + 2, gp.y * tile_size + 2, tile_size - 4, tile_size - 4)
		draw_rect(rect, frontier_color, true)
