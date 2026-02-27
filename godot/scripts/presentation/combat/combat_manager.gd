extends Node2D
class_name CombatManager
## Manages turn-based combat on a unified grid with CTB turn order and AP economy.
## Unified grid replaces the old dual 3x3 ally/enemy grids.

# Preload logic classes
const DataLoaderClass = preload("res://scripts/data/data_loader.gd")
const StatusEffectManagerClass = preload("res://scripts/logic/combat/status_effect_manager.gd")
const DamageCalculatorClass = preload("res://scripts/logic/combat/damage_calculator.gd")
const PositionValidatorClass = preload("res://scripts/logic/combat/position_validator.gd")
const CombatAIClass = preload("res://scripts/logic/combat/combat_ai.gd")
const CombatConfigLoaderClass = preload("res://scripts/logic/combat/combat_config_loader.gd")
const GridPathfinderClass = preload("res://scripts/logic/combat/grid_pathfinder.gd")
const CTBTurnManagerClass = preload("res://scripts/logic/combat/ctb_turn_manager.gd")
const APSystemClass = preload("res://scripts/logic/combat/ap_system.gd")
const UnitVisualClass = preload("res://scripts/presentation/combat/unit_visual.gd")
const FloatingTextClass = preload("res://scripts/presentation/combat/floating_text.gd")
const CombatResultsClass = preload("res://scripts/presentation/combat/combat_results.gd")

# Grid configuration (loaded from combat_config.json)
var GRID_SIZE: Vector2i = Vector2i(7, 5)
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
var current_unit: Dictionary = {}

# Unified data structures
var all_units: Dictionary = {}  # unit_id -> unit Dict
var grid: Dictionary = {}       # Vector2i -> unit_id

# Selected action/target
var selected_action: String = ""
var selected_skill: Dictionary = {}
var _pending_ap_cost: int = 0  # AP cost deferred until action is confirmed

# Core systems (CTB turn order + AP economy)
var _ctb_manager = null  # CTBTurnManager instance
var _ap_system = null    # APSystem instance

# Skills data (loaded once)
var skills_data: Dictionary = {}

# Status effect manager instance
var status_manager = StatusEffectManagerClass.new()

# Persistent unit visuals (unit_id -> UnitVisual)
var unit_visuals: Dictionary = {}

# Turn highlight node
var turn_highlight: Polygon2D = null

# Action log
var action_log_text: TextEdit
const ACTION_LOG_MAX_LINES = 200

# Node references
@onready var battle_grid_container: Node2D = $BattleGrid
@onready var grid_node: Node2D = $BattleGrid/Grid
@onready var turn_list: VBoxContainer = $UI/TurnOrderPanel/TurnList
@onready var status_label: Label = $UI/StatusLabel
@onready var action_panel: Panel = $UI/ActionPanel
@onready var ap_label: Label = $UI/ActionPanel/APLabel
@onready var turn_preview_label: Label = $UI/ActionPanel/TurnPreviewLabel
@onready var skill_panel = $UI/SkillPanel
@onready var target_selector = $TargetSelector

# Turn highlight pulse state
var _highlight_pulse_time: float = 0.0


## Convert grid position to visual position (direct mapping, no mirroring)
func grid_to_visual_pos(grid_pos: Vector2i) -> Vector2:
	return Vector2(grid_pos.x, grid_pos.y) * (CELL_SIZE + Vector2(CELL_GAP, CELL_GAP))


## Calculate centered unit position within a cell
func get_centered_unit_position(grid_pos: Vector2i) -> Vector2:
	# Calculate actual unit size (85% of cell, constrained by aspect ratio)
	var available_width = CELL_SIZE.x * 0.85
	var available_height = CELL_SIZE.y * 0.85
	var width_scale = available_width / 56.0  # BASE_UNIT_WIDTH
	var height_scale = available_height / 70.0  # BASE_UNIT_HEIGHT
	var scale_factor = min(width_scale, height_scale)
	var actual_unit_width = 56.0 * scale_factor
	var actual_unit_height = 70.0 * scale_factor

	# Center based on actual unit size
	var base_pos = grid_to_visual_pos(grid_pos) + Vector2(CELL_GAP / 2, CELL_GAP / 2)
	var centering_offset = Vector2(
		(CELL_SIZE.x - actual_unit_width) / 2.0,
		(CELL_SIZE.y - actual_unit_height) / 2.0
	)
	return base_pos + centering_offset


func _ready() -> void:
	GameManager.change_state(GameManager.GameState.COMBAT)

	# Connect to window resize signal
	get_tree().root.size_changed.connect(_on_window_resized)

	# Load grid config - prioritize configurator overrides over config file
	CombatConfigLoaderClass.reload()

	# Check if configurator specified custom grid size
	if GameManager.story_flags.has("_combat_config_grid_cols"):
		var cols = GameManager.story_flags.get("_combat_config_grid_cols", 7)
		var rows = GameManager.story_flags.get("_combat_config_grid_rows", 5)
		GRID_SIZE = Vector2i(cols, rows)
	else:
		GRID_SIZE = CombatConfigLoaderClass.get_grid_size()

	# Calculate optimal cell size and position to fill available screen space
	_calculate_grid_layout()
	CELL_GAP = CombatConfigLoaderClass.get_cell_gap()

	# Initialize logic systems
	_ctb_manager = CTBTurnManagerClass.new()
	_ap_system = APSystemClass.new()

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

	# Create action log
	_setup_action_log()

	# Initialize combat
	_initialize_combat()


## Calculate optimal grid cell size and position to fill screen
func _calculate_grid_layout() -> void:
	# Screen dimensions
	const SCREEN_WIDTH = 1920.0
	const SCREEN_HEIGHT = 1080.0

	# UI panel dimensions
	const TURN_PANEL_WIDTH = 260.0      # Left side turn order panel
	const ACTION_LOG_WIDTH = 250.0      # Right side action log panel
	const ACTION_PANEL_HEIGHT = 200.0   # Bottom action panel
	const TOP_MARGIN = 60.0             # Top margin for status label
	const PADDING = 40.0                # Extra padding around grid

	# Calculate available space
	var available_width = SCREEN_WIDTH - TURN_PANEL_WIDTH - ACTION_LOG_WIDTH - (PADDING * 2)
	var available_height = SCREEN_HEIGHT - ACTION_PANEL_HEIGHT - TOP_MARGIN - (PADDING * 2)

	# Calculate cell size that fits the grid into available space
	var cell_width = available_width / GRID_SIZE.x
	var cell_height = available_height / GRID_SIZE.y

	# Use the smaller dimension to ensure the grid fits
	var cell_size = min(cell_width, cell_height)

	# Clamp cell size to reasonable bounds (min 40, max 120)
	cell_size = clamp(cell_size, 40.0, 120.0)

	CELL_SIZE = Vector2(cell_size, cell_size)

	# Calculate actual grid dimensions
	var grid_width = GRID_SIZE.x * (CELL_SIZE.x + CELL_GAP)
	var grid_height = GRID_SIZE.y * (CELL_SIZE.y + CELL_GAP)

	# Center the grid in available space
	var grid_x = TURN_PANEL_WIDTH + ((available_width - grid_width) / 2.0) + PADDING
	var grid_y = TOP_MARGIN + ((available_height - grid_height) / 2.0) + PADDING

	# Position the BattleGrid node (parent of grid_node)
	battle_grid_container.position = Vector2(grid_x, grid_y)

	print("Grid layout calculated: Cell size: %.1f, Grid pos: (%.1f, %.1f)" % [cell_size, grid_x, grid_y])


func _on_window_resized() -> void:
	"""Handle window resize - recalculate grid layout and update all visuals"""
	_calculate_grid_layout()
	_draw_grid()
	_update_all_unit_scales()
	_highlight_current_unit()


func _update_all_unit_scales() -> void:
	"""Update scale of all unit visuals to match new cell size"""
	for unit_id in unit_visuals:
		var visual = unit_visuals[unit_id]
		if is_instance_valid(visual):
			visual.update_scale(CELL_SIZE)

			# Reposition unit based on new cell size (centered in cell)
			var unit = all_units.get(unit_id, {})
			if not unit.is_empty():
				var grid_pos = unit.get("grid_position", Vector2i(1, 1))
				visual.position = get_centered_unit_position(grid_pos)


func _process(delta: float) -> void:
	# Pulse the turn highlight
	if turn_highlight != null and is_instance_valid(turn_highlight):
		_highlight_pulse_time += delta * 3.0
		var alpha = 0.15 + 0.15 * sin(_highlight_pulse_time)
		turn_highlight.color = Color(1.0, 1.0, 0.0, alpha)


func _input(event: InputEvent) -> void:
	# Hot reload: F5 key
	if event is InputEventKey and event.pressed and not event.is_echo():
		if event.keycode == KEY_F5:
			_hot_reload_data()
			get_viewport().set_input_as_handled()
		# Debug panel toggle: ` key (backtick)
		elif event.keycode == KEY_QUOTELEFT:
			# TODO: Toggle debug panel when implemented
			print("Debug panel toggle (not yet implemented)")
			get_viewport().set_input_as_handled()


func _hot_reload_data() -> void:
	print("🔄 Hot reloading combat data...")

	# Reload all JSON data
	CombatConfigLoaderClass.reload()
	var old_skills = skills_data
	skills_data = DataLoaderClass.load_skills()

	# Update grid config
	GRID_SIZE = CombatConfigLoaderClass.get_grid_size()
	CELL_GAP = CombatConfigLoaderClass.get_cell_gap()

	# Recalculate grid layout with new size
	_calculate_grid_layout()

	# Reload character and enemy data
	var characters = DataLoaderClass.load_characters()
	var enemies_db = DataLoaderClass.load_enemies()

	# Update existing units with new data
	for unit_id in all_units:
		var unit = all_units[unit_id]

		# Find matching character/enemy in loaded data
		if unit.get("is_ally", true):
			for char in characters:
				if char.get("id", "") == unit_id:
					# Update base stats (preserve current HP/MP)
					unit["base_stats"] = char.get("base_stats", unit.get("base_stats", {}))
					# Recalculate speed/constitution
					unit["speed"] = unit["base_stats"].get("agility", 5)
					unit["constitution"] = unit["base_stats"].get("vigor", 5)
					break
		else:
			# For enemies, check if template exists
			var enemy_base_id = unit_id.split("_")[0] + "_" + unit_id.split("_")[1] if "_" in unit_id else unit_id
			if enemies_db.has(enemy_base_id):
				var enemy_template = enemies_db[enemy_base_id]
				unit["base_stats"] = enemy_template.get("base_stats", unit.get("base_stats", {}))
				unit["speed"] = unit["base_stats"].get("agility", 5)
				unit["constitution"] = unit["base_stats"].get("vigor", 5)

	# Update visuals with new data
	_update_unit_visuals()

	# Update skill panel if visible
	if skill_panel.visible:
		skill_panel.hide_panel()

	# Log what changed
	var skills_changed = 0
	for skill_id in skills_data:
		if not old_skills.has(skill_id) or skills_data[skill_id] != old_skills[skill_id]:
			skills_changed += 1

	_log_action("🔄 Data reloaded: %d skills updated" % skills_changed, Color(0.5, 1.0, 0.5))
	status_label.text = "Data reloaded! (%d skills changed)" % skills_changed

	print("✅ Hot reload complete: %d skills changed" % skills_changed)


func _initialize_combat() -> void:
	current_phase = CombatPhase.INITIALIZING
	status_label.text = "Initializing Combat..."

	# Clear previous status effects
	status_manager.clear_all()

	# Load all units
	_load_units_from_encounter()
	print("Loaded %d total units" % all_units.size())

	# Place units on grid
	_place_units_on_grid()

	# Initialize CTB + AP systems
	_initialize_turn_systems()
	print("Turn systems initialized")

	# Draw grid visuals
	_draw_grid()
	print("Grid drawn. Grid node children: %d" % grid_node.get_child_count())

	var ally_count = get_ally_units().size()
	var enemy_count = get_enemy_units().size()
	_log_action("Combat started: %d allies vs %d enemies" % [ally_count, enemy_count])
	_log_action("Tip: Press F5 to hot reload data files", Color(0.7, 0.7, 1.0))

	# Update turn order UI
	_update_turn_order_ui()

	# Start first turn
	_start_next_turn()


## Load units from encounter data or legacy _combat_enemies fallback
func _load_units_from_encounter() -> void:
	all_units.clear()

	var encounter_id = GameManager.story_flags.get("_combat_encounter_id", "")
	var encounter_data: Dictionary = {}
	if encounter_id != "":
		encounter_data = DataLoaderClass.get_encounter(encounter_id)

	# Position override from configurator (index-based: "0","1","2" -> Vector2i)
	var pos_config: Dictionary = GameManager.story_flags.get("_combat_config_ally_positions", {})

	# Load allies from party
	var ally_positions = encounter_data.get("ally_positions", {})
	for i in range(GameManager.party.size()):
		var member = GameManager.party[i].duplicate(true)
		member["is_ally"] = true

		# Priority: configurator override > encounter ally_positions > default
		var pos_override: Dictionary = pos_config.get(str(i), {})
		if not pos_override.is_empty() and pos_override.get("x", -1) >= 0:
			member["grid_position"] = Vector2i(pos_override.get("x", 0), pos_override.get("y", 0))
		elif ally_positions.has(member.get("id", "")):
			var pos_arr = ally_positions[member.get("id", "")]
			member["grid_position"] = Vector2i(int(pos_arr[0]), int(pos_arr[1]))
		else:
			member["grid_position"] = _get_default_ally_position(i)

		# Derive speed/constitution for systems
		var base_stats = member.get("base_stats", {})
		member["speed"] = base_stats.get("agility", 5)
		member["constitution"] = base_stats.get("vigor", 5)

		# Derive HP/MP using config formula
		var vigor = base_stats.get("vigor", 5)
		var resonance = base_stats.get("resonance", 5)
		if not member.has("max_hp") or member["max_hp"] == 0:
			var hp = int(vigor * CombatConfigLoaderClass.get_balance("hp_per_vigor", 60))
			member["current_hp"] = hp
			member["max_hp"] = hp
		if not member.has("max_mp") or member["max_mp"] == 0:
			var mp = int(resonance * CombatConfigLoaderClass.get_balance("mp_per_resonance", 5))
			member["current_mp"] = mp
			member["max_mp"] = mp

		all_units[member["id"]] = member

	# Load enemies from encounter data or legacy story_flags
	var enemy_spawns = encounter_data.get("enemy_spawns", [])
	if not enemy_spawns.is_empty():
		# Encounter-based spawning with explicit positions
		var enemies_db = DataLoaderClass.load_enemies()
		for spawn in enemy_spawns:
			var enemy_id = spawn.get("enemy_id", "")
			var enemy_template = enemies_db.get(enemy_id, {})
			if enemy_template.is_empty():
				push_warning("Enemy template not found: " + enemy_id)
				continue

			var enemy = enemy_template.duplicate(true)
			enemy["is_ally"] = false

			var pos_arr = spawn.get("position", [GRID_SIZE.x - 2, 2])
			enemy["grid_position"] = Vector2i(int(pos_arr[0]), int(pos_arr[1]))

			var e_stats = enemy.get("base_stats", {})
			var e_vigor = e_stats.get("vigor", 5)
			var e_resonance = e_stats.get("resonance", 5)
			var e_hp = int(e_vigor * CombatConfigLoaderClass.get_balance("hp_per_vigor", 60))
			var e_mp = int(e_resonance * CombatConfigLoaderClass.get_balance("mp_per_resonance", 5))
			enemy["current_hp"] = e_hp
			enemy["max_hp"] = e_hp
			enemy["current_mp"] = e_mp
			enemy["max_mp"] = e_mp
			enemy["speed"] = e_stats.get("agility", 5)
			enemy["constitution"] = e_vigor

			# Handle duplicate IDs
			var uid = enemy_id
			var suffix = 1
			while all_units.has(uid):
				uid = "%s_%d" % [enemy_id, suffix]
				suffix += 1
			enemy["id"] = uid
			all_units[uid] = enemy
	else:
		# Legacy loading from story_flags (used by configurator flow)
		var enemy_data = GameManager.story_flags.get("_combat_enemies", [])
		for i in range(enemy_data.size()):
			var enemy = enemy_data[i].duplicate(true)
			enemy["is_ally"] = false
			enemy["grid_position"] = _get_default_enemy_position(i)

			var e_stats = enemy.get("base_stats", {})
			var e_vigor = e_stats.get("vigor", 5)
			var e_resonance = e_stats.get("resonance", 5)
			var e_hp = int(e_vigor * CombatConfigLoaderClass.get_balance("hp_per_vigor", 60))
			var e_mp = int(e_resonance * CombatConfigLoaderClass.get_balance("mp_per_resonance", 5))
			enemy["current_hp"] = e_hp
			enemy["max_hp"] = e_hp
			enemy["current_mp"] = e_mp
			enemy["max_mp"] = e_mp
			enemy["speed"] = e_stats.get("agility", 5)
			enemy["constitution"] = e_vigor

			all_units[enemy.id] = enemy


func _get_default_ally_position(index: int) -> Vector2i:
	match index:
		0: return Vector2i(1, 2)  # Left zone, center
		1: return Vector2i(1, 1)  # Left zone, top
		2: return Vector2i(0, 3)  # Far left, lower
		_: return Vector2i(0, index % GRID_SIZE.y)


func _get_default_enemy_position(index: int) -> Vector2i:
	match index:
		0: return Vector2i(GRID_SIZE.x - 2, 1)  # Right zone, top
		1: return Vector2i(GRID_SIZE.x - 1, 3)  # Far right, lower
		2: return Vector2i(GRID_SIZE.x - 1, 4)  # Far right, bottom
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


func _initialize_turn_systems() -> void:
	_ap_system.reset()

	# Initialize CTB manager with unit lookup
	_ctb_manager.initialize(func(unit_id): return all_units.get(unit_id, {}))

	# Register all units with CTB and AP
	for unit_id in all_units:
		var unit = all_units[unit_id]
		var speed = unit.get("speed", 5)
		var constitution = unit.get("constitution", 5)
		var agility = unit.get("base_stats", {}).get("agility", 5)
		_ctb_manager.add_unit(unit_id, speed)
		_ap_system.register_unit(unit_id, constitution, unit.get("is_ally", false), agility)


func _update_turn_order_ui() -> void:
	for child in turn_list.get_children():
		child.queue_free()

	var preview = _ctb_manager.get_turn_order_preview()

	for i in range(min(preview.size(), 10)):
		var unit_id = preview[i]
		var unit = all_units.get(unit_id, {})
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

	var remaining_ap = current_ap
	var speed = current_unit.get("speed", 5)
	var ticks = _ctb_manager.calculate_ticks_with_ap_bonus(speed, remaining_ap)
	turn_preview_label.text = "End turn now: %d ticks until next turn" % ticks


func _update_action_buttons() -> void:
	var attack_btn = $UI/ActionPanel/ActionButtons/AttackButton
	var skill_btn = $UI/ActionPanel/ActionButtons/SkillButton
	var item_btn = $UI/ActionPanel/ActionButtons/ItemButton
	var move_btn = $UI/ActionPanel/ActionButtons/MoveButton

	attack_btn.disabled = not _ap_system.can_afford(current_unit.id, "attack")
	# Enable skill button if any skill is affordable (cheapest is 1 AP for light skills)
	skill_btn.disabled = not _ap_system.can_afford(current_unit.id, "skill_light")
	item_btn.disabled = not _ap_system.can_afford(current_unit.id, "item")
	move_btn.disabled = not _ap_system.can_afford(current_unit.id, "move")


# --- Grid Drawing ---

func _draw_grid() -> void:
	_draw_grid_background()
	_update_unit_visuals()


func _draw_grid_background() -> void:
	# Remove only non-UnitVisual children (grid cells, highlights)
	for child in grid_node.get_children():
		if not child is UnitVisualClass:
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
				cell.color = Color(0.2, 0.3, 0.5, 0.4)   # Blue-tinted ally zone
			elif x >= GRID_SIZE.x - 2:
				cell.color = Color(0.5, 0.2, 0.2, 0.4)   # Red-tinted enemy zone
			else:
				cell.color = Color(0.25, 0.25, 0.3, 0.35) # Neutral gray

			grid_node.add_child(cell)


func _update_unit_visuals() -> void:
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
	var pos = get_centered_unit_position(grid_pos)

	if unit_visuals.has(uid) and is_instance_valid(unit_visuals[uid]):
		var visual = unit_visuals[uid]
		visual.position = pos
		visual.update_scale(CELL_SIZE)  # Update scale in case cell size changed
		visual.update_stats(unit)
		visual.update_statuses(status_manager.get_statuses(uid))
	else:
		var visual = UnitVisualClass.new()
		visual.position = pos
		visual.setup(unit, unit.get("is_ally", true), CELL_SIZE)  # Pass current cell size
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
	title.text = "Action Log (Ctrl+C to copy)"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.offset_left = 5
	title.offset_top = 5
	title.offset_right = 245
	title.offset_bottom = 25
	panel.add_child(title)

	action_log_text = TextEdit.new()
	action_log_text.offset_left = 5
	action_log_text.offset_top = 28
	action_log_text.offset_right = 245
	action_log_text.offset_bottom = 685
	action_log_text.editable = false
	action_log_text.wrap_mode = TextEdit.LINE_WRAPPING_BOUNDARY
	action_log_text.scroll_fit_content_height = true
	action_log_text.add_theme_font_size_override("font_size", 11)
	panel.add_child(action_log_text)


func _log_action(text: String, color: Color = Color.WHITE) -> void:
	if action_log_text == null:
		return

	# Append new line
	var current_text = action_log_text.text
	if not current_text.is_empty():
		current_text += "\n"
	current_text += text

	# Limit total lines to prevent memory issues
	var lines = current_text.split("\n")
	if lines.size() > ACTION_LOG_MAX_LINES:
		lines = lines.slice(lines.size() - ACTION_LOG_MAX_LINES, lines.size())
		current_text = "\n".join(lines)

	action_log_text.text = current_text
	_scroll_log_to_bottom.call_deferred()


func _scroll_log_to_bottom() -> void:
	if action_log_text != null:
		action_log_text.scroll_vertical = INF  # Scroll to bottom


# --- Turn Flow ---

func _start_next_turn() -> void:
	if _check_combat_end():
		return

	var current_unit_id = _ctb_manager.get_current_unit_id()
	current_unit = all_units.get(current_unit_id, {})

	if current_unit.is_empty():
		push_error("No current unit found!")
		return

	current_phase = CombatPhase.TURN_START
	current_unit["is_defending"] = false

	# Apply stat modifiers from status effects
	var modifiers = status_manager.get_stat_modifiers(current_unit.id)
	if not modifiers.is_empty():
		_apply_stat_modifiers(current_unit, modifiers)

	# Start AP for this turn
	var available_ap = _ap_system.start_turn(current_unit.id)

	status_label.text = "%s's turn (AP: %d)" % [current_unit.name, available_ap]
	_update_turn_order_ui()
	_highlight_current_unit()

	var grid_pos = current_unit.get("grid_position", Vector2i(0, 0))
	_log_action("--- %s's turn (AP: %d) ---" % [current_unit.name, available_ap],
		Color.CYAN if current_unit.get("is_ally", false) else Color(1.0, 0.5, 0.5))

	EventBus.turn_started.emit(current_unit.id)

	# Regenerate MP at turn start
	_regenerate_mp(current_unit)
	_update_unit_visuals()

	# If AI controlled, handle AI turn
	if not current_unit.get("is_ally", true):
		_handle_ai_turn()
	else:
		current_phase = CombatPhase.SELECTING_ACTION
		action_panel.visible = true
		_update_ap_display()
		_update_action_buttons()


func _regenerate_mp(unit: Dictionary) -> void:
	var max_mp = unit.get("max_mp", 25)
	var current_mp = unit.get("current_mp", 0)
	var regen = int(CombatConfigLoaderClass.get_balance("mp_regen_per_turn", 2))
	var new_mp = min(max_mp, current_mp + regen)
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

	var actions_taken = 0
	while _ap_system.can_afford(current_unit.id, "attack"):
		var decision = CombatAIClass.make_decision(
			current_unit,
			all_units,
			grid,
			GRID_SIZE,
			skills_data,
			status_manager
		)

		var skill = skills_data.get(decision.skill_id, skills_data.get("basic_attack", {}))
		var target_id = decision.target_ids[0] if not decision.target_ids.is_empty() else ""
		var target = _find_unit_by_id(target_id)

		# Validate target is alive
		if target.is_empty() or target.get("current_hp", 0) <= 0:
			var alive_enemies = get_ally_units()  # Allies are AI's enemies
			if alive_enemies.is_empty():
				break
			target = alive_enemies[randi() % alive_enemies.size()]

		# Check if the target is actually in range
		var target_pos: Vector2i = target.get("grid_position", Vector2i(0, 0))
		var user_pos: Vector2i = current_unit.get("grid_position", Vector2i(0, 0))
		var skill_range = PositionValidatorClass.get_skill_range(skill)
		var in_range = skill_range == 0 or PositionValidatorClass.is_in_range(user_pos, target_pos, skill_range)

		if not in_range:
			# Not in range — try to move closer first
			if _ap_system.can_afford(current_unit.id, "move"):
				var moved = await _ai_move_toward_enemies(current_unit)
				if moved:
					actions_taken += 1
					continue  # Re-evaluate after moving
			break  # Can't move or still not in range, end turn

		# Spend AP for the skill
		var ap_cost = _ap_system.get_skill_cost(skill)
		if not _ap_system.can_afford_amount(current_unit.id, ap_cost):
			break
		_ap_system.spend_ap(current_unit.id, ap_cost)

		# Deduct MP for AI skill usage
		var ai_mp_cost = skill.get("mp_cost", 0)
		if ai_mp_cost > 0:
			current_unit["current_mp"] = max(0, current_unit.get("current_mp", 0) - ai_mp_cost)

		await _execute_skill(skill, current_unit, target)
		actions_taken += 1
		await get_tree().create_timer(0.4).timeout

	if actions_taken == 0:
		status_label.text = "%s does nothing!" % current_unit.name
		await get_tree().create_timer(0.3).timeout

	_end_turn()


func _execute_skill(skill: Dictionary, user: Dictionary, target: Dictionary) -> void:
	var skill_name = skill.get("name", "Attack")

	# Note: MP is deducted in _on_target_selected before calling this.
	# AI turns deduct MP in _handle_ai_turn.

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
			user.get("name", "?"), skill_name, target.get("name", "?"), result.damage, crit_text, eff_text
		]

		var log_extras = ""
		if result.is_critical:
			log_extras += " CRIT!"
		if result.effectiveness > 1.0:
			log_extras += " Weak!"
		elif result.effectiveness < 1.0:
			log_extras += " Resist"

		var log_color = Color(0.7, 0.9, 1.0) if user.get("is_ally", true) else Color(1.0, 0.7, 0.7)
		_log_action("%s -> %s: %s for %d dmg%s" % [user.get("name", "?"), target.get("name", "?"), skill_name, result.damage, log_extras], log_color)

		# Floating damage number
		var float_color = Color.WHITE
		var large = false
		if result.is_critical:
			float_color = Color(1.0, 0.9, 0.1)
			large = true
		elif result.effectiveness > 1.0:
			float_color = Color(1.0, 0.3, 0.3)
		elif result.effectiveness < 1.0:
			float_color = Color(0.6, 0.6, 0.6)

		_spawn_floating_text(str(result.damage), float_color, target, large)

		# Flash the target unit visual
		var tid = target.get("id", "")
		if unit_visuals.has(tid) and is_instance_valid(unit_visuals[tid]):
			unit_visuals[tid].flash_damage()

		EventBus.unit_damaged.emit(target.get("id", ""), result.damage, result.damage_type)
	else:
		status_label.text = "%s uses %s!" % [user.get("name", "?"), skill_name]
		_log_action("%s uses %s" % [user.get("name", "?"), skill_name], Color(0.8, 0.8, 0.5))

	# Handle effects
	if skill.has("effect"):
		await _apply_skill_effect(skill, user, target)

	# Add burst gauge
	var burst_gain = skill.get("burst_gauge_gain", 5)
	user["burst_gauge"] = min(100, user.get("burst_gauge", 0) + burst_gain)
	EventBus.burst_gauge_changed.emit(user.get("id", ""), user["burst_gauge"])

	_update_unit_visuals()
	await get_tree().create_timer(1.0).timeout


## AI movement: move toward the nearest enemy when no melee target is in range
## Returns true if movement was executed
func _ai_move_toward_enemies(unit: Dictionary) -> bool:
	var unit_pos: Vector2i = unit.get("grid_position", Vector2i(0, 0))
	var move_range = PositionValidatorClass.get_movement_range(unit)
	var reachable = GridPathfinderClass.get_cells_in_range(unit_pos, move_range, grid, GRID_SIZE)

	if reachable.is_empty():
		return false

	# Find the closest enemy
	var enemies = get_ally_units()  # AI's enemies are allies
	if enemies.is_empty():
		return false

	# Pick the reachable cell that minimizes distance to the nearest enemy
	var best_cell = Vector2i(-1, -1)
	var best_dist = 999

	for cell in reachable:
		for enemy in enemies:
			var enemy_pos: Vector2i = enemy.get("grid_position", Vector2i(0, 0))
			var dist = GridPathfinderClass.manhattan_distance(cell, enemy_pos)
			if dist < best_dist:
				best_dist = dist
				best_cell = cell

	if best_cell == Vector2i(-1, -1) or best_cell == unit_pos:
		return false

	var path = GridPathfinderClass.find_path(unit_pos, best_cell, grid, GRID_SIZE)
	if path.is_empty():
		return false

	_ap_system.spend_action(unit.get("id", ""), "move")
	await _execute_movement(unit, best_cell, path)
	_draw_grid()
	await get_tree().create_timer(0.2).timeout
	return true


## Execute movement along a path
func _execute_movement(unit: Dictionary, target_pos: Vector2i, path: Array[Vector2i] = []) -> void:
	var unit_id = unit.get("id", "")
	var old_pos: Vector2i = unit.get("grid_position", Vector2i(0, 0))

	if path.is_empty():
		path = GridPathfinderClass.find_path(old_pos, target_pos, grid, GRID_SIZE)

	if path.is_empty():
		return

	# Animate step-by-step
	for i in range(1, path.size()):
		var step_pos = path[i]
		grid.erase(unit.get("grid_position", Vector2i(0, 0)))
		unit["grid_position"] = step_pos
		grid[step_pos] = unit_id

		_update_unit_visuals()
		await get_tree().create_timer(0.15).timeout

	_log_action("%s moves to (%d,%d)" % [unit.get("name", "?"), target_pos.x, target_pos.y], Color(0.7, 0.9, 1.0))
	EventBus.position_changed.emit(unit_id, old_pos, target_pos)


func _apply_skill_effect(skill: Dictionary, user: Dictionary, target: Dictionary) -> void:
	var effect = skill.effect
	var effect_type = effect.get("type", "")
	var status_name = effect.get("status", "")
	var duration = effect.get("duration", 1)

	match effect_type:
		"self_buff":
			status_manager.apply_status(user.id, status_name, duration, effect)
			EventBus.status_applied.emit(user.id, status_name)
			status_label.text += " %s gains %s!" % [user.get("name", "?"), status_name]
			_log_action("  +%s on %s (%d turns)" % [status_name, user.get("name", "?"), duration], Color(0.5, 1.0, 0.5))

		"ally_buff":
			status_manager.apply_status(target.id, status_name, duration, effect)
			EventBus.status_applied.emit(target.id, status_name)
			status_label.text += " %s gains %s!" % [target.get("name", "?"), status_name]
			_log_action("  +%s on %s (%d turns)" % [status_name, target.get("name", "?"), duration], Color(0.5, 1.0, 0.5))

		"party_buff":
			var allies = get_ally_units() if user.get("is_ally", true) else get_enemy_units()
			for ally in allies:
				status_manager.apply_status(ally.id, status_name, duration, effect)
				EventBus.status_applied.emit(ally.id, status_name)
			status_label.text += " Party gains %s!" % status_name
			_log_action("  +%s on party (%d turns)" % [status_name, duration], Color(0.5, 1.0, 0.5))

		"debuff", "enemy_debuff":
			if effect_type == "enemy_debuff":
				var enemies = get_enemy_units() if user.get("is_ally", true) else get_ally_units()
				for enemy in enemies:
					if status_name == "taunted":
						status_manager.apply_taunt(enemy.id, user.id, duration, effect.get("attacks_redirected", 1))
					else:
						status_manager.apply_status(enemy.id, status_name, duration, effect)
					EventBus.status_applied.emit(enemy.id, status_name)
				status_label.text += " Enemies are %s!" % status_name
				_log_action("  -%s on all enemies (%d turns)" % [status_name, duration], Color(1.0, 0.5, 0.5))
			else:
				status_manager.apply_status(target.id, status_name, duration, effect)
				EventBus.status_applied.emit(target.id, status_name)
				status_label.text += " %s is %s!" % [target.get("name", "?"), status_name]
				_log_action("  -%s on %s (%d turns)" % [status_name, target.get("name", "?"), duration], Color(1.0, 0.5, 0.5))


func _apply_damage(target: Dictionary, damage: int) -> void:
	target.current_hp = max(0, target.current_hp - damage)
	EventBus.unit_damaged.emit(target.id, damage, "physical")

	if target.current_hp <= 0:
		EventBus.unit_defeated.emit(target.id)
		_log_action("  %s defeated!" % target.get("name", "?"), Color(1.0, 0.3, 0.3))


func _end_turn() -> void:
	current_phase = CombatPhase.TURN_END
	_clear_turn_highlight()

	# Process status effect tick
	var expired = status_manager.tick_turn_end(current_unit.id)
	for status_name in expired:
		EventBus.status_removed.emit(current_unit.id, status_name)
		_log_action("  %s expired on %s" % [status_name, current_unit.get("name", "?")], Color(0.6, 0.6, 0.6))
		if current_unit.has("original_stats"):
			current_unit["base_stats"] = current_unit["original_stats"].duplicate()

	EventBus.turn_ended.emit(current_unit.id)
	action_panel.visible = false

	# Get remaining AP for CTB speed bonus
	var remaining_ap = _ap_system.end_turn(current_unit.id)
	var unit_name = current_unit.get("name", "?")
	var log_color = Color.CYAN if current_unit.get("is_ally", false) else Color(1.0, 0.5, 0.5)
	_log_action("--- %s ends turn (AP left: %d) ---" % [unit_name, remaining_ap], log_color)

	var speed = current_unit.get("speed", 5)
	_ctb_manager.end_turn(current_unit.id, speed, remaining_ap)

	# Remove defeated units
	_remove_defeated_units()

	# Start next turn
	_start_next_turn()


func _remove_defeated_units() -> void:
	var defeated_ids: Array = []
	for uid in all_units:
		if all_units[uid].get("current_hp", 0) <= 0:
			status_manager.clear_unit(uid)
			_ctb_manager.remove_unit(uid)
			_ap_system.remove_unit(uid)
			defeated_ids.append(uid)

	for uid in defeated_ids:
		all_units.erase(uid)

	# Rebuild grid from surviving units
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
	return all_units.get(unit_id, {})


# ============================================================================
# MULTI-ACTION TURN FLOW
# ============================================================================

## After executing an action, return to action selection if AP remains.
## Otherwise, end the turn automatically.
func _return_to_action_selection() -> void:
	var remaining_ap = _ap_system.get_current_ap(current_unit.id)
	if remaining_ap <= 0 or current_unit.get("current_hp", 0) <= 0:
		_end_turn()
		return

	# Check if combat ended (target might have been defeated)
	if _check_combat_end():
		return

	current_phase = CombatPhase.SELECTING_ACTION
	action_panel.visible = true
	status_label.text = "%s's turn (AP: %d)" % [current_unit.get("name", "?"), remaining_ap]
	_log_action("  %s has %d AP remaining" % [current_unit.get("name", "?"), remaining_ap], Color(0.6, 0.8, 0.6))
	_update_ap_display()
	_update_action_buttons()
	_update_turn_order_ui()
	_update_unit_visuals()


# ============================================================================
# ACTION HANDLERS
# ============================================================================

func _on_attack_pressed() -> void:
	if current_phase != CombatPhase.SELECTING_ACTION:
		return

	if not _ap_system.can_afford(current_unit.id, "attack"):
		status_label.text = "Not enough AP!"
		return

	# AP is spent after target confirmation, not here
	selected_skill = skills_data.get("basic_attack", {})
	selected_action = "attack"
	_pending_ap_cost = _ap_system.get_action_cost("attack")
	current_phase = CombatPhase.SELECTING_TARGET
	status_label.text = "Select target..."
	action_panel.visible = false

	target_selector.start_targeting(
		selected_skill,
		current_unit,
		all_units,
		grid,
		GRID_SIZE,
		grid_node,
		status_manager,
		CELL_SIZE,
		CELL_GAP
	)


func _on_skill_pressed() -> void:
	if current_phase != CombatPhase.SELECTING_ACTION:
		return

	action_panel.visible = false
	skill_panel.show_skills(current_unit, skills_data, all_units, grid, GRID_SIZE, _ap_system)


func _on_skill_selected(skill_id: String) -> void:
	selected_skill = skills_data.get(skill_id, {})
	selected_action = "skill"

	# Determine AP cost for this skill (deferred until confirmation)
	_pending_ap_cost = _ap_system.get_skill_cost(selected_skill)
	if not _ap_system.can_afford_amount(current_unit.id, _pending_ap_cost):
		status_label.text = "Not enough AP for %s!" % selected_skill.get("name", skill_id)
		action_panel.visible = true
		return

	current_phase = CombatPhase.SELECTING_TARGET
	status_label.text = "Select target for %s..." % selected_skill.get("name", skill_id)

	target_selector.start_targeting(
		selected_skill,
		current_unit,
		all_units,
		grid,
		GRID_SIZE,
		grid_node,
		status_manager,
		CELL_SIZE,
		CELL_GAP
	)


func _on_skill_cancelled() -> void:
	_pending_ap_cost = 0
	action_panel.visible = true
	current_phase = CombatPhase.SELECTING_ACTION
	_update_ap_display()
	_update_action_buttons()


func _on_target_selected(target_id: String) -> void:
	var target = _find_unit_by_id(target_id)

	# Spend the deferred AP cost now that action is confirmed
	_ap_system.spend_ap(current_unit.id, _pending_ap_cost)

	# Deduct MP cost
	var mp_cost = selected_skill.get("mp_cost", 0)
	if mp_cost > 0:
		current_unit["current_mp"] = max(0, current_unit.get("current_mp", 0) - mp_cost)

	# Consume taunt charge when player targets enemies
	if current_unit.get("is_ally", true):
		var target_type = PositionValidatorClass.get_targeting_type(selected_skill)
		if target_type in ["single_enemy", "all_enemies"]:
			status_manager.get_taunt_target(current_unit.get("id", ""))

	var tt = PositionValidatorClass.get_targeting_type(selected_skill)
	if tt == "all_allies":
		var targets = get_ally_units() if current_unit.get("is_ally", true) else get_enemy_units()
		await _execute_skill_on_all(selected_skill, current_unit, targets)
	elif tt == "all_enemies":
		var targets = get_enemy_units() if current_unit.get("is_ally", true) else get_ally_units()
		await _execute_skill_on_all(selected_skill, current_unit, targets)
	elif tt == "self":
		await _execute_skill(selected_skill, current_unit, current_unit)
		_return_to_action_selection()
	else:
		if not target.is_empty():
			await _execute_skill(selected_skill, current_unit, target)
		_return_to_action_selection()


func _execute_skill_on_all(skill: Dictionary, user: Dictionary, targets: Array) -> void:
	for target in targets:
		await _execute_skill(skill, user, target)
	_return_to_action_selection()


func _on_targeting_cancelled() -> void:
	_pending_ap_cost = 0
	action_panel.visible = true
	current_phase = CombatPhase.SELECTING_ACTION
	var remaining_ap = _ap_system.get_current_ap(current_unit.id)
	status_label.text = "%s's turn (AP: %d)" % [current_unit.get("name", "?"), remaining_ap]
	_update_ap_display()
	_update_action_buttons()


func _on_item_pressed() -> void:
	status_label.text = "Items not yet implemented"


func _on_move_pressed() -> void:
	if current_phase != CombatPhase.SELECTING_ACTION:
		return

	if not _ap_system.can_afford(current_unit.id, "move"):
		status_label.text = "Not enough AP to move!"
		return

	selected_action = "move"
	current_phase = CombatPhase.SELECTING_TARGET
	status_label.text = "Select position to move to..."
	action_panel.visible = false

	target_selector.start_move_targeting(current_unit, grid, GRID_SIZE, grid_node, CELL_SIZE, CELL_GAP)


func _on_move_position_selected(position: Vector2i) -> void:
	_ap_system.spend_action(current_unit.id, "move")

	var old_pos: Vector2i = current_unit.get("grid_position", Vector2i(0, 0))
	var path = GridPathfinderClass.find_path(old_pos, position, grid, GRID_SIZE)
	await _execute_movement(current_unit, position, path)

	_draw_grid()
	_highlight_current_unit()
	await get_tree().create_timer(0.3).timeout
	_return_to_action_selection()


func _on_defend_pressed() -> void:
	if current_phase != CombatPhase.SELECTING_ACTION:
		return

	current_unit["is_defending"] = true

	# Defending is free (no AP cost) but ends turn with all remaining AP conserved
	status_manager.apply_status(current_unit.id, "defending", 2, {
		"damage_reduction": {"all": 0.5}
	})
	EventBus.status_applied.emit(current_unit.id, "defending")

	status_label.text = "%s defends!" % current_unit.get("name", "?")
	_log_action("%s defends (50%% DR)" % current_unit.get("name", "?"), Color(0.5, 0.7, 1.0))
	_update_unit_visuals()

	await get_tree().create_timer(0.5).timeout
	_end_turn()


func _on_end_turn_pressed() -> void:
	if current_phase != CombatPhase.SELECTING_ACTION:
		return

	var remaining = _ap_system.get_current_ap(current_unit.id)
	if remaining > 0:
		status_label.text = "%s conserves %d AP!" % [current_unit.get("name", "?"), remaining]
	else:
		status_label.text = "%s ends turn" % current_unit.get("name", "?")

	await get_tree().create_timer(0.3).timeout
	_end_turn()


func _on_back_pressed() -> void:
	GameManager.end_combat(true)
