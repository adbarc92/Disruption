Core Design Document: Strategy Game Role System
1. Overview
This document outlines the core role system for a fantasy strategy game rooted in mythological and tactical gameplay. The system prioritizes a compact, versatile roster of ten base roles, each with unique traits (passive abilities) and techniques (active abilities) to support strategic depth, team synergy, and player experimentation. The roles cover essential archetypes—damage, support, defense, control, and utility—forming a foundation for prototyping and future expansion.
Design Goals

Balance: Ensure roles are distinct yet complementary, covering core gameplay needs (damage, healing, control, etc.).
Thematic Cohesion: Ground roles in fantasy lore with evocative names and mechanics (e.g., Ignivox as a fiery mage).
Strategic Depth: Encourage synergy through traits and techniques that reward positioning, timing, and team composition.
Prototyping Flexibility: Design mechanics as modular for easy iteration (e.g., tweaking damage values or adding effects).

2. Base Roles
The initial roster consists of ten roles, selected to represent core archetypes while leaving room for hybrids or additions. Each role has a unique trait (passive) and technique (active ability) to define its identity and playstyle.
2.1 Bladewarden (Melee Damage Dealer)

Description: A stalwart melee fighter excelling in close-quarters combat with versatile weapon mastery.
Trait: Steel Resolve - Gains bonus damage when below 50% health, reflecting tenacity.
Technique: Whirlwind Slash - Spins to strike all adjacent enemies, dealing moderate damage with a chance to bleed (DoT).
Role: Frontline damage; thrives in sustained fights, synergizes with healers.

2.2 Farshot (Ranged Damage Dealer)

Description: A precise marksman delivering long-range damage with bows or guns.
Trait: Eagle Eye - Increased accuracy and critical hit chance at longer ranges.
Technique: Piercing Shot - Fires a high-damage arrow that passes through the first target to hit one behind.
Role: Backline DPS; counters clustered foes, vulnerable in melee.

2.3 Ignivox (Magical Damage Dealer)

Description: A fiery mage wielding destructive flame magic.
Trait: Emberheart - Attacks leave a burning effect dealing minor damage over 2 turns.
Technique: Flameburst - Launches an explosive fireball, dealing AoE damage centered on a target.
Role: AoE damage; high-risk, high-reward caster, pairs well with control roles.

2.4 Mendicant (Healer)

Description: A restorative caster using divine or natural magic to heal and cleanse.
Trait: Grace Under Pressure - Healing potency increases when allies are critically low on health.
Technique: Radiant Mend - Restores health to a single ally and removes one debuff.
Role: Core support; clutch healer, needs protection from damage roles.

2.5 Bulwark (Defender)

Description: A resilient protector who shields allies from harm.
Trait: Unyielding Stance - Reduces damage taken from frontal attacks by 20%.
Technique: Shield Wall - Raises a temporary barrier absorbing damage for allies in a row for 1 turn.
Role: Frontline defense; safeguards squishy roles, excels in choke points.

2.6 Shadowfang (Assassin)

Description: A stealthy killer striking high-value targets from the shadows.
Trait: Night’s Veil - Gains stealth after a critical hit, becoming untargetable until next action.
Technique: Backstab - Deals massive damage to a single target if attacking from behind or stealthed.
Role: Precision DPS; counters enemy leaders, fragile if exposed.

2.7 Zonemaster (Controller)

Description: A tactician denying areas with traps or hazards.
Trait: Terrain Mastery - Enemies in controlled zones take 10% more damage from all sources.
Technique: Snare Trap - Places a trap that immobilizes the first enemy to enter for 1 turn.
Role: Battlefield control; sets up kills, synergizes with AoE damage.

2.8 Harmonist (Magical Support)

Description: A mystic amplifying allies’ magical potency.
Trait: Resonant Aura - Nearby allies gain a 15% boost to magic damage output.
Technique: Amplify Chord - Doubles the next magical ability’s effect (e.g., damage, range) for an ally.
Role: Caster support; boosts roles like Ignivox, needs positioning care.

2.9 Chronovant (Tempo Manipulator)

Description: A time mage altering battle pacing with speed control.
Trait: Timeflow Sense - 20% chance to act twice in a turn if an ally is slowed or stunned.
Technique: Haste Pulse - Speeds up an ally, granting an immediate extra action this turn.
Role: Support/control; manipulates turn order, thrives with coordinated teams.

2.10 Ravencut (Utility Disruptor)

Description: A cunning thief disrupting enemies by stealing resources.
Trait: Quick Fingers - 50% chance to steal an additional resource (e.g., mana, item) when using theft.
Technique: Pilfer Strike - Attacks for light damage and steals a random buff or resource.
Role: Utility; weakens enemies while aiding allies, versatile but low damage.

3. Design Principles
3.1 Role Distribution

Damage: Bladewarden (melee), Farshot (ranged), Ignivox (magical), Shadowfang (precision).
Support: Mendicant (healing), Harmonist (magic boost), Chronovant (tempo).
Defense: Bulwark (protection).
Control: Zonemaster (area denial).
Utility: Ravencut (disruption).
Purpose: Covers core needs for a small roster, ensuring varied team compositions.

3.2 Trait Design

Traits are passive to reduce complexity while adding depth (e.g., Night’s Veil rewards crits for Shadowfang).
Each trait ties to the role’s identity and encourages specific strategies (e.g., Eagle Eye incentivizes long-range positioning for Farshot).
Avoid overlap (e.g., Ignivox’s Emberheart differs from Zonemaster’s Terrain Mastery).

3.3 Technique Design

Techniques are active, single-use abilities with clear effects (e.g., Flameburst for AoE, Haste Pulse for tempo).
Designed for synergy (e.g., Zonemaster’s Snare Trap sets up Ignivox’s Flameburst).
Balance high-impact abilities with risk (e.g., Shadowfang’s Backstab needs positioning).

3.4 Synergy and Counterplay

Synergies: Harmonist boosts Ignivox; Chronovant accelerates Shadowfang; Bulwark protects Mendicant.
Counters: Shadowfang threatens Mendicant; Farshot punishes Zonemaster’s static traps; Ignivox struggles vs. mobile foes like Ravencut.
Goal: Foster team-building and tactical choices without hard counters.

4. Prototyping Considerations

Iteration Points:
Adjust trait numbers (e.g., Unyielding Stance’s 20% reduction to 15% or 25%).
Add technique cooldowns or costs (e.g., Flameburst requires mana or a 2-turn recharge).
Experiment with status effects (e.g., Whirlwind Slash’s bleed could stack).


Testing Focus:
Ensure roles feel distinct (e.g., Bladewarden vs. Shadowfang in melee).
Verify synergy viability (e.g., Chronovant + Farshot for rapid sniping).
Check for overpowered combos (e.g., Harmonist + Ignivox overwhelming AoE).


Expansion Potential:
Add debuff roles (e.g., Plaguemonger for DoT).
Create hybrids (e.g., Ignivox + Shadowfang for a fiery assassin).
Introduce factions to tie roles to lore (e.g., Ignivox from a volcanic cult).



5. Next Steps

Mechanic Refinement: Define exact numbers (damage, percentages, ranges) and test balance.
Additional Techniques: Develop 2-3 techniques per role for variety (e.g., Ignivox could have a fire shield).
Hybrid Exploration: Prototype combinations like Farshot + Zonemaster for a sniper-trapper.
Lore Integration: Build a world where roles reflect factions or mythic orders (e.g., Chronovants as time priests).

6. Appendix: Role Inspirations

Fantasy Lore: Bladewarden (knights), Ignivox (fire sorcerers), Shadowfang (rogues), Mendicant (clerics).
Mythology: Chronovant (time deities like Chronos), Harmonist (muses), Ravencut (trickster gods).
Game Design: Draws from tactical RPGs (e.g., Final Fantasy Tactics, Fire Emblem) for role clarity and synergy.
