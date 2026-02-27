class_name APSystem
extends RefCounted
## Pure logic class for Action Point (AP) management in combat.
## Handles AP costs, conservation, and turn economy.
##
## This class has no Godot scene dependencies and can be tested in isolation.

const CombatConfigLoaderClass = preload("res://scripts/logic/combat/combat_config_loader.gd")

# ============================================================================
# TUNABLE CONSTANTS - See docs/00_Development/Battle_Tuning_Lab.md
# ============================================================================

## Fallback if config not loaded. Actual value derived from config ap.base + agility / ap.agility_divisor.
const BASE_AP_PER_TURN: int = 2

## Action costs by type
const AP_COSTS: Dictionary = {
	"attack": 1,
	"basic_attack": 1,
	"move": 1,
	"movement": 1,
	"skill_light": 1,
	"skill_standard": 2,
	"skill_heavy": 3,
	"defend": 0,  # Defend is free but ends turn
	"end_turn": 0,
	"item": 1,
}

## Default cost for unlisted actions
const DEFAULT_AP_COST: int = 1

# ============================================================================
# DATA STRUCTURES
# ============================================================================

## Per-unit AP state
class UnitAPState:
	var unit_id: String
	var current_ap: int
	var conserved_ap: int  # Carried from previous turn (players only)
	var ap_cap: int  # Maximum total AP (based on constitution)
	var base_ap: int  # AP granted per turn (from agility formula)
	var is_ally: bool

	func _init(p_unit_id: String, p_ap_cap: int, p_is_ally: bool) -> void:
		unit_id = p_unit_id
		current_ap = 0
		conserved_ap = 0
		ap_cap = p_ap_cap
		base_ap = BASE_AP_PER_TURN
		is_ally = p_is_ally

	func get_available_ap() -> int:
		return current_ap

# ============================================================================
# STATE
# ============================================================================

## AP state for all units in combat
var _unit_states: Dictionary = {}  # unit_id -> UnitAPState

# ============================================================================
# INITIALIZATION
# ============================================================================

## Clear all state (call at combat start)
func reset() -> void:
	_unit_states.clear()


## Register a unit with the AP system
## constitution: determines AP cap for player characters
## agility: used to derive base AP per turn from config formula
## is_ally: only allies can conserve AP
func register_unit(unit_id: String, constitution: int, is_ally: bool, agility: int = 5) -> void:
	var base_ap = _calculate_base_ap(agility)
	var ap_cap = max(constitution, base_ap) if is_ally else base_ap
	var state = UnitAPState.new(unit_id, ap_cap, is_ally)
	state.base_ap = base_ap
	_unit_states[unit_id] = state


## Calculate base AP per turn from config: base + floor(agility / divisor)
func _calculate_base_ap(agility: int) -> int:
	var base = int(CombatConfigLoaderClass.get_ap_base())
	var divisor = int(CombatConfigLoaderClass.get_ap_agility_divisor())
	if divisor <= 0:
		divisor = 4
	return base + int(floor(float(agility) / float(divisor)))


## Remove a unit (e.g., when defeated)
func remove_unit(unit_id: String) -> void:
	_unit_states.erase(unit_id)

# ============================================================================
# TURN MANAGEMENT
# ============================================================================

## Call at the start of a unit's turn to calculate available AP
## Returns the AP available for this turn
func start_turn(unit_id: String) -> int:
	var state = _get_state(unit_id)
	if state == null:
		return BASE_AP_PER_TURN

	# Calculate available AP: base_ap + conserved, capped at ap_cap
	var available = state.base_ap + state.conserved_ap
	if state.is_ally:
		available = min(available, state.ap_cap)
	else:
		available = state.base_ap  # Enemies don't conserve

	state.current_ap = available
	return available


## Spend AP on an action
## Returns true if successful, false if not enough AP
func spend_ap(unit_id: String, amount: int) -> bool:
	var state = _get_state(unit_id)
	if state == null:
		return false

	if state.current_ap < amount:
		return false

	state.current_ap -= amount
	return true


## Get current AP for a unit
func get_current_ap(unit_id: String) -> int:
	var state = _get_state(unit_id)
	if state == null:
		return 0
	return state.current_ap


## Get AP cap for a unit
func get_ap_cap(unit_id: String) -> int:
	var state = _get_state(unit_id)
	if state == null:
		return BASE_AP_PER_TURN
	return state.ap_cap


## End turn and handle AP conservation
## Returns remaining AP (useful for CTB speed bonus calculation)
func end_turn(unit_id: String) -> int:
	var state = _get_state(unit_id)
	if state == null:
		return 0

	var remaining = state.current_ap

	# Conserve AP for player characters only
	if state.is_ally:
		state.conserved_ap = remaining
	else:
		state.conserved_ap = 0

	state.current_ap = 0
	return remaining

# ============================================================================
# ACTION COSTS
# ============================================================================

## Get AP cost for an action type
func get_action_cost(action_type: String) -> int:
	if AP_COSTS.has(action_type):
		return AP_COSTS[action_type]
	return DEFAULT_AP_COST


## Check if unit can afford an action
func can_afford(unit_id: String, action_type: String) -> bool:
	var cost = get_action_cost(action_type)
	var current = get_current_ap(unit_id)
	return current >= cost


## Check if unit can afford a specific AP amount
func can_afford_amount(unit_id: String, amount: int) -> bool:
	return get_current_ap(unit_id) >= amount


## Spend AP for an action by type
## Returns true if successful
func spend_action(unit_id: String, action_type: String) -> bool:
	var cost = get_action_cost(action_type)
	return spend_ap(unit_id, cost)

# ============================================================================
# SKILL-SPECIFIC COSTS
# ============================================================================

## Get AP cost for a specific skill (skills can override default costs)
## skill_data should have an optional "ap_cost" field
func get_skill_cost(skill_data: Dictionary) -> int:
	if skill_data.has("ap_cost"):
		return skill_data.ap_cost

	# Default based on skill weight/power
	var weight = skill_data.get("weight", "standard")
	match weight:
		"light": return AP_COSTS.skill_light
		"heavy": return AP_COSTS.skill_heavy
		_: return AP_COSTS.skill_standard

# ============================================================================
# PREVIEW / SIMULATION
# ============================================================================

## Preview what AP would remain after an action (without actually spending)
func preview_remaining_ap(unit_id: String, action_type: String) -> int:
	var current = get_current_ap(unit_id)
	var cost = get_action_cost(action_type)
	return max(0, current - cost)


## Preview what AP would remain after spending a specific amount
func preview_remaining_ap_amount(unit_id: String, amount: int) -> int:
	var current = get_current_ap(unit_id)
	return max(0, current - amount)

# ============================================================================
# INTERNAL HELPERS
# ============================================================================

func _get_state(unit_id: String) -> UnitAPState:
	if _unit_states.has(unit_id):
		return _unit_states[unit_id]
	return null

# ============================================================================
# DEBUG / INSPECTION
# ============================================================================

## Get debug info about all unit AP states
func get_debug_state() -> Dictionary:
	var result = {}
	for unit_id in _unit_states:
		var state = _unit_states[unit_id]
		result[unit_id] = {
			"current_ap": state.current_ap,
			"conserved_ap": state.conserved_ap,
			"ap_cap": state.ap_cap,
			"is_ally": state.is_ally
		}
	return result
