extends Control
class_name VirtualJoystick
## Floating virtual joystick for touch movement input.
## Appears where the user touches the left half of the screen.
## Emits synthetic InputEventAction with proportional strength for analog movement.

@export var max_radius: float = 80.0
@export var dead_zone: float = 0.15  # Fraction of max_radius

var _touch_index: int = -1
var _center: Vector2 = Vector2.ZERO
var _is_active: bool = false

@onready var base_visual: ColorRect = $Base
@onready var knob_visual: ColorRect = $Knob


func _ready() -> void:
	base_visual.visible = false
	knob_visual.visible = false
	# Ensure we fill the left half of the screen
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func _input(event: InputEvent) -> void:
	if not visible:
		return
	if event is InputEventScreenTouch:
		_handle_touch(event)
	elif event is InputEventScreenDrag:
		_handle_drag(event)


func _handle_touch(event: InputEventScreenTouch) -> void:
	if event.pressed:
		# Only activate if touch is on the left half of the screen
		var viewport_width = get_viewport_rect().size.x
		if event.position.x > viewport_width * 0.5:
			return
		# Only capture if we don't already have a touch
		if _touch_index >= 0:
			return
		_touch_index = event.index
		_center = event.position
		_is_active = true
		_show_at(_center)
	else:
		if event.index == _touch_index:
			_release()


func _handle_drag(event: InputEventScreenDrag) -> void:
	if event.index != _touch_index:
		return
	var displacement = event.position - _center
	var distance = displacement.length()

	# Clamp to max radius
	if distance > max_radius:
		displacement = displacement.normalized() * max_radius
		distance = max_radius

	_update_knob_position(displacement)
	_emit_movement(displacement, distance)


func _release() -> void:
	_touch_index = -1
	_is_active = false
	base_visual.visible = false
	knob_visual.visible = false
	# Release all movement actions
	_emit_action("move_left", false, 0.0)
	_emit_action("move_right", false, 0.0)
	_emit_action("move_up", false, 0.0)
	_emit_action("move_down", false, 0.0)


func _show_at(pos: Vector2) -> void:
	base_visual.visible = true
	knob_visual.visible = true
	base_visual.position = pos - base_visual.size / 2.0
	knob_visual.position = pos - knob_visual.size / 2.0


func _update_knob_position(displacement: Vector2) -> void:
	knob_visual.position = _center + displacement - knob_visual.size / 2.0


func _emit_movement(displacement: Vector2, distance: float) -> void:
	var strength_fraction = distance / max_radius

	# Apply dead zone
	if strength_fraction < dead_zone:
		_emit_action("move_left", false, 0.0)
		_emit_action("move_right", false, 0.0)
		_emit_action("move_up", false, 0.0)
		_emit_action("move_down", false, 0.0)
		return

	# Remap strength past dead zone to 0-1 range
	var remapped = (strength_fraction - dead_zone) / (1.0 - dead_zone)
	var normalized = displacement.normalized()

	# Horizontal
	if normalized.x < 0:
		_emit_action("move_left", true, -normalized.x * remapped)
		_emit_action("move_right", false, 0.0)
	else:
		_emit_action("move_right", true, normalized.x * remapped)
		_emit_action("move_left", false, 0.0)

	# Vertical
	if normalized.y < 0:
		_emit_action("move_up", true, -normalized.y * remapped)
		_emit_action("move_down", false, 0.0)
	else:
		_emit_action("move_down", true, normalized.y * remapped)
		_emit_action("move_up", false, 0.0)


func _emit_action(action: String, pressed: bool, strength: float) -> void:
	var event = InputEventAction.new()
	event.action = action
	event.pressed = pressed
	event.strength = strength
	Input.parse_input_event(event)


func is_active() -> bool:
	return _is_active
