class_name PantallaInicio
extends Control

## Pantalla de inicio para "Búsqueda de Ojos".
## Integra video de fondo, botones transparentes interactivos y cursor guiado.

@onready var video_player: VideoStreamPlayer = $VideoStreamPlayer
@onready var btn_nueva_partida: Button = $BotonNuevaPartida
@onready var btn_continuar: Button = $BotonContinuar
@onready var btn_opciones: Button = $BotonOpciones
@onready var cursor: TextureRect = $Cursor
@onready var panel_opciones: Panel = $PanelOpciones

# Desplazamiento del cursor respecto a la esquina superior izquierda del botón
const CURSOR_OFFSET := Vector2(-22, -2)
const SCENE_GAME := "res://main.tscn"

var buttons: Array[Button] = []
var current_index: int = 0
var tween_cursor: Tween
var is_in_options: bool = false

func _ready() -> void:
	buttons = [btn_nueva_partida, btn_continuar, btn_opciones]
	
	# Asegurar reproducción del video en loop
	if video_player:
		video_player.loop = true
		if not video_player.is_playing():
			video_player.play()
		video_player.finished.connect(_on_video_finished)
	
	# Conexión de señales para ratón, teclado y mando
	for i in range(buttons.size()):
		var btn := buttons[i]
		btn.mouse_entered.connect(_on_button_mouse_entered.bind(i))
		btn.focus_entered.connect(_on_button_focus_entered.bind(i))
	
	btn_nueva_partida.pressed.connect(_on_nueva_partida_pressed)
	btn_continuar.pressed.connect(_on_continuar_pressed)
	btn_opciones.pressed.connect(_on_opciones_pressed)
	
	if panel_opciones:
		panel_opciones.visible = false
		_setup_panel_opciones()
	
	# Seleccionar primer botón ("NUEVA PARTIDA")
	await get_tree().process_frame
	select_button(0, false)
	btn_nueva_partida.grab_focus()

func _input(event: InputEvent) -> void:
	if is_in_options:
		if event.is_action_pressed("ui_cancel"):
			cerrar_opciones()
			get_viewport().set_input_as_handled()
		return
	
	# Navegación con flechas / D-Pad
	if event.is_action_pressed("ui_left"):
		var prev_idx := (current_index - 1 + buttons.size()) % buttons.size()
		select_button(prev_idx, true)
		buttons[prev_idx].grab_focus()
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("ui_right"):
		var next_idx := (current_index + 1) % buttons.size()
		select_button(next_idx, true)
		buttons[next_idx].grab_focus()
		get_viewport().set_input_as_handled()

func select_button(index: int, animate: bool = true) -> void:
	if index < 0 or index >= buttons.size():
		return
	
	current_index = index
	var target_btn := buttons[index]
	var target_pos := target_btn.position + CURSOR_OFFSET
	
	if cursor:
		if tween_cursor and tween_cursor.is_valid():
			tween_cursor.kill()
		
		if animate:
			tween_cursor = create_tween().set_parallel(true)
			tween_cursor.tween_property(cursor, "position", target_pos, 0.16)\
				.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
			# Efecto sutil de pulso al cambiar de opción
			cursor.scale = Vector2(1.2, 1.2)
			cursor.pivot_offset = cursor.size * 0.5
			tween_cursor.tween_property(cursor, "scale", Vector2.ONE, 0.16)\
				.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		else:
			cursor.position = target_pos
			cursor.scale = Vector2.ONE
			cursor.pivot_offset = cursor.size * 0.5

func _on_button_mouse_entered(index: int) -> void:
	if is_in_options:
		return
	select_button(index, true)
	buttons[index].grab_focus()

func _on_button_focus_entered(index: int) -> void:
	if is_in_options:
		return
	if current_index != index:
		select_button(index, true)

func _on_video_finished() -> void:
	# Respaldo en caso de que loop no se reanude automáticamente
	if video_player:
		video_player.play()

# -------------------------------------------------------------
# LÓGICA DE BOTONES
# -------------------------------------------------------------

func _on_nueva_partida_pressed() -> void:
	if is_in_options:
		return
	print("[PantallaInicio] -> Iniciando Nueva Partida...")
	
	# Animación de confirmación con el cursor
	if cursor:
		var tw := create_tween()
		tw.tween_property(cursor, "scale", Vector2(1.4, 1.4), 0.1)
		tw.tween_property(cursor, "scale", Vector2.ONE, 0.1)
		await tw.finished
	
	if ResourceLoader.exists(SCENE_GAME):
		get_tree().change_scene_to_file(SCENE_GAME)
	else:
		push_warning("No se encontró la escena del juego en: " + SCENE_GAME)

func _on_continuar_pressed() -> void:
	if is_in_options:
		return
	# Como se requiere: imprimir en consola la carga de partida
	print("[PantallaInicio] -> Continuar: Cargando partida guardada...")
	
	# Efecto visual de feedback
	if cursor:
		var tw := create_tween()
		tw.tween_property(cursor, "position:x", cursor.position.x + 4.0, 0.08)
		tw.tween_property(cursor, "position:x", cursor.position.x, 0.08)

func _on_opciones_pressed() -> void:
	if is_in_options:
		return
	abrir_opciones()

func abrir_opciones() -> void:
	print("[PantallaInicio] -> Abriendo menú de opciones...")
	is_in_options = true
	if cursor:
		cursor.visible = false
	if panel_opciones:
		panel_opciones.visible = true
		var btn_volver := panel_opciones.get_node_or_null("BtnVolver") as Button
		if btn_volver:
			btn_volver.grab_focus()

func cerrar_opciones() -> void:
	print("[PantallaInicio] -> Cerrando menú de opciones.")
	is_in_options = false
	if panel_opciones:
		panel_opciones.visible = false
	if cursor:
		cursor.visible = true
	buttons[current_index].grab_focus()
	select_button(current_index, false)

func _setup_panel_opciones() -> void:
	if not panel_opciones:
		return
	var btn_volver := panel_opciones.get_node_or_null("BtnVolver") as Button
	if btn_volver and not btn_volver.pressed.is_connected(cerrar_opciones):
		btn_volver.pressed.connect(cerrar_opciones)
	
	var slider_volumen := panel_opciones.get_node_or_null("HBoxVolumen/HSliderVolumen") as HSlider
	if slider_volumen:
		var master_idx := AudioServer.get_bus_index("Master")
		slider_volumen.value = db_to_linear(AudioServer.get_bus_volume_db(master_idx))
		slider_volumen.value_changed.connect(func(val: float):
			AudioServer.set_bus_volume_db(master_idx, linear_to_db(clampf(val, 0.0001, 1.0)))
		)
	
	var check_fullscreen := panel_opciones.get_node_or_null("HBoxPantalla/CheckPantalla") as CheckBox
	if check_fullscreen:
		check_fullscreen.button_pressed = (DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_FULLSCREEN)
		check_fullscreen.toggled.connect(func(toggled_on: bool):
			if toggled_on:
				DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
			else:
				DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
		)
