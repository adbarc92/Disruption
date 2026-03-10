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


## Load role definitions from roles.json
static func load_roles() -> Dictionary:
	var roles_by_id = {}
	var data = _load_json_file(DATA_PATH + "roles/roles.json")
	if data.has("roles"):
		for role in data.roles:
			roles_by_id[role.id] = role
	return roles_by_id


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
	var roles_db = load_roles()
	var all_skills = load_skills()
	var role_skills = []
	var role_data = roles_db.get(role, {})
	for skill_id in role_data.get("skills", []):
		if all_skills.has(skill_id):
			role_skills.append(all_skills[skill_id])
	return role_skills


## Load all equipment definitions
static func load_equipment() -> Dictionary:
	var equipment_by_id = {}
	var data = _load_json_file(DATA_PATH + "equipment/equipment.json")
	if data.has("equipment"):
		for item in data.equipment:
			equipment_by_id[item.id] = item
	return equipment_by_id


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
