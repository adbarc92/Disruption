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

# Node references
@onready var sprite: ColorRect = $Sprite
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


func _get_input_direction() -> Vector2:
	return Vector2(
		Input.get_axis("move_left", "move_right"),
		Input.get_axis("move_up", "move_down")
	).normalized()


func _update_facing(direction: Vector2) -> void:
	if direction == Vector2.ZERO:
		return

	facing_direction = direction.normalized()

	# Update sprite visual based on facing (simple 4-direction for now)
	# In a real game, this would change the sprite animation
	if abs(direction.x) > abs(direction.y):
		sprite.scale.x = sign(direction.x) if direction.x != 0 else 1

	# Update interaction area position
	interaction_area.position = facing_direction * 30


func _change_state(new_state: State) -> void:
	if new_state == current_state:
		return

	current_state = new_state
	state_changed.emit(current_state)

	# Visual feedback based on state
	match current_state:
		State.ROLLING:
			sprite.color = Color(0.1, 0.4, 0.7, 1)  # Darker blue
		State.GRAPPLING:
			sprite.color = Color(0.8, 0.6, 0.2, 1)  # Gold
		State.SPRINTING:
			sprite.color = Color(0.3, 0.6, 0.9, 1)  # Light blue
		State.HOPPING:
			sprite.color = Color(0.4, 0.7, 0.4, 1)  # Green
		_:
			sprite.color = Color(0.2, 0.5, 0.8, 1)  # Default blue


# Check if player is currently "in the air" (hopping)
func is_airborne() -> bool:
	return current_state == State.HOPPING and z_offset > 5.0
