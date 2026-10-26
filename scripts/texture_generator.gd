class_name TextureGenerator
extends RefCounted

## Generador procedural de texturas Pixel Art de 8/16 bits para Busqueda de Ojos.

static var _cache: Dictionary = {}

static func get_floor_tile() -> ImageTexture:
	if _cache.has("floor"):
		return _cache["floor"]
	var img := Image.create(32, 32, false, Image.FORMAT_RGBA8)
	var c_base := Color("1c1e29")
	var c_dark := Color("13141c")
	var c_light := Color("292c3d")
	var c_crack := Color("0d0e14")
	
	for y in range(32):
		for x in range(32):
			var col := c_base
			# Patrón de losas 16x16
			var lx := x % 16
			var ly := y % 16
			if lx == 0 or ly == 0:
				col = c_dark
			elif lx == 1 or ly == 1:
				col = c_light
			elif (x * 7 + y * 13) % 19 == 0:
				col = c_dark
			elif (x * 11 + y * 5) % 23 == 0:
				col = c_light
			
			# Grietas procedurales
			if (x == 8 and y >= 4 and y <= 12) or (y == 8 and x >= 6 and x <= 10):
				col = c_crack
			if (x == 24 and y >= 18 and y <= 27) or (x == 25 and y == 23):
				col = c_crack
				
			img.set_pixel(x, y, col)
	var tex := ImageTexture.create_from_image(img)
	_cache["floor"] = tex
	return tex

static func get_floor_alt_tile() -> ImageTexture:
	if _cache.has("floor_alt"):
		return _cache["floor_alt"]
	var img := Image.create(32, 32, false, Image.FORMAT_RGBA8)
	var c_base := Color("181a24")
	var c_dark := Color("101117")
	var c_rune := Color("4b245e")
	var c_rune_glow := Color("7a3999")
	
	for y in range(32):
		for x in range(32):
			var col := c_base
			if x == 0 or y == 0 or x == 31 or y == 31:
				col = c_dark
			elif (x + y) % 9 == 0:
				col = Color("202330")
			
			# Runa central circular en la baldosa
			var dx := x - 16
			var dy := y - 16
			var dist := sqrt(dx * dx + dy * dy)
			if abs(dist - 9.0) < 1.0:
				col = c_rune
			elif abs(dist - 5.0) < 0.9:
				col = c_rune_glow
			elif dist < 3.0:
				col = c_rune_glow
			
			img.set_pixel(x, y, col)
	var tex := ImageTexture.create_from_image(img)
	_cache["floor_alt"] = tex
	return tex

static func get_wall_tile() -> ImageTexture:
	if _cache.has("wall"):
		return _cache["wall"]
	var img := Image.create(32, 32, false, Image.FORMAT_RGBA8)
	var c_brick_base := Color("2b2b36")
	var c_brick_dark := Color("191921")
	var c_brick_light := Color("414254")
	var c_mortar := Color("111116")
	var c_moss := Color("1f3322")
	
	for y in range(32):
		var row := y / 8
		var row_y := y % 8
		for x in range(32):
			var col := c_brick_base
			var shift := (row % 2) * 16
			var brick_x := (x + shift) % 32
			var brick_col := brick_x / 16
			var bx := brick_x % 16
			
			if row_y == 0 or row_y == 7 or bx == 0 or bx == 15:
				col = c_mortar
			elif row_y == 1 or bx == 1:
				col = c_brick_light
			elif row_y == 6 or bx == 14:
				col = c_brick_dark
			else:
				# Moteado y textura de piedra
				var hash_val := (x * 17 + y * 31) % 11
				if hash_val == 0:
					col = c_brick_dark
				elif hash_val == 1:
					col = c_brick_light
				elif hash_val == 2 and y > 20: # Musgo en la base del muro
					col = c_moss
			
			img.set_pixel(x, y, col)
	var tex := ImageTexture.create_from_image(img)
	_cache["wall"] = tex
	return tex

static func get_pillar_tile() -> ImageTexture:
	if _cache.has("pillar"):
		return _cache["pillar"]
	var img := Image.create(32, 48, false, Image.FORMAT_RGBA8)
	var c_base := Color("3a3a4c")
	var c_dark := Color("20202d")
	var c_light := Color("575770")
	var c_trans := Color(0, 0, 0, 0)
	
	for y in range(48):
		for x in range(32):
			if x < 4 or x > 27:
				img.set_pixel(x, y, c_trans)
				continue
			var col := c_base
			# Relieve cilíndrico
			if x < 8:
				col = c_dark
			elif x >= 8 and x <= 12:
				col = c_light
			elif x >= 23:
				col = c_dark
			
			# Capitel superior y plinto inferior
			if y < 8 or y >= 40:
				if x == 4 or x == 27 or y == 0 or y == 47:
					col = c_dark
				elif y == 1 or y == 41:
					col = c_light
				else:
					col = Color("48485e")
			
			# Grietas y marcas
			if (y == 20 or y == 21) and x >= 10 and x <= 18:
				col = c_dark
				
			img.set_pixel(x, y, col)
	var tex := ImageTexture.create_from_image(img)
	_cache["pillar"] = tex
	return tex

static func get_debris_tile() -> ImageTexture:
	if _cache.has("debris"):
		return _cache["debris"]
	var img := Image.create(32, 32, false, Image.FORMAT_RGBA8)
	var c_trans := Color(0, 0, 0, 0)
	var c_rock := Color("4a4a5e")
	var c_rock_dark := Color("252533")
	var c_rock_light := Color("6b6b85")
	var c_bone := Color("c9c3aa")
	var c_bone_dark := Color("7a7561")
	
	for y in range(32):
		for x in range(32):
			img.set_pixel(x, y, c_trans)
	
	# Roca 1
	for y in range(12, 22):
		for x in range(6, 18):
			var dist := sqrt((x - 12) * (x - 12) + (y - 17) * (y - 17))
			if dist < 5.0:
				var col := c_rock
				if y > 18 or x > 15:
					col = c_rock_dark
				elif y < 15 and x < 10:
					col = c_rock_light
				img.set_pixel(x, y, col)
				
	# Roca 2 pequeña
	for y in range(18, 26):
		for x in range(20, 27):
			var dist := sqrt((x - 23) * (x - 23) + (y - 22) * (y - 22))
			if dist < 3.2:
				img.set_pixel(x, y, c_rock if y < 22 else c_rock_dark)
				
	# Fragmento de hueso / calavera
	img.set_pixel(14, 8, c_bone_dark)
	img.set_pixel(15, 8, c_bone)
	img.set_pixel(16, 8, c_bone)
	img.set_pixel(14, 9, c_bone)
	img.set_pixel(15, 9, c_bone_dark) # cuenca
	img.set_pixel(16, 9, c_bone)
	img.set_pixel(15, 10, c_bone_dark)
	
	var tex := ImageTexture.create_from_image(img)
	_cache["debris"] = tex
	return tex

static func get_player_sprite() -> ImageTexture:
	if _cache.has("player"):
		return _cache["player"]
	var img := Image.create(24, 24, false, Image.FORMAT_RGBA8)
	var c_trans := Color(0, 0, 0, 0)
	var c_aura := Color(0.2, 0.75, 1.0, 0.35)
	var c_body_outer := Color("2978a3")
	var c_body_mid := Color("4cb9eb")
	var c_body_core := Color("d8f6ff")
	var c_eye := Color("ffffff")
	
	for y in range(24):
		for x in range(24):
			img.set_pixel(x, y, c_trans)
			var dx := x - 12.0
			var dy := y - 11.0
			var dist := sqrt(dx * dx + dy * dy * 0.9)
			
			# Forma de espíritu con estela inferior
			if y > 12:
				var spread := (y - 12) * 0.5
				if abs(dx) < 6.0 - spread:
					img.set_pixel(x, y, c_body_mid)
			if dist < 9.5:
				img.set_pixel(x, y, c_aura)
			if dist < 7.5:
				img.set_pixel(x, y, c_body_outer)
			if dist < 5.5:
				img.set_pixel(x, y, c_body_mid)
			if dist < 3.2:
				img.set_pixel(x, y, c_body_core)
	
	# Ojos del espíritu
	img.set_pixel(9, 9, c_eye)
	img.set_pixel(10, 9, c_eye)
	img.set_pixel(14, 9, c_eye)
	img.set_pixel(15, 9, c_eye)
	img.set_pixel(10, 10, Color("144d6e"))
	img.set_pixel(14, 10, Color("144d6e"))
	
	var tex := ImageTexture.create_from_image(img)
	_cache["player"] = tex
	return tex

static func get_shadow_sprite() -> ImageTexture:
	if _cache.has("shadow"):
		return _cache["shadow"]
	var img := Image.create(28, 28, false, Image.FORMAT_RGBA8)
	var c_trans := Color(0, 0, 0, 0)
	var c_edge := Color(0.2, 0.05, 0.3, 0.45)
	var c_body := Color("14081c")
	var c_dark := Color("08020a")
	var c_eye := Color("ff2244")
	var c_pupil := Color("ffe57f")
	
	for y in range(28):
		for x in range(28):
			img.set_pixel(x, y, c_trans)
			var dx := x - 14.0
			var dy := y - 13.0
			var dist := sqrt(dx * dx + dy * dy * 1.1)
			
			# Cuernos o zarcillos
			var horn_left := (x >= 7 and x <= 11 and y >= 3 and y <= 10)
			var horn_right := (x >= 17 and x <= 21 and y >= 3 and y <= 10)
			
			if dist < 12.0 or horn_left or horn_right:
				img.set_pixel(x, y, c_edge)
			if dist < 9.5 or (horn_left and y > 5) or (horn_right and y > 5):
				img.set_pixel(x, y, c_body)
			if dist < 6.0:
				img.set_pixel(x, y, c_dark)
			
			# Zarcillos inferiores fantasmagóricos
			if y > 20 and dist < 11.0:
				if (x % 3) == 0:
					img.set_pixel(x, y, c_trans)
				else:
					img.set_pixel(x, y, c_body)
					
	# Ojos rojos brillantes acechantes
	img.set_pixel(10, 11, c_eye)
	img.set_pixel(11, 11, c_eye)
	img.set_pixel(11, 12, c_pupil)
	
	img.set_pixel(17, 11, c_eye)
	img.set_pixel(18, 11, c_eye)
	img.set_pixel(17, 12, c_pupil)

	var tex := ImageTexture.create_from_image(img)
	_cache["shadow"] = tex
	return tex

static func get_eye_base() -> ImageTexture:
	if _cache.has("eye_base"):
		return _cache["eye_base"]
	var img := Image.create(24, 24, false, Image.FORMAT_RGBA8)
	var c_trans := Color(0, 0, 0, 0)
	var c_socket := Color("120508")
	var c_flesh := Color("3d111b")
	var c_sclera_edge := Color("7a6f69")
	var c_sclera := Color("e4ded8")
	var c_vein := Color("a8283a")
	
	for y in range(24):
		for x in range(24):
			img.set_pixel(x, y, c_trans)
			var dx := x - 12.0
			var dy := (y - 12.0) * 1.35
			var dist := sqrt(dx * dx + dy * dy)
			
			if dist <= 11.0:
				img.set_pixel(x, y, c_socket)
			if dist <= 9.5:
				img.set_pixel(x, y, c_flesh)
			if dist <= 8.0:
				img.set_pixel(x, y, c_sclera_edge)
			if dist <= 7.0:
				var col := c_sclera
				# Venitas rojas en la esclerótica
				if (x == 6 and y == 12) or (x == 7 and y == 11) or (x == 17 and y == 13) or (x == 18 and y == 12):
					col = c_vein
				img.set_pixel(x, y, col)
				
	var tex := ImageTexture.create_from_image(img)
	_cache["eye_base"] = tex
	return tex

static func get_eye_pupil() -> ImageTexture:
	if _cache.has("eye_pupil"):
		return _cache["eye_pupil"]
	var img := Image.create(10, 10, false, Image.FORMAT_RGBA8)
	var c_trans := Color(0, 0, 0, 0)
	var c_iris_dark := Color("800010")
	var c_iris_bright := Color("e60026")
	var c_pupil := Color("100204")
	var c_glint := Color("ffffff")
	
	for y in range(10):
		for x in range(10):
			img.set_pixel(x, y, c_trans)
			var dx := x - 5.0
			var dy := y - 5.0
			var dist := sqrt(dx * dx + dy * dy)
			if dist <= 4.2:
				img.set_pixel(x, y, c_iris_dark)
			if dist <= 3.2:
				img.set_pixel(x, y, c_iris_bright)
			# Pupila vertical de gato/demonio
			if abs(dx) <= 1.0 and abs(dy) <= 3.0:
				img.set_pixel(x, y, c_pupil)
			# Reflejo especular
			if x == 4 and y == 3:
				img.set_pixel(x, y, c_glint)
				
	var tex := ImageTexture.create_from_image(img)
	_cache["eye_pupil"] = tex
	return tex

static func get_light_halo(radius: int = 256) -> ImageTexture:
	var key := "light_" + str(radius)
	if _cache.has(key):
		return _cache[key]
	var size := radius * 2
	var img := Image.create(size, size, false, Image.FORMAT_RGBA8)
	var center := Vector2(radius, radius)
	
	for y in range(size):
		for x in range(size):
			var dist := center.distance_to(Vector2(x, y))
			if dist >= radius:
				img.set_pixel(x, y, Color(1, 1, 1, 0))
			else:
				var t := 1.0 - (dist / float(radius))
				# Atenuación suave cúbica natural
				var alpha := t * t * (3.0 - 2.0 * t)
				img.set_pixel(x, y, Color(1.0, 0.95, 0.85, alpha))
				
	var tex := ImageTexture.create_from_image(img)
	_cache[key] = tex
	return tex

static func get_heart_icon(filled: bool) -> ImageTexture:
	var key := "heart_full" if filled else "heart_empty"
	if _cache.has(key):
		return _cache[key]
	var img := Image.create(16, 16, false, Image.FORMAT_RGBA8)
	var c_trans := Color(0, 0, 0, 0)
	var c_border := Color("1f050b")
	var c_fill := Color("e62e49") if filled else Color("3d2328")
	var c_highlight := Color("ffa3b1") if filled else Color("59363d")
	
	for y in range(16):
		for x in range(16):
			img.set_pixel(x, y, c_trans)
			
	var pattern := [
		"................",
		"..xxxx....xxxx..",
		".xoooo-..xoooo-.",
		"xoooooo-xoooooo-",
		"xoooooo-xoooooo-",
		"xoooooo-xoooooo-",
		".xoooooooooooo-.",
		"..xoooooooooo-..",
		"...xoooooooo-...",
		"....xoooooo-....",
		".....xoooo-.....",
		"......xoo-......",
		".......x-.......",
		"................",
		"................",
		"................"
	]
	
	for y in range(mini(16, pattern.size())):
		var line: String = pattern[y]
		for x in range(mini(16, line.length())):
			var char_code := line[x]
			if char_code == 'x' or char_code == '-':
				img.set_pixel(x, y, c_border)
			elif char_code == 'o':
				if y <= 4 and (x == 3 or x == 4 or x == 10):
					img.set_pixel(x, y, c_highlight)
				else:
					img.set_pixel(x, y, c_fill)
					
	var tex := ImageTexture.create_from_image(img)
	_cache[key] = tex
	return tex

static func get_eye_icon() -> ImageTexture:
	if _cache.has("eye_icon"):
		return _cache["eye_icon"]
	var img := Image.create(16, 16, false, Image.FORMAT_RGBA8)
	var c_trans := Color(0, 0, 0, 0)
	var c_edge := Color("120508")
	var c_white := Color("dedede")
	var c_red := Color("e60026")
	var c_pupil := Color("0d0003")
	
	for y in range(16):
		for x in range(16):
			img.set_pixel(x, y, c_trans)
			var dx := x - 8.0
			var dy := (y - 8.0) * 1.4
			var dist := sqrt(dx * dx + dy * dy)
			if dist <= 7.0:
				img.set_pixel(x, y, c_edge)
			if dist <= 5.5:
				img.set_pixel(x, y, c_white)
			if dist <= 3.5:
				img.set_pixel(x, y, c_red)
			if abs(dx) <= 0.8 and abs(dy) <= 2.2:
				img.set_pixel(x, y, c_pupil)
				
	var tex := ImageTexture.create_from_image(img)
	_cache["eye_icon"] = tex
	return tex

static func get_spark_particle() -> ImageTexture:
	if _cache.has("spark"):
		return _cache["spark"]
	var img := Image.create(8, 8, false, Image.FORMAT_RGBA8)
	var c_trans := Color(0, 0, 0, 0)
	var c_spark := Color("ffeaa7")
	var c_bright := Color("ffffff")
	
	for y in range(8):
		for x in range(8):
			img.set_pixel(x, y, c_trans)
	
	img.set_pixel(3, 1, c_spark)
	img.set_pixel(4, 1, c_spark)
	img.set_pixel(1, 3, c_spark)
	img.set_pixel(2, 3, c_spark)
	img.set_pixel(3, 3, c_bright)
	img.set_pixel(4, 3, c_bright)
	img.set_pixel(5, 3, c_spark)
	img.set_pixel(6, 3, c_spark)
	img.set_pixel(1, 4, c_spark)
	img.set_pixel(2, 4, c_spark)
	img.set_pixel(3, 4, c_bright)
	img.set_pixel(4, 4, c_bright)
	img.set_pixel(5, 4, c_spark)
	img.set_pixel(6, 4, c_spark)
	img.set_pixel(3, 6, c_spark)
	img.set_pixel(4, 6, c_spark)
	
	var tex := ImageTexture.create_from_image(img)
	_cache["spark"] = tex
	return tex
