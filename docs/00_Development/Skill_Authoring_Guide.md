# Skill Authoring Guide

How to add new combat skills to Disruption.

---

## Quick Start

1. Open (or create) a JSON file in `godot/data/skills/`
2. Add your skill object to the `"skills"` array
3. If you created a new file, add its filename to the list in `godot/scripts/data/data_loader.gd` → `load_skills()`
4. Assign the skill to a character via `starting_abilities` in `godot/data/characters/party.json`, or to equipment via `granted_skills` in `godot/data/equipment/*.json`
5. Press **F5** during combat to hot-reload without restarting

---

## Minimal Skill Template

```json
{
  "id": "your_skill_id",
  "name": "Display Name",
  "description": "What the player sees in the tooltip.",
  "action_type": "action",
  "mp_cost": 2,
  "damage": {
    "base": 30,
    "type": "physical",
    "subtype": "slash",
    "stat_scaling": "strength"
  },
  "targeting": {
    "type": "single_enemy",
    "range_band": "melee"
  },
  "burst_gauge_gain": 10
}
```

This creates a standard 2 AP melee attack that deals physical/slash damage scaling off strength.

---

## Field Reference

### Identity

| Field | Type | Required | Notes |
|-------|------|----------|-------|
| `id` | string | **yes** | Unique across all skill files. Snake_case. |
| `name` | string | **yes** | Shown on skill button. |
| `description` | string | **yes** | Tooltip text. |
| `roles` | string[] | no | Role tags, e.g. `["bladewarden"]`. Informational only — does not restrict usage. |

### Action Economy

| Field | Type | Default | Notes |
|-------|------|---------|-------|
| `action_type` | `"action"` or `"bonus_action"` | — | `action` = 2 AP, `bonus_action` = 1 AP. |
| `ap_cost` | int | derived from action_type | Explicit override. Use for non-standard costs (e.g. 3 AP heavies). |
| `mp_cost` | int | — | MP consumed on use. 0 is valid. |
| `equipment_charge_cost` | int | 0 | Deducts from the equipment that grants this skill. |
| `burst_gauge_gain` | int | — | Burst gauge added on use. Typical range: 5–25. |
| `burst_charge_type` | string | — | `"aggressive"`, `"defensive"`, `"technical"`, `"support"`. Cosmetic tag for now. |

### Targeting

```json
"targeting": {
  "type": "single_enemy",
  "range_band": "melee"
}
```

**Target types:**

| `type` | Picks | Notes |
|--------|-------|-------|
| `self` | Caster | No target selection UI. |
| `single_enemy` | One enemy | Player clicks a hex. |
| `single_ally` | One ally | Player clicks a hex. |
| `all_enemies` | Every enemy | No target selection — hits all. |
| `all_allies` | Every ally | No target selection — buffs all. |
| `aoe_adjacent_enemies` | All enemies adjacent to caster | Hex distance ≤ 1. No target selection. |

**Range bands** (how close the target must be):

| `range_band` | Hex distance | Typical use |
|--------------|-------------|-------------|
| `melee` | 1 | Swords, fists, adjacent-only. |
| `close` | 2–3 | Short-range abilities. |
| `distant` | 4+ | Long-range magic/archery. |
| `ranged` | any | Unlimited range. |

For `self`, `all_enemies`, and `all_allies`, range_band is ignored.

### Damage

Omit the entire `damage` block for non-damaging skills (buffs, debuffs without damage).

```json
"damage": {
  "base": 35,
  "type": "physical",
  "subtype": "slash",
  "stat_scaling": "strength",
  "hits": 1,
  "cannot_dodge": false
}
```

| Field | Type | Default | Notes |
|-------|------|---------|-------|
| `base` | int | — | Base damage before scaling. Basic attack = 20, standard skills = 25–45. |
| `type` | string | — | `"physical"`, `"elemental"`, `"magical"`, `"special"` |
| `subtype` | string | — | See damage subtypes below. |
| `stat_scaling` | string | — | `"strength"`, `"dexterity"`, `"resonance"`, `"vigor"` |
| `hits` | int | 1 | Multi-hit: each hit rolls damage separately with per-hit floating text. |
| `cannot_dodge` | bool | false | If true, ignores dodge/evasion. |

**Damage formula:**
```
final = base × (1 + stat × 0.15) × (100 / (100 + def × 5)) × effectiveness × crit × 0.25
```

**Damage subtypes:**
- Physical: `slash`, `pierce`, `blunt`
- Elemental: `fire`, `ice`, `lightning`, `earth`, `wind`, `water`
- Magical: `arcane`, `divine`, `occult`
- Special: `psychic`, `necrotic`, `radiant`

### Effect

Omit for pure damage skills with no secondary effect. One effect per skill.

```json
"effect": {
  "type": "debuff",
  "status": "hamstrung",
  "stat_modifier": { "agility": -0.5 },
  "duration": 3
}
```

**Effect types:**

| `type` | Target | Description |
|--------|--------|-------------|
| `self_buff` | Caster | Apply a beneficial status to self. |
| `ally_buff` | Chosen ally | Apply a beneficial status to one ally. |
| `party_buff` | All allies | Apply a beneficial status to entire party. |
| `debuff` | Damage target | Apply a harmful status to the unit you hit. |
| `enemy_debuff` | All enemies | Apply a harmful status to all enemies (no damage needed). |
| `aoe_debuff` | Adjacent enemies | Debuff all enemies within hex distance 1. |
| `knockback` | Damage target | Push target away from caster. |
| `pull` | Damage target | Pull target toward caster. |
| `forced_movement` | Damage target | Push target in a specified direction (row-based). |
| `self_reposition` | Caster | Move caster after attacking (e.g. retreat). |
| `reveal` | Target enemy | Permanently expose resistances/weaknesses. |
| `weapon_buff` | Caster | Enchant weapon with element for N attacks. |
| `random_debuff_per_hit` | Damage target | Roll a random debuff from a pool on each hit. |
| `create_terrain` | Grid tile | Spawn a destructible object on the battlefield. |

**Common effect fields:**

| Field | Used with | Description |
|-------|-----------|-------------|
| `status` | all | Status name string, e.g. `"stunned"`, `"iron_skin"`. |
| `duration` | all | How many turns the status lasts. |
| `stat_modifier` | buffs/debuffs | Dict of fractional changes. `{"strength": -0.3}` = −30%. |
| `damage_per_turn` | debuffs | DOT tick damage. Any status with this > 0 auto-ticks at end of turn. |
| `damage_reduction` | buffs | `{"physical": 0.3}` = 30% physical DR. |
| `apply_chance` | debuffs | 0.0–1.0 probability the effect applies. Omit for guaranteed. |
| `stackable` | buffs | If true, multiple applications stack instead of refreshing. |
| `max_stacks` | buffs | Maximum number of stacks when `stackable` is true. |

**Damage modifier fields** (self_buff):

| Field | Description |
|-------|-------------|
| `damage_multiplier` | Multiplier on next attack, e.g. `2.0`. |
| `multi_hit_bonus` | Adds N extra hits to multi-hit skills. |
| `mp_cost_reduction` | Reduces MP cost of next skill by this amount. |
| `burst_gauge_bonus` | Bonus burst gauge gain on next skill. |

**Consumption triggers** (self_buff — when is the status removed):

| Field | Description |
|-------|-------------|
| `consumes_on_attack` | Removed after caster's next basic attack. |
| `consumes_on_hit` | Removed when caster is hit by an enemy. |
| `consumes_on_skill` | Removed after caster's next skill use. |

**Defensive fields** (buffs):

| Field | Description |
|-------|-------------|
| `negates_forced_movement` | Immune to push/pull while active. |
| `counter_on_ally_hit` | If true, caster auto-counterattacks whoever hits an ally. |
| `redirect_damage_to` | `"self"` — caster intercepts the next hit targeting the buffed ally. |
| `prevents_movement` | If true, target cannot move (root). |

**Movement fields** (knockback/pull/forced_movement/self_reposition):

| Field | Description |
|-------|-------------|
| `distance` | How many hexes to move. |
| `direction` | `"away"`, `"toward"`, `"toward_caster"`, `"away_from_target"`, `"up"`, `"down"`. |

**Taunt fields** (enemy_debuff):

| Field | Description |
|-------|-------------|
| `attacks_redirected` | How many attacks the taunt absorbs before expiring. |

**Weapon buff fields** (weapon_buff):

| Field | Description |
|-------|-------------|
| `element` | Element applied to weapon: `"fire"`, `"ice"`, `"lightning"`, etc. |
| `choose_element` | If true, player picks the element at cast time. |
| `attacks_remaining` | Number of attacks the enchant lasts. |
| `converts_attacks_to_element` | If true, all attacks become the current element (not just bonus damage). |
| `dot_on_hit` | Nested object: on-hit DOT applied by enchanted attacks. See below. |

**`dot_on_hit` sub-object** (for weapon coatings like poison_coating, razor_edge):

```json
"dot_on_hit": {
  "status": "poisoned",
  "damage_per_turn": 6,
  "duration": 3,
  "apply_chance": 0.5
}
```

**Random debuff fields** (random_debuff_per_hit):

| Field | Description |
|-------|-------------|
| `debuff_pool` | Array of `{status, duration, stat_modifier}` objects. One is randomly applied per hit. |

**Size-conditional fields** (debuff — for skills like smash):

| Field | Description |
|-------|-------------|
| `size_conditional` | If true, effect varies by target size. |
| `knockdown_max_size` | Maximum size category that gets knocked down (smaller targets get stunned). |
| `hp_percent_if_large` | Fraction of target's max HP dealt as bonus damage to large targets instead. |

**Reveal fields** (reveal):

| Field | Description |
|-------|-------------|
| `reveals` | What to expose: `"weaknesses_and_resistances"`. |

**Terrain creation fields** (create_terrain):

| Field | Description |
|-------|-------------|
| `terrain` | Terrain type to create, e.g. `"wall"`. |
| `hp_percent_of_caster` | Terrain HP as fraction of caster's max HP (e.g. `0.75`). |
| `placement` | Where to place terrain: `"front_column"`, etc. |

### Healing (instead of damage)

For skills that restore HP instead of dealing damage, use a `healing` block (no `damage` block).

**Flat healing** (scales with a stat):
```json
"healing": {
  "base": 30,
  "stat_scaling": "vigor"
}
```

**Percent healing** (fraction of max HP):
```json
"healing": {
  "base_percent": 0.3,
  "target": "self"
}
```

| Field | Description |
|-------|-------------|
| `base` | Flat heal amount before stat scaling. |
| `stat_scaling` | Stat that scales the heal (same formula as damage scaling). |
| `base_percent` | Fraction of max HP to restore (0.3 = 30%). Use instead of `base`. |
| `target` | Currently only `"self"` is implemented. |

### Movement (lunge/teleport — optional)

For skills where the caster moves to the target before attacking:

```json
"movement": {
  "type": "to_target",
  "ignore_intervening": true
}
```

| Field | Description |
|-------|-------------|
| `type` | `"to_target"` — caster moves adjacent to target before attacking. |
| `ignore_intervening` | If true, skip over units/obstacles in the path. |

### Special Mechanics

For unique one-off mechanics that don't fit the standard model:

```json
"special": {
  "type": "spend_all_mp",
  "hits_formula": "mp_spent_div_2_min_2"
}
```

Currently only `spend_all_mp` is implemented (used by Break Stock). Spends all remaining MP, hits = MP ÷ 2 (minimum 2).

---

## Recipes

### Basic Melee Attack
```json
{
  "id": "slash",
  "name": "Slash",
  "description": "A quick blade strike.",
  "action_type": "action",
  "ap_cost": 1,
  "mp_cost": 0,
  "damage": { "base": 20, "type": "physical", "subtype": "slash", "stat_scaling": "strength" },
  "targeting": { "type": "single_enemy", "range_band": "melee" },
  "burst_gauge_gain": 5
}
```

### Ranged Spell
```json
{
  "id": "fire_bolt",
  "name": "Fire Bolt",
  "description": "Hurl a bolt of flame at a distant enemy.",
  "action_type": "action",
  "mp_cost": 3,
  "damage": { "base": 35, "type": "elemental", "subtype": "fire", "stat_scaling": "resonance" },
  "targeting": { "type": "single_enemy", "range_band": "distant" },
  "burst_gauge_gain": 10
}
```

### Self Buff (Bonus Action)
```json
{
  "id": "focus",
  "name": "Focus",
  "description": "Concentrate to deal more damage on your next attack.",
  "action_type": "bonus_action",
  "mp_cost": 2,
  "effect": {
    "type": "self_buff",
    "status": "focused",
    "damage_multiplier": 1.5,
    "consumes_on_attack": true,
    "duration": 2
  },
  "targeting": { "type": "self" },
  "burst_gauge_gain": 8
}
```

### Debuff with Damage
```json
{
  "id": "leg_sweep",
  "name": "Leg Sweep",
  "description": "Sweep the legs, slowing the target.",
  "action_type": "action",
  "mp_cost": 2,
  "damage": { "base": 20, "type": "physical", "subtype": "blunt", "stat_scaling": "strength" },
  "effect": {
    "type": "debuff",
    "status": "slowed",
    "stat_modifier": { "agility": -0.3 },
    "duration": 2
  },
  "targeting": { "type": "single_enemy", "range_band": "melee" },
  "burst_gauge_gain": 10
}
```

### DOT (Damage Over Time)
```json
{
  "id": "envenom",
  "name": "Envenom",
  "description": "Coat your blade in venom. Poisons the target.",
  "action_type": "action",
  "mp_cost": 2,
  "damage": { "base": 15, "type": "physical", "subtype": "pierce", "stat_scaling": "dexterity" },
  "effect": {
    "type": "debuff",
    "status": "poisoned",
    "damage_per_turn": 8,
    "duration": 3
  },
  "targeting": { "type": "single_enemy", "range_band": "melee" },
  "burst_gauge_gain": 10
}
```

### AoE Damage
```json
{
  "id": "whirlwind",
  "name": "Whirlwind",
  "description": "Spin and strike all nearby enemies.",
  "action_type": "action",
  "mp_cost": 3,
  "damage": { "base": 25, "type": "physical", "subtype": "slash", "stat_scaling": "strength" },
  "targeting": { "type": "aoe_adjacent_enemies", "range_band": "melee" },
  "burst_gauge_gain": 12
}
```

### Multi-Hit
```json
{
  "id": "barrage",
  "name": "Barrage",
  "description": "Strike three times in rapid succession.",
  "action_type": "action",
  "mp_cost": 3,
  "damage": { "base": 15, "type": "physical", "subtype": "pierce", "stat_scaling": "dexterity", "hits": 3 },
  "targeting": { "type": "single_enemy", "range_band": "melee" },
  "burst_gauge_gain": 12
}
```

### Ally Buff
```json
{
  "id": "fortify",
  "name": "Fortify",
  "description": "Harden an ally against physical attacks.",
  "action_type": "bonus_action",
  "mp_cost": 2,
  "effect": {
    "type": "ally_buff",
    "status": "fortified",
    "damage_reduction": { "physical": 0.3 },
    "duration": 3
  },
  "targeting": { "type": "single_ally", "range_band": "ranged" },
  "burst_gauge_gain": 10
}
```

### Knockback
```json
{
  "id": "bash",
  "name": "Bash",
  "description": "Slam the target, pushing them back.",
  "action_type": "action",
  "mp_cost": 1,
  "damage": { "base": 20, "type": "physical", "subtype": "blunt", "stat_scaling": "strength" },
  "effect": { "type": "knockback", "distance": 1, "direction": "away" },
  "targeting": { "type": "single_enemy", "range_band": "melee" },
  "burst_gauge_gain": 8
}
```

### Equipment-Charged Skill
```json
{
  "id": "quake",
  "name": "Quake",
  "description": "Channel the gauntlets to shake the earth.",
  "action_type": "action",
  "mp_cost": 4,
  "equipment_charge_cost": 1,
  "damage": { "base": 35, "type": "elemental", "subtype": "earth", "stat_scaling": "resonance" },
  "targeting": { "type": "all_enemies" },
  "burst_gauge_gain": 15
}
```

The equipment that grants this skill must have enough `charges`. The skill button shows `[1C]` and disables when charges run out.

### Weapon Buff (Elemental Enchant)
```json
{
  "id": "flame_edge",
  "name": "Flame Edge",
  "description": "Imbue your weapon with fire for your next 3 attacks.",
  "action_type": "bonus_action",
  "mp_cost": 2,
  "effect": {
    "type": "weapon_buff",
    "status": "fire_edge",
    "element": "fire",
    "attacks_remaining": 3,
    "duration": 5
  },
  "targeting": { "type": "self" },
  "burst_gauge_gain": 8
}
```

### Forced Movement (Directional Push)
```json
{
  "id": "gust",
  "name": "Gust",
  "description": "Blast the target upward on the grid.",
  "action_type": "action",
  "mp_cost": 2,
  "damage": { "base": 20, "type": "elemental", "subtype": "wind", "stat_scaling": "resonance" },
  "effect": { "type": "forced_movement", "direction": "up", "distance": 1 },
  "targeting": { "type": "single_enemy", "range_band": "melee" },
  "burst_gauge_gain": 10
}
```

### Self-Retreat After Attack
```json
{
  "id": "hit_and_run",
  "name": "Hit and Run",
  "description": "Strike and leap back to safety.",
  "action_type": "action",
  "mp_cost": 2,
  "damage": { "base": 30, "type": "physical", "subtype": "pierce", "stat_scaling": "dexterity" },
  "effect": { "type": "self_reposition", "direction": "away_from_target", "distance": 1 },
  "targeting": { "type": "single_enemy", "range_band": "melee" },
  "burst_gauge_gain": 10
}
```

### Stacking Party Buff
```json
{
  "id": "rally",
  "name": "Rally",
  "description": "Inspire allies, stacking up to 3 times.",
  "action_type": "bonus_action",
  "mp_cost": 2,
  "effect": {
    "type": "party_buff",
    "status": "inspired",
    "stat_modifier": { "strength": 0.05, "resonance": 0.05 },
    "duration": 4,
    "stackable": true,
    "max_stacks": 3
  },
  "targeting": { "type": "all_allies" },
  "burst_gauge_gain": 10
}
```

### Counter-Trigger (Protect Ally)
```json
{
  "id": "guardian_watch",
  "name": "Guardian Watch",
  "description": "Counter-attack any enemy that hits an ally.",
  "action_type": "bonus_action",
  "mp_cost": 2,
  "effect": {
    "type": "self_buff",
    "status": "protective_instinct",
    "counter_on_ally_hit": true,
    "duration": 4
  },
  "targeting": { "type": "self" },
  "burst_gauge_gain": 12
}
```

### Intercept (Redirect Hit to Self)
```json
{
  "id": "bodyguard",
  "name": "Bodyguard",
  "description": "Block the next hit targeting an ally.",
  "action_type": "bonus_action",
  "mp_cost": 2,
  "effect": {
    "type": "ally_buff",
    "status": "intercepted",
    "redirect_damage_to": "self",
    "consumes_on_hit": true,
    "duration": 3
  },
  "targeting": { "type": "single_ally", "range_band": "ranged" },
  "burst_gauge_gain": 12
}
```

### Root (Immobilize)
```json
{
  "id": "entangle",
  "name": "Entangle",
  "description": "Pin the target in place.",
  "action_type": "action",
  "mp_cost": 3,
  "effect": {
    "type": "debuff",
    "status": "rooted",
    "prevents_movement": true,
    "duration": 2
  },
  "targeting": { "type": "single_enemy", "range_band": "ranged" },
  "burst_gauge_gain": 12
}
```

### Reveal (Expose Weaknesses)
```json
{
  "id": "analyze",
  "name": "Analyze",
  "description": "Study the target and reveal all resistances.",
  "action_type": "action",
  "mp_cost": 1,
  "effect": {
    "type": "reveal",
    "reveals": "weaknesses_and_resistances"
  },
  "targeting": { "type": "single_enemy", "range_band": "ranged" },
  "burst_gauge_gain": 8
}
```

---

## Balance Guidelines

| Category | Base Damage | MP Cost | Burst Gain |
|----------|-------------|---------|------------|
| Basic attack | 20 | 0 | 5 |
| Light skill (bonus_action) | 0 (buff/debuff) | 1–2 | 8–12 |
| Standard skill | 25–35 | 2–3 | 10–12 |
| Heavy skill (3 AP) | 35–45 | 3–5 | 15–25 |
| Multi-hit (per hit) | 15–20 | 3 | 12–15 |
| Equipment-charged | 35–40 | 3–4 | 12–15 |

**TTK target:** 3–5 rounds of focused fire to kill a standard enemy.

**DOT balance:** 6–10 damage per turn for 3 turns is typical.

**Stat modifiers:** -20% to -50% is the typical debuff range. Duration 2–4 turns.

---

## Assigning Skills

### To a character (innate)

In `godot/data/characters/party.json`, add the skill ID to `starting_abilities`:

```json
"starting_abilities": ["basic_attack", "your_skill_id"]
```

### To equipment (granted on equip)

In `godot/data/equipment/*.json`, add the skill ID to `granted_skills`:

```json
{
  "id": "magic_ring",
  "name": "Ring of Fire",
  "category": "ring",
  "slot": "accessory",
  "charges": 2,
  "granted_skills": ["your_skill_id"],
  "type": "glyphion"
}
```

The character must have the equipment's `category` in their `equipment_proficiencies` to equip it.

---

## Adding a New Skill File

If you create a new file (e.g. `godot/data/skills/elementalist_skills.json`):

1. Use the standard wrapper format:
```json
{
  "skills": [
    { "id": "...", ... },
    { "id": "...", ... }
  ]
}
```

2. Add the filename to `godot/scripts/data/data_loader.gd` in the `load_skills()` function:
```gdscript
var skill_files = [
    "core_skills.json",
    "bladewarden_skills.json",
    # ... existing files ...
    "elementalist_skills.json",  # <- add here
]
```

---

## Implementation Status

### Fully Working

These features are implemented and functional in the combat engine:

- All targeting types (`self`, `single_enemy`, `single_ally`, `all_enemies`, `all_allies`, `aoe_adjacent_enemies`)
- All range bands (`melee`, `close`, `distant`, `ranged`)
- Damage with stat scaling, defense, crits, effectiveness
- Multi-hit (`damage.hits`) with per-hit floating text
- DOT (any status with `damage_per_turn > 0` auto-ticks at turn end)
- Self buff, ally buff, party buff, debuff, enemy_debuff, aoe_debuff
- Stat modifiers on buffs/debuffs
- Damage reduction buffs
- Damage multiplier (stance_of_pitch pattern)
- `consumes_on_attack`, `consumes_on_hit`, `consumes_on_skill`
- Knockback (`away`), pull (`toward`), forced_movement (`up`/`down`)
- Self-reposition (`away_from_target`)
- `apply_chance` on debuffs
- `negates_forced_movement` (braced immunity)
- `multi_hit_bonus` (constant_flurry pattern)
- `mp_cost_reduction`, `burst_gauge_bonus`
- `random_debuff_per_hit` with `debuff_pool`
- `spend_all_mp` special mechanic
- Equipment charge costs and deduction
- Reveal (marks unit as revealed)
- Stacking (`stackable` + `max_stacks`)
- Healing (`base_percent` of max HP)
- `prevents_movement` (root)
- `attacks_redirected` (taunt)
- Hot reload (F5)

### Data Stored, Not Yet Processed

These fields are accepted in JSON and stored at runtime but the engine does not act on them yet. Using them won't cause errors — they just won't do anything.

| Feature | What's missing |
|---------|---------------|
| `dot_on_hit` | Enchanted attacks don't apply the DOT to targets |
| `converts_attacks_to_element` | Damage calc doesn't swap element based on weapon buff |
| `choose_element` | No UI prompt; defaults to whatever `element` is set |
| `create_terrain` | Effect type recognized, but no terrain objects spawn |
| `attacks_remaining` decrement | Weapon buffs expire by duration, not attack count |
| `healing.target` beyond `"self"` | Always heals caster regardless |
| `healing.base` + `stat_scaling` | Flat+scaled healing path exists but untested |
| `movement.type: "to_target"` | Caster doesn't move before attacking |
| `counter_on_ally_hit` | Status stored, no counter-attack trigger logic |
| `redirect_damage_to` | Status stored, no damage redirect logic |
| `size_conditional` | Stored but no size categories on units yet |
| `terrain` / `hp_percent_of_caster` / `placement` | No terrain system |
