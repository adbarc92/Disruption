# Role-Based Skills + Slot-Based Equipment Refactor

## Summary

Refactor the party data structure to derive character abilities from roles and equipment rather than hardcoded lists. Consolidate scattered skill and equipment files. Move to explicit slot-based equipment with a device limit per character.

## Goals

- Abilities come from roles and equipment, not hardcoded `starting_abilities` lists
- Roles own their skill lists (not the other way around)
- Equipment uses explicit slots: weapon, helmet, chest, gloves, boots, accessory_1, accessory_2
- Device limit (equipment with skills/charges) per character, currently 3
- Consolidated data files instead of scattered per-role/per-type files

## Data Files

### `data/roles/roles.json` — Role-to-skill mapping

Single source of truth for which skills each role grants. Universal skills listed under a `"universal"` pseudo-role that all characters receive.

```json
{
  "roles": [
    {
      "id": "universal",
      "name": "Universal",
      "description": "Skills available to all characters.",
      "skills": ["basic_attack", "defend", "shove"]
    },
    {
      "id": "bladewarden",
      "name": "Bladewarden",
      "description": "Sword techniques focused on positioning and raw damage.",
      "skills": ["wide_swing", "raging_blossom", "flat_swing", "stance_of_pitch",
                 "resolve_break", "northern_gale", "southern_breeze", "break_stock",
                 "true_strike", "heavy_swing", "cleave"]
    },
    {
      "id": "shadowfang",
      "name": "Shadowfang",
      "description": "Precision strikes, debuffs, and tactical disruption.",
      "skills": ["hamstring", "sever_tendons", "commotion", "hook", "falcon_strike",
                 "deduce_vulnerability", "peak_efficiency", "constant_flurry",
                 "poison_coating", "razor_edge", "poison_strike"]
    },
    {
      "id": "warcrier",
      "name": "Warcrier",
      "description": "Leadership and party-wide inspiration.",
      "skills": ["leadership"]
    },
    {
      "id": "ironskin",
      "name": "Ironskin",
      "description": "Defensive techniques, tanking, and brawling.",
      "skills": ["ready_stance", "protective_instinct", "intercede", "again_with_vigor",
                 "one_two", "uppercut", "headclap", "smash", "thunderfist",
                 "striking_tips", "unerring_menace", "ironflesh", "derisive_snort", "bash"]
    },
    {
      "id": "geovant",
      "name": "Geovant",
      "description": "Earth magic and terrain manipulation.",
      "skills": ["the_wall", "earthquake", "pitfall", "stonefist",
                 "ignite_ground", "frost_sheet"]
    }
  ]
}
```

### `data/skills/skills.json` — Consolidated player/universal skills

All skills from the former 7 files (core_skills.json, bladewarden_skills.json, synergist_skills.json, shadowfang_skills.json, warcrier_skills.json, ironskin_skills.json, geovant_skills.json) merged into one file. The `roles` tags are stripped from every skill — skills are pure definitions (damage, targeting, effects). The role relationship lives in roles.json.

### `data/skills/enemy_skills.json` — Enemy-only skills

Skills extracted from core_skills that are only used by enemies: `frenzy`, `venom_spit`, `corrupting_aura`, `heal_self`, `weaken`, `ignite`, `dark_bolt`, `lightning_bolt`. Loaded separately by enemy data loading, not included in player ability resolution.

### `data/equipment/equipment.json` — Consolidated slot-based equipment

Replaces `weapons.json`, `devices.json`, `armor.json`. Each item has an explicit `slot` field. Equipment with `granted_skills` or `charges` counts as a "device" toward the per-character device limit.

Equipment items:

| ID | Slot | Category | Owner | Device? |
|----|------|----------|-------|---------|
| shifting_blade | weapon | greatsword | Cyrus | Yes (3 charges, 5 skills) |
| paired_shortswords | weapon | shortsword | Vaughn | No |
| earth_gauntlets | weapon | gauntlet | Phaidros | Yes (4 charges, 4 skills) |
| wooden_helmet | helmet | — | All | No |
| wooden_chestplate | chest | — | All | No |
| wooden_gauntlets | gloves | — | All | No |
| wooden_boots | boots | — | All | No |
| tactical_chronometer | accessory | — | Cyrus | Yes (2 charges) |
| poison_vial | accessory | — | Vaughn | Yes (1 charge, 2 skills) |
| hookshot | accessory | — | Vaughn | Yes (3 charges, 1 skill) |

### `data/characters/party.json` — Slot-based equipment, no starting_abilities

Equipment is a dictionary keyed by slot. Each character has `max_devices: 3`.

```json
{
  "characters": [
    {
      "id": "cyrus",
      "name": "Cyrus",
      "title": "The Seeker",
      "description": "A warrior who harnesses entropic blade techniques and elemental weapon enhancement.",
      "base_stats": { "vigor": 6, "strength": 7, "dexterity": 6, "resonance": 5, "agility": 6 },
      "equipment_proficiencies": ["greatsword", "longsword", "device"],
      "max_devices": 3,
      "equipment": {
        "weapon": "shifting_blade",
        "helmet": "wooden_helmet",
        "chest": "wooden_chestplate",
        "gloves": "wooden_gauntlets",
        "boots": "wooden_boots",
        "accessory_1": "tactical_chronometer",
        "accessory_2": null
      },
      "burst_mode": { "name": "Elemental Mastery", "duration": 5, "effects": { "damage_multiplier": 1.5, "speed_bonus": 0.4, "special": "all_attacks_gain_random_element" } },
      "roles": ["bladewarden"]
    },
    {
      "id": "vaughn",
      "name": "Vaughn",
      "title": "The Hawk",
      "description": "A tactical rogue specializing in debuffs and team leadership.",
      "base_stats": { "vigor": 5, "strength": 6, "dexterity": 8, "resonance": 4, "agility": 8 },
      "equipment_proficiencies": ["dagger", "shortsword", "consumable_device", "gadget"],
      "max_devices": 3,
      "equipment": {
        "weapon": "paired_shortswords",
        "helmet": "wooden_helmet",
        "chest": "wooden_chestplate",
        "gloves": "wooden_gauntlets",
        "boots": "wooden_boots",
        "accessory_1": "poison_vial",
        "accessory_2": "hookshot"
      },
      "burst_mode": { "name": "Master Tactician", "duration": 5, "effects": { "crit_rate_bonus": 0.45, "speed_bonus": 0.5, "special": "allies_gain_extra_action" } },
      "roles": ["shadowfang", "warcrier"]
    },
    {
      "id": "phaidros",
      "name": "Phaidros",
      "title": "Second Gnosis",
      "description": "An earth guardian who excels at protecting allies and controlling the battlefield.",
      "base_stats": { "vigor": 9, "strength": 7, "dexterity": 4, "resonance": 6, "agility": 4 },
      "equipment_proficiencies": ["gauntlet", "fist", "heavy_armor"],
      "max_devices": 3,
      "equipment": {
        "weapon": "earth_gauntlets",
        "helmet": "wooden_helmet",
        "chest": "wooden_chestplate",
        "gloves": "wooden_gauntlets",
        "boots": "wooden_boots",
        "accessory_1": null,
        "accessory_2": null
      },
      "burst_mode": { "name": "Mountain King", "duration": 6, "effects": { "damage_reduction": 0.7, "damage_multiplier": 1.4, "special": "immune_to_forced_movement" } },
      "roles": ["ironskin", "geovant"]
    }
  ]
}
```

## Ability Resolution Logic

`resolve_character_abilities(character, equipment_db, roles_db)`:

1. Collect skill IDs from the `"universal"` role in roles.json
2. For each role in the character's `roles` array, collect skill IDs from roles.json
3. For each equipped item (iterating slot values), collect `granted_skills` from equipment_db
4. Deduplicate and return

## Device Validation

`validate_equipment_devices(character, equipment_db)`:

1. Iterate all slot values in the character's equipment dict
2. Count items that have `granted_skills` or `charges`
3. Warn if count exceeds `max_devices`

## Code Changes

### `data_loader.gd`

- `load_skills()` — reads `skills.json` + `enemy_skills.json` instead of 7 files
- `load_equipment()` — reads single `equipment.json` instead of 3 files
- New `load_roles()` — reads roles.json, returns dictionary keyed by role ID
- `resolve_character_abilities()` — rewritten: universal role + character roles from roles.json + equipment granted_skills
- `get_skills_for_role()` — reads from roles.json instead of scanning skill tags
- New `validate_equipment_devices()` — checks device count against max_devices
- `can_equip()` — updated to work with slot-based equipment dict
- Equipment iteration throughout updated from array to dictionary (slot→id)

### `game_manager.gd`

- `_create_party_member_from_data()` — passes through slot-based equipment dict instead of array; no longer copies starting_abilities

### `combat_manager.gd`

- `_load_units_from_encounter()` — equipment iteration updated from array to dict; equipment charge initialization iterates slot values

## Files Created

- `data/roles/roles.json`
- `data/skills/skills.json`
- `data/skills/enemy_skills.json`
- `data/equipment/equipment.json`

## Files Deleted

- `data/skills/core_skills.json`
- `data/skills/bladewarden_skills.json`
- `data/skills/synergist_skills.json`
- `data/skills/shadowfang_skills.json`
- `data/skills/warcrier_skills.json`
- `data/skills/ironskin_skills.json`
- `data/skills/geovant_skills.json`
- `data/equipment/weapons.json`
- `data/equipment/devices.json`
- `data/equipment/armor.json`

## Future Considerations

- Role leveling: gate skills by role level (e.g., `"skills": {"1": [...], "2": [...]}`)
- Synergist role: removed for now, to be revisited
- Enemy skills: currently all under one file, will need per-enemy-type breakdown eventually
- `max_devices` could be modified by roles or progression
