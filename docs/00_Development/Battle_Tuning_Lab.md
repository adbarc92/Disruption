# Battle System Tuning Lab

A living document for tracking combat system configuration values and design experiments. This is the source of truth for current tunable values and a changelog of what we've tried.

---

## Current Configuration

### Turn Order System (CTB)

The turn order uses a tick-based Conditional Turn-Based (CTB) system inspired by Final Fantasy X.

| Parameter | Value | Notes |
|-----------|-------|-------|
| Tick countdown | Continuous | Units count down to 0, then act |
| Base ticks per turn | `100 - (Speed * 5)` | Higher speed = fewer ticks to wait |
| Turn order display | 10 turns | Visible upcoming turns |
| Tie-breaker (primary) | Higher Speed | Faster unit goes first |
| Tie-breaker (secondary) | Random | If Speed also ties |

**Speed Scaling Formula:**
```
ticks_until_next_turn = BASE_TICKS - (speed * SPEED_MULTIPLIER) - remaining_ap_bonus

Where:
  BASE_TICKS = 100
  SPEED_MULTIPLIER = 5
  remaining_ap_bonus = remaining_ap * AP_TO_TICKS_RATIO
  AP_TO_TICKS_RATIO = 5  (each unused AP reduces wait by 5 ticks)
```

### Action Point (AP) System

Units spend AP during their turn to perform actions. Remaining AP provides benefits.

| Parameter | Value | Notes |
|-----------|-------|-------|
| Base AP per turn | 3 | Fixed value (will experiment later) |
| AP cap (max total) | Constitution stat | Player characters only |
| AP conservation | Yes (players only) | Unused AP carries to next turn |
| End turn | Explicit | Player must choose to end turn |

**AP Economy:**
| Action Type | AP Cost | Notes |
|-------------|---------|-------|
| Basic Attack | 1 | Standard attack |
| Movement | 1 | Move one grid position |
| Skill (Light) | 1 | Quick abilities |
| Skill (Standard) | 2 | Most abilities |
| Skill (Heavy) | 3 | Powerful abilities |
| Defend | 0 | Ends turn, grants defensive bonus |
| End Turn | 0 | Explicitly end with remaining AP |

**Remaining AP Benefits:**
1. **Speed Boost**: Each unused AP reduces next turn's tick count
2. **Conservation** (players only): Unused AP added to next turn's pool (up to Constitution cap)

### Formulas (Tweak Zone)

```gdscript
# Core CTB Formula
func calculate_ticks_until_turn(unit: Dictionary, remaining_ap: int = 0) -> int:
    var base = BASE_TICKS  # 100
    var speed_reduction = unit.speed * SPEED_MULTIPLIER  # speed * 5
    var ap_bonus = remaining_ap * AP_TO_TICKS_RATIO  # remaining_ap * 5
    return max(1, base - speed_reduction - ap_bonus)

# AP Available This Turn
func calculate_available_ap(unit: Dictionary) -> int:
    var base_ap = BASE_AP_PER_TURN  # 3
    var conserved = unit.conserved_ap if unit.is_ally else 0
    var cap = unit.constitution if unit.is_ally else base_ap
    return min(base_ap + conserved, cap)

# After Turn Ends
func end_turn(unit: Dictionary, remaining_ap: int) -> void:
    # Calculate tick reduction from remaining AP
    var tick_bonus = remaining_ap * AP_TO_TICKS_RATIO

    # Conserve AP for player characters
    if unit.is_ally:
        unit.conserved_ap = remaining_ap  # Will be capped on next turn

    # Add to turn order with reduced ticks
    var base_ticks = calculate_ticks_until_turn(unit, remaining_ap)
    add_to_turn_queue(unit, base_ticks)
```

### Constants Reference

```gdscript
# CTB Constants
const BASE_TICKS = 100
const SPEED_MULTIPLIER = 5
const TURN_ORDER_DISPLAY_COUNT = 10

# AP Constants
const BASE_AP_PER_TURN = 3
const AP_TO_TICKS_RATIO = 5

# Action Costs
const AP_COST_BASIC_ATTACK = 1
const AP_COST_MOVEMENT = 1
const AP_COST_SKILL_LIGHT = 1
const AP_COST_SKILL_STANDARD = 2
const AP_COST_SKILL_HEAVY = 3
const AP_COST_DEFEND = 0
```

### Stat Mappings

The combat system derives values from character base stats:

| Combat Stat | Source Stat | Notes |
|-------------|-------------|-------|
| Speed | Agility | Determines turn frequency in CTB |
| Constitution (AP cap) | Vigor | Max AP pool for player characters |

**Current Character Speed Values:**
| Character | Agility | Base Ticks | Notes |
|-----------|---------|------------|-------|
| Cyrus | 6 | 70 | Balanced |
| Vaughn | 7 | 65 | Fastest party member |
| Phaidros | 4 | 80 | Slowest, but tankiest |

**Current Character Constitution Values:**
| Character | Vigor | AP Cap | Notes |
|-----------|-------|--------|-------|
| Cyrus | 6 | 6 | Can bank up to 6 AP |
| Vaughn | 5 | 5 | Lower cap, relies on speed |
| Phaidros | 9 | 9 | High cap, can save for big turns |

---

## Design Decisions Log

### 2025-02-15: Initial CTB + AP System

**Decision:** Combine FFX-style CTB with an Action Point system

**Rationale:**
- FFX's visible, dynamic turn order creates strategic depth
- AP system allows multiple actions per turn, more tactical options
- Remaining AP converting to speed creates interesting "save vs spend" decisions
- AP conservation (players only) rewards long-term planning and gives player advantage

**Key Rules:**
- Remaining AP both speeds up next turn AND carries over (double benefit for saving)
- Enemies do not conserve AP (player advantage, simpler AI)
- Players must explicitly end turn (deliberate choice to stop acting)
- Constitution determines max AP pool (stat has tactical meaning)

**Open Questions:**
- Should heavy skills cost 3 AP, or is that too much given base of 3?
- Is AP_TO_TICKS_RATIO of 5 enough to make saving AP feel impactful?
- Should there be a minimum ticks floor to prevent speed-stacking abuse?

---

## Experiments To Try

### Planned Tests

1. **AP costs**: Try base AP of 4 or 5 to allow more actions per turn
2. **Speed scaling**: Adjust SPEED_MULTIPLIER to change how much speed matters
3. **AP tick ratio**: Increase AP_TO_TICKS_RATIO to make saving AP more rewarding
4. **Action-based delays**: Later, add per-action tick costs (heavy attacks delay more)

### Backlog Ideas

- Haste/Slow status effects that modify tick calculations
- "Quick" actions that cost AP but don't consume your turn
- Combo system where certain action sequences cost less AP
- Burst mode interaction with AP system

---

## Archived Experiments

_(Record past experiments here with results)_

### Template:
```
### [Date]: [Experiment Name]
**Change:** What was modified
**Values:** Old → New
**Result:** What happened in playtesting
**Verdict:** Keep / Revert / Modify further
```

---

## Quick Reference Card

```
TURN ORDER
  Your turn when: ticks reach 0
  Ticks = 100 - (Speed × 5) - (Remaining AP × 5)
  Ties: Higher Speed wins, then random

ACTION POINTS
  Base: 3 AP per turn
  Max Pool: Constitution (players only)
  Conservation: Unused AP → next turn (players only)

COSTS
  Attack: 1 AP    Move: 1 AP    Light Skill: 1 AP
  Standard Skill: 2 AP    Heavy Skill: 3 AP    Defend: 0 AP
```
