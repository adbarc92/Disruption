# Blood & Soil Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Add a tile-based territorial control system (Blood & Soil) where units that hold position gain stacking damage, resistance, and MP regen bonuses.

**Architecture:** New `TileEnvironmentManager` logic class tracks tile effects (generic foundation). Combat manager wires Soil into turn start (accumulation), movement (clearing), damage (bonuses), and rendering (hex tints + unit badges). All bonus values are data-driven from `combat_config.json`.

**Tech Stack:** Godot 4 / GDScript, JSON config

---

### Task 1: Add Soil Config to combat_config.json

**Files:**
- Modify: `godot/data/combat/combat_config.json`

**Step 1: Add tile_effects section**

Add a new top-level `"tile_effects"` key to the existing config:

```json
{
  "grid": { ... },
  "movement": { ... },
  "balance": { ... },
  "ap": { ... },
  "opportunity_attacks": { ... },
  "tile_effects": {
    "soil": {
      "max_intensity": 3,
      "decay_rate": 1,
      "bonuses_per_level": [
        { "damage_mult": 0.0, "damage_reduction": 0.0, "mp_regen": 0 },
        { "damage_mult": 0.05, "damage_reduction": 0.0, "mp_regen": 0 },
        { "damage_mult": 0.05, "damage_reduction": 0.10, "mp_regen": 0 },
        { "damage_mult": 0.10, "damage_reduction": 0.10, "mp_regen": 1 }
      ]
    }
  }
}
```

**Step 2: Commit**

```bash
git add godot/data/combat/combat_config.json
git commit -m "Add tile_effects.soil config for Blood & Soil system"
```

---

### Task 2: Add Soil Config Getters to CombatConfigLoader

**Files:**
- Modify: `godot/scripts/logic/combat/combat_config_loader.gd`

**Step 1: Add getter methods**

Add these methods after the existing `get_oa_max_per_move()` function (after line 125):

```gdscript
## Get the maximum Soil intensity (default 3)
static func get_soil_max_intensity() -> int:
	_ensure_loaded()
	var soil = _config.get("tile_effects", {}).get("soil", {})
	return soil.get("max_intensity", 3)


## Get the Soil decay rate per combat turn (default 1)
static func get_soil_decay_rate() -> int:
	_ensure_loaded()
	var soil = _config.get("tile_effects", {}).get("soil", {})
	return soil.get("decay_rate", 1)


## Get Soil bonuses for a given intensity level
## Returns: { "damage_mult": float, "damage_reduction": float, "mp_regen": int }
static func get_soil_bonuses(intensity: int) -> Dictionary:
	_ensure_loaded()
	var soil = _config.get("tile_effects", {}).get("soil", {})
	var bonuses_table: Array = soil.get("bonuses_per_level", [])
	var clamped = clampi(intensity, 0, bonuses_table.size() - 1)
	if clamped >= 0 and clamped < bonuses_table.size():
		return bonuses_table[clamped]
	return { "damage_mult": 0.0, "damage_reduction": 0.0, "mp_regen": 0 }
```

**Step 2: Commit**

```bash
git add godot/scripts/logic/combat/combat_config_loader.gd
git commit -m "Add Soil config getters to CombatConfigLoader"
```

---

### Task 3: Create TileEnvironmentManager Logic Class

**Files:**
- Create: `godot/scripts/logic/combat/tile_environment_manager.gd`

**Step 1: Write the full class**

```gdscript
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
```

**Step 2: Commit**

```bash
git add godot/scripts/logic/combat/tile_environment_manager.gd
git commit -m "Add TileEnvironmentManager logic class for tile effects"
```

---

### Task 4: Wire Soil Into Combat Manager

This is the main integration task. It touches `combat_manager.gd` in several places.

**Files:**
- Modify: `godot/scripts/presentation/combat/combat_manager.gd`

**Step 1: Add preload and instance variable**

Near the top where other logic classes are preloaded (around line 14), add:

```gdscript
const TileEnvironmentManagerClass = preload("res://scripts/logic/combat/tile_environment_manager.gd")
```

In the variable declarations section (around line 50-60, near where `status_manager` is declared), add:

```gdscript
var tile_env_manager: TileEnvironmentManagerClass = TileEnvironmentManagerClass.new()
```

**Step 2: Wire Soil accumulation into `_start_next_turn()`**

After the MP regeneration call (`_regenerate_mp(current_unit)` at line 777), add Soil logic:

```gdscript
	# Blood & Soil: check if unit stayed on same tile
	var unit_id_for_soil = current_unit.get("id", "")
	var current_grid_pos = current_unit.get("grid_position", Vector2i(0, 0))
	var soil_eligible = current_unit.get("is_ally", true) or current_unit.get("soil_enabled", false)

	if soil_eligible and tile_env_manager.did_unit_stay(unit_id_for_soil, current_grid_pos):
		var new_intensity = tile_env_manager.increment_soil(current_grid_pos, unit_id_for_soil)
		if new_intensity > 0:
			_log_action("  Soil %d on %s (rooted)" % [new_intensity, current_unit.get("name", "?")],
				Color(0.85, 0.7, 0.3))

	# Apply tile bonus MP regen
	var tile_bonuses = tile_env_manager.get_bonuses_for_unit(unit_id_for_soil, current_grid_pos)
	if tile_bonuses.get("mp_regen", 0) > 0:
		var bonus_mp = tile_bonuses["mp_regen"]
		current_unit["current_mp"] = min(current_unit.get("max_mp", 25), current_unit.get("current_mp", 0) + bonus_mp)
		_log_action("  +%d MP from Soil" % bonus_mp, Color(0.4, 0.6, 0.9))
```

**Step 3: Wire Soil clearing into `_execute_movement()`**

In `_execute_movement()` (line 997), after `var old_pos` is set (line 999), add before the path check:

```gdscript
	# Blood & Soil: mark old position as decaying when unit moves
	tile_env_manager.mark_soil_decaying(old_pos, unit_id)
```

**Step 4: Wire Soil bonuses into `_execute_skill()`**

In `_execute_skill()` (line 878), inside the `if skill.has("damage"):` block, after the damage result is calculated (line 886) and before the status effect damage reduction (line 889), add tile bonus damage:

```gdscript
		# Apply tile environment damage bonus (attacker's Soil)
		var attacker_pos = user.get("grid_position", Vector2i(0, 0))
		var attacker_tile_bonuses = tile_env_manager.get_bonuses_for_unit(user.get("id", ""), attacker_pos)
		if attacker_tile_bonuses.get("damage_mult", 0.0) > 0.0:
			result.damage = int(ceil(result.damage * (1.0 + attacker_tile_bonuses["damage_mult"])))

		# Apply tile environment damage reduction (defender's Soil)
		var defender_pos = target.get("grid_position", Vector2i(0, 0))
		var defender_tile_bonuses = tile_env_manager.get_bonuses_for_unit(target.get("id", ""), defender_pos)
		if defender_tile_bonuses.get("damage_reduction", 0.0) > 0.0:
			result.damage = int(floor(result.damage * (1.0 - defender_tile_bonuses["damage_reduction"])))
```

**Step 5: Wire turn-end position recording into `_end_turn()`**

In `_end_turn()` (line 1075), before the status effect tick (line 1080), add:

```gdscript
	# Blood & Soil: record where this unit ended their turn
	var end_pos = current_unit.get("grid_position", Vector2i(0, 0))
	tile_env_manager.record_turn_end_position(current_unit.get("id", ""), end_pos)

	# Tick tile effect decay
	tile_env_manager.tick_decay()
```

**Step 6: Wire cleanup into `_remove_defeated_units()`**

In `_remove_defeated_units()` (line 1106), inside the loop where units are cleaned up (after `_ap_system.remove_unit(uid)` at line 1112), add:

```gdscript
			tile_env_manager.clear_unit(uid)
```

**Step 7: Wire cleanup into hot reload**

Find the `_hot_reload_data()` function and add `tile_env_manager.clear_all()` alongside the other clear calls.

**Step 8: Commit**

```bash
git add godot/scripts/presentation/combat/combat_manager.gd
git commit -m "Wire Blood & Soil into combat turn flow and damage"
```

---

### Task 5: Render Soil Hex Tints

**Files:**
- Modify: `godot/scripts/presentation/combat/combat_manager.gd`

**Step 1: Add Soil tint layer to `_draw_grid_background()`**

In `_draw_grid_background()` (line 580), after the zone-colored hex cells are added (inside the `for x/y` loop, after `grid_node.add_child(cell)` at line 602), add a Soil overlay:

```gdscript
			# Soil tint overlay
			var soil_level = tile_env_manager.get_max_soil_at(Vector2i(x, y))
			if soil_level > 0:
				var soil_overlay = Polygon2D.new()
				soil_overlay.polygon = hex_poly
				soil_overlay.position = grid_to_visual_pos(Vector2i(x, y))
				# Warm amber that intensifies: level 1=faint, 2=medium, 3=bright
				var alpha = 0.12 + (soil_level * 0.08)
				soil_overlay.color = Color(0.85, 0.65, 0.2, alpha)
				grid_node.add_child(soil_overlay)
```

**Step 2: Commit**

```bash
git add godot/scripts/presentation/combat/combat_manager.gd
git commit -m "Render Soil intensity as amber hex tint overlay"
```

---

### Task 6: Show Soil Badge on Unit Visual

**Files:**
- Modify: `godot/scripts/presentation/combat/unit_visual.gd`
- Modify: `godot/scripts/presentation/combat/combat_manager.gd`

**Step 1: Add Soil badge to UnitVisual**

In `unit_visual.gd`, add a `soil_badge` variable in the child nodes section (around line 35):

```gdscript
var soil_badge: Label
```

At the end of the `setup()` function (before `update_stats(unit)` at line 113), add badge creation:

```gdscript
	# Soil intensity badge (hidden by default)
	soil_badge = Label.new()
	soil_badge.text = ""
	soil_badge.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	soil_badge.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	soil_badge.add_theme_font_size_override("font_size", 10)
	soil_badge.add_theme_color_override("font_color", Color(0.95, 0.85, 0.3))
	soil_badge.size = Vector2(16, 16)
	soil_badge.position = Vector2(UNIT_WIDTH - 16, -2)
	soil_badge.visible = false
	add_child(soil_badge)
```

Add an `update_soil()` method after `update_statuses()`:

```gdscript
func update_soil(intensity: int) -> void:
	if soil_badge == null:
		return
	if intensity > 0:
		soil_badge.text = str(intensity)
		soil_badge.visible = true
	else:
		soil_badge.visible = false
```

**Step 2: Pass Soil data from combat_manager**

In `combat_manager.gd`, in the `_create_or_update_visual()` function (line 626), after the `visual.update_statuses(...)` calls, add:

```gdscript
		var soil_intensity = tile_env_manager.get_soil_intensity(grid_pos, uid)
		visual.update_soil(soil_intensity)
```

Add this in both the update path (existing visual) and the create path (new visual).

**Step 3: Commit**

```bash
git add godot/scripts/presentation/combat/unit_visual.gd godot/scripts/presentation/combat/combat_manager.gd
git commit -m "Show Soil intensity badge on unit visuals"
```

---

### Task 7: Add soil_enabled Flag to Select Enemies

**Files:**
- Modify: `godot/data/enemies/test_enemies.json`

**Step 1: Add `soil_enabled` to the Corrupted Brute and Corrupted Champion**

These are the tank/elite archetypes — thematically they "dig in" and hold position.

Add `"soil_enabled": true` to the `corrupted_brute` entry (after `"preferred_position": "front"` on line 26):

```json
      "preferred_position": "front",
      "soil_enabled": true
```

Add `"soil_enabled": true` to the `corrupted_champion` entry (after `"preferred_position": "front"` on line 187):

```json
      "preferred_position": "front",
      "soil_enabled": true
```

**Step 2: Commit**

```bash
git add godot/data/enemies/test_enemies.json
git commit -m "Enable Soil for brute and champion enemy archetypes"
```

---

### Task 8: Update Guidestone

**Files:**
- Modify: `C:\Users\barclay\.claude\projects\D--MajorProjects-GAME-DEVELOPMENT-Disruption\memory\combat-demo.md`

**Step 1: Update architecture table**

Add `tile_environment_manager.gd` to the LOGIC column in the architecture table.

**Step 2: Add Tile Effects / Blood & Soil section**

Add a new section after the "AI Behaviors" section documenting:
- TileEnvironmentManager API
- Soil accumulation rules
- Soil bonus table
- Integration points (turn start, movement, damage, rendering)
- Enemy opt-in via `soil_enabled`

**Step 3: Remove Blood & Soil from "Known Gaps" if listed**

**Step 4: Commit** (not needed for memory files, just save)
