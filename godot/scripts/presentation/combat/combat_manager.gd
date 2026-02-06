extends Node2D
class_name CombatManager
## Manages the turn-based combat system with CTB turn order and AP economy.
## Integrates skill system, status effects, targeting, and AP-based action economy.

# Preload logic classes
const DataLoaderClass = preload("res://scripts/data/data_loader.gd")
const StatusEffectManagerClass = preload("res://scripts/logic/combat/status_effect_manager.gd")
const DamageCalculatorClass = preload("res://scripts/logic/combat/damage_calculator.gd")
const PositionValidatorClass = preload("res://scripts/logic/combat/position_validator.gd")
const CombatAIClass = preload("res://scripts/logic/combat/combat_ai.gd")

# Grid configuration (default 3x3 per side; overridden by combat configurator)
var grid_size: Vector2i = Vector2i(3, 3)
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
var selected_skill: Dictionary = {}
var selected_target: Dictionary = {}

# Core systems (pure logic, no Godot dependencies)
var _ctb_manager: CTBTurnManager
var _ap_system: APSystem

# Skills data (loaded once)
var skills_data: Dictionary = {}

# Status effect manager instance
var status_manager = StatusEffectManagerClass.new()

# Node references
@onready var ally_grid_node: Node2D = $BattleGrid/AllyGrid
@onready var enemy_grid_node: Node2D = $BattleGrid/EnemyGrid
@onready var turn_list: VBoxContainer = $UI/TurnOrderPanel/TurnList
@onready var status_label: Label = $UI/StatusLabel
@onready var action_panel: Panel = $UI/ActionPanel
@onready var ap_label: Label = $UI/ActionPanel/APLabel
@onready var turn_preview_label: Label = $UI/ActionPanel/TurnPreviewLabel
@onready var skill_panel = $UI/SkillPanel
@onready var target_selector = $TargetSelector


func _ready() -> void:
	GameManager.change_state(GameManager.GameState.COMBAT)

	# Initialize logic systems
	_ctb_manager = CTBTurnManager.new()
	_ap_system = APSystem.new()

	# Load skills data
	skills_data = DataLoaderClass.load_skills()

	# Connect UI buttons
	$UI/ActionPanel/ActionButtons/AttackButton.pressed.connect(_on_attack_pressed)
	$UI/ActionPanel/ActionButtons/SkillButton.pressed.connect(_on_skill_pressed)
	$UI/ActionPanel/ActionButtons/ItemButton.pressed.connect(_on_item_pressed)
	$UI/ActionPanel/ActionButtons/MoveButton.pressed.connect(_on_move_pressed)
	$UI/ActionPanel/ActionButtons/DefendButton.pressed.connect(_on_defend_pressed)
	$UI/ActionPanel/ActionButtons/EndTurnButton.pressed.connect(_on_end_turn_pressed)
	$UI/BackButton.pressed.connect(_on_back_pressed)

	# Connect skill panel signals
	skill_panel.skill_selected.connect(_on_skill_selected)
	skill_panel.cancelled.connect(_on_skill_cancelled)

	# Connect target selector signals
	target_selector.target_selected.connect(_on_target_selected)
	target_selector.targeting_cancelled.connect(_on_targeting_cancelled)
	target_selector.move_position_selected.connect(_on_move_position_selected)

	# Initialize combat
	_initialize_combat()


func _initialize_combat() -> void:
	current_phase = CombatPhase.INITIALIZING
	status_label.text = "Initializing Combat..."

	# Apply grid size from configurator (falls back to default 3x3)
	grid_size = Vector2i(
		GameManager.story_flags.get("_combat_config_grid_cols", 3),
		GameManager.story_flags.get("_combat_config_grid_rows", 3)
	)

	# Reset logic systems
	_ap_system.reset()
	_units_by_id.clear()

	# Clear previous status effects
	status_manager.clear_all()

	# Load party from GameManager
	_load_party_units()
	print("Loaded %d party units" % ally_units.size())

	# Load enemies from stored data
	_load_enemy_units()
	print("Loaded %d enemy units" % enemy_units.size())

	# Place units on grids
	_place_units_on_grid()

	# Initialize CTB turn order
	_initialize_turn_order()

	# Draw grid visuals
	_draw_grids()
	print("Grids drawn. Ally grid children: %d, Enemy grid children: %d" % [ally_grid_node.get_child_count(), enemy_grid_node.get_child_count()])

	# Update turn order display
	_update_turn_order_ui()

	# Start first turn
	_start_next_turn()


func _load_party_units() -> void:
	ally_units.clear()
	var pos_config: Dictionary = GameManager.story_flags.get("_combat_config_ally_positions", {})

	for i in range(GameManager.party.size()):
		var member = GameManager.party[i].duplicate(true)
		member["is_ally"] = true

		# Apply position override from configurator, fall back to default
		var pos_override: Dictionary = pos_config.get(str(i), {})
		if not pos_override.is_empty() and pos_override.get("x", -1) >= 0:
			member["grid_position"] = Vector2i(pos_override.get("x", 0), pos_override.get("y", 0))
		else:
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
		enemy["current_mp"] = enemy.get("mp", 10)
		enemy["max_mp"] = enemy.get("mp", 10)

		# Extract stats for CTB and AP systems
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
		var hp_text = ""
		if i == 0 and unit.has("current_hp"):
			hp_text = " [HP:%d/%d]" % [unit.get("current_hp", 0), unit.get("max_hp", 1)]
		label.text = "%s%s%s" % [prefix, unit.get("name", "???"), hp_text]
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

	var base_color = Color(0.2, 0.4, 0.6, 0.5) if is_ally else Color(0.6, 0.2, 0.2, 0.5)
	var cell_size = CELL_SIZE - Vector2(4, 4)

	for x in range(grid_size.x):
		for y in range(grid_size.y):
			var cell = Polygon2D.new()
			cell.polygon = PackedVector2Array([
				Vector2(0, 0), Vector2(cell_size.x, 0),
				Vector2(cell_size.x, cell_size.y), Vector2(0, cell_size.y)
			])
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
		var grid_pos = unit.get("grid_position", Vector2i(1, 1))
		var pos = Vector2(grid_pos.x, grid_pos.y) * CELL_SIZE - (CELL_SIZE * 1.5)
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

		# Show status effects
		var statuses = status_manager.get_statuses(unit.id)
		if not statuses.is_empty():
			var status_text = Label.new()
			var status_names = []
			for s in statuses:
				status_names.append(s.status.substr(0, 3))
			status_text.text = ",".join(status_names)
			status_text.position = Vector2(-10, 68)
			status_text.add_theme_font_size_override("font_size", 10)
			status_text.add_theme_color_override("font_color", Color.YELLOW)
			unit_visual.add_child(status_text)

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

	# Apply stat modifiers from status effects
	var modifiers = status_manager.get_stat_modifiers(current_unit.id)
	if not modifiers.is_empty():
		_apply_stat_modifiers(current_unit, modifiers)

	# Start AP for this turn
	var available_ap = _ap_system.start_turn(current_unit.id)

	status_label.text = "%s's turn (AP: %d)" % [current_unit.name, available_ap]
	_update_turn_order_ui()
	_draw_grids()

	EventBus.turn_started.emit(current_unit.id)

	# Regenerate MP at turn start (2 MP per turn)
	_regenerate_mp(current_unit)

	# If AI controlled, handle AI turn
	if not current_unit.is_ally:
		_handle_ai_turn()
	else:
		current_phase = CombatPhase.SELECTING_ACTION
		action_panel.visible = true
		_update_ap_display()
		_update_action_buttons()


func _regenerate_mp(unit: Dictionary) -> void:
	var max_mp = unit.get("max_mp", 25)
	var current_mp = unit.get("current_mp", 0)
	var new_mp = min(max_mp, current_mp + 2)
	unit["current_mp"] = new_mp


func _apply_stat_modifiers(unit: Dictionary, modifiers: Dictionary) -> void:
	if not unit.has("original_stats"):
		unit["original_stats"] = unit.get("base_stats", {}).duplicate()

	var base_stats = unit.get("original_stats", unit.get("base_stats", {}))
	var modified_stats = base_stats.duplicate()

	for stat_name in modifiers:
		if modified_stats.has(stat_name):
			var base_value = base_stats.get(stat_name, 5)
			modified_stats[stat_name] = base_value * (1.0 + modifiers[stat_name])

	unit["base_stats"] = modified_stats


func _handle_ai_turn() -> void:
	action_panel.visible = false
	status_label.text = "%s is thinking..." % current_unit.name

	await get_tree().create_timer(0.3).timeout

	# Use AI to make decision
	var decision = CombatAIClass.make_decision(
		current_unit,
		enemy_units,  # AI's allies
		ally_units,   # AI's enemies (player party)
		skills_data,
		status_manager
	)

	# Execute actions while AP allows
	var actions_taken = 0
	while _ap_system.can_afford(current_unit.id, "attack") and not ally_units.is_empty():
		_ap_system.spend_action(current_unit.id, "attack")

		var skill = skills_data.get(decision.skill_id, skills_data.get("basic_attack", {}))
		var target_id = decision.target_ids[0] if not decision.target_ids.is_empty() else ""
		var target = _find_unit_by_id(target_id)
		if target.is_empty() or target.get("current_hp", 0) <= 0:
			var alive_allies = ally_units.filter(func(u): return u.current_hp > 0)
			if alive_allies.is_empty():
				break
			target = alive_allies[randi() % alive_allies.size()]

		await _execute_skill(skill, current_unit, target)
		actions_taken += 1
		await get_tree().create_timer(0.4).timeout

		# Re-decide for next action if AP remains
		if _ap_system.can_afford(current_unit.id, "attack"):
			decision = CombatAIClass.make_decision(
				current_unit,
				enemy_units,
				ally_units,
				skills_data,
				status_manager
			)

	if actions_taken == 0:
		status_label.text = "%s does nothing!" % current_unit.name
		await get_tree().create_timer(0.3).timeout

	_end_turn()


func _execute_skill(skill: Dictionary, user: Dictionary, target: Dictionary) -> void:
	var skill_name = skill.get("name", "Attack")
	var mp_cost = skill.get("mp_cost", 0)

	# Deduct MP
	if mp_cost > 0:
		user["current_mp"] = max(0, user.get("current_mp", 0) - mp_cost)

	# Handle damage
	if skill.has("damage"):
		var result = DamageCalculatorClass.calculate_damage(skill, user, target)

		# Apply damage reduction from status effects
		var reductions = status_manager.get_damage_reductions(target.get("id", ""))
		if not reductions.is_empty():
			result.damage = DamageCalculatorClass.apply_damage_reduction(
				result.damage, result.damage_type, reductions
			)

		_apply_damage(target, result.damage)

		var crit_text = " CRITICAL!" if result.is_critical else ""
		var eff_text = ""
		if result.effectiveness > 1.0:
			eff_text = " (Weak!)"
		elif result.effectiveness < 1.0:
			eff_text = " (Resist)"

		status_label.text = "%s uses %s on %s for %d damage!%s%s" % [
			user.name, skill_name, target.name, result.damage, crit_text, eff_text
		]

		EventBus.unit_damaged.emit(target.id, result.damage, result.damage_type)
	else:
		status_label.text = "%s uses %s!" % [user.name, skill_name]

	# Handle effects
	if skill.has("effect"):
		await _apply_skill_effect(skill, user, target)

	# Add burst gauge
	var burst_gain = skill.get("burst_gauge_gain", 5)
	user["burst_gauge"] = min(100, user.get("burst_gauge", 0) + burst_gain)
	EventBus.burst_gauge_changed.emit(user.id, user.burst_gauge)

	_draw_grids()
	await get_tree().create_timer(1.0).timeout


func _apply_skill_effect(skill: Dictionary, user: Dictionary, target: Dictionary) -> void:
	var effect = skill.effect
	var effect_type = effect.get("type", "")
	var status_name = effect.get("status", "")
	var duration = effect.get("duration", 1)

	match effect_type:
		"self_buff":
			status_manager.apply_status(user.id, status_name, duration, effect)
			EventBus.status_applied.emit(user.id, status_name)
			status_label.text += " %s gains %s!" % [user.name, status_name]

		"ally_buff":
			status_manager.apply_status(target.id, status_name, duration, effect)
			EventBus.status_applied.emit(target.id, status_name)
			status_label.text += " %s gains %s!" % [target.name, status_name]

		"party_buff":
			var allies = ally_units if user.is_ally else enemy_units
			for ally in allies:
				status_manager.apply_status(ally.id, status_name, duration, effect)
				EventBus.status_applied.emit(ally.id, status_name)
			status_label.text += " Party gains %s!" % status_name

		"debuff", "enemy_debuff":
			if effect_type == "enemy_debuff":
				var enemies = enemy_units if user.is_ally else ally_units
				for enemy in enemies:
					if status_name == "taunted":
						status_manager.apply_taunt(
							enemy.id, user.id, duration, effect.get("attacks_redirected", 1)
						)
					else:
						status_manager.apply_status(enemy.id, status_name, duration, effect)
					EventBus.status_applied.emit(enemy.id, status_name)
				status_label.text += " Enemies are %s!" % status_name
			else:
				status_manager.apply_status(target.id, status_name, duration, effect)
				EventBus.status_applied.emit(target.id, status_name)
				status_label.text += " %s is %s!" % [target.name, status_name]


func _apply_damage(target: Dictionary, damage: int) -> void:
	target.current_hp = max(0, target.current_hp - damage)
	EventBus.unit_damaged.emit(target.id, damage, "physical")

	if target.current_hp <= 0:
		EventBus.unit_defeated.emit(target.id)


func _end_turn() -> void:
	current_phase = CombatPhase.TURN_END

	# Process status effect tick
	var expired = status_manager.tick_turn_end(current_unit.id)
	for status_name in expired:
		EventBus.status_removed.emit(current_unit.id, status_name)
		if current_unit.has("original_stats"):
			current_unit["base_stats"] = current_unit["original_stats"].duplicate()

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
	# Remove defeated units from all systems
	for unit in ally_units:
		if unit.current_hp <= 0:
			_ctb_manager.remove_unit(unit.id)
			_ap_system.remove_unit(unit.id)
			status_manager.clear_unit(unit.id)

	for unit in enemy_units:
		if unit.current_hp <= 0:
			_ctb_manager.remove_unit(unit.id)
			_ap_system.remove_unit(unit.id)
			status_manager.clear_unit(unit.id)

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
	skill_panel.hide_panel()

	# Clear all status effects
	status_manager.clear_all()

	EventBus.combat_ended.emit(victory)

	await get_tree().create_timer(2.0).timeout

	GameManager.end_combat(victory)


func _find_unit_by_id(unit_id: String) -> Dictionary:
	return _units_by_id.get(unit_id, {})


# ============================================================================
# ACTION HANDLERS
# ============================================================================

func _on_attack_pressed() -> void:
	if current_phase != CombatPhase.SELECTING_ACTION:
		return

	if not _ap_system.can_afford(current_unit.id, "attack"):
		status_label.text = "Not enough AP!"
		return

	# Spend AP before entering target selection
	_ap_system.spend_action(current_unit.id, "attack")

	selected_skill = skills_data.get("basic_attack", {})
	selected_action = "attack"
	current_phase = CombatPhase.SELECTING_TARGET
	status_label.text = "Select target..."
	action_panel.visible = false

	target_selector.start_targeting(
		selected_skill,
		current_unit,
		ally_units,
		enemy_units,
		ally_grid_node,
		enemy_grid_node
	)


func _on_skill_pressed() -> void:
	if current_phase != CombatPhase.SELECTING_ACTION:
		return

	# Show skill panel
	action_panel.visible = false
	skill_panel.show_skills(current_unit, skills_data)


func _on_skill_selected(skill_id: String) -> void:
	selected_skill = skills_data.get(skill_id, {})
	selected_action = "skill"
	current_phase = CombatPhase.SELECTING_TARGET
	status_label.text = "Select target for %s..." % selected_skill.get("name", skill_id)

	target_selector.start_targeting(
		selected_skill,
		current_unit,
		ally_units,
		enemy_units,
		ally_grid_node,
		enemy_grid_node
	)


func _on_skill_cancelled() -> void:
	action_panel.visible = true
	current_phase = CombatPhase.SELECTING_ACTION


func _on_target_selected(target_id: String) -> void:
	var target = _find_unit_by_id(target_id)

	# Handle targeting type
	var target_type = PositionValidatorClass.get_targeting_type(selected_skill)
	if target_type == "all_allies":
		var targets = ally_units if current_unit.is_ally else enemy_units
		await _execute_skill_on_all(selected_skill, current_unit, targets)
	elif target_type == "all_enemies":
		var targets = enemy_units if current_unit.is_ally else ally_units
		await _execute_skill_on_all(selected_skill, current_unit, targets)
	elif target_type == "self":
		await _execute_skill(selected_skill, current_unit, current_unit)
	else:
		if not target.is_empty():
			await _execute_skill(selected_skill, current_unit, target)

	_end_turn()


func _execute_skill_on_all(skill: Dictionary, user: Dictionary, targets: Array) -> void:
	for target in targets:
		await _execute_skill(skill, user, target)


func _on_targeting_cancelled() -> void:
	action_panel.visible = true
	current_phase = CombatPhase.SELECTING_ACTION
	status_label.text = "%s's turn" % current_unit.name


func _on_item_pressed() -> void:
	status_label.text = "Items not yet implemented"


func _on_move_pressed() -> void:
	if current_phase != CombatPhase.SELECTING_ACTION:
		return

	selected_action = "move"
	current_phase = CombatPhase.SELECTING_TARGET
	status_label.text = "Select position to move to..."
	action_panel.visible = false

	target_selector.start_move_targeting(current_unit, ally_grid, ally_grid_node)


func _on_move_position_selected(position: Vector2i) -> void:
	var old_pos: Vector2i = current_unit.grid_position
	var unit_id: String = current_unit.id

	ally_grid.erase(old_pos)
	ally_grid[position] = unit_id
	current_unit["grid_position"] = position

	var col_name = PositionValidatorClass.get_position_name(position.x)
	status_label.text = "%s moves to %s row!" % [current_unit.name, col_name]

	EventBus.position_changed.emit(unit_id, old_pos, position)

	_draw_grids()

	await get_tree().create_timer(0.5).timeout
	_end_turn()


func _on_defend_pressed() -> void:
	if current_phase != CombatPhase.SELECTING_ACTION:
		return

	# Defend is free but ends turn immediately; conserve remaining AP for speed bonus
	status_label.text = "%s defends!" % current_unit.name

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
