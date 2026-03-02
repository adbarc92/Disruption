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
const TileEnvironmentManagerClass = preload("res://scripts/logic/combat/tile_environment_manager.gd")
const UnitVisualClass = preload("res://scripts/presentation/combat/unit_visual.gd")
const FloatingTextClass = preload("res://scripts/presentation/combat/floating_text.gd")
const CombatResultsClass = preload("res://scripts/presentation/combat/combat_results.gd")

# Grid configuration (loaded from combat_config.json)
var GRID_SIZE: Vector2i = Vector2i(7, 5)
var HEX_SIZE: float = 48.0  # Hex radius (center to vertex)
const HEX_INSET: float = 2.0  # Visual gap between hex cells

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

# Equipment data (loaded once)
var equipment_data: Dictionary = {}

# Status effect manager instance
var status_manager = StatusEffectManagerClass.new()

# Tile environment manager (Blood & Soil system)
var tile_env_manager: TileEnvironmentManagerClass = TileEnvironmentManagerClass.new()

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


## Convert grid position to visual pixel position (pointy-top, odd-row offset)
func grid_to_visual_pos(grid_pos: Vector2i) -> Vector2:
	var col = grid_pos.x
	var row = grid_pos.y
	var x = HEX_SIZE * sqrt(3.0) * (col + 0.5 * (row & 1))
	var y = HEX_SIZE * 1.5 * row
	return Vector2(x, y)


## Generate pointy-top hex polygon vertices centered at origin
func _hex_polygon(size: float) -> PackedVector2Array:
	var points = PackedVector2Array()
	for i in range(6):
		var angle_deg = 60.0 * i - 30.0
		var angle_rad = deg_to_rad(angle_deg)
		points.append(Vector2(size * cos(angle_rad), size * sin(angle_rad)))
	return points


## Convert pixel position (local to grid_node) to grid offset coordinates
func pixel_to_hex(pixel: Vector2) -> Vector2i:
	var q_frac = (sqrt(3.0) / 3.0 * pixel.x - 1.0 / 3.0 * pixel.y) / HEX_SIZE
	var r_frac = (2.0 / 3.0 * pixel.y) / HEX_SIZE
	# Cube round
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
	# Convert axial (q, r) back to offset (col, row)
	var row = int(r)
	var col = int(q) + (int(r) - (int(r) & 1)) / 2
	return Vector2i(col, row)


## Calculate centered unit position within a cell
## Works for both hex and square grids: computes unit visual size from cell
## bounding box, then offsets so the unit is centered on the cell position.
func get_centered_unit_position(grid_pos: Vector2i) -> Vector2:
	var center = grid_to_visual_pos(grid_pos)
	var cell_bounds = Vector2(HEX_SIZE * sqrt(3.0), HEX_SIZE * 2.0)
	# Mirror UnitVisual._calculate_scaled_sizes logic
	var available_w = cell_bounds.x * 0.85
	var available_h = cell_bounds.y * 0.85
	var scale_factor = min(available_w / 56.0, available_h / 70.0)  # BASE_UNIT_WIDTH, BASE_UNIT_HEIGHT
	var unit_w = 56.0 * scale_factor
	var unit_h = 70.0 * scale_factor
	return center - Vector2(unit_w / 2.0, unit_h / 2.0)


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

	# Calculate optimal hex size and position to fill available screen space
	_calculate_grid_layout()

	# Initialize logic systems
	_ctb_manager = CTBTurnManagerClass.new()
	_ap_system = APSystemClass.new()

	# Load skills data
	skills_data = DataLoaderClass.load_skills()
	equipment_data = DataLoaderClass.load_equipment()

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


func _calculate_grid_layout() -> void:
	const SCREEN_WIDTH = 1920.0
	const SCREEN_HEIGHT = 1080.0
	const TURN_PANEL_WIDTH = 260.0
	const ACTION_LOG_WIDTH = 250.0
	const ACTION_PANEL_HEIGHT = 200.0
	const TOP_MARGIN = 60.0
	const PADDING = 40.0

	var available_width = SCREEN_WIDTH - TURN_PANEL_WIDTH - ACTION_LOG_WIDTH - (PADDING * 2)
	var available_height = SCREEN_HEIGHT - ACTION_PANEL_HEIGHT - TOP_MARGIN - (PADDING * 2)

	# For pointy-top hexes:
	# grid_width = hex_size * sqrt(3) * (cols + 0.5)
	# grid_height = hex_size * 1.5 * (rows - 1) + hex_size * 2
	var hex_from_width = available_width / (sqrt(3.0) * (GRID_SIZE.x + 0.5))
	var hex_from_height = available_height / (1.5 * (GRID_SIZE.y - 1) + 2.0)

	HEX_SIZE = clamp(min(hex_from_width, hex_from_height), 20.0, 60.0)

	# Calculate actual grid dimensions
	var grid_width = HEX_SIZE * sqrt(3.0) * (GRID_SIZE.x + 0.5)
	var grid_height = HEX_SIZE * (1.5 * (GRID_SIZE.y - 1) + 2.0)

	var grid_x = TURN_PANEL_WIDTH + ((available_width - grid_width) / 2.0) + PADDING
	var grid_y = TOP_MARGIN + ((available_height - grid_height) / 2.0) + PADDING

	battle_grid_container.position = Vector2(grid_x, grid_y)

	print("Hex grid layout: size=%.1f, pos=(%.1f, %.1f)" % [HEX_SIZE, grid_x, grid_y])


func _on_window_resized() -> void:
	_calculate_grid_layout()
	_draw_grid()
	_highlight_current_unit()


## Update scale of all unit visuals to match new hex size
func _update_all_unit_scales() -> void:
	for unit_id in unit_visuals:
		var visual = unit_visuals[unit_id]
		if is_instance_valid(visual):
			visual.update_scale(Vector2(HEX_SIZE * sqrt(3.0), HEX_SIZE * 2.0))

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
	equipment_data = DataLoaderClass.load_equipment()

	# Re-resolve abilities for ally units
	for unit_id in all_units:
		var unit = all_units[unit_id]
		if unit.get("is_ally", true):
			unit["abilities"] = DataLoaderClass.resolve_character_abilities(unit, equipment_data)

	# Update grid config
	GRID_SIZE = CombatConfigLoaderClass.get_grid_size()
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

	# Reset tile environment on hot reload
	tile_env_manager.clear_all()

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
	tile_env_manager.clear_all()

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

		# Resolve abilities from starting_abilities + equipment
		member["abilities"] = DataLoaderClass.resolve_character_abilities(member, equipment_data)

		# Initialize equipment charges
		var equip_charges = {}
		for equip_id in member.get("equipment", []):
			var equip = equipment_data.get(equip_id, {})
			if equip.get("charges", 0) > 0:
				equip_charges[equip_id] = equip.charges
		member["equipment_charges"] = equip_charges

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

	var inset_size = HEX_SIZE - HEX_INSET
	var hex_poly = _hex_polygon(inset_size)

	for x in range(GRID_SIZE.x):
		for y in range(GRID_SIZE.y):
			var cell = Polygon2D.new()
			cell.polygon = hex_poly
			cell.position = grid_to_visual_pos(Vector2i(x, y))

			if x < 2:
				cell.color = Color(0.2, 0.3, 0.5, 0.4)
			elif x >= GRID_SIZE.x - 2:
				cell.color = Color(0.5, 0.2, 0.2, 0.4)
			else:
				cell.color = Color(0.25, 0.25, 0.3, 0.35)

			grid_node.add_child(cell)

			# Soil tint overlay
			var soil_level = tile_env_manager.get_max_soil_at(Vector2i(x, y))
			if soil_level > 0:
				var soil_overlay = Polygon2D.new()
				soil_overlay.polygon = hex_poly
				soil_overlay.position = grid_to_visual_pos(Vector2i(x, y))
				# Warm amber that intensifies: level 1=faint, 2=medium, 3=bright
				var alpha = 0.12 + (soil_level * 0.08)
				soil_overlay.color = Color(0.85, 0.65, 0.2, alpha)
				grid_node.add_child(soil_overlay)


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
	var hex_cell_size = Vector2(HEX_SIZE * sqrt(3.0), HEX_SIZE * 2.0)

	if unit_visuals.has(uid) and is_instance_valid(unit_visuals[uid]):
		var visual = unit_visuals[uid]
		visual.position = pos
		visual.update_scale(hex_cell_size)
		visual.update_stats(unit)
		visual.update_statuses(status_manager.get_statuses(uid))
		visual.update_soil(tile_env_manager.get_soil_intensity(grid_pos, uid))
	else:
		var visual = UnitVisualClass.new()
		visual.position = pos
		visual.setup(unit, unit.get("is_ally", true), hex_cell_size)
		visual.update_statuses(status_manager.get_statuses(uid))
		visual.update_soil(tile_env_manager.get_soil_intensity(grid_pos, uid))
		grid_node.add_child(visual)
		unit_visuals[uid] = visual


# --- Turn Highlight ---

func _highlight_current_unit() -> void:
	_clear_turn_highlight()

	if current_unit.is_empty():
		return

	var grid_pos = current_unit.get("grid_position", Vector2i(1, 1))
	var inset_size = HEX_SIZE - HEX_INSET

	turn_highlight = Polygon2D.new()
	turn_highlight.polygon = _hex_polygon(inset_size)
	turn_highlight.position = grid_to_visual_pos(grid_pos)
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
	var pos = grid_to_visual_pos(grid_pos) + Vector2(0, -HEX_SIZE)
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

	# Blood & Soil: check if unit stayed on same tile
	var unit_id_for_soil = current_unit.get("id", "")
	var current_grid_pos = current_unit.get("grid_position", Vector2i(0, 0))
	var soil_eligible = current_unit.get("is_ally", true) or current_unit.get("soil_enabled", false)

	if soil_eligible and tile_env_manager.did_unit_stay(unit_id_for_soil, current_grid_pos):
		var new_intensity = tile_env_manager.increment_soil(current_grid_pos, unit_id_for_soil)
		if new_intensity > 0:
			_log_action("  Soil %d on %s (rooted)" % [new_intensity, current_unit.get("name", "?")],
				Color(0.85, 0.7, 0.3))

	# Apply tile bonus MP regen
	var tile_bonuses = tile_env_manager.get_bonuses_for_unit(unit_id_for_soil, current_grid_pos)
	if tile_bonuses.get("mp_regen", 0) > 0:
		var bonus_mp = tile_bonuses["mp_regen"]
		current_unit["current_mp"] = mini(current_unit.get("max_mp", 25), current_unit.get("current_mp", 0) + bonus_mp)
		_log_action("  +%d MP from Soil" % bonus_mp, Color(0.4, 0.6, 0.9))

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

	# Handle spend_all_mp special (Break Stock)
	var special_hit_count = 0
	if skill.has("special") and skill.special.get("type", "") == "spend_all_mp":
		var mp_available = user.get("current_mp", 0)
		user["current_mp"] = 0
		special_hit_count = max(2, int(mp_available / 2))
		_log_action("  %s spends all %d MP! (%d hits)" % [user.get("name", "?"), mp_available, special_hit_count], Color(1.0, 0.85, 0.2))

	# Handle healing
	if skill.has("healing"):
		var healing_data = skill.healing
		var heal_amount = 0
		if healing_data.has("base_percent"):
			heal_amount = int(ceil(user.get("max_hp", 100) * healing_data.base_percent))
		else:
			heal_amount = healing_data.get("base", 0)
			var scaling_stat = healing_data.get("stat_scaling", "")
			if scaling_stat != "":
				var stat_val = user.get("base_stats", {}).get(scaling_stat, 5)
				heal_amount = int(ceil(heal_amount * (1.0 + stat_val * 0.15)))

		user["current_hp"] = min(user.get("max_hp", 100), user.get("current_hp", 0) + heal_amount)
		_spawn_floating_text("+%d" % heal_amount, Color(0.3, 1.0, 0.3), user, false)
		_log_action("  %s heals for %d HP!" % [user.get("name", "?"), heal_amount], Color(0.3, 1.0, 0.3))
		status_label.text = "%s heals for %d HP!" % [user.get("name", "?"), heal_amount]

	# Handle damage
	if skill.has("damage"):
		var hit_count = skill.damage.get("hits", 1)
		if special_hit_count > 0:
			hit_count = special_hit_count

		# Check for multi_hit_bonus from combat_flow status
		if hit_count > 1 and status_manager.has_status(user.get("id", ""), "combat_flow"):
			var bonus_data = status_manager.get_status_data(user.get("id", ""), "combat_flow")
			hit_count += bonus_data.get("multi_hit_bonus", 0)

		# Apply tile environment damage bonus (attacker's Soil)
		var attacker_pos = user.get("grid_position", Vector2i(0, 0))
		var attacker_tile_bonuses = tile_env_manager.get_bonuses_for_unit(user.get("id", ""), attacker_pos)
		if attacker_tile_bonuses.get("damage_mult", 0.0) > 0.0:
			result.damage = int(ceil(result.damage * (1.0 + attacker_tile_bonuses["damage_mult"])))

		# Apply tile environment damage reduction (defender's Soil)
		var defender_pos = target.get("grid_position", Vector2i(0, 0))
		var defender_tile_bonuses = tile_env_manager.get_bonuses_for_unit(target.get("id", ""), defender_pos)
		if defender_tile_bonuses.get("damage_reduction", 0.0) > 0.0:
			result.damage = int(floor(result.damage * (1.0 - defender_tile_bonuses["damage_reduction"])))

		# Apply damage reduction from status effects
		var reductions = status_manager.get_damage_reductions(target.get("id", ""))
		if not reductions.is_empty():
			result.damage = DamageCalculatorClass.apply_damage_reduction(
				result.damage, result.damage_type, reductions
			)

		# Check for pitched_stance (double damage on next attack)
		var stance_mult = 1.0
		if status_manager.has_status(user.get("id", ""), "pitched_stance"):
			stance_mult = 2.0
			status_manager.remove_status(user.get("id", ""), "pitched_stance")
			_log_action("  Stance of Pitch activates! 2x damage!", Color(1.0, 0.9, 0.2))

		var total_damage = 0
		for hit_i in range(hit_count):
			var result = DamageCalculatorClass.calculate_damage(skill, user, target)

			# Apply stance multiplier
			result.damage = int(ceil(result.damage * stance_mult))

			# Apply tile environment damage bonus (attacker's Soil)
			var attacker_pos = user.get("grid_position", Vector2i(0, 0))
			var attacker_tile_bonuses = tile_env_manager.get_bonuses_for_unit(user.get("id", ""), attacker_pos)
			if attacker_tile_bonuses.get("damage_mult", 0.0) > 0.0:
				result.damage = int(ceil(result.damage * (1.0 + attacker_tile_bonuses["damage_mult"])))

			# Apply tile environment damage reduction (defender's Soil)
			var defender_pos = target.get("grid_position", Vector2i(0, 0))
			var defender_tile_bonuses = tile_env_manager.get_bonuses_for_unit(target.get("id", ""), defender_pos)
			if defender_tile_bonuses.get("damage_reduction", 0.0) > 0.0:
				result.damage = int(floor(result.damage * (1.0 - defender_tile_bonuses["damage_reduction"])))

			# Apply damage reduction from status effects
			var reductions = status_manager.get_damage_reductions(target.get("id", ""))
			if not reductions.is_empty():
				result.damage = DamageCalculatorClass.apply_damage_reduction(
					result.damage, result.damage_type, reductions
				)

			_apply_damage(target, result.damage)
			total_damage += result.damage

			# Floating text per hit
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

			# Flash target
			var tid = target.get("id", "")
			if unit_visuals.has(tid) and is_instance_valid(unit_visuals[tid]):
				unit_visuals[tid].flash_damage()

			# Apply per-hit random debuff if applicable
			if skill.has("effect") and skill.effect.get("type", "") == "random_debuff_per_hit":
				var pool = skill.effect.get("debuff_pool", [])
				var debuff_duration = skill.effect.get("duration", 2)
				if not pool.is_empty():
					var random_status = pool[randi() % pool.size()]
					status_manager.apply_status(target.get("id", ""), random_status, debuff_duration, {})
					EventBus.status_applied.emit(target.get("id", ""), random_status)
					_log_action("  %s inflicts %s!" % [user.get("name", "?"), random_status], Color(1.0, 0.5, 0.5))

			# Small delay between hits
			if hit_count > 1 and hit_i < hit_count - 1:
				await get_tree().create_timer(0.25).timeout

			# Stop hitting if target is defeated
			if target.get("current_hp", 0) <= 0:
				break

		var hit_text = " (%d hits)" % hit_count if hit_count > 1 else ""
		var crit_text = ""
		var eff_text = ""
		status_label.text = "%s uses %s on %s for %d damage!%s" % [
			user.get("name", "?"), skill_name, target.get("name", "?"), total_damage, hit_text
		]
		_log_action("%s -> %s: %s for %d dmg%s" % [user.get("name", "?"), target.get("name", "?"), skill_name, total_damage, hit_text],
			Color(0.7, 0.9, 1.0) if user.get("is_ally", true) else Color(1.0, 0.7, 0.7))

		EventBus.unit_damaged.emit(target.get("id", ""), total_damage, skill.damage.get("type", "physical"))
	elif not skill.has("healing"):
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
			var dist = GridPathfinderClass.hex_distance(cell, enemy_pos)
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

	# Blood & Soil: mark old position as decaying when unit moves
	tile_env_manager.mark_soil_decaying(old_pos, unit_id)

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
				# Check apply chance
				var apply_chance = effect.get("apply_chance", 1.0)
				if apply_chance < 1.0 and randf() > apply_chance:
					_log_action("  %s resists %s!" % [target.get("name", "?"), status_name], Color(0.6, 0.6, 0.6))
					return
				status_manager.apply_status(target.id, status_name, duration, effect)
				EventBus.status_applied.emit(target.id, status_name)
				status_label.text += " %s is %s!" % [target.get("name", "?"), status_name]
				_log_action("  -%s on %s (%d turns)" % [status_name, target.get("name", "?"), duration], Color(1.0, 0.5, 0.5))

		"forced_movement":
			_apply_forced_movement(effect, user, target)

		"self_reposition":
			await get_tree().create_timer(0.3).timeout
			_apply_self_reposition(effect, user, target)

		"reveal":
			target["revealed"] = true
			var weaknesses = target.get("weaknesses", [])
			var resistances = target.get("resistances", [])
			var weak_text = ", ".join(weaknesses) if not weaknesses.is_empty() else "none"
			var resist_text = ", ".join(resistances) if not resistances.is_empty() else "none"
			_log_action("  Revealed %s! Weak: %s | Resist: %s" % [target.get("name", "?"), weak_text, resist_text], Color(0.9, 0.9, 0.3))
			status_label.text = "%s's weaknesses revealed!" % target.get("name", "?")

		"weapon_buff":
			status_manager.apply_status(user.id, status_name, duration, effect)
			EventBus.status_applied.emit(user.id, status_name)
			var element_text = effect.get("element", "chosen element")
			_log_action("  %s's weapon infused with %s!" % [user.get("name", "?"), element_text], Color(0.5, 1.0, 0.8))

		"random_debuff_per_hit":
			# Handled per-hit in _execute_skill damage loop
			pass

		"create_terrain":
			# Placeholder for terrain creation (The Wall)
			_log_action("  %s creates %s!" % [user.get("name", "?"), effect.get("terrain", "terrain")], Color(0.7, 0.5, 0.3))


## Handle forced movement effects (push up/down/toward/away)
func _apply_forced_movement(effect: Dictionary, user: Dictionary, target: Dictionary) -> void:
	var direction = effect.get("direction", "")
	var distance = effect.get("distance", 1)
	var target_pos: Vector2i = target.get("grid_position", Vector2i(0, 0))
	var user_pos: Vector2i = user.get("grid_position", Vector2i(0, 0))
	var new_pos = target_pos

	# Check if target has braced status (negates forced movement)
	if status_manager.has_status(target.get("id", ""), "braced"):
		var braced_data = status_manager.get_status_data(target.get("id", ""), "braced")
		if braced_data.get("negates_forced_movement", false):
			_log_action("  %s resists forced movement (Braced)!" % target.get("name", "?"), Color(0.8, 0.8, 0.2))
			return

	match direction:
		"up":
			new_pos = Vector2i(target_pos.x, max(0, target_pos.y - distance))
		"down":
			new_pos = Vector2i(target_pos.x, min(GRID_SIZE.y - 1, target_pos.y + distance))
		"away":
			var dx = sign(target_pos.x - user_pos.x) if target_pos.x != user_pos.x else 1
			new_pos = Vector2i(clamp(target_pos.x + dx * distance, 0, GRID_SIZE.x - 1), target_pos.y)
		"toward_caster":
			var dx = sign(user_pos.x - target_pos.x) if target_pos.x != user_pos.x else 0
			var dy = sign(user_pos.y - target_pos.y) if target_pos.y != user_pos.y else 0
			new_pos = Vector2i(
				clamp(target_pos.x + dx * distance, 0, GRID_SIZE.x - 1),
				clamp(target_pos.y + dy * distance, 0, GRID_SIZE.y - 1)
			)

	if new_pos != target_pos and not grid.has(new_pos):
		grid.erase(target_pos)
		target["grid_position"] = new_pos
		grid[new_pos] = target.get("id", "")
		_log_action("  %s pushed to (%d,%d)!" % [target.get("name", "?"), new_pos.x, new_pos.y], Color(0.9, 0.7, 0.3))
		EventBus.position_changed.emit(target.get("id", ""), target_pos, new_pos)
		_update_unit_visuals()
	elif new_pos != target_pos:
		_log_action("  %s can't be moved (blocked)!" % target.get("name", "?"), Color(0.6, 0.6, 0.6))


## Handle self-repositioning after attack (e.g., Falcon Strike retreat)
func _apply_self_reposition(effect: Dictionary, user: Dictionary, target: Dictionary) -> void:
	var direction = effect.get("direction", "")
	var distance = effect.get("distance", 1)
	var user_pos: Vector2i = user.get("grid_position", Vector2i(0, 0))
	var target_pos: Vector2i = target.get("grid_position", Vector2i(0, 0))
	var new_pos = user_pos

	match direction:
		"away_from_target":
			var dx = sign(user_pos.x - target_pos.x) if user_pos.x != target_pos.x else -1
			new_pos = Vector2i(clamp(user_pos.x + dx * distance, 0, GRID_SIZE.x - 1), user_pos.y)

	if new_pos != user_pos and not grid.has(new_pos):
		grid.erase(user_pos)
		user["grid_position"] = new_pos
		grid[new_pos] = user.get("id", "")
		_log_action("  %s repositions to (%d,%d)" % [user.get("name", "?"), new_pos.x, new_pos.y], Color(0.7, 0.9, 0.7))
		EventBus.position_changed.emit(user.get("id", ""), user_pos, new_pos)
		_update_unit_visuals()


## Find which equipment grants a skill for a unit
func _get_skill_equipment(unit: Dictionary, skill_id: String) -> String:
	for equip_id in unit.get("equipment", []):
		var equip = equipment_data.get(equip_id, {})
		if skill_id in equip.get("granted_skills", []):
			return equip_id
	return ""


func _apply_damage(target: Dictionary, damage: int) -> void:
	target.current_hp = max(0, target.current_hp - damage)
	EventBus.unit_damaged.emit(target.id, damage, "physical")

	if target.current_hp <= 0:
		EventBus.unit_defeated.emit(target.id)
		_log_action("  %s defeated!" % target.get("name", "?"), Color(1.0, 0.3, 0.3))


func _end_turn() -> void:
	current_phase = CombatPhase.TURN_END
	_clear_turn_highlight()

	# Blood & Soil: record where this unit ended their turn
	var end_pos = current_unit.get("grid_position", Vector2i(0, 0))
	tile_env_manager.record_turn_end_position(current_unit.get("id", ""), end_pos)

	# Tick tile effect decay
	tile_env_manager.tick_decay()

	# Process DOT damage (data-driven - any status with damage_per_turn)
	var all_statuses = status_manager.get_statuses(current_unit.id)
	for status_info in all_statuses:
		var status_data = status_manager.get_status_data(current_unit.id, status_info.status)
		var dot_damage = status_data.get("damage_per_turn", 0)
		if dot_damage > 0:
			_apply_damage(current_unit, dot_damage)
			var dot_color = Color(1.0, 0.4, 0.1)  # Default orange
			match status_info.status:
				"poisoned": dot_color = Color(0.6, 0.2, 0.8)
				"bleeding": dot_color = Color(0.8, 0.1, 0.1)
			_spawn_floating_text(str(dot_damage), dot_color, current_unit, false)
			_log_action("  %s takes %d %s damage" % [current_unit.get("name", "?"), dot_damage, status_info.status], dot_color)

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
			tile_env_manager.clear_unit(uid)
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
	tile_env_manager.clear_all()
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
		HEX_SIZE
	)


func _on_skill_pressed() -> void:
	if current_phase != CombatPhase.SELECTING_ACTION:
		return

	action_panel.visible = false
	skill_panel.show_skills(current_unit, skills_data, all_units, grid, GRID_SIZE, _ap_system, equipment_data)


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
		HEX_SIZE
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

	# Deduct equipment charges if needed
	var charge_cost = selected_skill.get("equipment_charge_cost", 0)
	if charge_cost > 0:
		var equip_id = _get_skill_equipment(current_unit, selected_skill.get("id", ""))
		if equip_id != "":
			var charges = current_unit.get("equipment_charges", {})
			charges[equip_id] = max(0, charges.get(equip_id, 0) - charge_cost)
			_log_action("  -%d charge from %s (%d remaining)" % [charge_cost, equipment_data.get(equip_id, {}).get("name", equip_id), charges.get(equip_id, 0)], Color(0.8, 0.6, 0.2))

	# Consume taunt charge when player targets enemies
	if current_unit.get("is_ally", true):
		var target_type = PositionValidatorClass.get_targeting_type(selected_skill)
		if target_type in ["single_enemy", "all_enemies", "aoe_adjacent_enemies"]:
			status_manager.get_taunt_target(current_unit.get("id", ""))

	var tt = PositionValidatorClass.get_targeting_type(selected_skill)
	if tt == "all_allies":
		var targets = get_ally_units() if current_unit.get("is_ally", true) else get_enemy_units()
		await _execute_skill_on_all(selected_skill, current_unit, targets)
	elif tt == "all_enemies":
		var targets = get_enemy_units() if current_unit.get("is_ally", true) else get_ally_units()
		await _execute_skill_on_all(selected_skill, current_unit, targets)
	elif tt == "aoe_adjacent_enemies":
		# Find all enemies adjacent to the user
		var enemies = get_enemy_units() if current_unit.get("is_ally", true) else get_ally_units()
		var user_pos: Vector2i = current_unit.get("grid_position", Vector2i(0, 0))
		var adjacent_enemies: Array = []
		for enemy in enemies:
			var enemy_pos: Vector2i = enemy.get("grid_position", Vector2i(0, 0))
			if GridPathfinderClass.hex_distance(user_pos, enemy_pos) <= 1:
				adjacent_enemies.append(enemy)
		if adjacent_enemies.is_empty():
			adjacent_enemies = [target]  # Fallback to clicked target
		await _execute_skill_on_all(selected_skill, current_unit, adjacent_enemies)
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

	target_selector.start_move_targeting(current_unit, grid, GRID_SIZE, grid_node, HEX_SIZE)


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
