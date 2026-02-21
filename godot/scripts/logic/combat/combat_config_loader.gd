class_name CombatConfigLoader
extends RefCounted
## CombatConfigLoader - Loads and caches combat configuration from JSON
## Provides typed getters for all combat balance values

const CONFIG_PATH = "res://data/combat/combat_config.json"

static var _config: Dictionary = {}
static var _loaded: bool = false


## Load config from file (cached after first load)
static func _ensure_loaded() -> void:
	if _loaded:
		return

	if not FileAccess.file_exists(CONFIG_PATH):
		push_error("Combat config not found: " + CONFIG_PATH)
		return

	var file = FileAccess.open(CONFIG_PATH, FileAccess.READ)
	if not file:
		push_error("Failed to open combat config: " + CONFIG_PATH)
		return

	var json = JSON.new()
	var result = json.parse(file.get_as_text())
	file.close()

	if result != OK:
		push_error("Failed to parse combat config: " + json.get_error_message())
		return

	_config = json.data
	_loaded = true


## Force reload config (useful for hot-reloading during testing)
static func reload() -> void:
	_loaded = false
	_config = {}
	_ensure_loaded()


## Get grid dimensions as Vector2i(columns, rows)
static func get_grid_size() -> Vector2i:
	_ensure_loaded()
	var grid = _config.get("grid", {})
	return Vector2i(grid.get("columns", 10), grid.get("rows", 6))


## Get cell size as Vector2
static func get_cell_size() -> Vector2:
	_ensure_loaded()
	var grid = _config.get("grid", {})
	var size = grid.get("cell_size", [48, 48])
	return Vector2(size[0], size[1])


## Get cell gap
static func get_cell_gap() -> float:
	_ensure_loaded()
	var grid = _config.get("grid", {})
	return grid.get("cell_gap", 4)


## Get a balance value by key with default fallback
static func get_balance(key: String, default_value: float = 0.0) -> float:
	_ensure_loaded()
	var balance = _config.get("balance", {})
	return balance.get(key, default_value)


## Calculate movement range for a given agility stat
## Formula: floor(agility / agility_divisor) + base_range
static func get_movement_range(agility: int) -> int:
	_ensure_loaded()
	var movement = _config.get("movement", {})
	var base_range = movement.get("base_range", 1)
	var divisor = movement.get("agility_divisor", 2)
	return int(floor(float(agility) / divisor)) + base_range
