class_name MouseLight
extends PointLight2D

var noise_offset: float = 0.0

func _ready() -> void:
	texture = TextureGenerator.get_light_halo(150)
	energy = 0.85
	color = Color(1.0, 0.96, 0.88, 1.0)

func _process(delta: float) -> void:
	global_position = get_global_mouse_position()
	noise_offset += delta * 8.0
	var flicker := sin(noise_offset) * 0.04 + sin(noise_offset * 2.1) * 0.03
	energy = 0.85 + flicker
