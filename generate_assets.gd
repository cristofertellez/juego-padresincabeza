@tool
extends SceneTree

# Script ejecutador para generar los assets requeridos en assets/

func _init() -> void:
	print("--- Generando assets pixel art para Búsqueda de Ojos (Catedral de León) ---")
	var dir := DirAccess.open("res://")
	if not dir.dir_exists("res://assets"):
		dir.make_dir("res://assets")
		
	generate_padre()
	generate_ojo()
	generate_banca()
	generate_altar()
	generate_columna()
	generate_leon()
	generate_santo()
	generate_confesionario()
	generate_piso()
	generate_alfombra()
	
	print("--- ¡Todos los assets generados exitosamente! ---")
	quit()

func set_p(img: Image, x: int, y: int, col: Color) -> void:
	if x >= 0 and x < img.get_width() and y >= 0 and y < img.get_height():
		img.set_pixel(x, y, col)

func blend_p(img: Image, x: int, y: int, col: Color) -> void:
	if x >= 0 and x < img.get_width() and y >= 0 and y < img.get_height():
		var bg := img.get_pixel(x, y)
		var out_a := col.a + bg.a * (1.0 - col.a)
		if out_a > 0.0:
			var out_r := (col.r * col.a + bg.r * bg.a * (1.0 - col.a)) / out_a
			var out_g := (col.g * col.a + bg.g * bg.a * (1.0 - col.a)) / out_a
			var out_b := (col.b * col.a + bg.b * bg.a * (1.0 - col.a)) / out_a
			img.set_pixel(x, y, Color(out_r, out_g, out_b, out_a))

func add_outline(img: Image, outline_col: Color = Color(0.05, 0.05, 0.08, 1.0)) -> void:
	var w: int = img.get_width()
	var h: int = img.get_height()
	var mask := Image.create(w, h, false, Image.FORMAT_RGBA8)
	
	for y in range(h):
		for x in range(w):
			if img.get_pixel(x, y).a > 0.05:
				continue
			var has_neighbor := false
			for dy: int in [-1, 0, 1]:
				for dx: int in [-1, 0, 1]:
					if dx == 0 and dy == 0:
						continue
					var nx: int = x + dx
					var ny: int = y + dy
					if nx >= 0 and nx < w and ny >= 0 and ny < h:
						if img.get_pixel(nx, ny).a > 0.4:
							has_neighbor = true
							break
				if has_neighbor:
					break
			if has_neighbor:
				mask.set_pixel(x, y, outline_col)
				
	for y in range(h):
		for x in range(w):
			var m_col := mask.get_pixel(x, y)
			if m_col.a > 0.0:
				img.set_pixel(x, y, m_col)

# 1. PADRE SIN CABEZA (64x64, transparente)
func generate_padre() -> void:
	var img := Image.create(64, 64, false, Image.FORMAT_RGBA8)
	var c_robe_dark := Color("0d0d12")
	var c_robe_mid := Color("1b1b24")
	var c_robe_light := Color("2c2c3b")
	var c_robe_high := Color("404052")
	var c_gold_dark := Color("7a5914")
	var c_gold := Color("d4af37")
	var c_gold_bright := Color("f5d76e")
	var c_skin := Color("d9cbb8")
	var c_skin_shadow := Color("8f7f71")
	var c_blood_dark := Color("4a070f")
	var c_blood_bright := Color("8f121d")
	var c_smoke := Color(0.2, 0.05, 0.3, 0.45)
	var c_smoke_dense := Color(0.12, 0.02, 0.18, 0.75)
	
	# Sotana / cuerpo (forma cónica / trapecio desde hombros hasta base)
	for y in range(20, 60):
		var progress: float = float(y - 20) / 40.0
		var half_w: float = 10.0 + progress * 14.0
		var min_x := int(32.0 - half_w)
		var max_x := int(32.0 + half_w)
		
		for x in range(min_x, max_x):
			var col := c_robe_mid
			# Pliegues verticales de tela
			var fold: float = sin(float(x) * 0.7 + progress * 2.0)
			if fold < -0.3:
				col = c_robe_dark
			elif fold > 0.4:
				col = c_robe_light
			elif (x + y) % 9 == 0:
				col = c_robe_high
				
			# Sombra en los laterales
			if x < min_x + 3 or x > max_x - 4:
				col = c_robe_dark
			if y > 54:
				col = c_robe_dark
				
			set_p(img, x, y, col)
			
	# Hombros robustos
	for y in range(16, 23):
		for x in range(20, 45):
			var dist: int = abs(x - 32)
			if dist <= 12:
				var col := c_robe_light if y < 19 else c_robe_mid
				set_p(img, x, y, col)

	# Estola y rosario sagrado dorado en el pecho
	for y in range(18, 48):
		# Dos bandas verticales de la estola sacerdotal
		set_p(img, 28, y, c_gold)
		set_p(img, 29, y, c_gold_bright)
		set_p(img, 30, y, c_gold_dark)
		
		set_p(img, 34, y, c_gold_dark)
		set_p(img, 35, y, c_gold_bright)
		set_p(img, 36, y, c_gold)
		
		# Flecos dorados al final de la estola
		if y >= 45:
			set_p(img, 28, y, c_gold_bright)
			set_p(img, 36, y, c_gold_bright)
			
	# Cruz colgante en el pecho
	for cy in range(32, 40):
		set_p(img, 32, cy, c_gold_bright)
	for cx in range(30, 35):
		set_p(img, cx, 34, c_gold_bright)
		
	# Brazos y mangas amplias
	for y in range(21, 38):
		var sleeve_len: float = float(y - 21) * 0.4
		# Manga izquierda extendida
		for x in range(int(16.0 - sleeve_len), 23):
			set_p(img, x, y, c_robe_mid if y < 32 else c_robe_dark)
		# Manga derecha extendida
		for x in range(42, int(49.0 + sleeve_len)):
			set_p(img, x, y, c_robe_mid if y < 32 else c_robe_dark)

	# Manos pálidas fantasmagóricas extendidas
	for y in range(34, 43):
		# Mano izquierda
		for x in range(10, 16):
			var c := c_skin if x > 11 else c_skin_shadow
			if y == 42 and x % 2 == 0:
				c = c_skin
			set_p(img, x, y, c)
		# Mano derecha
		for x in range(49, 55):
			var c := c_skin if x < 53 else c_skin_shadow
			if y == 42 and x % 2 != 0:
				c = c_skin
			set_p(img, x, y, c)
			
	# Cuello cortado y sangre oscura
	for y in range(14, 18):
		for x in range(27, 38):
			var c := c_blood_dark
			if y == 15 or (x >= 29 and x <= 35):
				c = c_blood_bright
			if x == 27 or x == 37:
				c = c_blood_dark
			set_p(img, x, y, c)
	# Gotas de sangre goteando hacia la estola
	set_p(img, 29, 18, c_blood_bright)
	set_p(img, 29, 19, c_blood_dark)
	set_p(img, 34, 18, c_blood_bright)
	set_p(img, 35, 19, c_blood_dark)

	# Niebla sombría espectral flotando donde debería estar la cabeza
	for y in range(2, 16):
		for x in range(22, 43):
			var dx: float = float(x - 32)
			var dy: float = float(y - 8)
			var dist: float = sqrt(dx * dx * 0.8 + dy * dy * 1.2)
			if dist < 8.0:
				var alpha: float = (1.0 - dist / 8.0) * 0.85
				var col := Color(c_smoke_dense.r, c_smoke_dense.g, c_smoke_dense.b, alpha)
				blend_p(img, x, y, col)
			elif dist < 12.0:
				var alpha: float = (1.0 - dist / 12.0) * 0.4
				var col := Color(c_smoke.r, c_smoke.g, c_smoke.b, alpha)
				blend_p(img, x, y, col)
				
	add_outline(img)
	img.save_png("res://assets/padre.png")
	print("  + assets/padre.png creado")

# 2. OJO MÍSTICO (32x32, transparente)
func generate_ojo() -> void:
	var img := Image.create(32, 32, false, Image.FORMAT_RGBA8)
	var c_socket := Color("140508")
	var c_sclera_dark := Color("827976")
	var c_sclera := Color("f2eee9")
	var c_vein := Color("ab1b2c")
	var c_iris_dark := Color("61050d")
	var c_iris := Color("e60026")
	var c_iris_glow := Color("ff3355")
	var c_pupil := Color("050002")
	var c_glint := Color("ffffff")
	
	for y in range(32):
		for x in range(32):
			var dx: float = float(x - 16)
			var dy: float = float(y - 16) * 1.45
			var dist: float = sqrt(dx * dx + dy * dy)
			
			if dist <= 14.0:
				set_p(img, x, y, c_socket)
			if dist <= 12.5:
				set_p(img, x, y, c_sclera_dark)
			if dist <= 11.0:
				var col := c_sclera
				# Venas arcanas
				if (x == 7 and y == 16) or (x == 8 and y == 15) or (x == 9 and y == 16):
					col = c_vein
				if (x == 23 and y == 17) or (x == 24 and y == 16) or (x == 25 and y == 16):
					col = c_vein
				set_p(img, x, y, col)
				
			# Iris
			var d_center: float = sqrt(float((x - 16) * (x - 16) + (y - 16) * (y - 16)))
			if d_center <= 6.5:
				set_p(img, x, y, c_iris_dark)
			if d_center <= 5.2:
				set_p(img, x, y, c_iris)
			if d_center <= 3.8:
				set_p(img, x, y, c_iris_glow)
				
			# Pupila vertical de hendidura
			if abs(x - 16) <= 1 and abs(y - 16) <= 4:
				set_p(img, x, y, c_pupil)
				
	# Brillo especular
	set_p(img, 14, 13, c_glint)
	set_p(img, 15, 13, c_glint)
	set_p(img, 14, 14, c_glint)
	
	add_outline(img)
	img.save_png("res://assets/ojo.png")
	print("  + assets/ojo.png creado")

# 3. BANCA DE CAOBA (64x32, transparente)
func generate_banca() -> void:
	var img := Image.create(64, 32, false, Image.FORMAT_RGBA8)
	var c_wood_dark := Color("240d07")
	var c_wood_mid := Color("451d11")
	var c_wood_light := Color("6e321e")
	var c_wood_high := Color("96482e")
	
	# Respaldo de la banca (y: 4 a 14)
	for y in range(4, 15):
		for x in range(4, 60):
			var col := c_wood_mid
			if y == 4:
				col = c_wood_high
			elif y == 5:
				col = c_wood_light
			elif y == 14:
				col = c_wood_dark
			elif (x % 8) == 0:
				col = c_wood_dark
			set_p(img, x, y, col)
			
	# Asiento de la banca (y: 15 a 22)
	for y in range(15, 23):
		for x in range(3, 61):
			var col := c_wood_light
			if y == 15:
				col = c_wood_high
			elif y == 22:
				col = c_wood_dark
			elif (x + y * 2) % 11 == 0:
				col = c_wood_mid
			set_p(img, x, y, col)
			
	# Apoyabrazos laterales (x: 2..5 y 58..61)
	for y in range(8, 25):
		for x in range(2, 6):
			var col := c_wood_mid
			if y == 8 or x == 2:
				col = c_wood_high
			elif x == 5:
				col = c_wood_dark
			set_p(img, x, y, col)
		for x in range(58, 62):
			var col := c_wood_mid
			if y == 8 or x == 58:
				col = c_wood_high
			elif x == 61:
				col = c_wood_dark
			set_p(img, x, y, col)
			
	# Patas de madera tallada (y: 23 a 30)
	var leg_x_positions := [6, 7, 8, 29, 30, 31, 54, 55, 56]
	for y in range(23, 31):
		for lx in leg_x_positions:
			var col := c_wood_mid if y < 28 else c_wood_dark
			set_p(img, lx, y, col)
			
	add_outline(img)
	img.save_png("res://assets/banca.png")
	print("  + assets/banca.png creado")

# 4. ALTAR MAYOR BARROCO (96x64, transparente)
func generate_altar() -> void:
	var img := Image.create(96, 64, false, Image.FORMAT_RGBA8)
	var c_gold_dark := Color("543805")
	var c_gold_mid := Color("996d12")
	var c_gold_light := Color("deb13a")
	var c_gold_high := Color("fae482")
	var c_cloth_shadow := Color("a8a59e")
	var c_cloth := Color("ededed")
	var c_cloth_high := Color("ffffff")
	var c_candle := Color("f7f1d5")
	var c_flame_core := Color("ffffff")
	var c_flame_mid := Color("ffb300")
	var c_flame_edge := Color("e63900")
	
	# Retablo barroco trasero (y: 2 a 32, x: 12 a 84)
	for y in range(2, 33):
		var arc_w: float = 34.0 - float(y) * 0.4
		var min_x := int(48.0 - arc_w)
		var max_x := int(48.0 + arc_w)
		for x in range(min_x, max_x):
			var col := c_gold_mid
			var d_edge: int = mini(x - min_x, max_x - x)
			if d_edge <= 2 or y <= 4:
				col = c_gold_high
			elif (x + y) % 6 == 0:
				col = c_gold_light
			elif (x * y) % 9 == 0:
				col = c_gold_dark
			set_p(img, x, y, col)
			
	# Nicho / arco central en el retablo
	for y in range(10, 30):
		for x in range(40, 57):
			var dx: float = float(x - 48)
			var dy: float = float(y - 20)
			if (dx * dx + dy * dy) < 42.0:
				set_p(img, x, y, Color("2e1c03"))
				
	# Gran Cruz Dorada central (y: 6 a 26, x: 45 a 51)
	for y in range(7, 26):
		set_p(img, 47, y, c_gold_high)
		set_p(img, 48, y, c_gold_high)
		set_p(img, 49, y, c_gold_mid)
	for x in range(43, 54):
		set_p(img, x, 12, c_gold_high)
		set_p(img, x, 13, c_gold_mid)

	# Mesa del Altar (y: 33 a 61, x: 8 a 88)
	# Mantel blanco con bordado
	for y in range(33, 60):
		for x in range(8, 88):
			var col := c_cloth
			# Superficie de la mesa
			if y < 40:
				col = c_cloth_high if y == 33 else c_cloth
			else:
				# Caída frontal del mantel con pliegues
				var fold: float = sin(float(x) * 0.5)
				if fold > 0.4:
					col = c_cloth_high
				elif fold < -0.3:
					col = c_cloth_shadow
					
				# Encaje y bordado dorado en el borde inferior
				if y >= 55 and y <= 58:
					if (x + y) % 3 == 0:
						col = c_gold_light
					else:
						col = c_gold_mid
			set_p(img, x, y, col)

	# Candelabros barrocos dorados y velas a los lados
	var candle_x := [20, 76]
	for cx in candle_x:
		# Base y fuste del candelabro
		for y in range(25, 34):
			set_p(img, cx - 2, y, c_gold_mid)
			set_p(img, cx - 1, y, c_gold_high)
			set_p(img, cx, y, c_gold_light)
			set_p(img, cx + 1, y, c_gold_mid)
		# Vela blanca
		for y in range(17, 25):
			set_p(img, cx - 1, y, c_candle)
			set_p(img, cx, y, c_candle)
		# Mecha
		set_p(img, cx, 16, Color("331a00"))
		# Llama viva
		set_p(img, cx, 13, c_flame_core)
		set_p(img, cx, 14, c_flame_mid)
		set_p(img, cx - 1, 14, c_flame_edge)
		set_p(img, cx + 1, 14, c_flame_edge)
		set_p(img, cx, 15, c_flame_edge)
		set_p(img, cx, 12, c_flame_mid)

	add_outline(img)
	img.save_png("res://assets/altar.png")
	print("  + assets/altar.png creado")

# 5. COLUMNA COLONIAL ENCALADA (48x64, transparente)
func generate_columna() -> void:
	var img := Image.create(48, 64, false, Image.FORMAT_RGBA8)
	var c_stone_dark := Color("5e5b56")
	var c_stone_shadow := Color("8a8780")
	var c_stone_mid := Color("c9c5ba")
	var c_stone_light := Color("ece8dc")
	var c_stone_high := Color("faf7f0")
	var c_crack := Color("403d38")
	
	# Capitel superior (y: 4 a 14)
	for y in range(4, 15):
		var w_prog: float = float(14 - y) * 0.7
		var x1 := int(8.0 - w_prog)
		var x2 := int(40.0 + w_prog)
		for x in range(x1, x2):
			var col := c_stone_mid
			if y == 4:
				col = c_stone_high
			elif x < x1 + 3:
				col = c_stone_shadow
			elif x >= x1 + 3 and x <= x1 + 8:
				col = c_stone_light
			elif x > x2 - 4:
				col = c_stone_dark
			set_p(img, x, y, col)

	# Fuste cilíndrico (y: 15 a 52, x: 10 a 38)
	for y in range(15, 53):
		for x in range(10, 38):
			var col := c_stone_mid
			# Sombreado cilíndrico realista de izquierda a derecha
			var t: float = float(x - 10) / 28.0
			if t < 0.15:
				col = c_stone_shadow
			elif t < 0.4:
				col = c_stone_high
			elif t < 0.7:
				col = c_stone_light
			elif t < 0.88:
				col = c_stone_mid
			else:
				col = c_stone_dark
				
			# Grietas coloniales de piedra
			if (y == 28 and x >= 14 and x <= 19) or (y == 29 and x == 18):
				col = c_crack
			if (y == 41 and x >= 22 and x <= 27) or (y == 42 and x == 25):
				col = c_crack
			if (x + y * 3) % 17 == 0:
				col = c_stone_shadow
				
			set_p(img, x, y, col)

	# Base cuadrada colonial (y: 53 a 62, x: 6 a 42)
	for y in range(53, 63):
		var x1 := 6
		var x2 := 42
		if y >= 58:
			x1 = 4
			x2 = 44
		for x in range(x1, x2):
			var col := c_stone_mid
			if y == 53 or y == 58:
				col = c_stone_high
			elif x < x1 + 3:
				col = c_stone_shadow
			elif x > x2 - 4 or y == 62:
				col = c_stone_dark
			set_p(img, x, y, col)

	add_outline(img)
	img.save_png("res://assets/columna.png")
	print("  + assets/columna.png creado")

# 6. LEÓN DE PIEDRA COLONIAL (64x64, transparente)
func generate_leon() -> void:
	var img := Image.create(64, 64, false, Image.FORMAT_RGBA8)
	var c_pedestal_dark := Color("303038")
	var c_pedestal_shadow := Color("232329")
	var c_pedestal_mid := Color("4f4f5c")
	var c_pedestal_light := Color("7a7a8c")
	var c_pedestal_high := Color("a4a4b8")
	var c_lion_shadow := Color("787672")
	var c_lion_mid := Color("b8b4ab")
	var c_lion_light := Color("e0dcd3")
	var c_lion_high := Color("f7f4ed")
	
	# Pedestal de piedra rectangular (y: 46 a 61, x: 4 a 60)
	for y in range(46, 62):
		for x in range(4, 60):
			var col := c_pedestal_mid
			if y == 46:
				col = c_pedestal_high
			elif y == 47:
				col = c_pedestal_light
			elif y >= 59 or x > 56:
				col = c_pedestal_dark
			elif x < 7:
				col = c_pedestal_shadow
			set_p(img, x, y, col)

	# Cuerpo del león acostado (y: 28 a 46, x: 12 a 54)
	for y in range(28, 47):
		for x in range(12, 54):
			var dx: float = float(x - 33)
			var dy: float = float(y - 37) * 1.5
			if (dx * dx * 0.7 + dy * dy) < 140.0:
				var col := c_lion_mid
				if y < 33:
					col = c_lion_high
				elif x > 44:
					col = c_lion_shadow
				set_p(img, x, y, col)

	# Cabeza y Melena majestuosa tallada (y: 12 a 34, x: 10 a 32)
	for y in range(12, 35):
		for x in range(10, 32):
			var dx: float = float(x - 20)
			var dy: float = float(y - 22)
			var d: float = sqrt(dx * dx + dy * dy)
			if d <= 11.0:
				var col := c_lion_mid
				# Mechones de la melena
				if (x + y * 2) % 4 == 0:
					col = c_lion_high
				elif (x * 3 + y) % 5 == 0:
					col = c_lion_shadow
				set_p(img, x, y, col)

	# Hocico del león
	for y in range(20, 27):
		for x in range(8, 16):
			var col := c_lion_light if y < 24 else c_lion_shadow
			set_p(img, x, y, col)
	# Nariz y ojo esculpido
	set_p(img, 8, 22, Color("2b2926"))
	set_p(img, 14, 19, Color("2b2926"))

	# Patas delanteras extendidas hacia la izquierda sobre el pedestal
	for y in range(40, 47):
		for x in range(6, 22):
			var col := c_lion_light if y < 43 else c_lion_shadow
			if x <= 10 and y == 44:
				col = c_lion_high
			set_p(img, x, y, col)

	# Cola descansando sobre el anca trasera
	for x in range(48, 58):
		set_p(img, x, 36, c_lion_high)
		set_p(img, x, 37, c_lion_mid)
	set_p(img, 57, 35, c_lion_shadow)
	set_p(img, 58, 35, c_lion_shadow)

	add_outline(img)
	img.save_png("res://assets/leon.png")
	print("  + assets/leon.png creado")

# 7. ESTATUA DEL SANTO (48x64, transparente)
func generate_santo() -> void:
	var img := Image.create(48, 64, false, Image.FORMAT_RGBA8)
	var c_wood_dark := Color("291207")
	var c_wood_mid := Color("4a220e")
	var c_wood_light := Color("7a3e1c")
	var c_wood_high := Color("9e552a")
	var c_halo := Color(0.95, 0.82, 0.3, 0.8)
	var c_stone_dark := Color("54504d")
	var c_stone_mid := Color("8c857f")
	var c_stone_light := Color("c7c0b7")
	var c_stone_high := Color("f0e9e1")
	var c_flame := Color("ff9900")
	var c_candle := Color("dedac8")
	
	# Pedestal de madera tallada (y: 48 a 62, x: 8 a 40)
	for y in range(48, 63):
		for x in range(8, 40):
			var col := c_wood_mid
			if y == 48:
				col = c_wood_high
			elif y >= 60 or x > 37:
				col = c_wood_dark
			elif x < 11:
				col = c_wood_light
			set_p(img, x, y, col)

	# Velitas encendidas en la base (x: 13 y 34)
	for vx in [13, 34]:
		for y in range(42, 49):
			set_p(img, vx, y, c_candle)
		set_p(img, vx, 40, c_flame)
		set_p(img, vx, 41, Color("ffe680"))

	# Halo dorado circular detrás de la cabeza
	for y in range(4, 18):
		for x in range(16, 33):
			var dist: float = sqrt(float((x - 24) * (x - 24) + (y - 11) * (y - 11)))
			if absf(dist - 6.5) < 1.2:
				set_p(img, x, y, c_halo)

	# Cabeza y rostro del santo
	for y in range(9, 16):
		for x in range(21, 28):
			var col := c_stone_light if x <= 24 else c_stone_mid
			set_p(img, x, y, col)
	# Cabello y barba esculpidos
	for x in range(20, 29):
		set_p(img, x, 8, c_stone_dark)
		set_p(img, x, 15, c_stone_dark)

	# Túnica y manto del santo (y: 16 a 48, x: 14 a 34)
	for y in range(16, 49):
		var w_prog: float = float(y - 16) / 32.0
		var min_x := int(20.0 - w_prog * 6.0)
		var max_x := int(28.0 + w_prog * 6.0)
		for x in range(min_x, max_x):
			var col := c_stone_light
			var fold: float = sin(float(x) * 0.8 + w_prog * 3.0)
			if fold < -0.3:
				col = c_stone_mid
			elif fold > 0.4:
				col = c_stone_high
			if x > max_x - 3:
				col = c_stone_dark
			set_p(img, x, y, col)
			
	# Manos sosteniendo un libro sagrado
	for y in range(24, 29):
		for x in range(21, 28):
			set_p(img, x, y, Color("572a14") if y < 27 else c_stone_high)

	add_outline(img)
	img.save_png("res://assets/santo.png")
	print("  + assets/santo.png creado")

# 8. CONFESIONARIO COLONIAL (64x64, transparente)
func generate_confesionario() -> void:
	var img := Image.create(64, 64, false, Image.FORMAT_RGBA8)
	var c_wood_dark := Color("210d07")
	var c_wood_mid := Color("421e12")
	var c_wood_light := Color("663120")
	var c_wood_high := Color("8c462f")
	var c_gold := Color("cca633")
	var c_curtain_dark := Color("290a36")
	var c_curtain_mid := Color("52176b")
	var c_curtain_light := Color("802a9e")
	var c_curtain_high := Color("a745c9")
	
	# Estructura de cabina (y: 8 a 62, x: 6 a 58)
	for y in range(8, 63):
		for x in range(6, 58):
			var col := c_wood_mid
			if y == 8:
				col = c_wood_high
			elif x < 9 or x > 54:
				col = c_wood_dark
			set_p(img, x, y, col)
			
	# Frontis y copete con cruz tallada arriba (y: 2 a 8)
	for x in range(24, 40):
		set_p(img, x, 7, c_wood_high)
	set_p(img, 31, 2, c_gold)
	set_p(img, 32, 2, c_gold)
	for y in range(2, 7):
		set_p(img, 31, y, c_gold)
		set_p(img, 32, y, c_gold)
	for x in range(29, 35):
		set_p(img, x, 4, c_gold)

	# Paneles laterales con celosía tallada (x: 10..22 y 42..54)
	for y in range(16, 54):
		for x in range(10, 23):
			var col := c_wood_dark if ((x + y) % 4 == 0) else c_wood_mid
			set_p(img, x, y, col)
		for x in range(42, 55):
			var col := c_wood_dark if ((x + y) % 4 == 0) else c_wood_mid
			set_p(img, x, y, col)

	# Hueco central con cortina morada rica (y: 14 a 60, x: 23 a 42)
	for y in range(14, 61):
		for x in range(23, 42):
			var col := c_curtain_mid
			# Pliegues de la cortina
			var fold: float = sin(float(x) * 0.9)
			if fold > 0.4:
				col = c_curtain_high
			elif fold > 0.0:
				col = c_curtain_light
			elif fold < -0.3:
				col = c_curtain_dark
			if y == 14:
				col = c_gold
			set_p(img, x, y, col)

	add_outline(img)
	img.save_png("res://assets/confesionario.png")
	print("  + assets/confesionario.png creado")

# 9. PISO COLONIAL (64x64, SIN transparencia, seamless tile)
func generate_piso() -> void:
	var img := Image.create(64, 64, false, Image.FORMAT_RGBA8)
	var c_mortar := Color("1f1a17")
	var c_terracotta_dark := Color("612419")
	var c_terracotta_mid := Color("87382b")
	var c_terracotta_light := Color("b35140")
	var c_stone_dark := Color("827d73")
	var c_stone_mid := Color("b8b2a5")
	var c_stone_light := Color("ded8cb")
	
	# Matriz de 2x2 losas grandes de 32x32 cada una, alternadas
	for y in range(64):
		for x in range(64):
			var tx := x / 32
			var ty := y / 32
			var is_terracotta := ((tx + ty) % 2 == 0)
			var lx := x % 32
			var ly := y % 32
			
			# Juntas de mortero oscuro en los bordes
			if lx == 0 or ly == 0:
				set_p(img, x, y, c_mortar)
				continue
				
			var col: Color
			if is_terracotta:
				col = c_terracotta_mid
				if lx == 1 or ly == 1:
					col = c_terracotta_light
				elif lx == 31 or ly == 31:
					col = c_terracotta_dark
				else:
					var h := (x * 7 + y * 13) % 17
					if h == 0:
						col = c_terracotta_dark
					elif h == 1:
						col = c_terracotta_light
			else:
				col = c_stone_mid
				if lx == 1 or ly == 1:
					col = c_stone_light
				elif lx == 31 or ly == 31:
					col = c_stone_dark
				else:
					var h := (x * 11 + y * 5) % 19
					if h == 0:
						col = c_stone_dark
					elif h == 1:
						col = c_stone_light
						
			set_p(img, x, y, col)
			
	img.save_png("res://assets/piso.png")
	print("  + assets/piso.png creado")

# 10. ALFOMBRA ROJA CON BORDES DORADOS (64x64, SIN transparencia, seamless tile en Y)
func generate_alfombra() -> void:
	var img := Image.create(64, 64, false, Image.FORMAT_RGBA8)
	var c_border_dark := Color("4a3305")
	var c_gold_dark := Color("8c6712")
	var c_gold_mid := Color("d4a728")
	var c_gold_high := Color("f7d563")
	var c_red_dark := Color("47080f")
	var c_red_mid := Color("7a0f1c")
	var c_red_light := Color("a3182a")
	var c_red_high := Color("b82538")
	
	for y in range(64):
		for x in range(64):
			var col := c_red_mid
			
			# Borde izquierdo dorado (x: 0 a 9)
			if x <= 1:
				col = c_border_dark
			elif x <= 4:
				col = c_gold_mid if (y % 4 < 2) else c_gold_high
			elif x <= 6:
				col = c_gold_dark
			elif x <= 9:
				col = c_gold_high if ((x + y) % 3 == 0) else c_gold_mid
			# Borde derecho dorado (x: 54 a 63)
			elif x >= 62:
				col = c_border_dark
			elif x >= 59:
				col = c_gold_mid if (y % 4 < 2) else c_gold_high
			elif x >= 57:
				col = c_gold_dark
			elif x >= 54:
				col = c_gold_high if ((x + y) % 3 == 0) else c_gold_mid
			# Centro de terciopelo rojo
			else:
				var grain := (x * 13 + y * 7) % 11
				if grain == 0:
					col = c_red_dark
				elif grain == 1:
					col = c_red_light
				elif grain == 2 and (x >= 28 and x <= 35):
					col = c_red_high
				else:
					col = c_red_mid
					
			set_p(img, x, y, col)
			
	img.save_png("res://assets/alfombra.png")
	print("  + assets/alfombra.png creado")
