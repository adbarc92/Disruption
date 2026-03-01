extends Node
## GameManager - Global game state management
## Handles scene transitions, game state, and high-level game flow

const DataLoaderClass = preload("res://scripts/data/data_loader.gd")

enum GameState {
	MAIN_MENU,
	EXPLORATION,
	COMBAT,
	DIALOG,
	CUTSCENE,
	PAUSED,
	COMBAT_CONFIG,
}

var current_state: GameState = GameState.MAIN_MENU
var previous_state: GameState = GameState.MAIN_MENU

# Party data
var party: Array[Dictionary] = []
var party_position: Vector2 = Vector2.ZERO

# Story/consequence tracking
var story_flags: Dictionary = {}
var consequence_values: Dictionary = {}

signal state_changed(new_state: GameState, old_state: GameState)
signal party_updated()


func _ready() -> void:
	print("GameManager initialized")
	_initialize_party()


func _initialize_party() -> void:
	# Load party from data files
	var character_data = DataLoaderClass.load_characters()

	# Initialize with vertical slice party: Cyrus, Vaughn, Phaidros
	var party_ids = ["cyrus", "vaughn", "phaidros"]

	for char_data in character_data:
		if char_data.id in party_ids:
			party.append(_create_party_member_from_data(char_data))

	party_updated.emit()


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
		"starting_abilities": char_data.get("starting_abilities", []),
		"abilities": char_data.get("starting_abilities", []),
		"equipment": char_data.get("equipment", []),
		"equipment_proficiencies": char_data.get("equipment_proficiencies", []),
		"base_stats": stats,
		"roles": char_data.get("roles", []),
		"burst_mode": char_data.get("burst_mode", {}),
	}


func change_state(new_state: GameState) -> void:
	if new_state == current_state:
		return

	previous_state = current_state
	current_state = new_state
	state_changed.emit(current_state, previous_state)
	print("Game state changed: %s -> %s" % [GameState.keys()[previous_state], GameState.keys()[current_state]])


func set_story_flag(flag_name: String, value: bool = true) -> void:
	story_flags[flag_name] = value
	print("Story flag set: %s = %s" % [flag_name, value])


func get_story_flag(flag_name: String, default: bool = false) -> bool:
	return story_flags.get(flag_name, default)


func modify_consequence(key: String, delta: int) -> void:
	if not consequence_values.has(key):
		consequence_values[key] = 0
	consequence_values[key] += delta
	print("Consequence modified: %s = %d" % [key, consequence_values[key]])


func get_consequence(key: String, default: int = 0) -> int:
	return consequence_values.get(key, default)


func transition_to_scene(scene_path: String) -> void:
	# Simple scene transition - can be enhanced with loading screen later
	get_tree().change_scene_to_file(scene_path)


func open_combat_configurator(return_scene: String) -> void:
	story_flags["_combat_return_scene"] = return_scene
	change_state(GameState.COMBAT_CONFIG)
	transition_to_scene("res://scenes/combat/combat_configurator.tscn")


func start_combat(enemy_data: Array, return_scene: String) -> void:
	# Store return point
	story_flags["_combat_return_scene"] = return_scene
	story_flags["_combat_enemies"] = enemy_data
	change_state(GameState.COMBAT)
	transition_to_scene("res://scenes/combat/combat_arena.tscn")


func end_combat(victory: bool) -> void:
	var return_scene = story_flags.get("_combat_return_scene", "res://scenes/main.tscn")
	change_state(GameState.EXPLORATION)
	if victory:
		set_story_flag("_last_combat_victory", true)
	transition_to_scene(return_scene)
