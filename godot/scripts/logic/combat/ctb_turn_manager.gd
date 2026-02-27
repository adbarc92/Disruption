class_name CTBTurnManager
extends RefCounted
## Pure logic class for Conditional Turn-Based (CTB) turn order management.
## Inspired by FFX's system with tick-based timing and dynamic turn preview.
##
## This class has no Godot scene dependencies and can be tested in isolation.

# ============================================================================
# TUNABLE CONSTANTS - See docs/00_Development/Battle_Tuning_Lab.md
# ============================================================================

const BASE_TICKS: int = 100
const SPEED_MULTIPLIER: int = 5
const AP_TO_TICKS_RATIO: int = 5
const TURN_ORDER_DISPLAY_COUNT: int = 10

# ============================================================================
# DATA STRUCTURES
# ============================================================================

## Represents a unit's position in the turn queue
class TurnEntry:
	var unit_id: String
	var ticks_remaining: int
	var speed: int  # Cached for tie-breaking
	var _random_tiebreaker: float  # For when speed also ties

	func _init(p_unit_id: String, p_ticks: int, p_speed: int) -> void:
		unit_id = p_unit_id
		ticks_remaining = p_ticks
		speed = p_speed
		_random_tiebreaker = randf()

# ============================================================================
# STATE
# ============================================================================

## The turn queue - sorted list of TurnEntry objects
var _turn_queue: Array[TurnEntry] = []

## Reference to get unit data by ID (set by combat manager)
var _unit_lookup: Callable

# ============================================================================
# INITIALIZATION
# ============================================================================

## Initialize with a function to look up unit data by ID
## The callable should take a unit_id (String) and return a Dictionary with:
##   - speed: int (unit's speed/agility stat)
##   - is_ally: bool
##   - Any other unit data needed
func initialize(unit_lookup: Callable) -> void:
	_unit_lookup = unit_lookup
	_turn_queue.clear()


## Add a unit to the turn queue with initial ticks based on speed
func add_unit(unit_id: String, speed: int) -> void:
	var initial_ticks = calculate_base_ticks(speed)
	var entry = TurnEntry.new(unit_id, initial_ticks, speed)
	_turn_queue.append(entry)
	_sort_queue()


## Remove a unit from the turn queue (e.g., when defeated)
func remove_unit(unit_id: String) -> void:
	_turn_queue = _turn_queue.filter(func(e): return e.unit_id != unit_id)

# ============================================================================
# CORE CTB LOGIC
# ============================================================================

## Calculate base ticks until next turn based on speed
## Higher speed = fewer ticks = faster turns
func calculate_base_ticks(speed: int) -> int:
	var ticks = BASE_TICKS - (speed * SPEED_MULTIPLIER)
	return max(1, ticks)  # Minimum 1 tick


## Calculate ticks with AP bonus (remaining AP reduces ticks)
func calculate_ticks_with_ap_bonus(speed: int, remaining_ap: int) -> int:
	var base = calculate_base_ticks(speed)
	var ap_bonus = remaining_ap * AP_TO_TICKS_RATIO
	return max(1, base - ap_bonus)


## Get the unit whose turn it is (lowest ticks_remaining)
func get_current_unit_id() -> String:
	if _turn_queue.is_empty():
		return ""
	return _turn_queue[0].unit_id


## Advance the current unit's turn with optional AP bonus
## Call this when a unit ends their turn
func end_turn(unit_id: String, speed: int, remaining_ap: int = 0) -> void:
	# Normalize first: advance time so the acting unit reaches 0
	# This ensures other units' ticks reflect the time that passed
	_normalize_queue()

	# Now set new ticks for the acting unit (placed at back of queue)
	for entry in _turn_queue:
		if entry.unit_id == unit_id:
			var new_ticks = calculate_ticks_with_ap_bonus(speed, remaining_ap)
			entry.ticks_remaining = new_ticks
			entry.speed = speed  # Update in case speed changed
			entry._random_tiebreaker = randf()  # New random for future ties
			break

	_sort_queue()


## Simulate what the turn order would look like if a unit used X remaining AP
## Returns array of unit_ids in predicted order (up to TURN_ORDER_DISPLAY_COUNT)
func preview_turn_order(acting_unit_id: String = "", remaining_ap: int = 0, acting_unit_speed: int = 0) -> Array[String]:
	# Create a copy of the queue for simulation
	var simulated: Array[Dictionary] = []

	for entry in _turn_queue:
		var sim_ticks = entry.ticks_remaining

		# If this is the acting unit, calculate their new position
		if entry.unit_id == acting_unit_id and acting_unit_speed > 0:
			sim_ticks = calculate_ticks_with_ap_bonus(acting_unit_speed, remaining_ap)

		simulated.append({
			"unit_id": entry.unit_id,
			"ticks": sim_ticks,
			"speed": entry.speed,
			"random": entry._random_tiebreaker
		})

	# Sort simulation
	simulated.sort_custom(_compare_simulated_entries)

	# Build preview by simulating turns
	var preview: Array[String] = []
	var turn_count = 0

	while preview.size() < TURN_ORDER_DISPLAY_COUNT and not simulated.is_empty():
		# Normalize to bring first unit to 0
		var min_ticks = simulated[0].ticks
		for sim in simulated:
			sim.ticks -= min_ticks

		# First unit acts
		var acting = simulated[0]
		preview.append(acting.unit_id)

		# Give them new ticks (use base calculation for preview)
		acting.ticks = calculate_base_ticks(acting.speed)
		acting.random = randf()

		# Re-sort
		simulated.sort_custom(_compare_simulated_entries)

		turn_count += 1
		if turn_count > 100:  # Safety limit
			break

	return preview


## Get current turn order preview (no hypothetical changes)
func get_turn_order_preview() -> Array[String]:
	return preview_turn_order()

# ============================================================================
# INTERNAL HELPERS
# ============================================================================

## Sort the queue by ticks_remaining, then by speed (higher first), then random
func _sort_queue() -> void:
	_turn_queue.sort_custom(_compare_entries)


func _compare_entries(a: TurnEntry, b: TurnEntry) -> bool:
	# Lower ticks = goes first
	if a.ticks_remaining != b.ticks_remaining:
		return a.ticks_remaining < b.ticks_remaining
	# Higher speed = goes first (tie-breaker)
	if a.speed != b.speed:
		return a.speed > b.speed
	# Random tie-breaker
	return a._random_tiebreaker < b._random_tiebreaker


func _compare_simulated_entries(a: Dictionary, b: Dictionary) -> bool:
	if a.ticks != b.ticks:
		return a.ticks < b.ticks
	if a.speed != b.speed:
		return a.speed > b.speed
	return a.random < b.random


## Normalize queue so the first unit has 0 ticks
func _normalize_queue() -> void:
	if _turn_queue.is_empty():
		return

	_sort_queue()
	var min_ticks = _turn_queue[0].ticks_remaining

	for entry in _turn_queue:
		entry.ticks_remaining -= min_ticks

# ============================================================================
# DEBUG / INSPECTION
# ============================================================================

## Get debug info about current queue state
func get_debug_state() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for entry in _turn_queue:
		result.append({
			"unit_id": entry.unit_id,
			"ticks_remaining": entry.ticks_remaining,
			"speed": entry.speed
		})
	return result
