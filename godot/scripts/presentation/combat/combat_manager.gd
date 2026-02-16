extends Node2D
class_name CombatManager
## Manages the turn-based combat system with CTB turn order and AP economy.
## Uses CTBTurnManager for turn order and APSystem for action economy.

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
var current_unit: Dictionary = {}

# Units in combat
var ally_units: Array[Dictionary] = []
var enemy_units: Array[Dictionary] = []

# Quick lookup by ID
var _units_by_id: Dictionary = {}

# Grid positions (Vector2i -> unit_id)
var ally_grid: Dictionary = {}
var enemy_grid: Dictionary = {}

# Selected action/target
var selected_action: String = ""
var selected_target: Dictionary = {}

# Core systems (pure logic, no Godot dependencies)
var _ctb_manager: CTBTurnManager
var _ap_system: APSystem

# Node references
@onready var ally_grid_node: Node2D = $BattleGrid/AllyGrid
@onready var enemy_grid_node: Node2D = $BattleGrid/EnemyGrid
@onready var turn_list: VBoxContainer = $UI/TurnOrderPanel/TurnList
@onready var status_label: Label = $UI/StatusLabel
@onready var action_panel: Panel = $UI/ActionPanel
@onready var ap_label: Label = $UI/ActionPanel/APLabel
@onready var turn_preview_label: Label = $UI/ActionPanel/TurnPreviewLabel


func _ready() -> void:
	GameManager.change_state(GameManager.GameState.COMBAT)

	# Initialize logic systems
	_ctb_manager = CTBTurnManager.new()
	_ap_system = APSystem.new()

	# Connect UI buttons
	$UI/ActionPanel/ActionButtons/AttackButton.pressed.connect(_on_attack_pressed)
	$UI/ActionPanel/ActionButtons/SkillButton.pressed.connect(_on_skill_pressed)
	$UI/ActionPanel/ActionButtons/ItemButton.pressed.connect(_on_item_pressed)
	$UI/ActionPanel/ActionButtons/MoveButton.pressed.connect(_on_move_pressed)
	$UI/ActionPanel/ActionButtons/DefendButton.pressed.connect(_on_defend_pressed)
	$UI/ActionPanel/ActionButtons/EndTurnButton.pressed.connect(_on_end_turn_pressed)
	$UI/BackButton.pressed.connect(_on_back_pressed)

	# Initialize combat
	_initialize_combat()


func _initialize_combat() -> void:
	current_phase = CombatPhase.INITIALIZING
	status_label.text = "Initializing Combat..."

	# Reset logic systems
	_ap_system.reset()
	_units_by_id.clear()

	# Load party from GameManager
	_load_party_units()

	# Load enemies from stored data
	_load_enemy_units()

	# Place units on grids
	_place_units_on_grid()

	# Initialize CTB turn order
	_initialize_turn_order()

	# Draw grid visuals
	_draw_grids()

	# Update turn order display
	_update_turn_order_ui()

	# Start first turn
	_start_next_turn()


func _load_party_units() -> void:
	ally_units.clear()
	for i in range(GameManager.party.size()):
		var member = GameManager.party[i].duplicate(true)
		member["is_ally"] = true
		member["grid_position"] = _get_default_ally_position(i)

		# Extract stats for CTB and AP systems
		var base_stats = member.get("base_stats", {})
		member["speed"] = base_stats.get("agility", 5)
		member["constitution"] = base_stats.get("vigor", 5)

		ally_units.append(member)
		_units_by_id[member.id] = member

		# Register with AP system (constitution determines AP cap)
		_ap_system.register_unit(member.id, member.constitution, true)


func _load_enemy_units() -> void:
	enemy_units.clear()
	var enemy_data = GameManager.story_flags.get("_combat_enemies", [])

	for i in range(enemy_data.size()):
		var enemy = enemy_data[i].duplicate(true)
		enemy["is_ally"] = false
		enemy["grid_position"] = _get_default_enemy_position(i)
		enemy["current_hp"] = enemy.get("hp", 50)
		enemy["max_hp"] = enemy.get("hp", 50)

		# Extract stats for CTB
		var base_stats = enemy.get("base_stats", {})
		enemy["speed"] = base_stats.get("agility", 5)
		enemy["constitution"] = base_stats.get("vigor", 5)

		enemy_units.append(enemy)
		_units_by_id[enemy.id] = enemy

		# Register with AP system (enemies don't conserve AP)
		_ap_system.register_unit(enemy.id, enemy.constitution, false)


func _get_default_ally_position(index: int) -> Vector2i:
	match index:
		0: return Vector2i(2, 1)  # Back middle
		1: return Vector2i(2, 0)  # Back top
		2: return Vector2i(2, 2)  # Back bottom
		_: return Vector2i(1, index % 3)


func _get_default_enemy_position(index: int) -> Vector2i:
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


func _initialize_turn_order() -> void:
	# Initialize CTB manager with unit lookup
	_ctb_manager.initialize(func(unit_id): return _units_by_id.get(unit_id))

	# Add all units to turn queue
	for unit in ally_units:
		_ctb_manager.add_unit(unit.id, unit.speed)

	for unit in enemy_units:
		_ctb_manager.add_unit(unit.id, unit.speed)


func _update_turn_order_ui() -> void:
	# Clear existing
	for child in turn_list.get_children():
		child.queue_free()

	# Get current turn order preview (10 turns ahead)
	var preview = _ctb_manager.get_turn_order_preview()

	# Add turn order entries
	for i in range(min(preview.size(), 10)):
		var unit_id = preview[i]
		var unit = _units_by_id.get(unit_id, {})
		if unit.is_empty():
			continue

		var label = Label.new()
		var prefix = ">> " if i == 0 else "   "
		label.text = "%s%s" % [prefix, unit.get("name", "???")]
		label.add_theme_color_override("font_color", Color.CYAN if unit.get("is_ally", false) else Color.RED)
		turn_list.add_child(label)


func _update_ap_display() -> void:
	if current_unit.is_empty():
		ap_label.text = "AP: --"
		return

	var current_ap = _ap_system.get_current_ap(current_unit.id)
	var ap_cap = _ap_system.get_ap_cap(current_unit.id)
	ap_label.text = "AP: %d / %d" % [current_ap, ap_cap]

	# Show turn preview based on current remaining AP
	var remaining_ap = current_ap
	var speed = current_unit.get("speed", 5)
	var ticks = _ctb_manager.calculate_ticks_with_ap_bonus(speed, remaining_ap)
	turn_preview_label.text = "End turn now: %d ticks until next turn" % ticks


func _update_action_buttons() -> void:
	# Enable/disable buttons based on AP availability
	var attack_btn = $UI/ActionPanel/ActionButtons/AttackButton
	var skill_btn = $UI/ActionPanel/ActionButtons/SkillButton
	var item_btn = $UI/ActionPanel/ActionButtons/ItemButton
	var move_btn = $UI/ActionPanel/ActionButtons/MoveButton

	attack_btn.disabled = not _ap_system.can_afford(current_unit.id, "attack")
	skill_btn.disabled = not _ap_system.can_afford(current_unit.id, "skill_standard")
	item_btn.disabled = not _ap_system.can_afford(current_unit.id, "item")
	move_btn.disabled = not _ap_system.can_afford(current_unit.id, "move")


func _draw_grids() -> void:
	_draw_grid_cells(ally_grid_node, true)
	_draw_grid_cells(enemy_grid_node, false)


func _draw_grid_cells(grid_node: Node2D, is_ally: bool) -> void:
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
		if unit.get("current_hp", 1) <= 0:
			continue

		var unit_visual = ColorRect.new()
		unit_visual.size = Vector2(40, 60)
		var pos = Vector2(unit.grid_position.x, unit.grid_position.y) * CELL_SIZE - (CELL_SIZE * 1.5)
		unit_visual.position = pos + Vector2(20, 10)

		# Highlight current unit
		if not current_unit.is_empty() and unit.id == current_unit.id:
			unit_visual.color = Color.YELLOW
		else:
			unit_visual.color = Color.BLUE if is_ally else Color.RED

		unit_visual.name = unit.id

		var label = Label.new()
		label.text = unit.get("name", "???").substr(0, 3)
		label.position = Vector2(-10, -20)
		unit_visual.add_child(label)

		# HP bar
		var hp_bar = ColorRect.new()
		hp_bar.size = Vector2(40, 4)
		hp_bar.position = Vector2(0, 62)
		hp_bar.color = Color.DARK_RED
		unit_visual.add_child(hp_bar)

		var hp_fill = ColorRect.new()
		var hp_ratio = float(unit.get("current_hp", 1)) / float(unit.get("max_hp", 1))
		hp_fill.size = Vector2(40 * hp_ratio, 4)
		hp_fill.position = Vector2(0, 62)
		hp_fill.color = Color.GREEN
		unit_visual.add_child(hp_fill)

		grid_node.add_child(unit_visual)


func _start_next_turn() -> void:
	if _check_combat_end():
		return

	var current_unit_id = _ctb_manager.get_current_unit_id()
	current_unit = _units_by_id.get(current_unit_id, {})

	if current_unit.is_empty():
		push_error("No current unit found!")
		return

	current_phase = CombatPhase.TURN_START

	# Start AP for this turn
	var available_ap = _ap_system.start_turn(current_unit.id)

	status_label.text = "%s's turn (AP: %d)" % [current_unit.name, available_ap]
	_update_turn_order_ui()
	_draw_grids()

	EventBus.turn_started.emit(current_unit.id)

	# If AI controlled, handle AI turn
	if not current_unit.is_ally:
		_handle_ai_turn()
	else:
		current_phase = CombatPhase.SELECTING_ACTION
		action_panel.visible = true
		_update_ap_display()
		_update_action_buttons()


func _handle_ai_turn() -> void:
	action_panel.visible = false
	status_label.text = "%s is thinking..." % current_unit.name

	await get_tree().create_timer(0.3).timeout

	# AI spends all AP on attacks
	var actions_taken = 0
	while _ap_system.can_afford(current_unit.id, "attack") and not ally_units.is_empty():
		# Spend AP
		_ap_system.spend_action(current_unit.id, "attack")

		# Pick random alive ally
		var alive_allies = ally_units.filter(func(u): return u.current_hp > 0)
		if alive_allies.is_empty():
			break

		var target = alive_allies[randi() % alive_allies.size()]
		var damage = randi_range(5, 15)

		_apply_damage(target, damage)
		status_label.text = "%s attacks %s for %d damage!" % [current_unit.name, target.name, damage]
		_draw_grids()

		actions_taken += 1
		await get_tree().create_timer(0.5).timeout

	if actions_taken == 0:
		status_label.text = "%s does nothing!" % current_unit.name
		await get_tree().create_timer(0.3).timeout

	_end_turn()


func _apply_damage(target: Dictionary, damage: int) -> void:
	target.current_hp = max(0, target.current_hp - damage)
	EventBus.unit_damaged.emit(target.id, damage, "physical")

	if target.current_hp <= 0:
		EventBus.unit_defeated.emit(target.id)


func _end_turn() -> void:
	current_phase = CombatPhase.TURN_END
	EventBus.turn_ended.emit(current_unit.id)

	action_panel.visible = false

	# Get remaining AP for speed bonus
	var remaining_ap = _ap_system.end_turn(current_unit.id)
	var speed = current_unit.get("speed", 5)

	# Update CTB with remaining AP bonus
	_ctb_manager.end_turn(current_unit.id, speed, remaining_ap)

	# Check for defeated units
	_remove_defeated_units()

	# Update UI
	_update_turn_order_ui()

	# Start next turn
	_start_next_turn()


func _remove_defeated_units() -> void:
	# Remove defeated units from arrays and systems
	for unit in ally_units:
		if unit.current_hp <= 0:
			_ctb_manager.remove_unit(unit.id)
			_ap_system.remove_unit(unit.id)

	for unit in enemy_units:
		if unit.current_hp <= 0:
			_ctb_manager.remove_unit(unit.id)
			_ap_system.remove_unit(unit.id)

	ally_units = ally_units.filter(func(u): return u.current_hp > 0)
	enemy_units = enemy_units.filter(func(u): return u.current_hp > 0)

	_draw_grids()


func _check_combat_end() -> bool:
	var alive_enemies = enemy_units.filter(func(u): return u.current_hp > 0)
	var alive_allies = ally_units.filter(func(u): return u.current_hp > 0)

	if alive_enemies.is_empty():
		_end_combat(true)
		return true
	elif alive_allies.is_empty():
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


# ============================================================================
# ACTION HANDLERS
# ============================================================================

func _on_attack_pressed() -> void:
	if current_phase != CombatPhase.SELECTING_ACTION:
		return

	if not _ap_system.can_afford(current_unit.id, "attack"):
		status_label.text = "Not enough AP!"
		return

	# Spend AP
	_ap_system.spend_action(current_unit.id, "attack")

	selected_action = "attack"
	current_phase = CombatPhase.EXECUTING_ACTION

	# For now, auto-select first alive enemy
	var alive_enemies = enemy_units.filter(func(u): return u.current_hp > 0)
	if not alive_enemies.is_empty():
		var target = alive_enemies[0]
		var damage = randi_range(10, 20)
		_apply_damage(target, damage)
		status_label.text = "%s attacks %s for %d damage!" % [current_unit.name, target.name, damage]
		_draw_grids()

	# Return to action selection (player may have more AP)
	await get_tree().create_timer(0.5).timeout

	if _ap_system.get_current_ap(current_unit.id) > 0:
		current_phase = CombatPhase.SELECTING_ACTION
		_update_ap_display()
		_update_action_buttons()
		_update_turn_order_ui()
	else:
		# Auto end turn if no AP left
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

	# Defend is free but ends turn immediately
	status_label.text = "%s defends!" % current_unit.name

	# Don't spend AP - player keeps it for speed bonus
	await get_tree().create_timer(0.3).timeout
	_end_turn()


func _on_end_turn_pressed() -> void:
	if current_phase != CombatPhase.SELECTING_ACTION:
		return

	var remaining = _ap_system.get_current_ap(current_unit.id)
	if remaining > 0:
		status_label.text = "%s conserves %d AP!" % [current_unit.name, remaining]
	else:
		status_label.text = "%s ends turn" % current_unit.name

	await get_tree().create_timer(0.3).timeout
	_end_turn()


func _on_back_pressed() -> void:
	GameManager.end_combat(true)
