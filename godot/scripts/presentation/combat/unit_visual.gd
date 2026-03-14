extends Node2D
class_name UnitVisual
## UnitVisual - Persistent visual representation of a combat unit
## All elements (name, bars, status dots) fit within the unit body rect.
## Displays animated knight sprites for party members, static sprites for enemies.

const CombatConfigLoaderClass = preload("res://scripts/logic/combat/combat_config_loader.gd")

# Sprite config (loaded once, shared across instances)
static var _sprite_config: Dictionary = {}
static var _sprite_config_loaded: bool = false

# Base proportions (will scale with cell size)
const BASE_UNIT_WIDTH = 56.0
const BASE_UNIT_HEIGHT = 70.0
const BASE_BAR_HEIGHT = 5.0
const BASE_BAR_WIDTH = 52.0
const BASE_BAR_OFFSET_X = 2.0
const BASE_STATUS_DOT_SIZE = 5.0
const BASE_NAME_HEIGHT = 14.0
const BASE_BAR_GAP = 1.0
const BASE_INSET = 2.0

# Dynamic sizes (calculated from cell size)
var UNIT_WIDTH: float = 56.0
var UNIT_HEIGHT: float = 70.0
var BAR_HEIGHT: float = 5.0
var BAR_WIDTH: float = 52.0
var BAR_OFFSET_X: float = 2.0
var STATUS_DOT_SIZE: float = 5.0
var NAME_HEIGHT: float = 14.0
var BAR_GAP: float = 1.0
var INSET: float = 2.0

var unit_id: String = ""
var is_ally: bool = true
var has_burst: bool = false
var cell_size: Vector2 = Vector2(48, 48)

# Child nodes
var border_rect: Polygon2D
var body_rect: Polygon2D
var unit_sprite: Sprite2D
var name_label: Label
var hp_bar_bg: Polygon2D
var hp_bar_fill: Polygon2D
var mp_bar_bg: Polygon2D
var mp_bar_fill: Polygon2D
var burst_bar_bg: Polygon2D
var burst_bar_fill: Polygon2D
var burst_info_label: Label
var flash_overlay: Polygon2D
var status_container: Node2D
var soil_badge: Label

# Sprite animation state
var _anim_frames: int = 0
var _anim_fps: float = 0.0
var _anim_timer: float = 0.0
var _anim_current_frame: int = 0
var _frame_width: int = 0
var _frame_height: int = 0
var _content_rect: Rect2 = Rect2()  # Visible content region within frame (x, y, w, h)
var _idle_content_rect: Rect2 = Rect2()  # Idle content rect used as scaling reference
var _has_sprite: bool = false
var _sprite_folder: String = ""
var _animations: Dictionary = {}  # Full animation config from sprite_config
var _current_anim: String = "idle"
var _anim_looping: bool = true
var _oneshot_timer: float = -1.0  # Timer for single-frame animations
const ONESHOT_HOLD_DURATION = 0.35  # How long to hold a single-frame animation

signal animation_finished(anim_name: String)

# Flash state
var flash_timer: float = 0.0
const FLASH_DURATION = 0.15

enum DetailLevel { FULL, REDUCED, MINIMAL }
var detail_level: DetailLevel = DetailLevel.FULL


static func _load_sprite_config() -> void:
	if _sprite_config_loaded:
		return
	var file = FileAccess.open("res://data/sprites/sprite_config.json", FileAccess.READ)
	if file:
		var json = JSON.new()
		if json.parse(file.get_as_text()) == OK:
			_sprite_config = json.data
	_sprite_config_loaded = true


func setup(unit: Dictionary, ally: bool, p_cell_size: Vector2 = Vector2(48, 48)) -> void:
	unit_id = unit.get("id", "")
	is_ally = ally
	has_burst = not unit.get("burst_mode", {}).is_empty()
	cell_size = p_cell_size
	_calculate_scaled_sizes()
	_load_sprite_config()

	var border_color = Color(0.3, 0.5, 0.8) if is_ally else Color(0.8, 0.2, 0.2)
	var body_color = Color(0.12, 0.12, 0.18)

	# Border
	border_rect = Polygon2D.new()
	border_rect.polygon = _rect(0, 0, UNIT_WIDTH, UNIT_HEIGHT)
	border_rect.color = border_color
	add_child(border_rect)

	# Body (inset)
	body_rect = Polygon2D.new()
	body_rect.polygon = _rect(INSET, INSET, UNIT_WIDTH - INSET, UNIT_HEIGHT - INSET)
	body_rect.color = body_color
	add_child(body_rect)

	# Unit sprite (on top of body, behind UI elements)
	_setup_sprite(unit)

	# Name label (inside top of body, with background for readability over sprite)
	name_label = Label.new()
	name_label.text = unit.get("name", "???")
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	if _has_sprite:
		var name_bg = StyleBoxFlat.new()
		name_bg.bg_color = Color(0.0, 0.0, 0.0, 0.6)
		name_label.add_theme_stylebox_override("normal", name_bg)
	add_child(name_label)

	# Bars are stacked from bottom of body upward:
	# Bottom:   MP bar
	# Above MP: HP bar
	# Above HP: Burst bar (allies only)
	var bar_bg_color = Color(0.1, 0.1, 0.1, 0.85) if _has_sprite else Color(0.2, 0.2, 0.2)
	var bar_bottom = UNIT_HEIGHT - INSET

	# MP bar
	var mp_y = bar_bottom - BAR_HEIGHT
	mp_bar_bg = _create_bar(BAR_OFFSET_X, mp_y, BAR_WIDTH, BAR_HEIGHT, bar_bg_color)
	add_child(mp_bar_bg)
	mp_bar_fill = _create_bar(BAR_OFFSET_X, mp_y, BAR_WIDTH, BAR_HEIGHT, Color(0.2, 0.4, 0.9))
	add_child(mp_bar_fill)

	# HP bar
	var hp_y = mp_y - BAR_HEIGHT - BAR_GAP
	hp_bar_bg = _create_bar(BAR_OFFSET_X, hp_y, BAR_WIDTH, BAR_HEIGHT, bar_bg_color)
	add_child(hp_bar_bg)
	hp_bar_fill = _create_bar(BAR_OFFSET_X, hp_y, BAR_WIDTH, BAR_HEIGHT, Color(0.2, 0.8, 0.2))
	add_child(hp_bar_fill)

	# Burst bar (units with burst_mode data)
	if has_burst:
		var burst_y = hp_y - BAR_HEIGHT - BAR_GAP
		burst_bar_bg = _create_bar(BAR_OFFSET_X, burst_y, BAR_WIDTH, BAR_HEIGHT, bar_bg_color)
		add_child(burst_bar_bg)
		burst_bar_fill = _create_bar(BAR_OFFSET_X, burst_y, 0, BAR_HEIGHT, Color(0.9, 0.75, 0.1))
		add_child(burst_bar_fill)

		# Info label overlaid on burst bar area
		burst_info_label = Label.new()
		burst_info_label.text = ""
		burst_info_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		burst_info_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		burst_info_label.clip_text = true
		burst_info_label.add_theme_color_override("font_color", Color(1.0, 0.95, 0.7))
		add_child(burst_info_label)

	# Flash overlay
	flash_overlay = Polygon2D.new()
	flash_overlay.polygon = _rect(INSET, INSET, UNIT_WIDTH - INSET, UNIT_HEIGHT - INSET)
	flash_overlay.color = Color(1.0, 1.0, 1.0, 0.0)
	add_child(flash_overlay)

	# Status dots (inside body, between name and bars)
	status_container = Node2D.new()
	add_child(status_container)

	# Soil intensity badge (inside body, top-right)
	soil_badge = Label.new()
	soil_badge.text = ""
	soil_badge.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	soil_badge.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	soil_badge.add_theme_color_override("font_color", Color(0.95, 0.85, 0.3))
	soil_badge.visible = false
	add_child(soil_badge)

	_apply_layout()
	update_stats(unit)


func _setup_sprite(unit: Dictionary) -> void:
	var uid = unit.get("id", "")
	var sprite_data: Dictionary = {}

	# Check party config first, then enemies
	if _sprite_config.has("party") and _sprite_config["party"].has(uid):
		sprite_data = _sprite_config["party"][uid]
		_setup_animated_sprite(sprite_data)
	elif _sprite_config.has("enemies") and _sprite_config["enemies"].has(uid):
		sprite_data = _sprite_config["enemies"][uid]
		_setup_static_sprite(sprite_data)


func _setup_animated_sprite(config: Dictionary) -> void:
	var folder = config.get("sprite_folder", "")
	var animations = config.get("animations", {})
	if not animations.has("idle") or folder.is_empty():
		return

	_sprite_folder = folder
	_animations = animations
	_frame_width = config.get("frame_width", 120)
	_frame_height = config.get("frame_height", 80)

	var idle_anim = animations["idle"]
	var sheet_path = folder + "/" + idle_anim.get("sheet", "")
	var texture = load(sheet_path)
	if texture == null:
		return

	var cr = idle_anim.get("content_rect", [])
	if cr.size() == 4:
		_content_rect = Rect2(cr[0], cr[1], cr[2], cr[3])
	else:
		_content_rect = Rect2(0, 0, _frame_width, _frame_height)
	_idle_content_rect = _content_rect
	_anim_frames = idle_anim.get("frames", 1)
	_anim_fps = idle_anim.get("fps", 8.0)
	_anim_current_frame = 0
	_anim_timer = 0.0
	_current_anim = "idle"
	_anim_looping = true

	unit_sprite = Sprite2D.new()
	unit_sprite.texture = texture
	unit_sprite.hframes = _anim_frames
	unit_sprite.vframes = 1
	unit_sprite.frame = 0
	unit_sprite.centered = true
	# Flip enemies to face left (party faces right by default)
	if not is_ally:
		unit_sprite.flip_h = true
	add_child(unit_sprite)
	_has_sprite = true
	_apply_sprite_layout()


func _setup_static_sprite(config: Dictionary) -> void:
	var sprite_path = config.get("sprite", "")
	if sprite_path.is_empty():
		return

	var texture = load(sprite_path)
	if texture == null:
		return

	unit_sprite = Sprite2D.new()
	unit_sprite.texture = texture
	unit_sprite.centered = true
	# Flip enemies to face left
	if not is_ally:
		unit_sprite.flip_h = true
	add_child(unit_sprite)
	_has_sprite = true
	_anim_frames = 0  # No animation
	_apply_sprite_layout()


func _apply_sprite_layout() -> void:
	if not unit_sprite:
		return

	if UNIT_WIDTH <= 0 or UNIT_HEIGHT <= 0:
		unit_sprite.visible = false
		return

	# Get frame dimensions and content region
	var tex_w: float
	var tex_h: float
	var content: Rect2
	if _anim_frames > 0:
		tex_w = float(_frame_width)
		tex_h = float(_frame_height)
		content = _content_rect
	else:
		tex_w = float(unit_sprite.texture.get_width())
		tex_h = float(unit_sprite.texture.get_height())
		content = Rect2(0, 0, tex_w, tex_h)

	# Scale based on idle content rect so the character body stays the same size
	# across all animations. Non-idle animations may extend beyond the unit rect.
	var scale_ref = _idle_content_rect if _idle_content_rect.size.x > 0 else content
	var scale_x = UNIT_WIDTH / scale_ref.size.x
	var scale_y = UNIT_HEIGHT / scale_ref.size.y
	var sprite_scale = min(scale_x, scale_y)
	unit_sprite.scale = Vector2(sprite_scale, sprite_scale)

	# Offset so the current animation's content center aligns with the rect center.
	# With centered=true, the full frame center sits at the sprite position.
	# We shift by the difference between frame center and content center.
	var frame_center = Vector2(tex_w / 2.0, tex_h / 2.0)
	var content_center = content.position + content.size / 2.0
	var offset = (frame_center - content_center) * sprite_scale
	unit_sprite.position = Vector2(UNIT_WIDTH / 2.0, UNIT_HEIGHT / 2.0) + offset
	unit_sprite.visible = true


func _calculate_scaled_sizes() -> void:
	var available_width = cell_size.x * 0.90
	var available_height = cell_size.y * 0.90
	var width_scale = available_width / BASE_UNIT_WIDTH
	var height_scale = available_height / BASE_UNIT_HEIGHT
	var scale_factor = min(width_scale, height_scale)

	UNIT_WIDTH = BASE_UNIT_WIDTH * scale_factor
	UNIT_HEIGHT = BASE_UNIT_HEIGHT * scale_factor
	BAR_HEIGHT = BASE_BAR_HEIGHT * scale_factor
	BAR_WIDTH = BASE_BAR_WIDTH * scale_factor
	BAR_OFFSET_X = BASE_BAR_OFFSET_X * scale_factor
	STATUS_DOT_SIZE = BASE_STATUS_DOT_SIZE * scale_factor
	NAME_HEIGHT = BASE_NAME_HEIGHT * scale_factor
	BAR_GAP = BASE_BAR_GAP * scale_factor
	INSET = BASE_INSET * scale_factor


## Apply layout positions for all elements based on current scaled sizes
func _apply_layout() -> void:
	var font_size = max(8, int(10 * (UNIT_HEIGHT / BASE_UNIT_HEIGHT)))
	var small_font = max(6, int(8 * (UNIT_HEIGHT / BASE_UNIT_HEIGHT)))

	# Bars stacked from bottom
	var bar_bottom = UNIT_HEIGHT - INSET

	var mp_y = bar_bottom - BAR_HEIGHT
	var hp_y = mp_y - BAR_HEIGHT - BAR_GAP
	var burst_y = hp_y - BAR_HEIGHT - BAR_GAP

	# Name label: inside top, height fills space above bars
	var bars_top = burst_y if has_burst else hp_y
	var name_available_height = bars_top - INSET - BAR_GAP
	if name_label:
		name_label.position = Vector2(INSET, INSET)
		name_label.size = Vector2(UNIT_WIDTH - INSET * 2, name_available_height)
		name_label.add_theme_font_size_override("font_size", font_size)

	if mp_bar_bg:
		mp_bar_bg.position = Vector2(BAR_OFFSET_X, mp_y)
		mp_bar_bg.polygon = _bar_poly(BAR_WIDTH, BAR_HEIGHT)
	if mp_bar_fill:
		mp_bar_fill.position = Vector2(BAR_OFFSET_X, mp_y)

	if hp_bar_bg:
		hp_bar_bg.position = Vector2(BAR_OFFSET_X, hp_y)
		hp_bar_bg.polygon = _bar_poly(BAR_WIDTH, BAR_HEIGHT)
	if hp_bar_fill:
		hp_bar_fill.position = Vector2(BAR_OFFSET_X, hp_y)

	if burst_bar_bg:
		burst_bar_bg.position = Vector2(BAR_OFFSET_X, burst_y)
		burst_bar_bg.polygon = _bar_poly(BAR_WIDTH, BAR_HEIGHT)
	if burst_bar_fill:
		burst_bar_fill.position = Vector2(BAR_OFFSET_X, burst_y)

	if burst_info_label:
		burst_info_label.position = Vector2(BAR_OFFSET_X, burst_y - NAME_HEIGHT)
		burst_info_label.size = Vector2(BAR_WIDTH, NAME_HEIGHT)
		burst_info_label.add_theme_font_size_override("font_size", small_font)

	# Status dots: just above the top bar
	var status_y = bars_top - STATUS_DOT_SIZE - BAR_GAP
	if status_container:
		status_container.position = Vector2(BAR_OFFSET_X, status_y)

	# Soil badge: top-right corner inside body
	if soil_badge:
		var badge_size = NAME_HEIGHT
		soil_badge.position = Vector2(UNIT_WIDTH - badge_size - INSET, INSET)
		soil_badge.size = Vector2(badge_size, badge_size)
		soil_badge.add_theme_font_size_override("font_size", small_font)

	# Update sprite layout when cell size changes
	_apply_sprite_layout()


func update_scale(p_cell_size: Vector2) -> void:
	cell_size = p_cell_size
	_calculate_scaled_sizes()

	if border_rect:
		border_rect.polygon = _rect(0, 0, UNIT_WIDTH, UNIT_HEIGHT)
	if body_rect:
		body_rect.polygon = _rect(INSET, INSET, UNIT_WIDTH - INSET, UNIT_HEIGHT - INSET)
	if flash_overlay:
		flash_overlay.polygon = _rect(INSET, INSET, UNIT_WIDTH - INSET, UNIT_HEIGHT - INSET)

	_apply_layout()
	update_detail_level(p_cell_size.y / 2.0)  # Approximate hex_size from cell height


func update_detail_level(hex_size: float) -> void:
	var new_level: DetailLevel
	if hex_size >= 40.0:
		new_level = DetailLevel.FULL
	elif hex_size >= 28.0:
		new_level = DetailLevel.REDUCED
	else:
		new_level = DetailLevel.MINIMAL

	if new_level == detail_level:
		return
	detail_level = new_level
	_apply_detail_level()


func _apply_detail_level() -> void:
	match detail_level:
		DetailLevel.FULL:
			if mp_bar_bg: mp_bar_bg.visible = true
			if mp_bar_fill: mp_bar_fill.visible = true
			if burst_bar_bg: burst_bar_bg.visible = true
			if burst_bar_fill: burst_bar_fill.visible = true
			if burst_info_label: burst_info_label.visible = true
			if status_container: status_container.visible = true
			if soil_badge: soil_badge.visible = true
		DetailLevel.REDUCED:
			if mp_bar_bg: mp_bar_bg.visible = true
			if mp_bar_fill: mp_bar_fill.visible = true
			if burst_bar_bg: burst_bar_bg.visible = true
			if burst_bar_fill: burst_bar_fill.visible = true
			if burst_info_label: burst_info_label.visible = false
			if status_container: status_container.visible = true
			if soil_badge: soil_badge.visible = false
		DetailLevel.MINIMAL:
			if mp_bar_bg: mp_bar_bg.visible = false
			if mp_bar_fill: mp_bar_fill.visible = false
			if burst_bar_bg: burst_bar_bg.visible = false
			if burst_bar_fill: burst_bar_fill.visible = false
			if burst_info_label: burst_info_label.visible = false
			if status_container: status_container.visible = false
			if soil_badge: soil_badge.visible = false


func update_stats(unit: Dictionary) -> void:
	var current_hp = unit.get("current_hp", 0)
	var max_hp = unit.get("max_hp", 1)
	var current_mp = unit.get("current_mp", 0)
	var max_mp = unit.get("max_mp", 1)

	# Update HP bar
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

	update_burst(unit)


func update_statuses(statuses: Array) -> void:
	for child in status_container.get_children():
		child.queue_free()

	for i in range(statuses.size()):
		var status = statuses[i]
		var dot = Polygon2D.new()
		var x = i * (STATUS_DOT_SIZE + 1)
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


func update_burst(unit: Dictionary) -> void:
	if not has_burst:
		return

	var gauge = unit.get("burst_gauge", 0)
	var max_gauge = CombatConfigLoaderClass.get_burst_max_gauge()
	var burst_active = unit.get("burst_active", false)
	var turns_remaining = unit.get("burst_turns_remaining", 0)

	# Update burst gauge bar fill
	if burst_bar_fill:
		var ratio = float(gauge) / float(max(max_gauge, 1))
		_update_bar_fill(burst_bar_fill, ratio, BAR_OFFSET_X, burst_bar_bg.position.y)

		if gauge >= max_gauge and not burst_active:
			burst_bar_fill.color = Color(1.0, 0.9, 0.3)  # Bright gold when ready
		else:
			burst_bar_fill.color = Color(0.9, 0.75, 0.1)  # Normal amber

	# Info label: turns remaining when active, gauge value when building
	if burst_info_label:
		if burst_active:
			burst_info_label.text = "B:%d" % turns_remaining
			burst_info_label.visible = true
		elif gauge > 0:
			burst_info_label.text = "%d/%d" % [gauge, max_gauge]
			burst_info_label.visible = true
		else:
			burst_info_label.visible = false

	# Gold border tint when burst is active
	if border_rect:
		if burst_active:
			border_rect.color = Color(1.0, 0.85, 0.2)
		else:
			border_rect.color = Color(0.3, 0.5, 0.8) if is_ally else Color(0.8, 0.2, 0.2)


func flash_damage() -> void:
	flash_timer = FLASH_DURATION
	flash_overlay.color = Color(1.0, 1.0, 1.0, 0.6)


## Play a named animation (e.g. "attack", "hit", "death"). Plays once then returns to idle.
## Returns immediately. Await animation_finished signal or use play_animation_async() to wait.
func play_animation(anim_name: String) -> void:
	if not _has_sprite or _sprite_folder.is_empty():
		_emit_finished_deferred.call_deferred(anim_name)
		return
	if not _animations.has(anim_name):
		_emit_finished_deferred.call_deferred(anim_name)
		return

	var anim_data = _animations[anim_name]
	var sheet_path = _sprite_folder + "/" + anim_data.get("sheet", "")
	var texture = load(sheet_path)
	if texture == null:
		_emit_finished_deferred.call_deferred(anim_name)
		return

	_current_anim = anim_name
	_anim_frames = anim_data.get("frames", 1)
	_anim_fps = anim_data.get("fps", 8.0)
	_anim_current_frame = 0
	_anim_timer = 0.0
	_anim_looping = false
	_oneshot_timer = ONESHOT_HOLD_DURATION if _anim_frames <= 1 else -1.0

	var cr = anim_data.get("content_rect", [])
	if cr.size() == 4:
		_content_rect = Rect2(cr[0], cr[1], cr[2], cr[3])
	else:
		_content_rect = Rect2(0, 0, _frame_width, _frame_height)

	unit_sprite.texture = texture
	unit_sprite.hframes = _anim_frames
	unit_sprite.frame = 0
	_apply_sprite_layout()


## Convenience async wrapper: plays animation and waits for it to finish.
func play_animation_async(anim_name: String) -> void:
	play_animation(anim_name)
	await animation_finished


func _emit_finished_deferred(anim_name: String) -> void:
	animation_finished.emit(anim_name)


func _return_to_idle() -> void:
	if not _animations.has("idle"):
		return

	var idle_anim = _animations["idle"]
	var sheet_path = _sprite_folder + "/" + idle_anim.get("sheet", "")
	var texture = load(sheet_path)
	if texture == null:
		return

	_current_anim = "idle"
	_anim_frames = idle_anim.get("frames", 1)
	_anim_fps = idle_anim.get("fps", 8.0)
	_anim_current_frame = 0
	_anim_timer = 0.0
	_anim_looping = true

	var cr = idle_anim.get("content_rect", [])
	if cr.size() == 4:
		_content_rect = Rect2(cr[0], cr[1], cr[2], cr[3])
	else:
		_content_rect = Rect2(0, 0, _frame_width, _frame_height)

	unit_sprite.texture = texture
	unit_sprite.hframes = _anim_frames
	unit_sprite.frame = 0
	_apply_sprite_layout()


func _process(delta: float) -> void:
	# Flash damage effect
	if flash_timer > 0:
		flash_timer -= delta
		var alpha = (flash_timer / FLASH_DURATION) * 0.6
		flash_overlay.color = Color(1.0, 1.0, 1.0, max(0.0, alpha))
		if flash_timer <= 0:
			flash_overlay.color = Color(1.0, 1.0, 1.0, 0.0)

	# Single-frame oneshot timer (e.g. hit animation)
	if _oneshot_timer >= 0.0 and not _anim_looping:
		_oneshot_timer -= delta
		if _oneshot_timer < 0.0:
			var finished_anim = _current_anim
			_return_to_idle()
			animation_finished.emit(finished_anim)
			return

	# Multi-frame sprite animation
	if _has_sprite and _anim_frames > 1 and _anim_fps > 0:
		_anim_timer += delta
		var frame_duration = 1.0 / _anim_fps
		if _anim_timer >= frame_duration:
			_anim_timer -= frame_duration
			_anim_current_frame += 1
			if _anim_current_frame >= _anim_frames:
				if _anim_looping:
					_anim_current_frame = 0
				else:
					# One-shot animation finished
					var finished_anim = _current_anim
					_return_to_idle()
					animation_finished.emit(finished_anim)
					return
			unit_sprite.frame = _anim_current_frame


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


func _rect(x1: float, y1: float, x2: float, y2: float) -> PackedVector2Array:
	return PackedVector2Array([Vector2(x1, y1), Vector2(x2, y1), Vector2(x2, y2), Vector2(x1, y2)])


func _bar_poly(w: float, h: float) -> PackedVector2Array:
	return PackedVector2Array([Vector2(0, 0), Vector2(w, 0), Vector2(w, h), Vector2(0, h)])


func _get_status_color(status_name: String) -> Color:
	match status_name:
		"defending":
			return Color(0.3, 0.6, 1.0)
		"taunted":
			return Color(1.0, 0.3, 0.1)
		"iron_skin":
			return Color(0.6, 0.6, 0.7)
		"inspired":
			return Color(1.0, 0.9, 0.2)
		"hamstrung":
			return Color(0.6, 0.2, 0.6)
		"elemental_attunement":
			return Color(0.2, 0.9, 0.9)
		"poisoned", "burning":
			return Color(0.1, 0.7, 0.1)
		_:
			return Color(0.8, 0.8, 0.2)
