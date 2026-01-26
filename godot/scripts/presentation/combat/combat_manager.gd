extends Node2D
class_name CombatManager
## Manages the turn-based combat system
## Handles turn order, actions, and combat flow

# Grid configuration (3x3 per side)
const GRID_SIZE = Vector2i(3, 3)
const CELL_SIZE = Vector2(80, 80)

# Combat state
enum CombatPhase {
	INITIALIZING,
	TURN_START,
	SELECTING_ACTION,
	SELECTING_TARGET,
	EXECUTING_ACTION,
	TURN_END,
	VICTORY,
	DEFEAT,
}

var current_phase: CombatPhase = CombatPhase.INITIALIZING
var turn_order: Array = []
var current_turn_index: int = 0
var current_unit: Dictionary = {}

# Units in combat
var ally_units: Array[Dictionary] = []
var enemy_units: Array[Dictionary] = []

# Grid positions (Vector2i -> unit_id)
var ally_grid: Dictionary = {}
var enemy_grid: Dictionary = {}

# Selected action/target
var selected_action: String = ""
var selected_target: Dictionary = {}

# Node references
@onready var ally_grid_node: Node2D = $BattleGrid/AllyGrid
@onready var enemy_grid_node: Node2D = $BattleGrid/EnemyGrid
@onready var turn_list: VBoxContainer = $UI/TurnOrderPanel/TurnList
@onready var status_label: Label = $UI/StatusLabel
@onready var action_panel: Panel = $UI/ActionPanel


func _ready() -> void:
	GameManager.change_state(GameManager.GameState.COMBAT)

	# Connect UI buttons
	$UI/ActionPanel/ActionButtons/AttackButton.pressed.connect(_on_attack_pressed)
	$UI/ActionPanel/ActionButtons/SkillButton.pressed.connect(_on_skill_pressed)
	$UI/ActionPanel/ActionButtons/ItemButton.pressed.connect(_on_item_pressed)
	$UI/ActionPanel/ActionButtons/MoveButton.pressed.connect(_on_move_pressed)
	$UI/ActionPanel/ActionButtons/DefendButton.pressed.connect(_on_defend_pressed)
	$UI/BackButton.pressed.connect(_on_back_pressed)

	# Initialize combat
	_initialize_combat()


func _initialize_combat() -> void:
	current_phase = CombatPhase.INITIALIZING
	status_label.text = "Initializing Combat..."

	# Load party from GameManager
	_load_party_units()

	# Load enemies from stored data
	_load_enemy_units()

	# Place units on grids
	_place_units_on_grid()

	# Calculate initial turn order
	_calculate_turn_order()

	# Draw grid visuals
	_draw_grids()

	# Start first turn
	_start_next_turn()


func _load_party_units() -> void:
	ally_units.clear()
	for i in range(GameManager.party.size()):
		var member = GameManager.party[i].duplicate()
		member["is_ally"] = true
		member["grid_position"] = _get_default_ally_position(i)
		member["initiative"] = randf_range(10, 20)  # TODO: Calculate from stats
		ally_units.append(member)


func _load_enemy_units() -> void:
	enemy_units.clear()
	var enemy_data = GameManager.story_flags.get("_combat_enemies", [])

	for i in range(enemy_data.size()):
		var enemy = enemy_data[i].duplicate()
		enemy["is_ally"] = false
		enemy["grid_position"] = _get_default_enemy_position(i)
		enemy["current_hp"] = enemy.get("hp", 50)
		enemy["max_hp"] = enemy.get("hp", 50)
		enemy["initiative"] = randf_range(5, 15)
		enemy_units.append(enemy)


func _get_default_ally_position(index: int) -> Vector2i:
	# Back column by default
	match index:
		0: return Vector2i(2, 1)  # Back middle
		1: return Vector2i(2, 0)  # Back top
		2: return Vector2i(2, 2)  # Back bottom
		_: return Vector2i(1, index % 3)


func _get_default_enemy_position(index: int) -> Vector2i:
	# Front column by default
	match index:
		0: return Vector2i(0, 1)  # Front middle
		1: return Vector2i(0, 0)  # Front top
		2: return Vector2i(0, 2)  # Front bottom
		_: return Vector2i(1, index % 3)


func _place_units_on_grid() -> void:
	ally_grid.clear()
	enemy_grid.clear()

	for unit in ally_units:
		ally_grid[unit.grid_position] = unit.id

	for unit in enemy_units:
		enemy_grid[unit.grid_position] = unit.id


func _calculate_turn_order() -> void:
	turn_order.clear()

	# Combine all units
	var all_units = ally_units + enemy_units

	# Sort by initiative (descending)
	all_units.sort_custom(func(a, b): return a.initiative > b.initiative)

	turn_order = all_units
	current_turn_index = 0

	_update_turn_order_ui()


func _update_turn_order_ui() -> void:
	# Clear existing
	for child in turn_list.get_children():
		child.queue_free()

	# Add turn order entries
	for i in range(min(turn_order.size(), 8)):
		var unit = turn_order[(current_turn_index + i) % turn_order.size()]
		var label = Label.new()
		label.text = "%s%s" % ["-> " if i == 0 else "   ", unit.name]
		label.add_theme_color_override("font_color", Color.CYAN if unit.is_ally else Color.RED)
		turn_list.add_child(label)


func _draw_grids() -> void:
	# Draw ally grid
	_draw_grid_cells(ally_grid_node, true)

	# Draw enemy grid
	_draw_grid_cells(enemy_grid_node, false)


func _draw_grid_cells(grid_node: Node2D, is_ally: bool) -> void:
	# Clear existing
	for child in grid_node.get_children():
		child.queue_free()

	var base_color = Color(0.2, 0.4, 0.6, 0.3) if is_ally else Color(0.6, 0.2, 0.2, 0.3)

	for x in range(GRID_SIZE.x):
		for y in range(GRID_SIZE.y):
			var cell = ColorRect.new()
			cell.size = CELL_SIZE - Vector2(4, 4)
			cell.position = Vector2(x, y) * CELL_SIZE - (CELL_SIZE * 1.5) + Vector2(2, 2)
			cell.color = base_color
			grid_node.add_child(cell)

	# Draw units
	var units = ally_units if is_ally else enemy_units
	for unit in units:
		var unit_visual = ColorRect.new()
		unit_visual.size = Vector2(40, 60)
		var pos = Vector2(unit.grid_position.x, unit.grid_position.y) * CELL_SIZE - (CELL_SIZE * 1.5)
		unit_visual.position = pos + Vector2(20, 10)
		unit_visual.color = Color.BLUE if is_ally else Color.RED
		unit_visual.name = unit.id

		var label = Label.new()
		label.text = unit.name.substr(0, 3)
		label.position = Vector2(-10, -20)
		unit_visual.add_child(label)

		grid_node.add_child(unit_visual)


func _start_next_turn() -> void:
	if _check_combat_end():
		return

	current_unit = turn_order[current_turn_index]
	current_phase = CombatPhase.TURN_START

	status_label.text = "%s's turn" % current_unit.name
	_update_turn_order_ui()

	EventBus.turn_started.emit(current_unit.id)

	# If AI controlled, handle AI turn
	if not current_unit.is_ally:
		_handle_ai_turn()
	else:
		current_phase = CombatPhase.SELECTING_ACTION
		action_panel.visible = true


func _handle_ai_turn() -> void:
	action_panel.visible = false
	status_label.text = "%s is thinking..." % current_unit.name

	# Simple AI: attack random ally
	await get_tree().create_timer(0.5).timeout

	var target = ally_units[randi() % ally_units.size()]
	var damage = randi_range(5, 15)

	_apply_damage(target, damage)

	status_label.text = "%s attacks %s for %d damage!" % [current_unit.name, target.name, damage]

	await get_tree().create_timer(1.0).timeout

	_end_turn()


func _apply_damage(target: Dictionary, damage: int) -> void:
	target.current_hp = max(0, target.current_hp - damage)
	EventBus.unit_damaged.emit(target.id, damage, "physical")

	if target.current_hp <= 0:
		EventBus.unit_defeated.emit(target.id)


func _end_turn() -> void:
	current_phase = CombatPhase.TURN_END
	EventBus.turn_ended.emit(current_unit.id)

	# Advance turn order
	current_turn_index = (current_turn_index + 1) % turn_order.size()

	# Check for defeated units
	_remove_defeated_units()

	# Start next turn
	_start_next_turn()


func _remove_defeated_units() -> void:
	ally_units = ally_units.filter(func(u): return u.current_hp > 0)
	enemy_units = enemy_units.filter(func(u): return u.current_hp > 0)
	turn_order = turn_order.filter(func(u): return u.current_hp > 0)

	if current_turn_index >= turn_order.size():
		current_turn_index = 0

	_draw_grids()


func _check_combat_end() -> bool:
	if enemy_units.is_empty():
		_end_combat(true)
		return true
	elif ally_units.is_empty():
		_end_combat(false)
		return true
	return false


func _end_combat(victory: bool) -> void:
	current_phase = CombatPhase.VICTORY if victory else CombatPhase.DEFEAT
	status_label.text = "Victory!" if victory else "Defeat..."
	action_panel.visible = false

	EventBus.combat_ended.emit(victory)

	await get_tree().create_timer(2.0).timeout

	GameManager.end_combat(victory)


# Action handlers
func _on_attack_pressed() -> void:
	if current_phase != CombatPhase.SELECTING_ACTION:
		return

	selected_action = "attack"
	current_phase = CombatPhase.SELECTING_TARGET
	status_label.text = "Select target..."

	# For now, auto-select first enemy
	if not enemy_units.is_empty():
		var target = enemy_units[0]
		var damage = randi_range(10, 20)
		_apply_damage(target, damage)
		status_label.text = "%s attacks %s for %d damage!" % [current_unit.name, target.name, damage]
		_draw_grids()

		await get_tree().create_timer(1.0).timeout
		_end_turn()


func _on_skill_pressed() -> void:
	status_label.text = "Skills not yet implemented"


func _on_item_pressed() -> void:
	status_label.text = "Items not yet implemented"


func _on_move_pressed() -> void:
	status_label.text = "Movement not yet implemented"


func _on_defend_pressed() -> void:
	if current_phase != CombatPhase.SELECTING_ACTION:
		return

	status_label.text = "%s defends!" % current_unit.name

	await get_tree().create_timer(0.5).timeout
	_end_turn()


func _on_back_pressed() -> void:
	# Test exit - return to menu
	GameManager.end_combat(true)
