extends Node
## SaveManager - Handles saving and loading game state
## Stores party, story flags, consequences, and progress

const SAVE_DIR = "user://saves/"
const SAVE_FILE_EXTENSION = ".disrupt"

var current_slot: int = 0


func _ready() -> void:
	print("SaveManager initialized")
	_ensure_save_directory()


func _ensure_save_directory() -> void:
	var dir = DirAccess.open("user://")
	if dir and not dir.dir_exists("saves"):
		dir.make_dir("saves")


func get_save_path(slot: int = -1) -> String:
	if slot < 0:
		slot = current_slot
	return SAVE_DIR + "save_%d%s" % [slot, SAVE_FILE_EXTENSION]


func save_game(slot: int = -1) -> bool:
	if slot < 0:
		slot = current_slot

	var save_data = _collect_save_data()
	var json_string = JSON.stringify(save_data, "\t")

	var file = FileAccess.open(get_save_path(slot), FileAccess.WRITE)
	if file:
		file.store_string(json_string)
		file.close()
		EventBus.save_completed.emit(true)
		print("Game saved to slot %d" % slot)
		return true
	else:
		push_error("Failed to save game to slot %d" % slot)
		EventBus.save_completed.emit(false)
		return false


func load_game(slot: int = -1) -> bool:
	if slot < 0:
		slot = current_slot

	var file = FileAccess.open(get_save_path(slot), FileAccess.READ)
	if not file:
		push_error("Failed to load game from slot %d - file not found" % slot)
		EventBus.load_completed.emit(false)
		return false

	var json_string = file.get_as_text()
	file.close()

	var json = JSON.new()
	var parse_result = json.parse(json_string)
	if parse_result != OK:
		push_error("Failed to parse save file")
		EventBus.load_completed.emit(false)
		return false

	var save_data = json.data
	_apply_save_data(save_data)

	current_slot = slot
	EventBus.load_completed.emit(true)
	print("Game loaded from slot %d" % slot)
	return true


func save_exists(slot: int) -> bool:
	return FileAccess.file_exists(get_save_path(slot))


func delete_save(slot: int) -> bool:
	var path = get_save_path(slot)
	if FileAccess.file_exists(path):
		var dir = DirAccess.open(SAVE_DIR)
		if dir:
			dir.remove("save_%d%s" % [slot, SAVE_FILE_EXTENSION])
			return true
	return false


func get_save_info(slot: int) -> Dictionary:
	if not save_exists(slot):
		return {}

	var file = FileAccess.open(get_save_path(slot), FileAccess.READ)
	if not file:
		return {}

	var json_string = file.get_as_text()
	file.close()

	var json = JSON.new()
	if json.parse(json_string) != OK:
		return {}

	var data = json.data
	return {
		"slot": slot,
		"timestamp": data.get("timestamp", "Unknown"),
		"playtime": data.get("playtime", 0),
		"location": data.get("location", "Unknown"),
		"party_level": data.get("party_level", 1),
	}


func _collect_save_data() -> Dictionary:
	return {
		"version": "0.1.0",
		"timestamp": Time.get_datetime_string_from_system(),
		"playtime": 0,  # TODO: Track playtime
		"location": "Unknown",  # TODO: Get current location name
		"party_level": 1,  # TODO: Calculate average party level
		"party": GameManager.party,
		"party_position": {
			"x": GameManager.party_position.x,
			"y": GameManager.party_position.y,
		},
		"story_flags": GameManager.story_flags,
		"consequence_values": GameManager.consequence_values,
		"current_state": GameManager.current_state,
	}


func _apply_save_data(data: Dictionary) -> void:
	if data.has("party"):
		GameManager.party = data.party

	if data.has("party_position"):
		GameManager.party_position = Vector2(
			data.party_position.x,
			data.party_position.y
		)

	if data.has("story_flags"):
		GameManager.story_flags = data.story_flags

	if data.has("consequence_values"):
		GameManager.consequence_values = data.consequence_values

	GameManager.party_updated.emit()
