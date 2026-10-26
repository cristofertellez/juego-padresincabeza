class_name HUD
extends Control

signal restart_requested

var total_eyes: int = 7
var collected_eyes: int = 0
var max_health: int = 3
var current_health: int = 3

var nearest_eye_distance: float = 9999.0
var radar_timer: float = 0.0
var radar_interval: float = 2.0
var radar_pulse_anim: float = 0.0

@onready var heart_icons_container: HBoxContainer = $MarginContainer/TopBar/HBoxLeft/HeartsContainer
@onready var eyes_label: Label = $MarginContainer/TopBar/HBoxRight/EyesLabel
@onready var radar_icon: TextureRect = $MarginContainer/TopBar/HBoxCenter/RadarIcon
@onready var radar_text: Label = $MarginContainer/TopBar/HBoxCenter/RadarText

@onready var game_over_panel: Control = $GameOverPanel
@onready var victory_panel: Control = $VictoryPanel
@onready var restart_button_gameover: Button = $GameOverPanel/VBox/RestartBtnGameOver
@onready var restart_button_victory: Button = $VictoryPanel/VBox/RestartBtnVictory

var heart_rects: Array[TextureRect] = []

func _ready() -> void:
	game_over_panel.visible = false
	victory_panel.visible = false
	
	if restart_button_gameover:
		restart_button_gameover.pressed.connect(_on_restart_pressed)
	if restart_button_victory:
		restart_button_victory.pressed.connect(_on_restart_pressed)
		
	if radar_icon:
		radar_icon.texture = TextureGenerator.get_eye_icon()
		radar_icon.pivot_offset = Vector2(8, 8)
		
	_setup_heart_icons()
	update_eyes(0, total_eyes)

func _setup_heart_icons() -> void:
	if not heart_icons_container:
		return
	for child in heart_icons_container.get_children():
		child.queue_free()
	heart_rects.clear()
	
	for i in range(max_health):
		var rect := TextureRect.new()
		rect.texture = TextureGenerator.get_heart_icon(true)
		rect.stretch_mode = TextureRect.STRETCH_KEEP_CENTERED
		rect.custom_minimum_size = Vector2(20, 20)
		heart_icons_container.add_child(rect)
		heart_rects.append(rect)

func update_health(current: int, maximum: int) -> void:
	current_health = current
	max_health = maximum
	if heart_rects.size() != max_health:
		_setup_heart_icons()
	for i in range(heart_rects.size()):
		var filled := i < current_health
		heart_rects[i].texture = TextureGenerator.get_heart_icon(filled)
		if not filled:
			heart_rects[i].modulate = Color(0.6, 0.6, 0.6, 0.6)
		else:
			heart_rects[i].modulate = Color.WHITE

func update_eyes(collected: int, total: int) -> void:
	collected_eyes = collected
	total_eyes = total
	if eyes_label:
		eyes_label.text = "Ojos: %d / %d" % [collected_eyes, total_eyes]

func set_nearest_eye_distance(distance: float) -> void:
	nearest_eye_distance = distance

func _process(delta: float) -> void:
	if collected_eyes >= total_eyes or current_health <= 0:
		if radar_text:
			radar_text.text = ""
		return
		
	# Cálculo de radar según la distancia al ojo más cercano
	# Lejos: > 500px -> intervalo 2.5s
	# Medio: 200px-500px -> intervalo 1.2s
	# Cerca: 80px-200px -> intervalo 0.6s
	# Muy cerca: < 80px -> intervalo 0.28s
	var clamped_dist := clampf(nearest_eye_distance, 40.0, 600.0)
	var t := (clamped_dist - 40.0) / 560.0
	radar_interval = lerpf(0.28, 2.5, t)
	
	radar_timer += delta
	if radar_timer >= radar_interval:
		radar_timer = 0.0
		radar_pulse_anim = 1.0
		if SoundManager.instance and nearest_eye_distance < 600.0:
			SoundManager.instance.play_radar(t)
			
	if radar_pulse_anim > 0.0:
		radar_pulse_anim = maxf(0.0, radar_pulse_anim - delta * 4.0)
		if radar_icon:
			var s := 1.0 + radar_pulse_anim * 0.5
			radar_icon.scale = Vector2(s, s)
			radar_icon.modulate = Color(1.0 + radar_pulse_anim * 0.8, 1.0, 1.0)
	else:
		if radar_icon:
			radar_icon.scale = Vector2.ONE
			radar_icon.modulate = Color.WHITE
			
	if radar_text:
		if nearest_eye_distance < 80.0:
			radar_text.text = "¡Latido Inminente!"
			radar_text.modulate = Color("ff3355")
		elif nearest_eye_distance < 200.0:
			radar_text.text = "Resonancia: Cerca"
			radar_text.modulate = Color("ffaa33")
		elif nearest_eye_distance < 450.0:
			radar_text.text = "Resonancia: Leve"
			radar_text.modulate = Color("77bbff")
		else:
			radar_text.text = "Resonancia: Silencio"
			radar_text.modulate = Color("667799")

func show_game_over() -> void:
	game_over_panel.visible = true
	game_over_panel.modulate.a = 0.0
	var tween := create_tween()
	tween.tween_property(game_over_panel, "modulate:a", 1.0, 0.6)

func show_victory() -> void:
	victory_panel.visible = true
	victory_panel.modulate.a = 0.0
	var tween := create_tween()
	tween.tween_property(victory_panel, "modulate:a", 1.0, 0.6)

func _on_restart_pressed() -> void:
	emit_signal("restart_requested")
