class_name DamageCalculator
extends RefCounted
## DamageCalculator - Pure damage calculation logic
## No engine dependencies - portable game rules
## All balance values read from CombatConfigLoader

const CombatConfigLoaderClass = preload("res://scripts/logic/combat/combat_config_loader.gd")

## Result structure for damage calculations
class DamageResult:
	var damage: int = 0
	var is_critical: bool = false
	var effectiveness: float = 1.0  # 0.5 resist, 1.0 normal, 1.5 weak
	var damage_type: String = "physical"

	func _init(dmg: int = 0, crit: bool = false, eff: float = 1.0, type: String = "physical"):
		damage = dmg
		is_critical = crit
		effectiveness = eff
		damage_type = type


## Calculate damage for a skill
## skill: Dictionary from skills.json
## attacker_stats: Dictionary with base_stats and any modifiers
## defender: Dictionary with base_stats, resistances, weaknesses
static func calculate_damage(skill: Dictionary, attacker_stats: Dictionary, defender: Dictionary) -> DamageResult:
	var result = DamageResult.new()

	if not skill.has("damage"):
		return result

	var damage_data = skill.damage
	result.damage_type = damage_data.get("type", "physical")
	var damage_subtype = damage_data.get("subtype", "")

	# Base damage from skill
	var base_damage: float = damage_data.get("base", 100)

	# Apply stat scaling (from config)
	var scaling_stat = damage_data.get("stat_scaling", "strength")
	var stat_value = _get_stat_value(attacker_stats, scaling_stat)
	var scaling_factor = CombatConfigLoaderClass.get_balance("stat_scaling_factor", 0.1)
	var scaled_damage = base_damage * (1.0 + stat_value * scaling_factor)

	# Apply defense reduction (from config)
	var defender_defense = _calculate_defense(defender)
	var after_defense = scaled_damage * (100.0 / (100.0 + defender_defense))

	# Check for critical hit (from config)
	var crit_rate = CombatConfigLoaderClass.get_balance("crit_rate_per_dexterity", 0.05)
	var crit_chance = _get_stat_value(attacker_stats, "dexterity") * crit_rate
	result.is_critical = randf() < crit_chance
	var crit_multiplier = CombatConfigLoaderClass.get_balance("crit_multiplier", 1.5) if result.is_critical else 1.0

	# Calculate type effectiveness
	result.effectiveness = _calculate_effectiveness(result.damage_type, damage_subtype, defender)

	# Apply base damage multiplier (global tuning knob)
	var base_mult = CombatConfigLoaderClass.get_balance("base_damage_multiplier", 1.0)
	var final_damage = after_defense * result.effectiveness * crit_multiplier * base_mult

	# Final damage
	var min_damage = int(CombatConfigLoaderClass.get_balance("min_damage", 1))
	result.damage = max(min_damage, int(floor(final_damage)))

	# Debug: log damage breakdown
	var attacker_name = attacker_stats.get("name", "???")
	var defender_name = defender.get("name", "???")
	print("[DMG] %s -> %s: base=%d, %s=%d, scaled=%.0f, def=%.0f(vig=%d), afterDef=%.0f, eff=%.1fx, crit=%s(%.0f%%), final=%d" % [
		attacker_name, defender_name, int(base_damage),
		scaling_stat, int(stat_value), scaled_damage,
		defender_defense, defender.get("base_stats", {}).get("vigor", 5), after_defense,
		result.effectiveness, "YES" if result.is_critical else "no", crit_chance * 100,
		result.damage
	])

	return result


## Calculate opportunity attack damage (basic attack at reduced multiplier)
static func calculate_opportunity_attack_damage(attacker: Dictionary, defender: Dictionary, skills_data: Dictionary) -> DamageResult:
	var basic_attack = skills_data.get("basic_attack", {
		"damage": {
			"base": 75,
			"type": "physical",
			"subtype": "slash",
			"stat_scaling": "strength"
		}
	})
	var result = calculate_damage(basic_attack, attacker, defender)
	var oa_mult = CombatConfigLoaderClass.get_oa_damage_mult()
	result.damage = max(1, int(floor(result.damage * oa_mult)))
	print("[DMG]   OA damage: applied %.0f%% multiplier -> %d" % [oa_mult * 100, result.damage])
	return result


## Get a stat value from a unit's stats
static func _get_stat_value(unit: Dictionary, stat_name: String) -> float:
	var base_stats = unit.get("base_stats", {})

	# Map stat names
	match stat_name:
		"strength":
			return base_stats.get("strength", 5)
		"dexterity":
			return base_stats.get("dexterity", 5)
		"vigor":
			return base_stats.get("vigor", 5)
		"resonance":
			return base_stats.get("resonance", 5)
		"agility":
			return base_stats.get("agility", 5)
		_:
			return 5.0


## Calculate defense value (from config)
static func _calculate_defense(defender: Dictionary) -> float:
	var base_stats = defender.get("base_stats", {})
	var vigor = base_stats.get("vigor", 5)
	var defense_per_vigor = CombatConfigLoaderClass.get_balance("defense_per_vigor", 3.0)
	return vigor * defense_per_vigor


## Calculate type effectiveness
static func _calculate_effectiveness(damage_type: String, damage_subtype: String, defender: Dictionary) -> float:
	var resistances = defender.get("resistances", [])
	var weaknesses = defender.get("weaknesses", [])

	# Check for type or subtype matches
	var types_to_check = [damage_type]
	if damage_subtype != "":
		types_to_check.append(damage_subtype)

	for check_type in types_to_check:
		if check_type in weaknesses:
			return 1.5  # Vulnerable
		if check_type in resistances:
			return 0.5  # Resistant

	return 1.0  # Normal


## Calculate derived stats from base stats (config-driven)
static func calculate_derived_stats(base_stats: Dictionary) -> Dictionary:
	var vigor = base_stats.get("vigor", 5)
	var resonance = base_stats.get("resonance", 5)
	var dexterity = base_stats.get("dexterity", 5)
	var agility = base_stats.get("agility", 5)

	var hp_per_vigor = CombatConfigLoaderClass.get_balance("hp_per_vigor", 40.0)
	var mp_per_resonance = CombatConfigLoaderClass.get_balance("mp_per_resonance", 5.0)
	var defense_per_vigor = CombatConfigLoaderClass.get_balance("defense_per_vigor", 3.0)
	var crit_rate = CombatConfigLoaderClass.get_balance("crit_rate_per_dexterity", 0.05)
	var speed_per_agility = CombatConfigLoaderClass.get_balance("speed_per_agility", 2.0)

	return {
		"max_hp": int(vigor * hp_per_vigor),
		"max_mp": int(resonance * mp_per_resonance),
		"defense": vigor * defense_per_vigor,
		"crit_rate": dexterity * crit_rate,
		"speed": agility * speed_per_agility,
	}


## Apply damage reduction from status effects (e.g., iron_skin, defending)
static func apply_damage_reduction(damage: int, damage_type: String, reductions: Dictionary) -> int:
	var reduction_multiplier = 1.0

	# Check for type-specific reduction
	if reductions.has(damage_type):
		reduction_multiplier -= reductions[damage_type]

	# Check for "all" damage reduction
	if reductions.has("all"):
		reduction_multiplier -= reductions["all"]

	reduction_multiplier = max(0.0, reduction_multiplier)
	var reduced = int(floor(damage * reduction_multiplier))
	if reduction_multiplier < 1.0:
		print("[DMG]   status DR: %d -> %d (mult=%.2f, reductions=%s)" % [damage, reduced, reduction_multiplier, str(reductions)])
	return reduced
