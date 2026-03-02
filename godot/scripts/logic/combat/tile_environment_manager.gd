class_name TileEnvironmentManager
extends RefCounted
## TileEnvironmentManager - Tracks tile-level environmental effects on the combat grid
## No engine dependencies - portable game rules
##
## Each tile (Vector2i) can hold multiple effects. Effects have an owner, intensity,
## and decay behavior. The first effect type is "soil" (Blood & Soil system).
##
## Additionally, each tile can hold up to one "surface" effect and one "obstacle" effect
## via the category_effects dictionary. These interact via element rules.

const CombatConfigLoaderClass = preload("res://scripts/logic/combat/combat_config_loader.gd")

## tile_effects: Dictionary of Vector2i -> Array[Dictionary]
## Each effect dict: { "type", "owner_id", "intensity", "decay_rate", "decaying" }
var tile_effects: Dictionary = {}

## category_effects: Dictionary of Vector2i -> Dictionary
## Inner dict has optional keys "surface" and/or "obstacle", each holding an effect dict:
##   { "type", "category", "element", "owner_id", "intensity", "duration", "hp", "impassable",
##     "on_enter", "on_turn", "visual" }
var category_effects: Dictionary = {}

## Track each unit's turn-end position for Soil accumulation checks
var unit_last_positions: Dictionary = {}  # unit_id -> Vector2i


## Record where a unit ended their turn (called at turn end)
func record_turn_end_position(unit_id: String, pos: Vector2i) -> void:
	unit_last_positions[unit_id] = pos


## Check if a unit stayed on the same tile since last turn end
func did_unit_stay(unit_id: String, current_pos: Vector2i) -> bool:
	if not unit_last_positions.has(unit_id):
		return false
	return unit_last_positions[unit_id] == current_pos


## Increment Soil intensity for a unit at a position
## Returns the new intensity, or -1 if unit is not eligible
func increment_soil(pos: Vector2i, owner_id: String) -> int:
	var max_intensity = CombatConfigLoaderClass.get_soil_max_intensity()
	var existing = _find_soil_effect(pos, owner_id)

	if existing != null:
		existing["intensity"] = mini(existing["intensity"] + 1, max_intensity)
		existing["decaying"] = false
		return existing["intensity"]

	# Create new Soil effect
	var effect = {
		"type": "soil",
		"owner_id": owner_id,
		"intensity": 1,
		"decay_rate": CombatConfigLoaderClass.get_soil_decay_rate(),
		"decaying": false,
	}

	if not tile_effects.has(pos):
		tile_effects[pos] = []
	tile_effects[pos].append(effect)
	return 1


## Mark a unit's Soil as decaying (called when unit moves away)
func mark_soil_decaying(pos: Vector2i, owner_id: String) -> void:
	var effect = _find_soil_effect(pos, owner_id)
	if effect != null:
		effect["decaying"] = true


## Get Soil intensity for a unit at a position
func get_soil_intensity(pos: Vector2i, owner_id: String) -> int:
	var effect = _find_soil_effect(pos, owner_id)
	if effect != null and not effect.get("decaying", false):
		return effect["intensity"]
	return 0


## Get combat bonuses for a unit at a position from all tile effects
## Returns: { "damage_mult": float, "damage_reduction": float, "mp_regen": int }
func get_bonuses_for_unit(unit_id: String, pos: Vector2i) -> Dictionary:
	var bonuses = { "damage_mult": 0.0, "damage_reduction": 0.0, "mp_regen": 0 }
	var intensity = get_soil_intensity(pos, unit_id)
	if intensity > 0:
		var soil_bonuses = CombatConfigLoaderClass.get_soil_bonuses(intensity)
		bonuses["damage_mult"] += soil_bonuses.get("damage_mult", 0.0)
		bonuses["damage_reduction"] += soil_bonuses.get("damage_reduction", 0.0)
		bonuses["mp_regen"] += soil_bonuses.get("mp_regen", 0)
	return bonuses


## Tick decay on all tile effects (called once per combat turn)
## Reduces decaying effects by their decay_rate, removes at intensity 0
func tick_decay() -> void:
	var empty_positions: Array = []

	for pos in tile_effects:
		var effects: Array = tile_effects[pos]
		var i = effects.size() - 1
		while i >= 0:
			var effect = effects[i]
			if effect.get("decaying", false):
				effect["intensity"] -= effect.get("decay_rate", 1)
				if effect["intensity"] <= 0:
					effects.remove_at(i)
			i -= 1

		if effects.is_empty():
			empty_positions.append(pos)

	for pos in empty_positions:
		tile_effects.erase(pos)


## Get all effects at a position (for rendering)
func get_effects_at(pos: Vector2i) -> Array:
	return tile_effects.get(pos, [])


## Get the highest Soil intensity at a position (across all owners, for rendering)
## Includes decaying effects — hex tint shows "fading territory" while unit badge hides immediately
func get_max_soil_at(pos: Vector2i) -> int:
	var max_val = 0
	for effect in tile_effects.get(pos, []):
		if effect.get("type", "") == "soil":
			max_val = maxi(max_val, effect.get("intensity", 0))
	return max_val


## Remove all effects owned by a unit (called when unit is defeated)
func clear_unit(unit_id: String) -> void:
	unit_last_positions.erase(unit_id)
	var empty_positions: Array = []

	for pos in tile_effects:
		var effects: Array = tile_effects[pos]
		var i = effects.size() - 1
		while i >= 0:
			if effects[i].get("owner_id", "") == unit_id:
				effects.remove_at(i)
			i -= 1
		if effects.is_empty():
			empty_positions.append(pos)

	for pos in empty_positions:
		tile_effects.erase(pos)


## Clear all effects (for combat end)
func clear_all() -> void:
	tile_effects.clear()
	category_effects.clear()
	unit_last_positions.clear()


## Helper: find a Soil effect owned by a specific unit at a position
func _find_soil_effect(pos: Vector2i, owner_id: String):
	for effect in tile_effects.get(pos, []):
		if effect.get("type", "") == "soil" and effect.get("owner_id", "") == owner_id:
			return effect
	return null


# =============================================================================
# Category-slotted effects (surface / obstacle)
# =============================================================================


## Place a category-slotted effect on a tile.
## params: { "type": String, "owner_id": String, optional "intensity", "duration", "hp" }
## Returns: { "placed": bool, "interactions": Array }
func place_effect(pos: Vector2i, params: Dictionary) -> Dictionary:
	var type_name: String = params.get("type", "")
	var type_def: Dictionary = CombatConfigLoaderClass.get_tile_effect_type(type_name)
	if type_def.is_empty():
		return { "placed": false, "interactions": [] }

	var category: String = type_def.get("category", "")
	if category != "surface" and category != "obstacle":
		return { "placed": false, "interactions": [] }

	var element: String = type_def.get("element", "")

	# Resolve element interactions with existing effects at this position
	var interactions: Array = _resolve_element_interactions(pos, element)

	# Check if the new effect was consumed by an interaction
	var consumed := false
	for interaction in interactions:
		if interaction.get("new_consumed", false):
			consumed = true
			break

	if consumed:
		return { "placed": false, "interactions": interactions }

	# If the slot is already occupied, overwrite it
	var hp_value = params.get("hp", type_def.get("default_hp_base", 0))
	var effect := {
		"type": type_name,
		"category": category,
		"element": element,
		"owner_id": params.get("owner_id", ""),
		"intensity": params.get("intensity", type_def.get("default_intensity", 1)),
		"duration": params.get("duration", type_def.get("default_duration", -1)),
		"hp": hp_value,
		"max_hp": hp_value,
		"impassable": type_def.get("impassable", false),
		"on_enter": type_def.get("on_enter", {}),
		"on_turn": type_def.get("on_turn", {}),
		"visual": type_def.get("visual", {}),
	}

	if not category_effects.has(pos):
		category_effects[pos] = {}
	category_effects[pos][category] = effect

	return { "placed": true, "interactions": interactions }


## Check all existing category effects at pos for element interactions with new_element.
## Removes existing effects that are consumed. Returns array of interaction result dicts.
func _resolve_element_interactions(pos: Vector2i, new_element: String) -> Array:
	if new_element == "":
		return []

	var interactions_config: Array = CombatConfigLoaderClass.get_element_interactions()
	var results: Array = []

	if not category_effects.has(pos):
		return results

	var slot_data: Dictionary = category_effects[pos]
	var categories_to_remove: Array = []

	for cat in slot_data:
		var existing: Dictionary = slot_data[cat]
		var existing_element: String = existing.get("element", "")
		if existing_element == "":
			continue

		var rule: Dictionary = _find_interaction(new_element, existing_element, interactions_config)
		if rule.is_empty():
			continue

		var result_type: String = rule.get("result", "")
		var interaction_result := {
			"pos": pos,
			"existing_category": cat,
			"existing_type": existing.get("type", ""),
			"existing_element": existing_element,
			"result": result_type,
			"new_consumed": false,
		}

		if result_type == "remove_both":
			categories_to_remove.append(cat)
			interaction_result["new_consumed"] = true
		elif result_type == "explode":
			categories_to_remove.append(cat)
			interaction_result["new_consumed"] = true
			interaction_result["explode_damage"] = rule.get("explode_damage", 0)
			interaction_result["explode_radius"] = rule.get("explode_radius", 0)

		results.append(interaction_result)

	# Remove consumed existing effects
	for cat in categories_to_remove:
		slot_data.erase(cat)

	if slot_data.is_empty():
		category_effects.erase(pos)

	return results


## Helper: find an element interaction rule matching elem_a and elem_b (bidirectional).
func _find_interaction(elem_a: String, elem_b: String, interactions: Array) -> Dictionary:
	for rule in interactions:
		var ra: String = rule.get("a", "")
		var rb: String = rule.get("b", "")
		if (ra == elem_a and rb == elem_b) or (ra == elem_b and rb == elem_a):
			return rule
	return {}


## Remove an effect from a specific category slot at a position.
func remove_effect(pos: Vector2i, category: String) -> void:
	if not category_effects.has(pos):
		return
	category_effects[pos].erase(category)
	if category_effects[pos].is_empty():
		category_effects.erase(pos)


## Get the surface effect at a position (or empty dict if none).
func get_surface_at(pos: Vector2i) -> Dictionary:
	if not category_effects.has(pos):
		return {}
	return category_effects[pos].get("surface", {})


## Get the obstacle effect at a position (or empty dict if none).
func get_obstacle_at(pos: Vector2i) -> Dictionary:
	if not category_effects.has(pos):
		return {}
	return category_effects[pos].get("obstacle", {})


## Check if a position has an impassable obstacle.
func is_impassable(pos: Vector2i) -> bool:
	var obstacle := get_obstacle_at(pos)
	return obstacle.get("impassable", false)


## Deal damage to an obstacle at a position. Returns true if the obstacle was destroyed.
func damage_obstacle(pos: Vector2i, damage: int) -> bool:
	var obstacle := get_obstacle_at(pos)
	if obstacle.is_empty():
		return false

	obstacle["hp"] = obstacle.get("hp", 0) - damage
	if obstacle["hp"] <= 0:
		remove_effect(pos, "obstacle")
		return true
	return false


## Decrement duration on all category effects. Remove effects that reach 0.
## Duration -1 means permanent (never decremented).
func tick_durations() -> void:
	var empty_positions: Array = []

	for pos in category_effects:
		var slot_data: Dictionary = category_effects[pos]
		var categories_to_remove: Array = []

		for cat in slot_data:
			var effect: Dictionary = slot_data[cat]
			var duration: int = effect.get("duration", -1)
			if duration == -1:
				continue
			duration -= 1
			effect["duration"] = duration
			if duration <= 0:
				categories_to_remove.append(cat)

		for cat in categories_to_remove:
			slot_data.erase(cat)

		if slot_data.is_empty():
			empty_positions.append(pos)

	for pos in empty_positions:
		category_effects.erase(pos)


## Get all category effects at a position (for rendering).
## Returns dict with "surface" and/or "obstacle" keys if present.
func get_all_category_effects_at(pos: Vector2i) -> Dictionary:
	return category_effects.get(pos, {})


## Get all positions that have at least one category effect.
func get_category_effect_positions() -> Array:
	return category_effects.keys()
