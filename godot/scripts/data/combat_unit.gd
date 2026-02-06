class_name CombatUnit
extends RefCounted
## CombatUnit - Runtime representation of a unit in combat
## Mutable state separate from persistent character data

var id: String = ""
var name: String = ""
var is_ally: bool = true

# Current combat stats (mutable)
var current_hp: int = 0
var max_hp: int = 0
var current_mp: int = 0
var max_mp: int = 0
var burst_gauge: int = 0
var max_burst: int = 100

# Position on grid (Vector2i: x=column, y=row)
var grid_position: Vector2i = Vector2i(0, 0)

# Base stats (from character/enemy data)
var base_stats: Dictionary = {}

# Combat-modified stats (base + status effects)
var current_stats: Dictionary = {}

# Available abilities
var abilities: Array = []

# Resistances and weaknesses
var resistances: Array = []
var weaknesses: Array = []

# Combat state flags
var is_defending: bool = false
var has_acted: bool = false

# Initiative for turn order
var initiative: float = 0.0

# AI behavior (for enemies)
var ai_behavior: String = "aggressive"

# Roles (for skill restrictions)
var roles: Array = []


## Create a CombatUnit from a party member dictionary
static func from_party_member(party_data: Dictionary, position: Vector2i) -> CombatUnit:
	var unit = CombatUnit.new()
	unit.id = party_data.get("id", "unknown_%d" % randi())
	unit.name = party_data.get("name", "Unknown")
	unit.is_ally = true

	# HP/MP from party data (already calculated by GameManager)
	unit.current_hp = party_data.get("current_hp", 100)
	unit.max_hp = party_data.get("max_hp", 100)
	unit.current_mp = party_data.get("current_mp", 25)
	unit.max_mp = party_data.get("max_mp", 25)
	unit.burst_gauge = party_data.get("burst_gauge", 0)

	# Base stats
	unit.base_stats = party_data.get("base_stats", {}).duplicate()
	unit.current_stats = unit.base_stats.duplicate()

	# Abilities from party data
	unit.abilities = party_data.get("abilities", []).duplicate()

	# Roles
	unit.roles = party_data.get("roles", []).duplicate()

	# Position
	unit.grid_position = position

	# Calculate initiative from agility
	var agility = unit.base_stats.get("agility", 5)
	unit.initiative = agility * 2.0 + randf_range(-2, 2)

	return unit


## Create a CombatUnit from enemy data
static func from_enemy_data(enemy_data: Dictionary, position: Vector2i) -> CombatUnit:
	var unit = CombatUnit.new()
	unit.id = enemy_data.get("id", "enemy_%d" % randi())
	unit.name = enemy_data.get("name", "Enemy")
	unit.is_ally = false

	# HP/MP from enemy data
	unit.max_hp = enemy_data.get("hp", 50)
	unit.current_hp = unit.max_hp
	unit.max_mp = enemy_data.get("mp", 10)
	unit.current_mp = unit.max_mp

	# Base stats
	unit.base_stats = enemy_data.get("base_stats", {}).duplicate()
	unit.current_stats = unit.base_stats.duplicate()

	# Abilities
	unit.abilities = enemy_data.get("abilities", ["basic_attack"]).duplicate()

	# Resistances and weaknesses
	unit.resistances = enemy_data.get("resistances", []).duplicate()
	unit.weaknesses = enemy_data.get("weaknesses", []).duplicate()

	# AI behavior
	unit.ai_behavior = enemy_data.get("ai_behavior", "aggressive")

	# Position
	unit.grid_position = position

	# Calculate initiative from agility
	var agility = unit.base_stats.get("agility", 5)
	unit.initiative = agility * 2.0 + randf_range(-2, 2)

	return unit


## Apply stat modifiers from status effects
func apply_stat_modifiers(modifiers: Dictionary) -> void:
	current_stats = base_stats.duplicate()

	for stat_name in modifiers:
		if current_stats.has(stat_name):
			var base_value = base_stats.get(stat_name, 0)
			var modifier = modifiers[stat_name]
			# Modifier is a percentage (0.05 = +5%)
			current_stats[stat_name] = base_value * (1.0 + modifier)


## Reset stats to base values
func reset_stats() -> void:
	current_stats = base_stats.duplicate()


## Take damage (returns actual damage taken)
func take_damage(amount: int) -> int:
	var actual_damage = min(amount, current_hp)
	current_hp = max(0, current_hp - amount)
	return actual_damage


## Heal (returns actual amount healed)
func heal(amount: int) -> int:
	var actual_heal = min(amount, max_hp - current_hp)
	current_hp = min(max_hp, current_hp + amount)
	return actual_heal


## Spend MP (returns true if successful)
func spend_mp(amount: int) -> bool:
	if current_mp >= amount:
		current_mp -= amount
		return true
	return false


## Restore MP
func restore_mp(amount: int) -> void:
	current_mp = min(max_mp, current_mp + amount)


## Add burst gauge
func add_burst(amount: int) -> void:
	burst_gauge = min(max_burst, burst_gauge + amount)


## Check if alive
func is_alive() -> bool:
	return current_hp > 0


## Check if has enough MP for a skill
func has_mp_for(mp_cost: int) -> bool:
	return current_mp >= mp_cost


## Get stat value (with modifiers applied)
func get_stat(stat_name: String) -> float:
	return current_stats.get(stat_name, base_stats.get(stat_name, 5.0))


## Convert to dictionary (for compatibility with existing code)
func to_dict() -> Dictionary:
	return {
		"id": id,
		"name": name,
		"is_ally": is_ally,
		"current_hp": current_hp,
		"max_hp": max_hp,
		"current_mp": current_mp,
		"max_mp": max_mp,
		"burst_gauge": burst_gauge,
		"grid_position": grid_position,
		"base_stats": base_stats,
		"current_stats": current_stats,
		"abilities": abilities,
		"resistances": resistances,
		"weaknesses": weaknesses,
		"is_defending": is_defending,
		"initiative": initiative,
		"ai_behavior": ai_behavior,
		"roles": roles,
	}
