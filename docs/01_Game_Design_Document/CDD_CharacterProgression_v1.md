# Character Progression System Design Document

## 1. System Overview

### Core Design Principles
- **Modularity**: Each system component operates independently with clean interfaces
- **Separation of Concerns**: Progression, equipment, abilities, and stats maintain distinct responsibilities
- **Tabletop Adaptability**: All mechanics must translate to physical gameplay
- **Build Diversity**: Multiple viable paths through progression space

### Architecture Philosophy
Following the Law of Demeter and interface-implementation patterns, the system consists of loosely coupled modules communicating through well-defined interfaces.

## 2. Core Modules

### 2.1 Progression Service
**Responsibility**: Manages the universal 3D progression grid and node activation rules

```
Interface: IProgressionService
├── getAvailableNodes(characterId, roleId): List<NodeId>
├── activateNode(characterId, nodeId, cost): Boolean
├── getNodeRequirements(nodeId): Requirements
├── getPathBetweenNodes(startNode, endNode): List<NodeId>
└── validateRoleAccess(characterId, nodeId): Boolean
```

**Implementation Details**:
- Universal 3D grid with coordinate system (x, y, z)
- Role-based access control for node activation
- XP cost calculations per node type
- Path validation and traversal rules

### 2.2 Character Data Service
**Responsibility**: Maintains character state and provides read/write access to character properties

```
Interface: ICharacterDataService
├── getCharacterStats(characterId): StatBlock
├── updateCharacterStats(characterId, statChanges): Void
├── getExperiencePoints(characterId): Integer
├── modifyExperiencePoints(characterId, amount): Void
├── getActiveRole(characterId): RoleId
└── getProgressionState(characterId): ProgressionState
```

### 2.3 Role System
**Responsibility**: Defines role-specific progression paths, abilities, and restrictions

```
Interface: IRoleSystem
├── getRoleAbilities(roleId, level): List<AbilityId>
├── getRoleProgressionPath(roleId): List<NodeId>
├── getHybridRole(roleId1, roleId2): RoleId
├── getRolePassiveBonuses(roleId, level): List<PassiveEffect>
└── validateRoleTransition(fromRole, toRole): Boolean
```

### 2.4 Ability System
**Responsibility**: Manages ability acquisition, equipping, and usage

```
Interface: IAbilitySystem
├── getEquippedAbilities(characterId): List<AbilityId>
├── getAvailableAbilities(characterId): List<AbilityId>
├── equipAbility(characterId, slotIndex, abilityId): Boolean
├── getAbilityDetails(abilityId): AbilityDetails
├── canUseAbility(characterId, abilityId): Boolean
└── getAbilityMastery(characterId, abilityId): MasteryLevel
```

### 2.5 Equipment System
**Responsibility**: Handles equipment effects on progression and abilities

```
Interface: IEquipmentSystem
├── getEquippedItems(characterId): EquipmentSet
├── getEquipmentEffects(characterId): List<EquipmentEffect>
├── getEquipmentAbilities(characterId): List<AbilityId>
├── validateEquipment(characterId, itemId, slot): Boolean
└── getGlyphionCharges(itemId): Integer
```

## 3. Data Structures

### 3.1 Core Stats
```
StatBlock {
    constitution: Integer    // Health, Magic Points
    strength: Integer       // Physical damage, crit damage
    dexterity: Integer     // Crit rate, accuracy
    agility: Integer       // Initiative, evasion
    resonance: Integer     // Magic attack, magic defense
}
```

### 3.2 Progression Node
```
ProgressionNode {
    id: NodeId
    coordinates: Point3D
    type: NodeType          // STAT, ABILITY, PASSIVE, SPECIAL
    requirements: List<NodeId>
    roleRestrictions: List<RoleId>
    xpCost: Integer
    effects: List<Effect>
}

NodeType {
    STAT_BOOST,            // +2 to specific stat
    ABILITY_UNLOCK,        // Grants new ability
    ABILITY_SLOT,          // +1 equippable ability slot
    PASSIVE_BONUS,         // Permanent combat effect
    ROLE_FEATURE          // Role-specific enhancement
}
```

### 3.3 Role Definition
```
Role {
    id: RoleId
    name: String
    baseProgessionPath: List<NodeId>
    abilityProgression: Map<Level, List<AbilityId>>
    equipmentRestrictions: EquipmentRestrictions
    passiveBonuses: Map<Level, List<PassiveEffect>>
}

HybridRole extends Role {
    parentRoles: Pair<RoleId, RoleId>
    fusionRules: FusionRuleSet
}
```

### 3.4 Ability Definition
```
Ability {
    id: AbilityId
    name: String
    type: AbilityType       // ATTACK, HEAL, BUFF, DEBUFF, UTILITY
    targetType: TargetType  // SINGLE, AREA, SELF, PARTY
    basePower: Integer
    cost: ResourceCost
    cooldown: Integer
    description: String
    permutations: List<AbilityPermutation>
}

AbilityPermutation {
    masteryRequired: Integer
    modifierType: ModifierType  // POWER, COST, RANGE, EFFECT
    value: Numeric
    description: String
}
```

## 4. System Interactions

### 4.1 Progression Flow
1. **XP Gain**: Combat/Quest systems notify Character Data Service
2. **Node Purchase**: UI queries Progression Service for available nodes
3. **Effect Application**: Progression Service notifies relevant systems of stat/ability changes
4. **Validation**: All systems validate state consistency

### 4.2 Equipment Integration
```
EquipmentEffect {
    type: EffectType
    target: TargetType
    value: Numeric
    condition: Condition?
}

EffectType {
    STAT_MODIFIER,         // Direct stat changes
    XP_MULTIPLIER,         // Affects XP gain rates
    NODE_UNLOCK,           // Temporarily unlocks progression nodes
    ABILITY_GRANT,         // Provides additional abilities
    COST_REDUCTION        // Reduces node purchase costs
}
```

### 4.3 Cross-System Communication
- **Event Bus Pattern**: Systems publish/subscribe to relevant events
- **Dependency Injection**: Services injected rather than directly instantiated
- **Interface Segregation**: Systems only depend on interfaces they actually use

## 5. Implementation Considerations

### 5.1 Data Persistence
- Character progression state stored separately from character base data
- Ability mastery tracked independently per character-ability pair
- Equipment effects calculated dynamically, not stored

### 5.2 Performance Optimization
- Progression paths pre-calculated and cached
- Node availability computed lazily
- Equipment effects aggregated during character loading

### 5.3 Extensibility Points
- Plugin architecture for custom node types
- Scriptable equipment effects
- Modular ability system supporting expansion packs

### 5.4 Validation Rules
- Role transitions must preserve character power level
- Node purchases must maintain path connectivity
- Equipment compatibility checked before application

## 6. Testing Strategy

### 6.1 Unit Testing
- Mock implementations for all interfaces
- Isolated testing of progression calculations
- Equipment effect validation

### 6.2 Integration Testing
- Cross-system state consistency
- Save/load progression state
- Equipment swapping scenarios

### 6.3 Tabletop Validation
- All mechanics must be calculable without digital assistance
- Progression choices must be meaningful in tabletop context
- Equipment effects must be trackable on paper

## 7. Future Considerations

### 7.1 Expandability
- New roles can be added without modifying existing systems
- Additional progression dimensions (4D grid)
- Dynamic node generation for procedural content

### 7.2 Respec Mechanics
- Complete progression reset with rare items
- Partial respec for limited node ranges
- Role change requiring full character rebuild

This modular architecture ensures that each system can evolve independently while maintaining clean integration points for cross-system functionality.
