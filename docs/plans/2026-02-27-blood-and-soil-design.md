# Blood & Soil System Design

**Date:** 2026-02-27
**Status:** Approved
**Source:** CDD_Combat_v2.md Section 3

---

## Goal

Add a tile-based territorial control system where units that hold position gain stacking combat bonuses. This creates a core "move or stay" tension: repositioning sacrifices accumulated power, while staying put builds it.

## Architecture

Blood & Soil is the first implementation of a broader **Tile Environment** system. Tiles can carry environmental modifiers (frozen, oil-slicked, soil-enriched, etc.) that affect occupying units. The foundation is generic; Blood & Soil is the first effect type.

### New Logic Class: `TileEnvironmentManager`

RefCounted, no engine dependencies. Lives in `godot/scripts/logic/combat/`.

**Data model:**
```
tile_effects: Dictionary  # Vector2i -> Array[Dictionary]
```

Each tile effect is a Dictionary:
```gdscript
{
  "type": "soil",           # Effect type identifier
  "owner_id": "cyrus",     # Unit that created it (null for environmental)
  "intensity": 2,          # Stacking level (Soil: 0-3)
  "decay_rate": 1,         # Intensity lost per combat turn when unoccupied by owner
  "bonuses": {             # Current bonuses (looked up from config by intensity)
    "damage_mult": 0.05,
    "damage_reduction": 0.10,
    "mp_regen": 0
  }
}
```

**Public API:**
- `add_effect(pos: Vector2i, effect: Dictionary)` - Place or update a tile effect
- `remove_effect(pos: Vector2i, type: String)` - Clear a specific effect type from a tile
- `get_effects_at(pos: Vector2i) -> Array` - All effects on a tile
- `get_soil_intensity(pos: Vector2i, owner_id: String) -> int` - Soil level for a specific unit
- `increment_soil(pos: Vector2i, owner_id: String)` - Add +1 Soil (capped at max)
- `mark_soil_decaying(pos: Vector2i, owner_id: String)` - Owner left; start decay
- `tick_decay()` - Called each combat turn; reduces decaying effects by decay_rate, removes at 0
- `get_bonuses_for_unit(unit_id: String, pos: Vector2i) -> Dictionary` - Aggregate tile bonuses for a unit

---

## Blood & Soil Mechanics

### Soil Token Accumulation

- At **turn start**, if a unit is on the same tile it ended its previous turn: +1 Soil intensity (max 3)
- The tile effect is owned by the unit — only the owner gets the bonuses
- Multiple units can have independent Soil effects on different tiles

### Soil Bonus Table

| Intensity | Damage Bonus | Damage Resistance | MP Regen Bonus |
|-----------|-------------|-------------------|----------------|
| 0 | +0% | +0% | +0 |
| 1 | +5% | +0% | +0 |
| 2 | +5% | +10% | +0 |
| 3 | +10% | +10% | +1 |

All values are data-driven from `combat_config.json`.

### Movement Clears Soil

When a unit moves to a different tile:
- Their Soil on the old tile is marked as "decaying"
- Decaying Soil loses 1 intensity per combat turn
- At intensity 0, the effect is removed

### Who Gets Soil

- **All ally units**: Always gain Soil tokens
- **Enemies**: Only if `"soil_enabled": true` in their enemy data (default: false)

---

## Integration Points

### Turn Start (`_start_next_turn` in combat_manager)
1. Check if unit's current position matches their previous turn-end position
2. If yes and unit is eligible: `tile_env.increment_soil(pos, unit_id)`
3. Look up Soil bonuses and apply MP regen bonus (added to base 2/turn)

### Damage Calculation (`DamageCalculator`)
- Attacker's tile bonuses: `damage_mult` increases outgoing damage
- Defender's tile bonuses: `damage_reduction` reduces incoming damage
- Both feed into existing modifier pipeline alongside status effects

### Movement (`_execute_movement` in combat_manager)
- On movement: `tile_env.mark_soil_decaying(old_pos, unit_id)`

### Decay Tick (each combat turn)
- `tile_env.tick_decay()` called during turn processing
- Reduces all decaying effects by their `decay_rate`
- Removes effects that reach intensity 0

---

## Visual Feedback

### Hex Tint
- Soil tiles get a warm earth-tone hex overlay
- Intensity 1: faint amber
- Intensity 2: medium amber
- Intensity 3: bright amber/gold
- Rendered as a semi-transparent polygon over the hex cell

### Unit Indicator
- Small numbered badge on unit visual showing current Soil level (1-3)
- Only shown when unit has Soil > 0

---

## Data Changes

### `combat_config.json` — New Section
```json
{
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

### `test_enemies.json` — Optional Flag
```json
{
  "id": "corrupted_brute",
  "soil_enabled": true
}
```

---

## File Changes Summary

| Layer | File | Change |
|-------|------|--------|
| Logic | `tile_environment_manager.gd` (NEW) | Core tile effect tracking, decay, bonus aggregation |
| Logic | `combat_config_loader.gd` | Add getters for `tile_effects.soil.*` config values |
| Logic | `damage_calculator.gd` | Accept tile bonuses in damage calculation |
| Presentation | `combat_manager.gd` | Wire Soil into turn start, movement, damage, decay; render hex tints |
| Presentation | `unit_visual.gd` | Show Soil token indicator badge |
| Data | `combat_config.json` | Add `tile_effects` section |
| Data | `test_enemies.json` | Add `soil_enabled` to select enemies (e.g., corrupted_brute) |

---

## Not In Scope (Future)

- Hostile Soil (disrupting enemy-rooted tiles)
- Blood Sanctification (permanent +1 from kills while rooted)
- Character type modifiers (Shaper/Sourcerer/Glyphein)
- Other tile effect types (frozen, oil, fire) — foundation supports them but only Soil is built now
- Dynamic Row System integration (Front/Mid/Back classification)
