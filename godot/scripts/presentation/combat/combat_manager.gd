extends Node2D
class_name CombatManager
## Manages the turn-based combat system on a unified 6x10 grid
## Handles turn order, actions, movement, opportunity attacks, and combat flow

# Preload logic classes
const DataLoaderClass = preload("res://scripts/data/data_loader.gd")
const StatusEffectManagerClass = preload("res://scripts/logic/combat/status_effect_manager.gd")
const DamageCalculatorClass = preload("res://scripts/logic/combat/damage_calculator.gd")
const PositionValidatorClass = preload("res://scripts/logic/combat/position_validator.gd")
const CombatAIClass = preload("res://scripts/logic/combat/combat_ai.gd")
const CombatConfigLoaderClass = preload("res://scripts/logic/combat/combat_config_loader.gd")
const GridPathfinderClass = preload("res://scripts/logic/combat/grid_pathfinder.gd")
const UnitVisualClass = preload("res://scripts/presentation/combat/unit_visual.gd")
const FloatingTextClass = preload("res://scripts/presentation/combat/floating_text.gd")
const CombatResultsClass = preload("res://scripts/presentation/combat/combat_results.gd")

# Grid configuration (loaded from config)
var GRID_SIZE: Vector2i = Vector2i(10, 6)
var CELL_SIZE: Vector2 = Vector2(48, 48)
var CELL_GAP: float = 4.0

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

# Unified data structures
var all_units: Dictionary = {}  # unit_id -> unit Dict
var grid: Dictionary = {}       # Vector2i -> unit_id

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

# Encounter ID
var encounter_id: String = "test_battle"

# Node references
@onready var grid_node: Node2D = $BattleGrid/Grid
@onready var turn_list: VBoxContainer = $UI/TurnOrderPanel/TurnList
@onready var status_label: Label = $UI/StatusLabel
@onready var action_panel: Panel = $UI/ActionPanel
@onready var skill_panel = $UI/SkillPanel
@onready var target_selector = $TargetSelector

# Turn highlight pulse state
var _highlight_pulse_time: float = 0.0


## Convert grid position to visual position (direct mapping, no mirroring)
func grid_to_visual_pos(grid_pos: Vector2i) -> Vector2:
	return Vector2(grid_pos.x, grid_pos.y) * (CELL_SIZE + Vector2(CELL_GAP, CELL_GAP))


func _ready() -> void:
	GameManager.change_state(GameManager.GameState.COMBAT)

	# Load config
	CombatConfigLoaderClass.reload()
	GRID_SIZE = CombatConfigLoaderClass.get_grid_size()
	CELL_SIZE = CombatConfigLoaderClass.get_cell_size()
	CELL_GAP = CombatConfigLoaderClass.get_cell_gap()

	# Load skills data
	skills_data = DataLoaderClass.load_skills()

	# Get encounter ID from story flags
	encounter_id = GameManager.story_flags.get("_combat_encounter_id", "test_battle")

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

	# Load units from encounter data
	_load_units_from_encounter(encounter_id)
	print("Loaded %d total units" % all_units.size())

	# Place units on grid
	_place_units_on_grid()

	# Calculate initial turn order
	_calculate_turn_order()
	print("Turn order has %d units" % turn_order.size())

	# Draw grid visuals
	_draw_grid()
	print("Grid drawn. Grid node children: %d" % grid_node.get_child_count())

	var ally_count = get_ally_units().size()
	var enemy_count = get_enemy_units().size()
	_log_action("Combat started: %d allies vs %d enemies" % [ally_count, enemy_count])

	# Start first turn
	_start_next_turn()


## Load units from encounter data or fallback to legacy loading
func _load_units_from_encounter(enc_id: String) -> void:
	all_units.clear()

	var encounter_data = DataLoaderClass.get_encounter(enc_id)

	# Load allies from party
	var ally_positions = encounter_data.get("ally_positions", {})
	for i in range(GameManager.party.size()):
		var member = GameManager.party[i].duplicate(true)
		member["is_ally"] = true

		# Use encounter position if available, else default
		var member_id = member.get("id", "")
		if ally_positions.has(member_id):
			var pos_arr = ally_positions[member_id]
			member["grid_position"] = Vector2i(int(pos_arr[0]), int(pos_arr[1]))
		else:
			member["grid_position"] = _get_default_ally_position(i)

		# Calculate initiative from agility
		var agility = member.get("base_stats", {}).get("agility", 5)
		member["initiative"] = agility * 2.0 + randf_range(-2, 2)

		all_units[member_id] = member

	# Load enemies
	var enemy_spawns = encounter_data.get("enemy_spawns", [])
	if not enemy_spawns.is_empty():
		# Encounter-based spawning
		var enemies_db = DataLoaderClass.load_enemies()
		for spawn in enemy_spawns:
			var enemy_id = spawn.get("enemy_id", "")
			var enemy_template = enemies_db.get(enemy_id, {})
			if enemy_template.is_empty():
				push_warning("Enemy template not found: " + enemy_id)
				continue

			var enemy = enemy_template.duplicate(true)
			enemy["is_ally"] = false

			var pos_arr = spawn.get("position", [8, 2])
			enemy["grid_position"] = Vector2i(int(pos_arr[0]), int(pos_arr[1]))

			# Derive HP/MP from stats using config formula
			var e_stats = enemy.get("base_stats", {})
			var e_vigor = e_stats.get("vigor", 5)
			var e_resonance = e_stats.get("resonance", 5)
			var e_hp = int(e_vigor * CombatConfigLoaderClass.get_balance("hp_per_vigor", 60))
			var e_mp = int(e_resonance * CombatConfigLoaderClass.get_balance("mp_per_resonance", 5))
			enemy["current_hp"] = e_hp
			enemy["max_hp"] = e_hp
			enemy["current_mp"] = e_mp
			enemy["max_mp"] = e_mp

			var agility = enemy.get("base_stats", {}).get("agility", 5)
			enemy["initiative"] = agility * 2.0 + randf_range(-2, 2)

			# Use enemy_id as key; handle duplicates with suffix
			var uid = enemy_id
			var suffix = 1
			while all_units.has(uid):
				uid = "%s_%d" % [enemy_id, suffix]
				suffix += 1
			enemy["id"] = uid
			all_units[uid] = enemy
	else:
		# Legacy loading from stored combat enemies
		var enemy_data = GameManager.story_flags.get("_combat_enemies", [])
		for i in range(enemy_data.size()):
			var enemy = enemy_data[i].duplicate(true)
			enemy["is_ally"] = false
			enemy["grid_position"] = _get_default_enemy_position(i)

			# Derive HP/MP from stats using config formula
			var e_stats = enemy.get("base_stats", {})
			var e_vigor = e_stats.get("vigor", 5)
			var e_resonance = e_stats.get("resonance", 5)
			var e_hp = int(e_vigor * CombatConfigLoaderClass.get_balance("hp_per_vigor", 60))
			var e_mp = int(e_resonance * CombatConfigLoaderClass.get_balance("mp_per_resonance", 5))
			enemy["current_hp"] = e_hp
			enemy["max_hp"] = e_hp
			enemy["current_mp"] = e_mp
			enemy["max_mp"] = e_mp

			var agility = enemy.get("base_stats", {}).get("agility", 5)
			enemy["initiative"] = agility * 2.0 + randf_range(-2, 2)

			all_units[enemy.id] = enemy


func _get_default_ally_position(index: int) -> Vector2i:
	# Left side of grid, spread vertically
	match index:
		0: return Vector2i(1, 2)
		1: return Vector2i(1, 1)
		2: return Vector2i(0, 3)
		_: return Vector2i(0, index % GRID_SIZE.y)


func _get_default_enemy_position(index: int) -> Vector2i:
	# Right side of grid, spread vertically
	match index:
		0: return Vector2i(GRID_SIZE.x - 2, 1)
		1: return Vector2i(GRID_SIZE.x - 1, 3)
		2: return Vector2i(GRID_SIZE.x - 1, 4)
		_: return Vector2i(GRID_SIZE.x - 1, index % GRID_SIZE.y)


func _place_units_on_grid() -> void:
	grid.clear()
	for unit_id in all_units:
		var unit = all_units[unit_id]
		var pos: Vector2i = unit.get("grid_position", Vector2i(0, 0))
		grid[pos] = unit_id


## Helper: Get array of ally unit dicts
func get_ally_units() -> Array:
	var allies: Array = []
	for uid in all_units:
		if all_units[uid].get("is_ally", true):
			allies.append(all_units[uid])
	return allies


## Helper: Get array of enemy unit dicts
func get_enemy_units() -> Array:
	var enemies: Array = []
	for uid in all_units:
		if not all_units[uid].get("is_ally", true):
			enemies.append(all_units[uid])
	return enemies


func _calculate_turn_order() -> void:
	turn_order.clear()

	var units_list: Array = []
	for uid in all_units:
		units_list.append(all_units[uid])

	# Sort by initiative (descending)
	units_list.sort_custom(func(a, b): return a.initiative > b.initiative)

	turn_order = units_list
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

func _draw_grid() -> void:
	_draw_grid_background()
	_update_unit_visuals()


func _draw_grid_background() -> void:
	# Remove only non-UnitVisual children (grid cells, old highlights)
	for child in grid_node.get_children():
		if not child is UnitVisual:
			child.queue_free()

	var cell_visual_size = CELL_SIZE - Vector2(CELL_GAP, CELL_GAP)

	for x in range(GRID_SIZE.x):
		for y in range(GRID_SIZE.y):
			var cell = Polygon2D.new()
			cell.polygon = PackedVector2Array([
				Vector2(0, 0), Vector2(cell_visual_size.x, 0),
				Vector2(cell_visual_size.x, cell_visual_size.y), Vector2(0, cell_visual_size.y)
			])
			var pos = grid_to_visual_pos(Vector2i(x, y))
			cell.position = pos + Vector2(CELL_GAP / 2, CELL_GAP / 2)

			# Color based on zone: ally (blue), enemy (red), neutral (gray)
			if x < 2:
				cell.color = Color(0.2, 0.3, 0.5, 0.4)  # Blue-tinted ally zone
			elif x >= 5:
				cell.color = Color(0.5, 0.2, 0.2, 0.4)  # Red-tinted enemy zone
			else:
				cell.color = Color(0.25, 0.25, 0.3, 0.35)  # Neutral gray

			grid_node.add_child(cell)


func _update_unit_visuals() -> void:
	# Track which unit IDs are still alive
	var alive_ids: Dictionary = {}

	for unit_id in all_units:
		alive_ids[unit_id] = true
		var unit = all_units[unit_id]
		_create_or_update_visual(unit)

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


func _create_or_update_visual(unit: Dictionary) -> void:
	var uid = unit.get("id", "")
	var grid_pos = unit.get("grid_position", Vector2i(1, 1))
	# Center unit in cell (offset slightly for visual padding)
	var pos = grid_to_visual_pos(grid_pos) + Vector2(6, 3)

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
		visual.setup(unit, unit.get("is_ally", true))
		visual.update_statuses(status_manager.get_statuses(uid))
		grid_node.add_child(visual)
		unit_visuals[uid] = visual


# --- Turn Highlight ---

func _highlight_current_unit() -> void:
	_clear_turn_highlight()

	if current_unit.is_empty():
		return

	var grid_pos = current_unit.get("grid_position", Vector2i(1, 1))
	var cell_visual_size = CELL_SIZE - Vector2(CELL_GAP, CELL_GAP)

	turn_highlight = Polygon2D.new()
	turn_highlight.polygon = PackedVector2Array([
		Vector2(0, 0), Vector2(cell_visual_size.x, 0),
		Vector2(cell_visual_size.x, cell_visual_size.y), Vector2(0, cell_visual_size.y)
	])
	turn_highlight.position = grid_to_visual_pos(grid_pos) + Vector2(CELL_GAP / 2, CELL_GAP / 2)
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
	var pos = grid_to_visual_pos(grid_pos) + Vector2(CELL_SIZE.x / 2, 0)
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

	var grid_pos = current_unit.get("grid_position", Vector2i(0, 0))
	_log_action("--- %s's turn (col %d, row %d) ---" % [current_unit.name, grid_pos.x, grid_pos.y], Color.CYAN if current_unit.is_ally else Color(1.0, 0.5, 0.5))

	EventBus.turn_started.emit(current_unit.id)

	# Regenerate MP at turn start
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
	var regen = int(CombatConfigLoaderClass.get_balance("mp_regen_per_turn", 2))
	var new_mp = min(max_mp, current_mp + regen)
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

	# Use AI to make decision (unified grid)
	var decision = CombatAIClass.make_decision(
		current_unit,
		all_units,
		grid,
		GRID_SIZE,
		skills_data,
		status_manager
	)

	# Execute the AI's chosen action
	var skill = skills_data.get(decision.skill_id, skills_data.get("basic_attack", {}))
	var target_id = decision.target_ids[0] if not decision.target_ids.is_empty() else ""

	# Find target
	var target = _find_unit_by_id(target_id)
	if target.is_empty():
		var enemies = get_ally_units()  # AI's enemies are player allies
		if not enemies.is_empty():
			target = enemies[randi() % enemies.size()]

	if not target.is_empty():
		await _execute_skill(skill, current_unit, target)

	_end_turn()


func _execute_skill(skill: Dictionary, user: Dictionary, target: Dictionary) -> void:
	var skill_name = skill.get("name", "Attack")
	var mp_cost = skill.get("mp_cost", 0)

	# Deduct MP
	if mp_cost > 0:
		user["current_mp"] = max(0, user.get("current_mp", 0) - mp_cost)

	# For melee skills, auto-move to adjacent cell if not already adjacent
	var range_type = skill.get("range_type", "melee")
	var user_pos: Vector2i = user.get("grid_position", Vector2i(0, 0))
	var target_pos: Vector2i = target.get("grid_position", Vector2i(0, 0))

	if range_type == "melee" and not GridPathfinderClass.is_adjacent(user_pos, target_pos):
		await _auto_move_to_target(user, target)

	# Handle damage
	if skill.has("damage"):
		var result = DamageCalculatorClass.calculate_damage(skill, user, target)

		# Apply damage reduction from status effects (including defending)
		var reductions = status_manager.get_damage_reductions(target.get("id", ""))
		if not reductions.is_empty():
			result.damage = DamageCalculatorClass.apply_damage_reduction(
				result.damage, result.damage_type, reductions
			)

		_apply_damage(target, result.damage)

		# Build damage message
		var crit_text = " CRITICAL!" if result.is_critical else ""
		var eff_text = ""
		if result.effectiveness > 1.0:
			eff_text = " (Weak!)"
		elif result.effectiveness < 1.0:
			eff_text = " (Resist)"

		status_label.text = "%s uses %s on %s for %d damage!%s%s" % [
			user.name, skill_name, target.name, result.damage, crit_text, eff_text
		]

		# Action log entry
		var log_extras = ""
		if result.is_critical:
			log_extras += " CRIT!"
		if result.effectiveness > 1.0:
			log_extras += " Weak!"
		elif result.effectiveness < 1.0:
			log_extras += " Resist"

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


## Auto-move user to a cell adjacent to target (for melee skills)
## Triggers opportunity attacks along the path
func _auto_move_to_target(user: Dictionary, target: Dictionary) -> void:
	var user_pos: Vector2i = user.get("grid_position", Vector2i(0, 0))
	var target_pos: Vector2i = target.get("grid_position", Vector2i(0, 0))

	# Find the best adjacent cell to move to
	var best_adj = Vector2i(-1, -1)
	var best_dist = 999

	var adjacent_cells = GridPathfinderClass._get_neighbors(target_pos, GRID_SIZE)
	for adj in adjacent_cells:
		if grid.has(adj) and grid[adj] != user.get("id", ""):
			continue
		if adj == user_pos:
			return  # Already adjacent
		var path = GridPathfinderClass.find_path(user_pos, adj, grid, GRID_SIZE)
		if not path.is_empty() and path.size() < best_dist:
			best_dist = path.size()
			best_adj = adj

	if best_adj == Vector2i(-1, -1):
		return  # No valid path

	var path = GridPathfinderClass.find_path(user_pos, best_adj, grid, GRID_SIZE)
	if path.is_empty():
		return

	await _execute_movement(user, best_adj, path)


## Execute movement along a path with opportunity attack detection
func _execute_movement(unit: Dictionary, target_pos: Vector2i, path: Array[Vector2i] = []) -> void:
	var unit_id = unit.get("id", "")
	var old_pos: Vector2i = unit.get("grid_position", Vector2i(0, 0))

	if path.is_empty():
		path = GridPathfinderClass.find_path(old_pos, target_pos, grid, GRID_SIZE)

	if path.is_empty():
		return

	# Detect opportunity attackers
	var oa_attackers: Array[String] = []
	if CombatConfigLoaderClass.is_oa_enabled():
		oa_attackers = GridPathfinderClass.get_opportunity_attackers(path, unit_id, all_units, grid)
		# Cap at max per move
		var max_oa = CombatConfigLoaderClass.get_oa_max_per_move()
		if oa_attackers.size() > max_oa:
			oa_attackers.resize(max_oa)

	# Animate step-by-step movement
	for i in range(1, path.size()):
		var step_pos = path[i]

		# Update grid
		grid.erase(unit.get("grid_position", Vector2i(0, 0)))
		unit["grid_position"] = step_pos
		grid[step_pos] = unit_id

		# Update visual
		_update_unit_visuals()
		await get_tree().create_timer(0.15).timeout

	# Execute opportunity attacks after movement completes
	for attacker_id in oa_attackers:
		await _execute_opportunity_attack(attacker_id, unit_id)

	_log_action("%s moves to (%d,%d)" % [unit.name, target_pos.x, target_pos.y], Color(0.7, 0.9, 1.0))
	EventBus.position_changed.emit(unit_id, old_pos, target_pos)


## Execute an opportunity attack
func _execute_opportunity_attack(attacker_id: String, target_id: String) -> void:
	var attacker = _find_unit_by_id(attacker_id)
	var target = _find_unit_by_id(target_id)

	if attacker.is_empty() or target.is_empty():
		return

	var result = DamageCalculatorClass.calculate_opportunity_attack_damage(attacker, target, skills_data)

	# Apply damage reductions
	var reductions = status_manager.get_damage_reductions(target_id)
	if not reductions.is_empty():
		result.damage = DamageCalculatorClass.apply_damage_reduction(
			result.damage, result.damage_type, reductions
		)

	_apply_damage(target, result.damage)

	_log_action("  OA! %s strikes %s for %d dmg" % [attacker.name, target.name, result.damage], Color(1.0, 0.6, 0.2))
	_spawn_floating_text("OA %d" % result.damage, Color(1.0, 0.6, 0.2), target)

	if unit_visuals.has(target_id) and is_instance_valid(unit_visuals[target_id]):
		unit_visuals[target_id].flash_damage()

	_update_unit_visuals()
	await get_tree().create_timer(0.5).timeout


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
			var allies = get_ally_units() if user.is_ally else get_enemy_units()
			for ally in allies:
				status_manager.apply_status(ally.id, status_name, duration, effect)
				EventBus.status_applied.emit(ally.id, status_name)
			status_label.text += " Party gains %s!" % status_name
			_log_action("  +%s on party (%d turns)" % [status_name, duration], Color(0.5, 1.0, 0.5))

		"debuff", "enemy_debuff":
			if effect_type == "enemy_debuff":
				# Apply to all enemies
				var enemies = get_enemy_units() if user.is_ally else get_ally_units()
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
	# Collect defeated unit IDs
	var defeated_ids: Array = []
	for uid in all_units:
		var unit = all_units[uid]
		if unit.get("current_hp", 0) <= 0:
			status_manager.clear_unit(uid)
			defeated_ids.append(uid)

	# Remove from all_units
	for uid in defeated_ids:
		all_units.erase(uid)

	# Remove from turn order
	turn_order = turn_order.filter(func(u): return u.get("current_hp", 0) > 0)

	if current_turn_index >= turn_order.size():
		current_turn_index = 0

	# Rebuild grid
	_place_units_on_grid()
	_draw_grid()


func _check_combat_end() -> bool:
	if get_enemy_units().is_empty():
		_end_combat(true)
		return true
	elif get_ally_units().is_empty():
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
		results.show_victory(get_ally_units())
		results.continue_pressed.connect(func(): GameManager.end_combat(true))
	else:
		status_label.text = "Defeat..."
		_log_action("=== DEFEAT ===", Color(0.8, 0.2, 0.2))
		results.show_defeat()
		results.retry_pressed.connect(func(): get_tree().reload_current_scene())
		results.menu_pressed.connect(func(): GameManager.end_combat(false))


func _find_unit_by_id(unit_id: String) -> Dictionary:
	if all_units.has(unit_id):
		return all_units[unit_id]
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

	# Start target selection on unified grid
	target_selector.start_targeting(
		selected_skill,
		current_unit,
		all_units,
		grid,
		GRID_SIZE,
		grid_node,
		status_manager
	)


func _on_skill_pressed() -> void:
	if current_phase != CombatPhase.SELECTING_ACTION:
		return

	# Show skill panel
	action_panel.visible = false
	skill_panel.show_skills(current_unit, skills_data, all_units, grid, GRID_SIZE)


func _on_skill_selected(skill_id: String) -> void:
	selected_skill = skills_data.get(skill_id, {})
	selected_action = "skill"
	current_phase = CombatPhase.SELECTING_TARGET
	status_label.text = "Select target for %s..." % selected_skill.get("name", skill_id)

	# Start target selection on unified grid
	target_selector.start_targeting(
		selected_skill,
		current_unit,
		all_units,
		grid,
		GRID_SIZE,
		grid_node,
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
			status_manager.get_taunt_target(current_unit.get("id", ""))

	# Handle "all" targeting
	var target_type = PositionValidatorClass.get_targeting_type(selected_skill)
	if target_type == "all_allies":
		var targets = get_ally_units() if current_unit.is_ally else get_enemy_units()
		_execute_skill_on_all(selected_skill, current_unit, targets)
	elif target_type == "all_enemies":
		var targets = get_enemy_units() if current_unit.is_ally else get_ally_units()
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

	target_selector.start_move_targeting(current_unit, grid, GRID_SIZE, grid_node)


func _on_move_position_selected(position: Vector2i) -> void:
	var old_pos: Vector2i = current_unit.grid_position
	var unit_id: String = current_unit.id

	# Build path and execute movement (with OA detection)
	var path = GridPathfinderClass.find_path(old_pos, position, grid, GRID_SIZE)
	await _execute_movement(current_unit, position, path)

	_draw_grid()

	await get_tree().create_timer(0.3).timeout
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
