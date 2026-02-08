extends Node2D
class_name CombatManager
## Manages the turn-based combat system
## Handles turn order, actions, and combat flow

# Preload logic classes
const DataLoaderClass = preload("res://scripts/data/data_loader.gd")
const StatusEffectManagerClass = preload("res://scripts/logic/combat/status_effect_manager.gd")
const DamageCalculatorClass = preload("res://scripts/logic/combat/damage_calculator.gd")
const PositionValidatorClass = preload("res://scripts/logic/combat/position_validator.gd")
const CombatAIClass = preload("res://scripts/logic/combat/combat_ai.gd")
const UnitVisualClass = preload("res://scripts/presentation/combat/unit_visual.gd")
const FloatingTextClass = preload("res://scripts/presentation/combat/floating_text.gd")
const CombatResultsClass = preload("res://scripts/presentation/combat/combat_results.gd")

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

# Units in combat (as dictionaries for compatibility)
var ally_units: Array[Dictionary] = []
var enemy_units: Array[Dictionary] = []

# Grid positions (Vector2i -> unit_id)
var ally_grid: Dictionary = {}
var enemy_grid: Dictionary = {}

# Selected action/target
var selected_action: String = ""
var selected_skill: Dictionary = {}
var selected_target: Dictionary = {}

# Skills data (loaded once)
var skills_data: Dictionary = {}

# Status effect manager instance
var status_manager = StatusEffectManagerClass.new()

# Persistent unit visuals (unit_id -> UnitVisual)
var unit_visuals: Dictionary = {}

# Turn highlight node
var turn_highlight: Polygon2D = null

# Action log
var action_log_scroll: ScrollContainer
var action_log_container: VBoxContainer
const ACTION_LOG_MAX_ENTRIES = 50

# Node references
@onready var ally_grid_node: Node2D = $BattleGrid/AllyGrid
@onready var enemy_grid_node: Node2D = $BattleGrid/EnemyGrid
@onready var turn_list: VBoxContainer = $UI/TurnOrderPanel/TurnList
@onready var status_label: Label = $UI/StatusLabel
@onready var action_panel: Panel = $UI/ActionPanel
@onready var skill_panel = $UI/SkillPanel
@onready var target_selector = $TargetSelector

# Turn highlight pulse state
var _highlight_pulse_time: float = 0.0


## Convert a grid position to visual position (mirrors ally columns so front=closest to enemies)
static func grid_to_visual_pos(grid_pos: Vector2i, is_ally: bool) -> Vector2:
	var visual_col = (2 - grid_pos.x) if is_ally else grid_pos.x
	return Vector2(visual_col, grid_pos.y) * CELL_SIZE - (CELL_SIZE * 1.5)


func _ready() -> void:
	GameManager.change_state(GameManager.GameState.COMBAT)

	# Load skills data
	skills_data = DataLoaderClass.load_skills()

	# Connect UI buttons
	$UI/ActionPanel/ActionButtons/AttackButton.pressed.connect(_on_attack_pressed)
	$UI/ActionPanel/ActionButtons/SkillButton.pressed.connect(_on_skill_pressed)
	$UI/ActionPanel/ActionButtons/ItemButton.pressed.connect(_on_item_pressed)
	$UI/ActionPanel/ActionButtons/MoveButton.pressed.connect(_on_move_pressed)
	$UI/ActionPanel/ActionButtons/DefendButton.pressed.connect(_on_defend_pressed)
	$UI/BackButton.pressed.connect(_on_back_pressed)

	# Connect skill panel signals
	skill_panel.skill_selected.connect(_on_skill_selected)
	skill_panel.cancelled.connect(_on_skill_cancelled)

	# Connect target selector signals
	target_selector.target_selected.connect(_on_target_selected)
	target_selector.targeting_cancelled.connect(_on_targeting_cancelled)
	target_selector.move_position_selected.connect(_on_move_position_selected)

	# Create action log
	_setup_action_log()

	# Initialize combat
	_initialize_combat()


func _process(delta: float) -> void:
	# Pulse the turn highlight
	if turn_highlight != null and is_instance_valid(turn_highlight):
		_highlight_pulse_time += delta * 3.0
		var alpha = 0.15 + 0.15 * sin(_highlight_pulse_time)
		turn_highlight.color = Color(1.0, 1.0, 0.0, alpha)


func _initialize_combat() -> void:
	current_phase = CombatPhase.INITIALIZING
	status_label.text = "Initializing Combat..."

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

	# Calculate initial turn order
	_calculate_turn_order()
	print("Turn order has %d units" % turn_order.size())

	# Draw grid visuals
	_draw_grids()
	print("Grids drawn. Ally grid children: %d, Enemy grid children: %d" % [ally_grid_node.get_child_count(), enemy_grid_node.get_child_count()])

	_log_action("Combat started: %d allies vs %d enemies" % [ally_units.size(), enemy_units.size()])

	# Start first turn
	_start_next_turn()


func _load_party_units() -> void:
	ally_units.clear()
	for i in range(GameManager.party.size()):
		var member = GameManager.party[i].duplicate(true)
		member["is_ally"] = true
		member["grid_position"] = _get_default_ally_position(i)

		# Calculate initiative from agility
		var agility = member.get("base_stats", {}).get("agility", 5)
		member["initiative"] = agility * 2.0 + randf_range(-2, 2)

		ally_units.append(member)


func _load_enemy_units() -> void:
	enemy_units.clear()
	var enemy_data = GameManager.story_flags.get("_combat_enemies", [])

	# Track occupied positions to avoid collisions
	var occupied: Dictionary = {}

	for i in range(enemy_data.size()):
		var enemy = enemy_data[i].duplicate(true)
		enemy["is_ally"] = false

		# Respect preferred_position from enemy data
		var pref = enemy.get("preferred_position", "")
		var pos = _get_default_enemy_position(i)
		if pref == "back":
			pos = Vector2i(2, i % 3)
		elif pref == "middle":
			pos = Vector2i(1, i % 3)

		# Resolve collision
		while occupied.has(pos):
			pos.y = (pos.y + 1) % 3
		occupied[pos] = true
		enemy["grid_position"] = pos

		enemy["current_hp"] = enemy.get("hp", 50)
		enemy["max_hp"] = enemy.get("hp", 50)
		enemy["current_mp"] = enemy.get("mp", 10)
		enemy["max_mp"] = enemy.get("mp", 10)

		# Calculate initiative from agility
		var agility = enemy.get("base_stats", {}).get("agility", 5)
		enemy["initiative"] = agility * 2.0 + randf_range(-2, 2)

		enemy_units.append(enemy)


func _get_default_ally_position(index: int) -> Vector2i:
	# Front column by default
	match index:
		0: return Vector2i(0, 1)  # Front middle
		1: return Vector2i(0, 0)  # Front top
		2: return Vector2i(0, 2)  # Front bottom
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

	# Show 8 entries (wraps around the turn order)
	for i in range(8):
		if turn_order.is_empty():
			break
		var unit = turn_order[(current_turn_index + i) % turn_order.size()]
		var label = Label.new()

		# Show HP and MP for current unit
		var hp_text = ""
		if i == 0:
			hp_text = " [HP:%d/%d MP:%d/%d]" % [unit.current_hp, unit.max_hp, unit.current_mp, unit.max_mp]

		label.text = "%s%s%s" % ["-> " if i == 0 else "   ", unit.name, hp_text]
		label.add_theme_color_override("font_color", Color.CYAN if unit.is_ally else Color.RED)
		turn_list.add_child(label)


# --- Grid Drawing ---

func _draw_grids() -> void:
	_draw_grid_background(ally_grid_node, true)
	_draw_grid_background(enemy_grid_node, false)
	_update_unit_visuals()


func _draw_grid_background(grid_node: Node2D, is_ally: bool) -> void:
	# Remove only non-UnitVisual children (grid cells, old highlights)
	for child in grid_node.get_children():
		if not child is UnitVisual:
			child.queue_free()

	var base_color = Color(0.2, 0.4, 0.6, 0.5) if is_ally else Color(0.6, 0.2, 0.2, 0.5)
	var cell_size = CELL_SIZE - Vector2(4, 4)

	for x in range(GRID_SIZE.x):
		for y in range(GRID_SIZE.y):
			var cell = Polygon2D.new()
			cell.polygon = PackedVector2Array([
				Vector2(0, 0), Vector2(cell_size.x, 0),
				Vector2(cell_size.x, cell_size.y), Vector2(0, cell_size.y)
			])
			# Mirror ally columns so front (col 0) is closest to enemies (right side)
			var visual_pos = grid_to_visual_pos(Vector2i(x, y), is_ally)
			cell.position = visual_pos + Vector2(2, 2)
			cell.color = base_color
			grid_node.add_child(cell)


func _update_unit_visuals() -> void:
	# Track which unit IDs are still alive
	var alive_ids: Dictionary = {}

	# Update ally visuals
	for unit in ally_units:
		alive_ids[unit.id] = true
		_create_or_update_visual(unit, true, ally_grid_node)

	# Update enemy visuals
	for unit in enemy_units:
		alive_ids[unit.id] = true
		_create_or_update_visual(unit, false, enemy_grid_node)

	# Remove visuals for defeated units
	var to_remove: Array = []
	for uid in unit_visuals:
		if not alive_ids.has(uid):
			to_remove.append(uid)

	for uid in to_remove:
		var visual = unit_visuals[uid]
		if is_instance_valid(visual):
			visual.queue_free()
		unit_visuals.erase(uid)


func _create_or_update_visual(unit: Dictionary, is_ally: bool, grid_node: Node2D) -> void:
	var uid = unit.get("id", "")
	var grid_pos = unit.get("grid_position", Vector2i(1, 1))
	var pos = grid_to_visual_pos(grid_pos, is_ally) + Vector2(12, 5)

	if unit_visuals.has(uid) and is_instance_valid(unit_visuals[uid]):
		# Update existing
		var visual: UnitVisual = unit_visuals[uid]
		visual.position = pos
		visual.update_stats(unit)
		visual.update_statuses(status_manager.get_statuses(uid))
	else:
		# Create new
		var visual = UnitVisualClass.new()
		visual.position = pos
		visual.setup(unit, is_ally)
		visual.update_statuses(status_manager.get_statuses(uid))
		grid_node.add_child(visual)
		unit_visuals[uid] = visual


# --- Turn Highlight ---

func _highlight_current_unit() -> void:
	_clear_turn_highlight()

	if current_unit.is_empty():
		return

	var grid_pos = current_unit.get("grid_position", Vector2i(1, 1))
	var is_ally = current_unit.get("is_ally", true)
	var grid_node = ally_grid_node if is_ally else enemy_grid_node

	turn_highlight = Polygon2D.new()
	var cell_size = CELL_SIZE - Vector2(4, 4)
	turn_highlight.polygon = PackedVector2Array([
		Vector2(0, 0), Vector2(cell_size.x, 0),
		Vector2(cell_size.x, cell_size.y), Vector2(0, cell_size.y)
	])
	turn_highlight.position = grid_to_visual_pos(grid_pos, is_ally) + Vector2(2, 2)
	turn_highlight.color = Color(1.0, 1.0, 0.0, 0.2)
	_highlight_pulse_time = 0.0

	grid_node.add_child(turn_highlight)


func _clear_turn_highlight() -> void:
	if turn_highlight != null and is_instance_valid(turn_highlight):
		turn_highlight.queue_free()
		turn_highlight = null


# --- Floating Damage Numbers ---

func _spawn_floating_text(text: String, color: Color, target: Dictionary, large: bool = false) -> void:
	var grid_pos = target.get("grid_position", Vector2i(1, 1))
	var is_ally = target.get("is_ally", true)
	var grid_node = ally_grid_node if is_ally else enemy_grid_node

	var pos = grid_to_visual_pos(grid_pos, is_ally) + Vector2(CELL_SIZE.x / 2, 0)
	var world_pos = grid_node.global_position + pos

	var ft = FloatingTextClass.create(text, color, world_pos, large)
	get_tree().current_scene.add_child(ft)


# --- Action Log ---

func _setup_action_log() -> void:
	var ui_layer = $UI

	var panel = Panel.new()
	panel.offset_left = 1660
	panel.offset_top = 10
	panel.offset_right = 1910
	panel.offset_bottom = 700
	ui_layer.add_child(panel)

	var title = Label.new()
	title.text = "Action Log"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.offset_left = 5
	title.offset_top = 5
	title.offset_right = 245
	title.offset_bottom = 25
	panel.add_child(title)

	action_log_scroll = ScrollContainer.new()
	action_log_scroll.offset_left = 5
	action_log_scroll.offset_top = 28
	action_log_scroll.offset_right = 245
	action_log_scroll.offset_bottom = 685
	panel.add_child(action_log_scroll)

	action_log_container = VBoxContainer.new()
	action_log_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	action_log_scroll.add_child(action_log_container)


func _log_action(text: String, color: Color = Color.WHITE) -> void:
	if action_log_container == null:
		return

	var label = Label.new()
	label.text = text
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.add_theme_font_size_override("font_size", 11)
	label.add_theme_color_override("font_color", color)
	label.custom_minimum_size = Vector2(230, 0)
	action_log_container.add_child(label)

	# Trim old entries
	while action_log_container.get_child_count() > ACTION_LOG_MAX_ENTRIES:
		var old = action_log_container.get_child(0)
		action_log_container.remove_child(old)
		old.queue_free()

	# Auto-scroll to bottom (deferred so layout updates first)
	_scroll_log_to_bottom.call_deferred()


func _scroll_log_to_bottom() -> void:
	if action_log_scroll != null:
		action_log_scroll.scroll_vertical = action_log_scroll.get_v_scroll_bar().max_value


# --- Turn Flow ---

func _start_next_turn() -> void:
	if _check_combat_end():
		return

	current_unit = turn_order[current_turn_index]
	current_phase = CombatPhase.TURN_START

	# Clear defending status at start of each unit's turn
	current_unit["is_defending"] = false

	# Apply stat modifiers from status effects
	var modifiers = status_manager.get_stat_modifiers(current_unit.id)
	if not modifiers.is_empty():
		_apply_stat_modifiers(current_unit, modifiers)

	status_label.text = "%s's turn" % current_unit.name
	_update_turn_order_ui()
	_highlight_current_unit()

	var pos_name = PositionValidatorClass.get_position_name(current_unit.get("grid_position", Vector2i(0, 0)).x)
	_log_action("--- %s's turn (%s row) ---" % [current_unit.name, pos_name], Color.CYAN if current_unit.is_ally else Color(1.0, 0.5, 0.5))

	EventBus.turn_started.emit(current_unit.id)

	# Regenerate MP at turn start (2 MP per turn)
	_regenerate_mp(current_unit)

	# Update visuals after MP regen
	_update_unit_visuals()

	# If AI controlled, handle AI turn
	if not current_unit.is_ally:
		_handle_ai_turn()
	else:
		current_phase = CombatPhase.SELECTING_ACTION
		action_panel.visible = true


func _regenerate_mp(unit: Dictionary) -> void:
	var max_mp = unit.get("max_mp", 25)
	var current_mp = unit.get("current_mp", 0)
	var new_mp = min(max_mp, current_mp + 2)
	unit["current_mp"] = new_mp


func _apply_stat_modifiers(unit: Dictionary, modifiers: Dictionary) -> void:
	# Store original stats if not already stored
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

	await get_tree().create_timer(0.5).timeout

	# Use AI to make decision
	var decision = CombatAIClass.make_decision(
		current_unit,
		enemy_units,  # AI's allies
		ally_units,   # AI's enemies (player party)
		skills_data,
		status_manager
	)

	# Execute the AI's chosen action
	var skill = skills_data.get(decision.skill_id, skills_data.get("basic_attack", {}))
	var target_id = decision.target_ids[0] if not decision.target_ids.is_empty() else ""

	# Find target
	var target = _find_unit_by_id(target_id)
	if target.is_empty() and not ally_units.is_empty():
		target = ally_units[randi() % ally_units.size()]

	await _execute_skill(skill, current_unit, target)

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

		# Apply damage reduction from status effects (including defending)
		var reductions = status_manager.get_damage_reductions(target.get("id", ""))
		if not reductions.is_empty():
			result.damage = DamageCalculatorClass.apply_damage_reduction(
				result.damage, result.damage_type, reductions
			)

		# Apply front row protection
		var target_is_ally = target.get("is_ally", true)
		var target_grid = ally_grid if target_is_ally else enemy_grid
		var target_pos = target.get("grid_position", Vector2i(0, 0))
		var protection_mult = DamageCalculatorClass.get_front_row_protection(target_pos, target_grid)
		if protection_mult < 1.0:
			result.damage = int(floor(result.damage * protection_mult))

		_apply_damage(target, result.damage)

		# Build damage message
		var crit_text = " CRITICAL!" if result.is_critical else ""
		var eff_text = ""
		if result.effectiveness > 1.0:
			eff_text = " (Weak!)"
		elif result.effectiveness < 1.0:
			eff_text = " (Resist)"

		var prot_text = ""
		if protection_mult < 1.0:
			prot_text = " (Protected)"

		status_label.text = "%s uses %s on %s for %d damage!%s%s%s" % [
			user.name, skill_name, target.name, result.damage, crit_text, eff_text, prot_text
		]

		# Action log entry
		var log_extras = ""
		if result.is_critical:
			log_extras += " CRIT!"
		if result.effectiveness > 1.0:
			log_extras += " Weak!"
		elif result.effectiveness < 1.0:
			log_extras += " Resist"
		if protection_mult < 1.0:
			log_extras += " Protected"

		var log_color = Color.WHITE
		if user.get("is_ally", true):
			log_color = Color(0.7, 0.9, 1.0)
		else:
			log_color = Color(1.0, 0.7, 0.7)
		_log_action("%s -> %s: %s for %d dmg%s" % [user.name, target.name, skill_name, result.damage, log_extras], log_color)

		# Floating damage number
		var float_color = Color.WHITE
		var large = false
		if result.is_critical:
			float_color = Color(1.0, 0.9, 0.1)  # Yellow for crit
			large = true
		elif result.effectiveness > 1.0:
			float_color = Color(1.0, 0.3, 0.3)  # Red for weakness
		elif result.effectiveness < 1.0:
			float_color = Color(0.6, 0.6, 0.6)  # Gray for resist

		_spawn_floating_text(str(result.damage), float_color, target, large)

		# Flash the target unit visual
		if unit_visuals.has(target.id) and is_instance_valid(unit_visuals[target.id]):
			unit_visuals[target.id].flash_damage()

		EventBus.unit_damaged.emit(target.id, result.damage, result.damage_type)
	else:
		status_label.text = "%s uses %s!" % [user.name, skill_name]
		_log_action("%s uses %s" % [user.name, skill_name], Color(0.8, 0.8, 0.5))

	# Handle effects
	if skill.has("effect"):
		await _apply_skill_effect(skill, user, target)

	# Add burst gauge
	var burst_gain = skill.get("burst_gauge_gain", 5)
	user["burst_gauge"] = min(100, user.get("burst_gauge", 0) + burst_gain)
	EventBus.burst_gauge_changed.emit(user.id, user.burst_gauge)

	_update_unit_visuals()
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
			_log_action("  +%s on %s (%d turns)" % [status_name, user.name, duration], Color(0.5, 1.0, 0.5))

		"ally_buff":
			status_manager.apply_status(target.id, status_name, duration, effect)
			EventBus.status_applied.emit(target.id, status_name)
			status_label.text += " %s gains %s!" % [target.name, status_name]
			_log_action("  +%s on %s (%d turns)" % [status_name, target.name, duration], Color(0.5, 1.0, 0.5))

		"party_buff":
			var allies = ally_units if user.is_ally else enemy_units
			for ally in allies:
				status_manager.apply_status(ally.id, status_name, duration, effect)
				EventBus.status_applied.emit(ally.id, status_name)
			status_label.text += " Party gains %s!" % status_name
			_log_action("  +%s on party (%d turns)" % [status_name, duration], Color(0.5, 1.0, 0.5))

		"debuff", "enemy_debuff":
			if effect_type == "enemy_debuff":
				# Apply to all enemies
				var enemies = enemy_units if user.is_ally else ally_units
				for enemy in enemies:
					if status_name == "taunted":
						status_manager.apply_taunt(
							enemy.id,
							user.id,
							duration,
							effect.get("attacks_redirected", 1)
						)
					else:
						status_manager.apply_status(enemy.id, status_name, duration, effect)
					EventBus.status_applied.emit(enemy.id, status_name)
				status_label.text += " Enemies are %s!" % status_name
				_log_action("  -%s on all enemies (%d turns)" % [status_name, duration], Color(1.0, 0.5, 0.5))
			else:
				# Apply to single target
				status_manager.apply_status(target.id, status_name, duration, effect)
				EventBus.status_applied.emit(target.id, status_name)
				status_label.text += " %s is %s!" % [target.name, status_name]
				_log_action("  -%s on %s (%d turns)" % [status_name, target.name, duration], Color(1.0, 0.5, 0.5))


func _apply_damage(target: Dictionary, damage: int) -> void:
	target.current_hp = max(0, target.current_hp - damage)
	EventBus.unit_damaged.emit(target.id, damage, "physical")

	if target.current_hp <= 0:
		EventBus.unit_defeated.emit(target.id)
		_log_action("  %s defeated!" % target.name, Color(1.0, 0.3, 0.3))


func _end_turn() -> void:
	current_phase = CombatPhase.TURN_END
	_clear_turn_highlight()

	# Process status effect tick
	var expired = status_manager.tick_turn_end(current_unit.id)
	for status_name in expired:
		EventBus.status_removed.emit(current_unit.id, status_name)
		_log_action("  %s expired on %s" % [status_name, current_unit.name], Color(0.6, 0.6, 0.6))
		# Reset stats if needed
		if current_unit.has("original_stats"):
			current_unit["base_stats"] = current_unit["original_stats"].duplicate()

	EventBus.turn_ended.emit(current_unit.id)

	# Advance turn order
	current_turn_index = (current_turn_index + 1) % turn_order.size()

	# Check for defeated units
	_remove_defeated_units()

	# Start next turn
	_start_next_turn()


func _remove_defeated_units() -> void:
	# Clear status effects for defeated units
	for unit in ally_units:
		if unit.current_hp <= 0:
			status_manager.clear_unit(unit.id)
	for unit in enemy_units:
		if unit.current_hp <= 0:
			status_manager.clear_unit(unit.id)

	ally_units = ally_units.filter(func(u): return u.current_hp > 0)
	enemy_units = enemy_units.filter(func(u): return u.current_hp > 0)
	turn_order = turn_order.filter(func(u): return u.current_hp > 0)

	if current_turn_index >= turn_order.size():
		current_turn_index = 0

	# Rebuild grids
	_place_units_on_grid()
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
	action_panel.visible = false
	skill_panel.hide_panel()
	_clear_turn_highlight()

	# Clear all status effects
	status_manager.clear_all()

	EventBus.combat_ended.emit(victory)

	# Show results screen
	var results = CombatResultsClass.new()
	add_child(results)

	if victory:
		status_label.text = "Victory!"
		_log_action("=== VICTORY ===", Color(1.0, 0.85, 0.2))
		results.show_victory(ally_units)
		results.continue_pressed.connect(func(): GameManager.end_combat(true))
	else:
		status_label.text = "Defeat..."
		_log_action("=== DEFEAT ===", Color(0.8, 0.2, 0.2))
		results.show_defeat()
		results.retry_pressed.connect(func(): get_tree().reload_current_scene())
		results.menu_pressed.connect(func(): GameManager.end_combat(false))


func _find_unit_by_id(unit_id: String) -> Dictionary:
	for unit in ally_units:
		if unit.id == unit_id:
			return unit
	for unit in enemy_units:
		if unit.id == unit_id:
			return unit
	return {}


# Action handlers
func _on_attack_pressed() -> void:
	if current_phase != CombatPhase.SELECTING_ACTION:
		return

	selected_skill = skills_data.get("basic_attack", {})
	selected_action = "attack"
	current_phase = CombatPhase.SELECTING_TARGET
	status_label.text = "Select target..."
	action_panel.visible = false

	# Start target selection (pass status_manager for taunt enforcement)
	target_selector.start_targeting(
		selected_skill,
		current_unit,
		ally_units,
		enemy_units,
		ally_grid_node,
		enemy_grid_node,
		status_manager
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

	# Start target selection (pass status_manager for taunt enforcement)
	target_selector.start_targeting(
		selected_skill,
		current_unit,
		ally_units,
		enemy_units,
		ally_grid_node,
		enemy_grid_node,
		status_manager
	)


func _on_skill_cancelled() -> void:
	action_panel.visible = true
	current_phase = CombatPhase.SELECTING_ACTION


func _on_target_selected(target_id: String) -> void:
	var target = _find_unit_by_id(target_id)

	# Consume taunt charge when player executes an action targeting enemies
	if current_unit.get("is_ally", true):
		var target_type = PositionValidatorClass.get_targeting_type(selected_skill)
		if target_type in ["single_enemy", "all_enemies"]:
			# get_taunt_target already decrements in AI path; for player, we consume here
			# The taunt was already peeked in target_selector, so consume now
			status_manager.get_taunt_target(current_unit.get("id", ""))

	# Handle "all" targeting
	var target_type = PositionValidatorClass.get_targeting_type(selected_skill)
	if target_type == "all_allies":
		var targets = ally_units if current_unit.is_ally else enemy_units
		_execute_skill_on_all(selected_skill, current_unit, targets)
	elif target_type == "all_enemies":
		var targets = enemy_units if current_unit.is_ally else ally_units
		_execute_skill_on_all(selected_skill, current_unit, targets)
	elif target_type == "self":
		_execute_skill(selected_skill, current_unit, current_unit)
		_end_turn()
	else:
		# Single target
		if not target.is_empty():
			_execute_skill(selected_skill, current_unit, target)
			_end_turn()


func _execute_skill_on_all(skill: Dictionary, user: Dictionary, targets: Array) -> void:
	for target in targets:
		await _execute_skill(skill, user, target)
	_end_turn()


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

	# Update grid dictionary
	ally_grid.erase(old_pos)
	ally_grid[position] = unit_id

	# Update unit data
	current_unit["grid_position"] = position

	# Get position name for status message
	var col_name = PositionValidatorClass.get_position_name(position.x)
	status_label.text = "%s moves to %s row!" % [current_unit.name, col_name]
	_log_action("%s moves to %s row" % [current_unit.name, col_name], Color(0.7, 0.9, 1.0))

	EventBus.position_changed.emit(unit_id, old_pos, position)

	_draw_grids()

	await get_tree().create_timer(0.5).timeout
	_end_turn()


func _on_defend_pressed() -> void:
	if current_phase != CombatPhase.SELECTING_ACTION:
		return

	current_unit["is_defending"] = true

	# Apply defending status with 50% all damage reduction
	# Duration 2 so it survives this turn's end-tick and protects until next turn
	status_manager.apply_status(current_unit.id, "defending", 2, {
		"damage_reduction": {"all": 0.5}
	})
	EventBus.status_applied.emit(current_unit.id, "defending")

	status_label.text = "%s defends!" % current_unit.name
	_log_action("%s defends (50%% DR)" % current_unit.name, Color(0.5, 0.7, 1.0))
	_update_unit_visuals()

	await get_tree().create_timer(0.5).timeout
	_end_turn()


func _on_back_pressed() -> void:
	# Test exit - return to menu
	GameManager.end_combat(true)
