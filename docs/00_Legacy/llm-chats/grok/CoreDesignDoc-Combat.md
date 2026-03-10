Spiral Weave Combat Design Document
1. Game Overview
A turn-based JRPG with grid-based combat (7x7 grid), inspired by classic Final Fantasy titles, emphasizing tactical strategy, narrative depth, and a panpsychic, animist world. The combat system, Spiral Weave Combat, integrates a Sympathetic Magic system, Exousia (vital force), and the Synthesis Pantheon within the Eternal Spiral cosmology.

Core Inspirations:
Final Fantasy X: Conditional Turn-Based (CTB) system for turn order.
Darkest Dungeon: Positioning-based mechanics.
Radiant Historia: Grid manipulation and enemy stacking.
Star Renegades: 3D tactical positioning in Unreal Engine.
Paper Mario: Reactive Action Commands.
Clair Obscur: Expedition 33: Action Point (AP) balance and reactive systems.



2. Metaphysical Framework
2.1 Cosmogony

Eternal Spiral: The universe is the All-Soul, a conscious entity evolving through recursive cycles.
Cosmic Wound: A fracture leaking unstable Exousia, spawning volatile spirits.
Exousia: Electric vital force defined by:
Amplitude: Sapience (+10% spell potency).
Frequency: Vitality (-1 Will cost for high vitality).
Rotation: Alignment with Principalities (+15% for aligned spells).
Sex: Sine (male, single-target), Cosine (female, AOE).


Exousia Variations: Differs by sapience, vitality, race, sex, and land. Toxic Exousia risks corruption (+5% Awakening Risk).

2.2 Synthesis Pantheon

27 Primordial Aspects: Combine Three Realms (Upper/Archetypal, Middle/Psychological, Lower/Material), Three Pillars (Force/Yang, Form/Yin, Flow/Tao), and Three Phases (Emergence, Manifestation, Transformation).
Principalities: Eight key Aspects (e.g., Wellspring, Potency, Liberator) define Exousia alignments.
Wellspring: Chaotic creation, Primal spells.
Potency: Life proliferation, Blooming spells.
Gardener: Nurturing growth, Blooming healing.
Liberator: Freedom, Imbuing disruption.
Sustainer: Endurance, Shaping barriers.



2.3 Sympathetic Magic System

Mechanics: Spells use Sympathetic Links (items, e.g., Crystal Chalice) and Ritual Gestures (Strike/Force, Shield/Form, Weave/Flow).
Exousia Forms:
Primal: Elemental (fire, lightning).
Imbuing: Soul constructs.
Shaping: Body/matter reshaping.
Blooming: Life proliferation (healing, buffs).


Will Resource: Spells cost Will (20/character/battle, regenerates via rest):
Lower Realm: 2–4 Will
Middle Realm: 4–6 Will
Upper Realm: 6–8 Will


Awakening Risk: 5–15% chance to spawn Aspect spirits (allies/enemies). Toxic Exousia adds +5%.
Terrain Bonuses: Land Exousia boosts matching spells (+20% potency, e.g., Blooming in forests. Toxic terrain imposes -10%.

3. Combat Mechanics: Spiral Weave Combat
3.1 Core Structure

Conditional Turn-Based (CTB) (FFX):
Turn order list shows upcoming actions for all units (heroes, enemies, spirits).
Turns determined by Agility and Exousia Frequency (high vitality reduces delays).
Actions have Rank (1–5, affecting delay):
Rank 1: Basic attack, minimal delay.
Rank 5: Upper Realm spell, significant delay.


Party swaps cost 2 AP**, Rank 2 action.


Action Points (AP) (Expedition 33):
Base 4 AP/turn, bankable up to 2 for next turn.
Costs:
Basic Attack/Defend: 1 AP
Technique: 2–3 AP
Spells: 1–4 AP (Lower: 2, Upper: 4)


High Exousia Frequency: +1 AP.


Will Synergy: Spells cost Will + AP, balanced by Frequency (-1 Will) and Amplitude (+10% potency).

3. 7x7 Grid Positioning

Layout (Star Renegades, Radiant Historia):
Party starts in rows 6–7, enemies in rows 1–3, neutral rows 4–5.
Height Advantage: Elevated tiles grant +1 Range, +10% damage.
Terrain Exousia: Matching spells gain +10% potency; toxic terrain penalizes -10%.


Darkest Dungeon Influence:
Roles have preferred positions:
Bladewarden, Bulwark: Front (rows 5–7).
Farshot, Ignivox: Mid-row (3–5).
Mendicant, Harmonist: Back (1–3).


Positioning affects efficacy (e.g., Ignivox’s AOE loses 20% potency in front row).
Enemies push/pull units to disrupt formations.


Radiant Historia Influence:
Grid manipulation (push/pull, stack enemies) enables AOE combos.
Stacked enemies take full damage from single-target attacks.


Star Renegades 3D:
3D grid in Unreal Engine with cover (partial: 25% damage reduction, full: 50%) and line-of-sight (LoS) blocking ranged attacks.
Movement: 1 AP/tile (diagonal: 1.5 AP). Roles like Ravencut reduce cost (0.5 AP).



3.3 Reactive Systems

Paper Mario Influence:
Action Commands: QTEs for attacks/spells boost damage (+20%) or reduce Will (-1).
Spells require Ritual Gesture combos (Strike/Shield/Weave). Failures reduce potency (-10%).


Expedition 33 Influence:
Dodge: 1 AP, roll to adjacent tile (QTE refunds AP).
Parry: 1 AP, reduces damage by 75%, fills Stagger Gauge.
Counter: 2 AP, Role-specific (e.g., Shadowfang steals).
Staggered enemies: +50% damage, lose next action (2 turns).
Turn indicators show enemy actions (e.g., “Wraith: Chaos Flare”).



3.4 Awakening Spirits

Mechanics: 5–15% spawn chance per spell, +5% for toxic Exousia or failed Action Commands.
Turn Order:
Ally spirits act after summoner, boosting next action (+10% potency).
Enemy spirits have high Agility, acting early.


Grid Behaviors:
Wellspring Sprite (1x1): Diagonal moves, burning tiles (10 damage/turn).
Liberator Chaos Wraith (1x1): Teleports, pulls targets.
Sustainer Golem (2x2): Immobile, AOE Shaping pulses (50 damage, 3x3).
Gardener Sprout (1x1): Grows 1x2 vines, blocking tiles.



3.5 Role System

10 Roles with Traits (passive) and Techniques (active spells):
Bladewarden: Shaping, Iron Form (defensive boost).
Farshot: Primal, Trailblaze (damage + movement).
Ignivox: Primal, Spark of Becoming (AOE damage).
Mendicant: Blooming, Vital Bloom (AOE healing).
Bulwark: Shaping, World Aegis (barrier).
Shadowfang: Imbuing, Pilfer Strike (damage + steal).
Zonemaster: Imbuing, Pure Sift (debuff + damage).
Harmonist: Blooming, Unity Weave (HP balance).
Chronovant: Primal, Spiral Return (revive/damage).
Ravencut: Blooming, Swift Current (mobility).


Waveform Modifiers:
Amplitude: +10% potency.
Frequency: +1 AP or -1 Will.
Rotation: +15% for Principality-aligned actions.
Sex: Sine (single-target), Cosine (AOE).


Synergies: E.g., Harmonist boosts Ignivox’s Primal (+10% potency); Bulwark protects Mendicant.

4. Enemy Classes and Compositions
4.1 Enemy Classes

Wellspring Wraith (Magical DPS, Wellspring):
Primal AOE (Chaos Flare, 100 damage, 3x3), pushes (Disruptive Pulse).
HP: 500, High Agility, High Amplitude (+15% potency).
Grid: Mid-rows (3–5), diagonal moves.


Potency Stalker (Melee DPS, Potency):
Blooming single-target (Vine Lash, 80 damage, 20 HP drain), pulls (Thorn Snare).
HP: 400, Very High Agility, High Frequency (-1 Will).
Grid: Front rows (5–7), ignores cover.


Gardener Husk (Tank/Support, Gardener):
Blooming AOE heal (Vital Sprout, 50 HP), barrier (Bark Shield).
HP: 800, Low Agility, immune to push/pull.
Grid: Front rows (1–3).


Liberator Phantom (Controller, Liberator):
Imbuing debuff (Soul Siphon, 2 Will drain), Stagger (Phantom Bind).
HP: 600, Moderate Agility, High Rotation (+15% potency).
Grid: Mid-rows (3–5).


Sustainer Monolith (Tank, Sustainer):
Shaping barrier (Iron Bastion, 50% reduction), push (Quake Strike).
HP: 1000, Very Low Agility, immune to Stagger.
Grid: 2x2, front rows (1–2).



4.2 Compositions

Forest Ambush (Potency Terrain, +10% Blooming):
2x Potency Stalkers, 1x Wellspring Wraith, 1x Gardener Husk.
Tactics: Stalkers disrupt backline, Wraith casts AOE, Husk heals/protects.
Awakening: Wraith risks Wellspring Sprite (1x1, burning tiles).


Wound Rift (Toxic Terrain, -10% potency):
1x Sustainer Monolith, 1x Liberator Phantom, 2x Wellspring Wraiths.
Tactics: Monolith tanks, Phantom debuffs, Wraiths spam AOE.
Awakening: Phantom risks Liberator Chaos Wraith (1x1, teleports/pulls).



5. Visual and Audio Aesthetics

Visuals (Unreal Engine):
Exousia as sine/cosine waves (blue/pink). Primal bursts, Blooming vines, Shaping metals.
Principality-colored enemies (e.g., Wraith: red, Husk: green). Toxic terrain flickers static.
Tarot-inspired UI for Action Commands (e.g., Wellspring’s “Star”).


Dynamic Camera:
Over-the-shoulder for active character, cinematic sweeps for targeting (e.g., 3x3 AOE zones) and Techniques (e.g., Ignivox’s Spark arcs).


Audio:
Waveform hums (high pitch for high Frequency). Aspect chants (e.g., Husk’s melody).
Cosmic Wound’s dissonant static, intensifying with Awakening.



6. Strategic Depth

Tactical Goals:
Balance AP, Will, and positioning to maximize damage, minimize Awakening Risk.
Grid manipulation (stacking, terrain bonuses) rewards planning.
Reactive systems (QTEs, dodges, counters) ensure engagement.


Narrative Integration:
Toxic Exousia boosts Agility (+10%) but risks corruption (-10% HP/turn).
Purifying land Exousia grants global bonuses (+5% potency).


Balance:
High-AP/Will actions (Upper Realm spells) are high-risk, high-reward.
Roles counter enemy types (e.g., Ravencut vs. tanks, Zonemaster vs. swarms).



7. Future Considerations

Progression: Separate system (TBD, e.g., Sphere Grid-like).
Bosses: Larger grid presence (3x3), multi-turn combos, unique Awakening triggers.
Awakening Balance: Ally spirits controllable but weaker vs. unpredictable enemies.
Camera: Potential limited manual control (zoom/rotate) for accessibility.
