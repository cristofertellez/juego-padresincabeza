class_name ChurchLandmarksManager
extends Node2D

## Gestor de Elementos Decorativos e Históricos de la Catedral de León
## Controla la instanciación de los 6 elementos decorativos:
## - 3 Objetos de piso con colisión física y ordenamiento Y-Sort (Altar Mayor, Estatua de Jesús, Tumba de Rubén Darío)
## - 3 Elementos de techo/muro alto (Rosetón del Ojo, Cruz Radiante, Colgante del Espíritu Santo)
## - Sistema de interacción con UI Box de información histórica y religiosa

signal landmark_inspected(data: Dictionary)

@export var data_file_path: String = "res://assets/data/church_landmarks.json"
@export var auto_spawn_on_ready: bool = true

var floor_props_container: Node2D = null
var ceiling_props_container: Node2D = null
var props: Array[ChurchProp] = []
var active_dialog_box: Control = null
var is_dialog_animating: bool = false

func _ready() -> void:
	if auto_spawn_on_ready:
		spawn_all_landmarks()

func spawn_all_landmarks() -> void:
	_ensure_containers()
	
	var landmarks_data: Array = _load_landmarks_data()
	for item_data in landmarks_data:
		_instantiate_landmark(item_data)
		
	_setup_dialog_box()

func _ensure_containers() -> void:
	# Contenedor para objetos en el suelo (con Y-Sort activo)
	# z_index = 5 sincronizado con el Player para ordenamiento de profundidad correcto
	if not floor_props_container:
		floor_props_container = Node2D.new()
		floor_props_container.name = "FloorLandmarks"
		floor_props_container.z_index = 5
		floor_props_container.y_sort_enabled = true
		add_child(floor_props_container)
		
	# Contenedor para elementos de techo y elementos suspendidos (sin colisión física)
	if not ceiling_props_container:
		ceiling_props_container = Node2D.new()
		ceiling_props_container.name = "CeilingLandmarks"
		ceiling_props_container.z_index = 12 # Renderizar sobre el jugador y sombras
		add_child(ceiling_props_container)

func _instantiate_landmark(item_data: Dictionary) -> ChurchProp:
	var prop := ChurchProp.new()
	var category: String = item_data.get("category", "floor")
	
	if category == "floor":
		floor_props_container.add_child(prop)
	else:
		ceiling_props_container.add_child(prop)
		
	prop.setup(item_data)
	prop.interacted.connect(_on_prop_interacted)
	props.append(prop)
	return prop

func _load_landmarks_data() -> Array:
	if not FileAccess.file_exists(data_file_path):
		return _get_default_landmarks_data()
		
	var file := FileAccess.open(data_file_path, FileAccess.READ)
	if not file:
		return _get_default_landmarks_data()
		
	var json_str := file.get_as_text()
	var test_json := JSON.new()
	var err := test_json.parse(json_str)
	if err != OK:
		push_error("Error parseando church_landmarks.json: %s" % test_json.get_error_message())
		return _get_default_landmarks_data()
		
	var result: Variant = test_json.data
	if typeof(result) == TYPE_DICTIONARY and result.has("landmarks"):
		return result["landmarks"]
		
	return _get_default_landmarks_data()

func _on_prop_interacted(item_data: Dictionary) -> void:
	landmark_inspected.emit(item_data)
	show_inspection_dialog(item_data)

## Configuración de la caja de diálogo (UI Box) con estilo colonial y barroco
func _setup_dialog_box() -> void:
	var canvas := CanvasLayer.new()
	canvas.name = "LandmarkDialogLayer"
	canvas.layer = 100 # Sobre cualquier elemento de juego o canvas_modulate
	add_child(canvas)
	
	var dialog := PanelContainer.new()
	dialog.name = "InspectionDialog"
	dialog.visible = false
	dialog.custom_minimum_size = Vector2(480, 130)
	
	# Centrado en la parte inferior de la pantalla de juego (640x360)
	dialog.anchor_left = 0.5
	dialog.anchor_right = 0.5
	dialog.anchor_top = 1.0
	dialog.anchor_bottom = 1.0
	dialog.offset_left = -240
	dialog.offset_right = 240
	dialog.offset_top = -150
	dialog.offset_bottom = -20
	
	# Estilo colonial tipo marco dorado
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.07, 0.06, 0.10, 0.95)
	style.set_border_width_all(2)
	style.border_color = Color("d4af37") # Oro colonial
	style.set_corner_radius_all(6)
	style.content_margin_left = 16
	style.content_margin_right = 16
	style.content_margin_top = 10
	style.content_margin_bottom = 10
	dialog.add_theme_stylebox_override("panel", style)
	
	var vbox := VBoxContainer.new()
	vbox.name = "VBox"
	vbox.add_theme_constant_override("separation", 6)
	
	# Encabezado con título
	var header := HBoxContainer.new()
	header.name = "Header"
	
	var title_lbl := Label.new()
	title_lbl.name = "TitleLabel"
	title_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title_lbl.add_theme_color_override("font_color", Color("ffd700")) # Oro brillante
	title_lbl.add_theme_font_size_override("font_size", 13)
	header.add_child(title_lbl)
	
	var badge_lbl := Label.new()
	badge_lbl.name = "BadgeLabel"
	badge_lbl.text = "Catedral de León"
	badge_lbl.add_theme_color_override("font_color", Color("a89b80"))
	badge_lbl.add_theme_font_size_override("font_size", 9)
	header.add_child(badge_lbl)
	vbox.add_child(header)
	
	# Línea divisoria dorada
	var sep := ColorRect.new()
	sep.custom_minimum_size = Vector2(0, 1)
	sep.color = Color(0.83, 0.69, 0.22, 0.5)
	vbox.add_child(sep)
	
	# Texto descriptivo histórico / religioso
	var desc_lbl := Label.new()
	desc_lbl.name = "DescLabel"
	desc_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	desc_lbl.add_theme_color_override("font_color", Color("f2eee6"))
	desc_lbl.add_theme_font_size_override("font_size", 11)
	vbox.add_child(desc_lbl)
	
	# Indicador de cómo cerrar
	var hint_lbl := Label.new()
	hint_lbl.name = "HintLabel"
	hint_lbl.text = "[Presiona E, Espacio o Clic para cerrar]"
	hint_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	hint_lbl.add_theme_color_override("font_color", Color("9e9689"))
	hint_lbl.add_theme_font_size_override("font_size", 9)
	vbox.add_child(hint_lbl)
	
	dialog.add_child(vbox)
	canvas.add_child(dialog)
	active_dialog_box = dialog

## Despliega el cuadro de diálogo con la información del objeto
func show_inspection_dialog(item_data: Dictionary) -> void:
	if not active_dialog_box:
		return
		
	var inter: Dictionary = item_data.get("interaction", {})
	var title_node := active_dialog_box.get_node_or_null("VBox/Header/TitleLabel") as Label
	var desc_node := active_dialog_box.get_node_or_null("VBox/DescLabel") as Label
	
	if title_node:
		title_node.text = inter.get("title", item_data.get("name", "Monumento Histórico"))
	if desc_node:
		desc_node.text = inter.get("description", "Elemento patrimonial de la Real Basílica Catedral de León.")
		
	active_dialog_box.visible = true
	active_dialog_box.modulate.a = 0.0
	is_dialog_animating = true
	
	var tw := create_tween()
	tw.tween_property(active_dialog_box, "modulate:a", 1.0, 0.15)
	tw.finished.connect(func(): is_dialog_animating = false)

func _unhandled_input(event: InputEvent) -> void:
	if active_dialog_box and active_dialog_box.visible and not is_dialog_animating:
		var close_pressed := false
		if event is InputEventKey and event.pressed and not event.echo:
			if event.keycode == KEY_E or event.keycode == KEY_SPACE or event.keycode == KEY_ESCAPE or event.keycode == KEY_ENTER:
				close_pressed = true
		elif event is InputEventMouseButton and event.pressed:
			close_pressed = true
		elif event.is_action_pressed("ui_accept") or event.is_action_pressed("ui_cancel"):
			close_pressed = true
			
		if close_pressed:
			hide_inspection_dialog()
			get_viewport().set_input_as_handled()

func hide_inspection_dialog() -> void:
	if not active_dialog_box or not active_dialog_box.visible or is_dialog_animating:
		return
		
	is_dialog_animating = true
	var tw := create_tween()
	tw.tween_property(active_dialog_box, "modulate:a", 0.0, 0.12)
	tw.finished.connect(func():
		active_dialog_box.visible = false
		is_dialog_animating = false
	)

## Definición completa de los 6 elementos decorativos de la Catedral
func _get_default_landmarks_data() -> Array:
	return [
		# 1. Altar Mayor (Piso / Presbiterio)
		{
			"id": "altar_mayor",
			"name": "Altar Mayor Dorado",
			"sprite": "altar_mayor.png",
			"category": "floor",
			"position": { "x": 960, "y": 200 },
			"hitbox": { "width": 110, "height": 36, "offset_x": 0, "offset_y": -18 },
			"interaction": {
				"enabled": true,
				"radius": 100.0,
				"action_prompt": "Presiona [E] para inspeccionar",
				"title": "Altar Mayor de la Catedral",
				"description": "El majestuoso Altar Mayor en estilo barroco dorado. En la parte superior resplandece la imagen de la Asunción de la Virgen María con halos celestiales, coronando el sagrario del Presbiterio de la Catedral de León."
			}
		},
		# 2. Estatua de Jesús de la Humildad (Piso / Nave Lateral Izquierda)
		{
			"id": "estatua_jesus_humildad",
			"name": "Señor de la Humildad y Paciencia",
			"sprite": "estatua_jesus_humildad.png",
			"category": "floor",
			"position": { "x": 400, "y": 600 },
			"hitbox": { "width": 64, "height": 26, "offset_x": 0, "offset_y": -13 },
			"interaction": {
				"enabled": true,
				"radius": 85.0,
				"action_prompt": "Presiona [E] para inspeccionar",
				"title": "Jesús de la Humildad y Paciencia",
				"description": "Venerada talla barroca en madera policromada. Muestra a Cristo sentado, meditabundo y coronado de espinas con manto púrpura, sobre un pedestal rodeado por ofrendas de helechos y flores de la comunidad."
			}
		},
		# 3. Tumba de Rubén Darío (Piso / Columna Central)
		{
			"id": "tumba_ruben_dario",
			"name": "Tumba de Rubén Darío",
			"sprite": "tumba_ruben_dario.png",
			"category": "floor",
			"position": { "x": 1150, "y": 550 },
			"hitbox": { "width": 84, "height": 30, "offset_x": 0, "offset_y": -15 },
			"interaction": {
				"enabled": true,
				"radius": 90.0,
				"action_prompt": "Presiona [E] para inspeccionar",
				"title": "Tumba de Rubén Darío (León Doliente)",
				"description": "Sepulcro del ilustre poeta nicaragüense, padre del Modernismo. El león de mármol doliente llora recostado sobre la bandera nacional, esculpido en 1916 al pie de la columna de San Pablo."
			}
		},
		# 4. Rosetón Cenital (Techo / Bóveda Central)
		{
			"id": "roseton_ojo_azul",
			"name": "Rosetón Central del Ojo de la Providencia",
			"sprite": "roseton_ojo_azul.png",
			"category": "ceiling",
			"position": { "x": 960, "y": 540 },
			"z_index": 12,
			"hitbox": null,
			"interaction": { "enabled": false }
		},
		# 5. Cruz Radiante con Ojo (Techo / Bóveda)
		{
			"id": "cruz_ojo_rayos",
			"name": "Cruz Radiante con el Ojo Divino",
			"sprite": "cruz_ojo_rayos.png",
			"category": "ceiling",
			"position": { "x": 960, "y": 800 },
			"z_index": 12,
			"hitbox": null,
			"interaction": { "enabled": false }
		},
		# 6. Colgante del Espíritu Santo (Techo / Suspendido)
		{
			"id": "colgante_espiritu_santo",
			"name": "Colgante del Espíritu Santo",
			"sprite": "colgante_espiritu_santo.png",
			"category": "ceiling",
			"position": { "x": 800, "y": 450 },
			"z_index": 14,
			"hitbox": null,
			"interaction": { "enabled": false }
		}
	]
