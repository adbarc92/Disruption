# Tile Effects System Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Extend the tile environment system from soil-only to a general-purpose framework supporting surface hazards, destructible obstacles, elemental interactions, and collision mechanics.

**Architecture:** Generalize `TileEnvironmentManager` with category-slotted effects (surface/obstacle/soil). All effect types defined in `combat_config.json`. Combat manager wires on-enter, on-turn, duration, obstacle blocking, collision, and creation from skills/encounters/death.

**Tech Stack:** Godot 4 (GDScript), JSON data files, pure logic classes (no engine deps in logic layer)

**Design doc:** `docs/plans/2026-03-01-tile-effects-design.md`

---

### Task 1: Add effect_types, element_interactions, and collision config to combat_config.json

**Files:**
- Modify: `godot/data/combat/combat_config.json`

**Step 1: Add the new config sections**

Add `effect_types`, `element_interactions`, and `collision` inside the existing `tile_effects` object, alongside the existing `soil` key:

```json
"tile_effects": {
  "soil": { "...existing unchanged..." },

  "effect_types": {
    "fire": {
      "category": "surface",
      "element": "fire",
      "default_duration": 3,
      "default_intensity": 1,
      "on_enter": { "damage": 15, "damage_type": "fire" },
      "on_turn": { "damage": 10, "damage_type": "fire" },
      "visual": { "color": [1.0, 0.4, 0.1], "alpha_base": 0.25, "alpha_per_intensity": 0.1 }
    },
    "ice_sheet": {
      "category": "surface",
      "element": "ice",
      "default_duration": -1,
      "default_intensity": 1,
      "on_enter": { "ends_movement": true },
      "on_turn": {},
      "visual": { "color": [0.5, 0.8, 1.0], "alpha_base": 0.3, "alpha_per_intensity": 0.08 }
    },
    "poison_cloud": {
      "category": "surface",
      "element": "poison",
      "default_duration": 4,
      "default_intensity": 1,
      "on_enter": { "apply_status": "poisoned", "status_duration": 3 },
      "on_turn": { "damage": 8, "damage_type": "poison" },
      "visual": { "color": [0.3, 0.7, 0.2], "alpha_base": 0.2, "alpha_per_intensity": 0.1 }
    },
    "stone_pillar": {
      "category": "obstacle",
      "element": "earth",
      "default_duration": -1,
      "default_hp_base": 150,
      "impassable": true,
      "visual": { "color": [0.5, 0.45, 0.35], "alpha_base": 0.6 }
    },
    "ice_pillar": {
      "category": "obstacle",
      "element": "ice",
      "default_duration": -1,
      "default_hp_base": 100,
      "impassable": true,
      "visual": { "color": [0.6, 0.85, 1.0], "alpha_base": 0.55 }
    }
  },

  "element_interactions": [
    { "a": "fire", "b": "ice", "result": "remove_both" },
    { "a": "fire", "b": "poison", "result": "explode", "explode_damage": 25, "explode_radius": 1 }
  ],

  "collision": {
    "damage_base": 20,
    "damage_type": "blunt",
    "destroys_obstacle_on_kill": true
  }
}
```

**Step 2: Commit**

```bash
git add godot/data/combat/combat_config.json
git commit -m "feat(tiles): add effect_types, element_interactions, collision config"
```

---

### Task 2: Add config loader getters for tile effect types

**Files:**
- Modify: `godot/scripts/logic/combat/combat_config_loader.gd`

**Step 1: Add getter functions**

Add these static functions after the existing `get_soil_bonuses()` method:

```gdscript
## Get the full definition for a tile effect type (fire, ice_sheet, etc.)
static func get_tile_effect_type(type_name: String) -> Dictionary:
	_ensure_loaded()
	var types = _config.get("tile_effects", {}).get("effect_types", {})
	return types.get(type_name, {})


## Get all tile effect type definitions
static func get_all_tile_effect_types() -> Dictionary:
	_ensure_loaded()
	return _config.get("tile_effects", {}).get("effect_types", {})


## Get element interaction rules
static func get_element_interactions() -> Array:
	_ensure_loaded()
	return _config.get("tile_effects", {}).get("element_interactions", [])


## Get collision config
static func get_collision_config() -> Dictionary:
	_ensure_loaded()
	return _config.get("tile_effects", {}).get("collision", {
		"damage_base": 20,
		"damage_type": "blunt",
		"destroys_obstacle_on_kill": true
	})
```

**Step 2: Commit**

```bash
git add godot/scripts/logic/combat/combat_config_loader.gd
git commit -m "feat(tiles): add config loader getters for effect types, interactions, collision"
```

---

### Task 3: Generalize TileEnvironmentManager for multi-category effects

This is the core task. The existing soil system continues to work, but we add a parallel category-slotted system for surface and obstacle effects.

**Files:**
- Modify: `godot/scripts/logic/combat/tile_environment_manager.gd`

**Step 1: Add new data structures**

Add a new dictionary alongside the existing `tile_effects` (which stores soil). The new dict uses category slots:

```gdscript
## Category-slotted tile effects: Vector2i -> { "surface": Dict, "obstacle": Dict }
## Each effect dict: { "type", "element", "category", "intensity", "duration", "owner_id", "hp", "max_hp" }
var category_effects: Dictionary = {}  # Vector2i -> Dictionary
```

**Step 2: Add place_effect()**

Places a new effect on a tile, resolving element interactions first. Returns a dictionary describing what happened (for the caller to trigger visuals/logs).

```gdscript
## Place a tile effect at a position. Resolves element interactions before placing.
## params: { "type": String, "intensity": int (opt), "duration": int (opt), "hp": int (opt), "owner_id": String }
## Returns: { "placed": bool, "interactions": Array[Dictionary] }
func place_effect(pos: Vector2i, params: Dictionary) -> Dictionary:
	var type_name: String = params.get("type", "")
	var type_def = CombatConfigLoaderClass.get_tile_effect_type(type_name)
	if type_def.is_empty():
		push_warning("Unknown tile effect type: " + type_name)
		return { "placed": false, "interactions": [] }

	var category: String = type_def.get("category", "")
	var element: String = type_def.get("element", "none")

	# Resolve element interactions with existing effects at this position
	var interactions = _resolve_element_interactions(pos, element)

	# Build the effect dictionary
	var effect = {
		"type": type_name,
		"element": element,
		"category": category,
		"intensity": params.get("intensity", type_def.get("default_intensity", 1)),
		"duration": params.get("duration", type_def.get("default_duration", -1)),
		"owner_id": params.get("owner_id", ""),
	}

	# Obstacle-specific fields
	if category == "obstacle":
		var base_hp = params.get("hp", type_def.get("default_hp_base", 100))
		effect["hp"] = base_hp
		effect["max_hp"] = base_hp

	# Check if the new effect was consumed by an interaction (e.g., fire+ice remove_both)
	var new_consumed = false
	for interaction in interactions:
		if interaction.get("new_consumed", false):
			new_consumed = true
			break

	if not new_consumed:
		if not category_effects.has(pos):
			category_effects[pos] = {}
		category_effects[pos][category] = effect

	return { "placed": not new_consumed, "interactions": interactions }
```

**Step 3: Add _resolve_element_interactions()**

```gdscript
## Check for element interactions between a new element and existing effects at a position.
## Removes existing effects that conflict. Returns array of interaction results.
func _resolve_element_interactions(pos: Vector2i, new_element: String) -> Array:
	var results: Array = []
	var interactions = CombatConfigLoaderClass.get_element_interactions()

	if not category_effects.has(pos):
		return results

	var slots = category_effects[pos]
	var slots_to_remove: Array = []

	for slot_name in slots:
		var existing = slots[slot_name]
		var existing_element = existing.get("element", "none")
		var interaction = _find_interaction(new_element, existing_element, interactions)
		if interaction.is_empty():
			continue

		var result_type = interaction.get("result", "")
		match result_type:
			"remove_both":
				slots_to_remove.append(slot_name)
				results.append({
					"result": "remove_both",
					"removed_type": existing.get("type", ""),
					"removed_slot": slot_name,
					"new_consumed": true,
					"pos": pos,
				})
			"explode":
				slots_to_remove.append(slot_name)
				results.append({
					"result": "explode",
					"removed_type": existing.get("type", ""),
					"removed_slot": slot_name,
					"new_consumed": true,
					"explode_damage": interaction.get("explode_damage", 25),
					"explode_radius": interaction.get("explode_radius", 1),
					"pos": pos,
				})

	for slot_name in slots_to_remove:
		slots.erase(slot_name)
	if slots.is_empty():
		category_effects.erase(pos)

	return results


## Find a matching interaction rule (bidirectional)
func _find_interaction(elem_a: String, elem_b: String, interactions: Array) -> Dictionary:
	for rule in interactions:
		var ra = rule.get("a", "")
		var rb = rule.get("b", "")
		if (ra == elem_a and rb == elem_b) or (ra == elem_b and rb == elem_a):
			return rule
	return {}
```

**Step 4: Add remove_effect(), get_surface_at(), get_obstacle_at()**

```gdscript
## Remove an effect from a specific category slot at a position
func remove_effect(pos: Vector2i, category: String) -> void:
	if category_effects.has(pos):
		category_effects[pos].erase(category)
		if category_effects[pos].is_empty():
			category_effects.erase(pos)


## Get surface effect at a position (or empty dict)
func get_surface_at(pos: Vector2i) -> Dictionary:
	if category_effects.has(pos):
		return category_effects[pos].get("surface", {})
	return {}


## Get obstacle at a position (or empty dict)
func get_obstacle_at(pos: Vector2i) -> Dictionary:
	if category_effects.has(pos):
		return category_effects[pos].get("obstacle", {})
	return {}


## Check if a position has an impassable obstacle
func is_impassable(pos: Vector2i) -> bool:
	var obstacle = get_obstacle_at(pos)
	if obstacle.is_empty():
		return false
	var type_def = CombatConfigLoaderClass.get_tile_effect_type(obstacle.get("type", ""))
	return type_def.get("impassable", false)
```

**Step 5: Add damage_obstacle()**

```gdscript
## Deal damage to an obstacle at a position. Returns true if destroyed.
func damage_obstacle(pos: Vector2i, damage: int) -> bool:
	var obstacle = get_obstacle_at(pos)
	if obstacle.is_empty():
		return false
	obstacle["hp"] = max(0, obstacle.get("hp", 0) - damage)
	if obstacle["hp"] <= 0:
		remove_effect(pos, "obstacle")
		return true
	return false
```

**Step 6: Add tick_durations()**

```gdscript
## Tick duration on all category effects (called once per combat turn).
## Effects with duration > 0 decrement. Removed at 0. Duration -1 = permanent.
func tick_durations() -> void:
	var empty_positions: Array = []

	for pos in category_effects:
		var slots = category_effects[pos]
		var slots_to_remove: Array = []

		for slot_name in slots:
			var effect = slots[slot_name]
			var duration = effect.get("duration", -1)
			if duration > 0:
				effect["duration"] = duration - 1
				if effect["duration"] <= 0:
					slots_to_remove.append(slot_name)

		for slot_name in slots_to_remove:
			slots.erase(slot_name)

		if slots.is_empty():
			empty_positions.append(pos)

	for pos in empty_positions:
		category_effects.erase(pos)
```

**Step 7: Add get_all_category_effects_at() and update clear_all()**

```gdscript
## Get all category-slotted effects at a position (for rendering)
func get_all_category_effects_at(pos: Vector2i) -> Dictionary:
	return category_effects.get(pos, {})


## Get all positions that have any category effects (for rendering)
func get_category_effect_positions() -> Array:
	return category_effects.keys()
```

Update the existing `clear_all()` to also clear category effects:

```gdscript
func clear_all() -> void:
	tile_effects.clear()
	category_effects.clear()
	unit_last_positions.clear()
```

**Step 8: Commit**

```bash
git add godot/scripts/logic/combat/tile_environment_manager.gd
git commit -m "feat(tiles): generalize TileEnvironmentManager with category-slotted effects"
```

---

### Task 4: Add obstacle blocking to grid pathfinder

**Files:**
- Modify: `godot/scripts/logic/combat/grid_pathfinder.gd`

**Step 1: Add impassable_cells parameter to find_path and get_cells_in_range**

Both `find_path()` and `get_cells_in_range()` currently take a `grid: Dictionary` of occupied cells. Add an `impassable: Dictionary` parameter (Vector2i -> bool) to also block on obstacle hexes.

In `find_path()`, change the neighbor filtering (around line 48):
```gdscript
static func find_path(start: Vector2i, end: Vector2i, grid: Dictionary, grid_size: Vector2i, impassable: Dictionary = {}) -> Array[Vector2i]:
```

Inside the neighbor loop, add after the existing `grid.has(neighbor)` check:
```gdscript
			# Obstacle cells are impassable
			if impassable.has(neighbor):
				continue
```

In `get_cells_in_range()`, same pattern:
```gdscript
static func get_cells_in_range(origin: Vector2i, move_range: int, grid: Dictionary, grid_size: Vector2i, impassable: Dictionary = {}) -> Array[Vector2i]:
```

Inside the neighbor loop, add after the existing `grid.has(neighbor)` check:
```gdscript
			if impassable.has(neighbor):
				continue
```

**Step 2: Commit**

```bash
git add godot/scripts/logic/combat/grid_pathfinder.gd
git commit -m "feat(tiles): add impassable parameter to pathfinding"
```

---

### Task 5: Wire tile effect rendering in combat_manager

**Files:**
- Modify: `godot/scripts/presentation/combat/combat_manager.gd`

**Step 1: Extend _draw_grid_background() to render surface and obstacle overlays**

After the existing soil overlay code (around line 668), add rendering for category effects:

```gdscript
			# Surface and obstacle tile effect overlays
			var cat_effects = tile_env_manager.get_all_category_effects_at(Vector2i(x, y))
			for slot_name in cat_effects:
				var effect = cat_effects[slot_name]
				var type_name = effect.get("type", "")
				var type_def = CombatConfigLoaderClass.get_tile_effect_type(type_name)
				var vis = type_def.get("visual", {})
				if vis.is_empty():
					continue

				var color_arr = vis.get("color", [0.5, 0.5, 0.5])
				var alpha_base = vis.get("alpha_base", 0.3)
				var alpha_per = vis.get("alpha_per_intensity", 0.0)
				var intensity = effect.get("intensity", 1)
				var alpha = alpha_base + (intensity * alpha_per)

				var effect_overlay = Polygon2D.new()
				effect_overlay.polygon = hex_poly
				effect_overlay.position = grid_to_visual_pos(Vector2i(x, y))
				effect_overlay.color = Color(color_arr[0], color_arr[1], color_arr[2], alpha)
				grid_node.add_child(effect_overlay)

				# Obstacle HP bar
				if slot_name == "obstacle" and effect.has("hp"):
					var hp_ratio = float(effect["hp"]) / float(max(effect.get("max_hp", 1), 1))
					var bar_w = HEX_SIZE * 0.8
					var bar_h = 4.0
					var bar_x = -bar_w / 2.0
					var bar_y = HEX_SIZE * 0.6  # Below center

					var bar_bg = Polygon2D.new()
					bar_bg.polygon = PackedVector2Array([
						Vector2(bar_x, bar_y), Vector2(bar_x + bar_w, bar_y),
						Vector2(bar_x + bar_w, bar_y + bar_h), Vector2(bar_x, bar_y + bar_h)
					])
					bar_bg.position = grid_to_visual_pos(Vector2i(x, y))
					bar_bg.color = Color(0.2, 0.2, 0.2, 0.8)
					grid_node.add_child(bar_bg)

					var fill_w = bar_w * hp_ratio
					var bar_fill = Polygon2D.new()
					bar_fill.polygon = PackedVector2Array([
						Vector2(bar_x, bar_y), Vector2(bar_x + fill_w, bar_y),
						Vector2(bar_x + fill_w, bar_y + bar_h), Vector2(bar_x, bar_y + bar_h)
					])
					bar_fill.position = grid_to_visual_pos(Vector2i(x, y))
					bar_fill.color = Color(0.8, 0.2, 0.2, 0.9)
					grid_node.add_child(bar_fill)
```

**Step 2: Commit**

```bash
git add godot/scripts/presentation/combat/combat_manager.gd
git commit -m "feat(tiles): render surface overlays and obstacle HP bars on hex grid"
```

---

### Task 6: Wire on-enter effects during movement

**Files:**
- Modify: `godot/scripts/presentation/combat/combat_manager.gd`

**Step 1: Add _apply_on_enter_effects() helper**

Add this function to combat_manager.gd:

```gdscript
## Apply on-enter tile effects when a unit moves onto a hex
func _apply_on_enter_effects(unit: Dictionary, pos: Vector2i) -> void:
	var surface = tile_env_manager.get_surface_at(pos)
	if surface.is_empty():
		return

	var type_name = surface.get("type", "")
	var type_def = CombatConfigLoaderClass.get_tile_effect_type(type_name)
	var on_enter = type_def.get("on_enter", {})
	if on_enter.is_empty():
		return

	var unit_name = unit.get("name", "?")
	var unit_id = unit.get("id", "")

	# On-enter damage
	if on_enter.has("damage"):
		var dmg = on_enter["damage"] * surface.get("intensity", 1)
		unit["current_hp"] = max(0, unit.get("current_hp", 0) - dmg)
		var dmg_type = on_enter.get("damage_type", "")
		_show_floating_text(pos, str(dmg), Color(1.0, 0.4, 0.1))
		_log_action("  %s takes %d %s damage from %s!" % [unit_name, dmg, dmg_type, type_name], Color(1.0, 0.5, 0.3))
		EventBus.unit_damaged.emit(unit_id, dmg, dmg_type)

	# On-enter status application
	if on_enter.has("apply_status"):
		var status_name = on_enter["apply_status"]
		var status_duration = on_enter.get("status_duration", 3)
		status_manager.apply_status(unit_id, {
			"status": status_name,
			"duration": status_duration,
		})
		_log_action("  %s is %s from %s!" % [unit_name, status_name, type_name], Color(1.0, 0.5, 0.5))

	# On-enter movement end (ice)
	if on_enter.get("ends_movement", false):
		_log_action("  %s slips on %s!" % [unit_name, type_name], Color(0.5, 0.8, 1.0))
		# The caller (_execute_movement) will need to check this return
		# Set a flag on the unit dict temporarily
		unit["_movement_ended_by_tile"] = true

	_update_unit_visuals()
```

**Step 2: Call it from _execute_movement()**

In `_execute_movement()`, after the unit's grid position is updated and the movement animation plays, call:

```gdscript
	_apply_on_enter_effects(unit, new_pos)
```

For ice sheet slip: in the movement loop (if movement is step-by-step along a path), check `unit.get("_movement_ended_by_tile", false)` after each step. If true, stop movement early and erase the flag:

```gdscript
	unit.erase("_movement_ended_by_tile")
```

**Step 3: Commit**

```bash
git add godot/scripts/presentation/combat/combat_manager.gd
git commit -m "feat(tiles): wire on-enter tile effects during movement"
```

---

### Task 7: Wire on-turn effects at turn start

**Files:**
- Modify: `godot/scripts/presentation/combat/combat_manager.gd`

**Step 1: Add _apply_on_turn_effects() helper**

```gdscript
## Apply on-turn tile effects for a unit standing on a surface effect
func _apply_on_turn_effects(unit: Dictionary) -> void:
	var pos: Vector2i = unit.get("grid_position", Vector2i(0, 0))
	var surface = tile_env_manager.get_surface_at(pos)
	if surface.is_empty():
		return

	var type_name = surface.get("type", "")
	var type_def = CombatConfigLoaderClass.get_tile_effect_type(type_name)
	var on_turn = type_def.get("on_turn", {})
	if on_turn.is_empty():
		return

	var unit_name = unit.get("name", "?")
	var unit_id = unit.get("id", "")

	if on_turn.has("damage"):
		var dmg = on_turn["damage"] * surface.get("intensity", 1)
		unit["current_hp"] = max(0, unit.get("current_hp", 0) - dmg)
		var dmg_type = on_turn.get("damage_type", "")
		_show_floating_text(pos, str(dmg), Color(1.0, 0.4, 0.1))
		_log_action("  %s takes %d %s damage from %s!" % [unit_name, dmg, dmg_type, type_name], Color(1.0, 0.5, 0.3))
		EventBus.unit_damaged.emit(unit_id, dmg, dmg_type)
		_update_unit_visuals()
```

**Step 2: Call from _start_next_turn()**

After the existing soil/MP regen logic, add:

```gdscript
	_apply_on_turn_effects(current_unit)
```

Check if the unit was killed by on-turn damage before proceeding with the rest of the turn.

**Step 3: Commit**

```bash
git add godot/scripts/presentation/combat/combat_manager.gd
git commit -m "feat(tiles): wire on-turn tile effects at turn start"
```

---

### Task 8: Wire duration ticking and effect creation from skills

**Files:**
- Modify: `godot/scripts/presentation/combat/combat_manager.gd`

**Step 1: Add tick_durations to _end_turn()**

After the existing `tile_env_manager.tick_decay()` call in `_end_turn()`, add:

```gdscript
	tile_env_manager.tick_durations()
```

**Step 2: Handle create_terrain in _apply_skill_effect()**

In the skill effect switch/match block (where effect types like "debuff", "forced_movement" etc. are handled), add a case for `"create_terrain"`:

```gdscript
		"create_terrain":
			var terrain_type = effect.get("terrain", "")
			var target_pos: Vector2i = target.get("grid_position", Vector2i(0, 0))
			var placement = effect.get("placement", "target_hex")

			# Determine positions to place effects
			var positions: Array[Vector2i] = []
			match placement:
				"target_hex":
					positions.append(target_pos)
				"front_column":
					var user_col = user.get("grid_position", Vector2i(0, 0)).x
					for row in range(GRID_SIZE.y):
						positions.append(Vector2i(user_col, row))
				"around_target":
					positions.append(target_pos)
					var neighbors = GridPathfinderClass._get_neighbors(target_pos, GRID_SIZE)
					positions.append_array(neighbors)

			for pos in positions:
				var params = {
					"type": terrain_type,
					"owner_id": user.get("id", ""),
					"intensity": effect.get("intensity", 1),
					"duration": effect.get("duration", -1),
				}
				# HP from caster's max HP (for walls/pillars)
				if effect.has("hp_percent_of_caster"):
					params["hp"] = int(ceil(user.get("max_hp", 100) * effect["hp_percent_of_caster"]))

				var result = tile_env_manager.place_effect(pos, params)

				# Handle element interaction results
				for interaction in result.get("interactions", []):
					_handle_tile_interaction(interaction)

			_log_action("  %s creates %s!" % [user.get("name", "?"), terrain_type], Color(0.7, 0.9, 0.5))
			_draw_grid_background()
			_update_unit_visuals()
```

**Step 3: Add _handle_tile_interaction()**

```gdscript
## Handle results of element interactions (explosions, removals)
func _handle_tile_interaction(interaction: Dictionary) -> void:
	var result = interaction.get("result", "")
	var pos: Vector2i = interaction.get("pos", Vector2i(0, 0))

	match result:
		"remove_both":
			var removed = interaction.get("removed_type", "")
			_log_action("  %s is neutralized!" % removed, Color(0.8, 0.8, 0.8))
			_show_floating_text(pos, "Neutralized!", Color(0.8, 0.8, 0.8))

		"explode":
			var dmg = interaction.get("explode_damage", 25)
			var radius = interaction.get("explode_radius", 1)
			_log_action("  Elemental explosion at (%d,%d)!" % [pos.x, pos.y], Color(1.0, 0.6, 0.1))
			_show_floating_text(pos, "EXPLOSION!", Color(1.0, 0.5, 0.1))

			# Damage all units in radius
			for unit in all_units.values():
				if unit.get("current_hp", 0) <= 0:
					continue
				var unit_pos: Vector2i = unit.get("grid_position", Vector2i(-1, -1))
				if GridPathfinderClass.hex_distance(pos, unit_pos) <= radius:
					unit["current_hp"] = max(0, unit.get("current_hp", 0) - dmg)
					_show_floating_text(unit_pos, str(dmg), Color(1.0, 0.4, 0.1))
					EventBus.unit_damaged.emit(unit.get("id", ""), dmg, "explosion")

	_update_unit_visuals()
```

**Step 4: Commit**

```bash
git add godot/scripts/presentation/combat/combat_manager.gd
git commit -m "feat(tiles): wire duration ticking and create_terrain skill effect"
```

---

### Task 9: Wire obstacle blocking into movement and targeting

**Files:**
- Modify: `godot/scripts/presentation/combat/combat_manager.gd`

**Step 1: Build impassable dictionary for pathfinding calls**

Add a helper to combat_manager:

```gdscript
## Build dictionary of impassable positions from obstacles
func _get_impassable_positions() -> Dictionary:
	var impassable: Dictionary = {}
	for pos in tile_env_manager.get_category_effect_positions():
		if tile_env_manager.is_impassable(pos):
			impassable[pos] = true
	return impassable
```

**Step 2: Pass impassable to all pathfinding calls**

Search for all calls to `GridPathfinderClass.find_path()` and `GridPathfinderClass.get_cells_in_range()` in combat_manager.gd. Add `_get_impassable_positions()` as the last argument to each call.

**Step 3: Allow skills to target obstacle hexes**

When a skill targets a hex with an obstacle (e.g., player clicks on a stone pillar), route the damage to the obstacle instead of looking for a unit. In `_execute_skill()`, before the existing "target not found" error, check:

```gdscript
	# Check if target hex has an obstacle (allow attacking obstacles)
	var target_pos_for_obstacle: Vector2i = # the clicked hex position
	var obstacle = tile_env_manager.get_obstacle_at(target_pos_for_obstacle)
	if not obstacle.is_empty():
		# Route damage to obstacle
		var skill_damage = # calculate base damage
		var destroyed = tile_env_manager.damage_obstacle(target_pos_for_obstacle, skill_damage)
		if destroyed:
			_log_action("  %s is destroyed!" % obstacle.get("type", "obstacle"), Color(0.8, 0.6, 0.2))
		_draw_grid_background()
		return
```

Note: The exact integration depends on how target selection currently works. This may need to be wired into `target_selector.gd` as well to allow clicking obstacle hexes.

**Step 4: Commit**

```bash
git add godot/scripts/presentation/combat/combat_manager.gd
git commit -m "feat(tiles): wire obstacle blocking into pathfinding and allow obstacle targeting"
```

---

### Task 10: Add collision mechanics to forced movement

**Files:**
- Modify: `godot/scripts/presentation/combat/combat_manager.gd`

**Step 1: Rewrite _apply_forced_movement() to handle collisions**

Replace the existing simple position-clamp logic with step-by-step movement that checks for obstacles and units at each step:

```gdscript
func _apply_forced_movement(effect: Dictionary, user: Dictionary, target: Dictionary) -> void:
	var direction = effect.get("direction", "")
	var distance = effect.get("distance", 1)
	var target_pos: Vector2i = target.get("grid_position", Vector2i(0, 0))
	var user_pos: Vector2i = user.get("grid_position", Vector2i(0, 0))
	var target_id = target.get("id", "")
	var target_name = target.get("name", "?")

	# Check if target has braced status
	if status_manager.has_status(target_id, "braced"):
		var braced_data = status_manager.get_status_data(target_id, "braced")
		if braced_data.get("negates_forced_movement", false):
			_log_action("  %s resists forced movement (Braced)!" % target_name, Color(0.8, 0.8, 0.2))
			return

	# Calculate movement direction vector
	var dir_vec = Vector2i.ZERO
	match direction:
		"up":
			dir_vec = Vector2i(0, -1)
		"down":
			dir_vec = Vector2i(0, 1)
		"away":
			var dx = sign(target_pos.x - user_pos.x) if target_pos.x != user_pos.x else 1
			dir_vec = Vector2i(dx, 0)
		"toward_caster":
			var dx = sign(user_pos.x - target_pos.x) if target_pos.x != user_pos.x else 0
			var dy = sign(user_pos.y - target_pos.y) if target_pos.y != user_pos.y else 0
			dir_vec = Vector2i(dx, dy)

	if dir_vec == Vector2i.ZERO:
		return

	var collision_config = CombatConfigLoaderClass.get_collision_config()
	var collision_damage = collision_config.get("damage_base", 20)

	# Step-by-step movement with collision detection
	var current_pos = target_pos
	for step in range(distance):
		var next_pos = current_pos + dir_vec

		# Off grid edge → collision with wall
		if next_pos.x < 0 or next_pos.x >= GRID_SIZE.x or next_pos.y < 0 or next_pos.y >= GRID_SIZE.y:
			target["current_hp"] = max(0, target.get("current_hp", 0) - collision_damage)
			_log_action("  %s slams into the wall for %d damage!" % [target_name, collision_damage], Color(1.0, 0.5, 0.2))
			_show_floating_text(current_pos, str(collision_damage), Color(1.0, 0.5, 0.2))
			EventBus.unit_damaged.emit(target_id, collision_damage, "blunt")
			break

		# Obstacle collision
		if tile_env_manager.is_impassable(next_pos):
			target["current_hp"] = max(0, target.get("current_hp", 0) - collision_damage)
			var obstacle = tile_env_manager.get_obstacle_at(next_pos)
			var obstacle_name = obstacle.get("type", "obstacle")
			var destroyed = tile_env_manager.damage_obstacle(next_pos, collision_damage)
			_log_action("  %s crashes into %s for %d damage!" % [target_name, obstacle_name, collision_damage], Color(1.0, 0.5, 0.2))
			_show_floating_text(current_pos, str(collision_damage), Color(1.0, 0.5, 0.2))
			EventBus.unit_damaged.emit(target_id, collision_damage, "blunt")
			if destroyed:
				_log_action("  %s is destroyed!" % obstacle_name, Color(0.8, 0.6, 0.2))
			break

		# Unit collision
		if grid.has(next_pos):
			var other_id = grid[next_pos]
			var other_unit = _find_unit_by_id(other_id)
			if not other_unit.is_empty():
				target["current_hp"] = max(0, target.get("current_hp", 0) - collision_damage)
				other_unit["current_hp"] = max(0, other_unit.get("current_hp", 0) - collision_damage)
				_log_action("  %s crashes into %s! Both take %d damage!" % [target_name, other_unit.get("name", "?"), collision_damage], Color(1.0, 0.5, 0.2))
				_show_floating_text(current_pos, str(collision_damage), Color(1.0, 0.5, 0.2))
				_show_floating_text(next_pos, str(collision_damage), Color(1.0, 0.5, 0.2))
				EventBus.unit_damaged.emit(target_id, collision_damage, "blunt")
				EventBus.unit_damaged.emit(other_id, collision_damage, "blunt")
			break

		current_pos = next_pos

	# Apply final position
	if current_pos != target_pos:
		grid.erase(target_pos)
		target["grid_position"] = current_pos
		grid[current_pos] = target_id
		_log_action("  %s pushed to (%d,%d)!" % [target_name, current_pos.x, current_pos.y], Color(0.9, 0.7, 0.3))
		EventBus.position_changed.emit(target_id, target_pos, current_pos)

		# On-enter effects at landing position
		_apply_on_enter_effects(target, current_pos)

	_update_unit_visuals()
	_draw_grid_background()
```

**Step 2: Commit**

```bash
git add godot/scripts/presentation/combat/combat_manager.gd
git commit -m "feat(tiles): add collision mechanics to forced movement"
```

---

### Task 11: Wire effect creation from encounters and enemy death

**Files:**
- Modify: `godot/scripts/presentation/combat/combat_manager.gd`
- Modify: `godot/data/combat/encounters.json`
- Modify: `godot/data/enemies/test_enemies.json`

**Step 1: Load starting_tile_effects from encounter data**

In the combat initialization (where encounter enemies are loaded), after placing units on the grid, check for `starting_tile_effects`:

```gdscript
	# Place starting tile effects from encounter data
	var starting_effects = encounter_data.get("starting_tile_effects", [])
	for effect_data in starting_effects:
		var pos_arr = effect_data.get("position", [0, 0])
		var pos = Vector2i(pos_arr[0], pos_arr[1])
		var params = {
			"type": effect_data.get("terrain", ""),
			"intensity": effect_data.get("intensity", 1),
			"duration": effect_data.get("duration", -1),
			"owner_id": "",
		}
		if effect_data.has("hp"):
			params["hp"] = effect_data["hp"]
		tile_env_manager.place_effect(pos, params)
```

**Step 2: Wire death_tile_effect in _remove_defeated_units()**

After the existing `tile_env_manager.clear_unit()` call when a unit is defeated, check for death tile effects:

```gdscript
		var death_effect = unit.get("death_tile_effect", {})
		if not death_effect.is_empty():
			var death_pos: Vector2i = unit.get("grid_position", Vector2i(0, 0))
			var params = {
				"type": death_effect.get("terrain", ""),
				"intensity": death_effect.get("intensity", 1),
				"duration": death_effect.get("duration", -1),
				"owner_id": unit.get("id", ""),
			}
			var result = tile_env_manager.place_effect(death_pos, params)
			if result.get("placed", false):
				_log_action("  %s leaves behind %s!" % [unit.get("name", "?"), death_effect.get("terrain", "")],
					Color(0.7, 0.5, 0.8))
			for interaction in result.get("interactions", []):
				_handle_tile_interaction(interaction)
```

**Step 3: Add test data**

Add `death_tile_effect` to `corrupted_caster` in `test_enemies.json`:
```json
"death_tile_effect": { "terrain": "fire", "intensity": 1, "duration": 3 }
```

Add `starting_tile_effects` to the `full_squad` encounter in `encounters.json`:
```json
"starting_tile_effects": [
  { "position": [3, 2], "terrain": "fire", "intensity": 1 },
  { "position": [4, 1], "terrain": "stone_pillar" }
]
```

**Step 4: Commit**

```bash
git add godot/scripts/presentation/combat/combat_manager.gd godot/data/combat/encounters.json godot/data/enemies/test_enemies.json
git commit -m "feat(tiles): wire effect creation from encounters and enemy death"
```

---

### Task 12: Update the_wall skill and add test skills for other tile effects

**Files:**
- Modify: `godot/data/skills/geovant_skills.json`
- Modify: `godot/data/skills/core_skills.json` (or appropriate skill file)

**Step 1: Update the_wall to use stone_pillar type**

In `geovant_skills.json`, update `the_wall`'s effect:

```json
"effect": {
  "type": "create_terrain",
  "terrain": "stone_pillar",
  "hp_percent_of_caster": 0.75,
  "placement": "front_column"
}
```

**Step 2: Add test skills for fire and ice terrain creation**

Add temporary test skills (can go in `core_skills.json` or a test file) so we can verify the system works:

```json
{
  "id": "ignite_ground",
  "name": "Ignite Ground",
  "description": "Set the target hex ablaze.",
  "action_type": "bonus_action",
  "mp_cost": 2,
  "effect": {
    "type": "create_terrain",
    "terrain": "fire",
    "intensity": 1,
    "duration": 3,
    "placement": "target_hex"
  },
  "targeting": { "type": "single_enemy", "range_band": "distant" },
  "burst_gauge_gain": 5,
  "roles": ["geovant"]
},
{
  "id": "frost_sheet",
  "name": "Frost Sheet",
  "description": "Cover the target hex in slippery ice.",
  "action_type": "bonus_action",
  "mp_cost": 2,
  "effect": {
    "type": "create_terrain",
    "terrain": "ice_sheet",
    "intensity": 1,
    "placement": "target_hex"
  },
  "targeting": { "type": "single_enemy", "range_band": "distant" },
  "burst_gauge_gain": 5,
  "roles": ["geovant"]
}
```

Add these skill IDs to a test character's abilities for testing.

**Step 3: Commit**

```bash
git add godot/data/skills/geovant_skills.json godot/data/skills/core_skills.json
git commit -m "feat(tiles): update the_wall and add test skills for fire/ice terrain"
```

---

### Task 13: Update hot reload and guidestone

**Files:**
- Modify: `godot/scripts/presentation/combat/combat_manager.gd` (hot reload)
- Modify: `C:\Users\barclay\.claude\projects\D--MajorProjects-GAME-DEVELOPMENT-Disruption\memory\combat-demo.md`

**Step 1: Update hot reload to clear and re-place tile effects**

In `_hot_reload_data()`, after clearing tile effects, re-apply starting tile effects from the encounter:

```gdscript
	tile_env_manager.clear_all()
	# Re-apply starting tile effects from encounter if available
```

**Step 2: Update guidestone**

Add a "Tile Effects System" section to `combat-demo.md` documenting:
- Category slots (surface/obstacle/soil)
- Effect type list and config location
- Element interactions
- Collision config
- Integration points
- Known gaps

**Step 3: Commit**

```bash
git add godot/scripts/presentation/combat/combat_manager.gd
git commit -m "chore(tiles): update hot reload and guidestone for tile effects"
```
