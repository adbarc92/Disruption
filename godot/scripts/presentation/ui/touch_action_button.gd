extends Button
class_name TouchActionButton
## Reusable touch button that emits synthetic InputEventAction events.
## Emits pressed on touch-down and released on touch-up, supporting hold behavior.
## Uses Button (not TextureButton) so it's clickable without textures during development.

@export var action_name: String = ""

func _ready() -> void:
	button_down.connect(_on_button_down)
	button_up.connect(_on_button_up)


func _on_button_down() -> void:
	if action_name.is_empty():
		return
	var event = InputEventAction.new()
	event.action = action_name
	event.pressed = true
	event.strength = 1.0
	Input.parse_input_event(event)


func _on_button_up() -> void:
	if action_name.is_empty():
		return
	var event = InputEventAction.new()
	event.action = action_name
	event.pressed = false
	event.strength = 0.0
	Input.parse_input_event(event)
