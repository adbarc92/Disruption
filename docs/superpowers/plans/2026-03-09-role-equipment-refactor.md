# Role-Based Skills + Slot-Based Equipment Refactor

> **For agentic workers:** REQUIRED: Use superpowers:subagent-driven-development (if subagents available) or superpowers:executing-plans to implement this plan. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Refactor party data to derive abilities from roles and slot-based equipment instead of hardcoded lists, consolidating scattered data files.

**Architecture:** Roles own skill lists via `roles.json`. Equipment uses explicit slot-based assignment. Skills are pure definitions with no role tags. Ability resolution collects universal + role + equipment skills at runtime.

**Tech Stack:** GDScript (Godot 4), JSON data files

**Spec:** `docs/superpowers/specs/2026-03-09-role-equipment-refactor-design.md`

---

## Chunk 1: Data Files

### Task 1: Create `roles.json`

**Files:**
- Create: `godot/data/roles/roles.json`

- [ ] **Step 1: Create the roles directory and file**

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
      "skills": [
        "wide_swing", "raging_blossom", "flat_swing", "stance_of_pitch",
        "resolve_break", "northern_gale", "southern_breeze", "break_stock",
        "true_strike", "heavy_swing", "cleave"
      ]
    },
    {
      "id": "shadowfang",
      "name": "Shadowfang",
      "description": "Precision strikes, debuffs, and tactical disruption.",
      "skills": [
        "hamstring", "sever_tendons", "commotion", "hook", "falcon_strike",
        "deduce_vulnerability", "peak_efficiency", "constant_flurry",
        "poison_coating", "razor_edge", "poison_strike"
      ]
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
      "skills": [
        "ready_stance", "protective_instinct", "intercede", "again_with_vigor",
        "one_two", "uppercut", "headclap", "smash", "thunderfist",
        "striking_tips", "unerring_menace", "ironflesh", "derisive_snort", "bash"
      ]
    },
    {
      "id": "geovant",
      "name": "Geovant",
      "description": "Earth magic and terrain manipulation.",
      "skills": [
        "the_wall", "earthquake", "pitfall", "stonefist",
        "ignite_ground", "frost_sheet"
      ]
    }
  ]
}
```

- [ ] **Step 2: Commit**

```bash
git add godot/data/roles/roles.json
git commit -m "feat: add roles.json with role-to-skill mappings"
```

---

### Task 2: Create consolidated `skills.json`

Merge all player/universal skills from the 7 existing files into one. Strip `roles` tags from every skill. Strip `_CATEGORY` and `_COMMENT` metadata fields.

**Files:**
- Create: `godot/data/skills/skills.json`
- Reference (read-only, will be deleted later):
  - `godot/data/skills/core_skills.json`
  - `godot/data/skills/bladewarden_skills.json`
  - `godot/data/skills/synergist_skills.json`
  - `godot/data/skills/shadowfang_skills.json`
  - `godot/data/skills/warcrier_skills.json`
  - `godot/data/skills/ironskin_skills.json`
  - `godot/data/skills/geovant_skills.json`

- [ ] **Step 1: Read all 7 skill files and identify which skills go into `skills.json` vs `enemy_skills.json`**

Player/universal skills (for `skills.json`): every skill that is NOT tagged `["enemy"]` in the current `core_skills.json`. This includes all skills from the 6 role-specific files plus the non-enemy skills from `core_skills.json`.

Enemy skills (for `enemy_skills.json` in Task 3): `frenzy`, `venom_spit`, `corrupting_aura`, `heal_self`, `weaken`, `ignite`, `dark_bolt`, `lightning_bolt`.

- [ ] **Step 2: Create `godot/data/skills/skills.json`**

Consolidate all non-enemy skills into a single `{"skills": [...]}` array. For each skill:
- Remove the `"roles"` field entirely (role mapping now lives in `roles.json`)
- Remove `"_CATEGORY"` and `"_COMMENT"` fields
- Keep all other fields exactly as-is (damage, targeting, effects, etc.)

The final file should contain these skills (in this order):

From `core_skills.json` (non-enemy):
`basic_attack`, `defend`, `shove`, `grapple_pull`, `heavy_swing`, `true_strike`, `cleave`, `hamstring`, `poison_strike`, `ironflesh`, `derisive_snort`, `bash`, `ignite_ground`, `frost_sheet`

From `bladewarden_skills.json`:
`wide_swing`, `raging_blossom`, `flat_swing`, `stance_of_pitch`, `resolve_break`, `northern_gale`, `southern_breeze`, `break_stock`

From `synergist_skills.json`:
`edge_shift`, `gout_of_flame`, `luminous_tines`, `frozen_thrust`, `infernal_incarnate`

From `shadowfang_skills.json`:
`sever_tendons`, `commotion`, `hook`, `falcon_strike`, `deduce_vulnerability`, `peak_efficiency`, `constant_flurry`, `poison_coating`, `razor_edge`

From `warcrier_skills.json`:
`leadership`

From `ironskin_skills.json`:
`ready_stance`, `protective_instinct`, `intercede`, `again_with_vigor`, `one_two`, `uppercut`, `headclap`, `smash`, `thunderfist`, `striking_tips`, `unerring_menace`

From `geovant_skills.json`:
`the_wall`, `earthquake`, `pitfall`, `stonefist`

- [ ] **Step 3: Validate skill count**

The consolidated file should contain exactly 48 skills. Count them to verify.

- [ ] **Step 4: Commit**

```bash
git add godot/data/skills/skills.json
git commit -m "feat: consolidate all player skills into skills.json"
```

---

### Task 3: Create `enemy_skills.json`

**Files:**
- Create: `godot/data/skills/enemy_skills.json`

- [ ] **Step 1: Create the file with enemy-only skills**

Extract from current `core_skills.json` the 8 skills tagged `"roles": ["enemy"]`. Strip the `roles` and `_CATEGORY` fields:

`frenzy`, `venom_spit`, `corrupting_aura`, `heal_self`, `weaken`, `ignite`, `dark_bolt`, `lightning_bolt`

```json
{
  "skills": [
    { "id": "frenzy", ... },
    ...
  ]
}
```

- [ ] **Step 2: Commit**

```bash
git add godot/data/skills/enemy_skills.json
git commit -m "feat: extract enemy skills into enemy_skills.json"
```

---

### Task 4: Create consolidated `equipment.json`

**Files:**
- Create: `godot/data/equipment/equipment.json`
- Reference (read-only, will be deleted later):
  - `godot/data/equipment/weapons.json`
  - `godot/data/equipment/devices.json`
  - `godot/data/equipment/armor.json`

- [ ] **Step 1: Create the consolidated equipment file**

Merge all items from the 3 existing files. Add new items: `paired_shortswords`, `wooden_helmet`, `wooden_chestplate`, `wooden_gauntlets`, `wooden_boots`. Remove the `"type"` field (no more device/glyphion distinction). Ensure every item has a `"slot"` field.

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
      "granted_skills": ["edge_shift", "gout_of_flame", "luminous_tines", "frozen_thrust", "infernal_incarnate"]
    },
    {
      "id": "paired_shortswords",
      "name": "Paired Shortswords",
      "description": "A matched set of short blades for dual-wielding.",
      "category": "shortsword",
      "slot": "weapon",
      "stat_bonuses": { "dexterity": 1 }
    },
    {
      "id": "earth_gauntlets",
      "name": "Earth Gauntlets",
      "description": "Ancient gauntlets imbued with the power of the earth.",
      "category": "gauntlet",
      "slot": "weapon",
      "stat_bonuses": { "vigor": 1, "strength": 1 },
      "charges": 4,
      "granted_skills": ["the_wall", "earthquake", "pitfall", "stonefist"]
    },
    {
      "id": "wooden_helmet",
      "name": "Wooden Helmet",
      "description": "A simple helmet carved from hardwood.",
      "slot": "helmet",
      "stat_bonuses": { "vigor": 1 }
    },
    {
      "id": "wooden_chestplate",
      "name": "Wooden Chestplate",
      "description": "A basic chestplate of layered wood panels.",
      "slot": "chest",
      "stat_bonuses": { "vigor": 1 }
    },
    {
      "id": "wooden_gauntlets",
      "name": "Wooden Gauntlets",
      "description": "Simple hand guards made from shaped wood.",
      "slot": "gloves",
      "stat_bonuses": { "strength": 1 }
    },
    {
      "id": "wooden_boots",
      "name": "Wooden Boots",
      "description": "Sturdy wooden-soled boots.",
      "slot": "boots",
      "stat_bonuses": { "agility": 1 }
    },
    {
      "id": "tactical_chronometer",
      "name": "Tactical Chronometer",
      "description": "A precision device that manipulates turn order.",
      "slot": "accessory",
      "stat_bonuses": {},
      "charges": 2
    },
    {
      "id": "poison_vial",
      "name": "Poison Vial",
      "description": "A vial of potent poison. Apply to weapons to envenom attacks.",
      "slot": "accessory",
      "stat_bonuses": {},
      "charges": 1,
      "granted_skills": ["poison_coating", "poison_strike"]
    },
    {
      "id": "hookshot",
      "name": "Hookshot",
      "description": "A mechanical grappling device that pulls distant enemies close.",
      "slot": "accessory",
      "stat_bonuses": {},
      "charges": 3,
      "granted_skills": ["grapple_pull"]
    }
  ]
}
```

Note: `rheas_tears_vial` is dropped — it was removed from Vaughn's equipment by the user. If it should be kept as an available-but-unequipped item, add it back.

- [ ] **Step 2: Commit**

```bash
git add godot/data/equipment/equipment.json
git commit -m "feat: consolidate equipment into equipment.json with slot-based structure"
```

---

### Task 5: Update `party.json` to slot-based equipment

**Files:**
- Modify: `godot/data/characters/party.json`

- [ ] **Step 1: Rewrite party.json with slot-based equipment and max_devices**

```json
{
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
      "burst_mode": {
        "name": "Elemental Mastery",
        "duration": 5,
        "effects": {
          "damage_multiplier": 1.5,
          "speed_bonus": 0.4,
          "special": "all_attacks_gain_random_element"
        }
      },
      "roles": ["bladewarden"]
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

- [ ] **Step 2: Commit**

```bash
git add godot/data/characters/party.json
git commit -m "feat: convert party.json to slot-based equipment with max_devices"
```

---

### Task 6: Delete old data files

**Files:**
- Delete: `godot/data/skills/core_skills.json`
- Delete: `godot/data/skills/bladewarden_skills.json`
- Delete: `godot/data/skills/synergist_skills.json`
- Delete: `godot/data/skills/shadowfang_skills.json`
- Delete: `godot/data/skills/warcrier_skills.json`
- Delete: `godot/data/skills/ironskin_skills.json`
- Delete: `godot/data/skills/geovant_skills.json`
- Delete: `godot/data/equipment/weapons.json`
- Delete: `godot/data/equipment/devices.json`
- Delete: `godot/data/equipment/armor.json`

- [ ] **Step 1: Delete all old files**

```bash
git rm godot/data/skills/core_skills.json \
       godot/data/skills/bladewarden_skills.json \
       godot/data/skills/synergist_skills.json \
       godot/data/skills/shadowfang_skills.json \
       godot/data/skills/warcrier_skills.json \
       godot/data/skills/ironskin_skills.json \
       godot/data/skills/geovant_skills.json \
       godot/data/equipment/weapons.json \
       godot/data/equipment/devices.json \
       godot/data/equipment/armor.json
```

- [ ] **Step 2: Commit**

```bash
git commit -m "chore: remove old per-role skill files and per-type equipment files"
```

---

## Chunk 2: Code Changes

### Task 7: Update `data_loader.gd`

**Files:**
- Modify: `godot/scripts/data/data_loader.gd`

- [ ] **Step 1: Rewrite `load_skills()` (lines 22-43)**

Replace the multi-file loading with two files:

```gdscript
## Load all skill definitions (player + enemy)
static func load_skills() -> Dictionary:
	var skills_by_id = {}
	var skills_dir = DATA_PATH + "skills/"
	var skill_files = [
		"skills.json",
		"enemy_skills.json",
	]
	for file_name in skill_files:
		var path = skills_dir + file_name
		if not FileAccess.file_exists(path):
			continue
		var data = _load_json_file(path)
		if data.has("skills"):
			for skill in data.skills:
				skills_by_id[skill.id] = skill
	return skills_by_id
```

- [ ] **Step 2: Add `load_roles()` function**

Add after `load_skills()`:

```gdscript
## Load role definitions from roles.json
static func load_roles() -> Dictionary:
	var roles_by_id = {}
	var data = _load_json_file(DATA_PATH + "roles/roles.json")
	if data.has("roles"):
		for role in data.roles:
			roles_by_id[role.id] = role
	return roles_by_id
```

- [ ] **Step 3: Rewrite `get_skills_for_role()` (lines 101-109)**

Replace tag-scanning with roles.json lookup:

```gdscript
## Get all skills for a given role
static func get_skills_for_role(role: String) -> Array:
	var roles_db = load_roles()
	var all_skills = load_skills()
	var role_skills = []
	var role_data = roles_db.get(role, {})
	for skill_id in role_data.get("skills", []):
		if all_skills.has(skill_id):
			role_skills.append(all_skills[skill_id])
	return role_skills
```

- [ ] **Step 4: Rewrite `load_equipment()` (lines 112-129)**

Replace multi-file loading with single file:

```gdscript
## Load all equipment definitions
static func load_equipment() -> Dictionary:
	var equipment_by_id = {}
	var data = _load_json_file(DATA_PATH + "equipment/equipment.json")
	if data.has("equipment"):
		for item in data.equipment:
			equipment_by_id[item.id] = item
	return equipment_by_id
```

- [ ] **Step 5: Rewrite `resolve_character_abilities()` (lines 132-165)**

Replace role-tag scanning with roles.json lookup. Equipment iteration changes from array to dictionary values:

```gdscript
## Resolve a character's full ability list from roles + equipment
## Abilities come from three sources:
##   1. Universal role skills (available to everyone)
##   2. Character role skills (from roles.json)
##   3. Equipment-granted skills
static func resolve_character_abilities(character: Dictionary, equipment_db: Dictionary) -> Array:
	var abilities: Array = []
	var roles_db = load_roles()
	var char_roles = character.get("roles", [])

	# Always include universal skills
	var roles_to_check = ["universal"] + char_roles
	for role_id in roles_to_check:
		var role_data = roles_db.get(role_id, {})
		for skill_id in role_data.get("skills", []):
			if skill_id not in abilities:
				abilities.append(skill_id)

	# Add equipment-granted skills (iterate slot values)
	var equipment = character.get("equipment", {})
	for slot in equipment:
		var equip_id = equipment[slot]
		if equip_id == null or equip_id == "":
			continue
		var equip = equipment_db.get(equip_id, {})
		for skill_id in equip.get("granted_skills", []):
			if skill_id not in abilities:
				abilities.append(skill_id)

	return abilities
```

- [ ] **Step 6: Add `validate_equipment_devices()` function**

Add after `resolve_character_abilities()`:

```gdscript
## Validate that a character doesn't exceed their device limit
## Devices are equipment with granted_skills or charges
static func validate_equipment_devices(character: Dictionary, equipment_db: Dictionary) -> bool:
	var max_devices = character.get("max_devices", 3)
	var device_count = 0
	var equipment = character.get("equipment", {})
	for slot in equipment:
		var equip_id = equipment[slot]
		if equip_id == null or equip_id == "":
			continue
		var equip = equipment_db.get(equip_id, {})
		if not equip.get("granted_skills", []).is_empty() or equip.get("charges", 0) > 0:
			device_count += 1
	if device_count > max_devices:
		push_warning("%s has %d devices equipped (max: %d)" % [character.get("id", "?"), device_count, max_devices])
		return false
	return true
```

- [ ] **Step 7: Commit**

```bash
git add godot/scripts/data/data_loader.gd
git commit -m "feat: update data_loader for roles.json lookup and slot-based equipment"
```

---

### Task 8: Update `game_manager.gd`

**Files:**
- Modify: `godot/scripts/autoload/game_manager.gd` (lines 51-72)

- [ ] **Step 1: Update `_create_party_member_from_data()` to pass through slot-based equipment dict and max_devices**

```gdscript
func _create_party_member_from_data(char_data: Dictionary) -> Dictionary:
	# Calculate derived stats from base stats
	var stats = char_data.get("base_stats", {})
	var vigor = stats.get("vigor", 5)
	var resonance = stats.get("resonance", 5)

	return {
		"id": char_data.get("id", "unknown"),
		"name": char_data.get("name", "Unknown"),
		"title": char_data.get("title", ""),
		"level": 1,
		"current_hp": vigor * 20,  # FIXME: Use proper formula from progression system
		"max_hp": vigor * 20,
		"current_mp": resonance * 5,
		"max_mp": resonance * 5,
		"burst_gauge": 0,
		"equipment": char_data.get("equipment", {}),
		"equipment_proficiencies": char_data.get("equipment_proficiencies", []),
		"max_devices": char_data.get("max_devices", 3),
		"base_stats": stats,
		"roles": char_data.get("roles", []),
		"burst_mode": char_data.get("burst_mode", {}),
	}
```

The key change: `equipment` now passes through as a dictionary `{"weapon": "id", ...}` instead of an array `["id", ...]`.

- [ ] **Step 2: Commit**

```bash
git add godot/scripts/autoload/game_manager.gd
git commit -m "feat: update game_manager for slot-based equipment dict"
```

---

### Task 9: Update `combat_manager.gd` equipment iteration

**Files:**
- Modify: `godot/scripts/presentation/combat/combat_manager.gd`

- [ ] **Step 1: Update equipment charge initialization (lines 462-468)**

Change from iterating an array to iterating dictionary values:

```gdscript
		# Initialize equipment charges
		var equip_charges = {}
		var member_equipment = member.get("equipment", {})
		for slot in member_equipment:
			var equip_id = member_equipment[slot]
			if equip_id == null or equip_id == "":
				continue
			var equip = equipment_data.get(equip_id, {})
			if equip.get("charges", 0) > 0:
				equip_charges[equip_id] = equip.charges
		member["equipment_charges"] = equip_charges
```

- [ ] **Step 2: Update `_get_skill_equipment()` (lines 1861-1866)**

Change from iterating an array to iterating dictionary values:

```gdscript
func _get_skill_equipment(unit: Dictionary, skill_id: String) -> String:
	var unit_equipment = unit.get("equipment", {})
	for slot in unit_equipment:
		var equip_id = unit_equipment[slot]
		if equip_id == null or equip_id == "":
			continue
		var equip = equipment_data.get(equip_id, {})
		if skill_id in equip.get("granted_skills", []):
			return equip_id
	return ""
```

- [ ] **Step 3: Commit**

```bash
git add godot/scripts/presentation/combat/combat_manager.gd
git commit -m "feat: update combat_manager for slot-based equipment iteration"
```

---

### Task 10: Update `skill_panel.gd` equipment charge check

**Files:**
- Modify: `godot/scripts/presentation/combat/skill_panel.gd` (lines 108-113)

- [ ] **Step 1: Update equipment iteration for charge checking**

Change from iterating an array to iterating dictionary values:

```gdscript
		# Check equipment charges
		if charge_cost > 0 and can_use:
			var has_charges = false
			var unit_equipment = current_unit.get("equipment", {})
			for slot in unit_equipment:
				var equip_id = unit_equipment[slot]
				if equip_id == null or equip_id == "":
					continue
				if skill.get("id", "") in _equip_data.get(equip_id, {}).get("granted_skills", []):
					var unit_charges = current_unit.get("equipment_charges", {})
					if unit_charges.get(equip_id, 0) >= charge_cost:
						has_charges = true
						break
			if not has_charges:
				can_use = false
				disable_reason = "No equipment charges remaining"
```

- [ ] **Step 2: Commit**

```bash
git add godot/scripts/presentation/combat/skill_panel.gd
git commit -m "feat: update skill_panel for slot-based equipment iteration"
```

---

## Chunk 3: Verification

### Task 11: Smoke test

- [ ] **Step 1: Launch the Godot project and verify no errors on startup**

Run: Open Godot editor or run from command line. Check Output panel for errors.

Expected: No `push_error` or `push_warning` messages about missing files or data.

- [ ] **Step 2: Verify ability resolution**

Enter combat configurator or start a combat encounter. Check that:
- Cyrus has: universal skills (basic_attack, defend, shove) + bladewarden skills (11) + shifting_blade skills (5) = ~19 skills
- Vaughn has: universal (3) + shadowfang (11) + warcrier (1) + poison_vial skills (2) + hookshot skills (1) = ~18 skills
- Phaidros has: universal (3) + ironskin (14) + geovant (6) + earth_gauntlets skills (4, overlapping with geovant) = ~23 skills

- [ ] **Step 3: Verify equipment charges work**

Start combat, use a charge-based skill (e.g., earthquake for Phaidros). Confirm charge is consumed and skill becomes disabled when charges run out.

- [ ] **Step 4: Final commit if any fixes were needed**

```bash
git add -A
git commit -m "fix: address smoke test issues from refactor"
```
