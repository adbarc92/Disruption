extends Node
## UILayoutManager - Detects viewport breakpoints and emits layout signals.

enum LayoutBreakpoint { WIDE, MEDIUM, NARROW }

var current_breakpoint: LayoutBreakpoint = LayoutBreakpoint.WIDE

signal breakpoint_changed(new_breakpoint: LayoutBreakpoint)
signal overlay_toggled(panel_name: String, visible: bool)

# Overlay state - only one overlay open at a time
var _active_overlay: String = ""

const WIDE_THRESHOLD = 1280.0
const MEDIUM_THRESHOLD = 800.0


func _ready() -> void:
	get_tree().root.size_changed.connect(_on_viewport_resized)
	# Initial calculation deferred so all nodes are ready
	_on_viewport_resized.call_deferred()


func _on_viewport_resized() -> void:
	var width = get_viewport().get_visible_rect().size.x
	var new_breakpoint = _calculate_breakpoint(width)
	if new_breakpoint != current_breakpoint:
		current_breakpoint = new_breakpoint
		breakpoint_changed.emit(current_breakpoint)
		# Close any open overlay when breakpoint changes
		if _active_overlay != "":
			_close_overlay()


func _calculate_breakpoint(width: float) -> LayoutBreakpoint:
	if width >= WIDE_THRESHOLD:
		return LayoutBreakpoint.WIDE
	elif width >= MEDIUM_THRESHOLD:
		return LayoutBreakpoint.MEDIUM
	else:
		return LayoutBreakpoint.NARROW


func get_viewport_size() -> Vector2:
	return get_viewport().get_visible_rect().size


func toggle_overlay(panel_name: String) -> void:
	if _active_overlay == panel_name:
		_close_overlay()
	else:
		# Close previous overlay first
		if _active_overlay != "":
			overlay_toggled.emit(_active_overlay, false)
		_active_overlay = panel_name
		overlay_toggled.emit(panel_name, true)


func _close_overlay() -> void:
	var was = _active_overlay
	_active_overlay = ""
	overlay_toggled.emit(was, false)


func is_overlay_open(panel_name: String) -> bool:
	return _active_overlay == panel_name
