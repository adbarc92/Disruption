extends CharacterBody2D
class_name PlayerController
## Player character controller for 2.5D top-down exploration (Chrono Trigger/Sea of Stars style)
## Handles 8-directional movement, hopping, sprinting, rolling, and grappling

# Movement constants
const WALK_SPEED = 150.0
const SPRINT_SPEED = 250.0
const ROLL_SPEED = 300.0
const ROLL_DURATION = 0.35
const GRAPPLE_SPEED = 400.0
const GRAPPLE_RANGE = 250.0

# Hop constants (for jumping over obstacles)
const HOP_DURATION = 0.3
const HOP_HEIGHT = 20.0  # Visual only - we use z-offset for "height"

# Physics
const ACCELERATION = 800.0
const FRICTION = 600.0

# Sprite config
const FRAME_WIDTH = 120
const FRAME_HEIGHT = 80

# State machine
enum State {
	IDLE,
	WALKING,
	SPRINTING,
	HOPPING,
	ROLLING,
	GRAPPLING,
}

var current_state: State = State.IDLE
var facing_direction: Vector2 = Vector2.DOWN  # 8-directional facing
var facing_right: bool = true

# Hop state
var hop_timer: float = 0.0
var hop_direction: Vector2 = Vector2.ZERO
var z_offset: float = 0.0  # Simulated height for hopping

# Roll state
var roll_timer: float = 0.0
var roll_direction: Vector2 = Vector2.ZERO

# Grapple state
var grapple_target: Vector2 = Vector2.ZERO
var is_grappling: bool = false
var grapple_point: Node2D = null

# Proximity tracking for touch UI
var _grapple_nearby: bool = false

# Node references
@onready var sprite: AnimatedSprite2D = $Sprite
@onready var shadow: ColorRect = $Shadow
@onready var grapple_line: Line2D = $GrappleLine
@onready var state_label: Label = $StateLabel
@onready var interaction_area: Area2D = $InteractionArea

# Signals
signal state_changed(new_state: State)
signal interacted(interactable: Node)


func _ready() -> void:
	grapple_line.visible = false
	_update_facing(Vector2.DOWN)
	_load_sprite_animations()
	sprite.play("idle")

	# Connect interactable proximity signals for touch overlay
	interaction_area.area_entered.connect(_on_interaction_area_entered)
	interaction_area.area_exited.connect(_on_interaction_area_exited)
	interaction_area.body_entered.connect(_on_interaction_body_entered)
	interaction_area.body_exited.connect(_on_interaction_body_exited)


func _load_sprite_animations() -> void:
	var config = _load_sprite_config()
	if config.is_empty():
		push_warning("PlayerController: sprite_config.json not found, using placeholder")
		return

	var char_config = config.get("party", {}).get("cyrus", {})
	if char_config.is_empty():
		push_warning("PlayerController: cyrus sprite config not found")
		return

	var sprite_folder = char_config.get("sprite_folder", "")
	var frame_w = char_config.get("frame_width", FRAME_WIDTH)
	var frame_h = char_config.get("frame_height", FRAME_HEIGHT)
	var animations = char_config.get("animations", {})

	var sprite_frames = SpriteFrames.new()
	# Remove the default animation
	if sprite_frames.has_animation("default"):
		sprite_frames.remove_animation("default")

	for anim_name in animations:
		var anim = animations[anim_name]
		var sheet_path = sprite_folder + "/" + anim.get("sheet", "")
		var frame_count = anim.get("frames", 1)
		var fps = anim.get("fps", 8)

		var texture = load(sheet_path)
		if not texture:
			push_warning("PlayerController: failed to load %s" % sheet_path)
			continue

		sprite_frames.add_animation(anim_name)
		sprite_frames.set_animation_speed(anim_name, fps)
		sprite_frames.set_animation_loop(anim_name, anim_name != "jump")

		for i in frame_count:
			var atlas = AtlasTexture.new()
			atlas.atlas = texture
			atlas.region = Rect2(i * frame_w, 0, frame_w, frame_h)
			sprite_frames.add_frame(anim_name, atlas)

	sprite.sprite_frames = sprite_frames


func _load_sprite_config() -> Dictionary:
	var path = "res://data/sprites/sprite_config.json"
	if not FileAccess.file_exists(path):
		return {}
	var file = FileAccess.open(path, FileAccess.READ)
	if not file:
		return {}
	var json = JSON.new()
	if json.parse(file.get_as_text()) != OK:
		return {}
	return json.data


func _physics_process(delta: float) -> void:
	# Update state label for debugging
	state_label.text = State.keys()[current_state]

	match current_state:
		State.IDLE, State.WALKING, State.SPRINTING:
			_handle_movement(delta)
		State.HOPPING:
			_handle_hop(delta)
		State.ROLLING:
			_handle_roll(delta)
		State.GRAPPLING:
			_handle_grapple(delta)

	# Apply z-offset to sprite (visual hop height)
	sprite.position.y = -z_offset - 24  # Base offset + hop

	# Update grapple proximity for touch overlay (only during exploration)
	if GameManager.current_state == GameManager.GameState.EXPLORATION:
		_check_grapple_proximity()

	move_and_slide()


func _handle_movement(delta: float) -> void:
	var input_dir = _get_input_direction()

	# Hop (always available)
	if Input.is_action_just_pressed("jump") and current_state != State.HOPPING:
		_start_hop(input_dir if input_dir != Vector2.ZERO else facing_direction)
		return

	# Roll
	if Input.is_action_just_pressed("roll") and input_dir != Vector2.ZERO:
		_start_roll(input_dir)
		return

	# Grapple
	if Input.is_action_just_pressed("grapple"):
		_try_grapple()
		return

	# Movement
	var speed = SPRINT_SPEED if Input.is_action_pressed("sprint") else WALK_SPEED

	if input_dir != Vector2.ZERO:
		velocity = velocity.move_toward(input_dir * speed, ACCELERATION * delta)
		_update_facing(input_dir)

		if Input.is_action_pressed("sprint"):
			_change_state(State.SPRINTING)
		else:
			_change_state(State.WALKING)
	else:
		velocity = velocity.move_toward(Vector2.ZERO, FRICTION * delta)
		if velocity.length() < 10:
			velocity = Vector2.ZERO
			_change_state(State.IDLE)

	# Interaction
	if Input.is_action_just_pressed("interact"):
		_try_interact()


func _handle_hop(delta: float) -> void:
	hop_timer -= delta

	# Calculate hop arc (parabola)
	var hop_progress = 1.0 - (hop_timer / HOP_DURATION)
	z_offset = HOP_HEIGHT * sin(hop_progress * PI)

	# Move in hop direction
	velocity = hop_direction * WALK_SPEED * 1.2

	if hop_timer <= 0:
		z_offset = 0.0
		_change_state(State.IDLE)


func _handle_roll(delta: float) -> void:
	roll_timer -= delta

	if roll_timer <= 0:
		_change_state(State.IDLE)
		return

	velocity = roll_direction * ROLL_SPEED


func _handle_grapple(delta: float) -> void:
	if not is_grappling:
		_change_state(State.IDLE)
		return

	var direction = (grapple_target - global_position).normalized()
	var distance = global_position.distance_to(grapple_target)

	# Update grapple line visual
	grapple_line.points = [Vector2.ZERO, grapple_target - global_position]

	if distance < 15:
		# Reached grapple point
		_end_grapple()
		return

	velocity = direction * GRAPPLE_SPEED

	# Allow releasing grapple
	if Input.is_action_just_released("grapple"):
		_end_grapple()


func _start_hop(direction: Vector2) -> void:
	hop_direction = direction.normalized()
	hop_timer = HOP_DURATION
	_change_state(State.HOPPING)


func _start_roll(direction: Vector2) -> void:
	roll_direction = direction.normalized()
	roll_timer = ROLL_DURATION
	_update_facing(direction)
	_change_state(State.ROLLING)


func _try_grapple() -> void:
	# Find nearest grapple point within range
	var grapple_points = get_tree().get_nodes_in_group("grapple_points")
	var nearest: Node2D = null
	var nearest_dist = GRAPPLE_RANGE

	for point in grapple_points:
		var dist = global_position.distance_to(point.global_position)
		if dist < nearest_dist:
			# Check if point is roughly in the direction we're facing
			var dir_to_point = (point.global_position - global_position).normalized()
			if dir_to_point.dot(facing_direction) > 0.3:
				nearest = point
				nearest_dist = dist

	if nearest:
		grapple_target = nearest.global_position
		grapple_point = nearest
		is_grappling = true
		grapple_line.visible = true
		_change_state(State.GRAPPLING)


func _end_grapple() -> void:
	is_grappling = false
	grapple_line.visible = false
	grapple_point = null
	velocity *= 0.3  # Reduce momentum after grapple
	_change_state(State.IDLE)


func _try_interact() -> void:
	var areas = interaction_area.get_overlapping_areas()
	var bodies = interaction_area.get_overlapping_bodies()

	for area in areas:
		if area.is_in_group("interactables"):
			interacted.emit(area)
			EventBus.player_interacted.emit(area)
			return

	for body in bodies:
		if body.is_in_group("interactables"):
			interacted.emit(body)
			EventBus.player_interacted.emit(body)
			return


func _on_interaction_area_entered(area: Area2D) -> void:
	if area.is_in_group("interactables"):
		EventBus.interactable_nearby.emit(true)


func _on_interaction_area_exited(area: Area2D) -> void:
	if area.is_in_group("interactables"):
		# Check if any other interactables still overlap (exclude the exiting node)
		for a in interaction_area.get_overlapping_areas():
			if a != area and a.is_in_group("interactables"):
				return
		for b in interaction_area.get_overlapping_bodies():
			if b.is_in_group("interactables"):
				return
		EventBus.interactable_nearby.emit(false)


func _on_interaction_body_entered(body: Node2D) -> void:
	if body.is_in_group("interactables"):
		EventBus.interactable_nearby.emit(true)


func _on_interaction_body_exited(body: Node2D) -> void:
	if body.is_in_group("interactables"):
		for a in interaction_area.get_overlapping_areas():
			if a.is_in_group("interactables"):
				return
		for b in interaction_area.get_overlapping_bodies():
			if b != body and b.is_in_group("interactables"):
				return
		EventBus.interactable_nearby.emit(false)


func _check_grapple_proximity() -> void:
	var has_grapple = false
	var grapple_points = get_tree().get_nodes_in_group("grapple_points")
	for point in grapple_points:
		var dist = global_position.distance_to(point.global_position)
		if dist < GRAPPLE_RANGE:
			var dir_to_point = (point.global_position - global_position).normalized()
			if dir_to_point.dot(facing_direction) > 0.3:
				has_grapple = true
				break
	if has_grapple != _grapple_nearby:
		_grapple_nearby = has_grapple
		EventBus.grapple_point_nearby.emit(_grapple_nearby)


func _get_input_direction() -> Vector2:
	return Vector2(
		Input.get_axis("move_left", "move_right"),
		Input.get_axis("move_up", "move_down")
	).normalized()


func _update_facing(direction: Vector2) -> void:
	if direction == Vector2.ZERO:
		return

	facing_direction = direction.normalized()

	# Flip sprite based on horizontal direction
	if direction.x > 0.1:
		facing_right = true
		sprite.flip_h = false
	elif direction.x < -0.1:
		facing_right = false
		sprite.flip_h = true

	# Update interaction area position
	interaction_area.position = facing_direction * 30


func _change_state(new_state: State) -> void:
	if new_state == current_state:
		return

	current_state = new_state
	state_changed.emit(current_state)

	# Play animation for state
	_play_state_animation()


func _play_state_animation() -> void:
	if not sprite or not sprite.sprite_frames:
		return

	match current_state:
		State.IDLE:
			if sprite.sprite_frames.has_animation("idle"):
				sprite.play("idle")
		State.WALKING, State.SPRINTING:
			if sprite.sprite_frames.has_animation("run"):
				sprite.play("run")
		State.HOPPING:
			if sprite.sprite_frames.has_animation("jump"):
				sprite.play("jump")
		State.ROLLING:
			if sprite.sprite_frames.has_animation("roll"):
				sprite.play("roll")
		State.GRAPPLING:
			if sprite.sprite_frames.has_animation("run"):
				sprite.play("run")


# Check if player is currently "in the air" (hopping)
func is_airborne() -> bool:
	return current_state == State.HOPPING and z_offset > 5.0
