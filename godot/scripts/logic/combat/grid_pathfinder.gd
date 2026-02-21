class_name GridPathfinder
extends RefCounted
## GridPathfinder - A* pathfinding and BFS flood fill for combat grid
## Pure logic, no engine dependencies


## Find shortest path from start to end using A* with Manhattan heuristic
## grid: Dictionary of Vector2i -> unit_id (occupied cells)
## grid_size: Vector2i(columns, rows)
## Returns array of Vector2i positions from start to end (inclusive)
## Occupied cells are impassable except the destination
static func find_path(start: Vector2i, end: Vector2i, grid: Dictionary, grid_size: Vector2i) -> Array[Vector2i]:
	if start == end:
		return [start]

	# A* implementation
	var open_set: Array[Vector2i] = [start]
	var came_from: Dictionary = {}  # Vector2i -> Vector2i
	var g_score: Dictionary = {start: 0}  # Vector2i -> int
	var f_score: Dictionary = {start: manhattan_distance(start, end)}

	while not open_set.is_empty():
		# Find node with lowest f_score
		var current = open_set[0]
		var current_f = f_score.get(current, 999999)
		for node in open_set:
			var f = f_score.get(node, 999999)
			if f < current_f:
				current = node
				current_f = f

		if current == end:
			return _reconstruct_path(came_from, current)

		open_set.erase(current)

		# Check orthogonal neighbors
		var neighbors = _get_neighbors(current, grid_size)
		for neighbor in neighbors:
			# Occupied cells are impassable (except destination)
			if neighbor != end and grid.has(neighbor):
				continue

			var tentative_g = g_score.get(current, 999999) + 1

			if tentative_g < g_score.get(neighbor, 999999):
				came_from[neighbor] = current
				g_score[neighbor] = tentative_g
				f_score[neighbor] = tentative_g + manhattan_distance(neighbor, end)

				if neighbor not in open_set:
					open_set.append(neighbor)

	# No path found
	return []


## Get all cells reachable within movement range using BFS flood fill
## Returns array of Vector2i positions (excludes start position)
static func get_cells_in_range(origin: Vector2i, move_range: int, grid: Dictionary, grid_size: Vector2i) -> Array[Vector2i]:
	var reachable: Array[Vector2i] = []
	var visited: Dictionary = {origin: 0}  # Vector2i -> distance
	var queue: Array = [[origin, 0]]

	while not queue.is_empty():
		var item = queue.pop_front()
		var pos: Vector2i = item[0]
		var dist: int = item[1]

		if dist > 0:
			reachable.append(pos)

		if dist >= move_range:
			continue

		var neighbors = _get_neighbors(pos, grid_size)
		for neighbor in neighbors:
			if visited.has(neighbor):
				continue
			# Can't move through occupied cells
			if grid.has(neighbor):
				continue
			visited[neighbor] = dist + 1
			queue.append([neighbor, dist + 1])

	return reachable


## Calculate Manhattan distance between two grid positions
static func manhattan_distance(a: Vector2i, b: Vector2i) -> int:
	return abs(a.x - b.x) + abs(a.y - b.y)


## Check if two positions are adjacent (Manhattan distance == 1)
static func is_adjacent(a: Vector2i, b: Vector2i) -> bool:
	return manhattan_distance(a, b) == 1


## Get orthogonal neighbors within grid bounds
static func _get_neighbors(pos: Vector2i, grid_size: Vector2i) -> Array[Vector2i]:
	var neighbors: Array[Vector2i] = []
	var directions = [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]

	for dir in directions:
		var candidate = pos + dir
		if candidate.x >= 0 and candidate.x < grid_size.x and candidate.y >= 0 and candidate.y < grid_size.y:
			neighbors.append(candidate)

	return neighbors


## Reconstruct path from came_from map
static func _reconstruct_path(came_from: Dictionary, current: Vector2i) -> Array[Vector2i]:
	var path: Array[Vector2i] = [current]
	while came_from.has(current):
		current = came_from[current]
		path.push_front(current)
	return path
