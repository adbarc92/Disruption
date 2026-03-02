# Burst Mode Design

**Date:** 2026-03-01
**Status:** Approved
**Scope:** Implement burst mode activation, stat boosts, UI gauge, and duration tracking for vertical slice

---

## Overview

Burst Mode is a transformation system where characters build gauge through combat actions and, once full, can activate a temporary powered-up state with stat boosts. The system uses a dedicated state (not the status effect system) to allow future expansion into ability transformation and burst-exclusive skills.

---

## Burst State on Units

Each unit dictionary gets three runtime fields initialized at combat start:

```
"burst_active": false,
"burst_turns_remaining": 0,
"burst_effects": {}
```

### Activation Flow

1. Player presses Burst button (0 AP, does not end turn)
2. `burst_active = true`
3. `burst_turns_remaining` = character's `burst_mode.duration`
4. `burst_effects` = copy of character's `burst_mode.effects`
5. `burst_gauge` reset to 0
6. Emit `EventBus.burst_mode_activated(unit_id)`
7. Log: "Cyrus activates Elemental Mastery! (5 turns)"
8. Player continues acting with remaining AP (burst is a free action)

### Deactivation Flow

At each turn end for the burst-active unit:

1. Decrement `burst_turns_remaining`
2. If reaches 0:
   - Set `burst_active = false`
   - Clear `burst_effects = {}`
   - Emit `EventBus.burst_mode_ended(unit_id)`
   - Log: "Cyrus's Elemental Mastery fades."

---

## Stat Boost Application

The `burst_effects` dict contains stat modifiers applied at specific integration points in the combat engine:

| Field | Where Applied | Character | Value |
|-------|--------------|-----------|-------|
| `damage_multiplier` | `_execute_skill()` damage calc, after all other modifiers | Cyrus | 1.5x |
| `damage_multiplier` | Same | Phaidros | 1.4x |
| `speed_bonus` | CTB tick recalculation at turn end | Cyrus | 0.4 (40% faster) |
| `speed_bonus` | Same | Vaughn | 0.5 (50% faster) |
| `crit_rate_bonus` | Damage calculator crit chance | Vaughn | 0.45 (+45%) |
| `damage_reduction` | Damage reduction path in `_execute_skill()` | Phaidros | 0.7 (70% DR) |

Check pattern: `if user.get("burst_active", false): apply burst_effects.get("field", 0)`

The `special` field (e.g. `"all_attacks_gain_random_element"`) is stored but NOT processed in the vertical slice. It serves as a future hook for ability transformation.

### Interaction with Existing Systems

- Burst `damage_multiplier` stacks multiplicatively with `pitched_stance` and tile environment bonuses
- Burst `damage_reduction` stacks with status-based DR and tile environment DR
- Burst `speed_bonus` reduces CTB ticks: `ticks = base_ticks * (1.0 - speed_bonus)`
- Burst `crit_rate_bonus` adds to base crit chance before cap

---

## UI

### Burst Gauge Bar (unit_visual.gd)

- Horizontal bar beneath HP/MP bars on each ally unit
- Gold/amber color to distinguish from HP (green) and MP (blue)
- Fills from 0 to 100 as skills are used
- Shows numeric value (e.g. "72/100")
- When full (100): bar pulses to signal readiness

### Burst Button (action panel)

- New button in action panel alongside Attack/Skill/Item/Move/Defend/End Turn
- Only visible and enabled when:
  - `current_unit.burst_gauge >= 100`
  - `current_unit.burst_active == false`
  - Unit is an ally
- Hidden/disabled otherwise
- Activation costs 0 AP, does NOT end turn
- After activation, returns to action selection so player can use remaining AP in burst state

### Burst Active Indicators

- Unit visual: gold tinted overlay or border during burst
- Turns remaining counter on unit visual (e.g. "B:3")
- Status label suffix: "Cyrus's turn (AP: 3) [BURST]"
- Action log messages on activation and deactivation

---

## Combat Config

New `burst` section in `combat_config.json`:

```json
"burst": {
  "max_gauge": 100,
  "activation_threshold": 100,
  "activation_ap_cost": 0,
  "gauge_carry_between_combats": 0.0
}
```

All values config-driven for tuning. `gauge_carry_between_combats` is 0.0 for now.

---

## Data — No Changes Required

- `party.json`: Existing `burst_mode` objects have name, duration, effects
- Skill JSONs: Existing `burst_gauge_gain` (5-25) and `burst_charge_type` fields
- `event_bus.gd`: Existing `burst_mode_activated` and `burst_mode_ended` signals

---

## What's NOT In Scope

| Feature | Reason |
|---------|--------|
| Ability transformation / burst-exclusive skills | Future — requires new skill data and UI |
| `special` field processing | Future — each character's special needs unique logic |
| Inter-combat gauge carryover | Future — needs save/load integration |
| Customizable charging methods | Future — charging is flat burst_gauge_gain per skill |
| Enemy burst mode | Future — enemies don't have burst_mode data |
| Burst gauge on enemies | Not designed |

---

## Files to Modify

| File | Changes |
|------|---------|
| `combat_config.json` | Add `burst` section |
| `combat_manager.gd` | Burst activation, stat boost integration, turn-end countdown, Burst button |
| `unit_visual.gd` | Burst gauge bar, active burst overlay, turns remaining counter |
| `damage_calculator.gd` | Crit rate bonus integration point |
| `ctb_turn_manager.gd` | Speed bonus integration point (or in combat_manager tick calc) |
| `combat_config_loader.gd` | Load burst config values |
