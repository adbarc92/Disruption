# Combat System Implementation Plan

## Overview

This document outlines the implementation plan for fleshing out the combat system in the Disruption vertical slice. The goal is to wire up the 7 skills defined in JSON, implement proper damage calculations, position-based targeting, status effects, and resource tracking.

---

## Architecture

Following the project's separation of concerns (CLAUDE.md), we create a **logic layer** for portable game rules and wire it into the existing **presentation layer**.

```
scripts/
├── logic/combat/           # NEW: Pure game logic (portable)
│   ├── damage_calculator.gd
│   ├── position_validator.gd
│   ├── status_effect_manager.gd
│   └── combat_ai.gd
├── data/
│   └── combat_unit.gd      # NEW: Runtime unit state
└── presentation/combat/
    ├── combat_manager.gd   # MODIFY: Wire up logic layer
    ├── skill_panel.gd      # NEW: Skill selection UI
    └── target_selector.gd  # NEW: Target selection
```

---

## Implementation Steps

### Step 1: Create Logic Layer Structure
Create `godot/scripts/logic/combat/` directory.

### Step 2: Damage Calculator (`damage_calculator.gd`)

Pure static class for damage formulas:

```gdscript
class_name DamageCalculator
extends RefCounted

const RESISTANCE_MULT = 0.5
const WEAKNESS_MULT = 1.5

static func calculate_damage(
    skill: Dictionary,
    attacker_stats: Dictionary,
    defender: Dictionary
) -> Dictionary:
    # Returns { damage: int, is_crit: bool, effectiveness: String }

static func get_stat_scaling_value(stat_name: String, stats: Dictionary) -> float:
    # Maps "strength", "dexterity", "resonance" to actual stat values

static func calculate_effectiveness(
    damage_type: String,
    damage_subtype: String,
    resistances: Array,
    weaknesses: Array
) -> float:
    # Returns multiplier based on type matching

static func roll_critical(attacker_stats: Dictionary) -> bool:
    # Determines if attack is critical based on dexterity
```

**Formulas:**
- Stat scaling: `base * (1 + stat_value * 0.1)`
- Defense: `damage * (100 / (100 + defense))`
- Type effectiveness: 0.5 (resist), 1.0 (normal), 1.5 (weak)
- Critical hits: dexterity-based chance, +50% damage

### Step 3: Position Validator (`position_validator.gd`)

Validate skill usage and targeting based on grid positions:

```gdscript
class_name PositionValidator
extends RefCounted

const FRONT = 0
const MIDDLE = 1
const BACK = 2

static func can_use_skill_from_position(
    skill: Dictionary,
    user_position: Vector2i
) -> bool:
    # Checks usable_positions against user's grid_position.x

static func get_valid_targets(
    skill: Dictionary,
    user: Dictionary,
    potential_targets: Array,
    ally_grid: Dictionary,
    enemy_grid: Dictionary
) -> Array:
    # Returns filtered list of valid targets based on:
    # - target_positions (front/middle/back)
    # - targeting.range (adjacent, any)
    # - targeting.type (single_enemy, all_enemies, single_ally, etc.)

static func get_column_name(column_index: int) -> String:
    # 0 -> "front", 1 -> "middle", 2 -> "back"
```

**Position Mapping:**
- Column 0 (X=0) = "front"
- Column 1 (X=1) = "middle"
- Column 2 (X=2) = "back"
- "any" means all positions valid

### Step 4: Status Effect Manager (`status_effect_manager.gd`)

Track and process status effects on units:

```gdscript
class_name StatusEffectManager
extends RefCounted

var active_effects: Dictionary = {}  # unit_id -> Array of effects

func apply_status(
    unit_id: String,
    status: String,
    duration: int,
    stat_modifier: Dictionary = {},
    extra_data: Dictionary = {}
) -> void

func remove_status(unit_id: String, status: String) -> void

func tick_turn_end(unit_id: String) -> Array:
    # Decrement durations, remove expired, return list of removed statuses

func get_stat_modifiers(unit_id: String) -> Dictionary:
    # Aggregate all stat modifiers for a unit

func get_active_statuses(unit_id: String) -> Array:
    # Return list of status names on unit

func is_taunted(unit_id: String) -> Dictionary:
    # Check if unit is taunted, return taunter info
```

**Status Effects from Skills:**
- `hamstrung`: speed -50% for 3 turns
- `inspired`: +5% strength/constitution/evasion for 4 turns (stackable x4)
- `iron_skin`: physical damage reduction 50% for 3 turns
- `taunted`: must attack taunter for 1 turn
- `elemental_attunement`: weapon gains chosen element for 3 attacks

### Step 5: Combat Unit Class (`combat_unit.gd`)

Runtime representation of a unit in combat with mutable state:

```gdscript
class_name CombatUnit
extends RefCounted

var id: String
var name: String
var is_ally: bool

# Resources
var current_hp: int
var max_hp: int
var current_mp: int
var max_mp: int
var burst_gauge: int = 0

# Position
var grid_position: Vector2i

# Stats
var base_stats: Dictionary  # vigor, strength, dexterity, resonance, agility
var current_stats: Dictionary  # Modified by status effects

# Combat data
var abilities: Array  # Skill IDs
var resistances: Array
var weaknesses: Array

# Turn order
var initiative: float

static func from_party_member(data: Dictionary) -> CombatUnit
static func from_enemy_data(data: Dictionary) -> CombatUnit
func apply_stat_modifiers(modifiers: Dictionary) -> void
func reset_to_base_stats() -> void
```

### Step 6: Wire Basic Attack

Modify `combat_manager.gd` to use calculated damage:

```gdscript
func _on_attack_pressed() -> void:
    selected_action = "attack"
    var skill = skills_db.get("basic_attack")
    # ... target selection ...
    _execute_skill(current_unit, skill, target)

func _execute_skill(user: Dictionary, skill: Dictionary, target: Dictionary) -> void:
    # Calculate damage
    var result = DamageCalculator.calculate_damage(skill, user.base_stats, target)

    # Apply damage
    _apply_damage(target, result.damage)
    EventBus.unit_damaged.emit(target.id, result.damage, skill.damage.type)

    # Consume MP
    user.current_mp -= skill.mp_cost

    # Add burst gauge
    user.burst_gauge += skill.burst_gauge_gain
    EventBus.burst_gauge_changed.emit(user.id, user.burst_gauge)
```

### Step 7: Skill Selection UI (`skill_panel.gd`)

```gdscript
class_name SkillPanel
extends Panel

signal skill_selected(skill_id: String)
signal cancelled

func show_skills(skills: Array) -> void:
    # Display skill buttons with name, MP cost
    # Gray out unusable skills

func _get_usable_skills_for_unit(unit: Dictionary) -> Array:
    var usable = []
    for skill_id in unit.abilities:
        var skill = skills_db.get(skill_id, {})
        if skill.is_empty():
            continue
        if skill.mp_cost > unit.current_mp:
            continue
        if not PositionValidator.can_use_skill_from_position(skill, unit.grid_position):
            continue
        usable.append(skill)
    return usable
```

### Step 8: Target Selection (`target_selector.gd`)

```gdscript
class_name TargetSelector
extends Node2D

signal target_selected(target_id: String)
signal cancelled

var valid_targets: Array = []

func show_valid_targets(skill: Dictionary, user: Dictionary, all_targets: Array) -> void:
    valid_targets = PositionValidator.get_valid_targets(skill, user, all_targets, ally_grid, enemy_grid)
    # Highlight valid target cells
```

### Step 9: Combat AI (`combat_ai.gd`)

```gdscript
class_name CombatAI
extends RefCounted

static func decide_action(
    enemy: Dictionary,
    allies: Array,
    enemies: Array,
    available_skills: Array,
    status_manager: StatusEffectManager
) -> Dictionary:
    # Returns { skill_id: String, target_id: String }

    match enemy.ai_behavior:
        "aggressive":
            return _aggressive_behavior(enemy, allies, available_skills)
        "defensive":
            return _defensive_behavior(enemy, allies, available_skills)
        "support":
            return _support_behavior(enemy, allies, available_skills)

    return { "skill_id": "basic_attack", "target_id": allies[0].id }

static func _aggressive_behavior(enemy, allies, skills) -> Dictionary:
    # Target lowest HP ally, use highest damage skill

static func _defensive_behavior(enemy, allies, skills) -> Dictionary:
    # Use protection skills, position front

static func _support_behavior(enemy, allies, skills) -> Dictionary:
    # Debuff enemies, stay in back
```

### Step 10: Status Effect Integration

In `combat_manager.gd`:

```gdscript
func _execute_skill(user: Dictionary, skill: Dictionary, target: Dictionary) -> void:
    # ... damage calculation ...

    # Apply status effects
    if skill.has("effect"):
        var effect = skill.effect
        status_manager.apply_status(
            target.id,
            effect.status,
            effect.duration,
            effect.get("stat_modifier", {})
        )
        EventBus.status_applied.emit(target.id, effect.status)

func _end_turn() -> void:
    # Process status effects
    var expired = status_manager.tick_turn_end(current_unit.id)
    for status in expired:
        EventBus.status_removed.emit(current_unit.id, status)

    # Recalculate stats
    current_unit.reset_to_base_stats()
    current_unit.apply_stat_modifiers(status_manager.get_stat_modifiers(current_unit.id))
```

---

## Files Summary

### Files to Create

| File | Purpose |
|------|---------|
| `godot/scripts/logic/combat/damage_calculator.gd` | Pure damage formulas |
| `godot/scripts/logic/combat/position_validator.gd` | Position rule validation |
| `godot/scripts/logic/combat/status_effect_manager.gd` | Effect tracking |
| `godot/scripts/logic/combat/combat_ai.gd` | AI decision making |
| `godot/scripts/data/combat_unit.gd` | Runtime unit state |
| `godot/scripts/presentation/combat/skill_panel.gd` | Skill selection UI |
| `godot/scripts/presentation/combat/target_selector.gd` | Target selection UI |

### Files to Modify

| File | Changes |
|------|---------|
| `godot/scripts/presentation/combat/combat_manager.gd` | Wire logic layer, skill execution, status processing |
| `godot/scenes/combat/combat_arena.tscn` | Add SkillPanel and TargetSelector nodes |

---

## Damage Formula Reference

```
# Stat Derivation (from TypeScript models)
max_hp = vigor * 20
max_mp = resonance * 5
defense = vigor * 2
crit_rate = dexterity * 5%

# Damage Calculation
base_damage = skill.damage.base
scaling_stat = base_stats[skill.damage.stat_scaling]  # 1-10
scaled_damage = base_damage * (1 + scaling_stat * 0.1)

# Defense Reduction (diminishing returns)
after_defense = scaled_damage * (100 / (100 + target_defense))

# Type Effectiveness
if damage_type in target.weaknesses: mult = 1.5
elif damage_type in target.resistances: mult = 0.5
else: mult = 1.0

# Critical Hit
if randf() < (dexterity * 0.05): crit_mult = 1.5
else: crit_mult = 1.0

final_damage = floor(after_defense * mult * crit_mult)
```

---

## Verification Checklist

1. **Basic Attack**: Start combat, attack enemy, verify damage uses strength scaling (not random 10-20)
2. **Skills**: Open skill menu, select Hamstring, verify target takes damage AND gets slowed status
3. **Position Rules**: Move Cyrus to back row, verify Edge Shift works but Hamstring is grayed out (requires front/middle)
4. **MP Tracking**: Use skills, verify MP decreases and skills become unavailable when insufficient
5. **AI**: Let enemy turn happen, verify they use actual skills with proper targeting
6. **Status Effects**: Apply debuff, advance turns, verify it expires and stats reset

---

## Out of Scope (Future Work)

- Movement as combat action
- Burst mode activation at 100 gauge
- Equipment charges (Glyphion system)
- Multi-target AoE skills
- CTB delay-based turn order (replacing simple initiative)
