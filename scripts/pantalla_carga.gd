class_name PantallaCarga
extends Control

## Pantalla de carga interactiva con consejos de la Catedral de León.
## Gestiona la barra de progreso animada durante un tiempo fijo (10 segundos por defecto)
## y realiza la precarga en segundo plano de la escena objetivo.

signal carga_completada

# ── Parámetros configurables ─────────────────────────────────────
@export var target_scene: String = "res://main.tscn"
@export var loading_duration: float = 10.0
@export var fade_duration: float = 0.4

# ── Referencias a nodos ──────────────────────────────────────────
@onready var bg_texture: TextureRect = $BackgroundImage
@onready var progress_bar: ProgressBar = $ProgressBar
@onready var label_loading: Label = $LabelLoading
@onready var fade_rect: ColorRect = $FadeRect

# ── Variables internas ───────────────────────────────────────────
var _elapsed_time: float = 0.0
var _dot_timer: float = 0.0
var _dot_count: int = 0
var _is_finished: bool = false
var _use_threaded_load: bool = false


func _ready() -> void:
	# Inicializar barra de progreso
	if progress_bar:
		progress_bar.min_value = 0.0
		progress_bar.max_value = 100.0
		progress_bar.value = 0.0

	if label_loading:
		label_loading.text = "Cargando..."

	# Iniciar con fade-in desde negro
	if fade_rect:
		fade_rect.color = Color(0.0, 0.0, 0.0, 1.0)
		fade_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var tw: Tween = create_tween()
		tw.tween_property(fade_rect, "color:a", 0.0, fade_duration)\
			.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)

	# Solicitar precarga en segundo plano si la escena existe
	if ResourceLoader.exists(target_scene):
		var err := ResourceLoader.load_threaded_request(target_scene)
		_use_threaded_load = (err == OK)


func _process(delta: float) -> void:
	if _is_finished:
		return

	_elapsed_time += delta

	# Animación de puntos suspensivos ("Cargando.", "Cargando..", "Cargando...")
	_dot_timer += delta
	if _dot_timer >= 0.35:
		_dot_timer = 0.0
		_dot_count = (_dot_count + 1) % 4
		var dots: String = ""
		for i in range(_dot_count):
			dots += "."
		if label_loading:
			label_loading.text = "Cargando" + dots

	# Cálculo de progreso (0.0 a 1.0) con curva natural de carga
	var raw_progress: float = clampf(_elapsed_time / loading_duration, 0.0, 1.0)

	# Curva de progresión sutil con desaceleración natural
	var visual_progress: float = ease(raw_progress, 0.85) * 100.0

	if progress_bar:
		progress_bar.value = visual_progress

	# Cuando se alcanzan exactamente los 5 segundos requeridos
	if _elapsed_time >= loading_duration:
		_complete_loading()


func _complete_loading() -> void:
	_is_finished = true

	if progress_bar:
		progress_bar.value = 100.0
	if label_loading:
		label_loading.text = "¡Listo!"

	# Efecto breve de pulso de confirmación
	await get_tree().create_timer(0.15).timeout

	# Desvanecer a negro antes de cambiar de escena
	if fade_rect:
		var tw: Tween = create_tween()
		tw.tween_property(fade_rect, "color:a", 1.0, fade_duration)\
			.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
		await tw.finished

	carga_completada.emit()

	# Cambio a la escena jugable
	if _use_threaded_load:
		var status := ResourceLoader.load_threaded_get_status(target_scene)
		if status == ResourceLoader.THREAD_LOAD_LOADED:
			var packed: PackedScene = ResourceLoader.load_threaded_get(target_scene) as PackedScene
			if packed:
				get_tree().change_scene_to_packed(packed)
				return

	# Carga estándar de respaldo
	if ResourceLoader.exists(target_scene):
		get_tree().change_scene_to_file(target_scene)
	else:
		push_error("[PantallaCarga] No se pudo encontrar la escena objetivo: " + target_scene)
