extends Node
## Main menu and entry point for the game


func _ready() -> void:
	GameManager.change_state(GameManager.GameState.MAIN_MENU)

	# Connect button signals
	$CanvasLayer/TestCombatButton.pressed.connect(_on_test_combat_pressed)
	$CanvasLayer/TestExplorationButton.pressed.connect(_on_test_exploration_pressed)
	$CanvasLayer/TestDialogueButton.pressed.connect(_on_test_dialogue_pressed)


func _on_test_combat_pressed() -> void:
	GameManager.open_combat_configurator("res://scenes/main.tscn")


func _on_test_exploration_pressed() -> void:
	print("Testing exploration")
	GameManager.change_state(GameManager.GameState.EXPLORATION)
	GameManager.transition_to_scene("res://scenes/exploration/test_exploration.tscn")


func _on_test_dialogue_pressed() -> void:
	GameManager.change_state(GameManager.GameState.DIALOG)
	GameManager.transition_to_scene("res://scenes/dialogue/test_dialogue.tscn")
