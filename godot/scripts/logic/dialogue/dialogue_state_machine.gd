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
