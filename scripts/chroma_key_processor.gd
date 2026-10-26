class_name ChromaKeyProcessor
extends RefCounted

## Procesador modular de Chroma Key para elementos 2D en Godot 4.
## Permite limpiar fondos magenta (#FF00FF) tanto a nivel de CPU (Image) como por Shader (GPU).

const MAGENTA_KEY := Color(1.0, 0.0, 1.0, 1.0) # #FF00FF

## Carga una textura desde disco y procesa el color magenta para hacerlo transparente
static func load_transparent_texture(path: String, key_color: Color = MAGENTA_KEY, tolerance: float = 0.28, despill: bool = true) -> Texture2D:
	if not FileAccess.file_exists(path):
		# Intentar en res://
		if not path.begins_with("res://") and FileAccess.file_exists("res://" + path):
			path = "res://" + path
		else:
			push_warning("ChromaKeyProcessor: Archivo no encontrado: %s" % path)
			return null
			
	var img := Image.new()
	var err := img.load(path)
	if err != OK:
		push_error("ChromaKeyProcessor: Error cargando imagen en %s" % path)
		return null
		
	var clean_img := apply_chroma_key(img, key_color, tolerance, despill)
	var tex := ImageTexture.create_from_image(clean_img)
	return tex

## Aplica el filtro Chroma Key a un objeto Image, retornando una nueva copia limpia con alpha
static func apply_chroma_key(src_img: Image, key_color: Color = MAGENTA_KEY, tolerance: float = 0.28, despill: bool = true) -> Image:
	var img := src_img.duplicate() as Image
	if img.get_format() != Image.FORMAT_RGBA8:
		img.convert(Image.FORMAT_RGBA8)
		
	var w: int = img.get_width()
	var h: int = img.get_height()
	
	for y in range(h):
		for x in range(w):
			var c := img.get_pixel(x, y)
			
			# Distancia perceptual al magenta
			var dr := absf(c.r - key_color.r)
			var dg := absf(c.g - key_color.g)
			var db := absf(c.b - key_color.b)
			var dist := sqrt((dr * dr + dg * dg + db * db) / 3.0)
			
			# Detección de fondo magenta (incluyendo artefactos de compresión JPG)
			var is_magenta := dist <= tolerance or (c.r > 0.70 and c.b > 0.70 and c.g < 0.35 and (c.r - c.g > 0.35) and (c.b - c.g > 0.35))
			
			if is_magenta:
				img.set_pixel(x, y, Color(0, 0, 0, 0))
			elif despill:
				# Eliminar halos rosados en los bordes del pixel art
				if c.r > 0.55 and c.b > 0.55 and (c.r - c.g > 0.20) and (c.b - c.g > 0.20):
					var avg_rb := (c.r + c.b) * 0.5
					var spill := maxf(0.0, avg_rb - c.g)
					var clean_r := maxf(0.0, c.r - spill * 0.75)
					var clean_b := maxf(0.0, c.b - spill * 0.75)
					img.set_pixel(x, y, Color(clean_r, c.g, clean_b, c.a))
					
	return img

## Crea un ShaderMaterial preconfigurado con el shader de Chroma Key
static func create_chroma_shader_material(key_color: Color = MAGENTA_KEY, similarity: float = 0.35, smoothness: float = 0.05, despill: float = 0.6) -> ShaderMaterial:
	var shader := load("res://shaders/chroma_key.gdshader") as Shader
	if not shader:
		push_error("ChromaKeyProcessor: No se pudo cargar el shader res://shaders/chroma_key.gdshader")
		return null
		
	var mat := ShaderMaterial.new()
	mat.shader = shader
	mat.set_shader_parameter("key_color", key_color)
	mat.set_shader_parameter("similarity", similarity)
	mat.set_shader_parameter("smoothness", smoothness)
	mat.set_shader_parameter("despill_amount", despill)
	return mat
