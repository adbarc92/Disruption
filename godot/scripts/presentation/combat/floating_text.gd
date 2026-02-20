extends Node2D
class_name FloatingText
## FloatingText - Rising, fading damage/heal numbers in combat

var velocity: Vector2 = Vector2(0, -60)
var lifetime: float = 1.0
var elapsed: float = 0.0
var label: Label


static func create(text: String, color: Color, pos: Vector2, large: bool = false) -> Node2D:
	var instance = load("res://scripts/presentation/combat/floating_text.gd").new()
	instance.position = pos

	instance.label = Label.new()
	instance.label.text = text
	instance.label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	instance.label.add_theme_color_override("font_color", color)
	instance.label.add_theme_font_size_override("font_size", 20 if large else 14)
	instance.label.position = Vector2(-30, -10)
	instance.label.size = Vector2(60, 20)
	instance.add_child(instance.label)

	return instance


func _process(delta: float) -> void:
	elapsed += delta
	position += velocity * delta
	velocity.y *= 0.95  # Slow down over time

	# Fade out in the second half of lifetime
	var alpha = 1.0
	if elapsed > lifetime * 0.5:
		alpha = 1.0 - (elapsed - lifetime * 0.5) / (lifetime * 0.5)

	label.modulate.a = max(0.0, alpha)

	if elapsed >= lifetime:
		queue_free()
