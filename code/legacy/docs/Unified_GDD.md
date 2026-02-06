# Game Design Document: Eternal Spiral

## Project Overview

**Game Title:** Eternal Spiral
**Genre:** Tactical JRPG
**Elevator Pitch:** Eternal Spiral is a tactical JRPG that combines the strategic depth of grid-based combat with a rich, philosophical narrative. Players command a party of heroes who wield the power of "Exousia," a vital life force, to mend a fractured reality known as the Cosmic Wound. By manipulating the battlefield, mastering a deep, turn-based combat system, and making morally complex choices, players will embark on a quest to restore balance to a world teetering on the brink of chaos, where every decision shapes the fate of the cosmos itself.

## Core Gameplay Loop

The gameplay of Eternal Spiral revolves around a compelling loop of exploration, combat, and progression, designed to be deeply engaging and rewarding.

**Moment-to-Moment:** Players will navigate a 7x7 grid-based battlefield in a Conditional Turn-Based (CTB) combat system. Using a pool of Action Points (AP), they will execute a variety of actions, from basic attacks to powerful techniques and spells. The core of combat is "Patternstrike," a system that rewards strategic positioning and manipulation of enemy formations. By pushing, pulling, and stacking foes, players can unleash devastating combo attacks that hit multiple enemies at once, turning the tide of battle.

**Session-to-Session:** Between battles, players will explore the three realms of the world—the Archetypal Heights, the Psychological Depths, and the Material Foundations. They will interact with a diverse cast of characters, uncover lore, and embark on quests that delve into the game's central conflict. Progression is tied to the "Spiral Lattice," a flexible, grid-based system inspired by Final Fantasy X's Sphere Grid, allowing for deep character customization.

**Long-Term Goals:** The ultimate objective is to heal the Cosmic Wound by reawakening and balancing the 27 Primordial Aspects of the universe. This is achieved by completing major story arcs, defeating powerful bosses tied to the Aspects, and making critical narrative choices. The "Wound Wager" system allows players to risk resources for greater power, with their choices directly impacting the world's stability and leading to multiple possible endings.

## Combat System: The Patternstrike

### 1. Core Rules

The "Patternstrike" system is a tactical, turn-based combat system that takes place on a 7x7 grid. It uses a Conditional Turn-Based (CTB) model, where the order of actions is determined by each unit's Agility stat and the type of actions they perform.

#### Action Points (AP)

*   **Gaining AP:** Each unit (player-controlled and enemy) gains a base of **4 AP** at the start of their turn.
*   **Banking AP:** A unit can end their turn without spending all their AP. Unused AP is "banked" and carried over to their next turn, up to a maximum of **6 banked AP**. This allows for a "big turn" where a unit can have up to 10 AP (4 base + 6 banked).
*   **Spending AP:** AP is the primary resource for all actions.

#### Turn Order (CTB)

*   The turn order is visually represented by a timeline showing the portraits of all units on the battlefield. A unit's position on this timeline is determined primarily by their **Agility** stat.
*   Every action has a "Delay" value associated with it. When a unit performs an action, their next turn is pushed down the timeline by that action's Delay. Simple actions have low Delay, while powerful skills have high Delay. This creates a strategic trade-off between powerful moves and the frequency of turns.

#### Basic Actions

*   **Move:**
    *   **Cost:** 1 AP per tile.
    *   **Effect:** Moves the unit to an adjacent, unoccupied tile. Diagonal movement is not allowed.
*   **Attack:**
    *   **Cost:** 2 AP.
    *   **Effect:** The unit performs a standard weapon attack on an adjacent enemy, dealing damage based on their Attack stat.
    *   **Delay:** 150.
*   **Use Skill:**
    *   **Cost:** Varies by skill (typically 2-5 AP).
    *   **Effect:** The unit performs a special skill, which can range from dealing damage to applying buffs/debuffs or manipulating the grid.
    *   **Delay:** Varies by skill (typically 200-400).

### 2. The "Patternstrike" Mechanic

The heart of the combat system is manipulating enemy positions to create geometric patterns, which can then be targeted by powerful "Patternstrike" combo skills for massive bonus effects.

#### Pushing, Pulling, and Stacking

Players can reposition enemies using specific skills. This is the primary method for setting up Patternstrikes.

*   **Push Skills:** These abilities move an enemy directly away from the user.
    *   *Example Skill: "Shield Shove" (Bulwark Role):* Costs 2 AP. Pushes an adjacent enemy back 2 tiles. If the target hits another unit or an obstacle, it stops and both units take minor damage.
*   **Pull Skills:** These abilities move an enemy directly towards the user.
    *   *Example Skill: "Gravity Well" (Chronovant Role):* Costs 3 AP. Pulls a target enemy within 4 tiles 2 tiles closer to the user.
*   **Stacking:** If an enemy is pushed or pulled onto a tile already occupied by another enemy, they become "Stacked." A single tile can hold up to 3 stacked enemies. Stacked enemies share a single tile, are easier to hit with AoE attacks, and are the primary setup for certain powerful Patternstrikes. Any attack that hits a stacked tile damages all enemies on it.

#### Patternstrike Combos

These are special skills that can only be activated when enemies are arranged in a specific pattern.

1.  **Line Strike:**
    *   **Setup:** Requires at least 3 enemies to be aligned in a single, unbroken horizontal or vertical line.
    *   **Skill Example: "Piercing Gale" (Farshot Role):** Costs 4 AP.
    *   **Effect:** Unleashes a powerful shot that travels down the entire row or column. It hits every enemy in the line for 150% weapon damage and inflicts an "Armor Break" debuff (reduces physical defense) for 2 turns.

2.  **Cluster Burst:**
    *   **Setup:** Requires at least 3 enemies to be Stacked on a single tile.
    *   **Skill Example: "Fulminating Charge" (Ignivox Role):** Costs 5 AP.
    *   **Effect:** Targets a single tile with 3 stacked enemies. The attack deals massive AoE damage in a 3x3 area centered on the target tile. The damage is amplified by 25% for each enemy stacked on the primary target tile.

3.  **Crossfire:**
    *   **Setup:** Requires 4 enemies to be arranged in a '+' shape (one central enemy with four others on adjacent N, S, E, W tiles).
    *   **Skill Example: "Nexus Blitz" (Harmonist Role):** Costs 5 AP.
    *   **Effect:** Hits all 5 enemies in the cross pattern. It deals moderate damage and applies the "Tethered" debuff for 2 turns. While Tethered, any damage dealt to one of the affected enemies is also dealt as a smaller percentage (20%) to the other four.

#### Example of a Patternstrike in Action

1.  **Setup:** A **Bulwark** and a **Farshot** are facing two **Goblins** (A and B) and a **Goblin Archer** (C).
    *   Goblin A is at tile (3,4). Goblin B is at (3,5). Goblin Archer C is at (3,6). They are already in a vertical line.
2.  **Player Turn (Farshot):** The Farshot has 4 AP. They recognize the pattern.
3.  **Execution:** The Farshot uses the **"Piercing Gale"** skill, targeting the line of enemies on column 3.
4.  **Resolution:** The skill's projectile fires down the column, hitting Goblin A, Goblin B, and Goblin Archer C. All three take 150% damage and receive the "Armor Break" debuff.

### 3. Enemy Behavior

#### Basic AI Routine (Melee Grunt)

1.  **Target Acquisition:** At the start of its turn, the enemy scans for the nearest player character.
2.  **Action Decision:**
    *   If a player is in attack range (an adjacent tile), the enemy will spend 2 AP to **Attack**.
    *   If no player is in range, the enemy will spend its AP to **Move** towards the nearest player character.
    *   If the enemy has excess AP after attacking, it will enter a **Defensive Stance** (if it has such an ability) or simply end its turn.

#### Reaction to Grid Manipulation

*   When an enemy is pushed or pulled, its position on the CTB timeline is slightly delayed as it "recovers its footing."
*   More advanced enemies ("Elite" or "Leader" types) have a "Break Formation" behavior. If they start their turn in a valid Patternstrike setup (e.g., in a line with two other enemies), they will prioritize using their Move action to break the pattern before attempting to attack.
*   Enemies will actively avoid moving into visible hazards like traps or burning ground unless they have no other path to a target.

### 4. UI/UX Considerations

#### AP Pool

*   The player's current and banked AP should be clearly visible near their character portrait or health bar.
*   A simple design would be a series of 10 pips or a segmented bar. 4 pips would be brightly colored (current turn's AP), and up to 6 would be a dimmer color (banked AP). When an action is considered, the corresponding number of pips should be highlighted to show the cost.

#### Turn Order Timeline

*   A timeline should be persistently displayed on the top or right side of the screen.
*   It will show the portraits of all units on the field, ordered from top (next to act) to bottom (last to act).
*   When a player highlights a skill, the timeline should dynamically update with a "ghost" portrait of their character, showing where they would re-enter the timeline if they commit to that action. This allows players to visually assess the trade-off between an action's power and its Delay.
*   Hovering over an enemy portrait in the timeline should highlight that enemy on the grid, making it easy to identify targets.


## Player & World

**The Player Character:** Players control a party of heroes, each aligned with one of ten core roles, such as the fiery Ignivox or the steadfast Bulwark. Each character possesses a unique set of abilities and a distinct connection to the game's metaphysical forces. The main character, a "Spiral Seeker," is driven by a desire to restore balance to the world and must navigate the complexities of power, corruption, and sacrifice.

**The World:** The game is set in a panpsychic, animist universe where all of existence is part of a conscious entity known as the All-Soul. This reality is structured around the Eternal Spiral, a cosmic model of creation, and the Synthesis Pantheon, a group of 27 Primordial Aspects that govern the laws of nature. The world is scarred by the Cosmic Wound, a metaphysical cataclysm that has thrown the realms into chaos and given rise to volatile spirits and corrupted landscapes.

## Character Progression: The Spiral Lattice

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

## Moral & Choice Systems

### The "Wound Wager" System

The "Wound Wager" system is a high-risk, high-reward mechanic that allows players to tap into the raw, chaotic power of the Cosmic Wound. It is a direct temptation, offering immense power at the cost of potentially deepening the very crisis the player is trying to solve.

#### Gameplay Loop

1.  **The Altar of Wounds:** In corrupted regions of the world, players will discover "Altars of Wounds." Interacting with one of these altars initiates the wager.

2.  **The Wagered Resource: Aspect Resonance:** The player does not risk a simple currency, but something far more valuable: their connection to a Primordial Aspect. The player chooses one of their awakened Aspects and wagers a significant portion of its "Resonance" (a measure of the player's alignment and power with that Aspect).

3.  **The Benefit: Aspect Infusion:** Upon making the wager, the player receives a powerful, temporary buff called an "Aspect Infusion." This infusion lasts for a set number of battles or until a specific quest objective is completed.
    *   **Effect:** The Aspect Infusion dramatically enhances all skills and stats related to the wagered Aspect. For example, a wager on the **Ignivox** Aspect might grant +100% fire damage, reduce the AP cost of all fire skills by 1, and cause all attacks to apply a burning debuff. This power is often enough to overcome an otherwise insurmountable boss or challenge.

4.  **The Condition of Success:** To "win" the wager, the player must complete a specific, difficult objective while the Aspect Infusion is active. This could be defeating a major boss, clearing a challenging dungeon, or purifying a heavily corrupted area.

5.  **The Consequence of Failure:** If the player fails the objective (e.g., a party wipe, failing to complete the task in time), the wager is lost.
    *   **Mechanical Consequence:** The character suffers a **"Resonance Fracture."** The wagered Aspect's power is permanently weakened, resulting in a significant debuff to all related skills and stats (e.g., -20% fire damage permanently). This can only be healed through a long and difficult side quest.
    *   **Narrative Consequence:** The failed wager causes a **"Wound Surge"** in the local region. The Cosmic Wound's influence deepens, making enemies in that area permanently stronger, altering the landscape, and potentially locking off certain side quests or peaceful resolutions.

### The "Shadows" System

The "Shadows" system is a narrative and mechanical representation of a character's internal struggle with the corrupting influence of their power. It is not a simple good vs. evil mechanic, but a journey of self-acceptance.

#### Gameplay Loop

1.  **Shadow Manifestation:** A character's "Shadow" grows stronger through specific actions that represent a rejection of balance:
    *   **Making "Wound Wagers":** Each wager made, whether won or lost, feeds the Shadow, as it represents a willingness to use chaotic, unbalanced power.
    *   **Using "Toxic Exousia":** Certain powerful but corrupted skills are labeled as "Toxic." Using these skills provides a short-term advantage but directly nourishes the character's Shadow.
    *   **Morally Ambiguous Choices:** Key dialogue and quest choices that favor power over harmony, or ruthlessness over compassion, will contribute to the Shadow's growth.

2.  **The Shadow Battle:** Once a character's Shadow reaches a critical threshold, it will manifest during a moment of crisis or self-doubt (often triggered during a major story beat). This initiates a "Shadow Battle."
    *   **Phase 1: The Dialogue Puzzle:** The battle begins with a confrontation against a spectral, twisted version of the character. The Shadow will voice its grievances—legitimate criticisms based on the player's past actions (e.g., "You sacrificed our allies for power," "You embraced chaos and called it strength"). The player must choose dialogue options that **acknowledge and accept** these truths, rather than denying or fighting them.
    *   **Phase 2: The Combat Encounter:**
        *   If the player successfully navigates the dialogue puzzle, the Shadow is weakened, and the subsequent combat is a manageable, symbolic duel.
        *   If the player chooses arrogant or dismissive dialogue options, the Shadow becomes enraged. The combat encounter is then incredibly difficult, with the Shadow using twisted, overpowered versions of the character's own skills against them.

3.  **The Reward for Integration:** If the player successfully defeats their Shadow (with the outcome weighted heavily by the preceding dialogue), they "integrate" it.
    *   **Mechanical Reward:** The character unlocks a unique and powerful **"Integrated Skill"** that represents their newfound balance (e.g., a fire mage might unlock a skill that deals massive damage but also heals allies in the blast). They also receive a permanent boost to their core stats.
    *   **Narrative Reward:** The character's worldview evolves. They gain new, more insightful dialogue options in future conversations and are able to guide other characters through their own struggles. This is essential for achieving the "good ending."

4.  **The Consequence of Failure:** If the player fails the Shadow Battle (either by losing the combat or repeatedly failing the dialogue), the Shadow is not integrated.
    *   **Mechanical Consequence:** The character is afflicted with the **"Haunted"** status, a permanent debuff. In combat, they have a chance each turn to be "Overwhelmed by Doubt," causing them to lose their turn or even use a skill against an ally.
    *   **Narrative Consequence:** The character becomes more cynical and ruthless. They are locked out of certain empathetic quest resolutions and can no longer achieve the "Balanced Spiral" ending. If all party members fail to integrate their Shadows, it can lead directly to one of the "bad" endings.



## Narrative & Lore

**High-Level Overview:** The story of Eternal Spiral begins long after the "Great Sundering," a catastrophic event where mortals, in their hubris, shattered the cosmic balance. This created the Cosmic Wound, a rift in reality that leaks unstable energy and threatens to unravel all of existence. The player's journey is a quest to heal this wound by seeking out the scattered Aspects and restoring their harmony.

**Main Conflict:** The central conflict is a struggle between balance and chaos, creation and destruction. Players must contend with the "Broken Orders," factions that seek to exploit the Cosmic Wound for their own gain, and confront their own "shadows"—the darker side of their power. The narrative is designed to be morally complex, with no easy answers. Choices made throughout the game will have a tangible impact on the world, leading to different outcomes and shaping the player's legend.

## Monetization & Audience

**Target Audience:** Eternal Spiral is aimed at fans of classic and modern JRPGs, particularly those who appreciate deep, tactical combat systems, rich world-building, and mature, philosophical storytelling. The game will appeal to players who enjoy titles like *Final Fantasy Tactics*, *Darkest Dungeon*, and *Radiant Historia*.

**Monetization Model:** The game will be a premium, single-player experience. Post-launch, we may explore cosmetic DLC or expansions that add new story content, but the core game will be a complete package with no pay-to-win mechanics. We are committed to an ethical monetization strategy that respects the player's investment and time.

## Unique Selling Proposition (USP)

Eternal Spiral stands out from other tactical JRPGs through its unique blend of innovative gameplay and a deeply philosophical world.

*   **Patternstrike Combat:** The "Patternstrike" system offers a fresh take on grid-based tactics, rewarding creative positioning and spatial awareness over brute force.
*   **Metaphysical Depth:** The game's world is built on a rich, cohesive metaphysical framework that informs every aspect of the experience, from the magic system to the narrative.
*   **Moral Complexity:** With the "Wound Wager" system and "Shadow Integration" mechanics, players are constantly faced with meaningful choices that have real consequences, creating a highly personal and replayable adventure.
*   **A World That Breathes:** The game world is dynamic and reactive, with player actions directly influencing the stability of the realms and the evolution of the story.

Eternal Spiral is more than just a game; it's an invitation to explore a world of ideas, to grapple with profound questions, and to forge a legend in a universe where every choice matters.

## The Primordial Aspects

The Synthesis Pantheon consists of 27 Primordial Aspects that govern the fundamental concepts of the universe.

| ID | Name | Domain | Description | Visual Concept |
|---|---|---|---|---|
| 1 | Wellspring | Chaotic Creation | The origin of all potential, Wellspring is the raw, untamed energy of creation. It represents the spark of life and the chaotic emergence of new ideas and forms from the cosmic void. Its influence is felt in moments of sudden inspiration and explosive growth. | A blinding, fractal explosion of multicolored light. |
| 2 | Apex | Dominion | Apex is the embodiment of peak power and realized potential. It governs the principles of leadership, strength, and the natural hierarchies that form within the cosmos. This Aspect drives beings to achieve their ultimate form and assert their influence over their domain. | A radiant, golden crown of light hovering over a mountain peak. |
| 3 | Liberator | Revolutionary Freedom | The Liberator is the force of radical change and the shattering of old forms. It represents the drive for freedom from all constraints, both physical and metaphysical. Its energy fuels revolutions, breaks down stagnant structures, and clears the way for new paradigms. | A pair of shattering chains made of pure, white energy. |
| 4 | Architect | Cosmic Structure | As the cosmic blueprint, the Architect establishes the fundamental laws and patterns that underpin reality. It governs logic, order, and the creation of stable systems. All physical laws and metaphysical constants are expressions of its will. | An infinitely complex, shifting lattice of crystalline blue lines. |
| 5 | Sustainer | Endurance | The Sustainer is the principle of stability, endurance, and persistence. It grants resilience to forms and concepts, allowing them to withstand the forces of chaos and decay. Its presence is felt in ancient mountains, timeless traditions, and unwavering resolve. | A monolithic, unmoving pillar of grey, unadorned stone. |
| 6 | Chronos | Time | Chronos governs the flow of time, from the smallest moment to the grandest cosmic cycle. It is the engine of causality, ensuring that events unfold in a coherent sequence. Its influence dictates the rhythm of life, death, and rebirth. | A vast, spiraling clock face made of sand and starlight. |
| 7 | Nexus | Connection | The Nexus is the force of unity and the interconnectedness of all things. It weaves the disparate threads of the All-Soul into a single, coherent tapestry. It governs empathy, communication, and the sympathetic bonds that tie all of existence together. | A radiant web of silver threads connecting countless points of light. |
| 8 | Harmonizer | Balance | The Harmonizer seeks equilibrium in all things, from the balance of cosmic forces to the inner peace of a single soul. It is the principle of resonance and synergy. Its influence is felt when opposing forces find a state of perfect, dynamic tension. | Two perfectly balanced, interlocking rings of light, one black and one white. |
| 9 | Returner | Consequence | Also known as the arbiter of karma, the Returner ensures that all actions have an equal and opposite reaction. It is the universal law of consequence, governing justice and the cyclical return of energy. Every choice made within the Spiral eventually comes back to its source through this Aspect. | A mirrored vortex that reflects the viewer's own actions. |
| 10 | Potency | Vitality | Potency is the animating force of life and the driver of proliferation. It governs growth, vitality, and the raw energy that fuels all living things. Its presence is felt in lush forests, thriving ecosystems, and the beating heart of every creature. | A pulsing, vibrant green heart entwined with flowering vines. |
| 11 | Passion | Emotion | Passion is the source of all emotion, from the fiercest love to the deepest sorrow. It is the subjective lens through which the All-Soul experiences itself. This Aspect gives meaning and color to existence, driving the actions of sapient beings. | A swirling storm of iridescent, liquid color. |
| 12 | Fury | Conflict | Fury is the embodiment of conflict, struggle, and the will to overcome adversity. It is not inherently evil, but represents the necessary friction that drives evolution and growth. Its energy is present in every battle, every argument, and every struggle for survival. | A roaring bonfire in the shape of a screaming visage. |
| 13 | Nurturer | Compassion | The Nurturer is the principle of care, compassion, and unconditional love. It seeks to heal wounds, soothe pain, and protect the vulnerable. This Aspect is the source of altruism and the deep, instinctual drive to care for others. | A pair of warm, gentle hands cupping a fragile, glowing seedling. |
| 14 | Sentinel | Vigilance | The Sentinel is the eternal guardian, the principle of protection and unwavering vigilance. It is the shield that stands against the encroaching darkness. Its influence is felt in the protective instincts of a parent and the steadfast watch of a city's walls. | A stoic, armored figure with a thousand unblinking eyes. |
| 15 | Dreamer | Imagination | The Dreamer is the source of all imagination, dreams, and the infinite possibilities that lie beyond material reality. It is the realm of 'what could be,' giving rise to art, innovation, and illusion. This Aspect allows the cosmos to envision new versions of itself. | A shimmering, ever-changing mirage of impossible landscapes. |
| 16 | Seeker | Curiosity | The Seeker embodies the insatiable drive for knowledge and understanding. It is the question that sparks a quest and the curiosity that pushes explorers to the edge of the map. This Aspect ensures that the All-Soul is always learning and growing. | A single, inquisitive eye made of swirling stardust, peering into the unknown. |
| 17 | Storyteller | Narrative | The Storyteller weaves the threads of memory and event into coherent narratives. It gives context and meaning to the past, shaping identity and culture. Without this Aspect, existence would be a series of disconnected moments with no overarching purpose. | An ancient, ethereal tome whose pages write themselves with ink of pure light. |
| 18 | Refiner | Purity | The Refiner is the principle of distillation and the quest for essence. It strips away the superfluous to reveal the true, core nature of a thing. Its influence is seen in the purification of metals, the clarification of thought, and the search for truth. | A flawless, clear crystal that refracts a single beam of light into a perfect spectrum. |
| 19 | Pioneer | Exploration | The Pioneer is the spirit of exploration and the courage to venture into the unknown. It is the force that pushes boundaries and discovers new lands, new ideas, and new ways of being. This Aspect represents the forward momentum of the material world. | A single, spectral footprint glowing on untouched soil. |
| 20 | Warrior | Strength | The Warrior embodies physical strength, martial prowess, and the application of force. It is the power to act decisively in the material world. This Aspect governs the body's potential for combat and the will to fight for one's convictions. | A perfectly forged sword, humming with latent power. |
| 21 | Harvester | Endings | The Harvester represents the natural cycle of decay, death, and the end of all things. It is not a malevolent force, but a necessary part of the Spiral that clears away the old to make way for the new. Its domain is the quiet finality of autumn and the gentle release of a final breath. | A silent, obsidian scythe that reaps fields of fading light. |
| 22 | Gardener | Cultivation | The Gardener is the principle of deliberate, thoughtful cultivation. It represents humanity's partnership with nature, guiding growth towards a specific, beneficial outcome. This Aspect is the source of agriculture, animal husbandry, and all forms of careful tending. | A spiraling trellis of wood and vine, bearing glowing, geometric fruit. |
| 23 | Builder | Artifice | The Builder governs the creation of tools, structures, and complex machinery. It is the power of artifice and the intellect's ability to shape the material world to its will. Cities, tools, and all technology are born from this Aspect's influence. | A set of glowing, ethereal tools—a hammer, a gear, and a compass—orbiting each other. |
| 24 | Stillness | Respite | Stillness is the principle of rest, silence, and contemplation. It is the pause between breaths, the silence between notes, and the peace that allows for recovery and reflection. This Aspect provides the necessary respite for the cosmos to integrate its experiences. | A perfectly calm, bottomless pool of dark, still water. |
| 25 | Messenger | Communication | The Messenger facilitates the transfer of information and ideas across the material realm. It governs language, symbols, and the swift movement of thought from one mind to another. Its energy ensures that knowledge is not lost and that communities can coordinate. | A fleeting streak of silver lightning that leaves a trail of glowing glyphs. |
| 26 | Weaver | Interdependence | The Weaver represents the intricate web of fate and the interdependence of all material things. It illustrates how the actions of one entity can have far-reaching consequences for all others. This Aspect is the master of supply chains, ecosystems, and social contracts. | A vast, shimmering spiderweb, where each dewdrop reflects a different part of the world. |
| 27 | Echo | History | Echo is the principle of history and the resonance of past events in the present. It is the memory of the material world, ensuring that the lessons of the past are not forgotten. Its influence is felt in ruins, traditions, and the lingering presence of ancient deeds. | A series of translucent, overlapping ripples spreading outwards from a central point. |

# Eternal Spiral: Three-Act Story Outline

## Act I: The Sundering's Echo

**Inciting Incident:** The story begins in the player character's home, a remote village nestled in a region known for its potent connection to the natural world. This peace is shattered when a "Wound Surge"—a violent manifestation of the Cosmic Wound—erupts nearby. The land twists, spirits turn hostile, and loved ones are either lost or corrupted by the chaotic energy. In the midst of this tragedy, the player character, the "Spiral Seeker," experiences an awakening. They see the flow of Exousia, the life force of the world, and feel the pain of the Wound directly. A mysterious guide, an Echo of a long-dead hero, appears to them, explaining that this event was no accident and that the Seeker is one of the few who can perceive the true nature of the crisis and begin the process of healing.

**Initial Goals:** The Seeker's initial quest is born of desperation: to find a way to reverse the corruption that has blighted their home. This personal mission quickly expands as they learn the scope of the decay. Their primary goal becomes to find and reawaken the first few dormant Primordial Aspects to gain the power and wisdom needed to confront the source of the corruption.

**Early Journey & Locations:**
1.  **The Verdant Scar:** The Seeker's corrupted homeland. Here, they must navigate the twisted flora and fauna to reach the heart of the decay, where they awaken the **Gardener** Aspect, learning their first lessons in cultivation and healing.
2.  **The Sunken City of Ouro:** Ancient ruins from before the Great Sundering. The Seeker explores this drowned city to uncover the history of the Wound, awakening the **Storyteller** Aspect and gaining crucial knowledge about the nature of the Aspects and the Spiral.
3.  **The Forgelands:** A desolate, industrialized region where the land's Exousia is being brutally extracted. Here, the Seeker awakens the **Builder** Aspect and discovers that the Wound Surge that destroyed their home was deliberately triggered.

**Antagonist Introduction:** In the Forgelands, the Seeker confronts the **Order of Pure Force**, one of the three "Broken Orders." This faction, led by a charismatic and ruthless visionary, believes that the Spiral must be shattered completely to be reborn. They are actively exploiting the Wound, seeing its chaotic energy as the ultimate tool of creation. The Seeker realizes they are not just fighting a natural disaster, but a group of zealots with a terrifying, cosmic agenda.

## Act II: The Spiral Unravels

**Raising the Stakes:** The conflict escalates dramatically when the Broken Orders succeed in their next plan: they don't just corrupt an Aspect, they completely shatter one. The destruction of a Primordial Aspect sends a shockwave across all of reality, causing one of the three realms to begin unraveling. The Seeker understands that merely awakening the remaining Aspects is not enough; they must now race against the Broken Orders to protect the very foundations of existence. The quest for healing becomes a desperate war for preservation.

**Journey Through the Realms:**
1.  **The Material Foundations:** The Seeker pursues the **Order of Perfect Form** into a sprawling, ancient city. This faction seeks to use the **Sustainer** Aspect to freeze the city in a state of perfect, unchanging order, creating a "paradise" free from chaos but devoid of life and change. The boss is a colossal, crystalline golem, the physical embodiment of stagnation, that absorbs the life out of its surroundings.
2.  **The Psychological Depths:** To find the elusive **Order of Eternal Flow**, the Seeker must journey into the mindscape of the All-Soul. This realm is a shifting, dreamlike landscape where the Flowists are using the **Dreamer** Aspect to lure countless souls into a collective, blissful illusion, causing their physical bodies to waste away. The primary obstacle here is the introduction of the **"shadows" mechanic.** The Seeker must confront a physical manifestation of their own inner darkness—their pride, fear, and the corrupting influence of the power they've wielded. This is a psychological trial where victory comes not from destruction, but from acceptance and integration.
3.  **The Archetypal Heights:** The Seeker ascends to the realm of pure concepts to stop the Order of Pure Force from seizing the **Wellspring**, the source of all chaotic creation. The boss is the leader of the Forcists, who has partially merged with the raw, untamed power of the Aspect, becoming a being of pure, destructive energy.

## Act III: The Eternal Rebirth

**The Climax:** After journeying through the realms and confronting the Broken Orders, the Seeker finally reaches the heart of the Cosmic Wound. Here, they learn the ultimate truth: the Wound was not caused by mortal hubris alone, but was a self-inflicted injury by the All-Soul, born from its inability to reconcile its own fundamental, contradictory natures—creation and destruction, order and chaos, consciousness and form. The leaders of the three Broken Orders, representing these irreconcilable ideas, are converging at the Wound's heart, seeking to impose their flawed, extremist ideologies upon the entire cosmos. The final confrontation is a multi-phase battle against a monstrous amalgam of the three leaders, a being torn apart by its own conflicting philosophies.

**The Final Wound Wager:** The battle is more than a physical confrontation; it is the final "Wound Wager." The Seeker's cumulative choices throughout the game—their use of toxic Exousia, their mastery over their own shadow, and the balance of the Aspects they've awakened—determine the options available. They must wager the fate of reality itself, using the immense power at the heart of the Wound to bring about the final outcome.

**Potential Endings:**
*   **The Balanced Spiral (Good Ending):** Having achieved inner balance and consistently chosen harmony over power, the Seeker uses their connection to the Aspects to soothe the All-Soul's pain. The Wound is not erased but integrated as a scar—a permanent reminder of the necessity of all parts of the whole, including darkness and chaos. The world is restored to a state of dynamic, evolving equilibrium.
*   **The Tyrant's Spiral (Lawful/Evil Ending):** The Seeker, having favored one of the cosmic Pillars (Force, Form, or Flow) above the others, seizes control. They defeat the Broken Orders only to become a new, singular authority, creating a universe of perfect order, absolute freedom, or transcendent thought, but at the cost of balance. The world is "saved," but it is a stagnant, incomplete version of itself.
*   **The Sundered Spiral (Chaotic/Evil Ending):** Giving in to the Wound's corruption and their own un-integrated shadow, the Seeker embraces the ideology of the Forcists. They use the power of the Wound to shatter the Spiral completely, plunging the universe into a state of perpetual, violent rebirth where nothing stable can ever exist again.
*   **The Silent Spiral (Neutral/Bad Ending):** The Seeker, lacking the conviction or the balanced power to enact a final choice, fails to tip the scales. The conflict at the heart of the Wound tears it open completely, and the All-Soul, unable to resolve its paradox, dissolves into a silent, empty void.

## UI & User Experience

### 1. Combat UI Wireframe

The Combat UI is designed to be clean, informative, and allow for quick tactical decision-making. The player should be able to understand the battlefield state at a glance.

#### Layout

The screen is divided into three main zones: the central grid, a right-hand information panel, and a bottom action bar.

```
+------------------------------------------------+-----------------+
|                                                | Turn Order      |
|                                                | Timeline        |
|                                                | (Vertical)      |
|           7x7 BATTLEFIELD GRID                 | - [Portrait]    |
|                                                | - [Portrait]    |
|                                                | - [Portrait]    |
|                                                | - ...           |
+------------------------------------------------+-----------------+
| Player Character Info & Action Bar             | Target Info     |
+------------------------------------------------+-----------------+
```

*   **Battlefield Grid (Center):** The 7x7 grid where all combat takes place. The player's party is typically on the bottom/left, and enemies are on the top/right.
*   **Turn Order Timeline (Right):** A vertical list showing the sequence of upcoming turns.
*   **Player Panel (Bottom-Left):** A detailed panel for the currently active character.
*   **Target Panel (Bottom-Right):** A panel that displays information about the currently targeted enemy or ally.

#### Player Panel

This panel is the player's command center for the active character.

*   **Character Portrait:** A large, animated portrait of the active character.
*   **Health & Will Bars:** Prominent horizontal bars for Health (HP) and Will (the resource for skills).
*   **AP Meter:** A segmented bar or a series of pips (e.g., 4 bright, 6 dim) clearly showing current and banked Action Points.
*   **Skills List:** A scrollable list or grid of the character's available skills. Each entry displays:
    *   The Skill Name (e.g., "Shield Shove").
    *   The AP Cost (e.g., "2 AP").
    *   A brief description of the effect.

#### Turn Order Timeline

This is a critical element for planning ahead.

*   **Visuals:** A vertical list of character portraits. The unit whose turn is next is at the top. The list scrolls downwards to show future turns.
*   **Dynamic "Ghost" Portrait:** When a player hovers over a skill in their action bar, the timeline provides instant feedback. A semi-transparent "ghost" portrait of their character appears in the timeline, showing exactly where their next turn will be if they use that skill. This visually communicates the "Delay" cost of an action. A more powerful skill will place the ghost further down the list.

#### Action Feedback

Clear feedback is essential for a tactical game.

*   **Movement:** When the "Move" action is selected, all reachable tiles for the current AP are highlighted in a blue overlay.
*   **Targeting:**
    *   Hovering over a valid target with a skill highlights that unit with an outline (e.g., red for an enemy, green for an ally).
    *   For AoE (Area of Effect) skills, the entire area of impact is highlighted on the grid, showing exactly which tiles and units will be affected.
*   **Damage Preview:** When an enemy is targeted with a damaging ability, a small pop-up appears over their health bar showing a preview of the damage they will take. This helps players make informed decisions without needing to do mental math.

### 2. Spiral Lattice UI Wireframe

This screen is designed to feel like a sacred, cosmic map that the player is exploring. The focus is on the beauty of the grid and the clarity of the choices.

#### Layout

The screen is dominated by the Spiral Lattice itself, with supporting information on the periphery.

```
+--------------------------------------+--------------------------+
|                                      | Character Stats Panel    |
|                                      | - Name                   |
|      SPIRAL LATTICE (Main View)      | - Portrait               |
|                                      | - Core Stats (HP, ATK...) |
|                                      | - Unlocked Skills List   |
|                                      |                          |
+--------------------------------------+--------------------------+
| Node Info Panel (Contextual)         | Spiral Essence: [Amount] |
+--------------------------------------+--------------------------+
```

*   **Spiral Lattice (Center):** A vast, visually impressive grid of nodes connected by glowing pathways. The camera can be panned and zoomed by the player. Activated nodes glow brightly, while inactive nodes are dim.
*   **Character Stats Panel (Right):** A persistent panel showing the character's current state.
*   **Node Info Panel (Bottom-Left):** This panel is contextual and only appears when a node is selected.
*   **Spiral Essence Display (Bottom-Right):** A clear, simple display of the player's current SE currency.

#### Node Interaction User Flow

1.  **Exploration:** The player uses the controller or mouse to pan the camera across the grid. They can only navigate along the glowing pathways connected to their already-activated nodes.
2.  **Selection:** The player selects a connected, inactive node. The camera centers on this node, and it begins to pulse gently.
3.  **Information Display:** Upon selection, the **Node Info Panel** at the bottom-left populates with details:
    *   **Node Name:** (e.g., "Greater Might").
    *   **Description:** A clear explanation of its effect (e.g., "Greatly increases Attack Power.").
    *   **Effect:** The specific stat change (e.g., "+8 ATK").
    *   **Cost:** The amount of Spiral Essence required to activate it (e.g., "Cost: 400 SE").
4.  **Activation:** The player is given a clear prompt to "Activate Node" by holding a button.
5.  **Feedback:** Upon activation:
    *   A beautiful visual effect emanates from the node.
    *   The SE cost is deducted from their total.
    *   The node begins to glow brightly, permanently.
    *   Any newly connected pathways light up, revealing the next set of choices.
    *   The Character Stats Panel on the right instantly updates to reflect the new stat increase or unlocked skill.

#### Character Stats Panel

This panel provides an at-a-glance summary of the character's growth.

*   **Header:** Character Name and Portrait.
*   **Core Stats:** A list of all primary stats (Health, Will, Attack, Defense, Agility) with their current values.
*   **Unlocked Skills:** A scrollable list of all skills unlocked from the Lattice. This allows the player to review their character's full ability set without leaving the screen.

#### "Spiral Essence" Display

Located in the bottom-right corner, this is a simple, unobtrusive text element that clearly reads: **"Spiral Essence: 12,500 SE"**. It updates in real-time as the player spends SE on the grid.

