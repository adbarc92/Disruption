class_name DataLoader
extends RefCounted
## DataLoader - Loads game data from JSON files
## This class is designed to be portable - minimal engine-specific code
##
## Usage:
##   var characters = DataLoader.load_characters()
##   var skills = DataLoader.load_skills()
##   var enemies = DataLoader.load_enemies()
##   var config = DataLoader.load_combat_config()
##   var encounter = DataLoader.get_encounter("test_battle")

const DATA_PATH = "res://data/"


## Load all party character definitions
static func load_characters() -> Array:
	var data = _load_json_file(DATA_PATH + "characters/party.json")
	if data.has("characters"):
		return data.characters
	return []


## Load all skill definitions (with migration for old format)
static func load_skills() -> Dictionary:
	var data = _load_json_file(DATA_PATH + "skills/core_skills.json")
	var skills_by_id = {}
	if data.has("skills"):
		for skill in data.skills:
			_migrate_skill_data(skill)
			skills_by_id[skill.id] = skill
	return skills_by_id


## Load all enemy definitions
static func load_enemies() -> Dictionary:
	var data = _load_json_file(DATA_PATH + "enemies/test_enemies.json")
	var enemies_by_id = {}
	if data.has("enemies"):
		for enemy in data.enemies:
			enemies_by_id[enemy.id] = enemy
	return enemies_by_id


## Load combat config
static func load_combat_config() -> Dictionary:
	return _load_json_file(DATA_PATH + "combat/combat_config.json")


## Load encounters data
static func load_encounters() -> Dictionary:
	var data = _load_json_file(DATA_PATH + "combat/encounters.json")
	if data.has("encounters"):
		return data.encounters
	return {}


## Get a specific encounter by ID
static func get_encounter(encounter_id: String) -> Dictionary:
	var encounters = load_encounters()
	if encounters.has(encounter_id):
		return encounters[encounter_id]
	push_warning("Encounter not found: " + encounter_id)
	return {}


## Load a specific character by ID
static func get_character(character_id: String) -> Dictionary:
	var characters = load_characters()
	for character in characters:
		if character.id == character_id:
			return character
	push_warning("Character not found: " + character_id)
	return {}


## Load a specific skill by ID
static func get_skill(skill_id: String) -> Dictionary:
	var skills = load_skills()
	if skills.has(skill_id):
		return skills[skill_id]
	push_warning("Skill not found: " + skill_id)
	return {}


## Load a specific enemy by ID
static func get_enemy(enemy_id: String) -> Dictionary:
	var enemies = load_enemies()
	if enemies.has(enemy_id):
		return enemies[enemy_id]
	push_warning("Enemy not found: " + enemy_id)
	return {}


## Get all skills for a given role
static func get_skills_for_role(role: String) -> Array:
	var all_skills = load_skills()
	var role_skills = []
	for skill_id in all_skills:
		var skill = all_skills[skill_id]
		if skill.has("roles") and role in skill.roles:
			role_skills.append(skill)
	return role_skills


## Migrate old skill format to new unified grid format
## Adds range/range_type fields if missing based on old targeting data
static func _migrate_skill_data(skill: Dictionary) -> void:
	# Already has new format fields
	if skill.has("range") and skill.has("range_type"):
		return

	var targeting = skill.get("targeting", {})
	var old_range = targeting.get("range", "any")
	var target_type = targeting.get("type", "single_enemy")

	# Set range_type based on target_type
	if target_type == "self":
		if not skill.has("range_type"):
			skill["range_type"] = "self"
		return

	if target_type in ["all_allies", "all_enemies"]:
		if not skill.has("range_type"):
			skill["range_type"] = "all_allies" if "allies" in target_type else "all_enemies"
		return

	# Convert old range to new format
	if not skill.has("range"):
		match old_range:
			"adjacent":
				skill["range"] = 1
				if not skill.has("range_type"):
					skill["range_type"] = "melee"
			"any":
				skill["range"] = 0
				if not skill.has("range_type"):
					skill["range_type"] = "ranged"
			_:
				skill["range"] = 1
				if not skill.has("range_type"):
					skill["range_type"] = "melee"


## Internal: Load and parse a JSON file
static func _load_json_file(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		push_error("Data file not found: " + path)
		return {}

	var file = FileAccess.open(path, FileAccess.READ)
	if not file:
		push_error("Failed to open data file: " + path)
		return {}

	var json_text = file.get_as_text()
	file.close()

	var json = JSON.new()
	var parse_result = json.parse(json_text)
	if parse_result != OK:
		push_error("Failed to parse JSON in %s: %s" % [path, json.get_error_message()])
		return {}

	return json.data
