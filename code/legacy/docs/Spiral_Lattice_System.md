# Spiral Lattice Progression System

## 1. System Description

The Spiral Lattice is a flexible, grid-based character progression system that allows for deep customization. Each character has their own instance of the Lattice, and they navigate it to unlock new stats, skills, and powerful abilities tied to the Primordial Aspects.

### Movement and Activation

*   **Spiral Essence (SE):** This is the primary resource used to interact with the Lattice. Players earn SE from completing battles, quests, and discovering hidden lore.
*   **Navigating the Grid:** The Lattice is composed of interconnected nodes. Players can move from an activated node to an adjacent, connected node. Moving onto an inactive node does not cost anything, but a player cannot move past it until it is activated.
*   **Activating Nodes:** To gain the benefit of a node, the player must spend the required amount of Spiral Essence. Once activated, the node's effect is permanently applied to the character, and the player can then move to any other nodes connected to it.

### Node Types

The Spiral Lattice features three primary types of nodes:

1.  **Stat Node:**
    *   **Function:** These are the most common nodes. They provide small, incremental increases to a character's core statistics (e.g., Health, Will, Attack, Defense, Agility).
    *   **Purpose:** They form the connective tissue of the grid, allowing for steady, gradual power growth as players move towards more significant nodes.

2.  **Skill Node:**
    *   **Function:** These nodes unlock a new active or passive skill for the character to use in combat. Active skills could be new attacks or support abilities, while passive skills might grant buffs or unique combat behaviors.
    *   **Purpose:** These are major points of interest on the Lattice that define a character's capabilities and playstyle. Reaching a new Skill Node is a significant milestone in a character's development.

3.  **Aspect Node (Gate Node):**
    *   **Function:** These are rare, major nodes that are aligned with one of the 27 Primordial Aspects. Activating an Aspect Node grants a powerful, thematic ability and often requires a special item called an "Aspect Key" in addition to a high SE cost.
    *   **Purpose:** Aspect Nodes serve as gateways between different regions of the Spiral Lattice. For example, a character might start in a region focused on the "Warrior" and "Bulwark" roles. By activating a connected "Ignivox" Aspect Node, they can unlock a new branch of the grid filled with fire magic and magical damage stats, allowing for powerful hybrid builds.

### Specialization and Unlocking

The Spiral Lattice is not a single, open grid but a series of interconnected regions, each themed around a set of related Aspects or combat roles.

*   **Starting Regions:** Each character begins at a unique starting point on the Lattice that is tailored to their initial role (e.g., a Farshot starts in a region with Agility and Ranged Attack nodes).
*   **Branching Paths:** From their starting point, the player can choose from several paths. They might choose to go deeper into their initial specialization or branch out towards an Aspect Node to begin multi-classing. This allows players to either build a highly specialized "master" of one role or a versatile "jack-of-all-trades."

## 2. Data Structure (JSON)

The following JSON schema defines the structure for the Spiral Lattice data. It includes a list of all nodes and a separate list of the connections that form the grid.

```json
{
  "spiral_lattice": {
    "nodes": [
      {
        "id": 1,
        "type": "STAT",
        "name": "Lesser Vigor",
        "description": "Slightly increases maximum Health.",
        "effect": { "stat": "HEALTH", "value": 15 },
        "cost": 100
      },
      {
        "id": 2,
        "type": "STAT",
        "name": "Lesser Celerity",
        "description": "Slightly increases Agility.",
        "effect": { "stat": "AGILITY", "value": 2 },
        "cost": 100
      },
      {
        "id": 3,
        "type": "STAT",
        "name": "Lesser Might",
        "description": "Slightly increases Attack Power.",
        "effect": { "stat": "ATTACK", "value": 3 },
        "cost": 100
      },
      {
        "id": 4,
        "type": "STAT",
        "name": "Vigor",
        "description": "Increases maximum Health.",
        "effect": { "stat": "HEALTH", "value": 30 },
        "cost": 250
      },
      {
        "id": 5,
        "type": "SKILL",
        "name": "Shield Shove",
        "description": "Unlocks the 'Shield Shove' ability, which pushes an enemy back.",
        "effect": { "unlocks_skill_id": "SKILL_SHIELD_SHOVE" },
        "cost": 500
      },
      {
        "id": 6,
        "type": "STAT",
        "name": "Fortitude",
        "description": "Increases maximum Defense.",
        "effect": { "stat": "DEFENSE", "value": 5 },
        "cost": 250
      },
      {
        "id": 7,
        "type": "STAT",
        "name": "Greater Vigor",
        "description": "Greatly increases maximum Health.",
        "effect": { "stat": "HEALTH", "value": 50 },
        "cost": 400
      },
      {
        "id": 8,
        "type": "STAT",
        "name": "Greater Might",
        "description": "Greatly increases Attack Power.",
        "effect": { "stat": "ATTACK", "value": 8 },
        "cost": 400
      },
      {
        "id": 9,
        "type": "ASPECT",
        "name": "Warrior's Heart",
        "description": "Embrace the Warrior Aspect. Unlocks the 'Whirlwind Slash' ability and opens paths to advanced martial skills.",
        "effect": { "unlocks_skill_id": "SKILL_WHIRLWIND_SLASH", "unlocks_gate_id": "GATE_WARRIOR_ADVANCED" },
        "cost": 1000,
        "key_required": "KEY_OF_STRENGTH"
      }
    ],
    "connections": [
      { "from_node_id": 1, "to_node_id": 2 },
      { "from_node_id": 1, "to_node_id": 4 },
      { "from_node_id": 2, "to_node_id": 1 },
      { "from_node_id": 2, "to_node_id": 3 },
      { "from_node_id": 2, "to_node_id": 5 },
      { "from_node_id": 3, "to_node_id": 2 },
      { "from_node_id": 3, "to_node_id": 6 },
      { "from_node_id": 4, "to_node_id": 1 },
      { "from_node_id": 4, "to_node_id": 5 },
      { "from_node_id": 4, "to_node_id": 7 },
      { "from_node_id": 5, "to_node_id": 2 },
      { "from_node_id": 5, "to_node_id": 4 },
      { "from_node_id": 5, "to_node_id": 6 },
      { "from_node_id": 5, "to_node_id": 8 },
      { "from_node_id": 6, "to_node_id": 3 },
      { "from_node_id": 6, "to_node_id": 5 },
      { "from_node_id": 6, "to_node_id": 9 },
      { "from_node_id": 7, "to_node_id": 4 },
      { "from_node_id": 8, "to_node_id": 5 },
      { "from_node_id": 8, "to_node_id": 9 },
      { "from_node_id": 9, "to_node_id": 6 },
      { "from_node_id": 9, "to_node_id": 8 }
    ]
  }
}
```
