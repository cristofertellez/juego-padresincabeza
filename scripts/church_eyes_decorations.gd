class_name ChurchEyesDecorations
extends Node2D

## Gestor para los 7 Símbolos Sagrados de Ojos en el techo y muros altos de la Catedral.
## 1. Aplica filtro Chroma Key al fondo magenta (#FF00FF).
## 2. Instancia los 7 sprites en las coordenadas exactas especificadas.
## 3. Asigna z_index para renderizarlos por encima de los muros y por detrás del jugador, sin colisión.

# Capa de profundidad: Muros están en z=0, Jugador está en z=5.
# z_index = 2 garantiza que se dibuje SOBRE los muros/suelo y DETRÁS del personaje.
@export var ceiling_z_index: int = 2
@export var chroma_tolerance: float = 0.15 # Tolerancia para limpiar bordes de compresión
@export var add_divine_light: bool = true   # Sutil iluminación dorada/azul ambiental

# Distribución exacta de los 7 ojos
const EYE_CONFIGURATIONS: Array[Dictionary] = [
	# ojo1.png: Rosetón circular azul con rayos dorados
	{
		"file": "ojo1.png",
		"pos": Vector2(960, 540),
		"name": "Ojo1_Central_Principal",
		"light_color": Color("88bbf8"), # Resplandor azul místico
		"scale": Vector2(1.0, 1.0)
	},
	{
		"file": "ojo1.png",
		"pos": Vector2(300, 250),
		"name": "Ojo1_Lateral_Izquierda",
		"light_color": Color("88bbf8"),
		"scale": Vector2(0.9, 0.9)
	},
	{
		"file": "ojo1.png",
		"pos": Vector2(1620, 250),
		"name": "Ojo1_Lateral_Derecha",
		"light_color": Color("88bbf8"),
		"scale": Vector2(0.9, 0.9)
	},
	
	# ojo2.png: Relieve de cruz con anclas y rayos
	{
		"file": "ojo2.png",
		"pos": Vector2(600, 200),
		"name": "Ojo2_Superior_Izquierda",
		"light_color": Color("ffe29e"), # Resplandor cálido de cantera
		"scale": Vector2(0.95, 0.95)
	},
	{
		"file": "ojo2.png",
		"pos": Vector2(1320, 200),
		"name": "Ojo2_Superior_Derecha",
		"light_color": Color("ffe29e"),
		"scale": Vector2(0.95, 0.95)
	},
	{
		"file": "ojo2.png",
		"pos": Vector2(600, 850),
		"name": "Ojo2_Inferior_Izquierda",
		"light_color": Color("ffe29e"),
		"scale": Vector2(0.95, 0.95)
	},
	{
		"file": "ojo2.png",
		"pos": Vector2(1320, 850),
		"name": "Ojo2_Inferior_Derecha",
		"light_color": Color("ffe29e"),
		"scale": Vector2(0.95, 0.95)
	}
]

var cached_textures: Dictionary = {}

func _ready() -> void:
	z_index = ceiling_z_index
	spawn_all_eyes()

## Instancia los 7 elementos en sus posiciones
func spawn_all_eyes() -> void:
	for child in get_children():
		child.queue_free()
		
	# Cargar y procesar ambas texturas con Chroma Key
	var tex_ojo1 := get_chroma_keyed_texture("ojo1.png")
	var tex_ojo2 := get_chroma_keyed_texture("ojo2.png")
	
	for cfg in EYE_CONFIGURATIONS:
		var tex := tex_ojo1 if cfg["file"] == "ojo1.png" else tex_ojo2
		if not tex:
			continue
			
		var node := Node2D.new()
		node.name = cfg["name"]
		node.position = cfg["pos"]
		node.z_index = ceiling_z_index
		
		# Sprite sin colisión física
		var sprite := Sprite2D.new()
		sprite.name = "Sprite"
		sprite.texture = tex
		sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		sprite.scale = cfg.get("scale", Vector2.ONE)
		node.add_child(sprite)
		
		# Sutil iluminación tenue de arquitectura sacra
		if add_divine_light:
			var light := PointLight2D.new()
			light.name = "AmbientLight"
			light.texture = _create_halo_texture(120)
			light.color = cfg.get("light_color", Color("fff2cc"))
			light.energy = 0.45
			node.add_child(light)
			
		add_child(node)

## 1. CARGA Y FILTRO CHROMA KEY PARA MAGENTA (#FF00FF)
func get_chroma_keyed_texture(filename: String) -> Texture2D:
	if cached_textures.has(filename):
		return cached_textures[filename]
		
	var paths_to_try: Array[String] = [
		"res://assets/sprites/" + filename,
		"res://assets/" + filename
	]
	
	var raw_image: Image = null
	for p in paths_to_try:
		if FileAccess.file_exists(p):
			var img := Image.new()
			if img.load(p) == OK:
				raw_image = img
				break
				
	if not raw_image:
		push_error("No se pudo encontrar la imagen: %s" % filename)
		return null
		
	# Aplicar filtro de transparencia Chroma Key para magenta (#FF00FF)
	var processed_image := apply_chroma_key(raw_image, Color(1.0, 0.0, 1.0), chroma_tolerance)
	var texture := ImageTexture.create_from_image(processed_image)
	cached_textures[filename] = texture
	return texture

## Convierte píxeles magenta (RGB: 255, 0, 255) y halos de compresión en alpha = 0
func apply_chroma_key(source: Image, key_color: Color = Color(1.0, 0.0, 1.0), tol: float = 0.15) -> Image:
	var img := source.duplicate() as Image
	if img.get_format() != Image.FORMAT_RGBA8:
		img.convert(Image.FORMAT_RGBA8)
		
	var w: int = img.get_width()
	var h: int = img.get_height()
	var has_magenta := false
	
	for y in range(h):
		for x in range(w):
			var c: Color = img.get_pixel(x, y)
			
			# Distancia al color magenta puro
			var dr: float = absf(c.r - key_color.r)
			var dg: float = absf(c.g - key_color.g)
			var db: float = absf(c.b - key_color.b)
			
			if dr <= tol and dg <= tol and db <= tol:
				img.set_pixel(x, y, Color(0, 0, 0, 0))
				has_magenta = true
			# Limpieza de halos de compresión (rojo y azul altos, verde bajo)
			elif c.r > 0.82 and c.b > 0.82 and c.g < 0.25:
				img.set_pixel(x, y, Color(0, 0, 0, 0))
				has_magenta = true
				
	return img

## Genera una textura de halo de luz radial suave para el PointLight2D
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
