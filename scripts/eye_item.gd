class_name EyeItem
extends Node2D

signal collected(eye_node: EyeItem)

@export var interact_distance: float = 80.0
var is_collected: bool = false
var player_ref: Node2D = null

var blink_timer: float = 0.0
var next_blink_time: float = 3.0
var is_blinking: bool = false
var blink_progress: float = 0.0

var pulse_time: float = 0.0
var is_hovered: bool = false

@onready var eye_sprite: Sprite2D = $EyeSprite
@onready var glow_light: PointLight2D = $GlowLight
@onready var area: Area2D = $Area2D
@onready var particles: CPUParticles2D = $CPUParticles2D

func _ready() -> void:
	if eye_sprite:
		var tex := load("res://assets/ojo.png") as Texture2D
		if tex:
			eye_sprite.texture = tex
		else:
			eye_sprite.texture = TextureGenerator.get_eye_base()
			
	if glow_light:
		glow_light.texture = TextureGenerator.get_light_halo(90)
		glow_light.color = Color(1.0, 0.15, 0.25, 1.0)
		glow_light.energy = 0.2
		
	if particles:
		particles.texture = TextureGenerator.get_spark_particle()
		particles.emitting = false
		particles.one_shot = true
		
	next_blink_time = randf_range(2.0, 5.0)
	
	if area:
		area.mouse_entered.connect(_on_mouse_entered)
		area.mouse_exited.connect(_on_mouse_exited)
		area.input_event.connect(_on_input_event)

func set_player(player: Node2D) -> void:
	player_ref = player

func _process(delta: float) -> void:
	if is_collected:
		return
		
	pulse_time += delta * 3.5
	
	if player_ref:
		var to_player := player_ref.global_position - global_position
		var dist := to_player.length()
		
		# Sutil inclinación o seguimiento hacia el niño
		if dist < 220.0 and eye_sprite:
			var target_rot := clampf(to_player.x * 0.001, -0.15, 0.15)
			eye_sprite.rotation = lerpf(eye_sprite.rotation, target_rot, delta * 6.0)
			
		# Brillo / Pulso rojo reactivo cuando la luz del candil toca el ojo
		if dist < 190.0:
			var proximity: float = 1.0 - (dist / 190.0)
			var pulse: float = 0.3 + 0.4 * (sin(pulse_time * (2.5 + proximity * 3.0)) * 0.5 + 0.5)
			glow_light.energy = pulse * proximity + 0.15
			glow_light.color = Color(1.0, 0.2, 0.2)
		else:
			glow_light.energy = 0.08
			
	# Animación de parpadeo realista
	blink_timer += delta
	if not is_blinking and blink_timer >= next_blink_time:
		is_blinking = true
		blink_progress = 0.0
		blink_timer = 0.0
		next_blink_time = randf_range(2.5, 5.5)
		
	if is_blinking and eye_sprite:
		blink_progress += delta * 12.0
		var blink_scale: float = absf(cos(blink_progress))
		eye_sprite.scale.y = clampf(blink_scale, 0.05, 1.0)
		if blink_progress >= PI:
			is_blinking = false
			eye_sprite.scale.y = 1.0
			
	# Resaltar si el ratón está encima
	if is_hovered and player_ref and eye_sprite:
		var d: float = global_position.distance_to(player_ref.global_position)
		if d <= interact_distance:
			eye_sprite.modulate = Color(1.3, 1.25, 1.25)
		else:
			eye_sprite.modulate = Color(1.1, 0.95, 0.95)
	elif eye_sprite:
		eye_sprite.modulate = Color.WHITE

func _on_mouse_entered() -> void:
	is_hovered = true

func _on_mouse_exited() -> void:
	is_hovered = false

func _on_input_event(_viewport: Node, event: InputEvent, _shape_idx: int) -> void:
	if is_collected:
		return
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		try_collect()

func try_collect() -> void:
	if is_collected:
		return
	if player_ref:
		var dist: float = global_position.distance_to(player_ref.global_position)
		if dist <= interact_distance:
			collect()
		else:
			var tween := create_tween()
			tween.tween_property(glow_light, "energy", 1.4, 0.1)
			tween.tween_property(glow_light, "energy", 0.2, 0.2)

func collect() -> void:
	is_collected = true
	emit_signal("collected", self)
	
	if SoundManager.instance:
		SoundManager.instance.play_eye()
		
	if particles:
		particles.emitting = true
		
	# Animación de absorción mística hacia arriba
	var tween := create_tween().set_parallel(true)
	if eye_sprite:
		tween.tween_property(eye_sprite, "scale", Vector2(1.7, 1.7), 0.35).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		tween.tween_property(eye_sprite, "position:y", eye_sprite.position.y - 16.0, 0.35)
		tween.tween_property(eye_sprite, "modulate:a", 0.0, 0.4)
	tween.tween_property(glow_light, "energy", 2.2, 0.15)
	tween.chain().tween_property(glow_light, "energy", 0.0, 0.25)
	
	await tween.finished
	queue_free()
