extends Node
## EventBus - Global signal hub for decoupled communication
## Allows systems to communicate without direct references

# Exploration signals
signal player_moved(position: Vector2)
signal player_interacted(interactable: Node)
signal area_entered(area_name: String)
signal obstacle_encountered(obstacle_type: String)

# Combat signals
signal combat_started(enemies: Array)
signal combat_ended(victory: bool)
signal turn_started(unit_id: String)
signal turn_ended(unit_id: String)
signal action_performed(action_data: Dictionary)
signal unit_damaged(unit_id: String, damage: int, damage_type: String)
signal unit_healed(unit_id: String, amount: int)
signal unit_defeated(unit_id: String)
signal position_changed(unit_id: String, old_pos: Vector2i, new_pos: Vector2i)
signal status_applied(unit_id: String, status: String)
signal status_removed(unit_id: String, status: String)
signal burst_gauge_changed(unit_id: String, new_value: int)
signal burst_mode_activated(unit_id: String)
signal burst_mode_ended(unit_id: String)

# Dialog signals
signal dialog_started(dialog_id: String)
signal dialog_ended(dialog_id: String)
signal dialog_choice_made(choice_index: int, choice_text: String)
signal dialog_line_displayed(speaker: String, text: String)

# Cutscene signals
signal cutscene_started(cutscene_id: String)
signal cutscene_ended(cutscene_id: String)
signal cutscene_skipped(cutscene_id: String)

# UI signals
signal ui_notification(message: String, type: String)
signal menu_opened(menu_name: String)
signal menu_closed(menu_name: String)

# Save/Load signals
signal save_requested()
signal load_requested()
signal save_completed(success: bool)
signal load_completed(success: bool)


func _ready() -> void:
	print("EventBus initialized")
