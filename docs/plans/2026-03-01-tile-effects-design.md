# Tile Effects System Design

**Goal:** Extend the existing Blood & Soil tile environment system into a general-purpose tile effects framework supporting surface hazards, destructible obstacles, elemental interactions, and collision mechanics.

**Architecture:** Generalize `TileEnvironmentManager` from soil-only to multi-category tile effects. All effect types are data-driven via `combat_config.json`. Each hex supports up to three simultaneous effects (one per category slot). Element interactions resolve automatically when conflicting effects overlap.

---

## Data Model

Each hex stores up to 3 effects — one per category slot: `surface`, `obstacle`, `soil`.

```
tile_effects[Vector2i] = {
  "surface": {
    "type": "fire",
    "element": "fire",
    "intensity": 2,
    "duration": 3,
    "owner_id": "cyrus"
  },
  "obstacle": {
    "type": "stone_pillar",
    "element": "earth",
    "hp": 150,
    "max_hp": 150,
    "owner_id": "phaidros",
    "duration": -1
  },
  "soil": { ... existing soil data unchanged ... }
}
```

### Effect Types

| Type | Category | Element | Duration | Behavior |
|------|----------|---------|----------|----------|
| `fire` | surface | fire | 3 turns | On-enter: fire damage. On-turn: fire DOT. |
| `ice_sheet` | surface | ice | -1 (permanent) | On-enter: movement ends immediately (slip). |
| `poison_cloud` | surface | poison | 4 turns | On-enter: apply poisoned status. On-turn: poison damage. |
| `stone_pillar` | obstacle | earth | -1 (permanent) | Impassable. Has HP, destroyed by attacks/collisions. |
| `ice_pillar` | obstacle | ice | -1 (permanent) | Impassable. Has HP, meltable by fire. |

### Categories

- **Surface**: Ground-level hazards. One per tile. Affects units entering or standing on the hex.
- **Obstacle**: Physical objects blocking movement. One per tile. Has HP, targetable, destructible.
- **Soil**: Existing Blood & Soil system. Unchanged, operates independently.

### Elements

Each effect has an element property (`fire`, `ice`, `poison`, `earth`, `none`) that determines interactions between effects, independent of category.

---

## Element Interactions

When a new effect is placed on a tile, the system checks existing effects for element conflicts and resolves before placing.

```json
"element_interactions": [
  { "a": "fire", "b": "ice", "result": "remove_both" },
  { "a": "fire", "b": "poison", "result": "explode", "explode_damage": 25, "explode_radius": 1 }
]
```

Interactions are bidirectional — `fire + ice` and `ice + fire` both resolve the same way. Interactions check across categories (fire surface melts ice pillar obstacle).

---

## Integration Points

### Turn Start (`_start_next_turn`)
- Existing: Soil increment if unit stayed.
- New: On-turn effects — if unit stands on a surface effect, apply per-turn behavior (fire DOT, poison damage).

### Movement (`_execute_movement`)
- Existing: Mark soil as decaying when unit leaves.
- New: On-enter effects — trigger when unit enters hex (fire damage, ice slip, poison status). Obstacle blocking — pathfinding excludes impassable hexes.

### Damage Calculation (`_execute_skill`)
- Existing: Soil damage mult / damage reduction.
- New: Obstacle targeting — skills hitting an obstacle hex deal damage to obstacle HP. Destroyed at 0 HP.

### Turn End (`_end_turn`)
- Existing: Record position, tick soil decay.
- New: Duration tick — decrement duration on effects with `duration > 0`. Remove at 0.

### Effect Creation Sources
- **Skills**: `create_terrain` effect type places a tile effect at target hex.
- **Encounters**: `starting_tile_effects` array in encounter data.
- **On-death**: `death_tile_effect` field in enemy data.
- **Items**: Same as skills, items with `create_terrain` effect.

---

## Collision Mechanics (Forced Movement)

When forced movement pushes a unit into an occupied space:

**Unit into obstacle:**
- Movement stops at hex before obstacle.
- Both take collision damage.
- Obstacle loses HP (may be destroyed).

**Unit into unit:**
- Movement stops at hex before target unit.
- Both units take collision damage.

**Unit off grid edge:**
- Movement stops at last valid hex.
- Pushed unit takes collision damage.

```json
"collision": {
  "damage_base": 20,
  "damage_type": "blunt",
  "destroys_obstacle_on_kill": true
}
```

---

## Config Schema

All in `combat_config.json` under `tile_effects`:

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

### Skill Data Schema

```json
"effect": {
  "type": "create_terrain",
  "terrain": "fire",
  "intensity": 2,
  "duration": 4,
  "placement": "target_hex"
}
```

### Encounter Data Schema

```json
"starting_tile_effects": [
  { "position": [3, 2], "terrain": "fire", "intensity": 1 },
  { "position": [4, 1], "terrain": "stone_pillar" }
]
```

### Enemy Death Effect Schema

```json
"death_tile_effect": { "terrain": "poison_cloud", "intensity": 2, "duration": 3 }
```

---

## Visual Rendering

Rendering order (bottom to top):
1. Base hex zone color (blue/red/neutral)
2. Soil tint overlay (existing amber)
3. Surface effect overlay (colored hex tint from config `visual` field)
4. Obstacle fill (higher alpha, visually dominant, blocks hex)
5. Unit visuals on top

Surface effects use the same hex overlay approach as soil. Obstacles use a solid fill with an HP bar drawn beneath.

---

## Files Changed

| File | Changes |
|------|---------|
| `tile_environment_manager.gd` | Generalize to multi-category. Add `place_effect()`, `remove_effect()`, `get_obstacle_at()`, `damage_obstacle()`, `resolve_element_interaction()`, `tick_durations()`, `get_on_enter_effects()`, `get_on_turn_effects()`. Keep existing soil methods. |
| `combat_config_loader.gd` | Add getters for `effect_types`, `element_interactions`, `collision` config. |
| `combat_manager.gd` | Wire on-enter, on-turn, duration ticks, obstacle blocking, collision, obstacle targeting, effect creation from skills/death/encounters. |
| `grid_pathfinder.gd` | Exclude impassable hexes from pathfinding. |
| `combat_config.json` | Add `effect_types`, `element_interactions`, `collision` sections. |
| `geovant_skills.json` | Update `the_wall` to new schema. |
| `test_enemies.json` | Add `death_tile_effect` to test enemies. |
| `encounters.json` | Add `starting_tile_effects` to test encounter. |

No new script files — everything extends existing architecture.
