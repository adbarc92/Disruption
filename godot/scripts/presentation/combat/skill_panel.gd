extends Panel
class_name SkillPanel
## SkillPanel - Skill selection UI for combat
## Lists available skills with MP costs, disables unusable skills

const PositionValidatorClass = preload("res://scripts/logic/combat/position_validator.gd")

signal skill_selected(skill_id: String)
signal cancelled()

@onready var skill_list: VBoxContainer = $VBoxContainer/SkillList
@onready var description_label: Label = $VBoxContainer/DescriptionLabel
@onready var cancel_button: Button = $VBoxContainer/CancelButton

var current_unit: Dictionary = {}
var skills_data: Dictionary = {}
var skill_buttons: Array[Button] = []


func _ready() -> void:
	cancel_button.pressed.connect(_on_cancel_pressed)
	visible = false


## Show skills for a unit
func show_skills(unit: Dictionary, all_skills: Dictionary) -> void:
	current_unit = unit
	skills_data = all_skills

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
	var position = current_unit.get("grid_position", Vector2i(0, 0))

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

		var action_tag = ""
		if action_type == "bonus_action":
			action_tag = " [B]"

		button.text = "%s%s - %d MP" % [skill_name, action_tag, mp_cost]
		button.custom_minimum_size = Vector2(280, 35)

		# Check if usable
		var can_use = true
		var disable_reason = ""

		if current_mp < mp_cost:
			can_use = false
			disable_reason = "Not enough MP"
		elif not PositionValidatorClass.can_use_skill_from_position(skill, position):
			can_use = false
			var usable_positions = skill.get("usable_positions", [])
			disable_reason = "Requires: %s" % ", ".join(usable_positions)

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

	# Add position requirements
	var usable_positions = skill.get("usable_positions", ["any"])
	if "any" not in usable_positions:
		extra_info += "\nUse from: %s" % ", ".join(usable_positions)

	var target_positions = skill.get("target_positions", ["any"])
	if "any" not in target_positions:
		extra_info += "\nTargets: %s row" % ", ".join(target_positions)

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
