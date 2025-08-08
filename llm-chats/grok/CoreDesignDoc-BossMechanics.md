Boss Mechanics Design Document
1. Overview
Boss battles in the Spiral Weave Combat system are climactic encounters that test players’ mastery of the 7x7 grid, Conditional Turn-Based (CTB) mechanics, Action Points (AP), Sympathetic Magic, and Exousia management. Bosses are tied to the Synthesis Pantheon and Cosmic Wound, embodying Principalities (e.g., Wellspring, Potency) and driving narrative stakes through Awakening risks and Exousia choices. These encounters feature unique grid effects, multi-phase progression, and dynamic turn order behaviors, balanced for tactical depth and JRPG spectacle.
2. Core Design Principles

Tactical Challenge: Bosses demand strategic use of grid positioning, AP/Will management, and reactive systems (dodge/parry/counters).
Narrative Resonance: Bosses reflect the Cosmic Wound’s chaos or Principality alignments, with toxic Exousia use impacting outcomes (e.g., corruption vs. purification).
Cinematic Engagement: Dynamic camera (over-the-shoulder to sweeping cinematic shots) and Tarot-inspired visuals enhance spectacle.
Inspirations:
Final Fantasy X: Multi-phase CTB with shifting turn order.
Darkest Dungeon: Positioning-dependent weaknesses.
Radiant Historia: Grid manipulation for combos.
Star Renegades: 3D grid effects and environmental interactions.
Paper Mario: QTE-based Action Commands for interactivity.
Expedition 33: AP economy and reactive counter mechanics.



3. Boss Mechanics
3.1 Grid Presence and Effects

Larger Grid Footprint:
Bosses occupy 2x2 to 3x3 tiles, limiting player movement and enabling wide-reaching AOEs.
Example: A Sustainer-aligned boss (e.g., Iron Sovereign) occupies a 3x3 space in rows 1–3, immovable but vulnerable to flanking.


Unique Grid Effects:
Principality Zones: Bosses project a 3x3–5x5 aura tied to their Principality, altering terrain:
Wellspring: Chaotic terrain (+20% Primal potency, +10% Awakening Risk).
Potency: Verdant terrain (+20% Blooming potency, +10% healing).
Liberator: Unstable terrain (randomly shifts units 1 tile/turn).


Environmental Hazards: Bosses spawn dynamic obstacles:
Toxic Rifts: 1x1 tiles dealing 20 damage/turn, spawned by toxic Exousia use.
Elemental Vents: 2x2 tiles emitting Primal bursts (50 damage, 3x3 AOE).


Grid Manipulation: Bosses reshape the grid:
Push/pull entire rows/columns (e.g., Liberator boss shifts row 4 back).
Create barriers (e.g., Sustainer boss spawns 1x2 walls, blocking LoS).




Cover Interaction: Bosses ignore partial cover (25% reduction) but are affected by full cover (50% reduction), encouraging players to use terrain strategically.

3.2 Multi-Phase Fights

Phase Transitions:
Bosses have 2–4 phases, triggered by HP thresholds (e.g., 75%, 50%, 25%) or narrative events (e.g., purifying a terrain tile).
Each phase shifts mechanics, turn order, and grid effects:
Phase 1: Defensive stance, high damage reduction (e.g., 50% via Shaping).
Phase 2: Aggressive, multi-turn combos (e.g., AOE + single-target).
Phase 3: Desperate, high Awakening Risk (+15%) and summons.
Phase 4 (optional): Overdrive, massive AOE with QTE counters.


Transitions trigger cinematic camera sweeps, highlighting boss transformations (e.g., Wellspring boss erupting into chaotic flames).


Phase-Specific Mechanics:
Weakness Exposure: Each phase reveals a vulnerability (e.g., Potency boss weak to Imbuing in Phase 2 after Blooming shield breaks).
Turn Order Shifts: Phases alter boss Agility (e.g., faster in Phase 3) or add minions to the CTB list.
Grid Resets: New phases may clear hazards or spawn new ones (e.g., Sustainer boss collapses barriers, opens new paths).



3.3 Multi-Turn Combos

Combo Sequences:
Bosses execute 2–3 action combos across consecutive turns, telegraphed via CTB turn indicators (e.g., “Iron Sovereign: Quake Barrage”).
Example: Liberator boss combo:
Turn 1: Soul Siphon (drains 3 Will, 80 Imbuing damage).
Turn 2: Chaos Pull (pulls all units to row 4).
Turn 3: Freedom Burst (5x5 AOE, 120 damage).


Players counter via parries (fill Stagger Gauge) or dodges (QTE for AP refund).


Stagger Opportunities:
Combos leave bosses vulnerable to Stagger (50% gauge fill per parry, 100% stops combo).
Staggered bosses take +50% damage and lose 1–2 turns, enabling combos (e.g., Ignivox’s Spark of Becoming).



3.4 Awakening Triggers

Enhanced Awakening Risk:
Bosses increase baseline Awakening Risk to 10–20% per spell, +10% in toxic terrain or after combo finishers.
Triggered spirits are tied to the boss’s Principality:
Wellspring: Chaos Sprite (1x1, AOE fire, diagonal moves).
Potency: Verdant Bloom (1x2, AOE healing, roots targets).
Sustainer: Stone Sentinel (2x2, AOE Shaping pulse, immobile).




Unique Behaviors:
Spirits act immediately after spawning, disrupting CTB order.
Example: Liberator Chaos Wraith teleports, pulling a unit to its tile.
Ally spirits (e.g., Gardener Sprout) are controllable but weaker (50% stats), boosting summoner’s next action (+10% potency).



3.5 Exousia and Narrative Integration

Toxic Exousia Mechanics:
Bosses may force toxic Exousia use (e.g., Wellspring boss corrupts terrain, boosting player damage by 20% but adding +10% Awakening Risk).
Players choosing toxic Exousia gain +10% Agility but risk ally corruption (-10% HP/turn).


Purification Choices:
Players can spend AP (3) and Will (6) to purify a terrain tile, removing toxic penalties and granting +10% potency for matching spells.
Purification may trigger phase transitions or weaken boss defenses (e.g., Potency boss loses Blooming shield).


Narrative Stakes:
Bosses embody Cosmic Wound dilemmas (e.g., Wellspring boss spreads chaos, Liberator boss seeks destructive freedom).
Defeating bosses via purified Exousia advances story arcs (e.g., healing the Wound); toxic use risks escalation (e.g., spawning more rifts).



4. Sample Boss: Iron Sovereign (Sustainer-Aligned)

Role: Tank/DPS Hybrid, Shaping specialist.
Grid Presence: 3x3 tiles, front rows (1–3), immovable.
Stats:
HP: 5000 (4 phases: 1250/phase).
Agility: Low (Rank 4–5 actions).
Exousia: High Amplitude (+20% potency), Low Frequency (+2 Will cost).


Abilities:
Titanic Bastion (Rank 4, 4 AP): 50% damage reduction, 2x2 barrier spawns (blocks LoS).
Earthrend Quake (Rank 3, 3 AP): 5x5 AOE Shaping (150 damage), pushes units back 2 tiles.
Core Pulse (Rank 5, 5 Will): 3x3 AOE (100 damage), +15% Awakening Risk (spawns Stone Sentinel).
Fortified Core (Passive): Immune to Stagger until Phase 3.


Phases:
Phase 1 (100–75%): Defensive, Titanic Bastion every 2 turns, high cover use.
Phase 2 (75–50%): Summons 2x Wellspring Wraiths, Earthrend Quake focus.
Phase 3 (50–25%): Loses Stagger immunity, uses Core Pulse, terrain becomes toxic.
Phase 4 (25–0%): Overdrive, double Earthrend Quake combo, +20% Awakening Risk.


Grid Effects:
Projects 5x5 Sustainer aura (+20% Shaping potency, +10% damage reduction for enemies).
Spawns 1x2 barriers, forcing players to flank or destroy them (200 HP each).


Tactics:
Players use Zonemaster’s Pure Sift to debuff barriers, Ignivox’s Spark of Becoming for AOE, and Ravencut’s Swift Current to flank.
Dodge Earthrend Quake (QTE for AP refund) or parry to fill Stagger Gauge in Phase 3.
Purify toxic terrain to weaken Core Pulse potency.


Camera: Over-the-shoulder on active character, sweeps to show 5x5 AOE or barriers during Titanic Bastion.
Narrative: The Iron Sovereign guards a Cosmic Wound rift, embodying Sustainer’s unyielding stability. Purification heals the rift; toxic Exousia strengthens it.

5. Sample Boss: Verdant Tyrant (Potency-Aligned)

Role: Support/DPS Hybrid, Blooming specialist.
Grid Presence: 2x2 tiles, mid-rows (3–5), mobile (1 tile/turn).
Stats:
HP: 4000 (3 phases: 1333/phase).
Agility: Moderate (Rank 2–3 actions).
Exousia: High Frequency (-1 Will cost), Moderate Amplitude (+10% potency).


Abilities:
Overgrowth Surge (Rank 3, 3 AP, 4 Will): 3x3 AOE Blooming (80 damage, heals allies 50 HP).
Thorn Cascade (Rank 2, 2 AP): Pulls 2 targets to adjacent tiles, applies Rooted (immobile, 1 turn).
Verdant Bloom (Passive): Spawns 1x1 vine patches (10 damage/turn, block movement).


Phases:
Phase 1 (100–66%): Defensive, Overgrowth Surge heals allies, spawns 2x Potency Stalkers.
Phase 2 (66–33%): Aggressive, Thorn Cascade every turn, vine patches spread.
Phase 3 (33–0%): Summons Gardener Sprout (1x2, AOE healing), +15% Awakening Risk.


Grid Effects:
Projects 4x4 Potency aura (+20% Blooming potency, +10% healing).
Vine patches grow 1x2 over 2 turns, limiting player positioning.


Tactics:
Players use Bladewarden’s Iron Form to tank Overgrowth Surge, Harmonist’s Unity Weave to balance HP, and Farshot’s Trailblaze to clear vines.
Stagger in Phase 2 via parries to stop Thorn Cascade combos.
Purify terrain to reduce vine spread and Awakening Risk.


Camera: Cinematic sweeps highlight vine growth and 3x3 AOE during Overgrowth Surge.
Narrative: The Verdant Tyrant embodies Potency’s unchecked growth, threatening to consume the land. Purification restores balance; toxic Exousia accelerates overgrowth.

6. Strategic Depth

Grid Tactics: Larger boss footprints and hazards force repositioning (e.g., Ravencut flanks Iron Sovereign’s barriers).
AP/Will Management: High-cost combos (e.g., Core Pulse) require banking AP and conserving Will.
Reactive Play: QTEs for dodges/counters mitigate AOE damage; parries enable Stagger combos.
Awakening Balance: High Risk in later phases demands cautious spell use or purification.
Narrative Choices: Toxic Exousia boosts damage but risks corruption; purification weakens bosses but costs resources.

7. Aesthetic Integration

Visuals (Unreal Engine):
Bosses pulse with Principality-colored Exousia (e.g., Iron Sovereign: metallic silver, Verdant Tyrant: vibrant green).
Phase transitions trigger dramatic effects (e.g., Sovereign’s barriers shatter, Tyrant’s vines erupt).
Tarot-inspired UI for QTEs (e.g., Sustainer’s “Tower” icon).


Dynamic Camera:
Over-the-shoulder for player actions, sweeping to show boss AOEs, hazards, or phase changes.
Example: Zooms to Iron Sovereign’s 3x3 form during Earthrend Quake, pans to vine patches for Verdant Tyrant.


Audio:
Boss-specific waveform hums (low for Sovereign, high for Tyrant).
Cosmic Wound dissonance intensifies in toxic phases; Principality chants play during summons.



8. Balance Considerations

Difficulty Scaling: HP, action Ranks, and Awakening Risks increase with story progression.
Counterplay: Weaknesses (e.g., Sovereign’s Phase 3 Stagger) reward specific Roles (e.g., Zonemaster).
Player Agency: Purification vs. toxic Exousia offers trade-offs (power vs. risk).
Accessibility: QTEs have adjustable timing windows; camera sweeps are automated for immersion.
