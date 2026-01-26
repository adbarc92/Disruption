class_name DataLoader
extends RefCounted
## DataLoader - Loads game data from JSON files
## This class is designed to be portable - minimal engine-specific code
##
## Usage:
##   var characters = DataLoader.load_characters()
##   var skills = DataLoader.load_skills()
##   var enemies = DataLoader.load_enemies()

const DATA_PATH = "res://data/"


## Load all party character definitions
static func load_characters() -> Array:
	var data = _load_json_file(DATA_PATH + "characters/party.json")
	if data.has("characters"):
		return data.characters
	return []


## Load all skill definitions
static func load_skills() -> Dictionary:
	var data = _load_json_file(DATA_PATH + "skills/core_skills.json")
	var skills_by_id = {}
	if data.has("skills"):
		for skill in data.skills:
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
