# Character Progression System Design Document

## Executive Summary

This document outlines a modular character progression system emphasizing build diversity, meaningful choice, and clean architectural separation. The system combines a universal 3D progression grid inspired by FFX's Sphere Grid with role-based restrictions, dual experience systems for character and skill advancement, and equipment integration that enhances rather than replaces core progression mechanics.

**Core Pillars:**
- **Modular Architecture:** Clean separation of concerns with interface-driven design for rapid iteration
- **Universal Progression Grid:** 3D node-based advancement system accessible to all roles with role-specific restrictions
- **Dual Experience Systems:** Character XP for grid progression and Ability XP for skill mastery and customization
- **Tabletop Compatibility:** All mechanics designed to function without digital assistance

---

## System Architecture Overview

### Modular Component Structure

```
Character Progression System
├── Progression Grid Module (3D Node Navigation + Activation)
├── Character Data Module (Stats + XP + State Management)
├── Role System Module (Progression Paths + Abilities + Restrictions)
├── Ability Management Module (Equipping + Mastery + Permutations)
├── Equipment Integration Module (Stat Modifiers + Progression Effects)
└── Experience Management Module (XP Gain + Ability Mastery Tracking)
```

Each module implements standardized interfaces allowing for complete subsystem replacement during development and easy adaptation to tabletop environments.

---

## Universal 3D Progression Grid System

### Core Grid Philosophy
The progression system centers around a universal 3D grid where all advancement occurs through node activation. Unlike traditional class-locked systems, every character can theoretically access every node, but role restrictions create natural progression paths while allowing for creative character building.

### Grid Architecture
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

### Node Types Framework
Each node provides specific advancement benefits:

**STAT_BOOST Nodes:**
- **Primary Stats:** +2 to Constitution, Strength, Dexterity, Agility, or Resonance
- **Secondary Stats:** +5% to derived stats (Health, MP, Critical Rate, etc.)
- **Hybrid Stats:** +1 to two different primary stats

**ABILITY_UNLOCK Nodes:**
- **Role Abilities:** Grant access to new role-specific combat abilities
- **Universal Abilities:** Basic abilities available to all characters
- **Cross-Role Abilities:** Abilities from other roles (rare, high-cost nodes)

**ABILITY_SLOT Nodes:**
- **Equipment Slots:** Increase maximum equippable abilities from roles
- **Standard Progression:** Start with 4 slots, maximum of 8 through grid progression
- **Specialization:** Some nodes grant specialized slots (offensive/defensive/utility)

**PASSIVE_BONUS Nodes:**
- **Combat Passives:** Always-active bonuses during battle
- **Exploration Passives:** Benefits for field/world navigation
- **Resource Passives:** MP regeneration, XP gain modifiers, equipment efficiency

**ROLE_FEATURE Nodes:**
- **Role Enhancement:** Strengthen existing role abilities
- **Hybrid Unlocks:** Enable hybrid role combinations
- **Mastery Bonuses:** Capstone abilities for role specialization

### Node Connectivity and Pathfinding
**Connection Rules:**
- **Adjacent Connectivity:** Nodes connect to immediate neighbors in 3D space
- **Bridge Nodes:** Special nodes that create long-distance connections
- **Role Pathways:** Predetermined efficient routes for each role
- **Hidden Connections:** Advanced pathways unlocked by specific conditions

**Path Validation:**
- **Prerequisite Checking:** Ensure required nodes are activated
- **Role Restriction Enforcement:** Validate character can access target node
- **Cost Calculation:** Determine XP cost based on node type and character state

### Progression Cost Structure
**Base XP Costs by Node Type:**
- **STAT_BOOST:** 100 XP (linear scaling)
- **ABILITY_UNLOCK:** 150-300 XP (based on ability power)
- **ABILITY_SLOT:** 200 XP (increases per slot: 200, 250, 300, 350)
- **PASSIVE_BONUS:** 175-250 XP (based on benefit strength)
- **ROLE_FEATURE:** 300-500 XP (capstone abilities most expensive)

**Cost Modifiers:**
- **Role Alignment:** -25% cost for nodes on character's primary role path
- **Distance Penalty:** +10% cost per node distance from nearest activated node
- **Equipment Bonuses:** Certain items reduce costs for specific node types
- **Hybrid Role Tax:** +50% cost for nodes outside both component roles

---

## Role System Integration

### Role-Based Progression Paths
Each role defines recommended progression routes through the 3D grid, but players can deviate for customization.

**Primary Role Structure:**
```java
interface Role {
    String getId();
    String getName();
    List<GridCoordinate> getRecommendedPath();
    Set<GridCoordinate> getRestrictedNodes();
    Map<Integer, List<AbilityId>> getAbilityProgression();
    List<PassiveEffect> getLevelBasedPassives();
}
```

**Role Progression Benefits:**
- **Efficient Pathing:** Clear routes to important abilities and stats
- **Cost Reduction:** Reduced XP costs for role-aligned nodes
- **Passive Acquisition:** Automatic bonuses as role mastery increases
- **Equipment Compatibility:** Access to role-specific gear

### Hybrid Role Mechanics
**Hybrid Role Generation:**
- **Parent Role Combination:** Each hybrid inherits from two base roles
- **Shared Progression:** Access to nodes from both parent role paths
- **Unique Nodes:** Exclusive hybrid-only nodes at intersection points
- **Balanced Restrictions:** Cannot access nodes forbidden to either parent role

**Implementation Example:**
```java
class HybridRole implements Role {
    private Role primaryParent;
    private Role secondaryParent;
    private Set<GridCoordinate> exclusiveNodes;

    @Override
    public Set<GridCoordinate> getRestrictedNodes() {
        return Sets.union(
            primaryParent.getRestrictedNodes(),
            secondaryParent.getRestrictedNodes()
        );
    }
}
```

### Role Mastery Progression
**Mastery Calculation:**
- **Node Count:** Total nodes activated on role's recommended path
- **Depth Achievement:** Advancement into higher Y-coordinate tiers
- **Specialization Balance:** Mix of offensive/defensive/utility nodes

**Mastery Benefits:**
- **Level 1 (10 nodes):** Basic role passive + equipment access
- **Level 2 (25 nodes):** Enhanced passive + advanced equipment
- **Level 3 (45 nodes):** Master passive + unique equipment access
- **Level 4 (70+ nodes):** Capstone passive + legendary equipment

---

## Dual Experience Systems

### Primary Experience: Character XP
**Gain Sources:**
- **Combat Victory:** 50-150 XP per encounter (based on difficulty)
- **Quest Completion:** 100-500 XP (based on complexity)
- **Exploration Milestones:** 25-75 XP (discovering locations, solving puzzles)
- **Special Items:** Rare consumables granting bonus XP

**Experience Modifiers:**
- **Equipment Bonuses:** +10-25% XP gain from specific items
- **Status Effects:** "Well-rested" and similar buffs increase XP gain
- **Difficulty Settings:** Higher difficulty multipliers for increased XP
- **Party Composition:** Balanced parties may receive small XP bonuses

**Usage:**
- **Exclusive Use:** Character XP only used for grid node activation
- **No Level Caps:** Progression limited only by grid boundaries
- **Banking System:** Excess XP stored for future expensive nodes

### Secondary Experience: Ability Mastery
**Individual Ability Tracking:**
Each character-ability combination maintains independent mastery progression:

```java
class AbilityMastery {
    private AbilityId abilityId;
    private CharacterId characterId;
    private int masteryLevel;        // 0-5 scale
    private int experiencePoints;    // Progress toward next level
    private List<Permutation> unlockedPermutations;
}
```

**Mastery Gain Methods:**
- **Ability Usage:** +2-5 points per use (based on ability complexity)
- **Successful Application:** Bonus points for effective usage
- **Combat Context:** Extra points for using abilities in challenging situations
- **Equipment Synergy:** "Flow" status effect doubles ability XP gain

**Mastery Level Benefits:**
- **Level 1 (100 points):** Unlock first permutation option
- **Level 2 (250 points):** Second permutation + minor efficiency improvement
- **Level 3 (450 points):** Third permutation + moderate power increase
- **Level 4 (700 points):** Advanced permutation + significant enhancement
- **Level 5 (1000 points):** Master permutation + maximum efficiency

### Permutation System Framework
**Permutation Categories:**
- **Power Modification:** +20% damage/healing, additional targets, extended duration
- **Cost Efficiency:** -1 MP cost (minimum 1), reduced cooldowns
- **Tactical Enhancement:** Extended range, repositioning effects, status additions
- **Synergy Effects:** Interactions with other abilities, combo potential

**Implementation Architecture:**
```java
interface AbilityPermutation {
    String getName();
    String getDescription();
    int getMasteryRequirement();
    ModifierSet getModifiers();
    boolean isCompatibleWith(List<AbilityPermutation> activePermutations);
}
```

---

## Equipment Integration Layer

### Equipment Effect Categories
Equipment enhances rather than replaces progression, providing temporary bonuses and new tactical options.

**Stat Modification Effects:**
- **Direct Bonuses:** +3 to primary stats, +10% to derived stats
- **Conditional Bonuses:** Stats increase under specific conditions
- **Conversion Effects:** Strength contributes to magic damage, etc.
- **Scaling Bonuses:** Effects that improve with character advancement

**Progression Enhancement Effects:**
- **XP Multipliers:** +15-30% to character or ability XP gain
- **Cost Reduction:** -10% to specific node types or ability costs
- **Path Unlocking:** Temporary access to restricted grid areas
- **Node Efficiency:** Reduced requirements for node activation

**Ability Enhancement Effects:**
- **Passive Abilities:** Equipment grants additional abilities beyond the 8-slot limit
- **Ability Modification:** Temporary permutation effects while equipped
- **Resource Enhancement:** Additional MP, extended ability ranges
- **Combination Effects:** Equipment that enhances specific ability combinations

### Glyphion Technology System
**Glyphion Properties:**
- **Charge-Based:** Limited uses per combat encounter
- **High Impact:** Significantly more powerful than standard equipment
- **Unique Effects:** Abilities not available through normal progression
- **Strategic Resource:** Must choose when to expend limited charges

**Glyphion Categories:**
- **Offensive Glyphion:** Devastating attacks, area damage, armor penetration
- **Defensive Glyphion:** Damage shields, status immunity, emergency healing
- **Utility Glyphion:** Battlefield manipulation, resource restoration, positioning

**Implementation Framework:**
```java
interface Glyphion extends Equipment {
    int getMaxCharges();
    int getCurrentCharges();
    List<GlyphionAbility> getProvidedAbilities();
    void consumeCharge();
    boolean canActivate();
}
```

---

## System Integration and Cross-Module Communication

### Data Flow Architecture
**Character State Management:**
```java
interface ICharacterDataService {
    // Core Stats
    StatBlock getBaseStats(CharacterId id);
    StatBlock getModifiedStats(CharacterId id);

    // Experience Tracking
    int getCharacterXP(CharacterId id);
    Map<AbilityId, AbilityMastery> getAbilityMasteries(CharacterId id);

    // Progression State
    Set<GridCoordinate> getActivatedNodes(CharacterId id);
    List<EquippedAbility> getEquippedAbilities(CharacterId id);
}
```

**Event-Driven Updates:**
- **XP Gain Events:** Combat system notifies experience module
- **Node Activation Events:** Progression module broadcasts stat changes
- **Equipment Changes:** Equipment system triggers recalculation of modifiers
- **Ability Usage Events:** Combat system updates ability mastery tracking

### Cross-System Validation
**Consistency Checking:**
- **Stat Totals:** Verify calculated stats match expected values
- **Progression Validity:** Ensure all activated nodes meet prerequisites
- **Equipment Compatibility:** Validate character can use equipped items
- **Ability Availability:** Confirm equipped abilities are accessible to character

**Error Handling Strategies:**
- **Graceful Degradation:** System functions with missing optional components
- **State Recovery:** Automatic correction of minor inconsistencies
- **Rollback Capability:** Revert to last known good state on critical errors
- **Debug Information:** Comprehensive logging for development troubleshooting

---

## Balance Framework and Design Constraints

### Progression Balance Principles
**Time Investment Scaling:**
- **Early Nodes:** 1-2 combat encounters worth of XP
- **Mid-Tier Nodes:** 3-5 encounters for significant upgrades
- **High-Tier Nodes:** 8-12 encounters for major advancements
- **Capstone Nodes:** 15-20 encounters for ultimate abilities

**Power Curve Management:**
- **Linear Base Growth:** Stats increase predictably for encounter design
- **Multiplicative Equipment:** Gear provides percentage bonuses to base stats
- **Ability Scaling:** Higher-tier abilities cost proportionally more resources
- **Diminishing Returns:** Multiple similar bonuses provide reduced benefits

### Choice Significance Framework
**Meaningful Decision Points:**
- **Path Divergence:** Multiple viable routes to similar power levels
- **Specialization vs. Generalization:** Clear trade-offs between focused and broad builds
- **Resource Allocation:** XP scarcity forces prioritization decisions
- **Timing Decisions:** When to pursue expensive nodes vs. multiple cheap ones

**Build Diversity Support:**
- **Multiple Viable Paths:** At least 3 distinct progression routes per role
- **Hybrid Viability:** Combined roles competitive with pure roles
- **Equipment Synergy:** Gear combinations enable unique character builds
- **Late-Game Customization:** High-tier nodes allow build refinement

### Tabletop Adaptation Requirements
**Physical Playability Constraints:**
- **Manual Calculation:** All formulas computable without digital assistance
- **Visual Representation:** 3D grid must be representable on paper/physical tokens
- **State Tracking:** Character sheets can track all necessary progression information
- **Random Generation:** XP gain and costs work with standard dice

**Simplified Variants:**
- **2D Grid Option:** Flatten Z-axis for simpler tabletop representation
- **Reduced Node Types:** Combine complex node types for easier management
- **Fixed Costs:** Simplified XP cost structure for manual calculation
- **Printed Paths:** Pre-generated role progression sheets

---

## Implementation Roadmap

### Phase 1: Core Infrastructure
- **Grid System:** 3D coordinate system and node connectivity
- **Character Data:** Basic stat tracking and XP management
- **Role Framework:** Base role definitions and progression paths
- **Simple Node Types:** STAT_BOOST and ABILITY_UNLOCK only

### Phase 2: Advanced Progression
- **Full Node Types:** Complete implementation of all node categories
- **Hybrid Roles:** Role combination system and unique nodes
- **Ability Mastery:** Secondary XP system and permutation framework
- **Cost Calculation:** Dynamic pricing based on character state and modifiers

### Phase 3: Equipment Integration
- **Equipment Effects:** Stat modifiers and progression enhancements
- **Glyphion System:** Charge-based equipment with unique abilities
- **Cross-System Communication:** Event-driven updates between modules
- **Validation Systems:** Consistency checking and error handling

### Phase 4: Balance and Polish
- **Progression Tuning:** XP costs, node power levels, ability balance
- **Tabletop Adaptation:** Simplified variants and physical play materials
- **Performance Optimization:** Efficient calculation and state management
- **Documentation:** Complete API documentation and implementation guides

---

## Technical Architecture Specifications

### Interface Definitions
```java
// Core Progression Interface
interface IProgressionService {
    Set<GridCoordinate> getAvailableNodes(CharacterId id);
    boolean canActivateNode(CharacterId id, GridCoordinate node);
    ActivationResult activateNode(CharacterId id, GridCoordinate node);
    int calculateNodeCost(CharacterId id, GridCoordinate node);
    List<GridCoordinate> findPathToNode(CharacterId id, GridCoordinate target);
}

// Character Data Interface
interface ICharacterDataService {
    StatBlock getCharacterStats(CharacterId id);
    int getExperiencePoints(CharacterId id);
    void modifyExperiencePoints(CharacterId id, int amount);
    Set<GridCoordinate> getActivatedNodes(CharacterId id);
    RoleId getActiveRole(CharacterId id);
}

// Experience Management Interface
interface IExperienceService {
    void awardExperience(CharacterId id, ExperienceSource source, int amount);
    void awardAbilityExperience(CharacterId id, AbilityId ability, int amount);
    Map<AbilityId, AbilityMastery> getAbilityMasteries(CharacterId id);
    List<AbilityPermutation> getAvailablePermutations(CharacterId id, AbilityId ability);
}
```

### Data Model Architecture
```java
// Core Progression Node
class ProgressionNode {
    private GridCoordinate coordinate;
    private NodeType type;
    private Set<GridCoordinate> prerequisites;
    private Set<RoleId> roleRestrictions;
    private int baseCost;
    private List<NodeEffect> effects;
    private String description;
}

// Character Progression State
class CharacterProgressionState {
    private CharacterId characterId;
    private Set<GridCoordinate> activatedNodes;
    private int currentExperience;
    private Map<AbilityId, AbilityMastery> abilityMasteries;
    private List<EquippedAbility> equippedAbilities;
    private RoleId activeRole;
}
```

### Event System Architecture
**Event Types:**
- **ExperienceGainedEvent:** Triggered when character gains XP
- **NodeActivatedEvent:** Fired when progression node is purchased
- **AbilityMasteredEvent:** Broadcast when ability reaches new mastery level
- **EquipmentChangedEvent:** Sent when character equipment modifications occur
- **StatRecalculationEvent:** Triggered when character stats need updating

**Event Handling:**
```java
interface IEventHandler<T extends GameEvent> {
    void handleEvent(T event);
    boolean canHandleEvent(Class<? extends GameEvent> eventType);
}
```

---

## Complexity Management Strategy

### Toggleable System Components
**Progression Complexity Levels:**
- **Simplified Mode:** 2D grid, fixed costs, basic node types only
- **Standard Mode:** Full 3D grid with all node types and role restrictions
- **Advanced Mode:** Dynamic costs, equipment integration, complex permutations
- **Master Mode:** All systems enabled with maximum customization options

**Module Independence:**
- **Ability Mastery:** Can be disabled to use abilities at fixed effectiveness
- **Equipment Integration:** Can fall back to stat bonuses only
- **Hybrid Roles:** Can restrict to single roles only
- **Dynamic Costs:** Can use fixed XP costs for simplified management

### Progressive Disclosure
**Tutorial Integration:**
- **Phase 1:** Basic XP gain and simple stat node purchases
- **Phase 2:** Introduction of ability nodes and equipment slots
- **Phase 3:** Advanced node types and role restrictions
- **Phase 4:** Full system with mastery, equipment integration, and optimization

**Player Assistance Systems:**
- **Recommended Builds:** Pre-configured progression paths for new players
- **Cost Calculator:** Tools to plan expensive node purchases
- **Build Comparison:** Side-by-side analysis of different progression choices
- **Mistake Recovery:** Limited respec options for correcting poor decisions

---

## Appendix: System Interactions and Edge Cases

### Cross-System Dependencies
**Progression ↔ Combat:** Node activation affects combat statistics and available abilities
**Equipment ↔ Progression:** Gear modifies XP costs and unlocks temporary progression access
**Role ↔ Ability:** Role determines which abilities can be equipped and mastered
**Experience ↔ Balance:** XP gain rates must align with content difficulty and progression costs

### Edge Case Handling
**Invalid Progression States:**
- **Orphaned Nodes:** Activated nodes with no valid path to character's current position
- **Role Conflicts:** Character attempting to access nodes forbidden by current role
- **Insufficient Resources:** Node activation attempts without adequate XP
- **Equipment Dependencies:** Gear removal that invalidates current character build

**Recovery Strategies:**
- **Automatic Correction:** System attempts to resolve minor inconsistencies
- **Player Notification:** Clear messages about invalid states and correction options
- **Graceful Degradation:** Character remains functional even with some invalid progression
- **Manual Override:** Administrative tools for correcting complex edge cases

**Performance Considerations:**
- **Path Calculation Caching:** Pre-compute common progression routes
- **Lazy Evaluation:** Calculate expensive operations only when needed
- **Batch Updates:** Group multiple progression changes for efficiency
- **Memory Management:** Efficient storage of large 3D grid structures

This comprehensive system provides the modular architecture you requested while maintaining the depth and complexity necessary for engaging character progression in both digital and tabletop environments.
