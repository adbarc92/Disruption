extends Panel
class_name SkillPanel
## SkillPanel - Skill selection UI for combat
## Lists available skills with MP costs, shows range info

const PositionValidatorClass = preload("res://scripts/logic/combat/position_validator.gd")

signal skill_selected(skill_id: String)
signal cancelled()

@onready var skill_list: VBoxContainer = $VBoxContainer/SkillList
@onready var description_label: Label = $VBoxContainer/DescriptionLabel
@onready var cancel_button: Button = $VBoxContainer/CancelButton

var current_unit: Dictionary = {}
var skills_data: Dictionary = {}
var skill_buttons: Array[Button] = []

# Unified grid references for can_use_skill checks
var _all_units: Dictionary = {}
var _grid: Dictionary = {}
var _grid_size: Vector2i = Vector2i(10, 6)
var _ap_system = null  # APSystem reference for cost checks


func _ready() -> void:
	cancel_button.pressed.connect(_on_cancel_pressed)
	visible = false


## Show skills for a unit (unified grid version)
func show_skills(unit: Dictionary, all_skills: Dictionary, all_units: Dictionary = {}, grid: Dictionary = {}, grid_size: Vector2i = Vector2i(10, 6), ap_system = null) -> void:
	current_unit = unit
	skills_data = all_skills
	_all_units = all_units
	_grid = grid
	_grid_size = grid_size
	_ap_system = ap_system

	_populate_skill_list()
	visible = true


## Hide the panel
func hide_panel() -> void:
	visible = false
	_clear_skill_list()


func _populate_skill_list() -> void:
	_clear_skill_list()

	var abilities = current_unit.get("abilities", [])
	var current_mp = current_unit.get("current_mp", 0)

	for ability_id in abilities:
		# Skip basic attack (handled by Attack button)
		if ability_id == "basic_attack":
			continue

		var skill = skills_data.get(ability_id, {})
		if skill.is_empty():
			continue

		var button = Button.new()
		button.name = ability_id

		# Build button text
		var skill_name = skill.get("name", ability_id)
		var mp_cost = skill.get("mp_cost", 0)
		var action_type = skill.get("action_type", "action")

		# Get AP cost for this skill
		var ap_cost = 2  # default for standard skill
		if _ap_system != null:
			ap_cost = _ap_system.get_skill_cost(skill)

		var action_tag = ""
		if action_type == "bonus_action":
			action_tag = " [B]"

		button.text = "%s%s - %d AP, %d MP" % [skill_name, action_tag, ap_cost, mp_cost]
		button.custom_minimum_size = Vector2(280, 35)

		# Check if usable
		var can_use = true
		var disable_reason = ""

		# Check AP affordability
		if _ap_system != null and not _ap_system.can_afford_amount(current_unit.get("id", ""), ap_cost):
			can_use = false
			disable_reason = "Not enough AP (%d needed)" % ap_cost
		elif current_mp < mp_cost:
			can_use = false
			disable_reason = "Not enough MP"
		elif not _all_units.is_empty() and not PositionValidatorClass.can_use_skill(skill, current_unit, _all_units, _grid, _grid_size):
			can_use = false
			disable_reason = "No valid targets in range"

		button.disabled = not can_use

		if not can_use:
			button.tooltip_text = disable_reason
			button.modulate = Color(0.5, 0.5, 0.5, 1.0)

		# Connect signals
		button.pressed.connect(_on_skill_button_pressed.bind(ability_id))
		button.mouse_entered.connect(_on_skill_hover.bind(ability_id))

		skill_list.add_child(button)
		skill_buttons.append(button)


func _clear_skill_list() -> void:
	for button in skill_buttons:
		button.queue_free()
	skill_buttons.clear()
	description_label.text = ""


func _on_skill_button_pressed(skill_id: String) -> void:
	skill_selected.emit(skill_id)
	hide_panel()


func _on_skill_hover(skill_id: String) -> void:
	var skill = skills_data.get(skill_id, {})
	var description = skill.get("description", "No description")

	var extra_info = ""

	# Add targeting info
	var targeting = skill.get("targeting", {})
	var target_type = targeting.get("type", "single_enemy")
	extra_info += "\nTarget: %s" % _format_target_type(target_type)

	# Add range info
	var range_type = skill.get("range_type", "melee")
	var skill_range = PositionValidatorClass.get_skill_range(skill)
	extra_info += "\nRange: %s" % _format_range(range_type, skill_range)

	# Add damage info if applicable
	if skill.has("damage"):
		var damage = skill.damage
		var damage_type = "%s/%s" % [damage.get("type", ""), damage.get("subtype", "")]
		extra_info += "\nDamage: %s" % damage_type

	# Add effect info if applicable
	if skill.has("effect"):
		var effect = skill.effect
		var status = effect.get("status", "")
		var duration = effect.get("duration", 0)
		if status != "":
			extra_info += "\nEffect: %s (%d turns)" % [status, duration]

	description_label.text = description + extra_info


func _on_cancel_pressed() -> void:
	cancelled.emit()
	hide_panel()


func _format_target_type(target_type: String) -> String:
	match target_type:
		"single_enemy":
			return "Single Enemy"
		"all_enemies":
			return "All Enemies"
		"single_ally":
			return "Single Ally"
		"all_allies":
			return "All Allies"
		"self":
			return "Self"
		_:
			return target_type.capitalize()


func _format_range(range_type: String, skill_range: int) -> String:
	match range_type:
		"melee":
			return "Melee (adjacent)"
		"self":
			return "Self"
		"all_allies", "all_enemies":
			return "All"
		"ranged":
			if skill_range == 0:
				return "Unlimited"
			else:
				return "%d cells" % skill_range
		_:
			if skill_range == 0:
				return "Unlimited"
			else:
				return "%d cells" % skill_range
