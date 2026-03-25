extends Node
## TouchInputManager - Detects touch activity and manages the touch overlay.
## Shows overlay on touch, hides after inactivity timeout.

const TOUCH_OVERLAY_SCENE = preload("res://scenes/ui/touch_overlay.tscn")
const HIDE_TIMEOUT: float = 3.0

var is_touch_active: bool = false
var _overlay: CanvasLayer = null
var _hide_timer: float = 0.0


func _ready() -> void:
	_overlay = TOUCH_OVERLAY_SCENE.instantiate()
	add_child(_overlay)
	_overlay.visible = false
	print("TouchInputManager initialized")


func _input(event: InputEvent) -> void:
	if event is InputEventScreenTouch or event is InputEventScreenDrag:
		_on_touch_detected()


func _process(delta: float) -> void:
	if is_touch_active:
		_hide_timer -= delta
		if _hide_timer <= 0.0:
			_hide_overlay()


func _on_touch_detected() -> void:
	_hide_timer = HIDE_TIMEOUT
	if not is_touch_active:
		is_touch_active = true
		_overlay.visible = true


func _hide_overlay() -> void:
	is_touch_active = false
	_overlay.visible = false
