extends CanvasLayer
class_name TouchOverlay
## Touch overlay containing virtual joystick and action buttons.
## Listens to GameManager.state_changed for mode-aware visibility.

@onready var joystick: VirtualJoystick = $JoystickZone
@onready var action_buttons: Control = $ActionButtons
@onready var hop_button: Button = $ActionButtons/HopButton
@onready var roll_button: Button = $ActionButtons/RollButton
@onready var sprint_button: Button = $ActionButtons/SprintButton
@onready var grapple_button: Button = $ActionButtons/GrappleButton
@onready var interact_button: Button = $ActionButtons/InteractButton
@onready var cancel_button: Button = $CancelButton


func _ready() -> void:
	layer = 100  # Above all game UI
	# Start with context buttons hidden
	grapple_button.visible = false
	interact_button.visible = false

	# Connect GameManager state changes
	GameManager.state_changed.connect(_on_game_state_changed)

	# Connect EventBus proximity signals
	EventBus.grapple_point_nearby.connect(_on_grapple_nearby)
	EventBus.interactable_nearby.connect(_on_interactable_nearby)

	# Set initial visibility based on current state
	_update_visibility(GameManager.current_state)


func _on_game_state_changed(new_state: GameManager.GameState, _old_state: GameManager.GameState) -> void:
	_update_visibility(new_state)


func _update_visibility(state: GameManager.GameState) -> void:
	match state:
		GameManager.GameState.EXPLORATION:
			joystick.visible = true
			action_buttons.visible = true
			cancel_button.visible = true
			# Reset context buttons — proximity signals will re-show if still nearby
			grapple_button.visible = false
			interact_button.visible = false
		GameManager.GameState.COMBAT:
			joystick.visible = false
			action_buttons.visible = false
			cancel_button.visible = true
		GameManager.GameState.DIALOG:
			joystick.visible = false
			action_buttons.visible = false
			cancel_button.visible = true
		_:
			joystick.visible = false
			action_buttons.visible = false
			cancel_button.visible = false


func _on_grapple_nearby(is_nearby: bool) -> void:
	grapple_button.visible = is_nearby


func _on_interactable_nearby(is_nearby: bool) -> void:
	interact_button.visible = is_nearby
