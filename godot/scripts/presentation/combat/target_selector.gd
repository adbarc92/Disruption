extends Node2D
class_name TargetSelector
## TargetSelector - Visual target selection for combat
## Highlights valid targets based on skill targeting rules

const PositionValidatorClass = preload("res://scripts/logic/combat/position_validator.gd")

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
var highlight_nodes: Array[ColorRect] = []

# References set by CombatManager
var ally_grid_node: Node2D
var enemy_grid_node: Node2D

const CELL_SIZE = Vector2(80, 80)


## Start target selection for a skill
func start_targeting(skill: Dictionary, user: Dictionary, allies: Array, enemies: Array, ally_grid: Node2D, enemy_grid: Node2D) -> void:
	current_skill = skill
	current_user = user
	ally_grid_node = ally_grid
	enemy_grid_node = enemy_grid
	is_active = true

	# Determine which side to target
	var user_is_ally = user.get("is_ally", true)
	var targets_allies = PositionValidatorClass.targets_allies(skill)
	var targets_enemies = PositionValidatorClass.targets_enemies(skill)

	# Get valid targets based on skill
	if targets_allies:
		if user_is_ally:
			valid_targets = PositionValidatorClass.get_valid_targets(skill, user, allies, true)
		else:
			valid_targets = PositionValidatorClass.get_valid_targets(skill, user, enemies, false)
	else:  # targets_enemies
		if user_is_ally:
			valid_targets = PositionValidatorClass.get_valid_targets(skill, user, enemies, true)
		else:
			valid_targets = PositionValidatorClass.get_valid_targets(skill, user, allies, false)

	# Check if skill targets all (no selection needed)
	if PositionValidatorClass.targets_all(skill):
		_auto_select_all()
		return

	# Highlight valid targets
	_show_target_highlights(targets_allies != user_is_ally)


## Start move targeting - highlights valid adjacent cells
func start_move_targeting(unit: Dictionary, grid: Dictionary, grid_node: Node2D) -> void:
	current_user = unit
	ally_grid_node = grid_node
	is_active = true
	is_move_mode = true

	valid_move_positions = PositionValidatorClass.get_valid_move_positions(unit, grid)

	if valid_move_positions.is_empty():
		is_active = false
		is_move_mode = false
		targeting_cancelled.emit()
		return

	_show_move_highlights(grid_node)


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
	for target in valid_targets:
		var target_rect = _get_target_rect(target)
		if target_rect.has_point(click_pos):
			_select_target(target)
			return


## Get the screen rect for a target
func _get_target_rect(target: Dictionary) -> Rect2:
	var grid_pos = target.get("grid_position", Vector2i(0, 0))
	var is_ally = target.get("is_ally", false)

	var grid_node = ally_grid_node if is_ally else enemy_grid_node
	if grid_node == null:
		return Rect2()

	var pos = Vector2(grid_pos.x, grid_pos.y) * CELL_SIZE - (CELL_SIZE * 1.5)
	var global_pos = grid_node.global_position + pos

	return Rect2(global_pos, CELL_SIZE)


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
	is_active = false
	_clear_highlights()
	target_selected.emit(target.get("id", ""))


## Show highlights on valid targets
func _show_target_highlights(target_enemy_side: bool) -> void:
	_clear_highlights()

	var grid_node = enemy_grid_node if target_enemy_side else ally_grid_node
	if grid_node == null:
		return

	for target in valid_targets:
		var grid_pos = target.get("grid_position", Vector2i(0, 0))
		var pos = Vector2(grid_pos.x, grid_pos.y) * CELL_SIZE - (CELL_SIZE * 1.5)

		var highlight = ColorRect.new()
		highlight.size = CELL_SIZE - Vector2(4, 4)
		highlight.position = pos + Vector2(2, 2)
		highlight.color = Color(1.0, 1.0, 0.0, 0.3)  # Yellow highlight
		highlight.name = "highlight_%s" % target.get("id", "")

		# Make it clickable by adding input handling
		highlight.mouse_filter = Control.MOUSE_FILTER_STOP
		highlight.gui_input.connect(_on_highlight_input.bind(target))

		grid_node.add_child(highlight)
		highlight_nodes.append(highlight)


## Clear all highlights
func _clear_highlights() -> void:
	for node in highlight_nodes:
		if is_instance_valid(node):
			node.queue_free()
	highlight_nodes.clear()


## Handle click on highlight
func _on_highlight_input(event: InputEvent, target: Dictionary) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		_select_target(target)


## Get currently valid targets (for UI display)
func get_valid_targets() -> Array:
	return valid_targets


## Check if targeting is active
func is_targeting() -> bool:
	return is_active


## Check if a click hit a valid move position
func _check_move_click(click_pos: Vector2) -> void:
	if ally_grid_node == null:
		return

	for pos in valid_move_positions:
		var cell_pos = Vector2(pos.x, pos.y) * CELL_SIZE - (CELL_SIZE * 1.5)
		var global_pos = ally_grid_node.global_position + cell_pos
		var rect = Rect2(global_pos, CELL_SIZE)
		if rect.has_point(click_pos):
			_select_move_position(pos)
			return


## Select a move position and emit signal
func _select_move_position(pos: Vector2i) -> void:
	is_active = false
	is_move_mode = false
	valid_move_positions.clear()
	_clear_highlights()
	move_position_selected.emit(pos)


## Show highlights on valid move positions
func _show_move_highlights(grid_node: Node2D) -> void:
	_clear_highlights()

	for pos in valid_move_positions:
		var cell_pos = Vector2(pos.x, pos.y) * CELL_SIZE - (CELL_SIZE * 1.5)

		var highlight = ColorRect.new()
		highlight.size = CELL_SIZE - Vector2(4, 4)
		highlight.position = cell_pos + Vector2(2, 2)
		highlight.color = Color(0.0, 1.0, 0.0, 0.3)  # Green highlight for move
		highlight.name = "move_highlight_%d_%d" % [pos.x, pos.y]

		highlight.mouse_filter = Control.MOUSE_FILTER_STOP
		highlight.gui_input.connect(_on_move_highlight_input.bind(pos))

		grid_node.add_child(highlight)
		highlight_nodes.append(highlight)


## Handle click on move highlight
func _on_move_highlight_input(event: InputEvent, pos: Vector2i) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		_select_move_position(pos)
