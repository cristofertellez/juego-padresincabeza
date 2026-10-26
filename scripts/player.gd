class_name Player
extends CharacterBody2D

signal health_changed(current_health: int, max_health: int)
signal player_died
signal player_damaged

@export var max_health: int = 3
@export var speed: float = 160.0
@export var acceleration: float = 12.0
@export var stop_distance: float = 14.0

var current_health: int = 3
var is_invulnerable: bool = false
var invulnerability_timer: float = 0.0
const INVULNERABILITY_DURATION: float = 1.4

var walk_timer: float = 0.0
var lantern_flicker_timer: float = 0.0
var current_direction: String = "down"

@onready var sprite: Node = $AnimatedSprite2D if has_node("AnimatedSprite2D") else $Sprite2D
@onready var light: PointLight2D = $PointLight2D
@onready var particles: CPUParticles2D = $TrailParticles
@onready var collision_shape: CollisionShape2D = $CollisionShape2D

func _ready() -> void:
	current_health = max_health
	emit_signal("health_changed", current_health, max_health)
	
	if sprite:
		if sprite is AnimatedSprite2D:
			if sprite.sprite_frames == null:
				var frames := load("res://assets/sprites/kid_frames.tres") as SpriteFrames
				if frames:
					sprite.sprite_frames = frames
			_play_anim("idle_down")
		elif sprite is Sprite2D:
			var tex := load("res://assets/jugador.png") as Texture2D
			if tex:
				sprite.texture = tex
			else:
				sprite.texture = TextureGenerator.get_player_sprite()
			
	if light:
		light.texture = TextureGenerator.get_light_halo(240)
		light.color = Color("ffe5ad") # Luz cálida de candil colonial
		light.energy = 1.15
		
	if particles:
		particles.texture = TextureGenerator.get_spark_particle()
		particles.color = Color("ffe082") # Chispitas doradas del candil

func _physics_process(delta: float) -> void:
	if current_health <= 0:
		velocity = Vector2.ZERO
		move_and_slide()
		return
		
	# Movimiento hacia el ratón
	var mouse_pos := get_global_mouse_position()
	var to_mouse := mouse_pos - global_position
	var distance := to_mouse.length()
	
	if distance > stop_distance:
		var target_speed := minf(speed, distance * 3.5)
		var desired_vel := to_mouse.normalized() * target_speed
		velocity = velocity.lerp(desired_vel, acceleration * delta)
		if particles:
			particles.emitting = true
			
		# Determinar dirección predominante
		if abs(velocity.x) > abs(velocity.y):
			current_direction = "right" if velocity.x > 0 else "left"
		else:
			current_direction = "down" if velocity.y > 0 else "up"
			
		# Seleccionar walk o run según velocidad / distancia
		if distance > 90.0 or velocity.length() > 110.0:
			_play_anim("run_" + current_direction)
		else:
			_play_anim("walk_" + current_direction)
	else:
		velocity = velocity.lerp(Vector2.ZERO, acceleration * delta)
		if particles:
			particles.emitting = false
		_play_anim("idle_" + current_direction)
			
	move_and_slide()
	
	# Parpadeo orgánico del candil colonial de aceite / vela
	lantern_flicker_timer += delta * 10.0
	if light:
		var flicker := (sin(lantern_flicker_timer) * 0.06) + (sin(lantern_flicker_timer * 2.7) * 0.04)
		light.energy = 1.15 + flicker
		var scale_var := 1.0 + (sin(lantern_flicker_timer * 1.6) * 0.02)
		light.scale = Vector2(scale_var, scale_var)

	# Manejo de invulnerabilidad
	if is_invulnerable:
		invulnerability_timer -= delta
		if sprite:
			sprite.modulate.a = 0.35 if int(invulnerability_timer * 16.0) % 2 == 0 else 1.0
		if invulnerability_timer <= 0.0:
			is_invulnerable = false
			if sprite:
				sprite.modulate = Color.WHITE

func take_damage(amount: int = 1, knockback_dir: Vector2 = Vector2.ZERO) -> void:
	if is_invulnerable or current_health <= 0:
		return
		
	current_health = maxi(0, current_health - amount)
	is_invulnerable = true
	invulnerability_timer = INVULNERABILITY_DURATION
	
	if knockback_dir != Vector2.ZERO:
		velocity = knockback_dir.normalized() * (speed * 1.8)
		
	emit_signal("health_changed", current_health, max_health)
	emit_signal("player_damaged")
	
	if SoundManager.instance:
		SoundManager.instance.play_damage()
		
	if current_health <= 0:
		emit_signal("player_died")
		if SoundManager.instance:
			SoundManager.instance.play_defeat()

func _play_anim(anim_name: String) -> void:
	if sprite is AnimatedSprite2D:
		if sprite.animation != anim_name or not sprite.is_playing():
			sprite.play(anim_name)

