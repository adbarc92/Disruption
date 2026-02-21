# Disruption - Project Context

## Overview

Disruption is a turn-based tactical RPG combining elements from Darkest Dungeon (positional combat), Final Fantasy X (CTB turn order), Chrono Trigger (exploration and encounter style), and Persona (weakness/resistance mechanics). The game is designed to work both as a digital game and as a tabletop experience.

---

## Current Development Target: Vertical Slice

### Technical Decisions
- **Engine**: Godot 4 (GDScript)
- **Primary Targets**: Steam (Windows/Mac/Linux) + iPad
- **Future Targets**: Console ports (architecture should accommodate)
- **Art Style**: HD 2D sprites, 2.5D top-down perspective (Chrono Trigger/Sea of Stars style)
- **Assets**: Placeholder art first, production art later
- **Audio**: Placeholder/royalty-free initially

### Vertical Slice Scope
- **Narrative**: Opening sequence of the game
- **Party**: Cyrus, Vaughn, Phaidros (DPS, tactical rogue, tank)
- **Combat**: 3v3, visible enemies on map (Chrono Trigger style encounters)
- **Dialog**: Branching with choices that have consequences

### Vertical Slice Components
1. **Cutscene** - Opening cinematic/narrative sequence
2. **Dialog** - Character interactions with player choices
3. **Exploration** - Chrono Trigger/Sea of Stars style 2.5D top-down movement with:
   - 8-directional free movement
   - Hopping over obstacles (always available, short hop arc)
   - Grappling to grapple points
   - Sprinting
   - Rolling/dodging
4. **Combat** - Full tactical battle demonstrating core systems

### Development Phases
| Phase | Focus | Deliverable |
|-------|-------|-------------|
| 1 | Project Setup | Godot project structure, input mapping, scene management |
| 2 | Movement Core | Character controller (jump, roll, sprint, grapple) |
| 3 | Combat Foundation | 3x3 grid, turn order, basic attacks, positioning |
| 4 | Dialog System | Branching dialog with consequence tracking |
| 5 | Exploration Scene | Playable area with obstacles and visible enemy |
| 6 | Combat Polish | Skills, status effects, combat UI |
| 7 | Cutscene System | Cutscene playback/scripting |
| 8 | Integration | Full vertical slice flow |

### Input Considerations
- **Steam**: Keyboard/Mouse + Controller support
- **iPad**: Touch controls (virtual joystick, gesture-based actions)
- Design touch-first for platforming actions, adapt to controller/keyboard

---

## Architecture Principles

### Separation of Concerns
The codebase should be structured to maximize portability and maintainability. Keep these layers clearly separated:

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

### Implementation Guidelines

**1. Data-Driven Design**
- Store game data (characters, skills, enemies, dialog, story flags) in JSON or portable resource files
- Avoid hardcoding game balance values in scripts
- Use configuration files that can be loaded by any engine

**2. Pure Logic Classes**
- Combat calculations, turn order, damage formulas should be in pure classes with no engine dependencies
- These classes should be testable without running the game
- Example: `CombatCalculator`, `TurnOrderManager`, `ProgressionCalculator`

**3. Engine Abstraction**
- Create wrapper interfaces for engine-specific functionality
- Input handling, scene management, audio playback should go through abstractions
- This allows swapping the engine layer without rewriting game logic

**4. Minimal Node Coupling**
- Scripts should communicate through signals/events, not direct node references where possible
- Use the EventBus for cross-system communication
- Avoid deep node path dependencies (`$Parent/Child/Grandchild`)

**5. Portable Data Formats**
```
data/
├── characters/          # Character definitions (JSON)
├── skills/              # Skill/ability data (JSON)
├── enemies/             # Enemy templates (JSON)
├── dialog/              # Dialog trees (JSON)
├── progression/         # Grid nodes, costs (JSON)
└── combat/              # Battle configurations (JSON)
```

**6. Future Unreal Consideration**
- GDScript classes that contain pure game logic should be written in a style that translates easily to C++ or Blueprints
- Avoid GDScript-specific idioms where a more universal pattern exists
- Document any Godot-specific workarounds that would need reimplementation

### File Organization by Concern
```
scripts/
├── autoload/            # Global managers (engine-coupled)
├── data/                # Data loading, models (portable)
├── logic/               # Pure game logic (portable)
│   ├── combat/          # Combat calculations
│   ├── progression/     # XP, grid, mastery
│   └── dialog/          # Dialog state machine
├── presentation/        # Godot-specific display logic
│   ├── exploration/     # Player controller, camera
│   ├── combat/          # Battle UI, animations
│   └── ui/              # Menus, HUD
└── util/                # Helpers, constants (portable)
```

---

## Core Design Pillars

1. **Playtesting is King** - A game is worthless if players aren't having fun. Design documents are hypotheses; playtesting reveals truth. When design conflicts with player enjoyment, enjoyment wins. Iterate rapidly, test frequently, and let player experience guide all decisions.
2. **Positioning as Primary Strategy** - Combat revolves around manipulating unit positions on a 3x3 grid per side
3. **Modular Architecture** - All systems designed for easy swapping and iteration
4. **Resource Depth** - Dual resource management (MP + Equipment charges + Burst Gauge)
5. **Complexity Scalability** - Systems can be individually toggled for complexity management
6. **Tabletop Compatibility** - All mechanics designed to function without digital assistance

---

## Combat System

### Battlefield
- **Configuration**: Two opposing 3x3 grids (6x3 total battlefield)
- **Positions**: Front/Mid/Back columns, Top/Mid/Bottom rows
- **Special Tiles**: Trap tiles, obstruction tiles, environmental hazards
- **Front Row Protection**: Units behind occupied front column positions take reduced damage

### Turn Management (CTB)
- Speed-based initiative determines turn frequency
- Different actions cause different delays before next turn
- Turn preview shows upcoming 8-10 turns
- **Action Economy Options**:
  - Action Point System (3-5 AP per turn)
  - Structured System (Movement + Action + Bonus Action, like D&D 5e)

### Damage Types
- **Physical**: Slash, Pierce, Blunt
- **Elemental**: Fire, Ice, Lightning, Earth, Wind, Water
- **Magical**: Arcane, Divine, Occult
- **Special**: Psychic, Necrotic, Radiant

### Resistance Levels
- Immune (0%), Resistant (50%), Normal (100%), Vulnerable (150%)

### Health Layers (in damage absorption order)
1. Shields (temporary, own resistances)
2. Armor (damage reduction layer)
3. Health (core HP)
4. Overhealth (temporary bonus from abilities)

### Resource Systems
- **MP**: Regenerates 2-3 per turn, spent on role abilities
- **Equipment Charges**: Limited uses per combat, powerful abilities
- **Burst Gauge**: 100 points max, enables transformation mode

---

## Burst Mode System

- Gauge fills via customizable charging methods (aggressive, defensive, support, technical)
- At 100 points, player can activate transformation (4-6 turns)
- Provides stat boosts (+40-60% damage, +2-3 turn order positions)
- Transforms basic abilities and grants exclusive ultimate abilities
- Gauge partially carries between combats (25-40%)

### Charging Methods Examples
- **Berserker**: +15 per enemy defeated, +5 per crit
- **Guardian**: +12 per damage absorbed for allies
- **Tactician**: +8 per ally repositioned, +12 per enemy repositioned
- **Opportunist**: +10 per weakness exploited

---

## Character Progression System

### 3D Progression Grid (FFX Sphere Grid inspired)
- **X-Axis**: Combat to Magic to Support specialization
- **Y-Axis**: Basic to Advanced to Master advancement
- **Z-Axis**: Offensive to Defensive to Utility depth

### Node Types
- **STAT_BOOST**: +2 primary stats or +5% derived stats
- **ABILITY_UNLOCK**: Grant access to role-specific abilities
- **ABILITY_SLOT**: Increase equippable abilities (4 base, 8 max)
- **PASSIVE_BONUS**: Always-active combat/exploration bonuses
- **ROLE_FEATURE**: Capstone abilities, hybrid unlocks

### Dual Experience Systems
1. **Character XP**: Used for grid node activation (50-500 XP per source)
2. **Ability Mastery XP**: Per-ability progression unlocking permutations (0-5 levels)

### Role System
- Roles serve as "Ability Tags" more than strict classes
- **Primitive Roles**: Elemental (Luminarch, Hydrosage, Geovant, Ignivox), Damage (Shadowfang, Bladewarden, Farshot), Utility (Gridreaver, Chronovant, Ironskin), Specialist (Metamorph, Synergist)
- **Hybrid Roles**: Combinations like Breaker, Huntsman, Tidalreaver, Pyrechain
- Role mastery provides bonuses at 10/25/45/70+ nodes activated

---

## Playable Characters

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

### Burst Mode Transformations (per character)
- **Cyrus**: "Elemental Mastery" - all attacks gain random elements, area attacks
- **Vaughn**: "Master Tactician" - +45% crit, allies gain extra actions
- **Phaidros**: "Mountain King" - +70% damage reduction, party-wide defense
- **Paidi**: "Harmonic Resonance" - all Mien effects active, dual heal/damage
- **Lione**: "Omnific Mirror" - use any ability seen this combat
- **Euphen**: "Shadow Lord" - stealth on all abilities, instant traps
- **Chiranjivi**: "Crimson Vessel" - immune to Bleed, convert self-harm to benefits

---

## Codebase Structure

**Tech Stack**: TypeScript, using UUID for identifiers

### Code Location: `code/src/model/`

| File | Purpose |
|------|---------|
| `ability-score.ts` | VIG, STR, DEX, RES, AGI ability scores (1-10 range) |
| `stats.ts` | Derived stats (vitality, defense, damage, crit, etc.) |
| `unit.ts` | Combat unit with category, family, stats, equipment |
| `skill.ts` | Skill definitions with positions, effects, damage types |
| `effect.ts` | Battle and field effects (health, status, position modifiers) |
| `status-effect.ts` | Status effects with types, activation times, duration |
| `equipment.ts` | Equipment with slots and stat bonuses |
| `position.ts` | Position management with advance/retreat/strafe |
| `space.ts` | 2D point system, 3x3 grid positions |
| `battle.ts` | Battle structure (stub - turn order, actors) |
| `core.ts` | Architecture notes and system overview |

### Current Implementation State
- **Implemented**: Core data models for units, skills, stats, effects, positions
- **Stubbed**: Battle system, AI system
- **Not Started**: Progression grid, burst mode, turn management, UI

### Key Design Patterns
- Separation of base stats vs current stats (for effects/resets)
- Family-based skill and equipment restrictions
- Position-based skill targeting system
- Modular effect composition

---

## Glyphion Equipment System

Charge-based powerful equipment with unique abilities:
- Limited uses per combat (1-3 charges typically)
- Significantly more powerful than standard abilities
- Examples: Earth Gauntlets (Earthquake), Shadow Cloak (teleport), Gravity Core (Singularity)

---

## Status Effects

### Categories
- **Health**: Regenerating, Poisoned, Burning
- **Beneficial**: Strengthened, Energized, Invisible, Immune
- **Detrimental**: Weakened, Disrupted
- **Control**: Paralyzed, Stunned, Restrained, Frozen, Charmed, Frightened
- **Unique**: Apotheosis, Unraveling, Quickened

### Special Status Effects
- **Well-rested**: Increased XP gain
- **Flow**: Increased ability XP gain
- **Enshrouded**: Damage resistance buff

---

## Technique Progression

- Techniques develop through usage
- Natural power growth over time
- Can gain extra effects: status infliction, extended range, AOE expansion

---

## Development Notes

- The GDD master file appears empty (v1) - primary design is in CDD documents
- Burst Mode system needs renaming (marked FIXME)
- Burst effects should be story-locked and vary by genetic categories
- Role system is evolving from "Jobs" to "Ability Tags"
- Consider 2D grid fallback for simpler tabletop representation

---

## File Organization

```
docs/
├── 01_Game_Design_Document/   # Core game mechanics
├── 02_Story_Narrative/        # Lore and world history
├── 03_World_Building/         # Bestiary, social strata
├── 04_Characters/             # Character profiles and glimpses
code/
└── src/model/                 # TypeScript data models
ui/
└── Sample UI.jpg              # UI reference
```
