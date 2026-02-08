extends Node
## Main menu and entry point for the game

const DataLoaderClass = preload("res://scripts/data/data_loader.gd")


func _ready() -> void:
	GameManager.change_state(GameManager.GameState.MAIN_MENU)

	# Connect button signals
	$CanvasLayer/StartButton.pressed.connect(_on_start_pressed)
	$CanvasLayer/TestCombatButton.pressed.connect(_on_test_combat_pressed)
	$CanvasLayer/TestExplorationButton.pressed.connect(_on_test_exploration_pressed)


func _on_start_pressed() -> void:
	print("Starting game - Opening sequence")
	# TODO: Start with cutscene/opening sequence
	GameManager.transition_to_scene("res://scenes/exploration/test_exploration.tscn")


func _on_test_combat_pressed() -> void:
	print("Testing combat")
	# Load proper enemy data from JSON
	var enemies_data = DataLoaderClass.load_enemies()
	var test_enemies = [
		enemies_data.get("grunt_a", {"id": "grunt_a", "name": "Scout", "hp": 45}),
		enemies_data.get("grunt_b", {"id": "grunt_b", "name": "Brute", "hp": 80}),
		enemies_data.get("grunt_c", {"id": "grunt_c", "name": "Caster", "hp": 35}),
	]
	GameManager.start_combat(test_enemies, "res://scenes/main.tscn")


func _on_test_exploration_pressed() -> void:
	print("Testing exploration")
	GameManager.change_state(GameManager.GameState.EXPLORATION)
	GameManager.transition_to_scene("res://scenes/exploration/test_exploration.tscn")
