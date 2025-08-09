# Turn-Based Combat System Design Document

## Executive Summary

This document outlines a turn-based tactical combat system emphasizing positioning, resource management, and modular design for rapid iteration. The system combines elements from Darkest Dungeon's positional combat, Final Fantasy X's CTB turn order, and Persona's weakness/resistance mechanics into a cohesive tactical experience.

**Core Pillars:**
- **Positioning as Primary Strategy:** Combat revolves around manipulating unit positions to create advantageous configurations
- **Modular Architecture:** All major systems designed for easy swapping and iteration
- **Resource Depth:** Dual resource management (MP + Equipment charges) with meaningful decision points
- **Complexity Scalability:** Systems designed to be individually toggleable for complexity management

---

## Burst Mode System (Trance/Overdrive Hybrid)

### Core Design Philosophy
The Burst system combines the best elements of FF7's Limit Breaks (powerful gauge-based abilities), FF9's Trance (transformative state changes), and FFX's Overdrives (player-controlled activation and customization) into a unified tactical resource.

### Burst Gauge Mechanics
**Gauge Properties:**
- **Capacity:** 100 points (standardized across all characters)
- **Persistence:** Gauge partially carries between combats (retains 25-40%)
- **Visibility:** Always visible to players for strategic planning
- **Decay:** No passive decay during combat

### Customizable Charging Methods
Each character can equip one primary charging method (selected outside combat):

**Aggressive Charging Methods:**
- **Berserker:** +15 points per enemy defeated, +5 per critical hit
- **Executioner:** +20 points when reducing enemy to 25% health or below
- **Chain Fighter:** +10 points per consecutive turn spent attacking

**Defensive Charging Methods:**
- **Guardian:** +12 points per damage absorbed for allies, +8 when taking damage while in front row
- **Survivor:** +15 points when dropping below 50% health, +10 per turn survived at low health
- **Protector:** +10 points per status effect cleansed from allies

**Support Charging Methods:**
- **Tactician:** +8 points per ally repositioned, +12 per enemy repositioned
- **Medic:** +10 points per healing action, +15 per ally saved from incapacitation
- **Buffer:** +8 points per beneficial status applied to allies

**Technical Charging Methods:**
- **Efficiency Expert:** +12 points per ability used at optimal resource cost
- **Combo Master:** +15 points per multi-target ability, +20 per ability that triggers reactions
- **Opportunist:** +10 points per weakness exploited, +15 per resistance overcome

### Burst Mode Activation
**Activation Requirements:**
- Gauge must be at 100 points
- Cannot be incapacitated or under specific control effects
- Uses an action (or bonus action, depending on turn system variant)

**Activation Effects:**
- **Immediate:** Gauge depletes to 0, transformation begins
- **Duration:** 4-6 turns (varies by character/customization)
- **Action Economy:** Activation turn grants immediate bonus action

### Transformation Effects Framework
Each character has a unique Burst Mode with three categories of changes:

**Stat Modifications (Applied for duration):**
- **Damage Boost:** +40-60% to all damage output
- **Speed Increase:** +2-3 positions in turn order
- **Resistance Boost:** +1 level to all resistances (Vulnerable→Normal→Resistant)
- **Special Stats:** Unique modifications per character archetype

**Ability Transformations:**
- **Basic Attack Enhancement:** Becomes area attack or gains additional effects
- **Role Ability Upgrades:** Existing abilities gain additional effects or reduced costs
- **MP Cost Reduction:** All abilities cost 1 less MP (minimum 1)

**Exclusive Burst Abilities:**
- **Ultimate Attack:** High-damage ability available only in Burst Mode
- **Mass Effect:** Area-of-effect version of signature ability
- **Emergency Protocol:** Defensive ability that can interrupt enemy turns

### Example Burst Mode Profiles

**Tank Character - "Fortress Mode":**
- **Stats:** +50% damage reduction, +30% damage output, immunity to forced movement
- **Transform:** Basic attack becomes area taunt, defensive abilities affect all allies
- **Ultimate:** "Aegis Protocol" - Absorb all damage to allies for 2 turns

**DPS Character - "Rampage Mode":**
- **Stats:** +60% damage, +3 turn order positions, critical hits reduce ability cooldowns
- **Transform:** All attacks gain cleave, movement abilities deal damage
- **Ultimate:** "Devastation" - Massive area attack that repositions all enemies

**Support Character - "Harmony Mode":**
- **Stats:** +2 range to all abilities, all abilities affect additional targets
- **Transform:** Healing abilities grant temporary buffs, buffs last twice as long
- **Ultimate:** "Restoration Wave" - Full heal + status cleanse + buff to entire party

### Strategic Depth Elements

**Burst Timing Decisions:**
- **Early Activation:** Control difficult encounters but lose late-game power
- **Mid-Combat:** Turn tide of battle when momentum shifts
- **Clutch Activation:** Last-resort power spike for comeback potential

**Counter-Play Mechanics:**
- **Gauge Disruption:** Some enemy abilities can reduce Burst Gauge
- **Transformation Punishment:** Certain enemies deal extra damage to Burst Mode units
- **Duration Manipulation:** Effects that can extend or shorten Burst duration

**Team Coordination:**
- **Staggered Bursts:** Maintain constant pressure with sequential activations
- **Synchronized Bursts:** Overwhelming combo potential with multiple simultaneous activations
- **Support Bursts:** Using support character Burst to enable DPS character setups

### Balance Framework
**Power Budget Guidelines:**
- Burst Mode should feel significantly more powerful than base state
- Total combat effectiveness increase should be 150-200% during Burst
- Gauge charging should require 8-12 turns of focused play
- One Burst activation per combat is standard, two is exceptional

**Charging Rate Balance:**
- Different charging methods should reach full gauge at similar rates
- High-risk charging methods (taking damage) charge slightly faster
- Support charging methods should be consistently reliable but not explosive

### Technical Implementation Notes
**Modular Transformation System:**
```java
interface BurstTransformation {
    StatModifierSet getStatChanges();
    AbilityTransformationSet getAbilityChanges();
    List<BurstAbility> getExclusiveAbilities();
    int getDuration();
}
```

**Gauge Charging System:**
```java
interface GaugeCharger {
    int calculateChargeGain(CombatEvent event, CombatContext context);
    boolean isEventRelevant(CombatEvent event);
}
```

**State Management:**
- Clean separation between base character state and Burst modifications
- Ability to preview Burst effects before activation
- Rollback system for debugging transformation issues

---

## System Architecture Overview

### Modular Component Structure

```
Combat System
├── Battlefield Module (Grid + Positioning)
├── Turn Management Module (CTB + Action Economy)
├── Action System Module (Abilities + Items + Movement)
├── Damage System Module (Types + Calculations + Health)
├── Status Effect Module (DOT + Modifiers + Complex Effects)
├── Resource Management Module (MP + Equipment Charges + Burst Gauge)
├── Burst Mode Module (Transformation States + Gauge Management)
└── Input/UI Module (Platform-agnostic interface)
```

Each module implements standardized interfaces allowing for complete subsystem replacement during development.

---

## Battlefield System

### Grid Configuration
**Primary Configuration:** Two opposing 3x3 grids (6x3 total battlefield)
**Alternative Configurations:**
- Single 7x3 grid for different encounter types
- Hexagonal grid variant for future expansion

### Grid Properties
- **Positions:** Each grid square has coordinates and properties
- **Occupancy:** One unit per square maximum
- **Special Tiles:**
  - **Trap Tiles:** Prevent movement off the tile until condition met
  - **Obstruction Tiles:** Block occupation and line of sight
  - **Environmental Hazards:** Deal damage or apply status effects

### Positioning Rules
- **Front Column Protection:** Units in middle/back columns take reduced damage when front column is occupied
- **Line of Sight:** Certain abilities require clear sight lines
- **Movement Constraints:** Various abilities and effects can restrict movement options

### Technical Implementation Notes
- Grid system should use abstract positioning interfaces
- Support for dynamic grid resizing/reshaping
- Pathfinding system for movement validation
- Visual feedback system for valid moves/targets

---

## Turn Management System (CTB)

### Core CTB Mechanics
Based on Final Fantasy X's Conditional Turn-Based system with enhancements:

- **Speed-Based Initiative:** Unit speed determines turn frequency
- **Action Delay:** Different actions cause different delays before next turn
- **Turn Preview:** Players can see upcoming turn order (next 8-10 turns)
- **Dynamic Turn Order:** Actions can modify turn order in real-time

### Turn Structure Variants (Modular)
**Option A: Action Point System**
- Each unit receives AP per turn (default: 3-5 AP)
- Actions consume varying AP amounts
- Unused AP can be saved or converted to defensive bonuses

**Option B: Structured Action System (5e-style)**
- Movement + Action + Bonus Action per turn
- Certain abilities can be used as reactions
- Clear action economy similar to D&D 5e

### Implementation Details
- Abstract Turn interface for easy system swapping
- Turn history tracking for complex effect resolution
- Interrupt system for reactive abilities
- Save/load turn state for debugging

---

## Action System

### Core Action Categories
1. **Basic Attack:** Always available, no resource cost
2. **Role Abilities:** Class-specific abilities using MP
3. **Equipment Abilities:** Gear-specific abilities using equipment charges
4. **Movement:** Repositioning on the battlefield
5. **Item Usage:** Consumables and utility items
6. **Defensive Actions:** Guard, dodge, prepare reactions
7. **Burst Activation:** Trigger transformation mode (once per combat when gauge is full)
8. **Burst Abilities:** Enhanced actions available only during Burst Mode

### Action Properties Framework
Each action defines:
- **Resource Cost:** MP, equipment charges, or special requirements
- **Target Type:** Self, ally, enemy, area, position
- **Range/Reach:** Which positions can be targeted from current position
- **Effects:** Damage, healing, status application, repositioning
- **Action Economy:** AP cost or action type (action/bonus action/reaction)

### Positioning-Based Actions
**Self-Repositioning:**
- Move forward/backward within column
- Swap positions with ally
- Retreat to specific row

**Ally Repositioning:**
- Pull ally to safer position
- Push ally through enemy lines
- Formation adjustments

**Enemy Repositioning:**
- Knockback/pull effects
- Force position swaps
- Area displacement abilities

### Technical Architecture
- Abstract Action interface with common properties
- Effect composition system for complex abilities
- Target validation system
- Action preview system for UI

---

## Damage and Health Systems

### Damage Type Framework
**Primary Damage Types:**
- Physical (Slash, Pierce, Blunt)
- Elemental (Fire, Ice, Lightning, Earth, Wind, Water)
- Magical (Arcane, Divine, Occult)
- Special (Psychic, Necrotic, Radiant)

### Resistance System
**Resistance Levels:**
- **Immune:** 0% damage taken
- **Resistant:** 50% damage taken
- **Normal:** 100% damage taken
- **Vulnerable:** 150% damage taken

**Dynamic Resistance Modification:**
- Abilities can temporarily change resistances
- Equipment can provide resistance bonuses
- Status effects can create vulnerabilities

### Health Layer System
**Health Types (in order of damage absorption):**
1. **Shields:** Temporary health with own resistances (like BattleChasers)
2. **Armor:** Damage reduction layer with specific vulnerabilities
3. **Health:** Core hit points
4. **Overhealth:** Temporary bonus health from abilities

### Damage Calculation Formula
```
Base Damage = (Ability Power + Stat Modifiers + Equipment Bonuses)
Positional Modifier = (Front Row Protection + Environmental Factors)
Resistance Modifier = (Target Resistance Level + Temporary Modifiers)
Final Damage = Base Damage × Positional Modifier × Resistance Modifier
```

---

## Status Effect System

### Status Effect Categories

**Damage Over Time (DOT):**
- **Poison:** Damage at turn end, reduces healing effectiveness
- **Burn:** Damage at turn start, spreads to adjacent allies
- **Bleed:** Damage when moving or taking actions
- **Corrosion:** Reduces armor effectiveness over time

**Stat Modifications:**
- **Buff/Debuff:** Temporary stat increases/decreases
- **Scaling Effects:** Effects that grow stronger over time
- **Conditional Modifiers:** Bonuses that trigger under specific conditions

**Control Effects:**
- **Stun:** Cannot take actions
- **Root:** Cannot move but can act
- **Charm:** Acts under opponent control
- **Fear:** Must move away from source

**Complex Effects:**
- **Mark:** Increases damage from specific sources
- **Link:** Shares damage/effects with linked target
- **Transformation:** Temporarily changes unit type/abilities
- **Well-rested:** Increased XP gain at the end of battles
- **Flow:** Increased ability XP gain at the end of battles.

### Status Effect Properties
- **Duration:** Turns remaining, permanent, or condition-based
- **Stacking:** How multiple applications interact
- **Dispel Resistance:** Difficulty to remove
- **Priority:** Order of application/resolution

### Technical Implementation
- Abstract StatusEffect interface
- Effect composition for complex interactions
- Stack management system
- Visual feedback and UI integration

---

## Resource Management Systems

### Primary Resource: MP (Mana Points)
**Core Mechanics:**
- Regenerates each turn (base: 2-3 MP)
- Maximum capacity varies by role/level
- Spent on role-specific abilities
- Can be enhanced by equipment or status effects

**Management Considerations:**
- High-impact abilities cost more MP
- Resource scarcity creates tactical decisions
- Emergency abilities may overcost (going negative with penalties)

### Secondary Resource: Equipment Charges
**Core Mechanics:**
- Each equipped item has limited uses per combat
- Charges don't regenerate during battle
- Powerful abilities tied to specific equipment
- Strategic equipment swapping between battles

**Equipment Charge Examples:**
- **Weapon:** 3 charges for special attacks
- **Armor:** 2 charges for protective abilities
- **Accessories:** 1-2 charges for utility effects

**Source Point Inspiration (DOS2):**
- Charges are precious and game-changing
- Abilities using charges are significantly more powerful
- Creates tension between saving and spending

### Tertiary Resource: Burst Gauge (Trance/Overdrive System)
**Core Mechanics:**
- Each party member has a Burst Gauge that fills during combat
- When full, player can choose to activate Burst Mode (no automatic triggering)
- Burst Mode transforms the unit with enhanced stats and altered abilities
- Duration-based transformation (4-6 turns typical)

**Burst Mode Effects:**
- **Stat Modifications:** Significant increases to damage, speed, resistances
- **Ability Transformation:** Basic abilities become enhanced versions
- **New Abilities:** Access to unique Burst-only abilities
- **Visual Transformation:** Distinct visual state for clarity

**Gauge Charging System (Customizable):**
Players can select from multiple charging methods per character:
- **Damage Dealt:** Fills based on damage output (aggressive playstyle)
- **Damage Taken:** Fills when taking damage (defensive/tank builds)
- **Ally Support:** Fills when helping teammates (support builds)
- **Status Infliction:** Fills when applying debuffs/buffs
- **Positional Play:** Fills when using positioning abilities
- **Resource Efficiency:** Fills when using abilities at optimal times
- **Combo Actions:** Fills when chaining abilities or executing setups

**Strategic Considerations:**
- **Timing:** When to activate for maximum impact
- **Team Coordination:** Staggering Burst activations vs. overwhelming pushes
- **Counter-play:** Enemies may have abilities that reduce gauge or punish Burst mode
- **Opportunity Cost:** Activating early vs. saving for critical moments

---

## Combat Flow and Procedures

### Pre-Combat Phase
1. **Battlefield Generation:** Load grid configuration and special tiles
2. **Unit Deployment:** Place units in starting positions
3. **Initiative Calculation:** Generate initial turn order
4. **Resource Initialization:** Set starting MP and equipment charges

### Turn Resolution Sequence
1. **Turn Start:** Apply start-of-turn status effects, process Burst Mode duration
2. **Action Selection:** Player/AI chooses action (including potential Burst activation)
3. **Target Selection:** Validate targets and positioning
4. **Action Resolution:** Apply effects in order, update Burst Gauge based on actions
5. **Status Update:** Process triggered effects and duration changes
6. **Burst Mode Check:** Handle Burst Mode expiration and stat restoration
7. **Turn End:** Apply end-of-turn effects, calculate next turn timing

### Combat End Conditions
- **Victory:** All enemy units incapacitated
- **Defeat:** All player units incapacitated
- **Objective Complete:** Mission-specific win conditions
- **Timeout:** Turn limit reached (rare, specific encounters)

---

## UI/UX Requirements

### Core Interface Elements
**Battle Grid Display:**
- Clear unit positioning and facing
- Movement range indicators
- Target highlight system
- Environmental hazard visualization

**Action Interface:**
- Available actions with resource costs
- Target selection system
- Action preview (damage estimates, positioning results)
- Undo/confirm system for complex turns

**Information Panels:**
- Unit health/status displays
- Turn order timeline
- Resource tracking (MP, equipment charges, Burst Gauge)
- Status effect tooltips
- Burst Mode indicators and duration timers

### Platform Considerations
**Input Method Abstraction:**
- Mouse & Keyboard: Hover targeting, right-click context menus
- Controller: D-pad navigation, button mapping
- Touch: Tap targeting, gesture controls

**Responsive Design:**
- Scalable UI elements for different screen sizes
- Information density adjustment
- Platform-specific interaction patterns

---

## Balance Framework

### Core Balance Principles
1. **Positional Advantage:** Positioning should provide clear tactical benefits
2. **Resource Tension:** Both MP and equipment charges should feel meaningful
3. **Risk/Reward:** Powerful abilities should require tactical setup or sacrifice
4. **Counter-play:** All strategies should have viable counters

### Balance Levers
**Numerical Adjustments:**
- Damage values and resource costs
- Status effect durations and potency
- Movement ranges and positioning restrictions

**Systemic Adjustments:**
- Turn order calculation methods
- Resource regeneration rates
- Status effect interaction rules

### Playtesting Metrics
- **Average Combat Duration:** Target 8-12 turns
- **Resource Utilization:** Players should use 80% of available resources
- **Decision Points:** Players should face meaningful choices each turn
- **Victory Conditions:** Multiple viable strategies per encounter

---

## Implementation Roadmap

### Phase 1: Core Systems (Prototype Foundation)
- Basic grid system with simple movement
- CTB turn order implementation
- Basic attack and movement actions
- Simple health/damage system

### Phase 2: Combat Depth
- Status effect framework
- Damage type and resistance system
- MP resource management
- Basic role abilities
- Burst Gauge system and basic transformations

### Phase 3: Advanced Mechanics
- Equipment charge system
- Complex positioning abilities
- Advanced status effects
- Health layer system (shields/armor)
- Advanced Burst Mode abilities and customizable charging

### Phase 4: Polish and Balance
- AI behavior implementation (including Burst Mode AI)
- UI/UX refinement
- Balance testing and adjustment
- Platform-specific optimizations

---

## Technical Architecture Notes

### Modular Interface Design
```java
interface CombatSystem {
    BattlefieldManager battlefield;
    TurnManager turnSystem;
    ActionProcessor actionHandler;
    DamageCalculator damageSystem;
    StatusEffectManager statusSystem;
    ResourceManager resourceSystem;
}
```

### Event-Driven Architecture
- Combat events (damage dealt, status applied, position changed)
- Subscription system for complex interactions
- Event history for debugging and replay systems

### Data Serialization
- Complete combat state serialization for save/load
- Action history tracking for replay analysis
- Modular system state for A/B testing different mechanics

---

## Complexity Management Strategy

### Toggleable Systems
Each major system component can be independently enabled/disabled:
- **Equipment Charges:** Can fall back to MP-only system
- **Health Layers:** Can simplify to basic health only
- **Complex Status Effects:** Can reduce to basic DOT/stat modifiers
- **Advanced Positioning:** Can limit to basic front/back row mechanics

### Progressive Complexity Introduction
- **Tutorial Mode:** Introduces one system at a time
- **Difficulty Modes:** Higher difficulties enable more systems
- **Player Options:** Allow players to toggle complexity features

### Cognitive Load Indicators
- **Turn Timer Options:** Pressure valves for decision paralysis
- **Auto-suggest Systems:** Highlight optimal moves for new players
- **Information Layering:** Progressive disclosure of complex interactions

---

## Appendix: System Interactions

### Cross-System Dependencies
- **Positioning ↔ Damage:** Front row protection affects damage calculation
- **Status Effects ↔ Resources:** Some effects modify resource generation/costs
- **Equipment ↔ Positioning:** Some gear provides movement abilities
- **Turn Order ↔ Actions:** Action choices affect future turn timing

### Edge Case Handling
- **Simultaneous Incapacitation:** Turn order determines resolution
- **Invalid Target States:** Action cancellation and resource refund policies
- **System Conflicts:** Priority order for contradictory effects
- **Performance Edge Cases:** Turn limit safeguards for infinite loops
