class_name TileEnvironmentManager
extends RefCounted
## TileEnvironmentManager - Tracks tile-level environmental effects on the combat grid
## No engine dependencies - portable game rules
##
## Each tile (Vector2i) can hold multiple effects. Effects have an owner, intensity,
## and decay behavior. The first effect type is "soil" (Blood & Soil system).

const CombatConfigLoaderClass = preload("res://scripts/logic/combat/combat_config_loader.gd")

## tile_effects: Dictionary of Vector2i -> Array[Dictionary]
## Each effect dict: { "type", "owner_id", "intensity", "decay_rate", "decaying" }
var tile_effects: Dictionary = {}

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
	unit_last_positions.clear()


## Helper: find a Soil effect owned by a specific unit at a position
func _find_soil_effect(pos: Vector2i, owner_id: String):
	for effect in tile_effects.get(pos, []):
		if effect.get("type", "") == "soil" and effect.get("owner_id", "") == owner_id:
			return effect
	return null
