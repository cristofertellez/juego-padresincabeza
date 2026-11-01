class_name PrologoNarrativo
extends Control

## Controlador del prólogo narrativo de 5 pantallas para "Búsqueda de Ojos".
## Integra ilustraciones históricas a pantalla completa, cuadro de diálogo RPG,
## máquina de escribir progresiva, navegación por teclado/ratón/mando y botón SKIP >>.

signal prologo_finished

# ── Nodos de la escena ───────────────────────────────────────────
@onready var bg_texture: TextureRect = $BackgroundContainer/BackgroundImage
@onready var bg_fade_rect: ColorRect = $BackgroundContainer/ImageFadeRect
@onready var dialog_panel: PanelContainer = $DialogLayer/DialogPanel
@onready var dialog_label: Label = $DialogLayer/DialogPanel/MarginContainer/DialogLabel
@onready var continue_indicator: Label = $DialogLayer/DialogPanel/ContinueIndicator
@onready var skip_button: Button = $DialogLayer/SkipButton
@onready var screen_fade_rect: ColorRect = $ScreenFadeRect
@onready var typewriter_timer: Timer = $TypewriterTimer

# ── Parámetros de configuración ──────────────────────────────────
const BASE_CHAR_DELAY: float = 0.032
const FADE_BETWEEN_SCREENS: float = 0.35
const FADE_FINAL: float = 0.6
const SCENE_LOADING: String = "res://scenes/pantalla_carga.tscn"
const SCENE_GAME: String = "res://main.tscn"

# ── Datos narrativos de las cinco pantallas ──────────────────────
const SCREEN_DATA: Array[Dictionary] = [
	{
		"id": 1,
		"image": "res://assets/prologo/prologo_01_abuelo.jpg",
		"text": "Desde pequeño, mi abuelo me contaba historias sobre León. Pero había una que siempre me llamaba la atención: la leyenda de los siete ojos. Según él, eran siete objetos antiguos escondidos en un lugar que guardaba muchos secretos."
	},
	{
		"id": 2,
		"image": "res://assets/prologo/prologo_02_investigacion.jpg",
		"text": "Al principio pensé que solamente era una leyenda. Sin embargo, cuanto más investigaba, más referencias encontraba. Después de días buscando información, conseguí reunir algunas pistas sobre su posible ubicación."
	},
	{
		"id": 3,
		"image": "res://assets/prologo/prologo_03_viaje_leon.jpg",
		"text": "Finalmente llegué a León. La ciudad estaba llena de visitantes y todo parecía normal. Llevaba conmigo mi diario, mis apuntes y todas las pistas que había conseguido."
	},
	{
		"id": 4,
		"image": "res://assets/prologo/prologo_04_dentro_catedral.jpg",
		"text": "La Catedral era exactamente el lugar que había estado buscando. Entré sin ningún problema. Había personas recorriendo el lugar, tomando fotografías y admirando su arquitectura."
	},
	{
		"id": 5,
		"image": "res://assets/prologo/prologo_05_inicio_busqueda.jpg",
		"text": "Abrí mi diario y revisé nuevamente las ubicaciones. Las pistas me habían llevado hasta allí. Solo tenía que encontrar los siete ojos. No imaginaba lo que sucedería cuando reuniera el último."
	}
]

# ── Estado de ejecución ──────────────────────────────────────────
var _current_index: int = 0
var _current_full_text: String = ""
var _is_typing: bool = false
var _is_transitioning: bool = false
var _is_ending: bool = false
var _indicator_tween: Tween = null


func _ready() -> void:
	# Configurar timer de máquina de escribir
	typewriter_timer.one_shot = false
	typewriter_timer.wait_time = BASE_CHAR_DELAY
	typewriter_timer.timeout.connect(_on_typewriter_tick)

	# Conectar botón SKIP
	skip_button.pressed.connect(_on_skip_pressed)

	# Configurar rectángulos de transición
	bg_fade_rect.color = Color(0.0, 0.0, 0.0, 0.0)
	screen_fade_rect.color = Color(0.0, 0.0, 0.0, 1.0)
	screen_fade_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE

	# Ocultar indicador de continuar
	_hide_continue_indicator()

	# Cargar primera pantalla y hacer fade-in inicial
	_load_screen_content(0)
	_fade_in_screen()


func _unhandled_input(event: InputEvent) -> void:
	if _is_transitioning or _is_ending:
		return

	# Opción de omitir con Escape o botón de cancelar/pausa
	if event.is_action_pressed("ui_cancel") or (event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_ESCAPE):
		get_viewport().set_input_as_handled()
		_on_skip_pressed()
		return

	var should_advance: bool = false

	# Detectar pulsación de teclas ESPACIO o ENTER (o keypad enter)
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_SPACE or event.keycode == KEY_ENTER or event.keycode == KEY_KP_ENTER:
			should_advance = true

	# Detectar clic izquierdo del ratón (excepto sobre el botón Skip)
	elif event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		if not skip_button.get_global_rect().has_point(event.global_position):
			should_advance = true

	# Detectar botón de acción en gamepad (ui_accept / A / X)
	elif event.is_action_pressed("ui_accept"):
		should_advance = true

	if not should_advance:
		return

	get_viewport().set_input_as_handled()

	if _is_typing:
		# Primera pulsación: completa inmediatamente el texto
		_complete_typing_instantly()
	else:
		# Segunda pulsación: avanza a la siguiente pantalla
		_advance_to_next()


# ═══════════════════════════════════════════════════════════════════
# GESTIÓN DE PANTALLAS Y CONTENIDO
# ═══════════════════════════════════════════════════════════════════

func _load_screen_content(index: int) -> void:
	if index < 0 or index >= SCREEN_DATA.size():
		return

	_current_index = index
	var data: Dictionary = SCREEN_DATA[index]

	# Cargar imagen de fondo
	var image_path: String = data["image"]
	var tex: Texture2D = load(image_path) as Texture2D
	if tex:
		bg_texture.texture = tex
	else:
		push_warning("[PrologoNarrativo] No se pudo cargar imagen: " + image_path)

	# Configurar texto completo en el Label
	_current_full_text = data["text"]
	dialog_label.text = _current_full_text
	dialog_label.visible_characters = 0

	# Ocultar indicador e iniciar escritura
	_hide_continue_indicator()
	_start_typewriter()


func _advance_to_next() -> void:
	if _current_index < SCREEN_DATA.size() - 1:
		_transition_to_screen(_current_index + 1)
	else:
		_finish_prologue_and_start_game()


func _transition_to_screen(next_index: int) -> void:
	if _is_transitioning or _is_ending:
		return
	_is_transitioning = true

	# Detener máquina de escribir e indicador
	_stop_typewriter()
	_hide_continue_indicator()

	# Desvanecer solo el fondo y el texto (el cuadro de diálogo se mantiene estable)
	var tw: Tween = create_tween().set_parallel(true)
	tw.tween_property(bg_fade_rect, "color:a", 1.0, FADE_BETWEEN_SCREENS)\
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tw.tween_property(dialog_label, "modulate:a", 0.0, FADE_BETWEEN_SCREENS * 0.8)\
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	await tw.finished

	# Actualizar imagen y texto
	_load_screen_content(next_index)
	dialog_label.modulate.a = 1.0

	# Reaparecer la nueva imagen
	var tw_in: Tween = create_tween()
	tw_in.tween_property(bg_fade_rect, "color:a", 0.0, FADE_BETWEEN_SCREENS)\
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	await tw_in.finished

	_is_transitioning = false


func _finish_prologue_and_start_game() -> void:
	if _is_ending:
		return
	_is_ending = true
	_is_transitioning = true

	_stop_typewriter()
	_hide_continue_indicator()

	# Desvanecer la pantalla completa a negro
	var tw: Tween = create_tween()
	tw.tween_property(screen_fade_rect, "color:a", 1.0, FADE_FINAL)\
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	await tw.finished

	prologo_finished.emit()

	# Cargar la pantalla de carga (o la escena del juego como respaldo)
	var target_scene := SCENE_LOADING if ResourceLoader.exists(SCENE_LOADING) else SCENE_GAME
	if ResourceLoader.exists(target_scene):
		get_tree().change_scene_to_file(target_scene)
	else:
		push_error("[PrologoNarrativo] Escena no encontrada en: " + target_scene)


# ═══════════════════════════════════════════════════════════════════
# MÁQUINA DE ESCRIBIR
# ═══════════════════════════════════════════════════════════════════

func _start_typewriter() -> void:
	_is_typing = true
	dialog_label.visible_characters = 0
	typewriter_timer.wait_time = BASE_CHAR_DELAY
	typewriter_timer.start()


func _stop_typewriter() -> void:
	_is_typing = false
	typewriter_timer.stop()


func _complete_typing_instantly() -> void:
	_stop_typewriter()
	dialog_label.visible_characters = -1
	_show_continue_indicator()


func _on_typewriter_tick() -> void:
	var total_chars: int = _current_full_text.length()
	if dialog_label.visible_characters >= total_chars:
		_complete_typing_instantly()
		return

	dialog_label.visible_characters += 1

	if dialog_label.visible_characters >= total_chars:
		_complete_typing_instantly()
		return

	# Pausas naturales para puntuación en español
	var current_idx: int = dialog_label.visible_characters - 1
	if current_idx >= 0 and current_idx < total_chars:
		var ch: String = _current_full_text[current_idx]
		if ch == "." or ch == ":" or ch == "…" or ch == "?" or ch == "!":
			typewriter_timer.wait_time = BASE_CHAR_DELAY * 7.0
		elif ch == "," or ch == ";":
			typewriter_timer.wait_time = BASE_CHAR_DELAY * 4.0
		else:
			typewriter_timer.wait_time = BASE_CHAR_DELAY


# ═══════════════════════════════════════════════════════════════════
# INDICADOR VISUAL DE CONTINUAR
# ═══════════════════════════════════════════════════════════════════

func _show_continue_indicator() -> void:
	continue_indicator.visible = true
	if _indicator_tween and _indicator_tween.is_valid():
		_indicator_tween.kill()

	continue_indicator.modulate.a = 0.2
	_indicator_tween = create_tween().set_loops()
	_indicator_tween.tween_property(continue_indicator, "modulate:a", 1.0, 0.4)\
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	_indicator_tween.tween_property(continue_indicator, "modulate:a", 0.2, 0.4)\
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)


func _hide_continue_indicator() -> void:
	if _indicator_tween and _indicator_tween.is_valid():
		_indicator_tween.kill()
	continue_indicator.visible = false
	continue_indicator.modulate.a = 0.0


# ═══════════════════════════════════════════════════════════════════
# BOTÓN SKIP >>
# ═══════════════════════════════════════════════════════════════════

func _on_skip_pressed() -> void:
	if _is_ending:
		return
	_finish_prologue_and_start_game()


# ═══════════════════════════════════════════════════════════════════
# TRANSICIÓN INICIAL
# ═══════════════════════════════════════════════════════════════════

func _fade_in_screen() -> void:
	var tw: Tween = create_tween()
	tw.tween_property(screen_fade_rect, "color:a", 0.0, FADE_FINAL)\
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
