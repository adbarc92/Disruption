class_name StatusEffectManager
extends RefCounted
## StatusEffectManager - Tracks and processes status effects on units
## No engine dependencies - portable game rules

## Active status effects by unit_id
## Structure: { "unit_id": [ { status_data }, ... ] }
var active_effects: Dictionary = {}


## Apply a status effect to a unit
## Returns true if effect was applied, false if blocked/invalid
func apply_status(unit_id: String, status_name: String, duration: int, effect_data: Dictionary = {}) -> bool:
	if not active_effects.has(unit_id):
		active_effects[unit_id] = []

	var effects_list: Array = active_effects[unit_id]

	# Check for existing effect (for stacking rules)
	var existing_index = _find_effect_index(effects_list, status_name)

	if existing_index >= 0:
		var existing = effects_list[existing_index]
		var stackable = effect_data.get("stackable", false)
		var max_stacks = effect_data.get("max_stacks", 1)

		if stackable:
			var current_stacks = existing.get("stacks", 1)
			if current_stacks < max_stacks:
				existing["stacks"] = current_stacks + 1
				# Refresh duration on stack
				existing["duration"] = duration
				return true
			else:
				# Max stacks reached, just refresh duration
				existing["duration"] = duration
				return true
		else:
			# Non-stackable - refresh duration
			existing["duration"] = duration
			return true

	# New effect
	var new_effect = {
		"status": status_name,
		"duration": duration,
		"stacks": 1,
	}

	# Copy relevant data from effect_data
	if effect_data.has("stat_modifier"):
		new_effect["stat_modifier"] = effect_data.stat_modifier
	if effect_data.has("damage_reduction"):
		new_effect["damage_reduction"] = effect_data.damage_reduction
	if effect_data.has("stackable"):
		new_effect["stackable"] = effect_data.stackable
	if effect_data.has("max_stacks"):
		new_effect["max_stacks"] = effect_data.max_stacks
	if effect_data.has("attacks_redirected"):
		new_effect["attacks_redirected"] = effect_data.attacks_redirected
	if effect_data.has("damage_per_turn"):
		new_effect["damage_per_turn"] = effect_data.damage_per_turn
	if effect_data.has("damage_multiplier"):
		new_effect["damage_multiplier"] = effect_data.damage_multiplier
	if effect_data.has("consumes_on_attack"):
		new_effect["consumes_on_attack"] = effect_data.consumes_on_attack
	if effect_data.has("consumes_on_hit"):
		new_effect["consumes_on_hit"] = effect_data.consumes_on_hit
	if effect_data.has("consumes_on_skill"):
		new_effect["consumes_on_skill"] = effect_data.consumes_on_skill
	if effect_data.has("negates_forced_movement"):
		new_effect["negates_forced_movement"] = effect_data.negates_forced_movement
	if effect_data.has("multi_hit_bonus"):
		new_effect["multi_hit_bonus"] = effect_data.multi_hit_bonus
	if effect_data.has("mp_cost_reduction"):
		new_effect["mp_cost_reduction"] = effect_data.mp_cost_reduction
	if effect_data.has("burst_gauge_bonus"):
		new_effect["burst_gauge_bonus"] = effect_data.burst_gauge_bonus
	if effect_data.has("counter_on_ally_hit"):
		new_effect["counter_on_ally_hit"] = effect_data.counter_on_ally_hit
	if effect_data.has("redirect_damage_to"):
		new_effect["redirect_damage_to"] = effect_data.redirect_damage_to
	if effect_data.has("prevents_movement"):
		new_effect["prevents_movement"] = effect_data.prevents_movement

	effects_list.append(new_effect)
	return true


## Remove a status effect from a unit
func remove_status(unit_id: String, status_name: String) -> bool:
	if not active_effects.has(unit_id):
		return false

	var effects_list: Array = active_effects[unit_id]
	var index = _find_effect_index(effects_list, status_name)

	if index >= 0:
		effects_list.remove_at(index)
		return true

	return false


## Process turn end for a unit - tick durations and return expired effects
func tick_turn_end(unit_id: String) -> Array:
	if not active_effects.has(unit_id):
		return []

	var expired: Array = []
	var effects_list: Array = active_effects[unit_id]

	# Iterate backwards to safely remove
	for i in range(effects_list.size() - 1, -1, -1):
		var effect = effects_list[i]
		effect["duration"] -= 1

		if effect["duration"] <= 0:
			expired.append(effect.status)
			effects_list.remove_at(i)

	return expired


## Get all stat modifiers for a unit from active effects
## Returns: { "strength": 0.1, "defense": -0.2, ... }
func get_stat_modifiers(unit_id: String) -> Dictionary:
	var modifiers: Dictionary = {}

	if not active_effects.has(unit_id):
		return modifiers

	for effect in active_effects[unit_id]:
		if effect.has("stat_modifier"):
			var stacks = effect.get("stacks", 1)
			for stat_name in effect.stat_modifier:
				var mod_value = effect.stat_modifier[stat_name] * stacks
				if modifiers.has(stat_name):
					modifiers[stat_name] += mod_value
				else:
					modifiers[stat_name] = mod_value

	return modifiers


## Get damage reduction modifiers for a unit
## Returns: { "physical": 0.5, "fire": 0.3, ... }
func get_damage_reductions(unit_id: String) -> Dictionary:
	var reductions: Dictionary = {}

	if not active_effects.has(unit_id):
		return reductions

	for effect in active_effects[unit_id]:
		if effect.has("damage_reduction"):
			for damage_type in effect.damage_reduction:
				var red_value = effect.damage_reduction[damage_type]
				if reductions.has(damage_type):
					reductions[damage_type] = min(1.0, reductions[damage_type] + red_value)
				else:
					reductions[damage_type] = red_value

	return reductions


## Check if a unit has a specific status
func has_status(unit_id: String, status_name: String) -> bool:
	if not active_effects.has(unit_id):
		return false

	return _find_effect_index(active_effects[unit_id], status_name) >= 0


## Get all active statuses for a unit
func get_statuses(unit_id: String) -> Array:
	if not active_effects.has(unit_id):
		return []

	var statuses: Array = []
	for effect in active_effects[unit_id]:
		statuses.append({
			"status": effect.status,
			"duration": effect.duration,
			"stacks": effect.get("stacks", 1)
		})
	return statuses


## Get the status data for a specific effect
func get_status_data(unit_id: String, status_name: String) -> Dictionary:
	if not active_effects.has(unit_id):
		return {}

	var index = _find_effect_index(active_effects[unit_id], status_name)
	if index >= 0:
		return active_effects[unit_id][index]

	return {}


## Clear all effects for a unit
func clear_unit(unit_id: String) -> void:
	if active_effects.has(unit_id):
		active_effects.erase(unit_id)


## Clear all effects (for combat end)
func clear_all() -> void:
	active_effects.clear()


## Check for taunt status and get taunter
func get_taunt_target(unit_id: String) -> String:
	if not active_effects.has(unit_id):
		return ""

	for effect in active_effects[unit_id]:
		if effect.status == "taunted" and effect.get("attacks_redirected", 0) > 0:
			# Decrement attacks remaining
			effect["attacks_redirected"] -= 1
			# Return the taunter ID (stored when taunt was applied)
			return effect.get("taunter_id", "")

	return ""


## Apply taunt from a unit
func apply_taunt(target_id: String, taunter_id: String, duration: int, attacks: int) -> bool:
	var effect_data = {
		"attacks_redirected": attacks,
		"taunter_id": taunter_id
	}

	return apply_status(target_id, "taunted", duration, effect_data)


## Helper: Find effect index by status name
func _find_effect_index(effects_list: Array, status_name: String) -> int:
	for i in range(effects_list.size()):
		if effects_list[i].status == status_name:
			return i
	return -1
