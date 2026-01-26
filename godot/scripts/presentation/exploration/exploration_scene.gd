extends Node2D
## Base exploration scene script
## Handles camera following, scene setup, and common exploration logic

@onready var player: PlayerController = $Player
@onready var camera: Camera2D = $Camera2D

var camera_smoothing: float = 5.0


func _ready() -> void:
	GameManager.change_state(GameManager.GameState.EXPLORATION)

	# Connect UI
	if has_node("UI/BackButton"):
		$UI/BackButton.pressed.connect(_on_back_pressed)

	# Connect player signals
	if player:
		player.interacted.connect(_on_player_interacted)

	# Add grapple points to group
	_setup_grapple_points()


func _process(delta: float) -> void:
	_update_camera(delta)


func _input(event: InputEvent) -> void:
	if event.is_action_pressed("cancel"):
		_on_back_pressed()


func _update_camera(delta: float) -> void:
	if player and camera:
		var target_pos = player.global_position
		camera.global_position = camera.global_position.lerp(target_pos, camera_smoothing * delta)


func _setup_grapple_points() -> void:
	# Find all Marker2D nodes that are grapple points and add them to the group
	for child in $World.get_children():
		if child.name.begins_with("GrapplePoint"):
			child.add_to_group("grapple_points")
			print("Added grapple point: ", child.name, " at ", child.global_position)


func _on_back_pressed() -> void:
	GameManager.change_state(GameManager.GameState.MAIN_MENU)
	GameManager.transition_to_scene("res://scenes/main.tscn")


func _on_player_interacted(interactable: Node) -> void:
	print("Player interacted with: ", interactable.name)

	# Handle different interactable types
	if interactable.is_in_group("enemies"):
		_start_combat_with(interactable)
	elif interactable.is_in_group("npcs"):
		_start_dialog_with(interactable)
	elif interactable.has_method("interact"):
		interactable.interact()


func _start_combat_with(enemy: Node) -> void:
	var enemy_data = []

	if enemy.has_method("get_combat_data"):
		enemy_data = enemy.get_combat_data()
	else:
		# Default test enemy data
		enemy_data = [
			{"id": "enemy_1", "name": "Enemy", "hp": 50},
		]

	GameManager.start_combat(enemy_data, get_tree().current_scene.scene_file_path)


func _start_dialog_with(npc: Node) -> void:
	if npc.has_method("get_dialog_id"):
		var dialog_id = npc.get_dialog_id()
		# TODO: Start dialog system
		print("Would start dialog: ", dialog_id)
