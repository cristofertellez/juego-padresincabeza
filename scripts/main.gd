class_name GameManager
extends Node2D

const TOTAL_EYES: int = 7

var collected_eyes: int = 0
var active_eyes: Array[EyeItem] = []
var active_shadows: Array[ShadowEnemy] = []

@onready var dungeon: DungeonBuilder = $Dungeon
@onready var player: Player = $Player
@onready var camera: GameCamera = $Camera2D
@onready var hud: HUD = $CanvasLayer/HUD
@onready var mouse_light: MouseLight = $MouseLight
@onready var canvas_modulate: CanvasModulate = $CanvasModulate

var eye_scene: PackedScene = preload("res://scenes/eye_item.tscn")
var shadow_scene: PackedScene = preload("res://scenes/shadow_enemy.tscn")
var landmarks_manager: ChurchLandmarksManager = null
var ceiling_eyes: ChurchEyesDecorations = null

func _ready() -> void:
	y_sort_enabled = true
	# Oscuridad nocturna dentro de la Catedral de León
	canvas_modulate.color = Color("05050b")
	
	if hud:
		hud.restart_requested.connect(_on_restart_requested)
		hud.update_eyes(0, TOTAL_EYES)
		
	# Luz del ratón: brillo auxiliar cálido como reflejo del candil
	if mouse_light:
		mouse_light.color = Color("fff0cc")
		mouse_light.energy = 0.8
		
	await get_tree().process_frame
	
	_spawn_player()
	_spawn_ceiling_eyes()
	_spawn_landmarks()
	_spawn_eyes()
	_spawn_shadows()
	
	if camera and player:
		camera.global_position = player.global_position
		
	if player:
		player.health_changed.connect(_on_player_health_changed)
		player.player_damaged.connect(_on_player_damaged)
		player.player_died.connect(_on_player_died)
		if hud:
			hud.update_health(player.current_health, player.max_health)

func _spawn_player() -> void:
	if dungeon and player:
		player.global_position = dungeon.player_spawn_pos

func _spawn_ceiling_eyes() -> void:
	ceiling_eyes = ChurchEyesDecorations.new()
	add_child(ceiling_eyes)

func _spawn_landmarks() -> void:
	landmarks_manager = ChurchLandmarksManager.new()
	add_child(landmarks_manager)

func _spawn_eyes() -> void:
	active_eyes.clear()
	for pos in dungeon.eye_spawn_positions:
		var eye: EyeItem = eye_scene.instantiate()
		eye.global_position = pos
		eye.set_player(player)
		eye.collected.connect(_on_eye_collected)
		$Entities.add_child(eye)
		active_eyes.append(eye)

func _spawn_shadows() -> void:
	active_shadows.clear()
	# Instanciar las apariciones del Padre sin Cabeza patrullando las naves de la Catedral
	for route in dungeon.shadow_patrol_routes:
		var shadow: ShadowEnemy = shadow_scene.instantiate()
		$Entities.add_child(shadow)
		shadow.setup(route, player)
		active_shadows.append(shadow)

func _process(_delta: float) -> void:
	if not player or not is_instance_valid(player):
		return
		
	if camera:
		camera.global_position = player.global_position
		
	# Distancia al ojo más cercano en la Catedral
	var min_distance: float = 9999.0
	for eye in active_eyes:
		if is_instance_valid(eye) and not eye.is_collected:
			var d := player.global_position.distance_to(eye.global_position)
			if d < min_distance:
				min_distance = d
				
	if hud:
		hud.set_nearest_eye_distance(min_distance)

func _on_eye_collected(eye: EyeItem) -> void:
	active_eyes.erase(eye)
	collected_eyes += 1
	if hud:
		hud.update_eyes(collected_eyes, TOTAL_EYES)
		
	if camera:
		camera.shake(4.0, 0.25)
		
	if collected_eyes >= TOTAL_EYES:
		_trigger_victory()

func _on_player_health_changed(current: int, maximum: int) -> void:
	if hud:
		hud.update_health(current, maximum)

func _on_player_damaged() -> void:
	if camera:
		camera.shake(11.0, 0.45)

func _on_player_died() -> void:
	if hud:
		hud.show_game_over()

func _trigger_victory() -> void:
	if SoundManager.instance:
		SoundManager.instance.play_win()
	if hud:
		hud.show_victory()

func _on_restart_requested() -> void:
	get_tree().reload_current_scene()
