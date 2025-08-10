# **Roles**

# Primitive Roles

## Elemental

### Luminarch (Photomancer)
- **Primary Function**: Damage/Support
- **Description**: Master of light magic; blinds, illuminates, or sears foes.
- **Strategic Use**: Counters stealth, hybrid utility.
- **Notes**: None

### Windrider
TBD

### Hydrosage (Aquamancer)
- **Primary Function**: Control/Support
- **Description**: Commands water magic; torrents, mists, or ice for control and healing.
- **Strategic Use**: Versatile caster, crowd control.
- **Notes**: None

### Geovant (Terramancer)
- **Primary Function**: Control/Defense
- **Description**: Shapes earth; barriers, boulders, or quakes to disrupt foes.
- **Strategic Use**: Fortifies positions, area control.
- **Notes**: None

### Ignivox (Pyromancer)
- **Primary Function**: Damage
- **Description**: Wields fire magic; incinerates or explodes foes.
- **Strategic Use**: High-damage, reckless caster.
- **Notes**: None

### Hemaphile (Blood Manipulator)
TBD

**Crimson Bolt**
- **Action Type**: Action
- **MP Cost**: 1
- **Range**: Any enemy position
- **Target**: Single enemy
- **Effect**: Deal 90% Pierce damage (blood projectile)
- **Burst Gauge**: +8 (Aggressive: Chain Fighter)

## Damage

### Shadowfang (Assassin)
- **Primary Function**: Damage
- **Description**: Stealthy killer with lethal single-target strikes.
- **Strategic Use**: Precision DPS, counters leaders.
- **Notes**: None

**Heart Piercer**
- **Action Type**: Action
- **MP Cost**: 2
- **Range**: 2 tiles forward
- **Effect**: Move forward 1 tile, deal 120% Pierce damage to single target
- **Burst Gauge**: +10 (Aggressive: Chain Fighter)
- **Notes**: Can target through allies

### Bladewarden (Warrior)
- **Primary Function**: Damage
- **Description**: Melee fighter with versatile close-quarters mastery.
- **Strategic Use**: Frontline, adaptable.
- **Notes**: None

**Pommel Strike**
- **Action Type**: Action
- **MP Cost**: 1
- **Range**: Adjacent enemy
- **Effect**: Deal 70% Blunt damage, 50% chance to apply Dazed (cannot use abilities for 1 turn)
- **Status Applied**: Dazed (chance)
- **Burst Gauge**: +8 (Technical: Status infliction)

**True Strike**
- **Action Type**: Action
- **MP Cost**: 2
- **Range**: Any enemy position
- **Effect**: Lunge forward to target (ignore intervening units), deal 130% Pierce damage, cannot be dodged
- **Positioning**: Move to adjacent tile of target
- **Burst Gauge**: +10 (Aggressive: Chain Fighter)

**Raging Cyclone**
- **Action Type**: Action
- **MP Cost**: 4
- **Range**: Front enemy column
- **Effect**: Strike 5 times at 70% Physical damage each, 40% chance per strike to inflict Bleed
- **Status Applied**: Bleed (chance)
- **Burst Gauge**: +20 (Technical: Multi-target)

**Unrequited Frenzy**
- **Action Type**: Bonus Action
- **MP Cost**: 2
- **Range**: Self
- **Effect**: Gain physical attack buff equal to (Missing HP% + 2% per 5% Bleed effect active)
- **Status Applied**: Rage (variable strength)
- **Burst Gauge**: +15 (Aggressive: Berserker)

### Stancebreaker (Monk)
- **Primary Function**: Utility/Control
- **Description**: Shifts stances; inflicts status effects (stun, bleed).
- **Strategic Use**: Debuff fighter, controls enemies.
- **Notes**: None

### Ravencut (Thief)
- **Primary Function**: Utility
- **Description**: Pilfers items, resources, or buffs from enemies.
- **Strategic Use**: Resource denial, disruption.
- **Notes**: None

### Farshot (Marksman)
- **Primary Function**: Damage
- **Description**: Delivers precise long-range damage.
- **Strategic Use**: Ranged DPS, weak close-up.
- **Notes**: None

### Skylancer (Dragoon)
- **Primary Function**: Damage
- **Description**: Leaps with polearms to strike distant foes.
- **Strategic Use**: Mobile striker, counters backline.
- **Notes**: None

### Veilstalker (Ninja)
- **Primary Function**: Damage/Utility
- **Description**: Vanishes, becoming untargetable before striking.
- **Strategic Use**: Evasive assassin, fragile.
- **Notes**: None

## Utility

### Gridreaver (Sweeper)
- **Primary Function**: Utility
- **Description**: Strikes rows/columns with sweeping attacks.
- **Strategic Use**: Moves enemies around, excels vs clusters.
- **Notes**: Originally a Damage class

**Shove**
- **Action Type**: Bonus Action
- **MP Cost**: 1
- **Range**: Adjacent enemy
- **Effect**: Push enemy backward 1 tile, no damage
- **Positioning**: Knockback
- **Burst Gauge**: +8 (Technical: Repositioning)

**Wide Swing**
- **Action Type**: Action
- **MP Cost**: 2
- **Range**: Front enemy row
- **Effect**: Strike all enemies in front row with 85% Slash damage
- **Burst Gauge**: +15 (Technical: Multi-target)

### Chronovant (Time Mage)
- **Primary Function**: Support/Control
- **Description**: Manipulates time; hastens allies, slows enemies.
- **Strategic Use**: Tempo control, fragile.
- **Notes**: None

### Harmonist (Resonator)
- **Primary Function**: Support
- **Description**: Amplifies magical potency for self/allies.
- **Strategic Use**: Magic support, boosts casters.
- **Notes**: None

### Ironskin (Tank)
- **Primary Function**: Defense
- **Description**: Draws aggro, intercepts attacks with resilience.
- **Strategic Use**: Protector, safeguards allies.
- **Notes**: None

### Bulwark (Fortifier)
- **Primary Function**: Defense/Support
- **Description**: Bolsters defenses with shields or wards for self/allies.
- **Strategic Use**: Defensive support, endurance.
- **Notes**: None

### Dancemaster (Choreographer)
- **Primary Function**: Support
- **Description**: Enhances evasion with graceful movements for self/allies.
- **Strategic Use**: Evasion support, counters hitters.
- **Notes**: None

### Mendicant (Healer)
- **Primary Function**: Support
- **Description**: Restores health and cures ailments with magic.
- **Strategic Use**: Core support, vulnerable.
- **Notes**: None

### Zonemaster (Controller)
- **Primary Function**: Control
- **Description**: Denies areas with traps, barriers, or hazards.
- **Strategic Use**: Battlefield control, splits foes.
- **Notes**: None

### Warcrier (Strike-leader)
- **Primary Function**: Support/Damage
- **Description**: Boosts attack power with rallying cries or aura.
- **Strategic Use**: Offensive support, physical boost.
- **Notes**: None

### Gapthreader
- Defensebreaker

## Specialist

### Spellmirror (Red Mage)
- **Primary Function**: Utility/Support
- **Description**: Absorbs and reuses enemy abilities adaptively.
- **Strategic Use**: Counter specialist, vs magic.
- **Notes**: None

### Metamorph (Transformer)
- **Primary Function**: Utility
- **Description**: Shifts forms (beast, elemental) to adapt mid-battle.
- **Strategic Use**: Versatile, complex.
- **Notes**: None

**Autophagia**
- **Action Type**: Action
- **MP Cost**: 3
- **Range**: Self
- **Effect**: Heal 30% max HP, apply Bleed (20% max HP over 3 turns), gain Bloodlust (+50% damage on offensive techniques) for 3 turns
- **Status Applied**: Bleed (Self), Bloodlust (Self)
- **Burst Gauge**: +15 (Defensive: Survivor - dropping below 50% health)

**Razor Step**
- **Action Type**: Movement (Enhanced)
- **MP Cost**: 1
- **Range**: Self
- **Effect**: Movement actions this turn can move up to 2 tiles in any direction, gain +10% Evasion for 2 turns
- **Burst Gauge**: +8 (Technical: Efficiency Expert)

Severance Symphony (Progressive Multi-Part Technique)

**Embedded Razors** (Stanza 1)
- **Action Type**: Action
- **MP Cost**: 2
- **Range**: Self
- **Effect**: Apply Razor Skin (enemies taking damage when attacking Chiranjivi) for 4 turns, self-inflict Bleed (20% over 1 turn)
- **Status Applied**: Razor Skin (Self), Bleed (Self)
- **Burst Gauge**: +10 (Technical: Combo Master)
- **Prerequisite**: None

**Hands of Knives** (Stanza 2)
- **Action Type**: Action
- **MP Cost**: 3
- **Range**: Adjacent enemy
- **Effect**: Leap to target, perform 2 attacks (4 if Enraged), each 80% Slash damage, self-inflict Bleed (30% over 1 turn)
- **Status Applied**: Bleed (Self)
- **Burst Gauge**: +15 (Aggressive: Chain Fighter)
- **Prerequisite**: Embedded Razors active

**Distant Reaper** (Stanza 3)
- **Action Type**: Action
- **MP Cost**: 4
- **Range**: Column + Front enemy row
- **Effect**: Strike all enemies in user's column, then all enemies in front row (or second row if front empty), 90% Slash damage each, self-inflict Bleed (40% over 1 turn)
- **Status Applied**: Bleed (Self)
- **Burst Gauge**: +20 (Technical: Multi-target ability)
- **Prerequisite**: Hands of Knives used this combat

**Maiden of Flesh** (Stanza 4 - Burst Mode Only)
- **Action Type**: Ultimate (Burst Mode)
- **MP Cost**: All remaining
- **Range**: Single enemy
- **Effect**: Leap to target, deal 300% Special (Necrotic) damage, heal self to 100% HP, remove all debuffs from self
- **Status Applied**: Full Heal (Self), Cleanse (Self)
- **Prerequisite**: Distant Reaper used this combat, Burst Mode active

Broken Symphony (Alternative Multi-Part Technique)

**Marrow Coating** (Stanza 1)
- **Action Type**: Bonus Action
- **MP Cost**: 2
- **Range**: Self
- **Effect**: Gain Bone Armor (30% Physical damage reduction) for 4 turns
- **Status Applied**: Bone Armor
- **Burst Gauge**: +10 (Defensive: Guardian)

**Bone Knuckles** (Stanza 2)
- **Action Type**: Action
- **MP Cost**: 3
- **Range**: Adjacent enemy
- **Effect**: Leap forward, perform 2 attacks with +20% damage, 60% chance to apply Sunder on each hit, self-inflict Weakness (40% physical damage) for 2 turns
- **Status Applied**: Sunder (Enemy), Weakness (Self)
- **Burst Gauge**: +15 (Aggressive: Chain Fighter)
- **Prerequisite**: Marrow Coating active

**Meteor Hammer** (Stanza 3)
- **Action Type**: Action
- **MP Cost**: 4
- **Range**: Back enemy row
- **Effect**: Leap into air, strike all back row enemies with +50% damage, knock back 1 tile if possible
- **Positioning**: Knockback
- **Burst Gauge**: +20 (Technical: Multi-target)
- **Prerequisite**: Bone Knuckles used this combat

**Knight of Blood** (Stanza 4 - Transformation)
- **Action Type**: Action (Concentration)
- **MP Cost**: 5
- **Range**: Self
- **Effect**: Transform - gain Bone Plate (+90% Physical Defense, +50% damage), apply stacking Bleed (15% per turn active) for 2 turns after transformation ends, gain Hemophilia (healing reduced by 50%) while active and 2 turns after
- **Duration**: Concentration (max 5 turns)
- **Status Applied**: Bone Plate, Hemophilia, Bleed (delayed)
- **Burst Gauge**: +25 (Technical: Efficiency Expert)
- **Prerequisite**: Meteor Hammer used this combat

### Synergist (Coordinator)
- **Primary Function**: Support
- **Description**: Links turns with allies for joint attacks or buffs.
- **Strategic Use**: Combo enabler, team-reliant.
- **Notes**: None

**Gout of Flame** (Ignivox+Bladewarden)
- **Action Type**: Action
- **MP Cost**: 3
- **Range**: 2 adjacent tiles
- **Effect**: Slash in burning arc, deal 100% Fire damage to 2 targets, weapon gains Fire Enhancement (next 3 attacks deal additional Fire damage)
- **Status Applied**: Fire Enhancement (Self)
- **Damage Type**: Fire
- **Burst Gauge**: +12 (Technical: Multi-target)

**Luminous Tines** (Luminarch+Bladewarden)
- **Action Type**: Action
- **MP Cost**: 3
- **Range**: Single enemy
- **Effect**: Overhead Lightning strike, 120% Lightning damage, weapon gains Lightning Enhancement (next 3 attacks deal additional Lightning damage and may chain)
- **Status Applied**: Lightning Enhancement (Self)
- **Damage Type**: Lightning
- **Burst Gauge**: +12 (Aggressive: Chain Fighter)

**Frozen Thrust** (Hydrosage+Bladewarden)
- **Action Type**: Action
- **MP Cost**: 3
- **Range**: Single enemy
- **Effect**: Ice-enhanced thrust, 110% Ice damage, 40% chance to apply Frozen (cannot move for 2 turns), weapon gains Ice Enhancement
- **Status Applied**: Ice Enhancement (Self), Frozen (chance)
- **Damage Type**: Ice
- **Burst Gauge**: +12 (Technical: Status infliction)

**Northern Gale** (Windrider+Bladewarden)
- **Action Type**: Action
- **MP Cost**: 2
- **Range**: Single enemy
- **Effect**: Wind-enhanced upward strike, 80% Wind damage, force enemy to move up 1 tile (toward back row)
- **Positioning**: Forced movement
- **Damage Type**: Wind
- **Burst Gauge**: +10 (Technical: Repositioning)

**Southern Breeze** (Windrider+Bladewarden)
- **Action Type**: Action
- **MP Cost**: 2
- **Range**: Single enemy
- **Effect**: Wind-enhanced downward strike, 80% Wind damage, force enemy to move down 1 tile (toward front row)
- **Positioning**: Forced movement
- **Damage Type**: Wind
- **Burst Gauge**: +10 (Technical: Repositioning)

### Gearmonger (Improviser)
- **Primary Function**: Utility
- **Description**: Merges tech and ingenuity; crafts traps or gadgets.
- **Strategic Use**: Wildcard, resource-dependent.
- **Notes**: None

### Chainweaver (Chainer)
- **Primary Function**: Support/Damage
- **Description**: Sets up combos that amplify damage when followed up.
- **Strategic Use**: Setup specialist, synergy-focused.
- **Notes**: None

### Omnigard (All-rounder)
- **Primary Function**: Utility/Damage
- **Description**: Balanced fighter effective in any row.
- **Strategic Use**: Jack-of-all-trades, no standout.
- **Notes**: None

### Crescender (Finisher)
- **Primary Function**: Damage
- **Description**: Caps combos with massive climactic strikes.
- **Strategic Use**: Burst damage, setup-reliant.
- **Notes**: None

### Stormbringer (Nuker)
- **Primary Function**: Damage
- **Description**: Unleashes devastating AoE attacks on clustered foes.
- **Strategic Use**: Crowd clearer, high-risk.
- **Notes**: None

# Higher Order (Hybrid) Roles

### Breaker (Bladewarden+Gapthreader)

**Flat Swing**
- **Action Type**: Action
- **MP Cost**: 2
- **Range**: Single enemy
- **Effect**: Broadside strike with flat of blade, 90% Blunt damage, apply Defense Break (-30% all defenses for 3 turns)
- **Status Applied**: Defense Break
- **Burst Gauge**: +12 (Technical: Status infliction)

### Huntsman (Marksman+Controller)
- **Primary Function**: Control/Damage
- **Description**: Tracks/pins foes with ranged attacks and snares.
- **Strategic Use**: Hybrid control/DPS, isolates.
- **Notes**: None

### Sniper (Marksman+Assassin)
- **Primary Function**: Damage
- **Description**: Lethal long-range precision strikes on key targets.
- **Strategic Use**: Elite killer, vulnerable exposed.
- **Notes**: None

### Eclipseblade (Shadowfang+Luminarch)
- **Primary Function**: Damage/Utility
- **Description**: Stealthy assassin with light magic; blinds and kills.
- **Strategic Use**: Burst with utility, vs stealth.
- **Notes**: None

### Tidalreaver (Hydrosage+Skylancer)
- **Primary Function**: Damage/Control
- **Description**: Leaping warrior with water magic; sweeps or scatters.
- **Strategic Use**: Mobile AoE, repositions.
- **Notes**: None

### Pyrechain (Ignivox+Chainweaver)
- **Primary Function**: Damage/Support
- **Description**: Fiery mage igniting combos with lingering flames.
- **Strategic Use**: Setup/Damage, synergy-focused.
- **Notes**: None

### Stonewatcher (Geovant+Bulwark)
- **Primary Function**: Defense/Control
- **Description**: Earthen defender raising rocky shields and barriers.
- **Strategic Use**: Defensive control, locks areas.
- **Notes**: None

### Tempestshot (Farshot+Stormbringer)
- **Primary Function**: Damage
- **Description**: Ranged devastator with explosive volleys over areas.
- **Strategic Use**: Long-range AoE, softens clusters.
- **Notes**: None

### Veilweaver (Veilstalker+Chainweaver)
- **Primary Function**: Utility/Support
- **Description**: Ninja vanishing to set combo traps for allies.
- **Strategic Use**: Stealth/setup, trap-focused.
- **Notes**: None

### Chronoshield (Chronovant+Ironskin)
- **Primary Function**: Defense/Control
- **Description**: Time-bending tank slowing foes while absorbing hits.
- **Strategic Use**: Protective control, stalls.
- **Notes**: None

### Harmonicblade (Harmonist+Bladewarden)
- **Primary Function**: Support/Damage
- **Description**: Warrior boosting spellpower with resonant strikes.
- **Strategic Use**: Melee support, caster synergy.
- **Notes**: None

### Soulshot (Soulreaver+Sniper)
- **Primary Function**: Damage/Utility
- **Description**: Ranged predator draining vitality with precise shots.
- **Strategic Use**: Ranged sustain, vs durable.
- **Notes**: None

### Gravicaller (Graviton+Beastcaller)
- **Primary Function**: Control/Utility
- **Description**: Summons gravity-bound beasts to cluster enemies.
- **Strategic Use**: Crowd control/summon, AoE setup.
- **Notes**: None

### Runedancer (Runescribe+Dancemaster)
- **Primary Function**: Support/Utility
- **Description**: Inscribes runes mid-dance for buffs or hazards.
- **Strategic Use**: Evasion/setup, subtle influence.
- **Notes**: None

### Bloodstorm (Bloodpact+Stormbringer)
- **Primary Function**: Damage
- **Description**: Berserker sacrificing health for blood-fueled AoE.
- **Strategic Use**: High-risk AoE, desperate play.
- **Notes**: None

### Windthief (Windrider+Ravencut)
- **Primary Function**: Utility
- **Description**: Swift rogue stealing resources with aerial agility.
- **Strategic Use**: Mobility/disruption, harassment.
- **Notes**: None

### Metamorphunt (Metamorph+Huntsman)
- **Primary Function**: Control/Utility
- **Description**: Shape-shifter tracking and pinning prey with traps.
- **Strategic Use**: Versatile control, pursuit.
- **Notes**: None

### Steelskin (Metamorph+Bulwark)

**Steelheart**
- **Action Type**: Bonus Action
- **MP Cost**: 1
- **Range**: Self
- **Effect**: Gain Bleed Resistance and Fortify (+20% Physical Defense) for 4 turns
- **Status Applied**: Bleed Resistance, Fortify
- **Burst Gauge**: +8 (Defensive: Protector)

**Crystalline Bones**
- **Action Type**: Action
- **MP Cost**: 2
- **Range**: Self
- **Effect**: Move forward 1 tile, gain Fortify (+20% Physical Defense) for 3 turns, apply Mark to self (enemies more likely to target)
- **Burst Gauge**: +12 (Defensive: Guardian - taking damage while in front row)

### Stanceshot (Stancebreaker+Farshot)
- **Primary Function**: Damage/Utility
- **Description**: Marksman shifting stances for status-inflicting shots.
- **Strategic Use**: Ranged debuff, softens targets.
- **Notes**: None

### Synergwind (Synergist+Windrider)
- **Primary Function**: Support/Damage
- **Description**: Swift coordinator linking aerial joint attacks.
- **Strategic Use**: Mobile synergy, speed-focused.
- **Notes**: None

### Mendispell (Mendicant+Spellmirror)
- **Primary Function**: Support/Utility
- **Description**: Healer reflecting spells while mending wounds.
- **Strategic Use**: Support/counter, vs casters.
- **Notes**: None

### Wargrid (Warcrier+Gridreaver)
- **Primary Function**: Support/Damage
- **Description**: Rallying leader sweeping rows with boosted attacks.
- **Strategic Use**: Offensive AoE/support, morale.
- **Notes**: None

### TimeWarden (Bladewarden + Chronovant)
- **Primary Function**: Utility/Damage

**Stance of Pitch**
- **Action Type**: Bonus Action
- **MP Cost**: 2
- **Range**: Self
- **Effect**: Enter prepared stance, next attack deals minimum 200% damage
- **Status Applied**: Perfect Stance (Self)
- **Burst Gauge**: +10 (Technical: Efficiency Expert)

**Raging Blossom** (Burst Mode Enhanced)
- **Action Type**: Action (Enhanced in Burst)
- **MP Cost**: 5 (3 in Burst Mode)
- **Range**: Single enemy
- **Effect**: Series of obliterating strikes - 6 attacks at 60% damage each, final strike deals 150% damage
- **Burst Gauge**: +25 (Aggressive: Chain Fighter)

# Final Roles
TBD
