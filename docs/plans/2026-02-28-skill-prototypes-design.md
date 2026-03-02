# Skill Prototypes Design - Cyrus, Vaughn, Phaidros

**Date:** 2026-02-28
**Status:** Approved
**Scope:** Implement spec'd techniques for all three vertical slice characters + equipment-grants-skills system

---

## Overview

Add character-specific skill prototypes organized by role, plus an equipment system where Glyphion items grant additional skills. This covers ~40 new skills across three characters and establishes the equipment data model.

## File Organization

### Skill Data (role-based JSON)

```
godot/data/skills/
  core_skills.json            (existing - basic_attack, shove, grapple_pull, etc.)
  bladewarden_skills.json     (Cyrus primary - sword techniques)
  synergist_skills.json       (Cyrus secondary - elemental weapon skills, granted by equipment)
  shadowfang_skills.json      (Vaughn primary - debuffs, precision strikes)
  warcrier_skills.json        (Vaughn secondary - leadership, buffs)
  ironskin_skills.json        (Phaidros primary - defensive/taunt/tank)
  geovant_skills.json         (Phaidros secondary - earth magic, granted by equipment)
```

### Equipment Data

```
godot/data/equipment/
  weapons.json                (Shifting Blade, etc.)
  devices.json                (Tactical Chronometer, Poison Vial, Rhea's Tears, etc.)
  armor.json                  (Earth Gauntlets, etc.)
```

### Equipment Data Format

```json
{
  "id": "shifting_blade",
  "name": "The Shifting Blade",
  "description": "A runic weapon that can reconfigure its elemental affinity.",
  "category": "greatsword",
  "slot": "weapon",
  "stat_bonuses": { "strength": 2 },
  "charges": 3,
  "granted_skills": ["edge_shift", "gout_of_flame", "luminous_tines", "frozen_thrust", "infernal_incarnate"],
  "type": "glyphion"
}
```

Equipment is **party-shared**, not character-locked. Restrictions are by equipment `category` vs character `equipment_proficiencies`. Any character proficient in the category can equip it.

### Party.json Changes

Add `equipment_proficiencies` and `equipment` fields:

```json
{
  "id": "cyrus",
  "equipment_proficiencies": ["greatsword", "longsword", "device"],
  "equipment": ["shifting_blade", "tactical_chronometer"],
  "starting_abilities": ["basic_attack", "wide_swing", "stance_of_pitch"],
  ...
}
```

`DataLoader` resolves: character abilities = `starting_abilities` + all `granted_skills` from equipped items.

---

## Cyrus - The Seeker (Bladewarden / Synergist)

**Identity:** Entropic Blade wielder. Melee DPS with elemental weapon infusions, stance-based gameplay.
**Stats:** VIG 6, STR 7, DEX 6, RES 5, AGI 6
**Proficiencies:** greatsword, longsword, device
**Default equipment:** Shifting Blade, Tactical Chronometer
**Starting abilities:** basic_attack, wide_swing, stance_of_pitch

### Innate Skills (Bladewarden)

| ID | Name | Action | AP | MP | Base Dmg | Type | Range | Effect | Burst Gain |
|----|------|--------|----|----|----------|------|-------|--------|------------|
| wide_swing | Wide Swing | action | 2 | 2 | 35 | phys/slash | aoe_adjacent | Front-line sweep, STR scaling | 12 |
| raging_blossom | Raging Blossom | action | 2 | 3 | 25 | phys/slash | adjacent | 3-hit combo (hits: 3), STR scaling | 15 |
| flat_swing | Flat Swing | action | 2 | 2 | 30 | phys/blunt | adjacent | Defense break: -30% defense 3 turns | 10 |
| stance_of_pitch | Stance of Pitch | bonus_action | 1 | 2 | - | - | self | Next attack deals 2x damage (2 turn window) | 8 |
| resolve_break | Resolve Break | action | 2 | 3 | 25 | special/psychic | adjacent | -30% resonance, -20% accuracy 3 turns | 10 |
| northern_gale | Northern Gale | action | 2 | 2 | 30 | phys/slash | adjacent | Push target up 1 row | 10 |
| southern_breeze | Southern Breeze | action | 2 | 2 | 30 | phys/slash | adjacent | Push target down 1 row | 10 |
| break_stock | Break Stock | action | 3 | ALL | 40 | phys/slash | all_enemies | Ultimate: hits = MP_spent / 2 (min 2) | 25 |

### Equipment Skills (Shifting Blade -> Synergist)

| ID | Name | Action | AP | MP | Base Dmg | Type | Range | Effect | Burst Gain |
|----|------|--------|----|----|----------|------|-------|--------|------------|
| edge_shift | Edge Shift | bonus_action | 1 | 1 | - | - | self | Choose element, next 3 attacks deal chosen element | 8 |
| gout_of_flame | Gout of Flame | action | 2 | 3 | 35 | elem/fire | adjacent+1 | Hit target + 1 adj; weapon gains Fire 3 hits | 12 |
| luminous_tines | Luminous Tines | action | 2 | 3 | 35 | elem/lightning | adjacent | Lightning strike; weapon gains Lightning 3 hits | 12 |
| frozen_thrust | Frozen Thrust | action | 2 | 3 | 35 | elem/ice | adjacent | Ice pierce; weapon gains Ice 3 hits | 12 |
| infernal_incarnate | Infernal Incarnate | action | 2 | 4 | - | - | self | +40% damage, all attacks become current element, 4 turns | 15 |

---

## Vaughn - The Hawk (Shadowfang / Warcrier)

**Identity:** Tactical Rogue. Fast, debuff-heavy, team leader. Devices and precision.
**Stats:** VIG 5, STR 6, DEX 8, RES 4, AGI 8
**Proficiencies:** dagger, shortsword, consumable_device, gadget
**Default equipment:** Poison Vial, Rhea's Tears Vial
**Starting abilities:** basic_attack, hamstring, commotion, leadership

### Innate Skills (Shadowfang + Warcrier)

| ID | Name | Action | AP | MP | Base Dmg | Type | Range | Effect | Burst Gain |
|----|------|--------|----|----|----------|------|-------|--------|------------|
| sever_tendons | Sever Tendons | action | 2 | 2 | 25 | phys/pierce | adjacent | -20% phys attack 4 turns | 10 |
| commotion | Commotion | bonus_action | 1 | 1 | - | - | single_enemy/ranged | -30% accuracy 2 turns | 8 |
| constant_flurry | Constant Flurry | bonus_action | 1 | 3 | - | - | self | +1 hit on multi-hit skills 3 turns | 12 |
| hook | Hook | action | 2 | 2 | 30 | phys/pierce | ranged (2 tiles) | Pull enemy 1 tile toward caster | 10 |
| falcon_strike | Falcon Strike | action | 2 | 2 | 40 | phys/pierce | adjacent | Hit + self retreat 1 tile | 10 |
| deduce_vulnerability | Deduce Vulnerability | action | 2 | 1 | - | - | single_enemy/ranged | Reveal all resistances permanently | 8 |
| peak_efficiency | Peak Efficiency | bonus_action | 1 | 2 | - | - | self | Next skill -1 MP, +50% burst gauge | 15 |

### Equipment Skills

**Poison Vial** (category: consumable_device, charges: 1):

| ID | Name | Action | AP | MP | Effect | Burst Gain |
|----|------|--------|----|----|--------|------------|
| poison_coating | Poison Coating | bonus_action | 1 | 0 | Next 5 attacks may poison (equip charge) | 8 |

**Rhea's Tears Vial** (category: consumable_device, charges: 1):

| ID | Name | Action | AP | MP | Effect | Burst Gain |
|----|------|--------|----|----|--------|------------|
| razor_edge | Razor Edge | bonus_action | 1 | 0 | Next 5 attacks may bleed (equip charge) | 8 |

---

## Phaidros - Second Gnosis (Ironskin / Geovant)

**Identity:** Earth Guardian. Tankiest party member, fist fighter, earth magic.
**Stats:** VIG 9, STR 7, DEX 4, RES 6, AGI 4
**Proficiencies:** gauntlet, fist, heavy_armor
**Default equipment:** Earth Gauntlets
**Starting abilities:** basic_attack, one_two, ironflesh, derisive_snort

### Innate Skills (Ironskin)

| ID | Name | Action | AP | MP | Base Dmg | Type | Range | Effect | Burst Gain |
|----|------|--------|----|----|----------|------|-------|--------|------------|
| ready_stance | Ready Stance | bonus_action | 1 | 1 | - | - | self | Next hit: -50% phys / -25% magic DR, negate push | 8 |
| protective_instinct | Protective Instinct | bonus_action | 1 | 2 | - | - | self | Counter-trigger: if ally hit, counterattack source 4 turns | 12 |
| intercede | Intercede | bonus_action | 1 | 2 | - | - | single_ally | Block next hit targeting chosen ally | 12 |
| again_with_vigor | Again with Vigor | bonus_action | 1 | 2 | - | - | self | Heal 30% shields | 10 |
| one_two | One-Two | action | 1 | 1 | 15 | phys/blunt | adjacent | 2-hit jab (hits: 2), charge kinetic shields | 6 |
| uppercut | Uppercut | action | 2 | 2 | 35 | phys/blunt | adjacent | Chance to stun 1 turn | 10 |
| headclap | Headclap | action | 2 | 2 | 25 | phys/blunt | adjacent | -30% resonance 3 turns | 10 |
| smash | Smash | action | 2 | 3 | 40 | phys/blunt | adjacent | Knockdown vs small, 5% max HP vs large | 15 |
| thunderfist | Thunderfist | action | 2 | 2 | 35 | phys/blunt | adjacent | Disorient: -20% accuracy, -1 turn order 2 turns | 10 |
| striking_tips | Striking Tips | action | 2 | 3 | 30 | phys/blunt | aoe_front_row | Hit front row + apply burning DOT (8/turn, 3 turns) | 12 |
| unerring_menace | Unerring Menace | action | 3 | 5 | 15 | phys/blunt | adjacent | 7 strikes, each inflicts random negative physical status | 25 |

### Equipment Skills (Earth Gauntlets -> Geovant)

| ID | Name | Action | AP | MP | Charges | Base Dmg | Type | Range | Effect | Burst Gain |
|----|------|--------|----|----|---------|----------|------|-------|--------|------------|
| the_wall | The Wall | action | 2 | 4 | 1 | - | - | front column | Create wall (HP=75% Phaidros HP) | 15 |
| earthquake | Earthquake | action | 2 | 4 | 1 | 35 | elem/earth | all_enemies | All-tile AoE earth damage | 15 |
| pitfall | Pitfall | action | 2 | 3 | 1 | - | - | single_enemy/ranged | Root enemy 2 turns | 12 |
| stonefist | Stonefist | action | 2 | 2 | 1 | 40 | elem/earth | single_enemy/ranged | Ranged earth punch, knockdown chance | 10 |

---

## New Effect Types Required

| Effect Type | Description | Skills Using It |
|-------------|-------------|-----------------|
| weapon_buff | Elemental enchant lasting N hits | edge_shift, gout_of_flame, luminous_tines, frozen_thrust |
| stance | Modify next attack (multiplier, element) | stance_of_pitch, infernal_incarnate |
| forced_movement_row | Push up/down 1 row | northern_gale, southern_breeze |
| forced_movement_pull | Pull toward caster | hook |
| self_retreat | Move self backward after attack | falcon_strike |
| multi_hit | Attack hits N times | raging_blossom (3), one_two (2), unerring_menace (7) |
| multi_hit_bonus | +N hits on multi-hit skills | constant_flurry |
| defense_break | Reduce defense stat | flat_swing |
| knockdown | Stun variant for physical | smash, stonefist |
| intercept | Redirect hit to self | intercede |
| counter_trigger | Auto-counterattack on condition | protective_instinct |
| reveal | Expose enemy resistances | deduce_vulnerability |
| heal_shields | Restore shield HP | again_with_vigor |
| dot_application | Apply DOT to weapon attacks | poison_coating, razor_edge |
| mp_cost_reduction | Reduce next skill MP cost | peak_efficiency |
| create_terrain | Spawn destructible object | the_wall |
| root | Immobilize enemy | pitfall |
| random_status_per_hit | Each hit rolls random debuff | unerring_menace |
| spend_all_mp | Cost = all remaining MP, effect scales | break_stock |

## DataLoader Changes

1. `load_all_skills()` - glob `godot/data/skills/*.json`, merge into single dictionary
2. `load_all_equipment()` - glob `godot/data/equipment/*.json`, build equipment registry
3. `resolve_character_abilities(character)` - merge `starting_abilities` + equipment `granted_skills`
4. `can_equip(character, equipment)` - check `category` vs `equipment_proficiencies`

## Combat Manager Changes

1. Expand `_apply_skill_effect()` to handle new effect types
2. Add `_handle_multi_hit()` for skills with `hits > 1`
3. Add equipment charge tracking (deduct on use, display in UI)
4. Add forced movement handlers (row push, pull toward)
5. Add intercept/counter-trigger status tracking
