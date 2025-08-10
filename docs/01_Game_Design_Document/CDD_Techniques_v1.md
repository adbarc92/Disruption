# Refactored Technique Specifications for Combat System

## System Integration Framework

All techniques are refactored to work within the established combat system architecture:
- **Grid System**: 3x3 ally grid + 3x3 enemy grid positioning
- **Resource Management**: MP costs, Equipment Charges, Burst Gauge generation
- **Status Effects**: DOT, stat modifications, control effects, complex effects
- **Action Economy**: Movement + Action + Bonus Action structure
- **Damage Types**: Physical (Slash/Pierce/Blunt), Elemental (Fire/Ice/Lightning/Earth/Wind/Water), Magical (Arcane/Divine/Occult), Special (Psychic/Necrotic/Radiant)

---

## Chiranjivi - Blood Manipulation Specialist

### Self-Modification Techniques

### Advanced Techniques

**Crimson Union**
- **Action Type**: Action (Concentration)
- **MP Cost**: 3
- **Range**: Single enemy + all allies
- **Effect**: Link target enemy - 50% of damage to enemy is distributed among all allies, concentration
- **Status Applied**: Damage Link
- **Burst Gauge**: +12 (Support: Buffer)

---

---

## Euphen - Shadow Archer

### Positioning and Stealth

**Dead Angle**
- **Action Type**: Action
- **MP Cost**: 3
- **Equipment Charge**: 1 (Shadow Cloak)
- **Range**: Any position behind enemy lines
- **Effect**: Teleport behind enemies, next attack ignores all damage mitigation and armor
- **Positioning**: Teleport
- **Status Applied**: Phantom Strike (Self, 1 attack)
- **Burst Gauge**: +12 (Technical: Opportunist)

**Dancing Shadows**
- **Action Type**: Bonus Action
- **MP Cost**: 2
- **Range**: All allies
- **Effect**: Extend Nature to allies, +15% Evasion for 3 turns
- **Status Applied**: Shadow Blessing
- **Burst Gauge**: +10 (Support: Buffer)

**Fleet Foot**
- **Action Type**: Bonus Action
- **MP Cost**: 2
- **Range**: All allies
- **Effect**: +2 turn order positions for 3 turns
- **Status Applied**: Haste
- **Burst Gauge**: +10 (Support: Buffer)

### Archery Techniques

**Guiding Shot**
- **Action Type**: Action
- **MP Cost**: 2
- **Range**: Single enemy
- **Effect**: Mark target, next ally attack against marked enemy deals +100% damage and cannot miss
- **Status Applied**: Hunter's Mark
- **Burst Gauge**: +12 (Support: Ally Support)

**Hunter's Instinct**
- **Action Type**: Bonus Action
- **MP Cost**: 3
- **Range**: All allies
- **Effect**: +15% Critical Rate for 4 turns
- **Status Applied**: Keen Eye
- **Burst Gauge**: +12 (Support: Buffer)

**Manifest Fire**
- **Action Type**: Action
- **MP Cost**: 4
- **Range**: Single enemy + 1-tile radius
- **Effect**: Explosive arrow - 120% Fire damage to primary target, 60% Fire damage to adjacent enemies
- **Damage Type**: Fire
- **Burst Gauge**: +15 (Technical: Multi-target)

### Trap Techniques

**X-Trap**
- **Action Type**: Action
- **MP Cost**: 2
- **Equipment Charge**: 1 (Trap Kit)
- **Range**: Empty tile
- **Effect**: Place trap in X pattern (target tile + 4 diagonals), triggers when enemy moves through, deals 100% Pierce damage and applies Root
- **Status Applied**: Root (when triggered)
- **Duration**: Until triggered or 5 turns
- **Burst Gauge**: +10 (Technical: Combo Master)

**Plus-Trap**
- **Action Type**: Action
- **MP Cost**: 2
- **Equipment Charge**: 1 (Trap Kit)
- **Range**: Empty tile
- **Effect**: Place trap in + pattern (target tile + 4 cardinals), triggers when enemy moves through, deals 80% Lightning damage and applies Dazed
- **Damage Type**: Lightning
- **Status Applied**: Dazed (when triggered)
- **Duration**: Until triggered or 5 turns
- **Burst Gauge**: +10 (Technical: Combo Master)

### Resource Manipulation

**Fate's Accomplice**
- **Action Type**: Action
- **MP Cost**: 3
- **Range**: One enemy, one ally
- **Effect**: Steal 20% max MP from enemy (percentage-based), restore equal amount to ally with lowest MP
- **Resource Effect**: MP transfer
- **Burst Gauge**: +12 (Support: Ally Support)

**Physiker's Quarrel**
- **Action Type**: Action
- **MP Cost**: 2
- **Range**: Single enemy
- **Effect**: Next healing attempt on target is redirected to Euphen instead, effect lasts 2 turns
- **Status Applied**: Heal Theft
- **Burst Gauge**: +10 (Technical: Opportunist)

### Ultimate Techniques

**Slayer's Curse**
- **Action Type**: Action
- **MP Cost**: 4
- **Range**: Self + Single enemy
- **Effect**: Self - cannot use defensive techniques, +50% offensive damage for 3 turns; Enemy - Speed reduced by 50%, all attacks targeting this enemy are unblockable and undodgeable for 3 turns
- **Status Applied**: Bloodlust (Self), Death Mark (Enemy)
- **Burst Gauge**: +20 (Aggressive: Berserker + Technical: Status infliction)

**Vanishing Point** (Burst Mode Enhanced)
- **Action Type**: Action
- **MP Cost**: 5 (2 in Burst Mode)
- **Range**: Self
- **Effect**: Become untargetable for 2 turns, all attacks deal +50% damage, can move through enemies
- **Status Applied**: Phantom Form
- **Burst Gauge**: +15 (Technical: Efficiency Expert)

---

## Phaidros - Earth Guardian

### Defensive Core

**Ironflesh**
- **Action Type**: Bonus Action
- **MP Cost**: 2
- **Range**: Single ally
- **Effect**: Target gains 50% Physical damage reduction for 3 turns
- **Status Applied**: Iron Skin
- **Burst Gauge**: +12 (Support: Ally Support)

**The Wall**
- **Action Type**: Action
- **MP Cost**: 4
- **Equipment Charge**: 1 (Earth Gauntlets)
- **Range**: Front-most column
- **Effect**: Create destructible wall (HP = 75% of Phaidros's HP) along entire front column
- **Positioning**: Creates obstacles
- **Duration**: Until destroyed
- **Burst Gauge**: +15 (Defensive: Guardian)

**Ready Stance**
- **Action Type**: Bonus Action
- **MP Cost**: 1
- **Range**: Self
- **Effect**: Next instance of damage reduced by 50% (physical) or 25% (magical), negates forced movement
- **Status Applied**: Braced
- **Burst Gauge**: +8 (Defensive: Guardian)

### Taunt and Control

**Parental Authority**
- **Action Type**: Bonus Action
- **MP Cost**: 2
- **Range**: All allies
- **Effect**: Set Counter trigger - if any ally takes damage, Phaidros immediately attacks the source (if in range)
- **Status Applied**: Protective Instinct (Self)
- **Duration**: 4 turns
- **Burst Gauge**: +12 (Defensive: Guardian)

**Derisive Snort**
- **Action Type**: Action
- **MP Cost**: 2
- **Range**: All enemies
- **Effect**: Next 3 enemy attacks target Phaidros instead of intended target (save vs. mental resistance)
- **Status Applied**: Taunted
- **Burst Gauge**: +10 (Defensive: Guardian)

### Earth Techniques

**Stonefist**
- **Action Type**: Action
- **MP Cost**: 2
- **Range**: Any enemy position
- **Effect**: Launch stone projectile, 100% Earth damage, 30% chance to apply Knockdown (lose next action)
- **Damage Type**: Earth
- **Status Applied**: Knockdown (chance)
- **Burst Gauge**: +10 (Aggressive: Chain Fighter)

**Earthquake**
- **Action Type**: Action
- **MP Cost**: 5
- **Equipment Charge**: 1 (Earth Gauntlets)
- **Range**: All tiles
- **Effect**: Ground tremor affects all units, 70% Earth damage, 25% chance to apply Knockdown
- **Damage Type**: Earth
- **Status Applied**: Knockdown (chance)
- **Burst Gauge**: +25 (Technical: Multi-target)

**Pitfall**
- **Action Type**: Action
- **MP Cost**: 3
- **Range**: Single enemy
- **Effect**: Ground collapses beneath target, 80% Earth damage, apply Root (cannot move) for 3 turns
- **Damage Type**: Earth
- **Status Applied**: Root
- **Positioning**: Creates difficult terrain
- **Burst Gauge**: +12 (Technical: Status infliction)

### Advanced Techniques

**God's Hands** (Burst Mode Only)
- **Action Type**: Ultimate
- **MP Cost**: All remaining
- **Range**: All allies
- **Effect**: Project barriers around all party members, negate next 2 instances of damage per ally
- **Status Applied**: Divine Protection
- **Duration**: Until consumed
- **Burst Gauge**: Generated by ultimate use

**Smash**
- **Action Type**: Action
- **MP Cost**: 3
- **Range**: Adjacent enemy
- **Effect**: Crushing downward attack, higher Knockdown chance vs. size ≤1 enemies, 5% max HP damage vs. larger enemies
- **Status Applied**: Knockdown (vs small) or % HP damage
- **Burst Gauge**: +15 (Aggressive: Executioner)

---

## Sophia - Water Elementalist

### Water Manipulation

**The Storm's Shrapnel**
- **Action Type**: Action
- **MP Cost**: 3
- **Range**: Same row as caster
- **Effect**: Water projectiles along row, 90% Water damage to all enemies in row
- **Damage Type**: Water
- **Burst Gauge**: +15 (Technical: Multi-target)

**Water Spout**
- **Action Type**: Action
- **MP Cost**: 3
- **Range**: Self + enemy in middle row
- **Effect**: Launch into air on water jet, +100% Evasion for 1 turn, strike from above for 110% Water damage
- **Positioning**: Aerial positioning
- **Damage Type**: Water
- **Status Applied**: Aerial (Self)
- **Burst Gauge**: +12 (Technical: Opportunist)

**Geyser**
- **Action Type**: Action
- **MP Cost**: 2
- **Range**: Any tile
- **Effect**: Water eruption from ground, 85% Water damage to any unit on target tile
- **Damage Type**: Water
- **Positioning**: Can target empty tiles for area denial
- **Burst Gauge**: +10 (Technical: Multi-target)

### Ice Techniques

**Frozen Layer**
- **Action Type**: Action
- **MP Cost**: 4
- **Range**: All enemy positions
- **Effect**: Wave of water drenches all enemies, then freezes - all enemies take 60% Ice damage and have 50% chance of Frozen status
- **Damage Type**: Ice
- **Status Applied**: Frozen (chance)
- **Burst Gauge**: +20 (Technical: Multi-target)

**Winter's Shards**
- **Action Type**: Action
- **MP Cost**: 3
- **Range**: All enemies
- **Effect**: Frozen droplet bombardment, 70% Ice damage to all enemies
- **Damage Type**: Ice
- **Burst Gauge**: +15 (Technical: Multi-target)

**Spire of Ice**
- **Action Type**: Action
- **MP Cost**: 3
- **Range**: Single enemy
- **Effect**: Ice spike from ground, 120% Ice damage, 40% chance to apply Impaled (DOT + movement restriction)
- **Damage Type**: Ice
- **Status Applied**: Impaled (chance)
- **Burst Gauge**: +12 (Technical: Status infliction)

### Support Techniques

**Veil of Convalescence**
- **Action Type**: Action
- **MP Cost**: 3
- **Range**: Single ally
- **Effect**: Apply +20% Evasion and Regeneration (15% max HP per turn) for 3 turns
- **Status Applied**: Misty Veil, Regeneration
- **Burst Gauge**: +12 (Support: Medic)

**Douse**
- **Action Type**: Action
- **MP Cost**: 2
- **Range**: All allies
- **Effect**: Clear all Burning effects, apply Enshrouded (+15% resistance to all damage types) for 2 turns
- **Status Applied**: Enshrouded
- **Status Removed**: Burning
- **Burst Gauge**: +15 (Support: Status cleansing)

**Aura of Mist**
- **Action Type**: Bonus Action
- **MP Cost**: 3
- **Range**: All allies
- **Effect**: +10% Evasion and 25% Exousia damage resistance for 4 turns
- **Status Applied**: Mist Shroud
- **Burst Gauge**: +12 (Support: Buffer)

### Ultimate Techniques

**Redemption**
- **Action Type**: Ultimate
- **Equipment Charge**: 1 (Sacred Amulet)
- **Range**: All allies
- **Effect**: Sacrifice current HP to fully restore all party members' HP and MP, remove all debuffs
- **Resource Effect**: Self-sacrifice for party restoration
- **Status Applied**: Full Heal (All allies), Cleanse (All allies)
- **Burst Gauge**: +30 (Support: Ally saved from incapacitation)

**Still Waters**
- **Action Type**: Action
- **MP Cost**: 3
- **Range**: Self
- **Effect**: +30% Defense, gain Evade&Counter (next attack missed triggers counter), end turn immediately, can interrupt enemy turns to counter
- **Status Applied**: Fluid Defense, Counter Stance
- **Burst Gauge**: +12 (Defensive: Guardian)

---

## Paidi - Harmonic Monk

### Healing and Recovery

**Repth**
- **Action Type**: Action
- **MP Cost**: 3
- **Range**: Single ally or self
- **Effect**: Flowing stance healing - restore 40% max HP
- **Burst Gauge**: +15 (Support: Medic)

**Ravishing Ravager Radiant Fist**
- **Action Type**: Action
- **MP Cost**: 4
- **Range**: Multiple adjacent enemies
- **Effect**: Multiple quick strikes (number based on adjacent enemies), each hit deals 60% Radiant damage and heals Paidi for 10% max HP
- **Damage Type**: Radiant
- **Recovery Effect**: HP per hit
- **Burst Gauge**: +15 (Support: Medic + Aggressive: Chain Fighter)

**Gauntlet**
- **Action Type**: Ultimate
- **Equipment Charge**: 1 (Harmony Bracers)
- **Range**: All enemies and allies
- **Effect**: Damage all enemies for 80% Radiant damage, heal all allies for 25% max HP
- **Damage Type**: Radiant
- **Burst Gauge**: +25 (Support: Medic + Technical: Multi-target)

### Stance System

**Stance: Open Hand**
- **Action Type**: Bonus Action
- **MP Cost**: 2
- **Range**: Self
- **Effect**: Enter defensive stance - next 3 attacks can be redirected to different targets, +15% accuracy
- **Status Applied**: Open Stance
- **Duration**: Until 3 attacks redirected or 4 turns
- **Burst Gauge**: +8 (Technical: Efficiency Expert)

**Gentle Sway**
- **Action Type**: Movement + Bonus Action
- **MP Cost**: 1
- **Range**: Self
- **Effect**: Move back 1 tile, +20% Evasion for 2 turns
- **Positioning**: Retreat
- **Status Applied**: Evasive
- **Burst Gauge**: +8 (Defensive: Survivor)

### Mien System (Personality-Based Buffs)

**Mien: Tipsy**
- **Action Type**: Bonus Action
- **MP Cost**: 2
- **Range**: Self
- **Effect**: Enter intoxicated state - attacks have random damage variance (70-130%), +25% resistance to mental effects, -10% accuracy
- **Status Applied**: Intoxicated
- **Duration**: 4 turns
- **Burst Gauge**: +8 (Technical: Efficiency Expert)

**Mien: Belligerent**
- **Action Type**: Bonus Action
- **MP Cost**: 2
- **Range**: Self
- **Effect**: Enter aggressive state - +30% damage, -15% accuracy, must attack if possible
- **Status Applied**: Belligerent
- **Duration**: 3 turns
- **Burst Gauge**: +10 (Aggressive: Berserker)

**Mien: Narcoleptic**
- **Action Type**: Bonus Action
- **MP Cost**: 1
- **Range**: Self
- **Effect**: Enter sleepy state - +50% resistance to all damage, -50% speed, 25% chance to skip turn
- **Status Applied**: Drowsy
- **Duration**: 3 turns
- **Burst Gauge**: +8 (Defensive: Survivor)

### Combat Techniques

**Turn Steel**
- **Action Type**: Reaction
- **MP Cost**: 2
- **Range**: Self
- **Effect**: When targeted by Slash damage while Ironflesh is active, redirect attack to adjacent enemy
- **Prerequisite**: Ironflesh buff active
- **Status Requirement**: Iron Skin
- **Burst Gauge**: +10 (Defensive: Guardian)

**Warding Palm**
- **Action Type**: Action
- **MP Cost**: 3
- **Range**: Self
- **Effect**: Trace protective circle, negate all projectiles for 5 turns, gain +1 Speed per projectile negated
- **Status Applied**: Projectile Ward, Speed (stacking)
- **Burst Gauge**: +12 (Defensive: Guardian)

### Advanced Techniques

**Shallow Rapture**
- **Action Type**: Action
- **MP Cost**: 4
- **Range**: All enemies
- **Effect**: Hypnotic dance, attempt to apply Berserk to all enemies (save vs. Resonance stat, success rate ~40% at level 30)
- **Status Applied**: Berserk (chance based on Resonance vs enemy resistance)
- **Burst Gauge**: +20 (Technical: Status infliction + Multi-target)

---

## Vaughn - Tactical Rogue

### Debuff Techniques

**Hamstring**
- **Action Type**: Action
- **MP Cost**: 2
- **Range**: Single enemy
- **Effect**: 60% Pierce damage, reduce enemy Speed by 50% and turn order priority for 3 turns
- **Status Applied**: Hamstrung
- **Burst Gauge**: +10 (Technical: Status infliction)

**Sever Tendons**
- **Action Type**: Action
- **MP Cost**: 2
- **Range**: Single enemy
- **Effect**: Precise cut, reduce Physical Attack damage by 20% for 4 turns
- **Status Applied**: Tendon Damage
- **Burst Gauge**: +10 (Technical: Status infliction)

**Commotion**
- **Action Type**: Bonus Action
- **MP Cost**: 1
- **Range**: Single enemy
- **Effect**: Distracting maneuvers, reduce Accuracy by 30% for 2 turns
- **Status Applied**: Distracted
- **Burst Gauge**: +8 (Technical: Status infliction)

### Enhancement Techniques

**Leadership**
- **Action Type**: Bonus Action
- **MP Cost**: 2
- **Range**: All allies
- **Effect**: +5% to Strength, Constitution, and Evasion for 4 turns, stacks up to 4 times
- **Status Applied**: Inspired (stackable)
- **Burst Gauge**: +15 (Support: Buffer)

**Constant Flurry**
- **Action Type**: Bonus Action
- **MP Cost**: 3
- **Range**: Self
- **Effect**: All multi-hit attacks gain +1 additional hit for 3 turns
- **Status Applied**: Combat Flow
- **Burst Gauge**: +12 (Technical: Combo Master)

**Poison Coating**
- **Action Type**: Bonus Action
- **Equipment Charge**: 1 (Poison Vial)
- **Range**: Self
- **Effect**: Next 5 attacks have chance to apply Poison DOT based on vial quality
- **Status Applied**: Poisoned Weapons (Self)
- **Burst Gauge**: +8 (Technical: Efficiency Expert)

**Razor Edge**
- **Action Type**: Bonus Action
- **Equipment Charge**: 1 (Rhea's Tears Vial)
- **Range**: Self
- **Effect**: Next 5 attacks have chance to apply Bleed DOT
- **Status Applied**: Bleeding Weapons (Self)
- **Burst Gauge**: +8 (Technical: Efficiency Expert)

### Positioning Techniques

**Hook**
- **Action Type**: Action
- **MP Cost**: 2
- **Range**: Enemy within 2 tiles
- **Effect**: Pull enemy forward 1 tile, 70% Pierce damage
- **Positioning**: Forced movement
- **Burst Gauge**: +10 (Technical: Repositioning)

**Falcon Strike**
- **Action Type**: Action
- **MP Cost**: 2
- **Range**: Adjacent enemy
- **Effect**: Strike enemy for 100% Pierce damage, then move back 1 tile
- **Positioning**: Self-repositioning after attack
- **Burst Gauge**: +10 (Aggressive: Chain Fighter)

### Analysis Techniques

**Deduce Vulnerability**
- **Action Type**: Action
- **MP Cost**: 1
- **Range**: Single enemy
- **Effect**: Reveal all resistances and vulnerabilities of target for entire party
- **Information**: Damage type effectiveness display
- **Duration**: Permanent for this combat
- **Burst Gauge**: +8 (Technical: Opportunist)

**Peak Efficiency**
- **Action Type**: Bonus Action
- **MP Cost**: 2
- **Range**: Self
- **Effect**: Next ability used costs 1 less MP and generates +50% Burst Gauge
- **Status Applied**: Optimized (Self)
- **Burst Gauge**: +15 (Technical: Efficiency Expert)

---

## Lione - Adaptive Mimic

### Information Gathering

**Sniff**
- **Action Type**: Action
- **MP Cost**: 1
- **Range**: Single enemy
- **Effect**: Reveal all items that can be stolen from target
- **Information**: Stealable item list
- **Burst Gauge**: +8 (Technical: Opportunist)

**Intuit**
- **Action Type**: Action
- **MP Cost**: 2
- **Range**: Single enemy
- **Effect**: Reveal enemy's ability list, highlight stealable skills
- **Information**: Enemy ability display with theft viability
- **Duration**: Permanent for this combat
- **Burst Gauge**: +10 (Technical: Opportunist)

**Steal**
- **Action Type**: Action
- **MP Cost**: 2
- **Range**: Adjacent enemy
- **Effect**: Attempt to steal random item, success based on Dexterity vs enemy Agility
- **Resource Effect**: Item acquisition
- **Burst Gauge**: +10 (Technical: Opportunist)

### Mimicry Techniques

**Anja Lancet**
- **Action Type**: Action
- **MP Cost**: Variable (matches copied ability)
- **Range**: Matches copied ability
- **Effect**: Attempt to replicate last enemy technique used, 75% effectiveness
- **Limitation**: Must have seen technique used this combat
- **Burst Gauge**: +15 (Technical: Combo Master)

**Shroudeater**
- **Action Type**: Action
- **MP Cost**: 3
- **Range**: Single Enshrouded enemy
- **Effect**: Remove Enshrouded status from enemy, apply it to self
- **Status Transfer**: Enshrouded (Enemy to Self)
- **Burst Gauge**: +12 (Technical: Status infliction)

### Support Techniques

**From Death, Life**
- **Action Type**: Action
- **MP Cost**: 2
- **Range**: Single ally
- **Effect**: Remove all DOT effects from ally, heal self equal to total damage prevented
- **Status Removed**: All DOTs (ally)
- **Recovery Effect**: Variable healing (self)
- **Burst Gauge**: +15 (Support: Status cleansing + Medic)

**Clear Skies**
- **Action Type**: Action
- **MP Cost**: 4
- **Equipment Charge**: 1 (Weather Rod)
- **Range**: Battlefield
- **Effect**: Reset all environmental effects to neutral
- **Environmental**: Clears all field effects
- **Burst Gauge**: +12 (Support: Utility)

**Refraction**
- **Action Type**: Action
- **MP Cost**: 3
- **Range**: All allies
- **Effect**: Restore 3 MP to all allies
- **Resource Effect**: MP restoration
- **Burst Gauge**: +15 (Support: Ally Support)

**Salience**
- **Action Type**: Action
- **MP Cost**: 2
- **Range**: Single ally
- **Effect**: Clear all mental status effects (Charm, Fear, Confusion, Dazed)
- **Status Removed**: Mental effects
- **Burst Gauge**: +10 (Support: Status cleansing)

### Environmental Manipulation

**Shear Granite**
- **Action Type**: Action
- **MP Cost**: 4
- **Range**: Battlefield
- **Effect**: Raise stone wall, +20% Defense to all units, shift all characters back 1 row (no collision damage)
- **Positioning**: Mass repositioning
- **Environmental**: Creates defensive terrain
- **Status Applied**: Stone Blessing (All units)
- **Burst Gauge**: +20 (Support: Ally Support + Repositioning)

**Impede Motion**
- **Action Type**: Action
- **MP Cost**: 3
- **Range**: All enemies
- **Effect**: Prevent enemies from using Movement actions for 2 turns
- **Status Applied**: Rooted
- **Burst Gauge**: +15 (Technical: Status infliction)

**Singularity**
- **Action Type**: Action
- **MP Cost**: 5
- **Equipment Charge**: 1 (Gravity Core)
- **Range**: Center battlefield tile
- **Effect**: Draw all enemies toward center, units that collide take 60% damage and gain Dazed
- **Positioning**: Forced mass movement
- **Status Applied**: Dazed (collision)
- **Burst Gauge**: +25 (Technical: Multi-target + Repositioning)

### Radiant-Derived Techniques

**Resonant Weave**
- **Action Type**: Action
- **MP Cost**: 4
- **Range**: Single enemy
- **Effect**: Gain temporary HP equal to 70% of target's max HP, suffer Resonance penalty of (tempHP/maxHP)/2, both effects decay at 20% per turn
- **Status Applied**: Resonant Shield (Self), Resonance Drain (Self)
- **Burst Gauge**: +15 (Technical: Opportunist)

**Microscopic Frailty**
- **Action Type**: Action
- **MP Cost**: 3
- **Range**: Single enemy
- **Effect**: Infinite splinters pierce target, 120% Radiant damage, ignores all armor
- **Damage Type**: Radiant
- **Armor Effect**: Bypasses all armor layers
- **Burst Gauge**: +12 (Technical: Opportunist)

**Cursed Weapon**
- **Action Type**: Action
- **MP Cost**: 3
- **Range**: All allies
- **Effect**: Wreathe allies' weapons in Disruptive energy, next 3 attacks per ally deal additional Radiant damage
- **Status Applied**: Cursed Arms (All allies)
- **Damage Type**: Radiant (enhancement)
- **Burst Gauge**: +15 (Support: Buffer)

### Advanced Environmental Control

**Promised Time**
- **Action Type**: Action
- **MP Cost**: 5
- **Range**: All enemies with DOTs
- **Effect**: All enemies with DOT effects immediately take 150% of their total DOT damage, then all DOTs are cleared
- **Status Interaction**: Accelerate and clear DOTs
- **Burst Gauge**: +20 (Technical: Multi-target)

**Blood Moon**
- **Action Type**: Ultimate
- **Equipment Charge**: 1 (Lunar Catalyst)
- **Range**: All units (enemies and allies)
- **Effect**: Apply Berserk to all units on battlefield
- **Status Applied**: Berserk (Universal)
- **Burst Gauge**: +25 (Technical: Multi-target)

**Burn Shadows**
- **Action Type**: Action
- **MP Cost**: 4
- **Range**: All enemies
- **Effect**: Convert all enemy evasion buffs into equivalent Burning DOT effects
- **Status Conversion**: Evasion buffs → Burning DOTs
- **Burst Gauge**: +20 (Technical: Status manipulation)

---

## Cross-Character Combination Techniques

### Dual Character Synergies

**Whiplash** (Vaughn + Chiranjivi)
- **Action Type**: Combination Action
- **MP Cost**: 3 (each character)
- **Range**: First two enemy rows
- **Effect**: Chiranjivi grabs Vaughn by ankles, extended arm swing across first two rows, 90% Slash damage to all targets
- **Positioning**: Both characters must be adjacent
- **Burst Gauge**: +20 (each character - Technical: Multi-target)

**Dual Strike** (Vaughn + Cyrus)
- **Action Type**: Combination Action
- **MP Cost**: 4 (each character)
- **Range**: Single enemy
- **Effect**: Coordinated attack - Vaughn strikes from above with jet boots, Cyrus attacks from ground, combined 180% damage
- **Positioning**: Must be able to reach same target
- **Burst Gauge**: +15 (each character - Aggressive: Chain Fighter)

**Warp Shatter** (Vaughn + Euphen)
- **Action Type**: Combination Action
- **MP Cost**: 5 (each character)
- **Range**: All enemies
- **Effect**: Reality-bending technique applies Sunder to all enemies
- **Status Applied**: Sunder (All enemies)
- **Burst Gauge**: +25 (each character - Technical: Multi-target)

**BOOST!** (Vaughn + Phaidros)
- **Action Type**: Combination Action
- **MP Cost**: 3 (Vaughn), 2 (Phaidros)
- **Range**: Any enemy position
- **Effect**: Phaidros launches Vaughn as projectile, 150% damage + 30% critical rate bonus
- **Positioning**: Vaughn travels to target location
- **Status Applied**: Critical Focus (Vaughn)
- **Burst Gauge**: +15 (Vaughn), +12 (Phaidros)

**Frozen Hammer** (Vaughn + Sophia)
- **Action Type**: Combination Action
- **MP Cost**: 3 (each character)
- **Range**: Single enemy
- **Effect**: Sophia encases Vaughn's weapon in ice, enhanced impact attack, 140% Ice damage + 60% chance to Freeze
- **Damage Type**: Ice
- **Status Applied**: Frozen (chance)
- **Burst Gauge**: +15 (each character - Technical: Status infliction)

### Universal Movement Techniques

**Cross Step** (Multi-Character)
- **Action Type**: Movement
- **MP Cost**: 1
- **Range**: Self
- **Effect**: Move up to 2 spaces along same column, +15% Evasion for 2 turns
- **Positioning**: Vertical column movement
- **Status Applied**: Evasive
- **Burst Gauge**: +8 (Technical: Repositioning)

**Burst Step** (Multi-Character)
- **Action Type**: Movement
- **MP Cost**: 1
- **Range**: Self
- **Effect**: Move up to 2 spaces along same row, +20% damage for 2 turns
- **Positioning**: Horizontal row movement
- **Status Applied**: Momentum
- **Burst Gauge**: +8 (Technical: Repositioning)

**Drop Step** (Multi-Character)
- **Action Type**: Movement
- **MP Cost**: 2
- **Range**: Self
- **Effect**: Leap backward over teammates to back row, +10% Evasion for 1 turn
- **Positioning**: Retreat to back row
- **Status Applied**: Evasive
- **Burst Gauge**: +8 (Defensive: Survivor)

### Technology Integration

**Override** (Cyrus + Sophia)
- **Action Type**: Action
- **MP Cost**: 2 (each character)
- **Range**: Enemy devices/magical constructs
- **Effect**: Disable enemy magical circuitry for 3 turns
- **Status Applied**: System Disruption
- **Burst Gauge**: +12 (each - Technical: Status infliction)

**Overcharge** (Cyrus + Sophia)
- **Action Type**: Bonus Action
- **Equipment Charge**: 2 (Device being enhanced)
- **Range**: Equipment/Device
- **Effect**: Next device activation enhanced by 100% + (ExpendedCharge/MaxCharge) effectiveness
- **Enhancement**: Equipment amplification
- **Burst Gauge**: +15 (each - Technical: Efficiency Expert)

**Refresh** (Cyrus + Sophia)
- **Action Type**: Action
- **MP Cost**: 3 (each character)
- **Equipment Charge**: Special (Restores charges)
- **Range**: All equipment
- **Effect**: Restore 1 charge to all party equipment
- **Resource Effect**: Equipment charge restoration
- **Burst Gauge**: +12 (each - Support: Utility)

---

## Burst Mode Integration Framework

### Character-Specific Burst Transformations

**Chiranjivi - "Crimson Vessel" Mode**
- **Stat Changes**: +60% damage, +2 turn order, immunity to Bleed effects
- **Ability Transforms**: All self-harm techniques become self-beneficial, Symphony techniques can be used in any order
- **Exclusive Abilities**:
  - **Blood Tsunami**: Area attack using all accumulated self-damage as bonus
  - **Crimson Regeneration**: Convert all bleeding effects to healing

**Cyrus - "Elemental Mastery" Mode**
- **Stat Changes**: +50% damage, +40% speed, all attacks gain random elemental enhancement
- **Ability Transforms**: All attacks become area attacks, weapon enhancements stack
- **Exclusive Abilities**:
  - **Prismatic Slash**: Attack with all elements simultaneously
  - **Weapon Storm**: Multiple floating weapons attack independently

**Euphen - "Shadow Lord" Mode**
- **Stat Changes**: +45% damage, +3 turn order, immunity to debuffs
- **Ability Transforms**: All abilities gain stealth component, traps activate immediately
- **Exclusive Abilities**:
  - **Shadow Army**: Create duplicates that use basic attacks
  - **Void Arrow**: Attack that removes enemy from battlefield for 2 turns

**Phaidros - "Mountain King" Mode**
- **Stat Changes**: +70% damage reduction, +40% damage, immunity to forced movement
- **Ability Transforms**: All defensive abilities affect entire party, earth attacks create permanent terrain
- **Exclusive Abilities**:
  - **Continental Drift**: Reshape entire battlefield
  - **Titan's Fist**: Single attack that scales with damage absorbed

**Sophia - "Elemental Convergence" Mode**
- **Stat Changes**: +50% damage, +2 range to all abilities, all abilities affect additional targets
- **Ability Transforms**: Water and Ice techniques can be combined in single action
- **Exclusive Abilities**:
  - **Absolute Zero**: Freeze all enemies and battlefield
  - **Tsunami**: Massive water attack that repositions all units

**Paidi - "Harmonic Resonance" Mode**
- **Stat Changes**: +40% healing effectiveness, +30% damage, all Mien effects active simultaneously
- **Ability Transforms**: All abilities gain harmony effects (damage enemies while healing allies)
- **Exclusive Abilities**:
  - **Perfect Balance**: Full heal party + full damage all enemies
  - **Transcendent Form**: Become untargetable while all abilities cost 0 MP

**Vaughn - "Master Tactician" Mode**
- **Stat Changes**: +45% critical rate, +50% speed, all allies gain +1 action per turn
- **Ability Transforms**: All abilities can target multiple enemies, leadership effects doubled
- **Exclusive Abilities**:
  - **Tactical Supremacy**: All allies act twice this turn
  - **Perfect Execution**: All attacks this turn are automatic criticals

**Lione - "Omnific Mirror" Mode**
- **Stat Changes**: +40% to all stats, can use any ability seen this combat
- **Ability Transforms**: Can combine multiple stolen abilities into single action
- **Exclusive Abilities**:
  - **Perfect Mimesis**: Copy and enhance any ultimate ability used this combat
  - **Reality Theft**: Steal beneficial status effects from all enemies

---

## Equipment Charge Integration

### High-Impact Glyphion Techniques

**Crimson Arsenal** (Chiranjivi Equipment)
- **Charges**: 2 per combat
- **Effect**: Transform all bleeding effects on battlefield into weapons that attack enemies
- **Scaling**: Damage based on total bleeding stacks present

**Elemental Catalyst** (Cyrus Equipment)
- **Charges**: 3 per combat
- **Effect**: Next elemental ability affects entire battlefield with chosen element
- **Versatility**: Can choose element when activated

**Shadow Nexus** (Euphen Equipment)
- **Charges**: 2 per combat
- **Effect**: Create shadow portals allowing instant movement and attacks from any position
- **Duration**: 3 turns of portal access

**Earthen Aegis** (Phaidros Equipment)
- **Charges**: 1 per combat
- **Effect**: Create indestructible barriers around all allies for 5 turns
- **Power**: Absolute protection for limited duration

**Tidal Core** (Sophia Equipment)
- **Charges**: 2 per combat
- **Effect**: Control all water on battlefield, reshape terrain and redirect all water-based attacks
- **Control**: Environmental dominance

**Harmony Sphere** (Paidi Equipment)
- **Charges**: 3 per combat
- **Effect**: Create zone where all abilities heal allies and harm enemies simultaneously
- **Area**: 3x3 tile effect zone

**Tactical Chronometer** (Vaughn Equipment)
- **Charges**: 2 per combat
- **Effect**: Manipulate turn order - can insert ally turns or delay enemy turns
- **Control**: Turn order manipulation

**Mirror of Souls** (Lione Equipment)
- **Charges**: 1 per combat
- **Effect**: Permanently copy any ability used while active, becomes part of Lione's moveset
- **Growth**: Permanent ability expansion

---

## Balance Framework Integration

### Resource Cost Scaling
- **Basic Abilities**: 1-2 MP, common use
- **Tactical Abilities**: 2-3 MP, situational advantage
- **Advanced Abilities**: 3-4 MP, significant impact
- **Ultimate Abilities**: 4-5 MP or Equipment Charges, combat-changing

### Positioning Value System
- **Self-Movement**: Generally 1 MP cost addition
- **Enemy Repositioning**: 1-2 MP cost addition based on distance
- **Mass Repositioning**: 2-3 MP cost addition, often requires equipment charges

### Status Effect Power Levels
- **Minor Effects** (Accuracy/Evasion adjustments): 1-2 turn durations
- **Major Effects** (Damage/Defense modifications): 2-4 turn durations
- **Control Effects** (Movement/Action restrictions): 1-3 turn durations
- **Transform Effects** (Fundamental ability changes): 3-5 turn durations or concentration

### Burst Gauge Generation Balance
- **Aggressive Methods**: 8-15 points per action
- **Defensive Methods**: 8-12 points per defensive trigger
- **Support Methods**: 8-15 points per ally assisted
- **Technical Methods**: 10-20 points per complex execution
