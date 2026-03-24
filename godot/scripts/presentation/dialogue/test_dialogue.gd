extends Control
## Test harness for the dialogue system. Loads a sample dialogue and
## provides a back button to return to the main menu.

const DataLoaderClass = preload("res://scripts/data/data_loader.gd")

@onready var dialogue_player: DialoguePlayer = $DialoguePlayer
@onready var back_button: Button = $UI/BackButton


func _ready() -> void:
	back_button.pressed.connect(_on_back_pressed)
	dialogue_player.dialogue_completed.connect(_on_dialogue_completed)

	# Load and start the test dialogue
	var dialogue_data = DataLoaderClass.load_dialogue("test_dialogue")
	if dialogue_data.is_empty():
		push_error("Failed to load test_dialogue")
		return
	dialogue_player.start_dialogue(dialogue_data)


func _on_dialogue_completed(_dialogue_id: String) -> void:
	print("Dialogue complete: ", _dialogue_id)
	# Show a completion message, then allow returning to menu
	back_button.text = "Dialogue Complete — Back to Menu"


func _on_back_pressed() -> void:
	GameManager.change_state(GameManager.GameState.MAIN_MENU)
	GameManager.transition_to_scene("res://scenes/main.tscn")
