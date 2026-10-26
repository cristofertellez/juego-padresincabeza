class_name GameCamera
extends Camera2D

var shake_intensity: float = 0.0
var shake_timer: float = 0.0
var original_offset: Vector2 = Vector2.ZERO

func _ready() -> void:
	position_smoothing_enabled = true
	position_smoothing_speed = 7.0
	original_offset = offset

func shake(intensity: float = 8.0, duration: float = 0.35) -> void:
	shake_intensity = intensity
	shake_timer = duration

func _process(delta: float) -> void:
	if shake_timer > 0.0:
		shake_timer -= delta
		var damping := shake_timer / 0.35
		offset = original_offset + Vector2(
			randf_range(-1.0, 1.0) * shake_intensity * damping,
			randf_range(-1.0, 1.0) * shake_intensity * damping
		)
		if shake_timer <= 0.0:
			offset = original_offset
