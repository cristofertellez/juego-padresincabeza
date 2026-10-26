class_name DungeonBuilder
extends Node2D

const TILE_SIZE: int = 64
const GRID_WIDTH: int = 34
const GRID_HEIGHT: int = 30

enum CellType { EMPTY = 0, PISO = 1, ALFOMBRA = 2, WALL = 3 }

var grid: Array = []
var eye_spawn_positions: Array[Vector2] = []
var shadow_patrol_routes: Array[Array] = []
var player_spawn_pos: Vector2 = Vector2.ZERO

var tex_piso: Texture2D
var tex_alfombra: Texture2D
var tex_wall: Texture2D
var tex_columna: Texture2D
var tex_banca: Texture2D
var tex_altar: Texture2D
var tex_leon: Texture2D
var tex_santo: Texture2D
var tex_confesionario: Texture2D

var floor_cells: Array[Dictionary] = [] # { pos: Vector2i, type: CellType }
var wall_cells: Array[Vector2i] = []

@onready var walls_body: StaticBody2D = $WallCollisions
@onready var decorations_layer: Node2D = $Decorations

func _ready() -> void:
	y_sort_enabled = true
	if decorations_layer:
		decorations_layer.y_sort_enabled = true
		
	_load_textures()
	_init_grid()
	_build_catedral_layout()
	_identify_walls()
	_build_collision_walls()
	_spawn_catedral_furniture()
	queue_redraw()

func _load_textures() -> void:
	tex_piso = load("res://assets/piso.png")
	tex_alfombra = load("res://assets/alfombra.png")
	tex_wall = TextureGenerator.get_wall_tile()
	tex_columna = load("res://assets/columna.png")
	tex_banca = load("res://assets/banca.png")
	tex_altar = load("res://assets/altar.png")
	tex_leon = load("res://assets/leon.png")
	tex_santo = load("res://assets/santo.png")
	tex_confesionario = load("res://assets/confesionario.png")

func _draw() -> void:
	# El suelo de la catedral se maneja modularmente mediante el TileMapLayer (FloorMap)
	# Dibujar muros perimetrales
	for cell_pos in wall_cells:
		var p := Vector2(cell_pos.x * TILE_SIZE, cell_pos.y * TILE_SIZE)
		# Escalar baldosa de pared para llenar los 64x64
		if tex_wall:
			draw_texture_rect(tex_wall, Rect2(p, Vector2(TILE_SIZE, TILE_SIZE)), false)

func _init_grid() -> void:
	grid.resize(GRID_WIDTH)
	for x in range(GRID_WIDTH):
		var col := []
		col.resize(GRID_HEIGHT)
		col.fill(CellType.EMPTY)
		grid[x] = col

func _carve_floor_rect(x1: int, y1: int, x2: int, y2: int) -> void:
	for x in range(x1, x2 + 1):
		for y in range(y1, y2 + 1):
			if x >= 0 and x < GRID_WIDTH and y >= 0 and y < GRID_HEIGHT:
				grid[x][y] = CellType.PISO

func _build_catedral_layout() -> void:
	# 1. Nave Principal y Naves Laterales (x: 4..29, y: 7..26)
	_carve_floor_rect(4, 7, 29, 26)
	
	# 2. Crucero y Presbiterio hacia el Altar Mayor (x: 8..25, y: 1..7)
	_carve_floor_rect(8, 1, 25, 7)
	
	# 3. Atrio / Entrada Sur (x: 12..21, y: 26..28)
	_carve_floor_rect(12, 26, 21, 28)

	# 4. Alfombra roja de la nave central (x: 16 y 17, y: 4 a 28)
	for y in range(4, 29):
		grid[16][y] = CellType.ALFOMBRA
		grid[17][y] = CellType.ALFOMBRA

	# Spawn del niño (en el atrio de entrada, frente a la alfombra)
	player_spawn_pos = Vector2(17 * TILE_SIZE, 27 * TILE_SIZE)

	# Ubicaciones de los 7 Ojos Escondidos en la Catedral de León
	eye_spawn_positions = [
		Vector2(17 * TILE_SIZE, 2 * TILE_SIZE),                  # Ojo 1: Deambulatorio tras el Altar Mayor
		Vector2(5 * TILE_SIZE + 20, 10 * TILE_SIZE + 10),        # Ojo 2: Confesionario oscuro del ala oeste
		Vector2(10 * TILE_SIZE + 10, 8 * TILE_SIZE + 16),        # Ojo 3: Junto a la estatua del León de piedra
		Vector2(8 * TILE_SIZE, 21 * TILE_SIZE + 16),             # Ojo 4: Entre las bancas de caoba en penumbra
		Vector2(29 * TILE_SIZE - 20, 15 * TILE_SIZE + 20),       # Ojo 5: Nicho del Santo en la Capilla este
		Vector2(28 * TILE_SIZE - 10, 9 * TILE_SIZE + 10),        # Ojo 6: Confesionario de la nave de la epístola
		Vector2(23 * TILE_SIZE + 16, 2 * TILE_SIZE + 16),        # Ojo 7: Esquina secreta de la Sacristía vieja
	]

	# Rutas de patrulla para el Padre sin Cabeza
	# Ruta 1: Nave Central a lo largo de la alfombra roja hasta el Altar
	var route_1: Array[Vector2] = [
		Vector2(17 * TILE_SIZE, 5 * TILE_SIZE),
		Vector2(17 * TILE_SIZE, 15 * TILE_SIZE),
		Vector2(17 * TILE_SIZE, 24 * TILE_SIZE),
		Vector2(17 * TILE_SIZE, 12 * TILE_SIZE)
	]
	# Ruta 2: Nave Lateral Oeste entre confesionarios y bancas
	var route_2: Array[Vector2] = [
		Vector2(6 * TILE_SIZE, 9 * TILE_SIZE),
		Vector2(6 * TILE_SIZE, 22 * TILE_SIZE),
		Vector2(12 * TILE_SIZE, 22 * TILE_SIZE),
		Vector2(12 * TILE_SIZE, 9 * TILE_SIZE)
	]
	# Ruta 3: Nave Lateral Este y Crucero
	var route_3: Array[Vector2] = [
		Vector2(22 * TILE_SIZE, 9 * TILE_SIZE),
		Vector2(28 * TILE_SIZE, 9 * TILE_SIZE),
		Vector2(28 * TILE_SIZE, 22 * TILE_SIZE),
		Vector2(22 * TILE_SIZE, 22 * TILE_SIZE)
	]
	shadow_patrol_routes = [route_1, route_2, route_3]

func _identify_walls() -> void:
	wall_cells.clear()
	floor_cells.clear()
	
	for x in range(GRID_WIDTH):
		for y in range(GRID_HEIGHT):
			var cell: CellType = grid[x][y]
			if cell == CellType.PISO or cell == CellType.ALFOMBRA:
				floor_cells.append({ "pos": Vector2i(x, y), "type": cell })
			else:
				var has_floor_neighbor := false
				for dx: int in [-1, 0, 1]:
					for dy: int in [-1, 0, 1]:
						if dx == 0 and dy == 0:
							continue
						var nx: int = x + dx
						var ny: int = y + dy
						if nx >= 0 and nx < GRID_WIDTH and ny >= 0 and ny < GRID_HEIGHT:
							var n_cell: CellType = grid[nx][ny]
							if n_cell == CellType.PISO or n_cell == CellType.ALFOMBRA:
								has_floor_neighbor = true
								break
					if has_floor_neighbor:
						break
				if has_floor_neighbor:
					grid[x][y] = CellType.WALL
					wall_cells.append(Vector2i(x, y))

func _build_collision_walls() -> void:
	if not walls_body:
		return
		
	# Agrupar segmentos horizontales de muro para optimizar la física
	var visited := {}
	for cell in wall_cells:
		if visited.has(cell):
			continue
		var start_x: int = cell.x
		var y: int = cell.y
		var end_x: int = start_x
		while end_x + 1 < GRID_WIDTH and grid[end_x + 1][y] == CellType.WALL and not visited.has(Vector2i(end_x + 1, y)):
			end_x += 1
			
		for x in range(start_x, end_x + 1):
			visited[Vector2i(x, y)] = true
			
		var count: int = end_x - start_x + 1
		var col_shape := CollisionShape2D.new()
		var rect := RectangleShape2D.new()
		rect.size = Vector2(float(count * TILE_SIZE), float(TILE_SIZE))
		col_shape.shape = rect
		col_shape.position = Vector2(float(start_x * TILE_SIZE) + float(count * TILE_SIZE) / 2.0, float(y * TILE_SIZE) + float(TILE_SIZE) / 2.0)
		walls_body.add_child(col_shape)

func _spawn_catedral_furniture() -> void:
	if not decorations_layer:
		return

	# 1. Altar Mayor: Manejado modularmente por ChurchLandmarksManager en (960, 200)
	# _add_altar_with_candles(Vector2(17 * TILE_SIZE, 3 * TILE_SIZE + 32))

	# 2. Columnas Coloniales Encaladas (48x64)
	# Fila Oeste (x: 13)
	for y_tile in [9, 12, 15, 18, 21, 24]:
		_add_furniture(tex_columna, Vector2(13 * TILE_SIZE + 32, y_tile * TILE_SIZE + 32), Vector2(28, 16), Vector2(0, 16))
	# Fila Este (x: 20)
	for y_tile in [9, 12, 15, 18, 21, 24]:
		_add_furniture(tex_columna, Vector2(20 * TILE_SIZE + 32, y_tile * TILE_SIZE + 32), Vector2(28, 16), Vector2(0, 16))

	# 3. Bancas de Caoba Oscura (64x32)
	# Nave del Evangelio (Oeste)
	for y_tile in [11, 13, 16, 18, 21, 23]:
		_add_furniture(tex_banca, Vector2(7 * TILE_SIZE + 32, y_tile * TILE_SIZE + 32), Vector2(58, 18), Vector2(0, 4))
		_add_furniture(tex_banca, Vector2(10 * TILE_SIZE + 32, y_tile * TILE_SIZE + 32), Vector2(58, 18), Vector2(0, 4))
	# Nave de la Epístola (Este)
	for y_tile in [11, 13, 16, 18, 21, 23]:
		_add_furniture(tex_banca, Vector2(23 * TILE_SIZE + 32, y_tile * TILE_SIZE + 32), Vector2(58, 18), Vector2(0, 4))
		_add_furniture(tex_banca, Vector2(26 * TILE_SIZE + 32, y_tile * TILE_SIZE + 32), Vector2(58, 18), Vector2(0, 4))

	# 4. Estatuas de los Leones de Piedra Colonial (64x64)
	_add_furniture(tex_leon, Vector2(11 * TILE_SIZE + 32, 7 * TILE_SIZE + 32), Vector2(52, 20), Vector2(0, 16))
	_add_furniture(tex_leon, Vector2(22 * TILE_SIZE + 32, 7 * TILE_SIZE + 32), Vector2(52, 20), Vector2(0, 16))

	# 5. Confesionarios de Caoba (64x64) en muros laterales
	_add_furniture(tex_confesionario, Vector2(4 * TILE_SIZE + 36, 10 * TILE_SIZE + 32), Vector2(52, 22), Vector2(0, 16))
	_add_furniture(tex_confesionario, Vector2(4 * TILE_SIZE + 36, 20 * TILE_SIZE + 32), Vector2(52, 22), Vector2(0, 16))
	_add_furniture(tex_confesionario, Vector2(29 * TILE_SIZE + 28, 10 * TILE_SIZE + 32), Vector2(52, 22), Vector2(0, 16))

	# 6. Estatuas de Santos Católicos con velitas (48x64)
	_add_santo_with_light(Vector2(4 * TILE_SIZE + 36, 15 * TILE_SIZE + 32))
	_add_santo_with_light(Vector2(29 * TILE_SIZE + 28, 16 * TILE_SIZE + 32))

func _add_furniture(tex: Texture2D, pos: Vector2, col_size: Vector2, col_offset: Vector2) -> void:
	if not tex:
		return
	var body := StaticBody2D.new()
	body.position = pos
	body.y_sort_enabled = true
	
	var sp := Sprite2D.new()
	sp.texture = tex
	body.add_child(sp)
	
	var col := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = col_size
	col.shape = rect
	col.position = col_offset
	body.add_child(col)
	
	decorations_layer.add_child(body)

func _add_altar_with_candles(pos: Vector2) -> void:
	if not tex_altar:
		return
	var altar_body := StaticBody2D.new()
	altar_body.position = pos
	altar_body.y_sort_enabled = true
	
	var sp := Sprite2D.new()
	sp.texture = tex_altar
	altar_body.add_child(sp)
	
	var col := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(90, 32)
	col.shape = rect
	col.position = Vector2(0, 12)
	altar_body.add_child(col)
	
	# Luz mística de las velas del Altar Mayor
	var light := PointLight2D.new()
	light.texture = TextureGenerator.get_light_halo(160)
	light.color = Color("ffe08a")
	light.energy = 0.95
	light.position = Vector2(0, -10)
	altar_body.add_child(light)
	
	decorations_layer.add_child(altar_body)

func _add_santo_with_light(pos: Vector2) -> void:
	if not tex_santo:
		return
	var santo_body := StaticBody2D.new()
	santo_body.position = pos
	santo_body.y_sort_enabled = true
	
	var sp := Sprite2D.new()
	sp.texture = tex_santo
	santo_body.add_child(sp)
	
	var col := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(36, 18)
	col.shape = rect
	col.position = Vector2(0, 18)
	santo_body.add_child(col)
	
	# Luz cálida tenue de las velitas de devoción
	var light := PointLight2D.new()
	light.texture = TextureGenerator.get_light_halo(80)
	light.color = Color("ffaa44")
	light.energy = 0.65
	light.position = Vector2(0, 12)
	santo_body.add_child(light)
	
	decorations_layer.add_child(santo_body)
