extends Node2D
class_name TargetSelector
## TargetSelector - Visual target selection for combat on unified grid
## Highlights valid targets based on skill targeting rules

const PositionValidatorClass = preload("res://scripts/logic/combat/position_validator.gd")
const GridPathfinderClass = preload("res://scripts/logic/combat/grid_pathfinder.gd")
const CombatConfigLoaderClass = preload("res://scripts/logic/combat/combat_config_loader.gd")

signal target_selected(target_id: String)
signal targeting_cancelled()
signal move_position_selected(position: Vector2i)

var valid_targets: Array = []
var current_skill: Dictionary = {}
var current_user: Dictionary = {}
var is_active: bool = false

# Move targeting state
var is_move_mode: bool = false
var valid_move_positions: Array[Vector2i] = []

# Visual nodes for highlighting
var highlight_nodes: Array[Node2D] = []

# Unified grid reference
var grid_node_ref: Node2D
var grid_ref: Dictionary = {}
var grid_size_ref: Vector2i = Vector2i(10, 6)
var all_units_ref: Dictionary = {}
var status_manager = null

var hex_size: float = 48.0
const HEX_INSET: float = 2.0


## Convert grid position to visual position (pointy-top, odd-row offset)
func _grid_to_visual(grid_pos: Vector2i) -> Vector2:
	var col = grid_pos.x
	var row = grid_pos.y
	var x = hex_size * sqrt(3.0) * (col + 0.5 * (row & 1))
	var y = hex_size * 1.5 * row
	return Vector2(x, y)


## Generate pointy-top hex polygon vertices centered at origin
func _hex_polygon(size: float) -> PackedVector2Array:
	var points = PackedVector2Array()
	for i in range(6):
		var angle_deg = 60.0 * i - 30.0
		var angle_rad = deg_to_rad(angle_deg)
		points.append(Vector2(size * cos(angle_rad), size * sin(angle_rad)))
	return points


## Convert pixel position to grid offset coordinates (pointy-top hex)
func _pixel_to_hex(pixel: Vector2) -> Vector2i:
	var q_frac = (sqrt(3.0) / 3.0 * pixel.x - 1.0 / 3.0 * pixel.y) / hex_size
	var r_frac = (2.0 / 3.0 * pixel.y) / hex_size
	var s_frac = -q_frac - r_frac
	var q = round(q_frac)
	var r = round(r_frac)
	var s = round(s_frac)
	var q_diff = abs(q - q_frac)
	var r_diff = abs(r - r_frac)
	var s_diff = abs(s - s_frac)
	if q_diff > r_diff and q_diff > s_diff:
		q = -r - s
	elif r_diff > s_diff:
		r = -q - s
	var row = int(r)
	var col = int(q) + (int(r) - (int(r) & 1)) / 2
	return Vector2i(col, row)


## Start target selection for a skill (unified grid)
func start_targeting(skill: Dictionary, user: Dictionary, p_all_units: Dictionary, p_grid: Dictionary, p_grid_size: Vector2i, p_grid_node: Node2D, p_status_manager = null, p_hex_size: float = 0.0) -> void:
	current_skill = skill
	current_user = user
	all_units_ref = p_all_units
	grid_ref = p_grid
	grid_size_ref = p_grid_size
	grid_node_ref = p_grid_node

	if p_hex_size > 0.0:
		hex_size = p_hex_size
	else:
		hex_size = CombatConfigLoaderClass.get_hex_size()

	if p_status_manager != null:
		status_manager = p_status_manager
	is_active = true

	# Determine which side to target
	var user_is_ally = user.get("is_ally", true)
	var targets_allies_flag = PositionValidatorClass.targets_allies(skill)

	# Build potential target list
	var potential_targets: Array = []
	for uid in all_units_ref:
		var u = all_units_ref[uid]
		if targets_allies_flag:
			if u.get("is_ally", true) == user_is_ally:
				potential_targets.append(u)
		else:
			if u.get("is_ally", true) != user_is_ally:
				potential_targets.append(u)

	# Get valid targets based on skill range
	valid_targets = PositionValidatorClass.get_valid_targets(skill, user, potential_targets, all_units_ref, grid_ref, grid_size_ref)

	# Enforce taunt: if player is taunted and targeting enemies, restrict to taunter
	if user_is_ally and not targets_allies_flag and status_manager != null:
		var taunt_data = status_manager.get_status_data(user.get("id", ""), "taunted")
		if not taunt_data.is_empty() and taunt_data.get("attacks_redirected", 0) > 0:
			var taunter_id = taunt_data.get("taunter_id", "")
			if taunter_id != "":
				valid_targets = valid_targets.filter(func(t): return t.get("id", "") == taunter_id)

	# Check if skill targets all (no selection needed)
	if PositionValidatorClass.targets_all(skill):
		_auto_select_all()
		return

	# Highlight valid targets
	_show_target_highlights()


## Start move targeting - highlights valid reachable cells
func start_move_targeting(unit: Dictionary, p_grid: Dictionary, p_grid_size: Vector2i, p_grid_node: Node2D, p_hex_size: float = 0.0) -> void:
	current_user = unit
	grid_ref = p_grid
	grid_size_ref = p_grid_size
	grid_node_ref = p_grid_node

	if p_hex_size > 0.0:
		hex_size = p_hex_size
	else:
		hex_size = CombatConfigLoaderClass.get_hex_size()

	is_active = true
	is_move_mode = true

	valid_move_positions = PositionValidatorClass.get_valid_move_positions(unit, p_grid, p_grid_size)

	if valid_move_positions.is_empty():
		is_active = false
		is_move_mode = false
		targeting_cancelled.emit()
		return

	_show_move_highlights()


## Cancel targeting mode
func cancel_targeting() -> void:
	is_active = false
	is_move_mode = false
	valid_targets.clear()
	valid_move_positions.clear()
	_clear_highlights()
	targeting_cancelled.emit()


## Handle input for target selection
func _input(event: InputEvent) -> void:
	if not is_active:
		return

	if event is InputEventKey and event.pressed:
		if event.keycode == KEY_ESCAPE:
			cancel_targeting()
			get_viewport().set_input_as_handled()
			return

	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		var click_pos = get_global_mouse_position()
		if is_move_mode:
			_check_move_click(click_pos)
		else:
			_check_target_click(click_pos)


## Check if a click hit a valid target
func _check_target_click(click_pos: Vector2) -> void:
	if grid_node_ref == null:
		return
	var local_pos = click_pos - grid_node_ref.global_position
	var hex_pos = _pixel_to_hex(local_pos)

	for target in valid_targets:
		var target_grid_pos = target.get("grid_position", Vector2i(-1, -1))
		if hex_pos == target_grid_pos:
			_select_target(target)
			return


## Auto-select for "all" targeting skills
func _auto_select_all() -> void:
	if valid_targets.is_empty():
		cancel_targeting()
		return

	# For "self" targeting, just select the user
	if PositionValidatorClass.get_targeting_type(current_skill) == "self":
		_select_target(current_user)
		return

	# For "all allies" or "all enemies", emit with first target (CombatManager handles all)
	_select_target(valid_targets[0])


## Select a target and emit signal
func _select_target(target: Dictionary) -> void:
	if not is_active:
		return
	is_active = false
	_clear_highlights()
	target_selected.emit(target.get("id", ""))


## Show highlights on valid targets (unified grid)
func _show_target_highlights() -> void:
	_clear_highlights()
	if grid_node_ref == null:
		return

	var inset_size = hex_size - HEX_INSET
	var hex_poly = _hex_polygon(inset_size)

	for target in valid_targets:
		var grid_pos = target.get("grid_position", Vector2i(0, 0))
		var pos = _grid_to_visual(grid_pos)

		var highlight = Polygon2D.new()
		highlight.polygon = hex_poly
		highlight.position = pos
		highlight.color = Color(1.0, 1.0, 0.0, 0.3)
		highlight.name = "highlight_%s" % target.get("id", "")

		grid_node_ref.add_child(highlight)
		highlight_nodes.append(highlight)


## Clear all highlights
func _clear_highlights() -> void:
	for node in highlight_nodes:
		if is_instance_valid(node):
			node.queue_free()
	highlight_nodes.clear()


## Get currently valid targets (for UI display)
func get_valid_targets() -> Array:
	return valid_targets


## Check if targeting is active
func is_targeting() -> bool:
	return is_active


## Check if a click hit a valid move position
func _check_move_click(click_pos: Vector2) -> void:
	if grid_node_ref == null:
		return
	var local_pos = click_pos - grid_node_ref.global_position
	var hex_pos = _pixel_to_hex(local_pos)

	if hex_pos in valid_move_positions:
		_select_move_position(hex_pos)


## Select a move position and emit signal
func _select_move_position(pos: Vector2i) -> void:
	if not is_active:
		return
	is_active = false
	is_move_mode = false
	valid_move_positions.clear()
	_clear_highlights()
	move_position_selected.emit(pos)


## Show highlights on valid move positions
func _show_move_highlights() -> void:
	_clear_highlights()
	if grid_node_ref == null:
		return

	var inset_size = hex_size - HEX_INSET
	var hex_poly = _hex_polygon(inset_size)

	for pos in valid_move_positions:
		var cell_pos = _grid_to_visual(pos)

		var highlight = Polygon2D.new()
		highlight.polygon = hex_poly
		highlight.position = cell_pos
		highlight.color = Color(0.0, 1.0, 0.0, 0.3)
		highlight.name = "move_highlight_%d_%d" % [pos.x, pos.y]

		grid_node_ref.add_child(highlight)
		highlight_nodes.append(highlight)
