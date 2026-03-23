class_name DialoguePlayer
extends Control
## Presentation layer for dialogues. Receives state from DialogueStateMachine
## and renders portraits, dialog box, and choices.

signal dialogue_completed(dialogue_id: String)

const TYPEWRITER_SPEED := 30.0  # characters per second

var _state_machine: DialogueStateMachine
var _dialogue_id: String = ""
var _is_typing: bool = false
var _full_text: String = ""
var _visible_chars: float = 0.0
var _selected_choice: int = 0
var _showing_choices: bool = false

# Portrait textures keyed by character ID
var portrait_map: Dictionary = {
	"cyrus": "res://assets/portraits/cyrus.png",
	"vaughn": "res://assets/portraits/vaughn.png",
	"phaidros": "res://assets/portraits/phaidros.png",
}

# Node references (set in _ready via scene tree)
@onready var background: ColorRect = $Background
@onready var speaker_slot: TextureRect = $PortraitSlots/SpeakerSlot
@onready var speaker_label: Label = $PortraitSlots/SpeakerLabel
@onready var listener_slot: TextureRect = $PortraitSlots/ListenerSlot
@onready var listener_label: Label = $PortraitSlots/ListenerLabel
@onready var observer_container: HBoxContainer = $PortraitSlots/ObserverContainer
@onready var dialog_box: PanelContainer = $DialogBox
@onready var speaker_name: Label = $DialogBox/MarginContainer/VBoxContainer/SpeakerName
@onready var dialog_text: RichTextLabel = $DialogBox/MarginContainer/VBoxContainer/DialogText
@onready var continue_indicator: Label = $DialogBox/MarginContainer/VBoxContainer/ContinueIndicator
@onready var choice_container: VBoxContainer = $DialogBox/MarginContainer/VBoxContainer/ChoiceContainer


func _ready() -> void:
	choice_container.visible = false
	continue_indicator.visible = false


func start_dialogue(dialogue_data: Dictionary) -> void:
	_dialogue_id = dialogue_data.get("id", "")
	_state_machine = DialogueStateMachine.new()
	_state_machine.load_dialogue(
		dialogue_data,
		func(flag_name): return GameManager.get_story_flag(flag_name),
		func(consequence_name): return GameManager.get_consequence(consequence_name),
	)

	GameManager.change_state(GameManager.GameState.DIALOG)
	EventBus.dialog_started.emit(_dialogue_id)

	var state = _state_machine.start()
	_display_state(state)


func _process(delta: float) -> void:
	if _is_typing:
		_visible_chars += TYPEWRITER_SPEED * delta
		var char_count = int(_visible_chars)
		if char_count >= _full_text.length():
			dialog_text.text = _full_text
			_is_typing = false
			_on_typing_complete()
		else:
			dialog_text.text = _full_text.substr(0, char_count)


func _unhandled_input(event: InputEvent) -> void:
	if not _state_machine:
		return

	if event.is_action_pressed("confirm"):
		_handle_confirm()
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("cancel"):
		_handle_cancel()
		get_viewport().set_input_as_handled()
	elif _showing_choices:
		if event.is_action_pressed("move_up"):
			_navigate_choices(-1)
			get_viewport().set_input_as_handled()
		elif event.is_action_pressed("move_down"):
			_navigate_choices(1)
			get_viewport().set_input_as_handled()


func _handle_confirm() -> void:
	if _is_typing:
		# Skip typewriter — show full text
		_is_typing = false
		dialog_text.text = _full_text
		_on_typing_complete()
		return

	if _showing_choices:
		_select_choice(_selected_choice)
		return

	if _state_machine.is_complete():
		_end_dialogue()
		return

	var state = _state_machine.advance()
	_display_state(state)


func _handle_cancel() -> void:
	if _is_typing:
		_is_typing = false
		dialog_text.text = _full_text
		_on_typing_complete()


func _display_state(state: Dictionary) -> void:
	# Apply pending effects
	var effects = state.get("pending_effects", {})
	for flag_name in effects.get("flags", {}):
		GameManager.set_story_flag(flag_name, effects.flags[flag_name])
	for consequence_name in effects.get("consequences", {}):
		GameManager.modify_consequence(consequence_name, effects.consequences[consequence_name])

	# Handle perspective shift
	if state.get("perspective_shifted", false):
		print("Perspective shifted to: ", state.get("perspective", ""))

	# Update portraits
	_update_portraits(state)

	# Update speaker name
	var speaker_id = state.get("speaker", "")
	speaker_name.text = speaker_id.to_upper()

	# Start typewriter
	_full_text = state.get("text", "")
	_visible_chars = 0.0
	dialog_text.text = ""
	_is_typing = true
	_showing_choices = false
	choice_container.visible = false
	continue_indicator.visible = false

	EventBus.dialog_line_displayed.emit(speaker_id, _full_text)


func _on_typing_complete() -> void:
	var state = _state_machine.get_current_state()
	var choices = state.get("choices", [])

	if not choices.is_empty():
		_show_choices(choices)
	elif _state_machine.is_complete():
		continue_indicator.text = "■"
		continue_indicator.visible = true
	else:
		continue_indicator.text = "▼"
		continue_indicator.visible = true


func _update_portraits(state: Dictionary) -> void:
	var speaker_id = state.get("speaker", "")
	var listener_id = state.get("listener", "")
	var participants = state.get("participants", [])

	# Speaker portrait (bottom-left) — highlighted
	_set_portrait(speaker_slot, speaker_id, true)
	speaker_label.text = speaker_id.to_upper()
	speaker_label.visible = not speaker_id.is_empty()

	# Listener portrait (top-right)
	if listener_id.is_empty():
		listener_slot.visible = false
		listener_label.visible = false
	else:
		listener_slot.visible = true
		_set_portrait(listener_slot, listener_id, false)
		listener_label.text = listener_id.to_upper()
		listener_label.visible = true

	# Observers (top-left)
	for child in observer_container.get_children():
		child.queue_free()

	for p in participants:
		if p != speaker_id and p != listener_id:
			var obs_portrait = TextureRect.new()
			obs_portrait.custom_minimum_size = Vector2(80, 100)
			obs_portrait.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
			obs_portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			obs_portrait.modulate = Color(0.5, 0.5, 0.5, 0.7)
			if portrait_map.has(p):
				obs_portrait.texture = load(portrait_map[p])
			observer_container.add_child(obs_portrait)


func _set_portrait(slot: TextureRect, character_id: String, is_active: bool) -> void:
	if portrait_map.has(character_id):
		slot.texture = load(portrait_map[character_id])
		slot.visible = true
	else:
		slot.visible = false
		return

	if is_active:
		slot.modulate = Color(1.0, 1.0, 1.0, 1.0)
	else:
		slot.modulate = Color(0.6, 0.6, 0.6, 0.8)


func _show_choices(choices: Array) -> void:
	_showing_choices = true
	_selected_choice = 0
	choice_container.visible = true
	continue_indicator.visible = false

	# Clear old choice buttons
	for child in choice_container.get_children():
		child.queue_free()

	# Create choice buttons
	for i in choices.size():
		var choice = choices[i]
		var button = Button.new()
		var text = "%d. %s" % [i + 1, choice.get("text", "")]
		if choice.has("hint"):
			text += "  [%s]" % choice.hint
		button.text = text
		button.alignment = HORIZONTAL_ALIGNMENT_LEFT
		button.pressed.connect(_select_choice.bind(i))
		choice_container.add_child(button)

	# Highlight first choice
	_update_choice_highlight()


func _navigate_choices(direction: int) -> void:
	var count = choice_container.get_child_count()
	if count == 0:
		return
	_selected_choice = wrapi(_selected_choice + direction, 0, count)
	_update_choice_highlight()


func _update_choice_highlight() -> void:
	for i in choice_container.get_child_count():
		var button = choice_container.get_child(i) as Button
		if button:
			# Use focus to indicate selection
			if i == _selected_choice:
				button.grab_focus()


func _select_choice(index: int) -> void:
	var choices = _state_machine.get_current_state().get("choices", [])
	if index >= 0 and index < choices.size():
		EventBus.dialog_choice_made.emit(index, choices[index].get("text", ""))

	var state = _state_machine.choose(index)
	_display_state(state)


func _end_dialogue() -> void:
	EventBus.dialog_ended.emit(_dialogue_id)
	dialogue_completed.emit(_dialogue_id)
