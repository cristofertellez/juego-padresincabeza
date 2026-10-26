class_name ChurchProp
extends Node2D

## Representa un elemento decorativo de la Catedral en el mapa.
## Maneja:
## - Carga y renderizado del sprite (con o sin shader de Chroma Key).
## - Ajuste de pivote y colisión en la base para ordenamiento de profundidad (Y-Sort).
## - Detección de proximidad con el jugador (Trigger zone).
## - Indicador visual flotante ("Presiona [E] para inspeccionar").
## - Despacho de eventos de interacción.

signal interacted(data: Dictionary)
signal player_entered_range(prop: ChurchProp)
signal player_exited_range(prop: ChurchProp)

@export var data: Dictionary = {}

var is_floor_object: bool = true
var is_player_near: bool = false
var sprite_node: Sprite2D = null
var static_body: StaticBody2D = null
var interact_area: Area2D = null
var prompt_container: PanelContainer = null
var prompt_label: Label = null

var float_timer: float = 0.0
var base_prompt_y: float = -60.0

func _process(delta: float) -> void:
	# Animación de flotación suave tipo respiración para el indicador visual
	if is_player_near and prompt_container and prompt_container.visible:
		float_timer += delta * 3.5
		prompt_container.position.y = base_prompt_y + sin(float_timer) * 3.0

func setup(prop_data: Dictionary) -> void:
	data = prop_data
	name = "Prop_" + String(data.get("id", "item"))
	position = Vector2(data.get("position", {}).get("x", 0), data.get("position", {}).get("y", 0))
	
	var category: String = data.get("category", "floor")
	is_floor_object = (category == "floor")
	
	_setup_sprite()
	
	if is_floor_object:
		y_sort_enabled = true
		_setup_collision()
		if data.get("interaction", {}).get("enabled", true):
			_setup_interaction_area()
			_setup_prompt_ui()
	else:
		# Elemento de techo o pared alta (sin colisión con el jugador)
		z_index = data.get("z_index", 12)
		_setup_decorative_fx()

func _setup_sprite() -> void:
	sprite_node = Sprite2D.new()
	sprite_node.name = "Sprite"
	sprite_node.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	
	var filename: String = data.get("sprite", "")
	var tex: Texture2D = _load_prop_texture(filename)
	sprite_node.texture = tex
	
	# PIVOTE Y-SORT: Para objetos de suelo, situar el origen (0,0) en la base de contacto
	# para que el ordenamiento de profundidad (Y-Sorting) funcione naturalmente
	if is_floor_object and tex:
		var h := tex.get_height()
		sprite_node.position = Vector2(0, -h / 2.0)
	else:
		sprite_node.position = Vector2.ZERO
		
	# Si la textura original todavía tiene fondo magenta crudo, aplicar shader de chroma key
	if data.get("use_chroma_shader", false):
		sprite_node.material = ChromaKeyProcessor.create_chroma_shader_material()
		
	add_child(sprite_node)

func _setup_collision() -> void:
	var hitbox_data: Variant = data.get("hitbox")
	if not hitbox_data or typeof(hitbox_data) != TYPE_DICTIONARY:
		return
		
	static_body = StaticBody2D.new()
	static_body.name = "StaticBody"
	static_body.y_sort_enabled = true
	static_body.collision_layer = 1
	static_body.collision_mask = 1
	
	var col_shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	var hw: float = float(hitbox_data.get("width", 54))
	var hh: float = float(hitbox_data.get("height", 24))
	rect.size = Vector2(hw, hh)
	col_shape.shape = rect
	col_shape.position = Vector2(hitbox_data.get("offset_x", 0), hitbox_data.get("offset_y", -hh * 0.5))
	
	static_body.add_child(col_shape)
	add_child(static_body)

func _setup_interaction_area() -> void:
	interact_area = Area2D.new()
	interact_area.name = "InteractionArea"
	interact_area.collision_layer = 0
	interact_area.collision_mask = 1 # Capa del jugador
	
	var area_shape := CollisionShape2D.new()
	var circle := CircleShape2D.new()
	var radius: float = float(data.get("interaction", {}).get("radius", 90.0))
	circle.radius = radius
	area_shape.shape = circle
	area_shape.position = Vector2(0, -20)
	
	interact_area.add_child(area_shape)
	add_child(interact_area)
	
	interact_area.body_entered.connect(_on_body_entered)
	interact_area.body_exited.connect(_on_body_exited)

func _setup_prompt_ui() -> void:
	prompt_container = PanelContainer.new()
	prompt_container.name = "PromptContainer"
	prompt_container.z_index = 25 # Siempre por encima del objeto y del jugador
	
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.08, 0.07, 0.12, 0.88)
	style.border_color = Color("e5c158")
	style.set_border_width_all(1)
	style.set_corner_radius_all(4)
	style.content_margin_left = 8
	style.content_margin_right = 8
	style.content_margin_top = 3
	style.content_margin_bottom = 3
	prompt_container.add_theme_stylebox_override("panel", style)
	
	prompt_label = Label.new()
	prompt_label.name = "Label"
	var custom_prompt: String = data.get("interaction", {}).get("action_prompt", "Presiona [E] para inspeccionar")
	prompt_label.text = custom_prompt
	prompt_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	prompt_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	prompt_label.add_theme_color_override("font_color", Color("fff5d0"))
	prompt_label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.8))
	prompt_label.add_theme_constant_override("shadow_offset_x", 1)
	prompt_label.add_theme_constant_override("shadow_offset_y", 1)
	prompt_label.add_theme_font_size_override("font_size", 10)
	
	prompt_container.add_child(prompt_label)
	
	# Calcular altura sobre el sprite
	var sprite_h: float = 64.0
	if sprite_node and sprite_node.texture:
		sprite_h = sprite_node.texture.get_height()
		
	base_prompt_y = -sprite_h - 22.0
	prompt_container.position = Vector2(-80, base_prompt_y)
	prompt_container.custom_minimum_size = Vector2(160, 22)
	prompt_container.modulate.a = 0.0
	prompt_container.visible = false
	
	add_child(prompt_container)

func _setup_decorative_fx() -> void:
	var id: String = data.get("id", "")
	
	# Suspensión suave para el Espíritu Santo
	if id == "colgante_espiritu_santo":
		var tween := create_tween().set_loops()
		tween.tween_property(sprite_node, "position:y", -5.0, 2.0).set_trans(Tween.TRANS_SINE)
		tween.tween_property(sprite_node, "position:y", 5.0, 2.0).set_trans(Tween.TRANS_SINE)
	
	# Halo de luz mística para rosetón y cruz
	if "ojo" in id or "roseton" in id:
		var light := PointLight2D.new()
		light.name = "DivineLight"
		light.texture = _create_halo_texture(110)
		light.color = Color("9ec5ff") if "azul" in id else Color("ffe299")
		light.energy = 0.55
		add_child(light)

func _unhandled_input(event: InputEvent) -> void:
	if not is_player_near or not data.get("interaction", {}).get("enabled", true):
		return
		
	var is_interact_pressed := false
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_E or event.keycode == KEY_SPACE or event.keycode == KEY_ENTER:
			is_interact_pressed = true
	elif event.is_action_pressed("ui_accept"):
		is_interact_pressed = true
		
	if is_interact_pressed:
		trigger_interaction()
		get_viewport().set_input_as_handled()

func trigger_interaction() -> void:
	interacted.emit(data)
	if SoundManager.instance:
		SoundManager.instance.play_pickup()

func _on_body_entered(body: Node2D) -> void:
	if body is Player or body.name == "Player":
		is_player_near = true
		player_entered_range.emit(self)
		_animate_prompt(true)

func _on_body_exited(body: Node2D) -> void:
	if body is Player or body.name == "Player":
		is_player_near = false
		player_exited_range.emit(self)
		_animate_prompt(false)

func _animate_prompt(show: bool) -> void:
	if not prompt_container:
		return
	var tween := create_tween()
	if show:
		prompt_container.visible = true
		tween.tween_property(prompt_container, "modulate:a", 1.0, 0.18)
	else:
		tween.tween_property(prompt_container, "modulate:a", 0.0, 0.15)
		tween.finished.connect(func():
			if not is_player_near and prompt_container:
				prompt_container.visible = false
		)

func _load_prop_texture(filename: String) -> Texture2D:
	var paths := [
		"res://assets/sprites/" + filename,
		"res://assets/" + filename
	]
	
	for p in paths:
		if ResourceLoader.exists(p):
			var res := load(p)
			if res is Texture2D:
				return res
		elif FileAccess.file_exists(p):
			var tex := ChromaKeyProcessor.load_transparent_texture(p)
			if tex:
				return tex
				
	return _generate_placeholder_texture(filename)

func _generate_placeholder_texture(filename: String) -> Texture2D:
	var w: int = 64
	var h: int = 64
	var bg_col := Color("4a4238")
	var border_col := Color("ffd700")
	var img := Image.create(w, h, false, Image.FORMAT_RGBA8)
	img.fill(bg_col)
	for x in range(w):
		img.set_pixel(x, 0, border_col)
		img.set_pixel(x, h - 1, border_col)
	for y in range(h):
		img.set_pixel(0, y, border_col)
		img.set_pixel(w - 1, y, border_col)
	return ImageTexture.create_from_image(img)

func _create_halo_texture(radius: int) -> ImageTexture:
	var size: int = radius * 2
	var img := Image.create(size, size, false, Image.FORMAT_RGBA8)
	var center := Vector2(radius, radius)
	for x in range(size):
		for y in range(size):
			var dist := center.distance_to(Vector2(x, y))
			if dist < radius:
				var alpha: float = pow(1.0 - (dist / float(radius)), 2.0)
				img.set_pixel(x, y, Color(1, 1, 1, alpha))
			else:
				img.set_pixel(x, y, Color(0, 0, 0, 0))
	return ImageTexture.create_from_image(img)
