# Dialogue System Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build a prototype dialogue system with branching conversations, spatial portrait layout, and story flag/consequence integration.

**Architecture:** JSON dialogue trees loaded via DataLoader, traversed by a pure `DialogueStateMachine` (no Godot deps), and rendered by a `DialoguePlayer` Godot scene with speaker/listener/observer portrait slots and a typewriter dialog box.

**Tech Stack:** Godot 4, GDScript, JSON data files

**Spec:** `docs/superpowers/specs/2026-03-23-dialogue-system-design.md`

---

## File Structure

| Action | Path | Responsibility |
|--------|------|----------------|
| Create | `godot/data/dialogue/test_dialogue.json` | Sample dialogue tree with branching, perspective shift, conditions, effects |
| Modify | `godot/scripts/data/data_loader.gd` | Add `load_dialogue()` static method |
| Create | `godot/scripts/logic/dialogue/dialogue_state_machine.gd` | Pure dialogue traversal logic |
| Create | `godot/scenes/dialogue/dialogue_player.tscn` | Dialogue scene with portrait slots and dialog box |
| Create | `godot/scripts/presentation/dialogue/dialogue_player.gd` | Scene controller for DialoguePlayer |
| Create | `godot/scenes/dialogue/test_dialogue.tscn` | Test harness scene launched from main menu |
| Create | `godot/scripts/presentation/dialogue/test_dialogue.gd` | Test harness script |
| Modify | `godot/scenes/main.tscn` | Add "Test Dialogue" button |
| Modify | `godot/scripts/main.gd` | Connect Test Dialogue button |

---

### Task 1: Sample Dialogue JSON

**Files:**
- Create: `godot/data/dialogue/test_dialogue.json`

- [ ] **Step 1: Create the dialogue data directory**

Run: `mkdir -p godot/data/dialogue`

- [ ] **Step 2: Write the sample dialogue JSON**

Create `godot/data/dialogue/test_dialogue.json`:

```json
{
  "id": "test_dialogue",
  "initial_node": "start",
  "initial_perspective": "cyrus",
  "participants": ["cyrus", "vaughn", "phaidros"],
  "nodes": {
    "start": {
      "speaker": "cyrus",
      "listener": "vaughn",
      "text": "We need to move carefully through here. I can sense something is wrong — the air feels heavy, charged.",
      "next": "vaughn_responds"
    },
    "vaughn_responds": {
      "speaker": "vaughn",
      "listener": "cyrus",
      "text": "What's the plan? We can't stay here forever.",
      "choices": [
        {
          "text": "Push forward — we can handle whatever's ahead.",
          "next": "push_forward"
        },
        {
          "text": "Vaughn, scout ahead first.",
          "next": "scout_ahead"
        },
        {
          "text": "Phaidros, what do you think?",
          "hint": "Builds trust",
          "next": "ask_phaidros",
          "effects": {
            "flags": { "trusted_phaidros": true },
            "consequences": { "phaidros_trust": 5 }
          }
        }
      ]
    },
    "push_forward": {
      "speaker": "cyrus",
      "listener": "vaughn",
      "text": "We push forward. Stay close and keep your guard up.",
      "next": "vaughn_acknowledges"
    },
    "vaughn_acknowledges": {
      "speaker": "vaughn",
      "listener": "cyrus",
      "text": "Understood. I'll watch the flanks."
    },
    "scout_ahead": {
      "speaker": "vaughn",
      "listener": "cyrus",
      "text": "On it. Give me a minute.",
      "next": "vaughn_returns"
    },
    "vaughn_returns": {
      "speaker": "vaughn",
      "listener": "cyrus",
      "text": "Path ahead is clear, but the ground is unstable. We should move quickly."
    },
    "ask_phaidros": {
      "perspective_shift": "phaidros",
      "speaker": "phaidros",
      "listener": "vaughn",
      "text": "The ground here is unstable. We should find higher terrain before pressing on.",
      "next": "phaidros_continues"
    },
    "phaidros_continues": {
      "speaker": "phaidros",
      "listener": "cyrus",
      "text": "There's a ridge to the east. It's a longer path, but safer.",
      "next": "cyrus_responds_to_phaidros"
    },
    "cyrus_responds_to_phaidros": {
      "perspective_shift": "cyrus",
      "speaker": "cyrus",
      "listener": "phaidros",
      "text": "Good thinking. Let's take the ridge.",
      "next": "conditional_node"
    },
    "conditional_node": {
      "speaker": "vaughn",
      "listener": "cyrus",
      "condition": { "flag": "trusted_phaidros", "value": true },
      "text": "Phaidros has good instincts. We should listen to him more often.",
      "fallback": "end_node"
    },
    "end_node": {
      "speaker": "cyrus",
      "listener": "vaughn",
      "text": "Let's move out."
    }
  }
}
```

- [ ] **Step 3: Commit**

```bash
git add godot/data/dialogue/test_dialogue.json
git commit -m "feat(dialogue): add sample dialogue tree with branching and conditions"
```

---

### Task 2: DataLoader Dialogue Methods

**Files:**
- Modify: `godot/scripts/data/data_loader.gd:94-95` (insert after `get_encounter`)

- [ ] **Step 1: Add load_dialogue method to DataLoader**

Add after the `get_encounter` method (line 94) in `godot/scripts/data/data_loader.gd`:

```gdscript
## Load a dialogue tree by ID
static func load_dialogue(dialogue_id: String) -> Dictionary:
	var path = DATA_PATH + "dialogue/" + dialogue_id + ".json"
	var data = _load_json_file(path)
	if data.is_empty():
		push_warning("Dialogue not found: " + dialogue_id)
	return data
```

- [ ] **Step 2: Verify DataLoader can load the sample dialogue**

Open the Godot editor, open the output console, and run the project. In main.gd `_ready()`, temporarily add a test print:
```gdscript
var test = DataLoader.load_dialogue("test_dialogue")
print("Dialogue loaded: ", test.get("id", "FAILED"))
```
Expected: `Dialogue loaded: test_dialogue` in the output console. Remove the test print after verifying.

- [ ] **Step 3: Commit**

```bash
git add godot/scripts/data/data_loader.gd
git commit -m "feat(dialogue): add load_dialogue method to DataLoader"
```

---

### Task 3: DialogueStateMachine — Core Traversal

**Files:**
- Create: `godot/scripts/logic/dialogue/dialogue_state_machine.gd`

- [ ] **Step 1: Create the directory**

Run: `mkdir -p godot/scripts/logic/dialogue`

- [ ] **Step 2: Write the DialogueStateMachine class**

Create `godot/scripts/logic/dialogue/dialogue_state_machine.gd`:

```gdscript
class_name DialogueStateMachine
extends RefCounted
## Pure dialogue traversal logic — no Godot node dependencies.
## Traverses a dialogue tree, evaluates conditions, and returns state dicts.
## Effects are returned via pending_effects for the caller to apply.

var _dialogue_data: Dictionary = {}
var _nodes: Dictionary = {}
var _current_node_id: String = ""
var _current_node: Dictionary = {}
var _perspective: String = ""
var _participants: Array = []
var _is_loaded: bool = false
var _is_complete: bool = false
var _pending_effects: Dictionary = {"flags": {}, "consequences": {}}
var _perspective_shifted: bool = false

# Injected callables for condition evaluation
var _flag_lookup: Callable
var _consequence_lookup: Callable


func load_dialogue(dialogue_data: Dictionary, flag_lookup: Callable, consequence_lookup: Callable) -> void:
	_dialogue_data = dialogue_data
	_nodes = dialogue_data.get("nodes", {})
	_participants = dialogue_data.get("participants", [])
	_perspective = dialogue_data.get("initial_perspective", "")
	_flag_lookup = flag_lookup
	_consequence_lookup = consequence_lookup
	_is_loaded = true
	_is_complete = false
	_pending_effects = {"flags": {}, "consequences": {}}


func start() -> Dictionary:
	assert(_is_loaded, "DialogueStateMachine: call load_dialogue() before start()")
	var initial_node_id = _dialogue_data.get("initial_node", "")
	return _go_to_node(initial_node_id)


func advance() -> Dictionary:
	if _is_complete:
		return get_current_state()

	# If current node has choices, advance is a no-op
	var choices = _current_node.get("choices", [])
	if not choices.is_empty():
		return get_current_state()

	var next_id = _current_node.get("next", "")
	if next_id.is_empty():
		_is_complete = true
		return get_current_state()

	return _go_to_node(next_id)


func choose(index: int) -> Dictionary:
	var choices = _get_visible_choices()
	if index < 0 or index >= choices.size():
		push_warning("DialogueStateMachine: invalid choice index %d" % index)
		return get_current_state()

	var choice = choices[index]

	# Collect effects for caller to apply
	_pending_effects = {"flags": {}, "consequences": {}}
	var effects = choice.get("effects", {})
	if not effects.is_empty():
		_pending_effects["flags"] = effects.get("flags", {})
		_pending_effects["consequences"] = effects.get("consequences", {})

	var next_id = choice.get("next", "")
	if next_id.is_empty():
		_is_complete = true
		return get_current_state()

	return _go_to_node(next_id)


func is_complete() -> bool:
	return _is_complete


func get_current_state() -> Dictionary:
	var visible_choices = _get_visible_choices()
	var choice_dicts: Array = []
	for choice in visible_choices:
		var c: Dictionary = {"text": choice.get("text", ""), "next": choice.get("next", "")}
		if choice.has("hint"):
			c["hint"] = choice.hint
		choice_dicts.append(c)

	var observers = _get_observers()
	var observer_expressions: Dictionary = {}
	var node_observer_expr = _current_node.get("observer_expressions", {})
	for obs_id in observers:
		observer_expressions[obs_id] = node_observer_expr.get(obs_id, "neutral")

	return {
		"speaker": _current_node.get("speaker", ""),
		"listener": _current_node.get("listener", ""),
		"perspective": _perspective,
		"text": _current_node.get("text", ""),
		"expression": _current_node.get("expression", "neutral"),
		"listener_expression": _current_node.get("listener_expression", "neutral"),
		"observer_expressions": observer_expressions,
		"participants": _participants.duplicate(),
		"choices": choice_dicts,
		"perspective_shifted": _perspective_shifted,
		"is_complete": _is_complete,
		"pending_effects": _pending_effects.duplicate(true),
	}


# --- Private ---

func _go_to_node(node_id: String) -> Dictionary:
	_pending_effects = {"flags": {}, "consequences": {}}
	_perspective_shifted = false

	if not _nodes.has(node_id):
		push_warning("DialogueStateMachine: node not found: %s" % node_id)
		_is_complete = true
		return get_current_state()

	var node = _nodes[node_id]

	# Check condition — skip if unmet
	if node.has("condition") and not _evaluate_condition(node.condition):
		var fallback = node.get("fallback", node.get("next", ""))
		if fallback.is_empty():
			_is_complete = true
			return get_current_state()
		return _go_to_node(fallback)

	# Apply perspective shift
	if node.has("perspective_shift"):
		_perspective = node.perspective_shift
		_perspective_shifted = true

	_current_node_id = node_id
	_current_node = node

	# Check if terminal
	if not node.has("next") and not node.has("choices"):
		_is_complete = true

	return get_current_state()


func _evaluate_condition(condition: Dictionary) -> bool:
	if condition.has("flag"):
		var flag_value = _flag_lookup.call(condition.flag)
		return flag_value == condition.get("value", true)

	if condition.has("consequence"):
		var current = _consequence_lookup.call(condition.consequence)
		var target_value = condition.get("value", 0)
		var op = condition.get("operator", "==")
		match op:
			"==": return current == target_value
			"!=": return current != target_value
			">": return current > target_value
			"<": return current < target_value
			">=": return current >= target_value
			"<=": return current <= target_value
		push_warning("DialogueStateMachine: unknown operator: %s" % op)
		return false

	push_warning("DialogueStateMachine: unknown condition format")
	return false


func _get_visible_choices() -> Array:
	var all_choices = _current_node.get("choices", [])
	var visible: Array = []
	for choice in all_choices:
		if choice.has("condition"):
			if not _evaluate_condition(choice.condition):
				continue
		visible.append(choice)
	return visible


func _get_observers() -> Array:
	var speaker = _current_node.get("speaker", "")
	var listener = _current_node.get("listener", "")
	var observers: Array = []
	for p in _participants:
		if p != speaker and p != listener:
			observers.append(p)
	return observers
```

- [ ] **Step 3: Verify it loads in Godot**

Open the project in the Godot editor. Check the output console for any parse errors related to `dialogue_state_machine.gd`. The class should register as `DialogueStateMachine` without errors.

- [ ] **Step 4: Commit**

```bash
git add godot/scripts/logic/dialogue/dialogue_state_machine.gd
git commit -m "feat(dialogue): implement DialogueStateMachine with traversal, branching, conditions"
```

---

### Task 4: Copy Placeholder Portraits into Godot Assets

**Files:**
- Create: `godot/assets/portraits/cyrus.png` (copy from BREAK!! assets)
- Create: `godot/assets/portraits/vaughn.png`
- Create: `godot/assets/portraits/phaidros.png`

- [ ] **Step 1: Create the portraits directory and copy placeholders**

```bash
mkdir -p godot/assets/portraits
cp assets/dialogue/BREAK\!\!Portraits/champion1.png godot/assets/portraits/cyrus.png
cp assets/dialogue/BREAK\!\!Portraits/sneak1.png godot/assets/portraits/vaughn.png
cp assets/dialogue/BREAK\!\!Portraits/factotum.png godot/assets/portraits/phaidros.png
```

- [ ] **Step 2: Commit**

```bash
git add godot/assets/portraits/
git commit -m "feat(dialogue): add placeholder portrait assets for party members"
```

---

### Task 5: DialoguePlayer Scene and Script

**Files:**
- Create: `godot/scenes/dialogue/dialogue_player.tscn`
- Create: `godot/scripts/presentation/dialogue/dialogue_player.gd`

This is the main presentation layer — the scene with portrait slots, dialog box, and typewriter text.

- [ ] **Step 1: Create the directories**

```bash
mkdir -p godot/scenes/dialogue
mkdir -p godot/scripts/presentation/dialogue
```

- [ ] **Step 2: Write the DialoguePlayer script**

Create `godot/scripts/presentation/dialogue/dialogue_player.gd`:

```gdscript
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
```

- [ ] **Step 3: Write the DialoguePlayer scene (.tscn)**

Create `godot/scenes/dialogue/dialogue_player.tscn`:

```
[gd_scene load_steps=2 format=3]

[ext_resource type="Script" path="res://scripts/presentation/dialogue/dialogue_player.gd" id="1_script"]

[node name="DialoguePlayer" type="Control"]
layout_mode = 3
anchors_preset = 15
anchor_right = 1.0
anchor_bottom = 1.0
grow_horizontal = 2
grow_vertical = 2
script = ExtResource("1_script")

[node name="Background" type="ColorRect" parent="."]
layout_mode = 1
anchors_preset = 15
anchor_right = 1.0
anchor_bottom = 1.0
grow_horizontal = 2
grow_vertical = 2
color = Color(0.04, 0.06, 0.1, 1)

[node name="PortraitSlots" type="Control" parent="."]
layout_mode = 1
anchors_preset = 15
anchor_right = 1.0
anchor_bottom = 1.0
grow_horizontal = 2
grow_vertical = 2

[node name="SpeakerSlot" type="TextureRect" parent="PortraitSlots"]
layout_mode = 1
anchors_preset = 2
anchor_top = 1.0
anchor_bottom = 1.0
offset_left = 40.0
offset_top = -300.0
offset_right = 220.0
offset_bottom = -40.0
grow_vertical = 0
expand_mode = 1
stretch_mode = 5

[node name="SpeakerLabel" type="Label" parent="PortraitSlots"]
layout_mode = 1
anchors_preset = 2
anchor_top = 1.0
anchor_bottom = 1.0
offset_left = 40.0
offset_top = -34.0
offset_right = 220.0
grow_vertical = 0
theme_override_font_sizes/font_size = 14
horizontal_alignment = 1

[node name="ListenerSlot" type="TextureRect" parent="PortraitSlots"]
layout_mode = 1
anchors_preset = 1
anchor_left = 1.0
anchor_right = 1.0
offset_left = -240.0
offset_top = 30.0
offset_right = -60.0
offset_bottom = 230.0
grow_horizontal = 0
expand_mode = 1
stretch_mode = 5

[node name="ListenerLabel" type="Label" parent="PortraitSlots"]
layout_mode = 1
anchors_preset = 1
anchor_left = 1.0
anchor_right = 1.0
offset_left = -240.0
offset_top = 235.0
offset_right = -60.0
offset_bottom = 255.0
grow_horizontal = 0
theme_override_font_sizes/font_size = 14
horizontal_alignment = 1

[node name="ObserverContainer" type="HBoxContainer" parent="PortraitSlots"]
layout_mode = 1
offset_left = 30.0
offset_top = 30.0
offset_right = 230.0
offset_bottom = 180.0
theme_override_constants/separation = 8

[node name="DialogBox" type="PanelContainer" parent="."]
layout_mode = 1
anchors_preset = 3
anchor_left = 1.0
anchor_top = 1.0
anchor_right = 1.0
anchor_bottom = 1.0
offset_left = -560.0
offset_top = -220.0
offset_right = -30.0
offset_bottom = -30.0
grow_horizontal = 0
grow_vertical = 0

[node name="MarginContainer" type="MarginContainer" parent="DialogBox"]
layout_mode = 2
theme_override_constants/margin_left = 16
theme_override_constants/margin_top = 12
theme_override_constants/margin_right = 16
theme_override_constants/margin_bottom = 12

[node name="VBoxContainer" type="VBoxContainer" parent="DialogBox/MarginContainer"]
layout_mode = 2

[node name="SpeakerName" type="Label" parent="DialogBox/MarginContainer/VBoxContainer"]
layout_mode = 2
theme_override_font_sizes/font_size = 16
theme_override_colors/font_color = Color(0.48, 0.72, 0.85, 1)
text = "SPEAKER"

[node name="DialogText" type="RichTextLabel" parent="DialogBox/MarginContainer/VBoxContainer"]
layout_mode = 2
custom_minimum_size = Vector2(0, 80)
text = ""
fit_content = true

[node name="ContinueIndicator" type="Label" parent="DialogBox/MarginContainer/VBoxContainer"]
layout_mode = 2
horizontal_alignment = 2
text = "▼"

[node name="ChoiceContainer" type="VBoxContainer" parent="DialogBox/MarginContainer/VBoxContainer"]
layout_mode = 2
theme_override_constants/separation = 4
```

- [ ] **Step 4: Open in Godot editor and verify the scene tree loads without errors**

Open `godot/scenes/dialogue/dialogue_player.tscn` in the Godot editor. Check:
- Scene tree matches the expected hierarchy
- No script errors in the output panel
- The layout roughly positions elements correctly (speaker bottom-left, listener top-right, dialog box bottom-right, observers top-left)

- [ ] **Step 5: Commit**

```bash
git add godot/scenes/dialogue/dialogue_player.tscn godot/scripts/presentation/dialogue/dialogue_player.gd
git commit -m "feat(dialogue): implement DialoguePlayer scene with portrait layout and typewriter text"
```

---

### Task 6: Test Dialogue Scene and Main Menu Button

**Files:**
- Create: `godot/scenes/dialogue/test_dialogue.tscn`
- Create: `godot/scripts/presentation/dialogue/test_dialogue.gd`
- Modify: `godot/scenes/main.tscn`
- Modify: `godot/scripts/main.gd`

- [ ] **Step 1: Write the test dialogue harness script**

Create `godot/scripts/presentation/dialogue/test_dialogue.gd`:

```gdscript
extends Control
## Test harness for the dialogue system. Loads a sample dialogue and
## provides a back button to return to the main menu.

const DataLoaderClass = preload("res://scripts/data/data_loader.gd")

@onready var dialogue_player: DialoguePlayer = $DialoguePlayer
@onready var back_button: Button = $UI/BackButton


func _ready() -> void:
	back_button.pressed.connect(_on_back_pressed)
	dialogue_player.dialogue_completed.connect(_on_dialogue_completed)

	# Load and start the test dialogue
	var dialogue_data = DataLoaderClass.load_dialogue("test_dialogue")
	if dialogue_data.is_empty():
		push_error("Failed to load test_dialogue")
		return
	dialogue_player.start_dialogue(dialogue_data)


func _on_dialogue_completed(_dialogue_id: String) -> void:
	print("Dialogue complete: ", _dialogue_id)
	# Show a completion message, then allow returning to menu
	back_button.text = "Dialogue Complete — Back to Menu"


func _on_back_pressed() -> void:
	GameManager.change_state(GameManager.GameState.MAIN_MENU)
	GameManager.transition_to_scene("res://scenes/main.tscn")
```

- [ ] **Step 2: Write the test dialogue scene (.tscn)**

Create `godot/scenes/dialogue/test_dialogue.tscn`:

```
[gd_scene load_steps=3 format=3]

[ext_resource type="Script" path="res://scripts/presentation/dialogue/test_dialogue.gd" id="1_script"]
[ext_resource type="PackedScene" path="res://scenes/dialogue/dialogue_player.tscn" id="2_dialogue_player"]

[node name="TestDialogue" type="Control"]
layout_mode = 3
anchors_preset = 15
anchor_right = 1.0
anchor_bottom = 1.0
grow_horizontal = 2
grow_vertical = 2
script = ExtResource("1_script")

[node name="DialoguePlayer" parent="." instance=ExtResource("2_dialogue_player")]
layout_mode = 1

[node name="UI" type="CanvasLayer" parent="."]

[node name="BackButton" type="Button" parent="UI"]
anchors_preset = 1
anchor_left = 1.0
anchor_right = 1.0
offset_left = -160.0
offset_top = 10.0
offset_right = -10.0
offset_bottom = 40.0
grow_horizontal = 0
text = "Back to Menu"
```

- [ ] **Step 3: Add Test Dialogue button to main menu scene**

In `godot/scenes/main.tscn`, add a new button node after `TestExplorationButton`. Insert before the `VersionLabel` node:

```
[node name="TestDialogueButton" type="Button" parent="CanvasLayer"]
anchors_preset = 8
anchor_left = 0.5
anchor_top = 0.5
anchor_right = 0.5
anchor_bottom = 0.5
offset_left = -100.0
offset_top = 150.0
offset_right = 100.0
offset_bottom = 190.0
grow_horizontal = 2
grow_vertical = 2
text = "Test Dialogue"
```

- [ ] **Step 4: Connect the button in main.gd**

In `godot/scripts/main.gd`, add the connection and handler:

Add to `_ready()`:
```gdscript
	$CanvasLayer/TestDialogueButton.pressed.connect(_on_test_dialogue_pressed)
```

Add the handler function:
```gdscript
func _on_test_dialogue_pressed() -> void:
	GameManager.change_state(GameManager.GameState.DIALOG)
	GameManager.transition_to_scene("res://scenes/dialogue/test_dialogue.tscn")
```

- [ ] **Step 5: Run the game and test the full flow**

Launch the project from Godot. Verify:
1. Main menu shows "Test Dialogue" button
2. Clicking it loads the dialogue scene
3. Cyrus's portrait appears bottom-left (highlighted), Vaughn top-right, Phaidros top-left (dimmed)
4. Dialog box shows speaker name and typewriter text
5. Pressing confirm advances to next line
6. Pressing cancel skips typewriter to full text
7. Choices appear after Vaughn's question — up/down navigates, confirm selects
8. Choosing "Phaidros, what do you think?" triggers perspective shift (Phaidros moves to speaker slot)
9. After the conditional node, dialogue ends with ■ indicator
10. "Back to Menu" returns to main menu

- [ ] **Step 6: Commit**

```bash
git add godot/scenes/dialogue/test_dialogue.tscn godot/scripts/presentation/dialogue/test_dialogue.gd godot/scenes/main.tscn godot/scripts/main.gd
git commit -m "feat(dialogue): add test dialogue scene and main menu button"
```

---

### Task 7: Polish and Verify

- [ ] **Step 1: Verify story flag integration**

1. Run the game, start test dialogue
2. Choose "Phaidros, what do you think?" (the choice with effects)
3. After dialogue completes, return to menu
4. Start test dialogue again
5. Play through to the conditional node — Vaughn's "Phaidros has good instincts" line should appear (because `trusted_phaidros` flag is now set)
6. Check Godot output console for: `Story flag set: trusted_phaidros = true` and `Consequence modified: phaidros_trust = 5`

- [ ] **Step 2: Verify alternative paths**

1. Restart the game (fresh flags)
2. Choose "Push forward" — should go to Cyrus's "We push forward" line, then Vaughn acknowledges, dialogue ends
3. Restart and choose "Vaughn, scout ahead" — should go to scout sequence, dialogue ends
4. In both paths, verify the conditional node is skipped (no trusted_phaidros flag)

- [ ] **Step 3: Verify edge cases**

1. Spam confirm during typewriter — should skip to full text, then advance
2. Press cancel during typewriter — should show full text
3. Navigate choices with up/down, wrap around
4. Verify no errors in Godot output console throughout all paths

- [ ] **Step 4: Final commit if any fixes were needed**

```bash
git status  # Review changed files first
git add godot/
git commit -m "fix(dialogue): polish and edge case fixes"
```

Only run this commit if changes were made during testing. Skip if everything worked cleanly.
