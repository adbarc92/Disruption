# Skill Prototypes Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Implement ~40 character-specific skills for Cyrus, Vaughn, and Phaidros, plus an equipment-grants-skills system where Glyphion items add abilities to characters.

**Architecture:** Role-based skill JSON files merged at load time. Equipment JSON defines items with `granted_skills` arrays. DataLoader resolves character abilities = `starting_abilities` + equipment-granted skills. `combat_manager.gd` handles new effect types (multi-hit, weapon buffs, forced movement, stances, etc.) in `_execute_skill()` and `_apply_skill_effect()`.

**Tech Stack:** Godot 4 / GDScript, JSON data files, existing combat demo architecture.

---

### Task 1: Create Role-Based Skill JSON Files

**Files:**
- Create: `godot/data/skills/bladewarden_skills.json`
- Create: `godot/data/skills/synergist_skills.json`
- Create: `godot/data/skills/shadowfang_skills.json`
- Create: `godot/data/skills/warcrier_skills.json`
- Create: `godot/data/skills/ironskin_skills.json`
- Create: `godot/data/skills/geovant_skills.json`

**Step 1: Create bladewarden_skills.json (Cyrus innate sword techniques)**

```json
{
  "_COMMENT": "Bladewarden role skills - Cyrus innate sword techniques",
  "skills": [
    {
      "id": "wide_swing",
      "name": "Wide Swing",
      "description": "Swing across the front-line, hitting all adjacent enemies.",
      "action_type": "action",
      "mp_cost": 2,
      "damage": {
        "base": 35,
        "type": "physical",
        "subtype": "slash",
        "stat_scaling": "strength"
      },
      "targeting": {
        "type": "aoe_adjacent_enemies",
        "range": "adjacent",
        "range_band": "melee"
      },
      "burst_gauge_gain": 12,
      "burst_charge_type": "aggressive",
      "roles": ["bladewarden"]
    },
    {
      "id": "raging_blossom",
      "name": "Raging Blossom",
      "description": "Obliterate the enemy with a series of three strikes.",
      "action_type": "action",
      "mp_cost": 3,
      "damage": {
        "base": 25,
        "type": "physical",
        "subtype": "slash",
        "stat_scaling": "strength",
        "hits": 3
      },
      "targeting": {
        "type": "single_enemy",
        "range": "adjacent",
        "range_band": "melee"
      },
      "burst_gauge_gain": 15,
      "burst_charge_type": "aggressive",
      "roles": ["bladewarden"]
    },
    {
      "id": "flat_swing",
      "name": "Flat Swing",
      "description": "Crush foes with the broadside, reducing their defenses.",
      "action_type": "action",
      "mp_cost": 2,
      "damage": {
        "base": 30,
        "type": "physical",
        "subtype": "blunt",
        "stat_scaling": "strength"
      },
      "effect": {
        "type": "debuff",
        "status": "defense_broken",
        "stat_modifier": { "vigor": -0.3 },
        "duration": 3
      },
      "targeting": {
        "type": "single_enemy",
        "range": "adjacent",
        "range_band": "melee"
      },
      "burst_gauge_gain": 10,
      "burst_charge_type": "aggressive",
      "roles": ["bladewarden"]
    },
    {
      "id": "stance_of_pitch",
      "name": "Stance of Pitch",
      "description": "Assume the learned form. Your next attack deals double damage.",
      "action_type": "bonus_action",
      "ap_cost": 1,
      "mp_cost": 2,
      "effect": {
        "type": "self_buff",
        "status": "pitched_stance",
        "damage_multiplier": 2.0,
        "duration": 2,
        "consumes_on_attack": true
      },
      "targeting": {
        "type": "self"
      },
      "burst_gauge_gain": 8,
      "burst_charge_type": "technical",
      "roles": ["bladewarden"]
    },
    {
      "id": "resolve_break",
      "name": "Resolve Break",
      "description": "Shatter an opponent's will, weakening their magic and focus.",
      "action_type": "action",
      "mp_cost": 3,
      "damage": {
        "base": 25,
        "type": "special",
        "subtype": "psychic",
        "stat_scaling": "strength"
      },
      "effect": {
        "type": "debuff",
        "status": "resolve_broken",
        "stat_modifier": { "resonance": -0.3, "dexterity": -0.2 },
        "duration": 3
      },
      "targeting": {
        "type": "single_enemy",
        "range": "adjacent",
        "range_band": "melee"
      },
      "burst_gauge_gain": 10,
      "burst_charge_type": "technical",
      "roles": ["bladewarden"]
    },
    {
      "id": "northern_gale",
      "name": "Northern Gale",
      "description": "Displace an enemy upward with a sweeping cut.",
      "action_type": "action",
      "mp_cost": 2,
      "damage": {
        "base": 30,
        "type": "physical",
        "subtype": "slash",
        "stat_scaling": "strength"
      },
      "effect": {
        "type": "forced_movement",
        "direction": "up",
        "distance": 1
      },
      "targeting": {
        "type": "single_enemy",
        "range": "adjacent",
        "range_band": "melee"
      },
      "burst_gauge_gain": 10,
      "burst_charge_type": "technical",
      "roles": ["bladewarden"]
    },
    {
      "id": "southern_breeze",
      "name": "Southern Breeze",
      "description": "Displace an enemy downward with a low sweep.",
      "action_type": "action",
      "mp_cost": 2,
      "damage": {
        "base": 30,
        "type": "physical",
        "subtype": "slash",
        "stat_scaling": "strength"
      },
      "effect": {
        "type": "forced_movement",
        "direction": "down",
        "distance": 1
      },
      "targeting": {
        "type": "single_enemy",
        "range": "adjacent",
        "range_band": "melee"
      },
      "burst_gauge_gain": 10,
      "burst_charge_type": "technical",
      "roles": ["bladewarden"]
    },
    {
      "id": "break_stock",
      "name": "Break Stock",
      "description": "Ultimate technique. Spend all remaining MP to slash all enemies multiple times.",
      "action_type": "action",
      "ap_cost": 3,
      "mp_cost": 0,
      "damage": {
        "base": 40,
        "type": "physical",
        "subtype": "slash",
        "stat_scaling": "strength"
      },
      "special": {
        "type": "spend_all_mp",
        "hits_formula": "mp_spent_div_2_min_2"
      },
      "targeting": {
        "type": "all_enemies"
      },
      "burst_gauge_gain": 25,
      "burst_charge_type": "aggressive",
      "roles": ["bladewarden"]
    }
  ]
}
```

**Step 2: Create synergist_skills.json (elemental weapon skills, granted by Shifting Blade)**

```json
{
  "_COMMENT": "Synergist role skills - elemental weapon infusion, granted by equipment",
  "skills": [
    {
      "id": "edge_shift",
      "name": "Edge Shift",
      "description": "Reconfigure weapon element. Next 3 attacks deal the chosen element.",
      "action_type": "bonus_action",
      "ap_cost": 1,
      "mp_cost": 1,
      "effect": {
        "type": "weapon_buff",
        "status": "elemental_edge",
        "choose_element": true,
        "attacks_remaining": 3,
        "duration": 99
      },
      "targeting": {
        "type": "self"
      },
      "burst_gauge_gain": 8,
      "burst_charge_type": "technical",
      "roles": ["synergist"]
    },
    {
      "id": "gout_of_flame",
      "name": "Gout of Flame",
      "description": "Slash in a burning arc. Weapon gains Fire for 3 hits.",
      "action_type": "action",
      "mp_cost": 3,
      "damage": {
        "base": 35,
        "type": "elemental",
        "subtype": "fire",
        "stat_scaling": "strength"
      },
      "effect": {
        "type": "weapon_buff",
        "status": "fire_edge",
        "element": "fire",
        "attacks_remaining": 3,
        "duration": 99
      },
      "targeting": {
        "type": "single_enemy",
        "range": "adjacent",
        "range_band": "melee"
      },
      "burst_gauge_gain": 12,
      "burst_charge_type": "aggressive",
      "roles": ["synergist"]
    },
    {
      "id": "luminous_tines",
      "name": "Luminous Tines",
      "description": "An overhead swing to mimic the wrath of a storm. Weapon gains Lightning for 3 hits.",
      "action_type": "action",
      "mp_cost": 3,
      "damage": {
        "base": 35,
        "type": "elemental",
        "subtype": "lightning",
        "stat_scaling": "strength"
      },
      "effect": {
        "type": "weapon_buff",
        "status": "lightning_edge",
        "element": "lightning",
        "attacks_remaining": 3,
        "duration": 99
      },
      "targeting": {
        "type": "single_enemy",
        "range": "adjacent",
        "range_band": "melee"
      },
      "burst_gauge_gain": 12,
      "burst_charge_type": "aggressive",
      "roles": ["synergist"]
    },
    {
      "id": "frozen_thrust",
      "name": "Frozen Thrust",
      "description": "A piercing thrust of ice. Weapon gains Ice for 3 hits.",
      "action_type": "action",
      "mp_cost": 3,
      "damage": {
        "base": 35,
        "type": "elemental",
        "subtype": "ice",
        "stat_scaling": "strength"
      },
      "effect": {
        "type": "weapon_buff",
        "status": "ice_edge",
        "element": "ice",
        "attacks_remaining": 3,
        "duration": 99
      },
      "targeting": {
        "type": "single_enemy",
        "range": "adjacent",
        "range_band": "melee"
      },
      "burst_gauge_gain": 12,
      "burst_charge_type": "aggressive",
      "roles": ["synergist"]
    },
    {
      "id": "infernal_incarnate",
      "name": "Infernal Incarnate",
      "description": "Channel the will of the blade. +40% damage, all attacks become current element.",
      "action_type": "action",
      "mp_cost": 4,
      "effect": {
        "type": "self_buff",
        "status": "infernal_incarnate",
        "stat_modifier": { "strength": 0.4 },
        "converts_attacks_to_element": true,
        "duration": 4
      },
      "targeting": {
        "type": "self"
      },
      "burst_gauge_gain": 15,
      "burst_charge_type": "aggressive",
      "roles": ["synergist"]
    }
  ]
}
```

**Step 3: Create shadowfang_skills.json (Vaughn debuff/precision strikes)**

```json
{
  "_COMMENT": "Shadowfang role skills - Vaughn debuff and precision techniques",
  "skills": [
    {
      "id": "sever_tendons",
      "name": "Sever Tendons",
      "description": "Precise cut to reduce physical attack damage by 20%.",
      "action_type": "action",
      "mp_cost": 2,
      "damage": {
        "base": 25,
        "type": "physical",
        "subtype": "pierce",
        "stat_scaling": "dexterity"
      },
      "effect": {
        "type": "debuff",
        "status": "tendon_damage",
        "stat_modifier": { "strength": -0.2 },
        "duration": 4
      },
      "targeting": {
        "type": "single_enemy",
        "range": "adjacent",
        "range_band": "melee"
      },
      "burst_gauge_gain": 10,
      "burst_charge_type": "technical",
      "roles": ["shadowfang"]
    },
    {
      "id": "commotion",
      "name": "Commotion",
      "description": "Distracting maneuvers reduce enemy accuracy by 30%.",
      "action_type": "bonus_action",
      "ap_cost": 1,
      "mp_cost": 1,
      "effect": {
        "type": "debuff",
        "status": "distracted",
        "stat_modifier": { "dexterity": -0.3 },
        "duration": 2
      },
      "targeting": {
        "type": "single_enemy",
        "range": "any",
        "range_band": "ranged"
      },
      "burst_gauge_gain": 8,
      "burst_charge_type": "technical",
      "roles": ["shadowfang"]
    },
    {
      "id": "hook",
      "name": "Hook",
      "description": "Pull an enemy forward 1 tile with a hooked strike.",
      "action_type": "action",
      "mp_cost": 2,
      "damage": {
        "base": 30,
        "type": "physical",
        "subtype": "pierce",
        "stat_scaling": "dexterity"
      },
      "effect": {
        "type": "forced_movement",
        "direction": "toward_caster",
        "distance": 1
      },
      "targeting": {
        "type": "single_enemy",
        "range": "any",
        "range_band": "close"
      },
      "burst_gauge_gain": 10,
      "burst_charge_type": "technical",
      "roles": ["shadowfang"]
    },
    {
      "id": "falcon_strike",
      "name": "Falcon Strike",
      "description": "Strike an enemy, then retreat 1 tile.",
      "action_type": "action",
      "mp_cost": 2,
      "damage": {
        "base": 40,
        "type": "physical",
        "subtype": "pierce",
        "stat_scaling": "dexterity"
      },
      "effect": {
        "type": "self_reposition",
        "direction": "away_from_target",
        "distance": 1
      },
      "targeting": {
        "type": "single_enemy",
        "range": "adjacent",
        "range_band": "melee"
      },
      "burst_gauge_gain": 10,
      "burst_charge_type": "aggressive",
      "roles": ["shadowfang"]
    },
    {
      "id": "deduce_vulnerability",
      "name": "Deduce Vulnerability",
      "description": "Determine an enemy's resistances and weaknesses for the entire party.",
      "action_type": "action",
      "mp_cost": 1,
      "effect": {
        "type": "reveal",
        "reveals": "weaknesses_and_resistances",
        "duration": -1
      },
      "targeting": {
        "type": "single_enemy",
        "range": "any",
        "range_band": "distant"
      },
      "burst_gauge_gain": 8,
      "burst_charge_type": "technical",
      "roles": ["shadowfang"]
    },
    {
      "id": "peak_efficiency",
      "name": "Peak Efficiency",
      "description": "Next ability costs 1 less MP and generates +50% Burst Gauge.",
      "action_type": "bonus_action",
      "ap_cost": 1,
      "mp_cost": 2,
      "effect": {
        "type": "self_buff",
        "status": "optimized",
        "mp_cost_reduction": 1,
        "burst_gauge_bonus": 0.5,
        "duration": 2,
        "consumes_on_skill": true
      },
      "targeting": {
        "type": "self"
      },
      "burst_gauge_gain": 15,
      "burst_charge_type": "technical",
      "roles": ["shadowfang"]
    },
    {
      "id": "constant_flurry",
      "name": "Constant Flurry",
      "description": "All multi-hit attacks gain +1 additional hit for 3 turns.",
      "action_type": "bonus_action",
      "ap_cost": 1,
      "mp_cost": 3,
      "effect": {
        "type": "self_buff",
        "status": "combat_flow",
        "multi_hit_bonus": 1,
        "duration": 3
      },
      "targeting": {
        "type": "self"
      },
      "burst_gauge_gain": 12,
      "burst_charge_type": "technical",
      "roles": ["shadowfang"]
    }
  ]
}
```

**Step 4: Create warcrier_skills.json (Vaughn leadership/party buffs)**

Note: Leadership already exists in core_skills.json. We move it here and remove from core_skills.json.

```json
{
  "_COMMENT": "Warcrier role skills - Vaughn leadership and party buffs",
  "skills": [
    {
      "id": "leadership",
      "name": "Leadership",
      "description": "Inspire allies with stat bonuses. Stacks up to 4 times.",
      "action_type": "bonus_action",
      "ap_cost": 1,
      "mp_cost": 2,
      "effect": {
        "type": "party_buff",
        "status": "inspired",
        "stat_modifier": {
          "strength": 0.05,
          "vigor": 0.05,
          "dexterity": 0.05
        },
        "duration": 4,
        "stackable": true,
        "max_stacks": 4
      },
      "targeting": {
        "type": "all_allies"
      },
      "burst_gauge_gain": 15,
      "burst_charge_type": "support",
      "roles": ["warcrier"]
    }
  ]
}
```

**Step 5: Create ironskin_skills.json (Phaidros defensive/tank)**

```json
{
  "_COMMENT": "Ironskin role skills - Phaidros defensive and tank techniques",
  "skills": [
    {
      "id": "ready_stance",
      "name": "Ready Stance",
      "description": "Brace for the next blow. -50% physical or -25% magical damage, negate push.",
      "action_type": "bonus_action",
      "ap_cost": 1,
      "mp_cost": 1,
      "effect": {
        "type": "self_buff",
        "status": "braced",
        "damage_reduction": { "physical": 0.5, "elemental": 0.25, "magical": 0.25 },
        "negates_forced_movement": true,
        "duration": 2,
        "consumes_on_hit": true
      },
      "targeting": {
        "type": "self"
      },
      "burst_gauge_gain": 8,
      "burst_charge_type": "defensive",
      "roles": ["ironskin"]
    },
    {
      "id": "protective_instinct",
      "name": "Protective Instinct",
      "description": "Set counter trigger. If any ally takes damage, counterattack the source.",
      "action_type": "bonus_action",
      "ap_cost": 1,
      "mp_cost": 2,
      "effect": {
        "type": "self_buff",
        "status": "protective_instinct",
        "counter_on_ally_hit": true,
        "duration": 4
      },
      "targeting": {
        "type": "self"
      },
      "burst_gauge_gain": 12,
      "burst_charge_type": "defensive",
      "roles": ["ironskin"]
    },
    {
      "id": "intercede",
      "name": "Intercede",
      "description": "Block the next hit targeting one ally, taking the damage instead.",
      "action_type": "bonus_action",
      "ap_cost": 1,
      "mp_cost": 2,
      "effect": {
        "type": "ally_buff",
        "status": "intercepted",
        "redirect_damage_to": "caster",
        "duration": 3,
        "consumes_on_hit": true
      },
      "targeting": {
        "type": "single_ally",
        "range": "any",
        "range_band": "distant"
      },
      "burst_gauge_gain": 12,
      "burst_charge_type": "defensive",
      "roles": ["ironskin"]
    },
    {
      "id": "again_with_vigor",
      "name": "Again, with Vigor",
      "description": "Repair personal defenses. Heal 30% of max HP.",
      "action_type": "bonus_action",
      "ap_cost": 1,
      "mp_cost": 2,
      "healing": {
        "base_percent": 0.3,
        "target": "self"
      },
      "targeting": {
        "type": "self"
      },
      "burst_gauge_gain": 10,
      "burst_charge_type": "defensive",
      "roles": ["ironskin"]
    },
    {
      "id": "one_two",
      "name": "One-Two",
      "description": "A quick jab combo.",
      "action_type": "action",
      "ap_cost": 1,
      "mp_cost": 1,
      "damage": {
        "base": 15,
        "type": "physical",
        "subtype": "blunt",
        "stat_scaling": "strength",
        "hits": 2
      },
      "targeting": {
        "type": "single_enemy",
        "range": "adjacent",
        "range_band": "melee"
      },
      "burst_gauge_gain": 6,
      "burst_charge_type": "aggressive",
      "roles": ["ironskin"]
    },
    {
      "id": "uppercut",
      "name": "Uppercut",
      "description": "A rising strike with a chance to stun.",
      "action_type": "action",
      "mp_cost": 2,
      "damage": {
        "base": 35,
        "type": "physical",
        "subtype": "blunt",
        "stat_scaling": "strength"
      },
      "effect": {
        "type": "debuff",
        "status": "stunned",
        "duration": 1,
        "apply_chance": 0.6
      },
      "targeting": {
        "type": "single_enemy",
        "range": "adjacent",
        "range_band": "melee"
      },
      "burst_gauge_gain": 10,
      "burst_charge_type": "aggressive",
      "roles": ["ironskin"]
    },
    {
      "id": "headclap",
      "name": "Headclap",
      "description": "Crunch an enemy's head between hands, reducing magic power.",
      "action_type": "action",
      "mp_cost": 2,
      "damage": {
        "base": 25,
        "type": "physical",
        "subtype": "blunt",
        "stat_scaling": "strength"
      },
      "effect": {
        "type": "debuff",
        "status": "headclapped",
        "stat_modifier": { "resonance": -0.3 },
        "duration": 3
      },
      "targeting": {
        "type": "single_enemy",
        "range": "adjacent",
        "range_band": "melee"
      },
      "burst_gauge_gain": 10,
      "burst_charge_type": "aggressive",
      "roles": ["ironskin"]
    },
    {
      "id": "smash",
      "name": "Smash",
      "description": "Crushing downward attack. Knocks down small enemies, deals %HP to larger ones.",
      "action_type": "action",
      "mp_cost": 3,
      "damage": {
        "base": 40,
        "type": "physical",
        "subtype": "blunt",
        "stat_scaling": "strength"
      },
      "effect": {
        "type": "debuff",
        "status": "knocked_down",
        "duration": 1,
        "size_conditional": true,
        "knockdown_max_size": 1,
        "hp_percent_if_large": 0.05
      },
      "targeting": {
        "type": "single_enemy",
        "range": "adjacent",
        "range_band": "melee"
      },
      "burst_gauge_gain": 15,
      "burst_charge_type": "aggressive",
      "roles": ["ironskin"]
    },
    {
      "id": "thunderfist",
      "name": "Thunderfist",
      "description": "A concussive punch that disorients the target.",
      "action_type": "action",
      "mp_cost": 2,
      "damage": {
        "base": 35,
        "type": "physical",
        "subtype": "blunt",
        "stat_scaling": "strength"
      },
      "effect": {
        "type": "debuff",
        "status": "disoriented",
        "stat_modifier": { "dexterity": -0.2, "agility": -0.2 },
        "duration": 2
      },
      "targeting": {
        "type": "single_enemy",
        "range": "adjacent",
        "range_band": "melee"
      },
      "burst_gauge_gain": 10,
      "burst_charge_type": "aggressive",
      "roles": ["ironskin"]
    },
    {
      "id": "striking_tips",
      "name": "Striking Tips",
      "description": "Damage all enemies in the front row, applying burning DOTs.",
      "action_type": "action",
      "mp_cost": 3,
      "damage": {
        "base": 30,
        "type": "physical",
        "subtype": "blunt",
        "stat_scaling": "strength"
      },
      "effect": {
        "type": "debuff",
        "status": "burning",
        "damage_per_turn": 8,
        "duration": 3
      },
      "targeting": {
        "type": "aoe_adjacent_enemies",
        "range": "adjacent",
        "range_band": "melee"
      },
      "burst_gauge_gain": 12,
      "burst_charge_type": "aggressive",
      "roles": ["ironskin"]
    },
    {
      "id": "unerring_menace",
      "name": "Unerring Menace",
      "description": "Unleash seven strikes, each inflicting a random negative physical status.",
      "action_type": "action",
      "ap_cost": 3,
      "mp_cost": 5,
      "damage": {
        "base": 15,
        "type": "physical",
        "subtype": "blunt",
        "stat_scaling": "strength",
        "hits": 7
      },
      "effect": {
        "type": "random_debuff_per_hit",
        "debuff_pool": ["weakened", "defense_broken", "disoriented", "hamstrung", "tendon_damage", "distracted", "knocked_down"],
        "duration": 2
      },
      "targeting": {
        "type": "single_enemy",
        "range": "adjacent",
        "range_band": "melee"
      },
      "burst_gauge_gain": 25,
      "burst_charge_type": "aggressive",
      "roles": ["ironskin"]
    }
  ]
}
```

**Step 6: Create geovant_skills.json (Phaidros earth magic, equipment-granted)**

```json
{
  "_COMMENT": "Geovant role skills - Earth magic, granted by Earth Gauntlets equipment",
  "skills": [
    {
      "id": "the_wall",
      "name": "The Wall",
      "description": "Create a destructible wall along the front column. HP = 75% of caster's max HP.",
      "action_type": "action",
      "mp_cost": 4,
      "equipment_charge_cost": 1,
      "effect": {
        "type": "create_terrain",
        "terrain": "wall",
        "hp_percent_of_caster": 0.75,
        "placement": "front_column"
      },
      "targeting": {
        "type": "self"
      },
      "burst_gauge_gain": 15,
      "burst_charge_type": "defensive",
      "roles": ["geovant"]
    },
    {
      "id": "earthquake",
      "name": "Earthquake",
      "description": "Shake the entire battlefield with earth damage.",
      "action_type": "action",
      "mp_cost": 4,
      "equipment_charge_cost": 1,
      "damage": {
        "base": 35,
        "type": "elemental",
        "subtype": "earth",
        "stat_scaling": "resonance"
      },
      "targeting": {
        "type": "all_enemies"
      },
      "burst_gauge_gain": 15,
      "burst_charge_type": "aggressive",
      "roles": ["geovant"]
    },
    {
      "id": "pitfall",
      "name": "Pitfall",
      "description": "Collapse the ground beneath an enemy, rooting them in place.",
      "action_type": "action",
      "mp_cost": 3,
      "equipment_charge_cost": 1,
      "effect": {
        "type": "debuff",
        "status": "rooted",
        "prevents_movement": true,
        "duration": 2
      },
      "targeting": {
        "type": "single_enemy",
        "range": "any",
        "range_band": "distant"
      },
      "burst_gauge_gain": 12,
      "burst_charge_type": "technical",
      "roles": ["geovant"]
    },
    {
      "id": "stonefist",
      "name": "Stonefist",
      "description": "Rip stone from the ground and launch at an enemy. Chance to knock down.",
      "action_type": "action",
      "mp_cost": 2,
      "equipment_charge_cost": 1,
      "damage": {
        "base": 40,
        "type": "elemental",
        "subtype": "earth",
        "stat_scaling": "strength"
      },
      "effect": {
        "type": "debuff",
        "status": "knocked_down",
        "duration": 1,
        "apply_chance": 0.5
      },
      "targeting": {
        "type": "single_enemy",
        "range": "any",
        "range_band": "distant"
      },
      "burst_gauge_gain": 10,
      "burst_charge_type": "aggressive",
      "roles": ["geovant"]
    }
  ]
}
```

**Step 7: Commit skill data files**

```bash
git add godot/data/skills/bladewarden_skills.json godot/data/skills/synergist_skills.json godot/data/skills/shadowfang_skills.json godot/data/skills/warcrier_skills.json godot/data/skills/ironskin_skills.json godot/data/skills/geovant_skills.json
git commit -m "feat: add role-based skill JSON files for Cyrus, Vaughn, Phaidros"
```

---

### Task 2: Create Equipment Data Files

**Files:**
- Create: `godot/data/equipment/weapons.json`
- Create: `godot/data/equipment/devices.json`
- Create: `godot/data/equipment/armor.json`

**Step 1: Create weapons.json**

```json
{
  "equipment": [
    {
      "id": "shifting_blade",
      "name": "The Shifting Blade",
      "description": "A runic greatsword that can reconfigure its elemental affinity. A gift from Phaidros.",
      "category": "greatsword",
      "slot": "weapon",
      "stat_bonuses": { "strength": 2 },
      "charges": 3,
      "granted_skills": ["edge_shift", "gout_of_flame", "luminous_tines", "frozen_thrust", "infernal_incarnate"],
      "type": "glyphion"
    }
  ]
}
```

**Step 2: Create devices.json**

```json
{
  "equipment": [
    {
      "id": "tactical_chronometer",
      "name": "Tactical Chronometer",
      "description": "A precision device that manipulates turn order.",
      "category": "device",
      "slot": "accessory",
      "stat_bonuses": {},
      "charges": 2,
      "granted_skills": [],
      "type": "glyphion"
    },
    {
      "id": "poison_vial",
      "name": "Poison Vial",
      "description": "A vial of potent poison. Apply to weapons to envenom attacks.",
      "category": "consumable_device",
      "slot": "accessory",
      "stat_bonuses": {},
      "charges": 1,
      "granted_skills": ["poison_coating"],
      "type": "device"
    },
    {
      "id": "rheas_tears_vial",
      "name": "Rhea's Tears Vial",
      "description": "A vial of Rhea's Tears. Apply to weapons to cause bleeding.",
      "category": "consumable_device",
      "slot": "accessory",
      "stat_bonuses": {},
      "charges": 1,
      "granted_skills": ["razor_edge"],
      "type": "device"
    }
  ]
}
```

**Step 3: Create armor.json**

```json
{
  "equipment": [
    {
      "id": "earth_gauntlets",
      "name": "Earth Gauntlets",
      "description": "Ancient gauntlets imbued with the power of the earth.",
      "category": "gauntlet",
      "slot": "weapon",
      "stat_bonuses": { "vigor": 1, "strength": 1 },
      "charges": 4,
      "granted_skills": ["the_wall", "earthquake", "pitfall", "stonefist"],
      "type": "glyphion"
    }
  ]
}
```

**Step 4: Commit equipment data files**

```bash
git add godot/data/equipment/weapons.json godot/data/equipment/devices.json godot/data/equipment/armor.json
git commit -m "feat: add equipment data files with granted skills"
```

---

### Task 3: Update party.json with Equipment and Proficiencies

**Files:**
- Modify: `godot/data/characters/party.json`

**Step 1: Update party.json**

Add `equipment_proficiencies` and `equipment` fields to each character. Update `starting_abilities` to reference new innate skill IDs (remove skills that will now come from equipment or other role files).

Replace the entire file content with:

```json
{
  "_FIXME": "Values need tweaking - these are placeholder stats for vertical slice",
  "characters": [
    {
      "id": "cyrus",
      "name": "Cyrus",
      "title": "The Seeker",
      "description": "A warrior who harnesses entropic blade techniques and elemental weapon enhancement.",
      "base_stats": {
        "vigor": 6,
        "strength": 7,
        "dexterity": 6,
        "resonance": 5,
        "agility": 6
      },
      "equipment_proficiencies": ["greatsword", "longsword", "device"],
      "equipment": ["shifting_blade", "tactical_chronometer"],
      "starting_abilities": ["basic_attack", "wide_swing", "stance_of_pitch", "raging_blossom", "flat_swing", "resolve_break", "northern_gale", "southern_breeze", "break_stock"],
      "burst_mode": {
        "name": "Elemental Mastery",
        "duration": 5,
        "effects": {
          "damage_multiplier": 1.5,
          "speed_bonus": 0.4,
          "special": "all_attacks_gain_random_element"
        }
      },
      "roles": ["bladewarden", "synergist"]
    },
    {
      "id": "vaughn",
      "name": "Vaughn",
      "title": "The Hawk",
      "description": "A tactical rogue specializing in debuffs and team leadership.",
      "base_stats": {
        "vigor": 5,
        "strength": 6,
        "dexterity": 8,
        "resonance": 4,
        "agility": 8
      },
      "equipment_proficiencies": ["dagger", "shortsword", "consumable_device", "gadget"],
      "equipment": ["poison_vial", "rheas_tears_vial"],
      "starting_abilities": ["basic_attack", "hamstring", "commotion", "leadership", "sever_tendons", "constant_flurry", "hook", "falcon_strike", "deduce_vulnerability", "peak_efficiency"],
      "burst_mode": {
        "name": "Master Tactician",
        "duration": 5,
        "effects": {
          "crit_rate_bonus": 0.45,
          "speed_bonus": 0.5,
          "special": "allies_gain_extra_action"
        }
      },
      "roles": ["shadowfang", "warcrier"]
    },
    {
      "id": "phaidros",
      "name": "Phaidros",
      "title": "Second Gnosis",
      "description": "An earth guardian who excels at protecting allies and controlling the battlefield.",
      "base_stats": {
        "vigor": 9,
        "strength": 7,
        "dexterity": 4,
        "resonance": 6,
        "agility": 4
      },
      "equipment_proficiencies": ["gauntlet", "fist", "heavy_armor"],
      "equipment": ["earth_gauntlets"],
      "starting_abilities": ["basic_attack", "one_two", "ironflesh", "derisive_snort", "ready_stance", "protective_instinct", "intercede", "again_with_vigor", "uppercut", "headclap", "smash", "thunderfist", "striking_tips", "unerring_menace"],
      "burst_mode": {
        "name": "Mountain King",
        "duration": 6,
        "effects": {
          "damage_reduction": 0.7,
          "damage_multiplier": 1.4,
          "special": "immune_to_forced_movement"
        }
      },
      "roles": ["ironskin", "geovant"]
    }
  ]
}
```

**Step 2: Clean up core_skills.json**

Remove `leadership` from `core_skills.json` (it's now in `warcrier_skills.json`). Remove `hamstring` (now in shadowfang but keep existing since it matches). Remove `ironflesh` and `derisive_snort` and `shield_bash` (now in ironskin or stay as generic). Actually: keep all existing skills in core_skills.json for backward compatibility with enemies. Only `leadership` needs to move since it's explicitly Vaughn's warcrier skill now.

Remove the `leadership` entry from `core_skills.json`.

**Step 3: Commit**

```bash
git add godot/data/characters/party.json godot/data/skills/core_skills.json
git commit -m "feat: update party.json with equipment/proficiencies, move leadership to warcrier"
```

---

### Task 4: Update DataLoader to Merge All Skill Files and Load Equipment

**Files:**
- Modify: `godot/scripts/data/data_loader.gd`

**Step 1: Update `load_skills()` to glob all skill JSON files**

Replace the existing `load_skills()` method and add equipment loading:

```gdscript
## Load all skill definitions from all JSON files in skills/ directory
static func load_skills() -> Dictionary:
	var skills_by_id = {}
	var skills_dir = DATA_PATH + "skills/"
	var dir = DirAccess.open(skills_dir)
	if dir == null:
		push_error("Cannot open skills directory: " + skills_dir)
		return skills_by_id

	dir.list_dir_begin()
	var file_name = dir.get_next()
	while file_name != "":
		if not dir.current_is_dir() and file_name.ends_with(".json"):
			var data = _load_json_file(skills_dir + file_name)
			if data.has("skills"):
				for skill in data.skills:
					skills_by_id[skill.id] = skill
		file_name = dir.get_next()
	dir.list_dir_end()
	return skills_by_id


## Load all equipment definitions from all JSON files in equipment/ directory
static func load_equipment() -> Dictionary:
	var equipment_by_id = {}
	var equip_dir = DATA_PATH + "equipment/"
	var dir = DirAccess.open(equip_dir)
	if dir == null:
		# Equipment dir may not exist yet - that's OK
		return equipment_by_id

	dir.list_dir_begin()
	var file_name = dir.get_next()
	while file_name != "":
		if not dir.current_is_dir() and file_name.ends_with(".json"):
			var data = _load_json_file(equip_dir + file_name)
			if data.has("equipment"):
				for item in data.equipment:
					equipment_by_id[item.id] = item
		file_name = dir.get_next()
	dir.list_dir_end()
	return equipment_by_id


## Resolve a character's full ability list: starting_abilities + equipment granted_skills
static func resolve_character_abilities(character: Dictionary, equipment_db: Dictionary) -> Array:
	var abilities: Array = []

	# Add innate starting abilities
	for ability_id in character.get("starting_abilities", []):
		if ability_id not in abilities:
			abilities.append(ability_id)

	# Add equipment-granted skills
	for equip_id in character.get("equipment", []):
		var equip = equipment_db.get(equip_id, {})
		for skill_id in equip.get("granted_skills", []):
			if skill_id not in abilities:
				abilities.append(skill_id)

	return abilities


## Check if a character can equip an item based on proficiencies
static func can_equip(character: Dictionary, equipment_item: Dictionary) -> bool:
	var proficiencies = character.get("equipment_proficiencies", [])
	var category = equipment_item.get("category", "")
	return category in proficiencies
```

**Step 2: Commit**

```bash
git add godot/scripts/data/data_loader.gd
git commit -m "feat: DataLoader loads all skill files + equipment with ability resolution"
```

---

### Task 5: Update CombatManager to Use Equipment-Resolved Abilities

**Files:**
- Modify: `godot/scripts/presentation/combat/combat_manager.gd`

**Step 1: Add equipment data loading and ability resolution in `_ready()`**

In the `_ready()` function, after `skills_data = DataLoaderClass.load_skills()` (line ~169), add:

```gdscript
	# Load equipment data
	var equipment_data: Dictionary = DataLoaderClass.load_equipment()
```

Store `equipment_data` as a class member variable. Add near line 55:

```gdscript
# Equipment data (loaded once)
var equipment_data: Dictionary = {}
```

**Step 2: Update `_load_units_from_encounter()` to resolve abilities from equipment**

After a party member is loaded (around line 410, after `all_units[member["id"]] = member`), add ability resolution:

```gdscript
		# Resolve abilities from starting_abilities + equipment
		member["abilities"] = DataLoaderClass.resolve_character_abilities(member, equipment_data)
```

This replaces the raw `starting_abilities` field with the full resolved list.

**Step 3: Update `_hot_reload_data()` to also reload equipment**

In `_hot_reload_data()`, after reloading skills, add:

```gdscript
	equipment_data = DataLoaderClass.load_equipment()
```

And re-resolve abilities for all ally units:

```gdscript
	# Re-resolve abilities for allies
	for unit_id in all_units:
		var unit = all_units[unit_id]
		if unit.get("is_ally", true):
			unit["abilities"] = DataLoaderClass.resolve_character_abilities(unit, equipment_data)
```

**Step 4: Commit**

```bash
git add godot/scripts/presentation/combat/combat_manager.gd
git commit -m "feat: combat manager resolves abilities from equipment at load time"
```

---

### Task 6: Implement Multi-Hit Damage in CombatManager

**Files:**
- Modify: `godot/scripts/presentation/combat/combat_manager.gd`

**Step 1: Update `_execute_skill()` to handle `hits` field**

In `_execute_skill()`, replace the single-damage block (lines ~924-988) with multi-hit support. When `skill.damage.hits > 1`, loop the damage calculation N times:

```gdscript
	# Handle damage
	if skill.has("damage"):
		var hit_count = skill.damage.get("hits", 1)

		# Check for multi_hit_bonus from combat_flow status
		if hit_count > 1 and status_manager.has_status(user.get("id", ""), "combat_flow"):
			var bonus_data = status_manager.get_status_data(user.get("id", ""), "combat_flow")
			hit_count += bonus_data.get("multi_hit_bonus", 0)

		# Check for pitched_stance (double damage on next attack)
		var stance_mult = 1.0
		if status_manager.has_status(user.get("id", ""), "pitched_stance"):
			stance_mult = 2.0
			status_manager.remove_status(user.get("id", ""), "pitched_stance")
			_log_action("  Stance of Pitch activates! 2x damage!", Color(1.0, 0.9, 0.2))

		var total_damage = 0
		for hit_i in range(hit_count):
			var result = DamageCalculatorClass.calculate_damage(skill, user, target)

			# Apply stance multiplier
			result.damage = int(ceil(result.damage * stance_mult))

			# Apply tile environment bonuses (same as before)
			var attacker_pos = user.get("grid_position", Vector2i(0, 0))
			var attacker_tile_bonuses = tile_env_manager.get_bonuses_for_unit(user.get("id", ""), attacker_pos)
			if attacker_tile_bonuses.get("damage_mult", 0.0) > 0.0:
				result.damage = int(ceil(result.damage * (1.0 + attacker_tile_bonuses["damage_mult"])))

			var defender_pos = target.get("grid_position", Vector2i(0, 0))
			var defender_tile_bonuses = tile_env_manager.get_bonuses_for_unit(target.get("id", ""), defender_pos)
			if defender_tile_bonuses.get("damage_reduction", 0.0) > 0.0:
				result.damage = int(floor(result.damage * (1.0 - defender_tile_bonuses["damage_reduction"])))

			# Apply damage reduction from status effects
			var reductions = status_manager.get_damage_reductions(target.get("id", ""))
			if not reductions.is_empty():
				result.damage = DamageCalculatorClass.apply_damage_reduction(
					result.damage, result.damage_type, reductions
				)

			_apply_damage(target, result.damage)
			total_damage += result.damage

			# Floating text per hit
			var float_color = Color.WHITE
			var large = false
			if result.is_critical:
				float_color = Color(1.0, 0.9, 0.1)
				large = true
			elif result.effectiveness > 1.0:
				float_color = Color(1.0, 0.3, 0.3)
			elif result.effectiveness < 1.0:
				float_color = Color(0.6, 0.6, 0.6)

			_spawn_floating_text(str(result.damage), float_color, target, large)

			# Flash target
			var tid = target.get("id", "")
			if unit_visuals.has(tid) and is_instance_valid(unit_visuals[tid]):
				unit_visuals[tid].flash_damage()

			# Small delay between hits for visual feedback
			if hit_count > 1 and hit_i < hit_count - 1:
				await get_tree().create_timer(0.25).timeout

			# Stop hitting if target is defeated
			if target.get("current_hp", 0) <= 0:
				break

		var hit_text = " (%d hits)" % hit_count if hit_count > 1 else ""
		status_label.text = "%s uses %s on %s for %d total damage!%s" % [
			user.get("name", "?"), skill.get("name", "Attack"), target.get("name", "?"), total_damage, hit_text
		]
		_log_action("%s -> %s: %s for %d dmg%s" % [user.get("name", "?"), target.get("name", "?"), skill.get("name", "Attack"), total_damage, hit_text],
			Color(0.7, 0.9, 1.0) if user.get("is_ally", true) else Color(1.0, 0.7, 0.7))

		EventBus.unit_damaged.emit(target.get("id", ""), total_damage, skill.damage.get("type", "physical"))
```

**Step 2: Commit**

```bash
git add godot/scripts/presentation/combat/combat_manager.gd
git commit -m "feat: implement multi-hit damage and stance of pitch activation"
```

---

### Task 7: Implement Forced Movement Effects

**Files:**
- Modify: `godot/scripts/presentation/combat/combat_manager.gd`

**Step 1: Add forced movement handler**

Add a new function after `_apply_skill_effect()`:

```gdscript
## Handle forced movement effects (push up/down/toward/away)
func _apply_forced_movement(effect: Dictionary, user: Dictionary, target: Dictionary) -> void:
	var direction = effect.get("direction", "")
	var distance = effect.get("distance", 1)
	var target_pos: Vector2i = target.get("grid_position", Vector2i(0, 0))
	var user_pos: Vector2i = user.get("grid_position", Vector2i(0, 0))
	var new_pos = target_pos

	# Check if target has braced status (negates forced movement)
	if status_manager.has_status(target.get("id", ""), "braced"):
		var braced_data = status_manager.get_status_data(target.get("id", ""), "braced")
		if braced_data.get("negates_forced_movement", false):
			_log_action("  %s resists forced movement (Braced)!" % target.get("name", "?"), Color(0.8, 0.8, 0.2))
			return

	match direction:
		"up":
			new_pos = Vector2i(target_pos.x, max(0, target_pos.y - distance))
		"down":
			new_pos = Vector2i(target_pos.x, min(GRID_SIZE.y - 1, target_pos.y + distance))
		"away":
			# Push away from user (increase distance between them)
			var dx = sign(target_pos.x - user_pos.x) if target_pos.x != user_pos.x else 1
			new_pos = Vector2i(clamp(target_pos.x + dx * distance, 0, GRID_SIZE.x - 1), target_pos.y)
		"toward_caster":
			# Pull toward user
			var dx = sign(user_pos.x - target_pos.x) if target_pos.x != user_pos.x else 0
			var dy = sign(user_pos.y - target_pos.y) if target_pos.y != user_pos.y else 0
			new_pos = Vector2i(
				clamp(target_pos.x + dx * distance, 0, GRID_SIZE.x - 1),
				clamp(target_pos.y + dy * distance, 0, GRID_SIZE.y - 1)
			)

	# Check if destination is occupied
	if new_pos != target_pos and not grid.has(new_pos):
		grid.erase(target_pos)
		target["grid_position"] = new_pos
		grid[new_pos] = target.get("id", "")
		_log_action("  %s pushed to (%d,%d)!" % [target.get("name", "?"), new_pos.x, new_pos.y], Color(0.9, 0.7, 0.3))
		EventBus.position_changed.emit(target.get("id", ""), target_pos, new_pos)
		_update_unit_visuals()
	elif new_pos != target_pos:
		_log_action("  %s can't be moved (blocked)!" % target.get("name", "?"), Color(0.6, 0.6, 0.6))
```

**Step 2: Add self-reposition handler (for Falcon Strike)**

```gdscript
## Handle self-repositioning after attack (e.g., Falcon Strike retreat)
func _apply_self_reposition(effect: Dictionary, user: Dictionary, target: Dictionary) -> void:
	var direction = effect.get("direction", "")
	var distance = effect.get("distance", 1)
	var user_pos: Vector2i = user.get("grid_position", Vector2i(0, 0))
	var target_pos: Vector2i = target.get("grid_position", Vector2i(0, 0))
	var new_pos = user_pos

	match direction:
		"away_from_target":
			var dx = sign(user_pos.x - target_pos.x) if user_pos.x != target_pos.x else -1
			new_pos = Vector2i(clamp(user_pos.x + dx * distance, 0, GRID_SIZE.x - 1), user_pos.y)

	if new_pos != user_pos and not grid.has(new_pos):
		grid.erase(user_pos)
		user["grid_position"] = new_pos
		grid[new_pos] = user.get("id", "")
		_log_action("  %s repositions to (%d,%d)" % [user.get("name", "?"), new_pos.x, new_pos.y], Color(0.7, 0.9, 0.7))
		EventBus.position_changed.emit(user.get("id", ""), user_pos, new_pos)
		_update_unit_visuals()
```

**Step 3: Wire into `_apply_skill_effect()`**

Add new cases in the `match effect_type:` block:

```gdscript
		"forced_movement":
			_apply_forced_movement(effect, user, target)

		"self_reposition":
			await get_tree().create_timer(0.3).timeout
			_apply_self_reposition(effect, user, target)
```

**Step 4: Commit**

```bash
git add godot/scripts/presentation/combat/combat_manager.gd
git commit -m "feat: implement forced movement (push/pull) and self-reposition effects"
```

---

### Task 8: Implement Healing Effect

**Files:**
- Modify: `godot/scripts/presentation/combat/combat_manager.gd`

**Step 1: Add healing handler in `_execute_skill()`**

After the damage block and before the effect block, add:

```gdscript
	# Handle healing
	if skill.has("healing"):
		var healing_data = skill.healing
		var heal_amount = 0
		if healing_data.has("base_percent"):
			var heal_target = user if healing_data.get("target", "self") == "self" else target
			heal_amount = int(ceil(heal_target.get("max_hp", 100) * healing_data.base_percent))
		else:
			heal_amount = healing_data.get("base", 0)
			var scaling_stat = healing_data.get("stat_scaling", "")
			if scaling_stat != "":
				var stat_val = user.get("base_stats", {}).get(scaling_stat, 5)
				heal_amount = int(ceil(heal_amount * (1.0 + stat_val * 0.15)))

		var heal_target = user if skill.get("targeting", {}).get("type", "") == "self" else target
		heal_target["current_hp"] = min(heal_target.get("max_hp", 100), heal_target.get("current_hp", 0) + heal_amount)
		_spawn_floating_text("+%d" % heal_amount, Color(0.3, 1.0, 0.3), heal_target, false)
		_log_action("  %s heals for %d HP!" % [heal_target.get("name", "?"), heal_amount], Color(0.3, 1.0, 0.3))
		status_label.text = "%s heals for %d HP!" % [heal_target.get("name", "?"), heal_amount]
```

**Step 2: Commit**

```bash
git add godot/scripts/presentation/combat/combat_manager.gd
git commit -m "feat: implement healing effects (flat and percent-based)"
```

---

### Task 9: Implement Break Stock (Spend-All-MP Ultimate)

**Files:**
- Modify: `godot/scripts/presentation/combat/combat_manager.gd`

**Step 1: Handle `special.type == "spend_all_mp"` in `_execute_skill()`**

Before the damage calculation, check for the spend_all_mp special:

```gdscript
	# Handle spend_all_mp special (Break Stock)
	var special_hit_count = 0
	if skill.has("special") and skill.special.get("type", "") == "spend_all_mp":
		var mp_available = user.get("current_mp", 0)
		user["current_mp"] = 0
		special_hit_count = max(2, int(mp_available / 2))
		_log_action("  %s spends all %d MP! (%d hits)" % [user.get("name", "?"), mp_available, special_hit_count], Color(1.0, 0.85, 0.2))
```

Then use `special_hit_count` to override the hit count when it's > 0:

```gdscript
		var hit_count = skill.damage.get("hits", 1)
		if special_hit_count > 0:
			hit_count = special_hit_count
```

**Step 2: Commit**

```bash
git add godot/scripts/presentation/combat/combat_manager.gd
git commit -m "feat: implement spend_all_mp ultimate (Break Stock)"
```

---

### Task 10: Implement Reveal Effect (Deduce Vulnerability)

**Files:**
- Modify: `godot/scripts/presentation/combat/combat_manager.gd`

**Step 1: Add `revealed` tracking to units**

Add a case in `_apply_skill_effect()`:

```gdscript
		"reveal":
			target["revealed"] = true
			var weaknesses = target.get("weaknesses", [])
			var resistances = target.get("resistances", [])
			var weak_text = ", ".join(weaknesses) if not weaknesses.is_empty() else "none"
			var resist_text = ", ".join(resistances) if not resistances.is_empty() else "none"
			_log_action("  Revealed %s! Weak: %s | Resist: %s" % [target.get("name", "?"), weak_text, resist_text], Color(0.9, 0.9, 0.3))
			status_label.text = "%s's weaknesses revealed!" % target.get("name", "?")
```

This sets a `revealed` flag on the unit dict. The UI can check this to show/hide weakness info.

**Step 2: Commit**

```bash
git add godot/scripts/presentation/combat/combat_manager.gd
git commit -m "feat: implement reveal effect for Deduce Vulnerability"
```

---

### Task 11: Implement Equipment Charge Tracking

**Files:**
- Modify: `godot/scripts/presentation/combat/combat_manager.gd`
- Modify: `godot/scripts/presentation/combat/skill_panel.gd`

**Step 1: Initialize equipment charges at combat start**

In `_load_units_from_encounter()`, after resolving abilities, initialize equipment charges:

```gdscript
		# Initialize equipment charges
		var equip_charges = {}
		for equip_id in member.get("equipment", []):
			var equip = equipment_data.get(equip_id, {})
			if equip.get("charges", 0) > 0:
				equip_charges[equip_id] = equip.charges
		member["equipment_charges"] = equip_charges
```

**Step 2: Build skill-to-equipment mapping**

Add a helper that maps skill IDs to the equipment that grants them:

```gdscript
## Find which equipment grants a skill for a unit
func _get_skill_equipment(unit: Dictionary, skill_id: String) -> String:
	for equip_id in unit.get("equipment", []):
		var equip = equipment_data.get(equip_id, {})
		if skill_id in equip.get("granted_skills", []):
			return equip_id
	return ""
```

**Step 3: Deduct equipment charges in `_on_target_selected()`**

After deducting MP, add charge deduction:

```gdscript
	# Deduct equipment charges if needed
	var charge_cost = selected_skill.get("equipment_charge_cost", 0)
	if charge_cost > 0:
		var equip_id = _get_skill_equipment(current_unit, selected_skill.get("id", ""))
		if equip_id != "":
			var charges = current_unit.get("equipment_charges", {})
			charges[equip_id] = max(0, charges.get(equip_id, 0) - charge_cost)
			_log_action("  -%d charge from %s (%d remaining)" % [charge_cost, equipment_data.get(equip_id, {}).get("name", equip_id), charges.get(equip_id, 0)], Color(0.8, 0.6, 0.2))
```

**Step 4: Update skill_panel.gd to check equipment charges**

In `_populate_skill_list()`, add charge checking after the MP check:

```gdscript
		# Check equipment charges
		var charge_cost = skill.get("equipment_charge_cost", 0)
		if charge_cost > 0 and can_use:
			var has_charges = false
			for equip_id in current_unit.get("equipment", []):
				var equip = skills_data.get("_equipment", {}).get(equip_id, {})
				# Check unit's runtime equipment_charges dict
				var unit_charges = current_unit.get("equipment_charges", {})
				if unit_charges.get(equip_id, 0) >= charge_cost:
					has_charges = true
					break
			if not has_charges:
				can_use = false
				disable_reason = "No equipment charges"
```

Actually, a simpler approach: pass equipment_data to skill_panel. Update the `show_skills` signature:

```gdscript
func show_skills(unit: Dictionary, all_skills: Dictionary, all_units: Dictionary = {}, grid: Dictionary = {}, grid_size: Vector2i = Vector2i(10, 6), ap_system = null, equipment_db: Dictionary = {}) -> void:
```

Then in the charge check, look up the equipment from `equipment_db` to find if the skill's equipment has charges remaining.

**Step 5: Commit**

```bash
git add godot/scripts/presentation/combat/combat_manager.gd godot/scripts/presentation/combat/skill_panel.gd
git commit -m "feat: implement equipment charge tracking and UI disable for empty charges"
```

---

### Task 12: Implement DOT Processing (Burning/Poison)

**Files:**
- Modify: `godot/scripts/presentation/combat/combat_manager.gd`

**Step 1: Process DOT effects in `_end_turn()`**

After the status tick (line ~1141), add DOT damage processing:

```gdscript
	# Process DOT damage before ticking durations
	var dot_statuses = ["poisoned", "burning"]
	for status_name in dot_statuses:
		if status_manager.has_status(current_unit.id, status_name):
			var status_data = status_manager.get_status_data(current_unit.id, status_name)
			var dot_damage = status_data.get("damage_per_turn", 0)
			if dot_damage > 0:
				_apply_damage(current_unit, dot_damage)
				var dot_color = Color(0.6, 0.2, 0.8) if status_name == "poisoned" else Color(1.0, 0.4, 0.1)
				_spawn_floating_text(str(dot_damage), dot_color, current_unit, false)
				_log_action("  %s takes %d %s damage" % [current_unit.get("name", "?"), dot_damage, status_name], dot_color)
```

**Step 2: Commit**

```bash
git add godot/scripts/presentation/combat/combat_manager.gd
git commit -m "feat: implement DOT processing for burning and poison status effects"
```

---

### Task 13: Implement Apply Chance for Status Effects

**Files:**
- Modify: `godot/scripts/presentation/combat/combat_manager.gd`

**Step 1: Check `apply_chance` in `_apply_skill_effect()`**

At the top of the debuff case, before applying the status:

```gdscript
		"debuff", "enemy_debuff":
			var apply_chance = effect.get("apply_chance", 1.0)
```

Then wrap the apply logic: if `randf() > apply_chance`, log a miss instead:

```gdscript
			if apply_chance < 1.0 and randf() > apply_chance:
				_log_action("  %s resists %s!" % [target.get("name", "?"), status_name], Color(0.6, 0.6, 0.6))
			else:
				# existing apply logic
```

**Step 2: Commit**

```bash
git add godot/scripts/presentation/combat/combat_manager.gd
git commit -m "feat: implement apply_chance for probabilistic status effects"
```

---

### Task 14: Wire StatusEffectManager to Store New Effect Fields

**Files:**
- Modify: `godot/scripts/logic/combat/status_effect_manager.gd`

**Step 1: Extend `apply_status()` to copy new fields**

In the "Copy relevant data" section (~line 50-61), add copies for new fields:

```gdscript
	if effect_data.has("damage_per_turn"):
		new_effect["damage_per_turn"] = effect_data.damage_per_turn
	if effect_data.has("damage_multiplier"):
		new_effect["damage_multiplier"] = effect_data.damage_multiplier
	if effect_data.has("consumes_on_attack"):
		new_effect["consumes_on_attack"] = effect_data.consumes_on_attack
	if effect_data.has("consumes_on_hit"):
		new_effect["consumes_on_hit"] = effect_data.consumes_on_hit
	if effect_data.has("consumes_on_skill"):
		new_effect["consumes_on_skill"] = effect_data.consumes_on_skill
	if effect_data.has("negates_forced_movement"):
		new_effect["negates_forced_movement"] = effect_data.negates_forced_movement
	if effect_data.has("multi_hit_bonus"):
		new_effect["multi_hit_bonus"] = effect_data.multi_hit_bonus
	if effect_data.has("mp_cost_reduction"):
		new_effect["mp_cost_reduction"] = effect_data.mp_cost_reduction
	if effect_data.has("burst_gauge_bonus"):
		new_effect["burst_gauge_bonus"] = effect_data.burst_gauge_bonus
	if effect_data.has("counter_on_ally_hit"):
		new_effect["counter_on_ally_hit"] = effect_data.counter_on_ally_hit
	if effect_data.has("redirect_damage_to"):
		new_effect["redirect_damage_to"] = effect_data.redirect_damage_to
	if effect_data.has("prevents_movement"):
		new_effect["prevents_movement"] = effect_data.prevents_movement
```

**Step 2: Commit**

```bash
git add godot/scripts/logic/combat/status_effect_manager.gd
git commit -m "feat: StatusEffectManager stores new effect fields for all skill types"
```

---

### Task 15: Update Hot Reload to Include Equipment

**Files:**
- Modify: `godot/scripts/presentation/combat/combat_manager.gd`

**Step 1: Update `_hot_reload_data()`**

In `_hot_reload_data()`, reload equipment and re-resolve abilities for all ally units. After `skills_data = DataLoaderClass.load_skills()`, add:

```gdscript
	equipment_data = DataLoaderClass.load_equipment()

	# Re-resolve abilities for ally units
	for unit_id in all_units:
		var unit = all_units[unit_id]
		if unit.get("is_ally", true):
			unit["abilities"] = DataLoaderClass.resolve_character_abilities(unit, equipment_data)
```

**Step 2: Commit**

```bash
git add godot/scripts/presentation/combat/combat_manager.gd
git commit -m "feat: hot reload includes equipment data and re-resolves abilities"
```

---

### Task 16: Clean Up core_skills.json - Remove Relocated Skills

**Files:**
- Modify: `godot/data/skills/core_skills.json`

**Step 1: Remove leadership from core_skills.json**

Remove the leadership skill entry (it now lives in `warcrier_skills.json`). Keep all other skills since enemies may reference them.

**Step 2: Commit**

```bash
git add godot/data/skills/core_skills.json
git commit -m "chore: remove leadership from core_skills (now in warcrier_skills)"
```

---

### Task 17: Integration Test - Launch Combat and Verify

**Step 1: Run the Godot project**

Launch the combat demo and verify:
- All three characters show their full skill lists in the skill panel
- New skills (Wide Swing, Raging Blossom, One-Two, etc.) appear and can be selected
- Multi-hit skills (Raging Blossom 3 hits, One-Two 2 hits) show multiple floating numbers
- Forced movement skills (Northern Gale, Southern Breeze, Hook) move enemies on the grid
- Falcon Strike hits then retreats the user
- Healing (Again with Vigor) restores HP
- Buffs (Stance of Pitch, Leadership) apply status effects
- Debuffs (Flat Swing, Sever Tendons, Commotion) reduce enemy stats
- Equipment-granted skills appear for characters with that equipment
- Equipment charge skills (Earthquake, Stonefist, etc.) deduct charges and disable when empty
- DOT effects (Striking Tips burning, Poison Coating poison) tick damage at turn end
- Hot reload (F5) picks up JSON changes

**Step 2: Fix any issues found**

**Step 3: Final commit**

```bash
git add -A
git commit -m "feat: complete skill prototype implementation for Cyrus, Vaughn, Phaidros"
```

---

## File Summary

| File | Action | Description |
|------|--------|-------------|
| `godot/data/skills/bladewarden_skills.json` | Create | 8 Cyrus innate sword skills |
| `godot/data/skills/synergist_skills.json` | Create | 5 elemental weapon skills (Shifting Blade) |
| `godot/data/skills/shadowfang_skills.json` | Create | 7 Vaughn debuff/precision skills |
| `godot/data/skills/warcrier_skills.json` | Create | 1 leadership skill (moved from core) |
| `godot/data/skills/ironskin_skills.json` | Create | 11 Phaidros tank/melee skills |
| `godot/data/skills/geovant_skills.json` | Create | 4 earth magic skills (Earth Gauntlets) |
| `godot/data/equipment/weapons.json` | Create | Shifting Blade |
| `godot/data/equipment/devices.json` | Create | Chronometer, Poison Vial, Rhea's Tears |
| `godot/data/equipment/armor.json` | Create | Earth Gauntlets |
| `godot/data/characters/party.json` | Modify | Add equipment, proficiencies, updated abilities |
| `godot/data/skills/core_skills.json` | Modify | Remove leadership (moved to warcrier) |
| `godot/scripts/data/data_loader.gd` | Modify | Glob all skill files, load equipment, resolve abilities |
| `godot/scripts/logic/combat/status_effect_manager.gd` | Modify | Store new effect fields |
| `godot/scripts/presentation/combat/combat_manager.gd` | Modify | Multi-hit, forced movement, healing, DOT, equipment charges, reveal, stance |
| `godot/scripts/presentation/combat/skill_panel.gd` | Modify | Equipment charge display/disable |
