# Combat Design Document v2
**Date:** 2026-02-21 (Updated: 2026-02-21 - Distance-Based Rows)
**Status:** Active Design
**Author:** Design Team

---

## Executive Summary

This document outlines the refined combat system for Disruption, emphasizing tabletop compatibility while maintaining the depth of classic turn-based JRPGs. The system balances strategic positioning, resource management, and team coordination without the complexity overhead of pure tactical games.

**Design Philosophy:**
- Lean toward Final Fantasy/Chrono Trigger feel over Final Fantasy Tactics complexity
- Maintain tabletop compatibility as a core requirement
- Create meaningful positional strategy without complex grid calculations
- Encourage aggressive, coordinated play over defensive turtling
- Balance multiple resource systems (AP, MP, Equipment Charges, Momentum, Blood & Soil)
- **Grid-agnostic design** - All mechanics work with any grid size or shape (squares, hexes, irregular)

**Core Pillars:**
1. **Team Coordination** - Momentum system rewards focused, cooperative strikes
2. **Territorial Strategy** - Blood & Soil mechanic creates meaningful positioning decisions
3. **Resource Tension** - Multiple resource types create layered tactical decisions
4. **Accessibility** - Complex systems with simple interfaces for tabletop play
5. **Scalability** - Systems work on any battlefield size (5×5 to 20×20+)

---

## Table of Contents

1. [Range Bands (Simplified Distance)](#1-range-bands-simplified-distance)
2. [Dynamic Row System (Distance-Based Positioning)](#2-dynamic-row-system-distance-based-positioning)
3. [Blood & Soil System (Territorial Control)](#3-blood--soil-system-territorial-control)
4. [Momentum System (Coordinated Strikes)](#4-momentum-system-coordinated-strikes)
5. [Equipment Charge System (Glyphion Artifacts)](#5-equipment-charge-system-glyphion-artifacts)
6. [Action Point Economy](#6-action-point-economy)
7. [Combat Flow Integration](#7-combat-flow-integration)
8. [Grid Shape & Scalability](#8-grid-shape--scalability)
9. [Tabletop Implementation](#9-tabletop-implementation)
10. [Design Synergies & Tensions](#10-design-synergies--tensions)
11. [Balance Framework](#11-balance-framework)
12. [Implementation Roadmap](#12-implementation-roadmap)

---

## 1. Range Bands (Simplified Distance)

### Overview
Instead of calculating exact grid distances, combat uses three intuitive range bands that are easy to assess visually on tabletop or digital play.

### Range Band Definitions

| Range Band | Distance | Description |
|------------|----------|-------------|
| **Melee (M)** | Adjacent tiles | 1 space Manhattan distance |
| **Close (C)** | Nearby | 2-3 spaces away |
| **Distant (D)** | Far | 4+ spaces away |

### Range Mechanics

**Ability Targeting:**
- All abilities specify their valid range: "Melee attack", "Close range skill", "Distant spell"
- Players assess range visually: "Am I adjacent? Within 3 spaces? Beyond 3 spaces?"
- No complex distance calculations required

**Integration with Dynamic Rows:**
- Range Bands determine which enemies you can target
- Your current range to enemies determines your Dynamic Row (see next section)
- Dynamic Rows provide tactical bonuses based on proximity to danger

### Design Rationale

**Tabletop Friendly:**
- Players can eyeball distances without measuring tools
- Reduces analysis paralysis from exact tile counting
- Maintains tactical positioning without complexity overhead

**Strategic Depth:**
- Distance to enemies creates dynamic risk/reward
- Encourages positioning awareness
- Creates emergent tactics as battlefield shifts

**Grid-Agnostic:**
- Works identically on square grids, hex grids, or irregular battlefields
- Scales to any battlefield size (5×5 or 50×50)
- No hardcoded position assumptions

**Digital Implementation:**
- Range indicators can highlight valid targets
- Tooltip shows "Melee/Close/Distant" for quick reference
- Visual feedback for range band transitions
- Dynamic Row status updates in real-time as units move

---

## 2. Dynamic Row System (Distance-Based Positioning)

### Overview
Instead of fixed "front/mid/back" grid positions, a unit's "row" is determined dynamically by their **current distance to the nearest enemy**. This creates a fluid, scalable positioning system that works on any grid size or shape.

### Row Definitions

| Dynamic Row | Condition | Meaning |
|-------------|-----------|---------|
| **Front Row** | Melee range (adjacent) to ≥1 enemy | "In immediate danger" |
| **Mid Row** | Close range (2-3 spaces) to nearest enemy | "Moderately exposed" |
| **Back Row** | Distant range (4+ spaces) to all enemies | "Relatively safe" |

**Key Principle:** Your row changes as enemies move, as you move, or as enemies are defeated. It's a dynamic property, not a fixed position.

### Row Bonuses & Penalties

**Front Row (In the Thick of It):**
- **Bonus:** Melee abilities gain +1 effective range band (can hit Close range targets)
- **Penalty:** Easier for enemies to target (more enemies can reach you)
- **Tactical Use:** Aggressive melee characters, tanks drawing fire

**Mid Row (Balanced Position):**
- **Bonus:** None (standard performance)
- **Penalty:** None
- **Tactical Use:** Versatile characters, ranged attackers with decent defense

**Back Row (Safe Distance):**
- **Bonus:** Ranged abilities gain +1 effective range band (can hit beyond Distant)
- **Penalty:** Limited target selection for melee abilities (may have no valid targets)
- **Tactical Use:** Fragile spellcasters, snipers, support characters

### Dynamic Row Interactions with Blood & Soil

**The Tension:**
- Blood & Soil rewards staying on the same tile (building Soil Tokens)
- Dynamic Rows change based on distance to enemies, regardless of your tile
- **Example:** You stay rooted (building Soil), but enemies approach you → Your row shifts from Back → Mid → Front while you gain Soil bonuses

**Strategic Implications:**
1. **Rooted Tank:** Stays on tile, enemies close in, becomes Front Row naturally → High Soil + Front Row bonus = Melee powerhouse
2. **Mobile Archer:** Moves to maintain Back Row status, sacrifices Soil → Consistent ranged advantage, no Soil bonuses
3. **Defensive Stand:** Party roots in Back Row, forces enemies to approach → Build Soil while maintaining safety, shift to Front Row only when engaged

### Why Distance-Based Rows?

**Scalability:**
- Works on 5×5 grid or 20×20 grid identically
- No need to define "which columns are front row" for each grid size
- Encounter designers can use any battlefield shape

**Grid-Shape Agnostic:**
- Square grids: Count Manhattan distance
- Hex grids: Count hex distance
- Irregular battlefields: Count shortest path
- Rules never change

**Tactical Dynamism:**
- Rows shift organically as combat progresses
- Defeating front-line enemies pushes your row back (safer)
- Flanking enemies shifts your row forward (danger!)
- Creates emergent gameplay without complex rules

**Tabletop Clarity:**
- "Count spaces to nearest enemy" is simple
- No memorizing fixed zone boundaries
- Intuitive: "I'm next to an enemy = Front Row = danger"

### Examples

**Scenario 1 - Small Battlefield (7×5):**
```
Turn 1:
[E] = Enemy at position (5,2)
[A] = Ally at position (1,2)

Distance: 4 spaces → Ally is in Back Row
```

**Scenario 2 - After Movement:**
```
Turn 3:
[E] = Enemy moved to (3,2)
[A] = Ally still at (1,2)

Distance: 2 spaces → Ally is now in Mid Row (dynamic shift!)
```

**Scenario 3 - Large Battlefield (15×10):**
```
Turn 1:
[E] = Enemy at position (12,5)
[A] = Ally at position (2,5)

Distance: 10 spaces → Ally is in Back Row
(Same rule, different grid size)
```

### UI Implementation

**Digital Display:**
- Unit portrait shows current row icon: [⚔️ Front] [➡️ Mid] [🏹 Back]
- Icon updates in real-time as distances change
- Mouseover shows: "Front Row: Melee +1 range, but exposed"

**Tabletop Play:**
- Quick mental count: "How far to nearest enemy?"
- Reference card shows: 1 = Front, 2-3 = Mid, 4+ = Back
- No tokens needed (derived from board state)

---

## 3. Blood & Soil System (Territorial Control)

### Core Concept
Units that hold position become "rooted" to their tile, drawing power from their established territory. This represents channeling Exousia from blood-soaked ground and stable footing.

### Rooting Mechanics

**Gaining Soil Tokens:**
- When a unit begins their turn on the same tile they ended their previous turn, they are "rooted"
- Rooted units gain +1 Soil Token at the start of their turn
- Maximum 3 Soil Tokens from passive accumulation
- Moving to a different tile removes all Soil Tokens

**Soil Bonus Table:**

| Soil Tokens | Bonus Effects |
|-------------|---------------|
| 0 | No bonuses (just moved) |
| 1 | +5% damage dealt |
| 2 | +5% damage dealt, +10% damage resistance |
| 3 | +10% damage dealt, +10% damage resistance, +1 MP regeneration |
| 4+ | +15% damage dealt, +15% damage resistance, +2 MP regeneration |

**Note:** 4+ Soil Tokens can only be achieved through Blood Sanctification (see below).

### Advanced Soil Mechanics

**Hostile Soil:**
- Standing on a tile where an enemy was previously rooted (had 2+ Soil Tokens) disrupts the Exousia flow
- Attacker on hostile soil: Enemy has -10% accuracy when targeting you
- Represents "corrupting" or "disrupting" their established ground
- Hostile soil markers fade after 2 turns or when the tile is re-rooted by anyone

**Blood Sanctification:**
- When a unit defeats an enemy while fully rooted (3 Soil Tokens), the ground becomes "blood-sanctified"
- That tile gains a permanent +1 Soil Token bonus for that unit for the rest of combat
- This allows reaching 4 Soil Tokens (max cap)
- Represents the concept of "blood and water" - power drawn from sacrifice
- Only the sanctifying unit benefits from the +1 bonus; allies standing there get normal Soil

**Character Type Modifiers:**
- **Shaper-type characters:** Gain Soil Tokens 50% faster (1.5 per turn, rounded down: every other turn gains 2 tokens)
- **Sourcerer-type characters:** Lose only half their Soil when moving (rounded down), can reposition while maintaining some territorial advantage
- **Glyphein (hybrid):** Choose which bonus applies at the start of combat

### Strategic Implications

**Tension Creation:**
- Momentum system encourages repositioning to focus targets
- Soil system rewards holding ground
- Creates meaningful "move or stay" decisions every turn

**Defensive Anchor:**
- Tanks can "dig in" to become increasingly resilient
- High Soil + Dynamic Front Row (enemies close) = Maximum threat
- Encourages enemy repositioning abilities to disrupt rooted defenders

**Offensive Escalation:**
- DPS characters gain increasing damage while holding position
- Creates incentive to "claim" high-value positions (central, good sightlines)
- Blood Sanctification provides victory momentum (getting stronger as you win)

**Dynamic Row Synergy:**
- Rooted character in Back Row builds Soil safely (3+ tokens common)
- Enemies approach → Character shifts to Mid/Front Row dynamically
- Gains both high Soil bonuses AND Dynamic Row combat bonuses
- Creates powerful defensive positions that enemies must disrupt

### Lore Integration

**World Building Connection:**
- Directly reflects "Blood and Soil" theme from world lore
- Shapers draw power from the land (faster Soil gain)
- Sourcerers maintain internal power reserves (keep Soil when moving)
- Blood Sanctification ties to sacrifice and the cost of power

---

## 4. Momentum System (Coordinated Strikes)

### Core Concept
Focused attacks on a single target build shared Momentum that the entire party can exploit for devastating finishing moves or status effects. This encourages team coordination and focus-fire tactics.

### Building Momentum

**Momentum Accumulation:**
- Each successful hit on an enemy adds +1 Momentum counter to that enemy
- Momentum is a property of the enemy, not the attacker (shared resource)
- Maximum 5 Momentum per enemy
- All party members can see and utilize accumulated Momentum

**Momentum Decay:**
- Momentum decays by 1 at the END of the enemy's turn
- If enemy is staggered/stunned and cannot act, Momentum does NOT decay that turn
- Gives party the full turn cycle to capitalize on built Momentum
- Complete wipe (all enemies defeated) resets all Momentum to 0

### Consuming Momentum

Abilities are categorized by their Momentum interaction:

**Momentum Ability Types:**

**1. Amplifiers (Builders)**
- Do NOT consume Momentum
- Deal bonus damage: +(10% × Momentum) damage
- Used to build toward the 5 Momentum cap
- Example: "Rapid Strike" - deals normal damage + 10% per Momentum, builds +1 Momentum

**2. Exploiters (Status Applicators)**
- Consume Momentum to apply status effects
- Effectiveness scales with Momentum consumed
- Momentum Thresholds:
  - **2 Momentum:** Basic status (Bleed, Slow, Weakened, Poison)
  - **4 Momentum:** Severe status (Stun, Disarm, Root, Fear)
  - **5 Momentum:** Rare status (Marked, Dominated, Cursed, Shattered)
- Example: "Hamstring" - Consumes 2+ Momentum, applies Slow, duration = Momentum consumed

**3. Breakers (Finishers)**
- Consume ALL accumulated Momentum
- Deal massive burst damage: +(20% × Momentum) damage
- If Momentum ≥ 3: Target is Staggered for 1 turn (loses next action)
- Resets the Momentum counter to 0
- Example: "Executioner's Strike" - Consumes all Momentum, deals bonus damage, staggers if 3+

### Equipment Momentum Interactions

**Special Glyphion Equipment Effects:**
- **Earthquake (Earth Gauntlets):** Consumes all Momentum from ALL enemies, deals AoE damage proportional to total consumed
- **Assassinate (Shadow Cloak):** Requires exactly 5 Momentum on target, deals 3x damage, instant kill if target below 30% HP
- **Temporal Rewind (Chronos Shard):** Restores consumed Momentum to target enemy, allows re-using it for a different effect
- **Chain Lightning (Storm Orb):** Spreads half of target's Momentum to adjacent enemies after hit

### Strategic Depth

**Turn Order Coordination:**
- Fast characters build Momentum early
- Slower characters with Breaker abilities capitalize later in the round
- Encourages CTB manipulation and turn order planning

**Target Selection:**
- Focus fire on priority targets to build Momentum quickly
- Split attacks when multiple enemies need status effects
- Momentum visibility creates clear team objectives

**Ability Loadout Diversity:**
- Teams need mix of Amplifiers (builders), Exploiters (control), and Breakers (damage)
- Characters can specialize in Momentum roles
- Equipment provides Momentum utility that skills might lack

### Tabletop Implementation

**Visual Tracking:**
- Place a d6 next to each enemy showing current Momentum (0-5)
- Skill cards clearly marked with icon: [A] Amplifier, [E] Exploiter, [B] Breaker
- Simple rule: "Hit = +1 Momentum, unless ability says otherwise"

**Example Combat Sequence:**
1. Vaughn hits Enemy A → Momentum 1
2. Cyrus hits Enemy A → Momentum 2
3. Phaidros uses Amplifier on Enemy A → Momentum 3, deals +30% damage
4. Vaughn uses Breaker on Enemy A → Consumes 3, deals +60% damage, staggers

---

## 5. Equipment Charge System (Glyphion Artifacts)

### Overview
Glyphion equipment provides powerful, charge-limited abilities that operate independently of MP. These represent rare artifacts channeling concentrated Exousia.

### Equipment Structure

**Equip Slots:**
- Each character can equip 1-3 Glyphion items (limited by progression/level)
- Common loadout: 1 Weapon + 1 Armor + 1 Accessory
- Each item provides passive stats + 1 active ability

**Charge Mechanics:**
- Each equipment ability has 1-3 charges per combat
- Charges do NOT regenerate during combat (very limited resource)
- Charges reset fully between combats
- Using an equipment ability consumes 1 charge

### Equipment Categories

**Offensive Equipment (2-3 charges typical):**
- High damage or special offensive effects
- Lower AP cost than equivalent MP abilities (1-2 AP vs 2-3 AP)
- Examples:
  - **Flame Brand (Weapon):** 3 charges, 2 AP - Fire AoE attack, ignores 50% resistance
  - **Void Dagger (Weapon):** 2 charges, 1 AP - Single target, ignores all armor
  - **Thunder Lance (Weapon):** 2 charges, 2 AP - Chain lightning, bounces to 3 targets

**Defensive Equipment (2 charges typical):**
- Protection, healing, or tactical repositioning
- Examples:
  - **Earth Gauntlets (Armor):** 2 charges, 2 AP - Earthquake (damage) or Earthen Wall (barrier)
  - **Displacement Orb (Accessory):** 2 charges, 1 AP - Teleport self or ally to any empty tile
  - **Phoenix Mantle (Armor):** 1 charge, 0 AP (Reaction) - Auto-resurrect with 30% HP when defeated

**Utility Equipment (1-2 charges typical):**
- Game-changing tactical effects
- Examples:
  - **Chronos Shard (Accessory):** 1 charge, 2 AP - Target acts immediately (or delay target by 3 turn positions)
  - **Siphon Ring (Accessory):** 2 charges, 1 AP - Drain 5 MP and 10% max HP from target
  - **Mimic's Mask (Accessory):** 1 charge, 2 AP - Copy the last ability used by any unit in combat

### Charge Recovery Mechanics

**Conditional Reload:**
- Some legendary equipment can regain charges mid-combat under specific conditions
- Examples:
  - **Reaper's Edge:** Regain 1 charge when scoring a killing blow
  - **Martyr's Shield:** Regain 1 charge when dropping below 25% HP
  - **Gambler's Die:** 50% chance to not consume charge on use
  - **Blood Drinker:** Regain 1 charge per 3 enemies defeated while equipped

**Balance Consideration:**
- Conditional reload should be rare and hard to achieve
- Prevents equipment from overshadowing MP abilities
- Creates exciting "clutch" moments when conditions align

### Strategic Implications

**Resource Decisions:**
- "Do I use this powerful charge now, or save it for a critical moment?"
- Limited charges create meaningful scarcity
- Early usage provides advantage; late usage provides flexibility

**Build Diversity:**
- Characters can be built around specific equipment synergies
- Equipment choice changes playstyle significantly
- Trade-offs between high-charge versatile items vs. low-charge powerful items

**Momentum Integration:**
- Some equipment abilities have Momentum requirements or bonuses
- Creates layered resource management (charges + Momentum)
- Example: "Shadow Strike" requires 5 Momentum + 1 charge, but deals 4x damage

### Lore Integration

**Glyphion Artifacts:**
- Equipment represents Glyphein craftsmanship (hybrid Sourcerer/Shaper creations)
- Charges represent the crystallized Exousia stored in the item
- Using abilities "discharges" the stored power
- Resting between combats allows the artifact to "recharge" by drawing ambient Exousia

---

## 6. Action Point Economy

### Core AP System

**Base AP Per Turn:** 3 AP (may be modified by Constitution stat)

**AP Allocation:**
- Players receive full AP pool at start of their turn
- AP can be spent in any order on available actions
- Unused AP is lost (except for AP Banking, see below)
- Some abilities cost more AP than you have (requires skipping actions or using bonus AP sources)

### Action Costs

| Action Type | AP Cost | Notes |
|-------------|---------|-------|
| **Basic Attack** | 1 AP | Always available, no MP cost |
| **Movement** | 1 AP | Move to adjacent tile, breaks Blood & Soil |
| **Standard Skill** | 2 AP | Most MP-costing abilities |
| **Powerful Skill** | 3 AP | High-impact MP abilities, often 4+ MP cost |
| **Equipment Ability** | 1-2 AP | Charge-limited but AP-efficient |
| **Defend** | 0 AP | Ends turn immediately, +50% damage resistance until next turn |
| **Item Use** | 1 AP | Consumables (potions, bombs, etc.) |
| **Swap Position** | 1 AP | Trade places with adjacent ally |

### AP Banking

**Mechanic:**
- Ending turn with 2+ AP remaining grants a turn order bonus
- Next turn comes 1-2 CTB positions earlier (faster initiative)
- Represents conserving energy for quicker reaction

**Banking Tiers:**
- 2 AP remaining: +1 position earlier in next turn order
- 3 AP remaining: +2 positions earlier in next turn order

**Strategic Consideration:**
- Trade current turn power for next turn speed
- Useful for interrupt-heavy characters
- Creates decision: "Go all-out now, or act sooner next turn?"

### Constitution Modifier

**AP Pool Scaling:**
- Base 3 AP for all characters
- High Constitution (7-10): +1 AP per turn (4 total)
- Very Low Constitution (1-3): -1 AP per turn (2 total)

**Balance Note:**
- Most characters have 4-6 Constitution (3 AP standard)
- Tank characters (Phaidros) may reach 4 AP
- Glass cannon characters may have 2 AP but compensate with power

### Bonus AP Sources

**Status Effects:**
- **Energized:** +1 AP for duration
- **Quickened:** +2 AP for 1 turn (rare)
- **Exhausted:** -1 AP for duration

**Equipment Passives:**
- Some equipment provides +1 AP (very rare, often with drawbacks)
- Example: "Berserker's Rage" - +1 AP but take 10% more damage

**Blood & Soil:**
- 3 Soil Tokens: +1 MP regen (not AP, but enables more MP ability usage)

### AP Costs for Specific Mechanics

**Momentum Abilities:**
- Amplifiers: Typically 1-2 AP (encourage building)
- Exploiters: Typically 2 AP (moderate cost for utility)
- Breakers: Typically 2-3 AP (high damage justifies high cost)

**Equipment Abilities:**
- Designed to be AP-efficient (1-2 AP) to compensate for limited charges
- Encourages mixing equipment abilities with MP skills

### Turn Example

**Cyrus (3 AP, rooted with 2 Soil Tokens):**

**Option A - Aggressive:**
1. Basic Attack (1 AP) → Builds Momentum on Enemy A
2. Elemental Slash skill (2 AP, 3 MP) → Breaker ability, consumes Momentum
3. Turn ends, lost Soil Tokens due to no banking

**Option B - Sustainable:**
1. Basic Attack (1 AP) → Builds Momentum
2. End Turn (2 AP banked) → Next turn comes +2 positions earlier
3. Keeps 2 Soil Tokens, can use big skill earlier next turn

**Option C - Positional:**
1. Movement (1 AP) → Loses Soil, gets into better range
2. Equipment Ability: Void Dagger (1 AP, 1 charge) → High damage, no MP
3. Basic Attack (1 AP) → Builds Momentum on new target

---

## 7. Combat Flow Integration

### Turn Structure

**1. Turn Start Phase:**
- Check Blood & Soil: If on same tile as last turn, gain +1 Soil Token
- Apply start-of-turn status effects (Regen, Burn, Energized)
- Receive AP pool (3 + modifiers)
- Receive MP regeneration (2-3 base + Soil bonuses)

**2. Action Phase:**
- Player/AI selects actions and spends AP
- Each action resolves immediately (no batching)
- Momentum builds/consumes during this phase
- Movement immediately breaks Soil

**3. Turn End Phase:**
- Apply end-of-turn status effects (Poison, Bleed)
- Check AP Banking: If 2+ AP remaining, mark for initiative bonus
- Update status effect durations
- Enemy Momentum decays by 1 (if that enemy's turn)

**4. Between Turns:**
- CTB system calculates next acting unit
- Apply AP Banking initiative adjustments
- Update turn order preview UI

### Complete Combat Example

**Setup:**
- Party: Cyrus (tile 1,2), Vaughn (tile 1,1), Phaidros (tile 0,3)
- Enemies: Elite Guard A (tile 5,2), Elite Guard B (tile 5,1), Archer C (tile 6,4)
- Grid: 7×5 squares
- Turn Order: Vaughn → Elite A → Cyrus → Elite B → Phaidros → Archer C

**Initial Dynamic Rows (based on distance to nearest enemy):**
- Cyrus: 4 spaces to Elite A → **Back Row**
- Vaughn: 4 spaces to Elite B → **Back Row**
- Phaidros: 5 spaces to Elite A → **Back Row**

---

**Round 1, Turn 1 - Vaughn:**
- Position: Tile (1,1), 4 spaces to Elite B → **Back Row** (ranged +1 range)
- Soil: 0 (just started)
- Action: Precise Strike on Elite B (2 AP, 2 MP) → Amplifier, uses Back Row bonus to hit at range
  - Elite B gains +1 Momentum (total: 1)
  - Deals 110% damage (base + 10% from 1 Momentum)
- Action: Basic Attack on Elite B (1 AP)
  - Elite B gains +1 Momentum (total: 2)
- Ends turn with 0 AP, stays on same tile to root

**Round 1, Turn 2 - Elite Guard A:**
- Moves 2 spaces forward to (3,2)
- Attacks Cyrus (now only 2 spaces away)
- **Cyrus' Dynamic Row shifts:** Was Back Row → now **Mid Row** (enemy 2 spaces away)
- Cyrus takes damage

**Round 1, Turn 3 - Cyrus:**
- Position: Tile (1,2), 2 spaces to Elite A → **Mid Row** (shifted from Back!)
- Soil: 1 (rooted from Round 0 setup) → gains +1 = 2 total (+5% dmg, +10% resist)
- Action: Basic Attack on Elite A (1 AP, Mid Row allows Melee targeting at 2 spaces? No - must move)
- Action: Move to (2,2) → Loses Soil, now adjacent to Elite A
- **Cyrus' Dynamic Row shifts:** Was Mid Row → now **Front Row** (adjacent to enemy)
- Action: Basic Attack on Elite A (1 AP)
  - Elite A gains +1 Momentum (total: 1)

**Round 1, Turn 4 - Elite Guard B:**
- Attacks Vaughn (ranged attack)
- Vaughn takes damage, still in Back Row (safe distance)

**Round 1, Turn 5 - Phaidros:**
- Position: Tile (0,3), 5 spaces to nearest enemy → **Back Row**
- Soil: 2 (rooted) → gains +1 = 3 total (+10% dmg, +10% resist, +1 MP regen)
- Action: Equipment - Earth Gauntlets: Earthquake (2 AP, 1 charge)
  - Uses Back Row ranged bonus to hit at extended range
  - AoE hits Elite A and Elite B
  - Elite A gains +1 Momentum (total: 2)
  - Elite B gains +1 Momentum (total: 3)
- Ends turn with 1 AP remaining, stays rooted in Back Row

**Round 1, Turn 6 - Archer C:**
- Attacks from Back Row (tile 6,4), targets Vaughn
- Vaughn takes damage

---

**Round 2, Turn 1 - Vaughn:**
- Soil: 1 (rooted from last turn) → gains +1 = 2 total (+5% dmg, +10% resist)
- Action: Hamstring on Elite A (2 AP, 3 MP) → Exploiter
  - Consumes 3 Momentum from Elite A
  - Applies Slow status for 3 turns
  - Elite A now at 0 Momentum
- Action: Basic Attack on Elite A (1 AP)
  - Elite A gains +1 Momentum (total: 1)

**Round 2, Turn 2 - Elite Guard A:**
- Slowed, acts later in turn order
- Elite A's turn ends → Momentum decays by 1 (total: 0)

**Round 2, Turn 3 - Cyrus (AP Banking bonus - acts 2 positions early):**
- Soil: 3 (rooted) → gains +1 but capped at 3 (+10% dmg, +10% resist, +1 MP regen)
- Has bonus MP from Soil, can afford powerful skill
- Action: Elemental Slash on Elite B (2 AP, 4 MP) → Breaker
  - Consumes 1 Momentum from Elite B
  - Deals +20% damage, but not enough to stagger (needs 3 Momentum)
  - Elite B now at 0 Momentum
- Action: Basic Attack on Elite B (1 AP)
  - Elite B gains +1 Momentum

**Round 2, Turn 4 - Phaidros:**
- Soil: 3 (max) → stays at 3
- Action: Basic Attack on Elite A (1 AP)
  - Elite A gains +1 Momentum (total: 1)
- Action: Basic Attack on Elite A (1 AP)
  - Elite A gains +1 Momentum (total: 2)
- Action: Executioner's Strike on Elite A (1 AP, equipment ability, 1 charge) → Breaker
  - Consumes 2 Momentum from Elite A
  - Deals +40% damage, defeats Elite A
  - **Blood Sanctification:** Phaidros was at 3 Soil when defeating enemy
  - Phaidros' current tile gains permanent +1 Soil bonus (now has 4 Soil Tokens)
  - 4 Soil: +15% dmg, +15% resist, +2 MP regen

---

**Result:**
- Elite Guard A defeated
- Phaidros blood-sanctified and extremely powerful on his tile
- Team building Momentum on remaining enemies
- Cyrus positioned to act early next round due to AP Banking

### Key Interactions Demonstrated

1. **Momentum Building → Consuming:** Team focused Elite A, built 3 Momentum, Vaughn consumed it for Slow status
2. **Blood & Soil Escalation:** Phaidros went from 0 → 4 Soil, becoming significantly stronger
3. **AP Banking:** Cyrus sacrificed 1 turn of full damage to act earlier in Round 2
4. **Equipment Integration:** Phaidros used equipment for efficient AoE, saved MP for other units
5. **Blood Sanctification:** Phaidros achieved max power by defeating enemy while rooted

---

## 8. Grid Shape & Scalability

### Overview
The combat system is designed to be grid-agnostic, working equally well with square grids, hexagonal grids, or even irregular battlefields. All mechanics reference distance (Range Bands) or tile occupancy (Blood & Soil), not specific grid layouts.

### Square Grids

**Distance Calculation:** Manhattan distance (|x1-x2| + |y1-y2|)

**Advantages:**
- Familiar to players (chess, checkers)
- Easy to draw/print for tabletop
- Simple coordinate system
- Graph paper readily available

**Disadvantages:**
- Diagonal movement creates distance ambiguity
- 4 orthogonal neighbors only (limits tactical options)
- Less organic appearance

**Grid Sizes:**
- Small Skirmish: 5×5 (25 tiles)
- Standard Battle: 7×5 (35 tiles)
- Large Encounter: 10×7 (70 tiles)
- Epic Battle: 15×10 (150 tiles)

### Hexagonal Grids

**Distance Calculation:** Hex distance using cube coordinates

**Advantages:**
- All 6 neighbors equidistant (no diagonal weirdness)
- 50% more positioning options than squares
- Better range visualization (concentric hex rings)
- More organic, natural appearance
- Cleaner AoE patterns

**Disadvantages:**
- Slightly more complex coordinate math
- Harder to manufacture/print for tabletop
- Less familiar to non-wargamers

**Grid Sizes:**
- Small Skirmish: ~25 hexes (3-4 hex radius)
- Standard Battle: ~35 hexes (4-5 hex radius)
- Large Encounter: ~70 hexes (5-6 hex radius)
- Epic Battle: ~150 hexes (7-8 hex radius)

**Hex Orientation:**
- **Flat-Top:** Easier for horizontal battlefields
- **Pointy-Top:** Easier for vertical battlefields
- Rules identical for both orientations

### Grid-Agnostic Design Principles

**Distance-Based Mechanics:**
- Range Bands use counted spaces, not grid-specific math
- Dynamic Rows based on distance to nearest enemy
- Blood & Soil tracks tile occupancy, not coordinates
- Momentum is enemy property, unrelated to grid

**Scalability:**
- Same rules work on 5×5 or 50×50
- Encounter designers choose appropriate battlefield size
- Larger grids = more movement options, longer combats
- Smaller grids = faster, more constrained tactical puzzles

**Implementation Flexibility:**
- Digital version can use hexes for better UX
- Tabletop version can use squares for easier setup
- Players choose preferred grid shape
- All use identical combat rules

### Recommended Grid Shapes by Context

| Context | Recommended Grid | Reason |
|---------|------------------|--------|
| Digital Play | Hexagonal | Better UX, cleaner distances, no implementation cost |
| Tabletop Play | Square | Easier to manufacture, familiar to players |
| Tournament/Competitive | Hexagonal | More tactical depth, balanced positioning |
| Casual/Introductory | Square | Lower barrier to entry |
| Boss Fights | Either, Large Size | Epic scale, multiple phases |
| Quick Encounters | Either, Small Size | Fast resolution, high intensity |

### Technical Implementation Notes

**For Square Grids:**
```
Distance = abs(x1 - x2) + abs(y1 - y2)
Neighbors = [(x±1, y), (x, y±1)]  # 4 orthogonal
```

**For Hex Grids (Offset Coordinates):**
```
Distance = cube_distance(offset_to_cube(pos1), offset_to_cube(pos2))
Neighbors = 6 directional offsets based on row parity
```

**Grid Configuration (combat_config.json):**
```json
{
  "grid": {
    "shape": "hex" | "square",
    "size": [7, 5],
    "hex_orientation": "flat" | "pointy"  // if hex
  }
}
```

### Future Expansion: Irregular Battlefields

**Concept:** Non-rectangular grids with environmental features
- L-shaped battlefields
- Circular arenas
- Multi-elevation platforms
- Destructible terrain

**Compatibility:** All systems remain functional:
- Range Bands: Count shortest valid path
- Dynamic Rows: Distance to nearest enemy
- Blood & Soil: Any tile can be rooted
- Momentum: Enemy property, grid-independent

---

## 9. Tabletop Implementation

### Physical Components

**Required Tokens/Dice:**
- **Soil Tokens:** Colored d6 placed under each unit miniature (shows 0-4)
  - Different color for blood-sanctified tiles (e.g., red d6)
- **Momentum Dice:** d6 placed next to each enemy miniature (shows 0-5)
- **AP Tokens:** Small beads/chips (3 per player, spend as used)
- **Equipment Charge Trackers:** Flip cards or tokens next to character sheets
- **Status Effect Markers:** Colored rings/tokens placed on miniatures
- **Hostile Soil Markers:** Small transparent tokens on disrupted tiles

### Play Aid Cards

**Player Reference Card (Front):**
```
RANGE BANDS:
- Melee (M): Adjacent (1 space)
- Close (C): Nearby (2-3 spaces)
- Distant (D): Far (4+ spaces)

DYNAMIC ROWS (distance to nearest enemy):
- Front: 1 space (Melee +1 range)
- Mid: 2-3 spaces (Normal)
- Back: 4+ spaces (Ranged +1 range)

ACTION COSTS:
- Basic Attack: 1 AP
- Movement: 1 AP (breaks Soil)
- Skill (Standard): 2 AP
- Skill (Powerful): 3 AP
- Equipment: 1-2 AP
- Defend: 0 AP (ends turn)
- Item: 1 AP

SOIL BONUSES:
1 Token: +5% damage
2 Tokens: +5% dmg, +10% resist
3 Tokens: +10% dmg, +10% resist, +1 MP
4 Tokens: +15% dmg, +15% resist, +2 MP
```

**Player Reference Card (Back):**
```
TURN SEQUENCE:
1. Start: +1 Soil if didn't move
2. Gain AP (3 + mods) and MP regen
3. Take actions, spend AP
4. End: Status effects, bank AP if 2+

MOMENTUM:
- Each hit = +1 Momentum (max 5)
- Decays -1 at enemy turn end
[A] Amplifier: Don't consume, +10%/token
[E] Exploiter: Consume for status
[B] Breaker: Consume all, +20%/token

AP BANKING:
- End with 2 AP: Next turn +1 earlier
- End with 3 AP: Next turn +2 earlier
```

### Skill Card Format

Each skill card should clearly display:

```
┌─────────────────────────────────┐
│ EXECUTIONER'S STRIKE       [B]  │ ← Momentum type icon
├─────────────────────────────────┤
│ AP: 2  |  MP: 4  |  Range: M    │
├─────────────────────────────────┤
│ Consume all Momentum from       │
│ target. Deal +20% damage per    │
│ Momentum consumed.              │
│                                 │
│ If Momentum ≥ 3: Stagger target │
│ (lose next turn)                │
└─────────────────────────────────┘
```

### Equipment Card Format

```
┌─────────────────────────────────┐
│ EARTH GAUNTLETS (Armor)         │
├─────────────────────────────────┤
│ Passive: +2 VIG, +15 DEF        │
├─────────────────────────────────┤
│ ACTIVE: Earthquake              │
│ Charges: ○○ (2)                 │ ← Punch out circles when used
│ AP: 2  |  Range: Self (AoE)     │
├─────────────────────────────────┤
│ Deal damage to all enemies in   │
│ Melee range. Consume all their  │
│ Momentum, damage = 50 + (20 ×   │
│ total Momentum consumed)        │
└─────────────────────────────────┘
```

### Grid Setup

**Note:** There are no fixed "zones" or "rows" on the grid. All positioning is determined dynamically by distance to enemies.

**Square Grid Example (7×5):**
```
[0,0][1,0][2,0][3,0][4,0][5,0][6,0]
[0,1][1,1][2,1][3,1][4,1][5,1][6,1]
[0,2][1,2][2,2][3,2][4,2][5,2][6,2]
[0,3][1,3][2,3][3,3][4,3][5,3][6,3]
[0,4][1,4][2,4][3,4][4,4][5,4][6,4]
```

**Hex Grid Example (Flat-Top, ~35 hexes):**
```
  ⬡ ⬡ ⬡ ⬡ ⬡ ⬡ ⬡
 ⬡ ⬡ ⬡ ⬡ ⬡ ⬡ ⬡
  ⬡ ⬡ ⬡ ⬡ ⬡ ⬡ ⬡
 ⬡ ⬡ ⬡ ⬡ ⬡ ⬡ ⬡
  ⬡ ⬡ ⬡ ⬡ ⬡ ⬡ ⬡
```

**Tabletop Setup:**
- Use any grid size appropriate for the encounter
- Small skirmish: 5×5 squares or ~20 hexes
- Standard battle: 7×5 squares or ~35 hexes
- Large battle: 10×7 squares or ~70 hexes
- Players determine their Dynamic Row by counting distance to nearest enemy each turn

### Turn Order Tracker

**CTB Timeline Board:**
- Horizontal track showing next 8-10 turn positions
- Unit tokens placed on track, moved forward after actions
- AP Banking adjustments visible (move token forward)
- Easy visual for "when do I act next?"

---

## 10. Design Synergies & Tensions

### Intentional Design Tensions

**Movement vs. Soil:**
- **Momentum** often requires repositioning to reach optimal targets
- **Blood & Soil** rewards staying put to gain bonuses
- **Tension:** "Do I move to help build Momentum on priority target, or stay to maintain my Soil advantage?"
- **Resolution:** Equipment abilities provide ranged options, allowing Soil maintenance

**Burst Damage vs. Sustained Control:**
- **Breaker abilities** consume Momentum for burst damage
- **Exploiter abilities** consume Momentum for crowd control
- **Tension:** "Do we finish this enemy now, or lock down multiple threats?"
- **Resolution:** Different enemies require different approaches; team communication essential

**Equipment Charge Conservation vs. Early Power:**
- **Early usage** provides combat advantage and momentum
- **Late usage** provides insurance and clutch potential
- **Tension:** "Do I use my limited equipment charge now, or save it for emergency?"
- **Resolution:** Conditional Reload equipment rewards aggressive usage

**AP Spending vs. Banking:**
- **Full AP spending** maximizes current turn power
- **AP Banking** accelerates next turn, creating turn order advantage
- **Tension:** "Do I go all-out now, or act sooner next turn?"
- **Resolution:** Depends on turn order context (who acts between now and your next turn?)

### Positive Feedback Loops

**Blood Sanctification Momentum:**
- Defeating enemies while rooted grants permanent Soil bonus
- Higher Soil grants more damage
- More damage enables more defeats
- **Loop:** Victory → Stronger → More Victory
- **Counterbalance:** Enemies can force repositioning, breaking the loop

**Momentum Snowball:**
- Focused fire builds Momentum quickly
- High Momentum enables Breaker abilities
- Breakers defeat enemies faster
- **Loop:** Focus → Momentum → Burst → Victory
- **Counterbalance:** Momentum decays; switching targets resets progress

### Negative Feedback Loops

**Soil Disruption:**
- Enemies can force movement, breaking Soil
- High-value targets attract displacement abilities
- **Loop:** Become strong → Get displaced → Lose Soil → Become weaker
- **Counterbalance:** Defensive abilities prevent displacement

**Resource Depletion:**
- Equipment charges are finite
- Heavy equipment usage early leads to MP dependence late
- **Loop:** Use charges → Run out → Reduced options
- **Counterbalance:** Conditional Reload provides limited regeneration

### Synergy Combinations

**Tank Fortress (Phaidros Build):**
- Roots in central position, enemies approach (Dynamic Front Row)
- Blood & Soil (3-4 tokens) from staying rooted
- Defensive equipment for sustainability
- Breaker abilities to finish enemies while rooted
- **Synergy:** High Soil + Dynamic Front Row (when engaged) + Blood Sanctification = Unstoppable anchor

**Mobile Striker (Vaughn Build):**
- Maintains Back Row distance through repositioning
- Exploiter abilities with Back Row ranged bonus
- Equipment with movement/teleportation to maintain distance
- Focuses on Momentum building, sacrifices Soil
- **Synergy:** Mobility + Back Row safety + Status effects + Momentum manipulation = Tactical control

**Burst Assassin (Cyrus Build):**
- Starts in Back Row, moves to Front Row when Momentum is high
- Breaker abilities + AP Banking for optimal timing
- Equipment with Momentum requirements
- Waits for 5 Momentum, strikes with multiple Breakers in one turn
- **Synergy:** AP Banking speed + Dynamic Row flexibility + Breaker burst + Equipment finishers = Elimination specialist

---

## 11. Balance Framework

### Core Balance Principles

**Resource Tension:**
- No single resource should solve all problems
- AP limits action quantity, MP limits quality, Equipment provides spikes
- Momentum creates team dependency, Soil creates positional dependency

**Opportunity Cost:**
- Every action should compete with viable alternatives
- "Always optimal" actions indicate imbalance
- Movement, attacking, defending should all have clear use cases

**Counterplay Availability:**
- All strategies should have counterplay options
- High Soil characters: Displacement abilities
- Momentum stacking: AoE spread damage
- Equipment dependency: MP drain/disable effects

### Balance Levers

**Numerical Adjustments:**

| System | Primary Levers | Tuning Range |
|--------|---------------|--------------|
| Blood & Soil | Bonus percentages, token cap | ±5% per tuning pass |
| Momentum | Decay rate, max cap, bonus percentages | ±10% per tuning pass |
| Equipment Charges | Charge count, AP costs, power level | ±1 charge or ±20% power |
| AP Economy | Base AP, action costs | ±1 AP or ±1 AP cost |

**Systemic Adjustments:**
- Soil token gain rate (1 vs. 1.5 per turn)
- Momentum decay timing (turn start vs. turn end)
- Equipment charge recovery conditions (easier vs. harder)
- AP banking thresholds (2 AP vs. 3 AP requirement)

### Playtesting Metrics

**Target Metrics:**
- **Average Combat Duration:** 8-12 turns
- **Momentum Cap Frequency:** Reached 2-3 times per combat
- **Max Soil Frequency:** 1-2 characters reach 3 Soil per combat
- **Blood Sanctification Rate:** 20-30% of combats
- **Equipment Usage:** 80%+ of charges used per combat (prevent hoarding)
- **AP Banking:** Used in 30-40% of turns (common but not default)

**Warning Indicators:**
- **Too Fast:** Combats ending in <6 turns (damage too high)
- **Too Slow:** Combats lasting >15 turns (damage too low or too defensive)
- **Momentum Unused:** <1 cap reached per combat (decay too fast or building too slow)
- **Soil Ignored:** <50% of combats reach 3 Soil (movement forced too often or bonuses too weak)
- **Equipment Hoarding:** <50% of charges used (charges too scarce or abilities too weak)

### Character Archetype Balance

**Expected Power Distribution:**

**Tanks (Phaidros):**
- High Soil dependency, attracts enemies to become Dynamic Front Row
- Lower damage output, very high survivability
- Blood Sanctification enables late-game scaling
- **Balance:** Should be unkillable at 4 Soil + Front Row, but not outdamage DPS

**DPS (Cyrus):**
- Moderate Soil dependency, shifts between Mid/Front Row dynamically
- High burst damage via Breakers
- Equipment enables alpha strikes
- **Balance:** Should top damage charts but be vulnerable to focus fire

**Support/Control (Vaughn, Paidi):**
- Low Soil dependency, maintains Back Row distance when possible
- Exploiter abilities for crowd control
- Equipment provides utility
- **Balance:** Should enable team success, not carry alone

**Hybrid (Lione):**
- Adaptive playstyle, comfortable in any Dynamic Row
- Mix of all Momentum types
- Equipment flexibility
- **Balance:** Jack-of-all-trades, master of none

---

## 12. Implementation Roadmap

### Phase 1: Core Systems (Weeks 1-2)

**Deliverables:**
- Range Band targeting system
- Basic AP economy (3 AP, basic costs)
- Momentum building and basic Breaker abilities
- Blood & Soil token tracking (1-3 tokens, basic bonuses)

**Success Criteria:**
- Units can target based on range bands
- Momentum builds and is consumed correctly
- Soil accumulates when stationary, clears on movement
- AP system limits actions per turn

**Testing Focus:**
- Validate range band clarity (can players eyeball it?)
- Ensure Momentum building feels rewarding
- Check if Soil bonuses create meaningful "stay or move" decisions

---

### Phase 2: Advanced Mechanics (Weeks 3-4)

**Deliverables:**
- Amplifier and Exploiter Momentum abilities
- Blood Sanctification (4 Soil tokens)
- Hostile Soil mechanic
- AP Banking system
- Equipment charge system framework

**Success Criteria:**
- All three Momentum types functional
- Blood Sanctification triggers correctly
- AP Banking provides turn order advantage
- Equipment abilities use charge tracking

**Testing Focus:**
- Momentum type diversity creates interesting decisions
- Blood Sanctification frequency feels right (not too common/rare)
- AP Banking trade-off is meaningful
- Equipment charges feel appropriately scarce

---

### Phase 3: Equipment & Integration (Weeks 5-6)

**Deliverables:**
- Full Glyphion equipment library (15-20 items)
- Equipment-Momentum special interactions
- Conditional Reload mechanics
- Character-specific equipment synergies
- Shaper/Sourcerer Soil modifiers

**Success Criteria:**
- Equipment provides distinct tactical options
- Special Momentum interactions create "wow" moments
- Conditional Reload rewards appropriate play patterns
- Character archetypes supported by equipment choices

**Testing Focus:**
- Equipment diversity (are some items always/never picked?)
- Conditional Reload frequency (too easy/too hard?)
- Character identity reinforcement through equipment

---

### Phase 4: Balance & Polish (Weeks 7-8)

**Deliverables:**
- Tuned damage values across all abilities
- Balanced Soil bonuses and Momentum scaling
- Equipment rarity and power tiers
- Enemy AI behavior for all systems
- Tabletop play aids and reference cards

**Success Criteria:**
- Combat duration hits 8-12 turn target
- All character archetypes feel viable
- Equipment usage >80%, hoarding minimized
- Tabletop playtesters can run combat without digital assistance

**Testing Focus:**
- Full combat balance passes
- Edge case identification and handling
- Tabletop usability and clarity
- Player satisfaction metrics (fun factor)

---

### Phase 5: Advanced Features (Weeks 9+)

**Deliverables:**
- Terrain effects integration with Soil
- Advanced status effect interactions
- Legendary equipment with unique mechanics
- Environmental hazards and special tiles
- Boss-specific Momentum/Soil mechanics

**Success Criteria:**
- Advanced systems deepen strategy without complexity creep
- Boss fights feel distinct from standard encounters
- Legendary equipment creates build-around strategies

---

## Appendix A: Design Decisions Log

### Why Distance-Based Rows Instead of Fixed Positions?
**Date:** 2026-02-21
**Decision:** Rows determined dynamically by distance to nearest enemy, not by fixed grid positions
**Rationale:**
- Fixed position rows (columns 0-2 = Front) break on scalable grids (what is "front" on a 15×10 grid?)
- Distance-based rows work on any grid size (5×5 or 50×50) with identical rules
- Grid-shape agnostic (works with squares, hexes, irregular battlefields)
- Creates dynamic tactical situations (your row shifts as enemies move)
- Integrates perfectly with Blood & Soil (stay rooted, enemies approach, gain Soil while shifting to Front Row)
- Simpler for tabletop ("count to nearest enemy" vs. memorizing zone boundaries)

### Why Remove Opportunity Attacks?
**Date:** 2026-02-21
**Decision:** Removed opportunity attack system
**Rationale:** Incentivized turtling and defensive play, directly counter to design goal of aggressive positioning. Blood & Soil provides defensive positioning rewards without punishing movement.

### Why Shared Momentum Instead of Per-Character?
**Date:** 2026-02-21
**Decision:** Momentum is a property of enemies, shared across party
**Rationale:** Encourages team coordination and communication. Per-character Momentum would incentivize selfish play and reduce team synergy.

### Why Cap Soil at 3 (4 with Sanctification)?
**Date:** 2026-02-21
**Decision:** Soil tokens max at 3 normally, 4 via Blood Sanctification only
**Rationale:** Prevents infinite scaling on long combats. Blood Sanctification as only route to 4 tokens makes it a meaningful achievement. Keeps bonuses impactful but not overwhelming.

### Why AP Banking Instead of AP Carry-Over?
**Date:** 2026-02-21
**Decision:** Unused AP grants initiative bonus, not stored for next turn
**Rationale:** Full AP carry-over creates AP hoarding strategies and imbalanced turns. Initiative bonus maintains turn-by-turn decision-making while rewarding conservation.

### Why Low AP Cost for Equipment Abilities?
**Date:** 2026-02-21
**Decision:** Equipment abilities cost 1-2 AP vs. 2-3 AP for skills
**Rationale:** Charge scarcity already limits equipment usage. Lower AP cost encourages spending charges rather than hoarding. Creates AP efficiency trade-off: "Use charge now for AP advantage, or save charge and spend more AP on skills?"

---

## Appendix B: Terminology Glossary

**Action Point (AP):** Resource spent per turn to perform actions. Base 3, modified by Constitution and buffs.

**Amplifier:** Momentum ability type that builds Momentum while dealing bonus damage based on current Momentum (doesn't consume).

**Blood Sanctification:** Defeating an enemy while at 3 Soil Tokens grants permanent +1 Soil bonus to that tile for that unit.

**Breaker:** Momentum ability type that consumes all Momentum for massive damage and potential Stagger.

**Dynamic Row:** A unit's tactical position (Front/Mid/Back) determined by their current distance to the nearest enemy, not by fixed grid positions. Changes in real-time as units move.

**Charge:** Limited-use resource for Glyphion equipment abilities. Does not regenerate during combat.

**Conditional Reload:** Specific equipment that can regain charges mid-combat under certain conditions.

**Exploiter:** Momentum ability type that consumes Momentum to apply status effects.

**Glyphion Equipment:** Artifacts created by Glyphein (hybrid Sourcerer/Shaper) that provide powerful charge-based abilities.

**Hostile Soil:** Tile previously rooted by an enemy; standing on it grants defensive bonuses against that enemy.

**Momentum:** Shared party resource that builds on enemies from hits, consumed by special abilities.

**Range Band:** Simplified distance category (Melee/Close/Distant) instead of exact tile counting.

**Rooted:** Unit that stayed on the same tile between turns, eligible for Soil Token gain.

**Soil Token:** Stackable buff gained by staying stationary (0-4), provides damage/resistance/MP bonuses.

**Stagger:** Status effect causing target to lose their next turn. Applied by Breaker abilities with 3+ Momentum.

---

## Appendix C: Quick Reference Tables

### Dynamic Row Quick Reference

| Row | Distance to Nearest Enemy | Melee Bonus | Ranged Bonus | Risk Level |
|-----|---------------------------|-------------|--------------|------------|
| **Front** | 1 space (Adjacent) | +1 range band | — | High |
| **Mid** | 2-3 spaces | — | — | Medium |
| **Back** | 4+ spaces | — | +1 range band | Low |

**Note:** Your row updates dynamically as you or enemies move. Check distance each turn.

### Soil Bonus Quick Reference

| Tokens | Damage | Resistance | MP Regen | How to Get |
|--------|--------|------------|----------|------------|
| 0 | — | — | — | Just moved |
| 1 | +5% | — | — | 1 turn rooted |
| 2 | +5% | +10% | — | 2 turns rooted |
| 3 | +10% | +10% | +1 | 3 turns rooted |
| 4 | +15% | +15% | +2 | Blood Sanctification only |

### Momentum Scaling Quick Reference

| Momentum | Amplifier Bonus | Breaker Bonus | Exploiter Options |
|----------|----------------|---------------|-------------------|
| 1 | +10% damage | +20% damage | — |
| 2 | +20% damage | +40% damage | Basic status (Slow, Bleed) |
| 3 | +30% damage | +60% damage + Stagger | Basic status |
| 4 | +40% damage | +80% damage + Stagger | Severe status (Stun, Disarm) |
| 5 | +50% damage | +100% damage + Stagger | Rare status (Marked, Cursed) |

### Action Cost Quick Reference

| Action | AP | MP | Charges | Notes |
|--------|----|----|---------|-------|
| Basic Attack | 1 | 0 | — | Always available |
| Move | 1 | 0 | — | Breaks Soil |
| Skill (Std) | 2 | 2-3 | — | Most abilities |
| Skill (Power) | 3 | 4-6 | — | High impact |
| Equipment | 1-2 | 0 | 1 | Charge limited |
| Defend | 0 | 0 | — | Ends turn, +50% resist |
| Item | 1 | 0 | 1 | Consumable |
| Swap Position | 1 | 0 | — | With adjacent ally |

---

**Document Version:** 2.1
**Last Updated:** 2026-02-21 (Distance-Based Rows + Grid Scalability)
**Major Changes:**
- Added Dynamic Row System (distance-based, not position-based)
- Added Grid Shape & Scalability section (squares vs. hexes)
- Updated all examples to use distance-based positioning
- Clarified grid-agnostic design principles

**Next Review:** After Phase 1 Implementation
**Status:** Active Design - Implementation in Progress
