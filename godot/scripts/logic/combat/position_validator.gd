class_name PositionValidator
extends RefCounted
## PositionValidator - Validates skill usage and targeting on unified combat grid
## No engine dependencies - portable game rules
##
## Unified Grid: columns x rows, allies on left, enemies on right
## Range is measured via Manhattan distance

const CombatConfigLoaderClass = preload("res://scripts/logic/combat/combat_config_loader.gd")
const GridPathfinderClass = preload("res://scripts/logic/combat/grid_pathfinder.gd")


## Get valid targets for a skill based on range (Manhattan distance)
## For melee skills, includes targets reachable via movement + 1 adjacent cell
## all_units: Dictionary of unit_id -> unit Dict
## grid: Dictionary of Vector2i -> unit_id
## grid_size: Vector2i(columns, rows)
static func get_valid_targets(skill: Dictionary, user: Dictionary, potential_targets: Array, all_units: Dictionary, grid: Dictionary, grid_size: Vector2i) -> Array:
	var targeting = skill.get("targeting", {})
	var target_type = targeting.get("type", "single_enemy")

	match target_type:
		"self":
			return [user]
		"all_allies", "all_enemies":
			return potential_targets.duplicate()
		_:
			pass

	var skill_range = get_skill_range(skill)
	var user_pos: Vector2i = user.get("grid_position", Vector2i(0, 0))
	var range_type = skill.get("range_type", "melee")
	var valid: Array = []

	for target in potential_targets:
		var target_pos: Vector2i = target.get("grid_position", Vector2i(0, 0))

		if skill_range == 0:
			# Unlimited range
			valid.append(target)
		else:
			# Both melee and ranged use Manhattan distance check
			if is_in_range(user_pos, target_pos, skill_range):
				valid.append(target)

	return valid


## Check if any valid target exists for a skill
static func can_use_skill(skill: Dictionary, user: Dictionary, all_units: Dictionary, grid: Dictionary, grid_size: Vector2i) -> bool:
	var target_type = get_targeting_type(skill)

	match target_type:
		"self":
			return true
		"all_allies", "single_ally":
			var allies = _get_units_by_side(user.get("is_ally", true), all_units)
			return not get_valid_targets(skill, user, allies, all_units, grid, grid_size).is_empty()
		"all_enemies", "single_enemy":
			var enemies = _get_units_by_side(not user.get("is_ally", true), all_units)
			return not get_valid_targets(skill, user, enemies, all_units, grid, grid_size).is_empty()
		_:
			return true


## Get the range value from a skill (with migration for old format)
static func get_skill_range(skill: Dictionary) -> int:
	# New format: explicit "range" field
	if skill.has("range"):
		return skill.get("range", 1)

	# Old format migration
	var targeting = skill.get("targeting", {})
	var old_range = targeting.get("range", "any")
	match old_range:
		"adjacent":
			return 1
		"any":
			return 0
		_:
			return 1


## Check if target is within range (Manhattan distance, 0 = unlimited)
static func is_in_range(user_pos: Vector2i, target_pos: Vector2i, skill_range: int) -> bool:
	if skill_range == 0:
		return true
	return GridPathfinderClass.manhattan_distance(user_pos, target_pos) <= skill_range


## Get movement range for a unit based on agility
static func get_movement_range(unit: Dictionary) -> int:
	var agility = unit.get("base_stats", {}).get("agility", 5)
	return CombatConfigLoaderClass.get_movement_range(agility)


## Get valid movement positions for a unit (delegates to GridPathfinder)
static func get_valid_move_positions(unit: Dictionary, grid: Dictionary, grid_size: Vector2i) -> Array[Vector2i]:
	var origin: Vector2i = unit.get("grid_position", Vector2i(0, 0))
	var move_range = get_movement_range(unit)
	return GridPathfinderClass.get_cells_in_range(origin, move_range, grid, grid_size)


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


## Filter units by side (ally/enemy)
static func _get_units_by_side(is_ally: bool, all_units: Dictionary) -> Array:
	var result: Array = []
	for unit_id in all_units:
		var unit = all_units[unit_id]
		if unit.get("is_ally", true) == is_ally:
			result.append(unit)
	return result


## Legacy helpers kept for backward compatibility
static func can_use_skill_from_position(skill: Dictionary, position: Vector2i) -> bool:
	return true  # Unified grid: position-based restrictions handled by get_valid_targets
