class_name PositionValidator
extends RefCounted
## PositionValidator - Validates skill usage and targeting based on grid positions
## No engine dependencies - portable game rules
##
## Grid Layout (per side):
##   Column 0 = Front, Column 1 = Middle, Column 2 = Back
##   Row 0 = Top, Row 1 = Middle, Row 2 = Bottom

const POSITION_FRONT = 0
const POSITION_MIDDLE = 1
const POSITION_BACK = 2


## Check if a skill can be used from the user's current position
static func can_use_skill_from_position(skill: Dictionary, user_position: Vector2i) -> bool:
	var usable_positions = skill.get("usable_positions", ["any"])

	if "any" in usable_positions:
		return true

	var user_column = user_position.x
	return _column_matches_position(user_column, usable_positions)


## Get valid targets for a skill based on targeting rules
## Returns array of unit dictionaries that are valid targets
static func get_valid_targets(skill: Dictionary, user: Dictionary, potential_targets: Array, user_is_ally: bool) -> Array:
	var targeting = skill.get("targeting", {})
	var target_type = targeting.get("type", "single_enemy")
	var target_range = targeting.get("range", "any")
	var target_positions = skill.get("target_positions", ["any"])

	var valid_targets: Array = []

	match target_type:
		"self":
			return [user]
		"single_ally", "all_allies":
			if user_is_ally:
				valid_targets = _filter_by_position(potential_targets, target_positions, true)
			else:
				valid_targets = _filter_by_position(potential_targets, target_positions, false)
		"single_enemy", "all_enemies":
			valid_targets = _filter_by_position(potential_targets, target_positions, true)
		_:
			valid_targets = potential_targets.duplicate()

	# Apply range filtering if needed
	if target_range != "any":
		valid_targets = _filter_by_range(valid_targets, user, target_range)

	return valid_targets


## Check if a target can be hit based on position rules
static func can_target_position(skill: Dictionary, target_position: Vector2i) -> bool:
	var target_positions = skill.get("target_positions", ["any"])

	if "any" in target_positions:
		return true

	var target_column = target_position.x
	return _column_matches_position(target_column, target_positions)


## Get the targeting type for a skill
static func get_targeting_type(skill: Dictionary) -> String:
	var targeting = skill.get("targeting", {})
	return targeting.get("type", "single_enemy")


## Check if skill targets allies
static func targets_allies(skill: Dictionary) -> bool:
	var target_type = get_targeting_type(skill)
	return target_type in ["self", "single_ally", "all_allies"]


## Check if skill targets enemies
static func targets_enemies(skill: Dictionary) -> bool:
	var target_type = get_targeting_type(skill)
	return target_type in ["single_enemy", "all_enemies"]


## Check if skill targets all (no selection needed)
static func targets_all(skill: Dictionary) -> bool:
	var target_type = get_targeting_type(skill)
	return target_type in ["self", "all_allies", "all_enemies"]


## Check if a position name matches a column index
static func _column_matches_position(column: int, position_names: Array) -> bool:
	for pos_name in position_names:
		match pos_name:
			"front":
				if column == POSITION_FRONT:
					return true
			"middle":
				if column == POSITION_MIDDLE:
					return true
			"back":
				if column == POSITION_BACK:
					return true
			"any":
				return true
	return false


## Filter targets by their grid position
static func _filter_by_position(targets: Array, position_names: Array, check_column: bool) -> Array:
	if "any" in position_names:
		return targets.duplicate()

	var filtered: Array = []
	for target in targets:
		var grid_pos = target.get("grid_position", Vector2i(0, 0))
		var column = grid_pos.x
		if _column_matches_position(column, position_names):
			filtered.append(target)

	return filtered


## Filter targets by range (adjacent targets the frontmost occupied column)
static func _filter_by_range(targets: Array, user: Dictionary, range_type: String) -> Array:
	if range_type == "any":
		return targets.duplicate()

	# For "adjacent" range, find the frontmost occupied column among targets
	# and only allow targeting units in that column
	if range_type == "adjacent":
		var min_col = 3  # Higher than any valid column
		for target in targets:
			var col = target.get("grid_position", Vector2i(0, 0)).x
			if col < min_col:
				min_col = col

		var filtered: Array = []
		for target in targets:
			if target.get("grid_position", Vector2i(0, 0)).x == min_col:
				filtered.append(target)
		return filtered

	return targets.duplicate()


## Get a human-readable position name from column index
static func get_position_name(column: int) -> String:
	match column:
		POSITION_FRONT:
			return "Front"
		POSITION_MIDDLE:
			return "Middle"
		POSITION_BACK:
			return "Back"
		_:
			return "Unknown"


## Get valid adjacent positions a unit can move to
## Returns empty cells orthogonally adjacent within the 3x3 grid
static func get_valid_move_positions(unit: Dictionary, grid: Dictionary) -> Array[Vector2i]:
	var current_pos: Vector2i = unit.get("grid_position", Vector2i(0, 0))
	var unit_id: String = unit.get("id", "")
	var valid: Array[Vector2i] = []

	# Orthogonal directions only
	var directions = [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]

	for dir in directions:
		var candidate = current_pos + dir
		# Check bounds (0-2 for both axes)
		if candidate.x < 0 or candidate.x > 2 or candidate.y < 0 or candidate.y > 2:
			continue
		# Check occupancy
		if grid.has(candidate) and grid[candidate] != unit_id:
			continue
		valid.append(candidate)

	return valid


## Convert position name to column index
static func get_column_from_name(position_name: String) -> int:
	match position_name.to_lower():
		"front":
			return POSITION_FRONT
		"middle":
			return POSITION_MIDDLE
		"back":
			return POSITION_BACK
		_:
			return -1
