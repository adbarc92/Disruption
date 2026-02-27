class_name GridPathfinder
extends RefCounted
## GridPathfinder - A* pathfinding and BFS flood fill for combat grid
## Pure logic, no engine dependencies

## Range Bands - Simplified distance categories for targeting
enum RangeBand {
	MELEE = 0,    # Adjacent (1 space)
	CLOSE = 1,    # Nearby (2-3 spaces)
	DISTANT = 2   # Far (4+ spaces)
}


## Find shortest path from start to end using A* with hex distance heuristic
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
	var f_score: Dictionary = {start: hex_distance(start, end)}

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

		# Check hex neighbors
		var neighbors = _get_neighbors(current, grid_size)
		for neighbor in neighbors:
			# Occupied cells are impassable (except destination)
			if neighbor != end and grid.has(neighbor):
				continue

			var tentative_g = g_score.get(current, 999999) + 1

			if tentative_g < g_score.get(neighbor, 999999):
				came_from[neighbor] = current
				g_score[neighbor] = tentative_g
				f_score[neighbor] = tentative_g + hex_distance(neighbor, end)

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


## Convert offset coordinates (col, row) to axial coordinates (q, r)
static func offset_to_axial(pos: Vector2i) -> Vector2i:
	var q = pos.x - (pos.y - (pos.y & 1)) / 2
	var r = pos.y
	return Vector2i(q, r)


## Calculate hex distance between two offset-coordinate positions
## Uses cube coordinate distance: (|dq| + |dq+dr| + |dr|) / 2
static func hex_distance(a: Vector2i, b: Vector2i) -> int:
	var ax = offset_to_axial(a)
	var bx = offset_to_axial(b)
	var dq = ax.x - bx.x
	var dr = ax.y - bx.y
	return (abs(dq) + abs(dq + dr) + abs(dr)) / 2


## Deprecated: use hex_distance instead. Kept for any external callers.
static func manhattan_distance(a: Vector2i, b: Vector2i) -> int:
	return hex_distance(a, b)


## Get range band from distance value
static func get_range_band(distance: int) -> RangeBand:
	if distance <= 1:
		return RangeBand.MELEE
	elif distance <= 3:
		return RangeBand.CLOSE
	else:
		return RangeBand.DISTANT


## Get range band between two positions
static func get_range_band_between(pos_a: Vector2i, pos_b: Vector2i) -> RangeBand:
	var dist = hex_distance(pos_a, pos_b)
	return get_range_band(dist)


## Convert range band enum to string
static func range_band_to_string(band: RangeBand) -> String:
	match band:
		RangeBand.MELEE:
			return "melee"
		RangeBand.CLOSE:
			return "close"
		RangeBand.DISTANT:
			return "distant"
		_:
			return "unknown"


## Convert string to range band enum
static func string_to_range_band(band_str: String) -> RangeBand:
	match band_str.to_lower():
		"melee", "m":
			return RangeBand.MELEE
		"close", "c":
			return RangeBand.CLOSE
		"distant", "d", "far":
			return RangeBand.DISTANT
		_:
			return RangeBand.MELEE  # Default fallback


## Check if a target is within the specified range band
## Returns true if target distance is within or closer than the max_band
static func is_within_range_band(user_pos: Vector2i, target_pos: Vector2i, max_band: RangeBand) -> bool:
	var actual_band = get_range_band_between(user_pos, target_pos)
	return actual_band <= max_band


## Check if two positions are adjacent (hex distance == 1)
static func is_adjacent(a: Vector2i, b: Vector2i) -> bool:
	return hex_distance(a, b) == 1


## Get hex neighbors within grid bounds (pointy-top, odd-row offset)
static func _get_neighbors(pos: Vector2i, grid_size: Vector2i) -> Array[Vector2i]:
	var neighbors: Array[Vector2i] = []

	# Offsets differ based on row parity (odd rows shift right)
	var even_row_offsets = [
		Vector2i(+1, 0), Vector2i(-1, 0),   # E, W
		Vector2i(0, -1), Vector2i(+1, -1),  # NW, NE
		Vector2i(0, +1), Vector2i(+1, +1),  # SW, SE
	]
	var odd_row_offsets = [
		Vector2i(+1, 0), Vector2i(-1, 0),   # E, W
		Vector2i(-1, -1), Vector2i(0, -1),  # NW, NE
		Vector2i(-1, +1), Vector2i(0, +1),  # SW, SE
	]

	var offsets = odd_row_offsets if (pos.y & 1) else even_row_offsets

	for offset in offsets:
		var candidate = pos + offset
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
