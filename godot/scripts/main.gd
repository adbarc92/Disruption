extends Node
## Main menu and entry point for the game


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
	var test_enemies = [
		{"id": "enemy_1", "name": "Test Enemy A", "hp": 50},
		{"id": "enemy_2", "name": "Test Enemy B", "hp": 50},
		{"id": "enemy_3", "name": "Test Enemy C", "hp": 50},
	]
	GameManager.start_combat(test_enemies, "res://scenes/main.tscn")


func _on_test_exploration_pressed() -> void:
	print("Testing exploration")
	GameManager.change_state(GameManager.GameState.EXPLORATION)
	GameManager.transition_to_scene("res://scenes/exploration/test_exploration.tscn")
