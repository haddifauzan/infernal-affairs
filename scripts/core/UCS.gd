class_name UCSSearch
extends RefCounted

func search(grid_manager: GridManager, start: Vector2i, goal: Vector2i) -> Dictionary:
	var start_time = Time.get_ticks_usec()
	var frontier = MinHeap.new()
	frontier.push(start, 0.0)
	
	var came_from: Dictionary = {}
	var cost_so_far: Dictionary = {}
	cost_so_far[start] = 0.0
	
	var explored: Array[Vector2i] = []
	var nodes_expanded: int = 0

	while not frontier.is_empty():
		var current = frontier.pop()
		nodes_expanded += 1
		if not explored.has(current):
			explored.append(current)
			
		if current == goal:
			break
			
		for neighbor in grid_manager.get_neighbors(current):
			var new_cost = cost_so_far[current] + neighbor.cost # Uniform cost = 1
			if not cost_so_far.has(neighbor.pos) or new_cost < cost_so_far[neighbor.pos]:
				cost_so_far[neighbor.pos] = new_cost
				frontier.push(neighbor.pos, new_cost) # Tanpa Heuristik
				came_from[neighbor.pos] = current

	var execution_time_ms = (Time.get_ticks_usec() - start_time) / 1000.0
	var path = _reconstruct_path(start, goal, came_from)
	var total_cost = cost_so_far.get(goal, INF)
	
	return {
		"path": path,
		"cost": total_cost,
		"explored": explored,
		"nodes_expanded": nodes_expanded,
		"execution_time_ms": execution_time_ms
	}

func _reconstruct_path(start: Vector2i, goal: Vector2i, came_from: Dictionary) -> Array[Vector2i]:
	var path: Array[Vector2i] = []
	var curr = goal
	if not came_from.has(curr) and curr != start:
		return []
	while curr != start:
		path.append(curr)
		curr = came_from[curr]
	path.append(start)
	path.reverse()
	return path
