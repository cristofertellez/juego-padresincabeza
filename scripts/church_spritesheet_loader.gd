class_name ChurchSpritesheetLoader
extends Node2D

## Módulo automático para:
## 1. Cargar "iglesia_spritesheet.png" y aplicar Chroma Key sobre el fondo magenta (#FF00FF).
## 2. Recortar los 9 sprites usando coordenadas normalizadas y detección de bounding box exacta.
## 3. Escalar proporcionalmente los sprites a la escala del jugador y colocarlos en el mapa con colisión/Y-Sort o capas de techo.

signal sprites_extracted(textures: Dictionary)
signal landmark_inspected(data: Dictionary)

@export var spritesheet_path: String = "res://assets/iglesia_spritesheet.png"
@export var chroma_key: Color = Color(1.0, 0.0, 1.0) # #FF00FF Magenta puro
@export var tolerance: float = 0.15 # Tolerancia para limpiar bordes con compresión
@export var auto_spawn_on_ready: bool = true

# Definición de regiones normalizadas (0.0 a 1.0) y tamaños objetivo en píxeles (escala del jugador)
const SPRITE_DEFINITIONS: Dictionary = {
	"altar_mayor": {
		"rect": Rect2(0.00, 0.00, 0.38, 0.65),
		"target_max_dim": 160,
		"category": "floor",
		"map_pos": Vector2(960, 200),
		"hitbox": { "width": 90, "height": 34, "offset_x": 0, "offset_y": -17 },
		"name": "Altar Mayor Dorado",
		"prompt": "[E] Examinar Altar Mayor",
		"desc": "El imponente Altar Mayor de la Catedral de León en estilo barroco dorado. La Virgen de la Asunción preside la cúspide rodeada de rayos celestiales y la sagrada custodia."
	},
	"estatua_jesus_humildad": {
		"rect": Rect2(0.36, 0.01, 0.22, 0.38),
		"target_max_dim": 80,
		"category": "floor",
		"map_pos": Vector2(400, 600),
		"hitbox": { "width": 52, "height": 24, "offset_x": 0, "offset_y": -12 },
		"name": "Señor de la Humildad y Paciencia",
		"prompt": "[E] Acercarse a la Imagen",
		"desc": "Talla barroca de Jesús reflexivo, sentado en su trono de madera noble con túnica morada y caña de dolor, rodeado de frondosos helechos."
	},
	"tumba_ruben_dario": {
		"rect": Rect2(0.57, 0.01, 0.23, 0.36),
		"target_max_dim": 100,
		"category": "floor",
		"map_pos": Vector2(1150, 550),
		"hitbox": { "width": 78, "height": 28, "offset_x": 0, "offset_y": -14 },
		"name": "Tumba de Rubén Darío",
		"prompt": "[E] Leer Monumento",
		"desc": "El melancólico león de mármol esculpido custodia el sepulcro de Rubén Darío. Sobre la columna reposa la corona de laurel de la inmortalidad literaria."
	},
	"roseton_ojo_azul": {
		"rect": Rect2(0.77, 0.02, 0.22, 0.32),
		"target_max_dim": 96,
		"category": "ceiling",
		"z_index": 12,
		"map_pos": Vector2(960, 540),
		"name": "Rosetón Central del Ojo",
		"desc": "Rosetón cenital en la bóveda principal con fondo azul y destellos dorados que enmarcan la omnisciencia divina."
	},
	"cruz_ojo_rayos": {
		"rect": Rect2(0.38, 0.37, 0.38, 0.31),
		"target_max_dim": 96,
		"category": "ceiling",
		"z_index": 12,
		"map_pos": Vector2(960, 800),
		"name": "Cruz Radiante con el Ojo",
		"desc": "Altorrelieve de yesería colonial con nubes y cuatro largos haces cruzados rodeando el triángulo del Ojo de la Providencia."
	},
	"relieve_pelicano": {
		"rect": Rect2(0.01, 0.66, 0.30, 0.31),
		"target_max_dim": 72,
		"category": "wall_high",
		"z_index": 8,
		"map_pos": Vector2(700, 380),
		"name": "Relieve del Pelícano",
		"desc": "Símbolo bíblico de sacrificio en la pechina del arco: el pelícano entregando su sangre para alimentar a sus crías."
	},
	"relieve_querubines": {
		"rect": Rect2(0.31, 0.68, 0.26, 0.29),
		"target_max_dim": 72,
		"category": "wall_high",
		"z_index": 8,
		"map_pos": Vector2(1450, 200),
		"name": "Relieve de los Querubines",
		"desc": "Seis cabezas de ángeles alados en piedra caliza que resguardan la mirada del Ojo Sagrado."
	},
	"colgante_espiritu_santo": {
		"rect": Rect2(0.56, 0.68, 0.17, 0.28),
		"target_max_dim": 68,
		"category": "ceiling",
		"z_index": 14,
		"map_pos": Vector2(800, 450),
		"name": "Paloma del Espíritu Santo",
		"desc": "Figura suspendida de una paloma blanca con alas extendidas ante un resplandor dorado triangular."
	},
	"altar_plata_jesus": {
		"rect": Rect2(0.73, 0.48, 0.27, 0.51),
		"target_max_dim": 120,
		"category": "floor",
		"map_pos": Vector2(1550, 350),
		"hitbox": { "width": 64, "height": 28, "offset_x": 0, "offset_y": -14 },
		"name": "Altar de Plata (Capilla del Sagrario)",
		"prompt": "[E] Contemplar Altar de Plata",
		"desc": "Mesa de plata repujada con candelabros dorados y la figura de Cristo bendiciendo bajo un dosel custodiado por ángeles."
	}
}

var extracted_textures: Dictionary = {} # id -> ImageTexture
var floor_container: Node2D = null
var ceiling_container: Node2D = null
var active_dialog: Control = null

func _ready() -> void:
	if auto_spawn_on_ready:
		load_and_instantiate_all()

## Función principal: Carga la hoja, remueve el fondo magenta, recorta y ubica los objetos
func load_and_instantiate_all() -> void:
	# 1. Cargar la imagen base
	var raw_image := _load_spritesheet_image()
	if not raw_image:
		push_error("No se pudo cargar la imagen del spritesheet en %s" % spritesheet_path)
		return
		
	# 2. Convertir y aplicar Chroma Key (Magenta -> Transparente)
	var keyed_image := process_chroma_key(raw_image, chroma_key, tolerance)
	
	# 3. Recortar y escalar los 9 sprites con bounding boxes exactos
	extracted_textures = extract_all_sprites(keyed_image)
	sprites_extracted.emit(extracted_textures)
	
	# 4. Instanciar en el mapa con Y-Sort o capa de techo
	spawn_in_map()

## 1. ALGORITMO DE CHROMA KEY
func process_chroma_key(source_img: Image, key_col: Color, tol: float) -> Image:
	var img := source_img.duplicate() as Image
	if img.get_format() != Image.FORMAT_RGBA8:
		img.convert(Image.FORMAT_RGBA8)
		
	var w: int = img.get_width()
	var h: int = img.get_height()
	
	for y in range(h):
		for x in range(w):
			var c: Color = img.get_pixel(x, y)
			# Distancia perceptual al color magenta (R: 1.0, G: 0.0, B: 1.0)
			var dr := absf(c.r - key_col.r)
			var dg := absf(c.g - key_col.g)
			var db := absf(c.b - key_col.b)
			
			if dr <= tol and dg <= tol and db <= tol:
				img.set_pixel(x, y, Color(0, 0, 0, 0))
			# Limpieza de halos de compresión JPEG cercanos al magenta
			elif c.r > 0.82 and c.b > 0.82 and c.g < 0.20:
				img.set_pixel(x, y, Color(0, 0, 0, 0))
				
	return img

## 2. RECORTE DE SPRITES CON DETECCIÓN DE BOUNDING BOX
func extract_all_sprites(keyed_img: Image) -> Dictionary:
	var textures: Dictionary = {}
	var sheet_w: int = keyed_img.get_width()
	var sheet_h: int = keyed_img.get_height()
	
	for key in SPRITE_DEFINITIONS.keys():
		var def: Dictionary = SPRITE_DEFINITIONS[key]
		var norm_rect: Rect2 = def["rect"]
		
		# Región inicial basada en porcentajes normalizados
		var start_x: int = clampi(int(norm_rect.position.x * sheet_w), 0, sheet_w - 1)
		var start_y: int = clampi(int(norm_rect.position.y * sheet_h), 0, sheet_h - 1)
		var region_w: int = clampi(int(norm_rect.size.x * sheet_w), 1, sheet_w - start_x)
		var region_h: int = clampi(int(norm_rect.size.y * sheet_h), 1, sheet_h - start_y)
		
		# Búsqueda de isla / bounding box ajustado a píxeles no transparentes
		var min_x: int = start_x + region_w
		var max_x: int = -1
		var min_y: int = start_y + region_h
		var max_y: int = -1
		
		for y in range(start_y, start_y + region_h):
			for x in range(start_x, start_x + region_w):
				var px: Color = keyed_img.get_pixel(x, y)
				if px.a > 0.05: # Píxel visible
					if x < min_x: min_x = x
					if x > max_x: max_x = x
					if y < min_y: min_y = y
					if y > max_y: max_y = y
					
		if max_x < min_x or max_y < min_y:
			push_warning("No se encontraron píxeles para el sprite: %s" % key)
			continue
			
		var tight_rect := Rect2i(min_x, min_y, (max_x - min_x) + 1, (max_y - min_y) + 1)
		var cropped_img: Image = keyed_img.get_region(tight_rect)
		
		# Escala proporcional para integrarse naturalmente con el tamaño del jugador
		var max_dim: int = def.get("target_max_dim", 96)
		var orig_max: int = maxi(cropped_img.get_width(), cropped_img.get_height())
		var scale_factor: float = float(max_dim) / float(orig_max)
		
		var final_w: int = maxi(1, int(round(cropped_img.get_width() * scale_factor)))
		var final_h: int = maxi(1, int(round(cropped_img.get_height() * scale_factor)))
		
		# Re-escalar conservando la nitidez de pixel art
		cropped_img.resize(final_w, final_h, Image.INTERPOLATE_NEAREST)
		
		var tex := ImageTexture.create_from_image(cropped_img)
		textures[key] = tex
		
	return textures

## 3. POSICIONAMIENTO EN EL MAPA CON COLISIÓN / Y-SORT Y CAPAS DE ALTURA
func spawn_in_map() -> void:
	# Contenedor para objetos en el suelo (con Y-Sort activo)
	floor_container = Node2D.new()
	floor_container.name = "FloorChurchObjects"
	floor_container.y_sort_enabled = true
	add_child(floor_container)
	
	# Contenedor para relieves altos y bóveda de techo
	ceiling_container = Node2D.new()
	ceiling_container.name = "CeilingChurchObjects"
	ceiling_container.z_index = 12
	add_child(ceiling_container)
	
	_create_dialog_overlay()
	
	for key in SPRITE_DEFINITIONS.keys():
		var def: Dictionary = SPRITE_DEFINITIONS[key]
		var tex: Texture2D = extracted_textures.get(key)
		if not tex:
			continue
			
		var category: String = def.get("category", "floor")
		var is_floor: bool = (category == "floor")
		var spawn_pos: Vector2 = def.get("map_pos", Vector2.ZERO)
		
		var prop_node := Node2D.new()
		prop_node.name = "Prop_" + key
		prop_node.position = spawn_pos
		
		var sp := Sprite2D.new()
		sp.name = "Sprite"
		sp.texture = tex
		sp.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		
		if is_floor:
			prop_node.y_sort_enabled = true
			# Ajuste de pivote al pie del objeto para ordenamiento Y-Sort impecable
			sp.position = Vector2(0, -tex.get_height() / 2.0)
			prop_node.add_child(sp)
			
			# Añadir caja de colisión (Hitbox en la base)
			var hitbox_info: Dictionary = def.get("hitbox", {})
			var body := StaticBody2D.new()
			body.name = "Collider"
			body.y_sort_enabled = true
			
			var col := CollisionShape2D.new()
			var rect := RectangleShape2D.new()
			rect.size = Vector2(hitbox_info.get("width", 48), hitbox_info.get("height", 24))
			col.shape = rect
			col.position = Vector2(hitbox_info.get("offset_x", 0), hitbox_info.get("offset_y", 0))
			body.add_child(col)
			prop_node.add_child(body)
			
			# Área de interacción para detectar al jugador
			_add_interaction_detector(prop_node, def, tex.get_height())
			floor_container.add_child(prop_node)
		else:
			# Objeto de techo o pared alta: sin colisión física
			prop_node.z_index = def.get("z_index", 10)
			sp.position = Vector2.ZERO
			prop_node.add_child(sp)
			
			# Animación de suspensión suave para el Espíritu Santo
			if key == "colgante_espiritu_santo":
				var tw := create_tween().set_loops()
				tw.tween_property(sp, "position:y", -4.0, 1.8).set_trans(Tween.TRANS_SINE)
				tw.tween_property(sp, "position:y", 4.0, 1.8).set_trans(Tween.TRANS_SINE)
				
			ceiling_container.add_child(prop_node)

func _add_interaction_detector(node: Node2D, def: Dictionary, sprite_h: float) -> void:
	var area := Area2D.new()
	area.name = "InteractArea"
	area.collision_layer = 0
	area.collision_mask = 1 # Jugador
	
	var shape := CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = 85.0
	shape.shape = circle
	shape.position = Vector2(0, -20)
	area.add_child(shape)
	node.add_child(area)
	
	# Etiqueta flotante emergente
	var prompt := Label.new()
	prompt.name = "Prompt"
	prompt.text = def.get("prompt", "[E] Interactuar")
	prompt.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	prompt.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	prompt.position = Vector2(-100, -sprite_h - 18)
	prompt.custom_minimum_size = Vector2(200, 20)
	prompt.add_theme_color_override("font_color", Color("ffd700"))
	prompt.add_theme_color_override("font_shadow_color", Color.BLACK)
	prompt.add_theme_constant_override("shadow_offset_x", 1)
	prompt.add_theme_constant_override("shadow_offset_y", 1)
	prompt.add_theme_font_size_override("font_size", 11)
	prompt.modulate.a = 0.0
	prompt.visible = false
	node.add_child(prompt)
	
	var is_near := { "val": false }
	
	area.body_entered.connect(func(body):
		if body is Player or body.name == "Player":
			is_near.val = true
			prompt.visible = true
			var tw := create_tween()
			tw.tween_property(prompt, "modulate:a", 1.0, 0.2)
	)
	
	area.body_exited.connect(func(body):
		if body is Player or body.name == "Player":
			is_near.val = false
			var tw := create_tween()
			tw.tween_property(prompt, "modulate:a", 0.0, 0.2)
			tw.finished.connect(func(): if not is_near.val: prompt.visible = false)
	)
	
	# Manejar pulsación de tecla E / Espacio dentro de este nodo
	node.set_process_unhandled_input(true)
	node.script = load("res://scripts/church_prop_trigger.gd") if ResourceLoader.exists("res://scripts/church_prop_trigger.gd") else null

func _create_dialog_overlay() -> void:
	var canvas := CanvasLayer.new()
	canvas.name = "DialogCanvas"
	canvas.layer = 100
	add_child(canvas)
	
	var panel := PanelContainer.new()
	panel.name = "DialogPanel"
	panel.visible = false
	panel.custom_minimum_size = Vector2(460, 130)
	panel.anchor_left = 0.5
	panel.anchor_right = 0.5
	panel.anchor_top = 1.0
	panel.anchor_bottom = 1.0
	panel.offset_left = -230
	panel.offset_right = 230
	panel.offset_top = -150
	panel.offset_bottom = -20
	
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.06, 0.05, 0.08, 0.95)
	style.set_border_width_all(2)
	style.border_color = Color("d4af37")
	style.set_corner_radius_all(6)
	style.content_margin_left = 14
	style.content_margin_right = 14
	style.content_margin_top = 10
	style.content_margin_bottom = 10
	panel.add_theme_stylebox_override("panel", style)
	
	var vbox := VBoxContainer.new()
	var t_lbl := Label.new()
	t_lbl.name = "Title"
	t_lbl.add_theme_color_override("font_color", Color("ffd700"))
	t_lbl.add_theme_font_size_override("font_size", 14)
	vbox.add_child(t_lbl)
	
	var d_lbl := Label.new()
	d_lbl.name = "Desc"
	d_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	d_lbl.add_theme_color_override("font_color", Color("eae6df"))
	d_lbl.add_theme_font_size_override("font_size", 11)
	vbox.add_child(d_lbl)
	
	var close_lbl := Label.new()
	close_lbl.text = "[Presiona E o Espacio para cerrar]"
	close_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	close_lbl.add_theme_color_override("font_color", Color("8a8479"))
	close_lbl.add_theme_font_size_override("font_size", 9)
	vbox.add_child(close_lbl)
	
	panel.add_child(vbox)
	canvas.add_child(panel)
	active_dialog = panel

func show_dialog(title: String, description: String) -> void:
	if not active_dialog:
		return
	var t_node := active_dialog.get_node_or_null("VBoxContainer/Title") as Label
	var d_node := active_dialog.get_node_or_null("VBoxContainer/Desc") as Label
	if t_node: t_node.text = title
	if d_node: d_node.text = description
	
	active_dialog.visible = true
	active_dialog.modulate.a = 0.0
	var tw := create_tween()
	tw.tween_property(active_dialog, "modulate:a", 1.0, 0.15)
	if SoundManager.instance:
		SoundManager.instance.play_pickup()

func hide_dialog() -> void:
	if not active_dialog or not active_dialog.visible:
		return
	var tw := create_tween()
	tw.tween_property(active_dialog, "modulate:a", 0.0, 0.1)
	tw.finished.connect(func(): active_dialog.visible = false)

func _unhandled_input(event: InputEvent) -> void:
	if active_dialog and active_dialog.visible:
		var close: bool = false
		if event is InputEventKey and event.pressed and not event.echo:
			if event.keycode == KEY_E or event.keycode == KEY_SPACE or event.keycode == KEY_ESCAPE or event.keycode == KEY_ENTER:
				close = true
		elif event is InputEventMouseButton and event.pressed:
			close = true
		elif event.is_action_pressed("ui_accept") or event.is_action_pressed("ui_cancel"):
			close = true
		if close:
			hide_dialog()
			get_viewport().set_input_as_handled()

func _load_spritesheet_image() -> Image:
	var paths := [
		spritesheet_path,
		"res://assets/iglesia_spritesheet.jpg",
		"res://assets/iglesia_spritesheet.png"
	]
	
	for p in paths:
		if FileAccess.file_exists(p):
			var img := Image.new()
			var err := img.load(p)
			if err == OK:
				return img
				
	return null
