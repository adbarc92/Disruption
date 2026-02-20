extends CanvasLayer
class_name CombatResults
## CombatResults - Victory/Defeat overlay after combat ends

signal continue_pressed
signal retry_pressed
signal menu_pressed

var panel: Panel
var header_label: Label
var content_container: VBoxContainer


func show_victory(party_units: Array, xp_gained: int = 50) -> void:
	_build_ui()

	header_label.text = "Victory!"
	header_label.add_theme_color_override("font_color", Color(1.0, 0.85, 0.2))

	# XP gained
	var xp_label = Label.new()
	xp_label.text = "XP Gained: %d" % xp_gained
	xp_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	xp_label.add_theme_font_size_override("font_size", 18)
	xp_label.add_theme_color_override("font_color", Color(0.6, 0.8, 1.0))
	content_container.add_child(xp_label)

	# Spacer
	var spacer = Control.new()
	spacer.custom_minimum_size = Vector2(0, 10)
	content_container.add_child(spacer)

	# Party member rows
	for unit in party_units:
		var row = _create_party_row(unit)
		content_container.add_child(row)

	# Spacer before button
	var spacer2 = Control.new()
	spacer2.custom_minimum_size = Vector2(0, 16)
	content_container.add_child(spacer2)

	# Continue button
	var continue_btn = Button.new()
	continue_btn.text = "Continue"
	continue_btn.custom_minimum_size = Vector2(200, 40)
	continue_btn.pressed.connect(func(): continue_pressed.emit())
	content_container.add_child(continue_btn)

	# Center the button
	continue_btn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER


func show_defeat() -> void:
	_build_ui()

	header_label.text = "Defeat..."
	header_label.add_theme_color_override("font_color", Color(0.8, 0.2, 0.2))

	# Spacer
	var spacer = Control.new()
	spacer.custom_minimum_size = Vector2(0, 20)
	content_container.add_child(spacer)

	# Retry button
	var retry_btn = Button.new()
	retry_btn.text = "Retry"
	retry_btn.custom_minimum_size = Vector2(200, 40)
	retry_btn.pressed.connect(func(): retry_pressed.emit())
	content_container.add_child(retry_btn)
	retry_btn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER

	# Spacer
	var spacer2 = Control.new()
	spacer2.custom_minimum_size = Vector2(0, 8)
	content_container.add_child(spacer2)

	# Return to Menu button
	var menu_btn = Button.new()
	menu_btn.text = "Return to Menu"
	menu_btn.custom_minimum_size = Vector2(200, 40)
	menu_btn.pressed.connect(func(): menu_pressed.emit())
	content_container.add_child(menu_btn)
	menu_btn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER


func _build_ui() -> void:
	# Semi-transparent background
	var bg = ColorRect.new()
	bg.color = Color(0, 0, 0, 0.6)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg)

	# Center panel
	panel = Panel.new()
	panel.custom_minimum_size = Vector2(400, 320)
	panel.set_anchors_preset(Control.PRESET_CENTER)
	panel.position = Vector2(-200, -160)
	panel.size = Vector2(400, 320)
	add_child(panel)

	# Vertical layout inside panel
	content_container = VBoxContainer.new()
	content_container.set_anchors_preset(Control.PRESET_FULL_RECT)
	content_container.add_theme_constant_override("separation", 4)
	content_container.offset_left = 20
	content_container.offset_top = 16
	content_container.offset_right = -20
	content_container.offset_bottom = -16
	panel.add_child(content_container)

	# Header
	header_label = Label.new()
	header_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	header_label.add_theme_font_size_override("font_size", 28)
	content_container.add_child(header_label)


func _create_party_row(unit: Dictionary) -> HBoxContainer:
	var row = HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)

	# Name
	var name_label = Label.new()
	name_label.text = unit.get("name", "???")
	name_label.custom_minimum_size = Vector2(100, 0)
	name_label.add_theme_font_size_override("font_size", 14)
	row.add_child(name_label)

	# HP
	var hp_label = Label.new()
	hp_label.text = "HP: %d/%d" % [unit.get("current_hp", 0), unit.get("max_hp", 1)]
	hp_label.custom_minimum_size = Vector2(100, 0)
	hp_label.add_theme_font_size_override("font_size", 14)
	var hp_ratio = float(unit.get("current_hp", 0)) / float(max(unit.get("max_hp", 1), 1))
	if hp_ratio > 0.5:
		hp_label.add_theme_color_override("font_color", Color(0.3, 0.9, 0.3))
	elif hp_ratio > 0.25:
		hp_label.add_theme_color_override("font_color", Color(0.9, 0.9, 0.2))
	else:
		hp_label.add_theme_color_override("font_color", Color(0.9, 0.2, 0.2))
	row.add_child(hp_label)

	# MP
	var mp_label = Label.new()
	mp_label.text = "MP: %d/%d" % [unit.get("current_mp", 0), unit.get("max_mp", 1)]
	mp_label.custom_minimum_size = Vector2(80, 0)
	mp_label.add_theme_font_size_override("font_size", 14)
	mp_label.add_theme_color_override("font_color", Color(0.4, 0.6, 1.0))
	row.add_child(mp_label)

	return row
