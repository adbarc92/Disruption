class_name CombatAI
extends RefCounted
## CombatAI - Behavior-based AI decision making for enemies
## No engine dependencies - portable game rules
## Uses unified grid with range-based targeting

const PositionValidatorClass = preload("res://scripts/logic/combat/position_validator.gd")
const GridPathfinderClass = preload("res://scripts/logic/combat/grid_pathfinder.gd")
const CombatConfigLoaderClass = preload("res://scripts/logic/combat/combat_config_loader.gd")

## AI decision result
class AIDecision:
	var skill_id: String = "basic_attack"
	var target_ids: Array = []  # Array of target unit IDs
	var move_to: Vector2i = Vector2i(-1, -1)  # Movement destination (-1,-1 = no move)

	func _init(skill: String = "basic_attack", targets: Array = [], move: Vector2i = Vector2i(-1, -1)):
		skill_id = skill
		target_ids = targets
		move_to = move


## Make a decision for an AI-controlled unit
## all_units: Dictionary of unit_id -> unit Dict
## grid: Dictionary of Vector2i -> unit_id
## grid_size: Vector2i
static func make_decision(unit: Dictionary, all_units: Dictionary, grid: Dictionary, grid_size: Vector2i, skills_data: Dictionary, status_manager) -> AIDecision:
	# Check for taunt - if taunted, must attack the taunter
	var taunt_target_id = status_manager.get_taunt_target(unit.get("id", ""))
	if taunt_target_id != "":
		var attack_skill_id = _get_best_attack_skill(unit, all_units, grid, grid_size, skills_data)
		return AIDecision.new(attack_skill_id, [taunt_target_id])

	var behavior = unit.get("ai_behavior", "aggressive")

	match behavior:
		"aggressive":
			return _aggressive_decision(unit, all_units, grid, grid_size, skills_data, status_manager)
		"defensive":
			return _defensive_decision(unit, all_units, grid, grid_size, skills_data, status_manager)
		"support":
			return _support_decision(unit, all_units, grid, grid_size, skills_data, status_manager)
		_:
			return _aggressive_decision(unit, all_units, grid, grid_size, skills_data, status_manager)


## Aggressive AI: target lowest HP, use highest damage skill
static func _aggressive_decision(unit: Dictionary, all_units: Dictionary, grid: Dictionary, grid_size: Vector2i, skills_data: Dictionary, status_manager) -> AIDecision:
	var usable_skills = _get_usable_skills(unit, all_units, grid, grid_size, skills_data)
	var enemies = _get_enemies(unit, all_units)

	if enemies.is_empty():
		return AIDecision.new()

	# Find best damage skill
	var best_skill_id = "basic_attack"
	var best_damage = 0

	for skill_id in usable_skills:
		var skill = skills_data.get(skill_id, {})
		if skill.has("damage"):
			var damage_base = skill.damage.get("base", 0)
			if damage_base > best_damage:
				best_damage = damage_base
				best_skill_id = skill_id

	var skill = skills_data.get(best_skill_id, {})

	# Get valid targets for the skill
	var valid_targets = PositionValidatorClass.get_valid_targets(skill, unit, enemies, all_units, grid, grid_size)
	if valid_targets.is_empty():
		# Fall back to basic attack
		skill = skills_data.get("basic_attack", {})
		valid_targets = PositionValidatorClass.get_valid_targets(skill, unit, enemies, all_units, grid, grid_size)

	if valid_targets.is_empty():
		return AIDecision.new("basic_attack", [_get_random_target(enemies)])

	# Target lowest HP
	var lowest_hp_target = _find_lowest_hp_target(valid_targets)
	return AIDecision.new(best_skill_id, [lowest_hp_target.id])


## Defensive AI: use protection skills, attack if none available
static func _defensive_decision(unit: Dictionary, all_units: Dictionary, grid: Dictionary, grid_size: Vector2i, skills_data: Dictionary, status_manager) -> AIDecision:
	var usable_skills = _get_usable_skills(unit, all_units, grid, grid_size, skills_data)
	var allies = _get_allies(unit, all_units)

	# Look for defensive/protection skills
	for skill_id in usable_skills:
		var skill = skills_data.get(skill_id, {})
		if skill.has("effect"):
			var effect_type = skill.effect.get("type", "")
			if effect_type in ["ally_buff", "self_buff"]:
				var targets = PositionValidatorClass.get_valid_targets(skill, unit, allies, all_units, grid, grid_size)
				if not targets.is_empty():
					return AIDecision.new(skill_id, [targets[0].id])

	# Fall back to aggressive behavior
	return _aggressive_decision(unit, all_units, grid, grid_size, skills_data, status_manager)


## Support AI: debuff enemies, stay back
static func _support_decision(unit: Dictionary, all_units: Dictionary, grid: Dictionary, grid_size: Vector2i, skills_data: Dictionary, status_manager) -> AIDecision:
	var usable_skills = _get_usable_skills(unit, all_units, grid, grid_size, skills_data)
	var enemies = _get_enemies(unit, all_units)

	# Look for debuff skills
	for skill_id in usable_skills:
		var skill = skills_data.get(skill_id, {})
		if skill.has("effect"):
			var effect_type = skill.effect.get("type", "")
			if effect_type in ["debuff", "enemy_debuff"]:
				var targets = PositionValidatorClass.get_valid_targets(skill, unit, enemies, all_units, grid, grid_size)
				if not targets.is_empty():
					# Target enemy without the debuff
					var status_name = skill.effect.get("status", "")
					for target in targets:
						if not status_manager.has_status(target.id, status_name):
							return AIDecision.new(skill_id, [target.id])
					# All have debuff, target random
					return AIDecision.new(skill_id, [targets[0].id])

	# Fall back to ranged attack or basic attack
	return _aggressive_decision(unit, all_units, grid, grid_size, skills_data, status_manager)


## Get skills the unit can use (has ability and enough MP, has valid targets)
static func _get_usable_skills(unit: Dictionary, all_units: Dictionary, grid: Dictionary, grid_size: Vector2i, skills_data: Dictionary) -> Array:
	var usable: Array = []
	var abilities = unit.get("abilities", ["basic_attack"])
	var current_mp = unit.get("current_mp", 0)

	for ability_id in abilities:
		var skill = skills_data.get(ability_id, {})
		if skill.is_empty():
			continue

		var mp_cost = skill.get("mp_cost", 0)
		if current_mp >= mp_cost:
			if PositionValidatorClass.can_use_skill(skill, unit, all_units, grid, grid_size):
				usable.append(ability_id)

	# Always include basic attack if nothing else available
	if usable.is_empty() and skills_data.has("basic_attack"):
		usable.append("basic_attack")

	return usable


## Get enemy units relative to this unit
static func _get_enemies(unit: Dictionary, all_units: Dictionary) -> Array:
	var is_ally = unit.get("is_ally", true)
	var enemies: Array = []
	for uid in all_units:
		var u = all_units[uid]
		if u.get("is_ally", true) != is_ally:
			enemies.append(u)
	return enemies


## Get ally units relative to this unit
static func _get_allies(unit: Dictionary, all_units: Dictionary) -> Array:
	var is_ally = unit.get("is_ally", true)
	var allies: Array = []
	for uid in all_units:
		var u = all_units[uid]
		if u.get("is_ally", true) == is_ally:
			allies.append(u)
	return allies


## Find the target with lowest HP
static func _find_lowest_hp_target(targets: Array) -> Dictionary:
	if targets.is_empty():
		return {}

	var lowest = targets[0]
	for target in targets:
		if target.get("current_hp", 999) < lowest.get("current_hp", 999):
			lowest = target

	return lowest


## Get random target from list
static func _get_random_target(targets: Array) -> String:
	if targets.is_empty():
		return ""
	return targets[randi() % targets.size()].get("id", "")


## Get the best damage-dealing skill the unit can use (for forced attacks like taunt)
static func _get_best_attack_skill(unit: Dictionary, all_units: Dictionary, grid: Dictionary, grid_size: Vector2i, skills_data: Dictionary) -> String:
	var usable = _get_usable_skills(unit, all_units, grid, grid_size, skills_data)
	var best_id = "basic_attack"
	var best_damage = 0

	for skill_id in usable:
		var skill = skills_data.get(skill_id, {})
		if skill.has("damage"):
			var base = skill.damage.get("base", 0)
			if base > best_damage:
				best_damage = base
				best_id = skill_id

	return best_id
