# Dialogue System — Prototype Design

## Overview

A prototype dialogue system for Disruption's vertical slice. Visual novel style with a unique spatial portrait layout: the speaker is positioned bottom-left (facing away from camera), the listener is top-right (facing toward camera), and observers are top-left. The dialog box is anchored bottom-right.

The system follows the project's architecture principles: JSON data, pure logic layer, Godot presentation layer.

## Layout

The dialogue scene uses a cinematic perspective where the camera is positioned behind the speaker, looking into the conversation:

- **Speaker** (bottom-left): larger portrait, highlighted border, facing away. This is the character currently delivering a line.
- **Listener** (top-right): portrait facing toward camera, showing their reaction.
- **Observers** (top-left): full-body, dimmed. Other participants not directly involved in the current exchange.
- **Dialog box** (bottom-right): speaker name plate, text with typewriter effect, and inline branching choices.

When the speaking role changes, characters stay in their positions — only the highlight shifts (brightness, border glow). Positions only rearrange on a **perspective shift**, where the player's viewpoint character changes.

### Perspective

Each dialogue scene has a perspective character — the party member the player is "seeing through" and making choices for. This is typically the speaker in the bottom-left position. The perspective character is defined in the dialogue data and can shift mid-conversation. When a perspective shift occurs, portraits snap to new positions (animation is out of scope for the prototype).

Any party member can be the perspective character, not just Cyrus.

## Data Format

Dialogue trees are JSON files stored in `godot/data/dialogue/` (resolved as `res://data/dialogue/` at runtime). Each file is one conversation.

```json
{
  "id": "ch1_camp_discussion",
  "initial_node": "start",
  "initial_perspective": "cyrus",
  "participants": ["cyrus", "vaughn", "phaidros"],
  "nodes": {
    "start": {
      "speaker": "cyrus",
      "listener": "vaughn",
      "text": "We need to move carefully through here. I can sense something is wrong.",
      "expression": "concerned",
      "listener_expression": "neutral",
      "observer_expressions": { "phaidros": "thoughtful" },
      "next": "vaughn_responds"
    },
    "vaughn_responds": {
      "speaker": "vaughn",
      "listener": "cyrus",
      "text": "What's the plan? We can't stay here forever.",
      "choices": [
        {
          "text": "Push forward — we can handle it.",
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
    "ask_phaidros": {
      "perspective_shift": "phaidros",
      "speaker": "phaidros",
      "listener": "vaughn",
      "text": "The ground here is unstable. We should find higher terrain.",
      "next": "after_phaidros"
    }
  }
}
```

### Node fields

| Field | Required | Description |
|-------|----------|-------------|
| `speaker` | yes | Character ID of the speaking character |
| `listener` | no | Character ID of the character being addressed. If omitted (e.g., monologue or inner thought), the listener slot is hidden. |
| `text` | yes | The dialogue line |
| `next` | no | ID of the next node. Absent on terminal nodes (no `next` and no `choices` = dialogue ends). Mutually exclusive with `choices`. |
| `choices` | no | Array of choice objects. Mutually exclusive with `next`. |
| `expression` | no | Speaker's expression (defaults to `"neutral"`) |
| `listener_expression` | no | Listener's expression |
| `observer_expressions` | no | Dict of character ID to expression for observers |
| `perspective_shift` | no | Character ID to shift perspective to before this line plays |
| `condition` | no | Condition object; if unmet, the node skips to `next` or `fallback` |
| `fallback` | no | Node ID to go to if the condition is unmet |

### Choice fields

| Field | Required | Description |
|-------|----------|-------------|
| `text` | yes | The choice text shown to the player |
| `next` | yes | Node ID to go to when selected |
| `hint` | no | Consequence hint shown to the player (e.g., "Builds trust") |
| `effects` | no | Object with `flags` (dict of flag name to value) and `consequences` (dict of consequence name to delta) |
| `condition` | no | Condition object; if unmet, the choice is hidden |

### Condition format

Flag check:
```json
{ "flag": "trusted_phaidros", "value": true }
```

Consequence threshold check:
```json
{ "consequence": "phaidros_trust", "operator": ">=", "value": 10 }
```

Supported operators for consequence checks: `==`, `!=`, `>`, `<`, `>=`, `<=`.

Conditions are evaluated by the state machine via a flag/consequence lookup callable injected at load time (see Logic Layer). A choice or node with an unmet condition is hidden (choices) or skipped (nodes).

## Logic Layer

`godot/scripts/logic/dialogue/dialogue_state_machine.gd`

A pure class with no Godot node dependencies. Handles dialogue traversal, branching, and condition evaluation. Does **not** call GameManager directly — effects and flag lookups are mediated through callables and return values to keep this layer portable.

### Interface

- `load(dialogue_data: Dictionary, flag_lookup: Callable, consequence_lookup: Callable)` — parse the dialogue tree. `flag_lookup(name) -> Variant` and `consequence_lookup(name) -> float` are injected so the state machine can evaluate conditions without depending on GameManager.
- `start() -> Dictionary` — returns the first node's state
- `advance() -> Dictionary` — move to next node, returns new state. If the current node has choices, this is a no-op and returns the current state unchanged (use `choose()` instead).
- `choose(index: int) -> Dictionary` — select a choice, returns new state with `pending_effects` for the caller to apply
- `is_complete() -> bool` — true when there's no next node
- `get_current_state() -> Dictionary` — returns the current state

### State dictionary

Returned by `start()`, `advance()`, and `choose()`:

```
{
  "speaker": String,
  "listener": String,           # empty string if no listener (monologue)
  "perspective": String,
  "text": String,
  "expression": String,
  "listener_expression": String,
  "observer_expressions": Dictionary,
  "participants": Array,
  "choices": Array,             # empty if no choices
  "perspective_shifted": bool,
  "is_complete": bool,
  "pending_effects": Dictionary  # { "flags": {}, "consequences": {} } — caller applies these
}
```

The `pending_effects` field is populated when `choose()` selects a choice that has `effects`. The presentation layer (or integration code) is responsible for calling `GameManager.set_story_flag()` and `GameManager.modify_consequence()` with these values. This keeps the state machine free of engine dependencies.

## Presentation Layer

`godot/scripts/presentation/dialogue/dialogue_player.gd` + `godot/scenes/dialogue/dialogue_player.tscn`

### Scene tree

```
DialoguePlayer (Control)
├── Background (TextureRect)
├── PortraitSlots (Control)
│   ├── SpeakerSlot (bottom-left)
│   ├── ListenerSlot (top-right)
│   └── ObserverContainer (HBoxContainer, top-left — holds 0+ observer portraits)
├── DialogBox (PanelContainer, bottom-right)
│   ├── SpeakerName (Label)
│   ├── DialogText (RichTextLabel)
│   ├── ContinueIndicator (Label)
│   └── ChoiceContainer (VBoxContainer)
└── InputHandler (Node)
```

### Behavior

1. Receives state dict from `DialogueStateMachine`
2. Places portrait textures in slots based on speaker/listener/participant roles. Remaining participants go into `ObserverContainer`. If no listener, the listener slot is hidden.
3. Highlights the active speaker slot (bright border, full opacity), dims others
4. Displays text with typewriter effect (~30 characters/second) in the dialog box
5. When `choices` is non-empty, hides continue indicator and shows choice buttons in `ChoiceContainer`
6. On perspective shift, portraits snap to new positions (no animation in prototype)
7. After `choose()`, reads `pending_effects` from the state dict and applies them via `GameManager.set_story_flag()` / `GameManager.modify_consequence()`

### Portrait management

A `portrait_map` dictionary maps character ID + expression to texture paths. For the prototype, one portrait per character with the expression field ignored.

### Input

- `confirm` — advance text or select highlighted choice
- `cancel` — fast-complete the typewriter effect (skip to full text)
- Up/down — navigate choices

## Integration

### DataLoader addition

Add a `load_dialogue(dialogue_id: String) -> Dictionary` static method to `godot/scripts/data/data_loader.gd` that loads from `res://data/dialogue/{dialogue_id}.json`, following the existing pattern for skills, characters, etc.

### From exploration (out of scope for prototype)

The existing `_start_dialog_with(npc)` in `exploration_scene.gd` will eventually:

1. Get the dialogue ID from the NPC
2. Load the JSON via `DataLoader.load_dialogue()`
3. Call `GameManager.change_state(GameManager.GameState.DIALOG)`
4. Instantiate `DialoguePlayer`, pass it the dialogue data
5. When dialogue completes, return to `EXPLORATION` state

### From main menu (prototype testing)

A "Test Dialogue" button on the main menu loads a test dialogue scene directly.

### EventBus signals

Existing signals emitted at the appropriate moments:

- `dialog_started(dialog_id)` — when DialoguePlayer begins
- `dialog_line_displayed(speaker, text)` — each time a new line renders
- `dialog_choice_made(choice_index, choice_text)` — when the player selects a choice
- `dialog_ended(dialog_id)` — when the conversation completes

## File Organization

```
godot/scripts/logic/dialogue/
    dialogue_state_machine.gd       # Pure logic, no Godot node deps
godot/scripts/data/
    data_loader.gd                  # Add load_dialogue() method
godot/scripts/presentation/dialogue/
    dialogue_player.gd              # Scene controller
godot/data/dialogue/
    ch1_camp_discussion.json        # Sample dialogue tree
godot/scenes/dialogue/
    dialogue_player.tscn            # The dialogue scene
    test_dialogue.tscn              # Test harness (launched from main menu)
```

## Prototype Scope

### In scope

- `DialogueStateMachine` with load, advance, choose, conditions, effects
- `DialoguePlayer` scene with spatial portrait layout
- Dialog box with typewriter text, speaker name plate, inline choices
- One portrait per character (no expression variants)
- Highlight/dim for active speaker
- One sample dialogue JSON (3 characters, branching, perspective shift, story flag)
- "Test Dialogue" button on main menu
- EventBus signal emissions

### Out of scope

- Expression variants on portraits
- Perspective shift animation (snap only)
- Background art (placeholder gradient)
- Sound effects / voice
- Save/load mid-dialogue
- NPC integration in exploration scene
