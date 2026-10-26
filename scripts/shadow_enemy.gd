class_name ShadowEnemy
extends CharacterBody2D

enum State { PATROL, CHASE, RETURNING }

@export var patrol_speed: float = 50.0
@export var chase_speed: float = 90.0
@export var detection_radius: float = 160.0
@export var lose_radius: float = 260.0

var current_state: State = State.PATROL
var patrol_points: Array[Vector2] = []
var current_patrol_index: int = 0
var player_ref: Player = null

var float_timer: float = 0.0
var has_alerted: bool = false
var damage_cooldown: float = 0.0
var current_direction: String = "down"

@onready var sprite: Node = $AnimatedSprite2D if has_node("AnimatedSprite2D") else $Sprite2D
@onready var dark_light: PointLight2D = $DarkLight
@onready var particles: CPUParticles2D = $Particles
@onready var hitbox: Area2D = $Hitbox

func _ready() -> void:
	if sprite:
		if sprite is AnimatedSprite2D:
			if sprite.sprite_frames == null:
				var frames := load("res://assets/sprites/priest_frames.tres") as SpriteFrames
				if frames:
					sprite.sprite_frames = frames
			_play_anim("idle_down")
		elif sprite is Sprite2D:
			var tex := load("res://assets/padre.png") as Texture2D
			if tex:
				sprite.texture = tex
			else:
				sprite.texture = TextureGenerator.get_shadow_sprite()
			
	if dark_light:
		dark_light.texture = TextureGenerator.get_light_halo(150)
		dark_light.color = Color(0.55, 0.05, 0.25, 0.85) # Resplandor siniestro de sangre y niebla
		dark_light.energy = 0.75
		
	if particles:
		particles.texture = TextureGenerator.get_spark_particle()
		particles.color = Color(0.2, 0.02, 0.25, 0.75)
		
	if hitbox:
		hitbox.body_entered.connect(_on_hitbox_body_entered)

func setup(points: Array[Vector2], player: Player) -> void:
	patrol_points = points
	player_ref = player
	if not patrol_points.is_empty():
		global_position = patrol_points[0]

func _physics_process(delta: float) -> void:
	if damage_cooldown > 0.0:
		damage_cooldown -= delta

	float_timer += delta * 4.0
	
	# Comprobar distancia con el niño
	if player_ref and is_instance_valid(player_ref) and player_ref.current_health > 0:
		var dist_to_player := global_position.distance_to(player_ref.global_position)
		if current_state == State.PATROL or current_state == State.RETURNING:
			if dist_to_player <= detection_radius:
				current_state = State.CHASE
				if not has_alerted:
					has_alerted = true
					if SoundManager.instance:
						SoundManager.instance.play_ghost()
		elif current_state == State.CHASE:
			if dist_to_player >= lose_radius:
				current_state = State.RETURNING
				has_alerted = false
	else:
		current_state = State.RETURNING

	# Movimiento de patrulla / persecución
	match current_state:
		State.PATROL:
			_process_patrol(delta)
		State.CHASE:
			_process_chase(delta)
		State.RETURNING:
			_process_returning(delta)

	move_and_slide()
	
	# Actualizar animación del Padre sin Cabeza según estado y dirección
	var anim_prefix := "walk_"
	if current_state == State.CHASE:
		anim_prefix = "run_"
	elif current_state == State.PATROL or current_state == State.RETURNING:
		anim_prefix = "walk_"

	if velocity.length() > 6.0:
		if abs(velocity.x) > abs(velocity.y):
			current_direction = "right" if velocity.x > 0 else "left"
		else:
			current_direction = "down" if velocity.y > 0 else "up"
		_play_anim(anim_prefix + current_direction)
	else:
		_play_anim("idle_" + current_direction)

func _play_anim(anim_name: String) -> void:
	if sprite is AnimatedSprite2D:
		if sprite.animation != anim_name or not sprite.is_playing():
			sprite.play(anim_name)

func _process_patrol(delta: float) -> void:
	if patrol_points.is_empty():
		velocity = velocity.lerp(Vector2.ZERO, delta * 4.0)
		return
		
	var target_point := patrol_points[current_patrol_index]
	var to_point := target_point - global_position
	var dist := to_point.length()
	
	if dist < 20.0:
		current_patrol_index = (current_patrol_index + 1) % patrol_points.size()
	else:
		var desired := to_point.normalized() * patrol_speed
		velocity = velocity.lerp(desired, delta * 3.5)

func _process_chase(delta: float) -> void:
	if not player_ref:
		return
	var to_player := player_ref.global_position - global_position
	var desired := to_player.normalized() * chase_speed
	velocity = velocity.lerp(desired, delta * 4.8)
	
	# Pulso espectral amenazante
	if dark_light:
		dark_light.energy = 0.9 + sin(float_timer * 6.0) * 0.3

func _process_returning(delta: float) -> void:
	if patrol_points.is_empty():
		current_state = State.PATROL
		return
	var nearest_point := patrol_points[0]
	var min_dist := global_position.distance_to(nearest_point)
	var best_idx := 0
	
	for i in range(1, patrol_points.size()):
		var d := global_position.distance_to(patrol_points[i])
		if d < min_dist:
			min_dist = d
			nearest_point = patrol_points[i]
			best_idx = i
			
	var to_pt := nearest_point - global_position
	if to_pt.length() < 24.0:
		current_patrol_index = best_idx
		current_state = State.PATROL
	else:
		velocity = velocity.lerp(to_pt.normalized() * patrol_speed, delta * 3.0)

func _on_hitbox_body_entered(body: Node2D) -> void:
	if body is Player and damage_cooldown <= 0.0:
		var knock_dir := (body.global_position - global_position).normalized()
		body.take_damage(1, knock_dir)
		damage_cooldown = 1.3
		velocity = -knock_dir * 120.0
