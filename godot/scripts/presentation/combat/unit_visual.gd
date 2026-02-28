extends Node2D
class_name UnitVisual
## UnitVisual - Persistent visual representation of a combat unit
## Includes colored border, HP/MP bars, status dots, and damage flash

# Base proportions (will scale with cell size)
const BASE_UNIT_WIDTH = 56.0
const BASE_UNIT_HEIGHT = 70.0
const BASE_BAR_HEIGHT = 6.0
const BASE_BAR_WIDTH = 52.0
const BASE_BAR_OFFSET_X = 2.0
const BASE_STATUS_DOT_SIZE = 6.0

# Dynamic sizes (calculated from cell size)
var UNIT_WIDTH: float = 56.0
var UNIT_HEIGHT: float = 70.0
var BAR_HEIGHT: float = 6.0
var BAR_WIDTH: float = 52.0
var BAR_OFFSET_X: float = 2.0
var STATUS_DOT_SIZE: float = 6.0

var unit_id: String = ""
var is_ally: bool = true
var cell_size: Vector2 = Vector2(48, 48)

# Child nodes
var border_rect: Polygon2D
var body_rect: Polygon2D
var name_label: Label
var hp_bar_bg: Polygon2D
var hp_bar_fill: Polygon2D
var mp_bar_bg: Polygon2D
var mp_bar_fill: Polygon2D
var flash_overlay: Polygon2D
var status_container: Node2D
var soil_badge: Label

# Flash state
var flash_timer: float = 0.0
const FLASH_DURATION = 0.15


func setup(unit: Dictionary, ally: bool, p_cell_size: Vector2 = Vector2(48, 48)) -> void:
	unit_id = unit.get("id", "")
	is_ally = ally
	cell_size = p_cell_size

	# Calculate scaled sizes based on cell size
	_calculate_scaled_sizes()

	var border_color = Color(0.3, 0.5, 0.8) if is_ally else Color(0.8, 0.2, 0.2)
	var body_color = Color(0.12, 0.12, 0.18)

	# Border (slightly larger than body)
	border_rect = Polygon2D.new()
	border_rect.polygon = PackedVector2Array([
		Vector2(0, 0), Vector2(UNIT_WIDTH, 0),
		Vector2(UNIT_WIDTH, UNIT_HEIGHT), Vector2(0, UNIT_HEIGHT)
	])
	border_rect.color = border_color
	add_child(border_rect)

	# Body (inset by 2px)
	body_rect = Polygon2D.new()
	body_rect.polygon = PackedVector2Array([
		Vector2(2, 2), Vector2(UNIT_WIDTH - 2, 2),
		Vector2(UNIT_WIDTH - 2, UNIT_HEIGHT - 2), Vector2(2, UNIT_HEIGHT - 2)
	])
	body_rect.color = body_color
	add_child(body_rect)

	# Name label (centered above unit)
	name_label = Label.new()
	name_label.text = unit.get("name", "???")
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_label.add_theme_font_size_override("font_size", 11)
	name_label.add_theme_color_override("font_color", Color.WHITE)
	name_label.position = Vector2(-2, -16)
	name_label.size = Vector2(UNIT_WIDTH + 4, 16)
	add_child(name_label)

	# HP bar background
	var hp_y = UNIT_HEIGHT - BAR_HEIGHT * 2 - 4
	hp_bar_bg = _create_bar(BAR_OFFSET_X, hp_y, BAR_WIDTH, BAR_HEIGHT, Color(0.2, 0.2, 0.2))
	add_child(hp_bar_bg)

	# HP bar fill
	hp_bar_fill = _create_bar(BAR_OFFSET_X, hp_y, BAR_WIDTH, BAR_HEIGHT, Color(0.2, 0.8, 0.2))
	add_child(hp_bar_fill)

	# MP bar background
	var mp_y = UNIT_HEIGHT - BAR_HEIGHT - 2
	mp_bar_bg = _create_bar(BAR_OFFSET_X, mp_y, BAR_WIDTH, BAR_HEIGHT, Color(0.2, 0.2, 0.2))
	add_child(mp_bar_bg)

	# MP bar fill
	mp_bar_fill = _create_bar(BAR_OFFSET_X, mp_y, BAR_WIDTH, BAR_HEIGHT, Color(0.2, 0.4, 0.9))
	add_child(mp_bar_fill)

	# Flash overlay (invisible by default)
	flash_overlay = Polygon2D.new()
	flash_overlay.polygon = PackedVector2Array([
		Vector2(2, 2), Vector2(UNIT_WIDTH - 2, 2),
		Vector2(UNIT_WIDTH - 2, UNIT_HEIGHT - 2), Vector2(2, UNIT_HEIGHT - 2)
	])
	flash_overlay.color = Color(1.0, 1.0, 1.0, 0.0)
	add_child(flash_overlay)

	# Status effect container
	status_container = Node2D.new()
	status_container.position = Vector2(0, UNIT_HEIGHT + 2)
	add_child(status_container)

	# Soil intensity badge (hidden by default)
	soil_badge = Label.new()
	soil_badge.text = ""
	soil_badge.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	soil_badge.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	soil_badge.add_theme_font_size_override("font_size", 10)
	soil_badge.add_theme_color_override("font_color", Color(0.95, 0.85, 0.3))
	soil_badge.size = Vector2(16, 16)
	soil_badge.position = Vector2(UNIT_WIDTH - 16, -2)
	soil_badge.visible = false
	add_child(soil_badge)

	update_stats(unit)


func _calculate_scaled_sizes() -> void:
	# Units (including bars) should fit within cells with padding
	# Use 85% of cell dimensions to leave padding
	var available_width = cell_size.x * 0.85
	var available_height = cell_size.y * 0.85

	# Calculate scale factor that fits both width AND height
	var width_scale = available_width / BASE_UNIT_WIDTH
	var height_scale = available_height / BASE_UNIT_HEIGHT

	# Use the smaller scale to ensure unit fits in both dimensions
	var scale_factor = min(width_scale, height_scale)

	# Apply uniform scaling to maintain aspect ratio
	UNIT_WIDTH = BASE_UNIT_WIDTH * scale_factor
	UNIT_HEIGHT = BASE_UNIT_HEIGHT * scale_factor
	BAR_HEIGHT = BASE_BAR_HEIGHT * scale_factor
	BAR_WIDTH = BASE_BAR_WIDTH * scale_factor
	BAR_OFFSET_X = BASE_BAR_OFFSET_X * scale_factor
	STATUS_DOT_SIZE = BASE_STATUS_DOT_SIZE * scale_factor


func update_scale(p_cell_size: Vector2) -> void:
	"""Update the visual scale when cell size changes (e.g., window resize)"""
	cell_size = p_cell_size
	_calculate_scaled_sizes()

	# Rebuild all visuals with new sizes
	if border_rect:
		border_rect.polygon = PackedVector2Array([
			Vector2(0, 0), Vector2(UNIT_WIDTH, 0),
			Vector2(UNIT_WIDTH, UNIT_HEIGHT), Vector2(0, UNIT_HEIGHT)
		])

	if body_rect:
		body_rect.polygon = PackedVector2Array([
			Vector2(2, 2), Vector2(UNIT_WIDTH - 2, 2),
			Vector2(UNIT_WIDTH - 2, UNIT_HEIGHT - 2), Vector2(2, UNIT_HEIGHT - 2)
		])

	if name_label:
		name_label.position = Vector2(-2, -16 * (cell_size.x / 48.0))
		name_label.size = Vector2(UNIT_WIDTH + 4, 16 * (cell_size.x / 48.0))
		name_label.add_theme_font_size_override("font_size", int(11 * (cell_size.x / 48.0)))

	if flash_overlay:
		flash_overlay.polygon = PackedVector2Array([
			Vector2(2, 2), Vector2(UNIT_WIDTH - 2, 2),
			Vector2(UNIT_WIDTH - 2, UNIT_HEIGHT - 2), Vector2(2, UNIT_HEIGHT - 2)
		])

	if status_container:
		status_container.position = Vector2(0, UNIT_HEIGHT + 2)

	# Recalculate bar positions
	var hp_y = UNIT_HEIGHT - BAR_HEIGHT * 2 - 4
	if hp_bar_bg:
		hp_bar_bg.position = Vector2(BAR_OFFSET_X, hp_y)
		hp_bar_bg.polygon = PackedVector2Array([
			Vector2(0, 0), Vector2(BAR_WIDTH, 0), Vector2(BAR_WIDTH, BAR_HEIGHT), Vector2(0, BAR_HEIGHT)
		])
	if hp_bar_fill:
		hp_bar_fill.position = Vector2(BAR_OFFSET_X, hp_y)

	var mp_y = UNIT_HEIGHT - BAR_HEIGHT - 2
	if mp_bar_bg:
		mp_bar_bg.position = Vector2(BAR_OFFSET_X, mp_y)
		mp_bar_bg.polygon = PackedVector2Array([
			Vector2(0, 0), Vector2(BAR_WIDTH, 0), Vector2(BAR_WIDTH, BAR_HEIGHT), Vector2(0, BAR_HEIGHT)
		])
	if mp_bar_fill:
		mp_bar_fill.position = Vector2(BAR_OFFSET_X, mp_y)


func update_stats(unit: Dictionary) -> void:
	var current_hp = unit.get("current_hp", 0)
	var max_hp = unit.get("max_hp", 1)
	var current_mp = unit.get("current_mp", 0)
	var max_mp = unit.get("max_mp", 1)

	# Update HP bar width and color
	var hp_ratio = float(current_hp) / float(max(max_hp, 1))
	_update_bar_fill(hp_bar_fill, hp_ratio, BAR_OFFSET_X, hp_bar_bg.position.y)

	# HP color gradient: green -> yellow -> red
	if hp_ratio > 0.5:
		hp_bar_fill.color = Color(0.2, 0.8, 0.2).lerp(Color(0.9, 0.9, 0.2), 1.0 - (hp_ratio - 0.5) * 2.0)
	else:
		hp_bar_fill.color = Color(0.9, 0.9, 0.2).lerp(Color(0.8, 0.15, 0.15), 1.0 - hp_ratio * 2.0)

	# Update MP bar
	var mp_ratio = float(current_mp) / float(max(max_mp, 1))
	_update_bar_fill(mp_bar_fill, mp_ratio, BAR_OFFSET_X, mp_bar_bg.position.y)


func update_statuses(statuses: Array) -> void:
	# Clear existing dots
	for child in status_container.get_children():
		child.queue_free()

	# Add dots for each status
	for i in range(statuses.size()):
		var status = statuses[i]
		var dot = Polygon2D.new()
		var x = i * (STATUS_DOT_SIZE + 2)
		dot.polygon = PackedVector2Array([
			Vector2(x, 0), Vector2(x + STATUS_DOT_SIZE, 0),
			Vector2(x + STATUS_DOT_SIZE, STATUS_DOT_SIZE), Vector2(x, STATUS_DOT_SIZE)
		])
		dot.color = _get_status_color(status.get("status", ""))
		status_container.add_child(dot)


func update_soil(intensity: int) -> void:
	if soil_badge == null:
		return
	if intensity > 0:
		soil_badge.text = str(intensity)
		soil_badge.visible = true
	else:
		soil_badge.visible = false


func flash_damage() -> void:
	flash_timer = FLASH_DURATION
	flash_overlay.color = Color(1.0, 1.0, 1.0, 0.6)


func _process(delta: float) -> void:
	if flash_timer > 0:
		flash_timer -= delta
		var alpha = (flash_timer / FLASH_DURATION) * 0.6
		flash_overlay.color = Color(1.0, 1.0, 1.0, max(0.0, alpha))
		if flash_timer <= 0:
			flash_overlay.color = Color(1.0, 1.0, 1.0, 0.0)


func _create_bar(x: float, y: float, w: float, h: float, color: Color) -> Polygon2D:
	var bar = Polygon2D.new()
	bar.polygon = PackedVector2Array([
		Vector2(0, 0), Vector2(w, 0), Vector2(w, h), Vector2(0, h)
	])
	bar.position = Vector2(x, y)
	bar.color = color
	return bar


func _update_bar_fill(bar: Polygon2D, ratio: float, x: float, y: float) -> void:
	var fill_width = BAR_WIDTH * clampf(ratio, 0.0, 1.0)
	bar.polygon = PackedVector2Array([
		Vector2(0, 0), Vector2(fill_width, 0),
		Vector2(fill_width, BAR_HEIGHT), Vector2(0, BAR_HEIGHT)
	])
	bar.position = Vector2(x, y)


func _get_status_color(status_name: String) -> Color:
	match status_name:
		"defending":
			return Color(0.3, 0.6, 1.0)       # Blue
		"taunted":
			return Color(1.0, 0.3, 0.1)       # Orange-red
		"iron_skin":
			return Color(0.6, 0.6, 0.7)       # Silver
		"inspired":
			return Color(1.0, 0.9, 0.2)       # Gold
		"hamstrung":
			return Color(0.6, 0.2, 0.6)       # Purple
		"elemental_attunement":
			return Color(0.2, 0.9, 0.9)       # Cyan
		"poisoned", "burning":
			return Color(0.1, 0.7, 0.1)       # Green
		_:
			return Color(0.8, 0.8, 0.2)       # Default yellow
