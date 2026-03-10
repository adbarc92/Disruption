# Disruption - Core Design Document
**Version:** 1.0
**Date:** 2026-02-21
**Status:** Living Document

---

## Table of Contents

1. [Executive Summary](#executive-summary)
2. [Design Pillars](#design-pillars)
3. [Technical Architecture](#technical-architecture)
4. [Combat Systems](#combat-systems)
5. [Character Progression](#character-progression)
6. [Resource Management](#resource-management)
7. [Role System](#role-system)
8. [Exploration & Encounters](#exploration--encounters)
9. [Vertical Slice Scope](#vertical-slice-scope)
10. [Development Status](#development-status)
11. [Balance Framework](#balance-framework)

---

## Executive Summary

### What is Disruption?

Disruption is a **turn-based tactical RPG** that combines position-based combat (Darkest Dungeon), speed-based turn order (Final Fantasy X), exploration encounters (Chrono Trigger), and weakness/resistance mechanics (Persona). The game is designed to function both as a **digital game** (Godot 4) and a **tabletop experience** (all mechanics playable without digital assistance).

### Core Experience

Players control a party of 3-8 characters across:
- **Combat**: Grid-based tactical battles with CTB turn order and AP economy
- **Exploration**: 2.5D top-down movement with visible enemies on map
- **Progression**: 3D node-based character advancement (FFX Sphere Grid inspired)
- **Narrative**: Branching dialog with consequence tracking

### Platform Targets

**Primary:** Steam (Windows/Mac/Linux) + iPad
**Future:** Console ports (architecture accommodates)
**Art Style:** HD 2D sprites, 2.5D top-down (Chrono Trigger/Sea of Stars)

---

## Design Pillars

### 1. Playtesting is King
**Philosophy:** Design documents are hypotheses; playtesting reveals truth.

- Iterate rapidly, test frequently
- Let player experience guide all decisions
- When design conflicts with enjoyment, enjoyment wins
- Balance through play, not spreadsheets

### 2. Positioning as Primary Strategy
Combat revolves around manipulating unit positions:
- Dynamic row system (distance-based: Front/Mid/Back)
- Range bands (Melee/Close/Distant) for simplified targeting
- Territorial control via Blood & Soil mechanic
- Positioning abilities (Shove, Grapple, Knockback)

### 3. Modular Architecture
All systems designed for easy swapping and iteration:
- Data-driven design (JSON configs, hot-reloadable)
- Pure logic classes (engine-independent)
- Clear separation: Presentation → Game Logic → Data
- Tabletop-compatible rules (playable without digital assistance)

### 4. Resource Depth
Multiple resource systems create layered tactical decisions:
- **MP** (2-3 per turn regeneration, spent on abilities)
- **AP** (3 base per turn, spent on actions)
- **Equipment Charges** (limited uses, powerful abilities)
- **Burst Gauge** (100 points max, enables transformation)
- **Momentum** (coordinated strikes bonus)
- **Blood & Soil** (territorial control)

### 5. Complexity Scalability
Systems can be individually toggled:
- Full tactical mode: All systems ON
- Simplified mode: Position restrictions OFF, fewer resources
- Tabletop mode: Streamlined rules, visual aids
- Players choose complexity level

### 6. Tabletop Compatibility
All mechanics function without digital assistance:
- Simple distance calculations (range bands, not exact tiles)
- Clear turn order (visible CTB queue)
- Token-based resource tracking
- No hidden calculations

---

## Technical Architecture

### Layer Separation

```
┌─────────────────────────────────────────────────────────┐
│                    PRESENTATION LAYER                    │
│  (Godot scenes, UI, sprites, audio - engine-specific)   │
├─────────────────────────────────────────────────────────┤
│                    GAME LOGIC LAYER                      │
│  (Combat rules, dialog flow, progression - portable)    │
├─────────────────────────────────────────────────────────┤
│                      DATA LAYER                          │
│  (Characters, skills, enemies, story - JSON/resources)  │
└─────────────────────────────────────────────────────────┘
```

### Data-Driven Design

**All game data in JSON:**
- `data/characters/` - Character definitions, base stats
- `data/skills/` - Ability data, effects, costs
- `data/enemies/` - Enemy templates, AI behaviors
- `data/combat/` - Battle configurations, balance values
- `data/dialog/` - Dialog trees, branching choices
- `data/progression/` - Grid nodes, XP costs

**Hot-Reload Support:**
- Press F5 in combat to reload skills.json
- Balance changes apply instantly
- No restart required for most data changes

### Codebase Organization

```
scripts/
├── autoload/            # Global managers (engine-coupled)
│   ├── GameManager      # Scene transitions, game state
│   ├── EventBus         # Cross-system communication
│   └── SaveManager      # Persistence
├── data/                # Data loading, models (portable)
│   ├── DataLoader       # JSON parsing
│   └── CombatUnit       # Unit data structures
├── logic/               # Pure game logic (portable)
│   ├── combat/          # Combat calculations
│   │   ├── CTBTurnManager
│   │   ├── APSystem
│   │   ├── DamageCalculator
│   │   ├── StatusEffectManager
│   │   ├── PositionValidator
│   │   └── CombatAI
│   ├── progression/     # XP, grid, mastery
│   └── dialog/          # Dialog state machine
└── presentation/        # Godot-specific display logic
    ├── exploration/     # Player controller, camera
    ├── combat/          # Battle UI, animations
    │   ├── CombatManager
    │   ├── UnitVisual
    │   ├── SkillPanel
    │   └── TargetSelector
    └── ui/              # Menus, HUD
```

---

## Combat Systems

### Battlefield Configuration

**Grid Structure:**
- Scalable grid size (current: 7 columns × 5 rows)
- Works on any grid size or shape (squares, hexes, irregular)
- Special tiles: traps, obstructions, environmental hazards

**Dynamic Row System (Distance-Based):**

| Row | Condition | Bonuses/Penalties |
|-----|-----------|-------------------|
| **Front Row** | Adjacent to ≥1 enemy | Melee +1 range; easier to target |
| **Mid Row** | 2-3 spaces to nearest enemy | Balanced (no modifiers) |
| **Back Row** | 4+ spaces to all enemies | Ranged +1 range; limited melee targets |

**Row changes dynamically** as units move or are defeated.

### Range Bands (Simplified Targeting)

| Range Band | Distance | Usage |
|------------|----------|-------|
| **Melee** | Adjacent (1 space) | Most physical attacks |
| **Close** | Nearby (2-3 spaces) | Thrown weapons, short-range magic |
| **Distant** | Far (4+ spaces) | Arrows, long-range spells |

**No exact tile counting required** - players assess range visually.

### Turn Order (CTB System)

**Conditional Turn-Based** inspired by Final Fantasy X:

```
Ticks Until Next Turn = BASE_TICKS - (Speed × SPEED_MULTIPLIER) - (Remaining AP × AP_TO_TICKS_RATIO)

Where:
  BASE_TICKS = 100
  SPEED_MULTIPLIER = 5
  AP_TO_TICKS_RATIO = 5
```

**Key Features:**
- Speed determines turn frequency (not just first-turn initiative)
- Visible turn preview (next 10 turns)
- Remaining AP speeds up next turn (save vs spend decision)
- Tie-breaker: Higher Speed wins, then random

### Action Point Economy

**Base AP per turn:** 3
**AP cap:** Constitution stat (player characters only)
**AP conservation:** Unused AP carries to next turn (players only)

**Action Costs:**
| Action | AP Cost | Notes |
|--------|---------|-------|
| Basic Attack | 1 | Free damage |
| Movement | 1 | One grid position |
| Light Skill | 1 | Quick abilities |
| Standard Skill | 2 | Most abilities |
| Heavy Skill | 3 | Powerful abilities |
| Defend | 0 | Ends turn, grants defensive bonus |
| End Turn | 0 | Explicit end with remaining AP |

**Remaining AP Benefits:**
1. Speed boost on next turn (fewer ticks to wait)
2. Conserved for next turn (up to Constitution cap, players only)

### Damage & Resistance System

**Damage Types:**
- **Physical:** Slash, Pierce, Blunt
- **Elemental:** Fire, Ice, Lightning, Earth, Wind, Water
- **Magical:** Arcane, Divine, Occult
- **Special:** Psychic, Necrotic, Radiant

**Resistance Levels:**
- **Immune:** 0% damage taken
- **Resistant:** 50% damage taken
- **Normal:** 100% damage taken
- **Vulnerable:** 150% damage taken

**Health Layers** (damage absorption order):
1. **Shields** - Temporary, own resistances
2. **Armor** - Damage reduction layer
3. **Health** - Core HP
4. **Overhealth** - Temporary bonus from abilities

### Status Effects

**Categories:**
- **Health:** Regenerating, Poisoned, Burning, Bleeding
- **Beneficial:** Strengthened, Energized, Invisible, Immune
- **Detrimental:** Weakened, Disrupted, Hamstrung
- **Control:** Paralyzed, Stunned, Restrained, Frozen, Charmed, Frightened
- **Unique:** Apotheosis, Unraveling, Quickened, Flow

**Processing:**
- Turn-start effects (regeneration, poison ticks)
- Turn-end effects (duration countdown, expiration)
- Condition-based (trigger on hit, on move, etc.)

### Combat AI

**Behavior Types:**
- **Aggressive:** Target lowest HP, use highest damage skill
- **Defensive:** Use protection skills, fallback to attack
- **Support:** Apply debuffs, fallback to aggressive
- **Custom:** Per-enemy scripted behaviors

**Decision Making:**
1. Check for taunt (forced targeting)
2. Evaluate usable skills (MP cost, valid targets)
3. Select optimal action based on behavior type
4. Execute with target selection

---

## Character Progression

### 3D Progression Grid (FFX Sphere Grid Inspired)

**Dimensional Structure:**
- **X-Axis:** Horizontal specialization (Combat → Magic → Support)
- **Y-Axis:** Vertical advancement (Basic → Advanced → Master)
- **Z-Axis:** Depth specialization (Offensive → Defensive → Utility)

**Node Coordinate System:**
```
Node Position: (X, Y, Z)
Examples:
- (0, 0, 0): Universal starting node
- (2, 1, -1): Combat-focused, intermediate, defensive
- (-2, 3, 1): Magic-focused, advanced, offensive
```

### Node Types

**STAT_BOOST:**
- +2 primary stats (Vigor, Strength, Dexterity, Agility, Resonance)
- +5% derived stats (Health, MP, Crit Rate, etc.)
- +1 to two different stats (hybrid)

**ABILITY_UNLOCK:**
- Grant access to role-specific combat abilities
- Universal abilities (available to all)
- Cross-role abilities (rare, high-cost)

**ABILITY_SLOT:**
- Increase equippable abilities (4 base, 8 max)
- Specialized slots (offensive/defensive/utility)

**PASSIVE_BONUS:**
- Combat passives (always active in battle)
- Exploration passives (field navigation)
- Resource passives (MP regen, XP gain, etc.)

**ROLE_FEATURE:**
- Role enhancement (strengthen existing abilities)
- Hybrid unlocks (enable role combinations)
- Mastery bonuses (capstone abilities)

### Progression Costs

**Base XP Costs:**
- STAT_BOOST: 100 XP
- ABILITY_UNLOCK: 150-300 XP (power-based)
- ABILITY_SLOT: 200-350 XP (increases per slot)
- PASSIVE_BONUS: 175-250 XP (benefit-based)
- ROLE_FEATURE: 300-500 XP (capstones most expensive)

**Cost Modifiers:**
- Role alignment: -25% for primary role path
- Distance penalty: +10% per node from nearest activated
- Equipment bonuses: Specific items reduce costs
- Hybrid role tax: +50% outside both component roles

### Dual Experience Systems

**1. Character XP** (Grid Progression):
- Earned from: Combat victories, quest completion, exploration
- Used for: Activating grid nodes
- Amount: 50-500 XP per source

**2. Ability Mastery XP** (Skill Enhancement):
- Earned from: Using specific abilities in combat
- Used for: Unlocking ability permutations (0-5 levels)
- Grants: Extra effects, extended range, AOE expansion, etc.

---

## Resource Management

### MP (Mana Points)

**Core Resource for Abilities:**
- Base regeneration: 2-3 per turn
- Spent on: Role abilities, spells
- Maximum MP: Resonance × 5 (base formula)

**Current Balance (Prototyping):**
- Light skills: 1 MP
- Standard skills: 2 MP
- Heavy skills: 3 MP
- Basic attack: 0 MP (free)

### Equipment Charges (Glyphion Artifacts)

**Limited-Use Powerful Abilities:**
- Charges per combat: 1-3 (typically)
- Significantly more powerful than standard abilities
- Examples:
  - Earth Gauntlets: Earthquake (AOE damage)
  - Shadow Cloak: Teleport (repositioning)
  - Gravity Core: Singularity (pull + damage)

**Strategic Use:**
- Save for critical moments
- Powerful but scarce
- Combat-specific (recharge between battles)

### Burst Gauge (Transformation System)

**100-Point Maximum:**
- Fills via: Customizable charging methods
- Enables: Transformation mode (4-6 turns)
- Carries over: 25-40% between combats

**Charging Methods (Examples):**
- **Berserker:** +15 per enemy defeated, +5 per crit
- **Guardian:** +12 per damage absorbed for allies
- **Tactician:** +8 per ally repositioned, +12 per enemy
- **Opportunist:** +10 per weakness exploited

**Transformation Benefits:**
- Stat boosts: +40-80% damage, +30-100% damage reduction
- Transform basic abilities
- Grant exclusive ultimate abilities
- Shift turn order (+2-3 positions)

### Momentum System (Coordinated Strikes)

**Team Coordination Bonus:**
- Rewards focused, cooperative strikes
- Build momentum through sequential attacks
- Higher momentum = damage multipliers

**Implementation:** To be designed (placeholder)

### Blood & Soil (Territorial Control)

**Positional Resource:**
- Soil Tokens: Gained by staying on same tile
- Blood Tokens: Gained from kills on tiles
- Strategic tension: Mobility vs rooting

**Tactical Implications:**
- Rooted tank: High Soil + Front Row = melee powerhouse
- Mobile archer: Sacrifice Soil for Back Row safety
- Defensive stand: Build Soil in Back Row, shift when engaged

---

## Role System

### Role Philosophy

**Roles as "Ability Tags"** (not strict classes):
- Characters can mix multiple roles
- Hybrid roles unlock combination abilities
- Mastery bonuses at progression thresholds

### Primary Roles (10 Base)

**Damage Dealers:**
1. **Bladewarden** - Melee DPS (+15% attack below 50% HP)
2. **Farshot** - Ranged DPS (+20% accuracy/crit at 4+ tiles)
3. **Ignivox** - Magical AOE (10-damage burn over 2 turns)
4. **Shadowfang** - Assassin (stealth after crits)

**Support:**
5. **Mendicant** - Healer (+20% healing for allies below 30% HP)
6. **Harmonist** - Magic support (+15% magic damage, +10% MP regen in 2 tiles)
7. **Chronovant** - Tempo manipulator (20% extra action chance)
8. **Ravencut** - Utility (50% MP steal, +1 movement, immune to restrictions)

**Defense/Control:**
9. **Bulwark** - Tank (20% frontal DR, immovable)
10. **Zonemaster** - Controller (+10% damage to enemies in zones)

### Role Mastery Thresholds

- **Apprentice:** 10 nodes activated
- **Journeyman:** 25 nodes
- **Expert:** 45 nodes
- **Grandmaster:** 70+ nodes

**Mastery Bonuses:**
- Passive stat increases
- Unlock advanced abilities
- Cost reductions on role-aligned nodes
- Access to role-specific equipment

### Hybrid Roles

**Parent Role Combination:**
- Each hybrid inherits from two base roles
- Access to nodes from both parent paths
- Unique hybrid-only nodes at intersections
- Balanced restrictions (cannot access nodes forbidden to either parent)

**Examples:**
- **Spiritcaller:** Ignivox + Mendicant
- **Voidwalker:** Shadowfang + Chronovant
- **Breaker:** Bladewarden + Bulwark
- **Huntsman:** Farshot + Shadowfang

**Advanced System (End-Game):**
- **Role Fusion:** Requires Grandmaster in both roles + story milestones + rare catalysts
- Creates unique hybrid identities with exclusive abilities

---

## Exploration & Encounters

### Movement System

**2.5D Top-Down (Chrono Trigger Style):**
- 8-directional free movement
- Hopping over obstacles (always available, short arc)
- Grappling to grapple points
- Sprinting (speed boost)
- Rolling/dodging (invincibility frames)

**Input Support:**
- Keyboard/Mouse: WASD + mouse aiming
- Controller: Left stick + face buttons
- Touch (iPad): Virtual joystick + gesture-based actions

### Encounter Design

**Visible Enemies on Map:**
- Chrono Trigger-style encounters
- Players see enemies before engaging
- Positioning on map determines battle start positions
- Can avoid or initiate on player terms

**Encounter Triggers:**
- Direct contact: Touch enemy sprite
- Ambush: Enemy initiates from stealth
- Scripted: Story-driven battles
- Optional: Skippable enemies for backtracking

---

## Vertical Slice Scope

### Purpose
Demonstrate all core systems in a **30-60 minute playable experience**.

### Components

**1. Opening Cutscene**
- Narrative introduction
- Character introductions
- World setup

**2. Branching Dialog**
- Character interactions
- Player choices with consequences
- Flags for downstream story impact

**3. Exploration Scene**
- 2.5D top-down movement
- All movement mechanics (jump, roll, sprint, grapple)
- Visible enemy on map
- Interactive objects

**4. Combat Encounter (3v3)**
- Full tactical battle
- 3 party members: Cyrus, Vaughn, Phaidros
- Demonstrates positioning, abilities, turn order
- Win/loss outcomes

### Vertical Slice Characters

**Cyrus - The Seeker (Striker):**
- Stats: STR 7, DEX 6, VIG 6, AGI 6
- Abilities:
  - True Strike: 40 damage, can't dodge, lunges to target
  - Heavy Swing: 45 damage, blunt
  - Cleave: 30 damage AOE to all adjacent

**Vaughn - The Hawk (Debuffer/Support):**
- Stats: DEX 8, STR 6, AGI 7, VIG 5
- Abilities:
  - Hamstring: 25 damage + reduce Agility 50% for 3 turns
  - Poison Strike: 20 damage + 8/turn for 3 turns (44 total)
  - Leadership: +15% STR/DEX to all allies for 3 turns

**Phaidros - Second Gnosis (Tank/Controller):**
- Stats: VIG 9, STR 7, DEX 4, AGI 4
- Abilities:
  - Shield Bash: 20 damage + stun 1 turn
  - Ironflesh: Grant ally 30% physical DR for 3 turns
  - Grapple: 10 damage + pull enemy 2 spaces

---

## Development Status

### Current Phase: Phase 1 - Combat Prototyping

**Implemented (Godot 4):**
- ✅ Combat grid visualization (7×5, scalable)
- ✅ CTB turn order system with preview
- ✅ AP economy (3 base AP, conservation for players)
- ✅ Basic attack and skill execution
- ✅ Unit visuals with health bars
- ✅ Hot-reload for skills.json (F5 in combat)
- ✅ Combat configurator (test encounters)
- ✅ Action log (copyable with Ctrl+C)
- ✅ Range band validation (Melee/Close/Distant)
- ✅ Dynamic row calculation (Front/Mid/Back)

**In Progress:**
- ⏳ 22 prototyped skills (organized by category)
- ⏳ 8 enemy archetypes (Glass Cannon, Tank, Debuffer, etc.)
- ⏳ Time-to-kill balancing (target: 3-5 rounds)
- ⏳ Enemy AI diversity testing

**Not Started:**
- ⬜ Status effects (DOTs, buffs, debuffs)
- ⬜ Positioning abilities (Shove, Grapple, Knockback)
- ⬜ Burst Mode system
- ⬜ Equipment Charge system
- ⬜ Momentum system
- ⬜ Blood & Soil system
- ⬜ Character progression grid
- ⬜ Exploration movement
- ⬜ Dialog system
- ⬜ Cutscene system

### Development Roadmap

**Phase 1: Combat Foundation** (Weeks 1-6)
- Validate core combat loop is fun
- Balance damage/TTK
- Test positioning mechanics
- **Decision Point:** Is combat fun with zero customization?

**Phase 2: Limited Customization** (Weeks 8-12)
- Add 1-2 ability choices per character
- Test if build choices matter
- **Decision Point:** Expand customization or keep fixed classes?

**Phase 3A: Expand** (if Phase 2 succeeds)
- Implement hybrid tag system
- 9 builds per character (27 total to balance)

**Phase 3B: Pivot** (if complexity too high)
- Rule-based emergent interactions
- Divinity-style elemental combos

**Phase 3C: Simplify** (if customization doesn't add value)
- Polish fixed classes
- Deep mastery instead of build variety

### Testing Philosophy

**Rapid Iteration Workflow:**
1. Fight an encounter
2. Note pain points ("Scout dies too fast")
3. Make ONE change (increase Scout HP by 20)
4. Press F5 (skills) or restart combat (enemies)
5. Test again
6. Repeat

**Goal:** Find the fun through play, not theory.

---

## Balance Framework

### Current Damage Baseline (Prototyping)

**Target TTK:** 3-5 rounds to kill standard enemy with focused fire

**Ability Damage:**
| Ability Type | Base Damage | MP Cost | Notes |
|--------------|-------------|---------|-------|
| Basic Attack | 20 | 0 | Free, unlimited |
| Light Skill | 25-30 | 1-2 | Quick abilities |
| Standard Skill | 30-35 | 2 | Most abilities |
| Heavy Skill | 40-45 | 3 | Powerful abilities |
| DOT (per turn) | 6-10 | - | 18-30 total over 3 turns |
| AOE | 30 | 2-3 | Multi-target |

**Enemy HP Ranges:**
| Enemy Type | HP | Rounds to Kill | Notes |
|------------|----|----- |----------|-------|
| Swarm (Imp) | 35 | ~2 | Weak individually, dangerous in groups |
| Glass Cannon (Scout, Caster) | 50-60 | ~3 | High damage, priority target |
| Standard (Hexer, Brawler) | 70-90 | ~4 | Balanced threat |
| Tank (Brute, Leech) | 100-140 | ~5-7 | High HP, slow |
| Boss (Champion) | 200 | ~10 | Elite with diverse abilities |

### Enemy Archetypes

**1. Glass Cannon** (Scout, Caster)
- **Threat:** High damage output
- **Weakness:** Dies fast
- **Priority:** KILL FIRST
- **Abilities:** Frenzy (2x hits), Lightning Bolt, Ignite

**2. Tank** (Brute, Leech)
- **Threat:** Soaks damage, slows combat
- **Weakness:** Slow, predictable
- **Priority:** Last
- **Abilities:** Heavy Swing, Shield Bash, Heal Self

**3. Debuffer** (Hexer)
- **Threat:** Weakens party over time
- **Weakness:** Moderate HP
- **Priority:** Second
- **Abilities:** Weaken, Corrupting Aura, Venom Spit

**4. Disruptor** (Brawler)
- **Threat:** Messes up positioning
- **Weakness:** Linear tactics
- **Priority:** Second/Third
- **Abilities:** Shove, Grapple Pull, Heavy Swing

**5. Regenerator** (Leech)
- **Threat:** Heals itself, extends combat
- **Weakness:** Moderate damage
- **Priority:** First or Second
- **Abilities:** Venom Spit, Heal Self (30 HP)

**6. Swarm** (Imp)
- **Threat:** Chip damage, action economy
- **Weakness:** One-shots from abilities
- **Priority:** AOE them
- **Abilities:** Basic Attack, Dark Bolt

**7. Boss** (Champion)
- **Threat:** Everything
- **Weakness:** None (balanced)
- **Priority:** Focus fire with debuffs
- **Abilities:** Heavy Swing, Cleave, Shield Bash, Frenzy

### Balance Testing Questions

**Time to Kill:**
- Does combat feel too fast? Too slow?
- Are tanks annoying or strategic?
- Do glass cannons die satisfyingly fast?

**Skill Balance:**
- Is Basic Attack ever worth using over abilities?
- Are 2 MP abilities worth the cost?
- Do DOTs feel impactful or ignorable?

**Enemy Asymmetry:**
- Can players tell enemies apart by behavior?
- Do different archetypes demand different tactics?
- Are any enemies "boring" (just HP sponges)?

**Positioning:**
- Do Grapple/Shove create interesting moments?
- Is repositioning worth the AP cost?
- Does the grid size feel right?

**Player Agency:**
- Do players have meaningful choices each turn?
- Are there "correct" and "trap" builds?
- Is MP scarcity creating tough decisions?

---

## Appendices

### A. Playable Characters (Full Roster)

| Character | Title | Specialization |
|-----------|-------|----------------|
| Cyrus | The Seeker | Entropic Blade, elemental weapon enhancement |
| Vaughn | The Hawk | Tactical Rogue, debuffs and team leadership |
| Phaidros | Second Gnosis | Earth Guardian, tank and protective abilities |
| Paidi | The Mystic | Harmonic Monk, healing and stance system |
| Lione | The Changeling | Adaptive Mimic, ability theft and environmental control |
| Euphen | The Wanderer | Shadow Archer, traps and positioning |
| Chiranjivi | The Outsider | Blood Manipulation, self-harm for power |
| Adam | The Supreme | (Details TBD) |

### B. Burst Mode Transformations

**Cyrus - Elemental Mastery:**
- Duration: 5 turns
- Effects: +50% damage, +40% speed, all attacks gain random elements

**Vaughn - Master Tactician:**
- Duration: 5 turns
- Effects: +45% crit rate, +50% speed, allies gain extra action

**Phaidros - Mountain King:**
- Duration: 6 turns
- Effects: +70% damage reduction, +40% damage, immune to forced movement

**Paidi - Harmonic Resonance:**
- Duration: 5 turns
- Effects: All Mien effects active, dual heal/damage

**Lione - Omnific Mirror:**
- Duration: 5 turns
- Effects: Can use any ability seen this combat

**Euphen - Shadow Lord:**
- Duration: 5 turns
- Effects: Stealth on all abilities, instant trap deployment

**Chiranjivi - Crimson Vessel:**
- Duration: 5 turns
- Effects: Immune to Bleed, convert self-harm to benefits

### C. Development Phases (8-Phase Plan)

**Phase 1:** Project Setup (Godot structure, input mapping)
**Phase 2:** Movement Core (Jump, roll, sprint, grapple)
**Phase 3:** Combat Foundation (Grid, turn order, basic attacks)
**Phase 4:** Dialog System (Branching with consequences)
**Phase 5:** Exploration Scene (Playable area, visible enemy)
**Phase 6:** Combat Polish (Skills, status effects, UI)
**Phase 7:** Cutscene System (Playback/scripting)
**Phase 8:** Integration (Full vertical slice flow)

### D. Key Design Decisions

**✅ Distance-Based Rows (Not Fixed Grid Positions):**
- Scales to any grid size
- Works on any grid shape (squares, hexes, irregular)
- Creates dynamic tactical shifts

**✅ Range Bands (Not Exact Tile Counting):**
- Tabletop-friendly (visual assessment)
- Reduces analysis paralysis
- Maintains strategic depth

**✅ AP Economy (Not Per-Action Costs):**
- Multiple actions per turn
- Save vs spend decisions
- Conserved AP carries over (players only)

**✅ CTB Turn Order (Not Initiative Roll):**
- Speed determines turn frequency
- Visible turn preview (next 10)
- Remaining AP affects next turn speed

**⚠️ Compositional Tags (Under Review):**
- Original design: Build characters from granular tags
- Reality check: Exponential complexity, 2-5 year balance cycle
- Current approach: Start with fixed classes, add limited customization if playtesting demands it

**❌ Opportunity Attacks (Removed):**
- Punished movement, encouraged turtling
- Contradicted positioning-focused design
- Movement is now risk-free (aside from ending in poor position)

### E. Technology Stack

**Engine:** Godot 4.6+ (GDScript)
**Data Models (Legacy):** TypeScript (code/src/model/)
**Data Format:** JSON (hot-reloadable)
**Version Control:** Git + GitHub
**Platforms:** Windows, macOS, Linux, iOS (iPad)

**File Organization:**
```
Disruption/
├── godot/              # Godot 4 project
│   ├── scenes/         # Game scenes (.tscn)
│   ├── scripts/        # GDScript (.gd)
│   └── data/           # JSON configs
├── docs/               # Design documentation
│   ├── 00_Development/ # Dev guides, labs
│   ├── 01_Game_Design_Document/
│   ├── 02_Story_Narrative/
│   ├── 03_World_Building/
│   ├── 04_Characters/
│   └── 06_Progression_Systems/
└── code/               # Legacy TypeScript models
    └── src/model/
```

---

## Document Control

**Last Updated:** 2026-02-21
**Version:** 1.0
**Status:** Living Document (update as systems evolve)

**Next Review:** After Phase 1 Complete (~Week 6)

**Change Log:**
- 2026-02-21: Initial comprehensive systems overview created

**Contributors:**
- Design Team
- Claude Sonnet 4.5 (Co-Authored)

---

*This document consolidates information from: CLAUDE.md, CDD_Combat_v2.md, CDD_CharacterProgression_v2.md, CDD_Roles_v1.md, Battle_Tuning_Lab.md, Skill_Prototyping_Guide.md, Class_Design_Lab.md, and Combat_Iteration_Roadmap.md*
