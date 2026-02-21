extends Node
## CombatConfigurator - Debug UI for configuring combat before launch
## Allows setting grid size, ally starting positions, and encounter preset

const DataLoaderClass = preload("res://scripts/data/data_loader.gd")

const PARTY_NAMES = ["Cyrus", "Vaughn", "Phaidros"]

# --- State ---
var grid_cols: int = 7  # Default from combat_config.json
var grid_rows: int = 5  # Default from combat_config.json
var ally_positions: Dictionary = { 0: Vector2i(-1, -1), 1: Vector2i(-1, -1), 2: Vector2i(-1, -1) }
var selected_party_member: int = -1   # -1 = nothing held
var selected_encounter_index: int = 1  # default: Scout + Brute
var _encounters: Array = []

# UI element references (built at _ready)
var _grid_cell_buttons: Array[Button] = []
var _party_chip_buttons: Array[Button] = []
var _encounter_buttons: Array[Button] = []
var _encounter_desc_label: Label
var _grid_container: GridContainer
var _col_value_label: Label
var _row_value_label: Label


func _ready() -> void:
	# Load grid size from combat config
	const CombatConfigLoaderClass = preload("res://scripts/logic/combat/combat_config_loader.gd")
	CombatConfigLoaderClass.reload()
	var config_grid_size = CombatConfigLoaderClass.get_grid_size()
	grid_cols = config_grid_size.x
	grid_rows = config_grid_size.y

	_encounters = DataLoaderClass.load_encounters()
	_load_last_config()
	_build_ui()


func _build_ui() -> void:
	var root = Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(root)

	var margin = MarginContainer.new()
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 20)
	margin.add_theme_constant_override("margin_right", 20)
	margin.add_theme_constant_override("margin_top", 16)
	margin.add_theme_constant_override("margin_bottom", 16)
	root.add_child(margin)

	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 12)
	margin.add_child(vbox)

	# Title
	var title = Label.new()
	title.text = "Combat Configurator"
	title.add_theme_font_size_override("font_size", 28)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(title)

	vbox.add_child(HSeparator.new())

	# Quick Presets Section
	_build_quick_presets(vbox)

	vbox.add_child(HSeparator.new())

	# Three-panel row
	var hbox = HBoxContainer.new()
	hbox.size_flags_vertical = Control.SIZE_EXPAND_FILL
	hbox.add_theme_constant_override("separation", 24)
	vbox.add_child(hbox)

	_build_grid_size_panel(hbox)
	_build_ally_position_panel(hbox)
	_build_encounter_panel(hbox)

	vbox.add_child(HSeparator.new())

	# Button row
	var btn_row = HBoxContainer.new()
	btn_row.alignment = BoxContainer.ALIGNMENT_CENTER
	btn_row.add_theme_constant_override("separation", 20)
	vbox.add_child(btn_row)

	var back_btn = Button.new()
	back_btn.text = "Back"
	back_btn.custom_minimum_size = Vector2(120, 40)
	back_btn.pressed.connect(_on_back_pressed)
	btn_row.add_child(back_btn)

	var start_btn = Button.new()
	start_btn.text = "Start Combat"
	start_btn.custom_minimum_size = Vector2(160, 40)
	start_btn.pressed.connect(_on_start_pressed)
	btn_row.add_child(start_btn)


# --- Section 1: Grid Size ---

func _build_grid_size_panel(parent: Control) -> void:
	var panel = VBoxContainer.new()
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	panel.add_theme_constant_override("separation", 10)
	parent.add_child(panel)

	var header = Label.new()
	header.text = "Grid Size"
	header.add_theme_font_size_override("font_size", 18)
	header.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	panel.add_child(header)

	panel.add_child(HSeparator.new())

	# Columns stepper
	var col_row = HBoxContainer.new()
	col_row.alignment = BoxContainer.ALIGNMENT_CENTER
	col_row.add_theme_constant_override("separation", 6)
	panel.add_child(col_row)

	var col_label = Label.new()
	col_label.text = "Columns:"
	col_row.add_child(col_label)

	var col_minus = Button.new()
	col_minus.text = "-"
	col_minus.custom_minimum_size = Vector2(32, 32)
	col_minus.pressed.connect(func(): _change_cols(-1))
	col_row.add_child(col_minus)

	_col_value_label = Label.new()
	_col_value_label.text = str(grid_cols)
	_col_value_label.custom_minimum_size = Vector2(32, 0)
	_col_value_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	col_row.add_child(_col_value_label)

	var col_plus = Button.new()
	col_plus.text = "+"
	col_plus.custom_minimum_size = Vector2(32, 32)
	col_plus.pressed.connect(func(): _change_cols(1))
	col_row.add_child(col_plus)

	# Rows stepper
	var row_row = HBoxContainer.new()
	row_row.alignment = BoxContainer.ALIGNMENT_CENTER
	row_row.add_theme_constant_override("separation", 6)
	panel.add_child(row_row)

	var row_label = Label.new()
	row_label.text = "Rows:    "
	row_row.add_child(row_label)

	var row_minus = Button.new()
	row_minus.text = "-"
	row_minus.custom_minimum_size = Vector2(32, 32)
	row_minus.pressed.connect(func(): _change_rows(-1))
	row_row.add_child(row_minus)

	_row_value_label = Label.new()
	_row_value_label.text = str(grid_rows)
	_row_value_label.custom_minimum_size = Vector2(32, 0)
	_row_value_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	row_row.add_child(_row_value_label)

	var row_plus = Button.new()
	row_plus.text = "+"
	row_plus.custom_minimum_size = Vector2(32, 32)
	row_plus.pressed.connect(func(): _change_rows(1))
	row_row.add_child(row_plus)


func _change_cols(delta: int) -> void:
	grid_cols = clamp(grid_cols + delta, 1, 10)  # Allow up to 10 columns
	_col_value_label.text = str(grid_cols)
	_evict_out_of_bounds()
	_grid_container.columns = grid_cols
	_rebuild_ally_grid()
	_update_chip_colors()


func _change_rows(delta: int) -> void:
	grid_rows = clamp(grid_rows + delta, 1, 10)  # Allow up to 10 rows
	_row_value_label.text = str(grid_rows)
	_evict_out_of_bounds()
	_rebuild_ally_grid()
	_update_chip_colors()


func _evict_out_of_bounds() -> void:
	for member_idx in ally_positions.keys():
		var pos: Vector2i = ally_positions[member_idx]
		if pos.x >= grid_cols or pos.y >= grid_rows:
			ally_positions[member_idx] = Vector2i(-1, -1)


# --- Section 2: Ally Starting Positions ---

func _build_ally_position_panel(parent: Control) -> void:
	var panel = VBoxContainer.new()
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	panel.add_theme_constant_override("separation", 10)
	parent.add_child(panel)

	var header = Label.new()
	header.text = "Ally Starting Positions"
	header.add_theme_font_size_override("font_size", 18)
	header.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	panel.add_child(header)

	panel.add_child(HSeparator.new())

	# Party chips
	var chips_row = HBoxContainer.new()
	chips_row.alignment = BoxContainer.ALIGNMENT_CENTER
	chips_row.add_theme_constant_override("separation", 8)
	panel.add_child(chips_row)

	_party_chip_buttons.clear()
	for i in range(PARTY_NAMES.size()):
		var chip = Button.new()
		chip.text = PARTY_NAMES[i]
		chip.custom_minimum_size = Vector2(80, 36)
		var idx = i
		chip.pressed.connect(func(): _on_party_chip_pressed(idx))
		chips_row.add_child(chip)
		_party_chip_buttons.append(chip)

	# Grid
	_grid_container = GridContainer.new()
	_grid_container.columns = grid_cols
	panel.add_child(_grid_container)

	_rebuild_ally_grid()

	# Reset button
	var reset_btn = Button.new()
	reset_btn.text = "Reset to Defaults"
	reset_btn.pressed.connect(_reset_ally_positions)
	panel.add_child(reset_btn)

	_update_chip_colors()


func _rebuild_ally_grid() -> void:
	for child in _grid_container.get_children():
		child.queue_free()
	_grid_cell_buttons.clear()

	for row in range(grid_rows):
		for col in range(grid_cols):
			var cell_btn = Button.new()
			cell_btn.custom_minimum_size = Vector2(70, 50)
			var cell_pos = Vector2i(col, row)
			cell_btn.pressed.connect(func(): _on_grid_cell_pressed(cell_pos))
			_grid_container.add_child(cell_btn)
			_grid_cell_buttons.append(cell_btn)

	_update_grid_colors()


func _on_grid_cell_pressed(cell_pos: Vector2i) -> void:
	var occupant_idx = _find_occupant(cell_pos)

	if occupant_idx >= 0:
		# Pick up occupant
		selected_party_member = occupant_idx
		ally_positions[occupant_idx] = Vector2i(-1, -1)
	elif selected_party_member >= 0:
		# Place held member here
		ally_positions[selected_party_member] = cell_pos
		selected_party_member = -1
	# else: no member held and cell empty — do nothing

	_update_grid_colors()
	_update_chip_colors()


func _find_occupant(cell_pos: Vector2i) -> int:
	for member_idx in ally_positions.keys():
		if ally_positions[member_idx] == cell_pos:
			return member_idx
	return -1


func _update_grid_colors() -> void:
	var btn_idx = 0
	for row in range(grid_rows):
		for col in range(grid_cols):
			if btn_idx >= _grid_cell_buttons.size():
				break
			var cell_pos = Vector2i(col, row)
			var occupant = _find_occupant(cell_pos)
			var btn = _grid_cell_buttons[btn_idx]
			if occupant >= 0:
				btn.text = PARTY_NAMES[occupant].substr(0, 3)
				btn.add_theme_color_override("font_color", Color.GREEN)
			else:
				btn.text = ""
				btn.remove_theme_color_override("font_color")
			btn_idx += 1


func _on_party_chip_pressed(idx: int) -> void:
	if selected_party_member == idx:
		selected_party_member = -1
	else:
		selected_party_member = idx
	_update_chip_colors()


func _update_chip_colors() -> void:
	for i in range(_party_chip_buttons.size()):
		var chip = _party_chip_buttons[i]
		if i == selected_party_member:
			chip.add_theme_color_override("font_color", Color.YELLOW)
		elif ally_positions[i] != Vector2i(-1, -1):
			chip.add_theme_color_override("font_color", Color(0.6, 0.6, 0.6))
		else:
			chip.remove_theme_color_override("font_color")


func _reset_ally_positions() -> void:
	selected_party_member = -1
	ally_positions = { 0: Vector2i(-1, -1), 1: Vector2i(-1, -1), 2: Vector2i(-1, -1) }
	_update_grid_colors()
	_update_chip_colors()


# --- Section 3: Encounter Selection ---

func _build_encounter_panel(parent: Control) -> void:
	var panel = VBoxContainer.new()
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	panel.add_theme_constant_override("separation", 8)
	parent.add_child(panel)

	var header = Label.new()
	header.text = "Encounter"
	header.add_theme_font_size_override("font_size", 18)
	header.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	panel.add_child(header)

	panel.add_child(HSeparator.new())

	_encounter_buttons.clear()
	for i in range(_encounters.size()):
		var enc = _encounters[i]
		var btn = Button.new()
		btn.text = enc.get("name", "Encounter %d" % i)
		btn.custom_minimum_size = Vector2(0, 32)
		var idx = i
		btn.pressed.connect(func(): _on_encounter_selected(idx))
		panel.add_child(btn)
		_encounter_buttons.append(btn)

	panel.add_child(HSeparator.new())

	_encounter_desc_label = Label.new()
	_encounter_desc_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_encounter_desc_label.custom_minimum_size = Vector2(0, 60)
	panel.add_child(_encounter_desc_label)

	_update_encounter_ui()


func _on_encounter_selected(idx: int) -> void:
	selected_encounter_index = idx
	_update_encounter_ui()


func _update_encounter_ui() -> void:
	for i in range(_encounter_buttons.size()):
		var btn = _encounter_buttons[i]
		if i == selected_encounter_index:
			btn.add_theme_color_override("font_color", Color.YELLOW)
		else:
			btn.remove_theme_color_override("font_color")

	if selected_encounter_index >= 0 and selected_encounter_index < _encounters.size():
		var enc = _encounters[selected_encounter_index]
		_encounter_desc_label.text = enc.get("description", "")
	else:
		_encounter_desc_label.text = ""


# --- Navigation ---

func _on_back_pressed() -> void:
	var return_scene = GameManager.story_flags.get("_combat_return_scene", "res://scenes/main.tscn")
	GameManager.transition_to_scene(return_scene)


func _on_start_pressed() -> void:
	# Resolve enemies from selected encounter
	var enemies_by_id = DataLoaderClass.load_enemies()
	var resolved_enemies: Array = []

	if selected_encounter_index >= 0 and selected_encounter_index < _encounters.size():
		var enc = _encounters[selected_encounter_index]
		for enemy_id in enc.get("enemy_ids", []):
			var enemy = enemies_by_id.get(enemy_id, {})
			if not enemy.is_empty():
				resolved_enemies.append(enemy)

	# Write grid config to story_flags
	GameManager.story_flags["_combat_config_grid_cols"] = grid_cols
	GameManager.story_flags["_combat_config_grid_rows"] = grid_rows

	# Serialize positions as string-keyed dict with dict values (JSON-safe)
	var pos_config: Dictionary = {}
	for member_idx in ally_positions.keys():
		var pos: Vector2i = ally_positions[member_idx]
		pos_config[str(member_idx)] = {"x": pos.x, "y": pos.y}
	GameManager.story_flags["_combat_config_ally_positions"] = pos_config

	# Save current config as "last"
	_save_last_config()

	var return_scene = GameManager.story_flags.get("_combat_return_scene", "res://scenes/main.tscn")
	GameManager.start_combat(resolved_enemies, return_scene)


# --- Quick Presets ---

func _build_quick_presets(parent: Control) -> void:
	var panel = VBoxContainer.new()
	panel.add_theme_constant_override("separation", 8)
	parent.add_child(panel)

	var header = Label.new()
	header.text = "⚡ Quick Launch Presets"
	header.add_theme_font_size_override("font_size", 16)
	header.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	panel.add_child(header)

	var buttons_row = HBoxContainer.new()
	buttons_row.alignment = BoxContainer.ALIGNMENT_CENTER
	buttons_row.add_theme_constant_override("separation", 12)
	panel.add_child(buttons_row)

	# Preset buttons
	var presets = [
		{"name": "Default 3v3", "method": "_preset_default_3v3"},
		{"name": "Speed Test", "method": "_preset_speed_test"},
		{"name": "Tank Test", "method": "_preset_tank_test"},
		{"name": "Last Config", "method": "_preset_last_config"},
	]

	for preset in presets:
		var btn = Button.new()
		btn.text = preset.name
		btn.custom_minimum_size = Vector2(140, 36)
		var method = preset.method
		btn.pressed.connect(Callable(self, method))
		buttons_row.add_child(btn)


func _preset_default_3v3() -> void:
	# Reset to config defaults
	const CombatConfigLoaderClass = preload("res://scripts/logic/combat/combat_config_loader.gd")
	var config_grid_size = CombatConfigLoaderClass.get_grid_size()
	grid_cols = config_grid_size.x
	grid_rows = config_grid_size.y

	# Position allies on left side (7x5 grid: allies on left, enemies on right)
	ally_positions = {
		0: Vector2i(1, 2),  # Cyrus - left zone, center
		1: Vector2i(1, 1),  # Vaughn - left zone, top
		2: Vector2i(0, 3),  # Phaidros - far left, lower
	}
	selected_encounter_index = 3  # Full Squad (3v3)
	_apply_preset_and_launch()


func _preset_speed_test() -> void:
	const CombatConfigLoaderClass = preload("res://scripts/logic/combat/combat_config_loader.gd")
	var config_grid_size = CombatConfigLoaderClass.get_grid_size()
	grid_cols = config_grid_size.x
	grid_rows = config_grid_size.y

	ally_positions = {
		0: Vector2i(1, 2),  # Cyrus - left center
		1: Vector2i(0, 1),  # Vaughn - far left top (fastest)
		2: Vector2i(1, 3),  # Phaidros - left lower
	}
	selected_encounter_index = 0  # Two Scouts (fast enemies)
	_apply_preset_and_launch()


func _preset_tank_test() -> void:
	const CombatConfigLoaderClass = preload("res://scripts/logic/combat/combat_config_loader.gd")
	var config_grid_size = CombatConfigLoaderClass.get_grid_size()
	grid_cols = config_grid_size.x
	grid_rows = config_grid_size.y

	ally_positions = {
		0: Vector2i(1, 2),  # Cyrus - left center
		1: Vector2i(1, 1),  # Vaughn - left top
		2: Vector2i(0, 2),  # Phaidros - front line (tank position)
	}
	selected_encounter_index = 4  # Twin Brutes (high HP)
	_apply_preset_and_launch()


func _preset_last_config() -> void:
	_load_last_config()
	_apply_preset_and_launch()


func _apply_preset_and_launch() -> void:
	# Update UI to reflect preset
	_col_value_label.text = str(grid_cols)
	_row_value_label.text = str(grid_rows)
	_grid_container.columns = grid_cols
	_rebuild_ally_grid()
	_update_chip_colors()
	_update_encounter_ui()

	# Small delay for visual feedback, then launch
	await get_tree().create_timer(0.2).timeout
	_on_start_pressed()


func _save_last_config() -> void:
	GameManager.story_flags["_configurator_last_grid_cols"] = grid_cols
	GameManager.story_flags["_configurator_last_grid_rows"] = grid_rows
	GameManager.story_flags["_configurator_last_ally_positions"] = ally_positions.duplicate()
	GameManager.story_flags["_configurator_last_encounter"] = selected_encounter_index


func _load_last_config() -> void:
	if GameManager.story_flags.has("_configurator_last_grid_cols"):
		grid_cols = GameManager.story_flags.get("_configurator_last_grid_cols", 3)
		grid_rows = GameManager.story_flags.get("_configurator_last_grid_rows", 3)
		ally_positions = GameManager.story_flags.get("_configurator_last_ally_positions", {
			0: Vector2i(-1, -1), 1: Vector2i(-1, -1), 2: Vector2i(-1, -1)
		}).duplicate()
		selected_encounter_index = GameManager.story_flags.get("_configurator_last_encounter", 1)
