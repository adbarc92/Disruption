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


## Get list of enemy unit IDs that would get opportunity attacks along a path
## For each cell in the path (excluding start), check orthogonal neighbors for enemies
## Deduplicated - each enemy only attacks once per move
static func get_opportunity_attackers(path: Array[Vector2i], moving_unit_id: String, all_units: Dictionary, grid: Dictionary) -> Array[String]:
	var attackers: Array[String] = []
	var attacker_set: Dictionary = {}  # For deduplication

	# Determine which side the moving unit is on
	var moving_unit = all_units.get(moving_unit_id, {})
	var moving_is_ally = moving_unit.get("is_ally", true)

	# Skip the first cell (starting position)
	for i in range(1, path.size()):
		var cell = path[i]
		# Check orthogonal neighbors
		var directions = [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]
		for dir in directions:
			var adj = cell + dir
			if grid.has(adj):
				var adj_unit_id = grid[adj]
				if adj_unit_id == moving_unit_id:
					continue
				if attacker_set.has(adj_unit_id):
					continue
				# Only enemies trigger OAs
				var adj_unit = all_units.get(adj_unit_id, {})
				if adj_unit.get("is_ally", true) != moving_is_ally:
					attacker_set[adj_unit_id] = true
					attackers.append(adj_unit_id)

	return attackers


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
