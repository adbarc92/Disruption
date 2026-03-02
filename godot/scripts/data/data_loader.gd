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


## Load all skill definitions from all known skill JSON files
static func load_skills() -> Dictionary:
	var skills_by_id = {}
	var skills_dir = DATA_PATH + "skills/"
	var skill_files = [
		"core_skills.json",
		"bladewarden_skills.json",
		"synergist_skills.json",
		"shadowfang_skills.json",
		"warcrier_skills.json",
		"ironskin_skills.json",
		"geovant_skills.json",
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


## Load all encounter presets (array format for UI listing)
static func load_encounters() -> Array:
	var data = _load_json_file(DATA_PATH + "combat/encounters.json")
	return data.get("encounters", [])


## Load a specific named encounter by ID (object-keyed format)
## Returns {} if not found; combat_manager falls back to legacy _combat_enemies loading
static func get_encounter(encounter_id: String) -> Dictionary:
	var data = _load_json_file(DATA_PATH + "combat/encounters.json")
	var encounters = data.get("encounters", {})
	# Support both array format and object-keyed format
	if encounters is Dictionary:
		return encounters.get(encounter_id, {})
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


## Load all equipment definitions from known equipment JSON files
static func load_equipment() -> Dictionary:
	var equipment_by_id = {}
	var equip_dir = DATA_PATH + "equipment/"
	var equip_files = [
		"weapons.json",
		"devices.json",
		"armor.json",
	]
	for file_name in equip_files:
		var path = equip_dir + file_name
		if not FileAccess.file_exists(path):
			continue
		var data = _load_json_file(path)
		if data.has("equipment"):
			for item in data.equipment:
				equipment_by_id[item.id] = item
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
