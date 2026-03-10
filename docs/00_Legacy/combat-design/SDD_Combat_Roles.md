# Core Design Document: Role System

## 1. Overview
This document adapts the role system for a turn-based JRPG with grid-based combat, rooted in a panpsychic cosmogony and the Synthesis Pantheon’s metaphysical framework. The game draws inspiration from classic *Final Fantasy* titles, emphasizing narrative depth, tactical gameplay, and a living world where all matter is conscious. The system features ten base roles, each aligned with the **Eternal Spiral**, **Cosmic Wound**, and **27 Primordial Aspects**, using **Sympathetic Magic** (combining **Sympathetic Links** and **Ritual Gestures**) for abilities. Roles are designed for strategic depth, team synergy, and player experimentation on a 7x7 grid.

### Design Goals
- **Balance**: Ensure roles are distinct yet complementary, covering damage, support, defense, control, and utility.
- **Thematic Cohesion**: Root roles in the Synthesis Pantheon, with abilities reflecting Aspect personalities and the panpsychic world.
- **Strategic Depth**: Foster synergy through positioning, terrain bonuses, and Awakening risks, rewarding tactical planning.
- **Prototyping Flexibility**: Keep mechanics modular for iteration (e.g., adjusting Will costs, Awakening chances).

## 2. Base Roles
The ten roles are reimagined to align with the Sympathetic Magic system and Synthesis Pantheon. Each role has a **Primary Aspect** (and sometimes a secondary Aspect), a **Trait** (passive ability tied to an Aspect’s nature), and a **Technique** (active ability using a Sympathetic Link and Ritual Gesture). Roles operate on a 7x7 grid, with abilities featuring **Range**, **AOE**, **Will Cost**, **Awakening Risk**, and **Terrain Bonuses**.

### 2.1 Bladewarden (Melee Damage Dealer)
- **Description**: A resolute warrior channeling the **Warrior (Lower/Force/Transformation)** Aspect, mastering close-combat with spirit-infused blades.
- **Trait**: *Guardian’s Resolve* - Gains +15% attack when below 50% HP, reflecting the Warrior’s courage (inspired by *Steel Resolve*).
- **Technique**: *Guardian’s Clash* - Link: Iron Shield, Gesture: Strike, Will: 4, Effect: Deals 30 damage to one enemy (Range: 2 tiles, Single target), grants +20% defense for 1 turn if hit next turn, Awakening Risk: 8% (spawns noble Warrior Guardian ally or aggressive War Brute enemy), Terrain Bonus: +10 damage in battlefields.
- **Role**: Frontline DPS; thrives in sustained fights, synergizes with healers like Mendicant.
- **Lore**: Bladewardens are protectors bound to the Warrior Aspect, defending the Spiral’s balance with blade and spirit.

### 2.2 Farshot (Ranged Damage Dealer)
- **Description**: A sharpshooter guided by the **Pioneer (Lower/Force/Emergence)** Aspect, exploring the battlefield with precise shots.
- **Trait**: *Trailblazer’s Sight* - +20% accuracy and critical chance at ranges ≥4 tiles, reflecting the Pioneer’s exploration (inspired by *Eagle Eye*).
- **Technique**: *Trailblaze* - Link: Compass Needle, Gesture: Strike, Will: 2, Effect: Deals 20 damage to one enemy (Range: 3 tiles, Single target), grants +2 movement next turn, Awakening Risk: 5% (spawns bold Pioneer Scout ally or reckless Hazard Spirit enemy), Terrain Bonus: +10 damage in uncharted terrain.
- **Role**: Backline DPS; counters distant foes, vulnerable in melee, pairs with controllers like Zonemaster.
- **Lore**: Farshots embody the Pioneer’s adventurous spirit, scouting the Spiral’s frontiers with bow or rifle.

### 2.3 Ignivox (Magical Damage Dealer)
- **Description**: A fiery mage channeling the **Wellspring (Upper/Force/Emergence)** Aspect, unleashing chaotic flame magic.
- **Trait**: *Spark of Creation* - Attacks apply a 10-damage burn over 2 turns, reflecting the Wellspring’s creativity (inspired by *Emberheart*).
- **Technique**: *Spark of Becoming* - Link: Crystal Chalice, Gesture: Strike, Will: 6, Effect: Deals 35 damage in a 3x3 grid (Range: 3 tiles), 20% chance for random status (e.g., stun), Awakening Risk: 12% (spawns Wellspring Sprite ally or Void Spark enemy), Terrain Bonus: +10 damage near springs.
- **Role**: AOE damage; high-risk caster, synergizes with Harmonist or Zonemaster.
- **Lore**: Ignivoxes tap the Wellspring’s boundless potential, risking chaos to wield the Spiral’s primal fire.

### 2.4 Mendicant (Healer)
- **Description**: A restorative mystic aligned with the **Gardener (Lower/Form/Emergence)** Aspect, nurturing allies with life magic.
- **Trait**: *Verdant Grace* - Healing increases by 20% for allies below 30% HP, reflecting the Gardener’s care (inspired by *Grace Under Pressure*).
- **Technique**: *Verdant Embrace* - Link: Sprouting Seed, Gesture: Shield, Will: 2, Effect: Heals 15 HP in a 2x2 grid (Range: 3 tiles), +10% attack for 2 turns, Awakening Risk: 5% (spawns Gardener Sprout ally or Vine Creeper enemy), Terrain Bonus: +10 HP in forests.
- **Role**: Core healer; supports frontline roles like Bladewarden, needs Bulwark protection.
- **Lore**: Mendicants commune with the Gardener, tending the Spiral’s growth to heal the Cosmic Wound.

### 2.5 Bulwark (Defender)
- **Description**: A steadfast guardian embodying the **Sustainer (Upper/Form/Manifestation)** Aspect, shielding allies with spirit barriers.
- **Trait**: *Enduring Aegis* - Reduces frontal damage by 20%, reflecting the Sustainer’s stability (inspired by *Unyielding Stance*).
- **Technique**: *World Aegis* - Link: Oak Heart, Gesture: Shield, Will: 6, Effect: Creates a 3x3 barrier (20 HP, Range: 4 tiles) blocking movement/attacks for 2 turns, Awakening Risk: 10% (spawns Sustainer Tree ally or Vine Warden enemy), Terrain Bonus: +10 HP in forests.
- **Role**: Frontline defense; protects Mendicant or Harmonist, excels in choke points.
- **Lore**: Bulwarks invoke the Sustainer to preserve the Spiral’s harmony, standing firm against chaos.

### 2.6 Shadowfang (Assassin)
- **Description**: A stealthy killer aligned with the **Ravencut (Lower/Flow/Emergence)** Aspect, disrupting foes with cunning strikes.
- **Trait**: *Trickster’s Veil* - Gains stealth (untargetable until next action) after a critical hit, reflecting Ravencut’s guile (inspired by *Night’s Veil*).
- **Technique**: *Pilfer Strike* - Link: Raven Feather, Gesture: Weave, Will: 3, Effect: Deals 20 damage (Range: 2 tiles, Single target), steals a buff or 2 Will, Awakening Risk: 5% (spawns Ravencut Trickster ally or Gossip Wisp enemy), Terrain Bonus: +10 damage in urban terrain.
- **Role**: Precision DPS; targets enemy supports, fragile if exposed, synergizes with Chronovant.
- **Lore**: Shadowfangs channel Ravencut’s trickery, weaving through the Spiral to disrupt the Wound’s agents.

### 2.7 Zonemaster (Controller)
- **Description**: A tactician wielding the **Refiner (Middle/Form/Transformation)** Aspect, controlling areas with precise traps.
- **Trait**: *Purified Ground* - Enemies in controlled zones take +10% damage, reflecting the Refiner’s discernment (inspired by *Terrain Mastery*).
- **Technique**: *Pure Sift* - Link: Alchemical Vial, Gesture: Shield, Will: 5, Effect: Removes all buffs from one enemy (Range: 3 tiles, Single target), deals 15 damage, Awakening Risk: 10% (spawns Refiner Alchemist ally or Critic Shade enemy), Terrain Bonus: +10 damage in purified terrain.
- **Role**: Control; sets up kills for Ignivox or Farshot, thrives with terrain strategy.
- **Lore**: Zonemasters purify the Spiral’s chaos with the Refiner’s clarity, shaping battlefields with precision.

### 2.8 Harmonist (Magical Support)
- **Description**: A mystic amplifying allies via the **Harmonizer (Upper/Flow/Manifestation)** Aspect, balancing spiritual energies.
- **Trait**: *Unity Aura* - Allies within 2 tiles gain +15% magic damage, reflecting the Harmonizer’s balance (inspired by *Resonant Aura*).
- **Technique**: *Unity Weave* - Link: Silk Mandala, Gesture: Weave, Will: 7, Effect: Balances HP in a 3x3 grid (Range: 3 tiles), removes one status effect, Awakening Risk: 10% (spawns Harmonizer Loom ally or Balance Shade enemy), Terrain Bonus: +10% HP in sacred terrain.
- **Role**: Caster support; boosts Ignivox or Zonemaster, needs Bulwark protection.
- **Lore**: Harmonists weave the Spiral’s unity, aligning allies with the Harmonizer to counter the Wound.

### 2.9 Chronovant (Tempo Manipulator)
- **Description**: A time mage channeling the **Returner (Upper/Flow/Transformation)** Aspect, manipulating cycles with wisdom.
- **Trait**: *Cycle’s Insight* - 20% chance for an extra action if an ally is slowed/stunned, reflecting the Returner’s completion (inspired by *Timeflow Sense*).
- **Technique**: *Spiral Return* - Link: Ouroboros Ring, Gesture: Weave, Will: 8, Effect: Revives one ally at 50% HP or deals 40 damage in a 2x2 grid (Range: 3 tiles), Awakening Risk: 15% (spawns Returner Guide ally or Void Pilgrim enemy), Terrain Bonus: +10% HP/damage on cosmic terrain.
- **Role**: Support/control; manipulates turn order, synergizes with Shadowfang or Farshot.
- **Lore**: Chronovants guide the Spiral’s cycles with the Returner’s wisdom, bending time to heal the Wound.

### 2.10 Ravencut (Utility Disruptor)
- **Description**: A cunning thief embodying the **Messenger (Lower/Flow/Emergence)** Aspect, disrupting foes with swift strikes.
- **Trait**: *Swift Courier* - 50% chance to steal 2 Will when attacking, reflecting the Messenger’s connectivity (inspired by *Quick Fingers*).
- **Technique**: *Swift Current* - Link: River Pebble, Gesture: Weave, Will: 2, Effect: Grants +1 movement and +10% evasion to one ally (Range: 4 tiles, Single target), Awakening Risk: 5% (spawns Messenger Wind ally or Rumor Wisp enemy), Terrain Bonus: +1 turn duration near rivers.
- **Role**: Utility; weakens enemies while aiding allies, versatile with Chronovant or Harmonist.
- **Lore**: Ravencuts carry the Messenger’s flow, linking allies and disrupting the Wound’s chaos.

## 3. Design Principles
### 3.1 Role Distribution
- **Damage**: Bladewarden (melee), Farshot (ranged), Ignivox (magical), Shadowfang (precision).
- **Support**: Mendicant (healing), Harmonist (magic boost), Chronovant (tempo), Ravencut (utility).
- **Defense**: Bulwark (protection).
- **Control**: Zonemaster (debuff/control).
- **Purpose**: Covers JRPG needs with a compact roster, enabling varied party builds (e.g., Ignivox + Harmonist for AOE, Shadowfang + Chronovant for burst).

### 3.2 Trait Design
- Traits are passive, tied to Aspects’ personalities (e.g., *Spark of Creation* for Ignivox’s Wellspring chaos).
- Encourage strategic play (e.g., *Trailblazer’s Sight* rewards Farshot’s long-range positioning).
- Avoid overlap (e.g., Bulwark’s *Enduring Aegis* vs. Mendicant’s *Verdant Grace*).

### 3.3 Technique Design
- Techniques use Sympathetic Links and Ritual Gestures, with **Will Costs**, **Awakening Risks**, and **Terrain Bonuses**.
- Designed for grid-based synergy (e.g., Zonemaster’s *Pure Sift* sets up Ignivox’s *Spark of Becoming*).
- Balance power with risk (e.g., Chronovant’s *Spiral Return* is potent but risks high Awakening).

### 3.4 Synergy and Counterplay
- **Synergies**: Harmonist boosts Ignivox’s AOE; Chronovant accelerates Shadowfang’s burst; Bulwark shields Mendicant’s healing.
- **Counters**: Shadowfang threatens Mendicant; Farshot punishes Zonemaster’s static debuffs; Ignivox struggles vs. mobile Ravencut.
- **Goal**: Promote tactical team-building without hard counters, rewarding grid positioning and Aspect combos.

## 4. Gameplay Integration
### Grid-Based Combat (7x7 Grid)
- **Positioning**: Techniques have Range (2-5 tiles) and AOE (single, line, 3x3). High ground adds +1 Range; terrain boosts matching Links (e.g., Mendicant’s *Verdant Embrace* in forests).
- **Turn Structure**: Players choose to move (up to 3 tiles), cast a technique (Link + Gesture), attack physically, or use an item. The UI shows effects, Will costs, and Awakening risks.
- **Awakening Dynamics**: Awakened spirits spawn on the grid, acting as allies or enemies (e.g., Wellspring Sprite aids, Void Spark attacks AOE).
- **Terrain Strategy**: Maps feature forests, rivers, shrines, etc., with bonuses for Aspect-aligned Links (e.g., +10% effect for Gardener near forests).

### Narrative and Character Arcs
- **Aspect-Driven Stories**: Each role aligns with an Aspect, shaping their arc (e.g., Ignivox’s Wellspring optimism vs. chaotic shadow, Chronovant’s Returner wisdom vs. detachment).
- **Spiral Choices**: Technique use affects the Cosmic Wound. Overusing Force Aspects (e.g., Ignivox’s Wellspring) widens the Wound, spawning chaos; balancing Aspects heals it.
- **Quests**: Roles undertake Aspect-specific missions (e.g., Mendicant aids Gardener to heal a forest), earning Links or story progression.

### JRPG Aesthetics
- **Visuals**: Cinematic technique animations (e.g., spiraling flames for *Spark of Becoming*, blooming vines for *Verdant Embrace*). Awakening events shake the grid (e.g., a tree uproots as a Sustainer spirit).
- **Audio**: Environmental soundscapes (e.g., spirit whispers) and Aspect-specific sounds (e.g., Wellspring’s chime, Warrior’s clash).
- **UI**: Tarot-inspired icons for Aspects, with spiral motifs, evoking *Final Fantasy*’s emotional depth.

## 5. Prototyping Considerations
- **Iteration Points**:
  - Adjust Will costs (e.g., *Spiral Return*’s 8 Will to 7 or 9).
  - Tweak Awakening risks (e.g., *Spark of Becoming*’s 12% to 10%).
  - Experiment with AOE sizes (e.g., *World Aegis*’s 3x3 to 2x2).
- **Testing Focus**:
  - Ensure role distinction (e.g., Bladewarden’s melee vs. Shadowfang’s stealth).
  - Verify synergy (e.g., Harmonist + Ignivox for AOE dominance).
  - Check for overpowered combos (e.g., Chronovant + Shadowfang burst).
- **Expansion Potential**:
  - Add roles (e.g., Plaguemonger using Recycler Aspect for DoT).
  - Create hybrids (e.g., Ignivox + Shadowfang for a Wellspring-Ravencut assassin).
  - Tie roles to factions (e.g., Mendicants from a Gardener cult).

## 6. Next Steps
- **Mechanic Refinement**: Finalize Will costs, ranges, and Awakening risks for ~20-30-turn battles.
- **Additional Techniques**: Develop 2-3 techniques per role (e.g., Ignivox’s fire shield using Wellspring).
- **Hybrid Exploration**: Prototype Ignivox + Zonemaster for a fiery controller.
- **Lore Integration**: Flesh out factions tied to Aspects (e.g., Chronovants as Returner priests).
- **Narrative Hooks**: Define how role choices shape the Cosmic Wound (e.g., Ignivox’s chaos vs. Harmonist’s balance).

## 7. Appendix: Role Inspirations
- **Synthesis Pantheon**: Roles draw from Aspects (e.g., Wellspring for Ignivox, Gardener for Mendicant), reflecting the Eternal Spiral.
- **Metaphysical Roots**: Animism (spirit-filled world), panpsychism (conscious matter), Tarot (archetypes), Kabbalah (Three Pillars).
- **JRPG Influence**: *Final Fantasy Tactics* for grid tactics, *Final Fantasy VI* for narrative depth, *Final Fantasy IX* for vibrant aesthetics.
