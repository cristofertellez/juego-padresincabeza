class_name CatedralMap
extends Node2D

## Mapa oficial de la Catedral de León (Nicaragua) en Pixel Art (140x88 tiles de 16x16 px).
## Carga automáticamente el TileSet, el TileMapLayer y genera las colisiones físicas
## a partir de catedral_map.csv y tileset.png tal y como fue provisto.

const TILE: int = 16
const TILES_BLOQUEADOS: Array[int] = [2, 3, 10, 12, 15, 16, 17, 18] # muro, pilar, banca, vitral, retablo, arbol, fuente, seto

var tile_map_layer: TileMapLayer = null
var player_spawn_pos: Vector2 = Vector2.ZERO
var eye_spawn_positions: Array[Vector2] = []
var shadow_patrol_routes: Array[Array] = []


func _init() -> void:
	_setup_spawn_points()


func _ready() -> void:
	_build_map()
	_setup_boundaries()


func _setup_boundaries() -> void:
	var bounds := StaticBody2D.new()
	bounds.name = "MapBoundaries"
	bounds.collision_layer = 1
	bounds.collision_mask = 1

	var map_w: float = 140.0 * TILE
	var map_h: float = 88.0 * TILE
	var thickness: float = 64.0

	# Muro superior
	_create_boundary_wall(bounds, Vector2(map_w / 2.0, -thickness / 2.0), Vector2(map_w + thickness * 2.0, thickness))
	# Muro inferior
	_create_boundary_wall(bounds, Vector2(map_w / 2.0, map_h + thickness / 2.0), Vector2(map_w + thickness * 2.0, thickness))
	# Muro izquierdo
	_create_boundary_wall(bounds, Vector2(-thickness / 2.0, map_h / 2.0), Vector2(thickness, map_h + thickness * 2.0))
	# Muro derecho
	_create_boundary_wall(bounds, Vector2(map_w + thickness / 2.0, map_h / 2.0), Vector2(thickness, map_h + thickness * 2.0))

	add_child(bounds)


func _create_boundary_wall(parent: Node2D, pos: Vector2, size: Vector2) -> void:
	var shape_node := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = size
	shape_node.shape = rect
	shape_node.position = pos
	parent.add_child(shape_node)


func _build_map() -> void:
	var tile_set := TileSet.new()
	tile_set.tile_size = Vector2i(TILE, TILE)
	tile_set.add_physics_layer()

	var src := TileSetAtlasSource.new()
	var tex := load("res://tileset.png") as Texture2D
	src.texture = tex
	src.texture_region_size = Vector2i(TILE, TILE)
	tile_set.add_source(src, 0)

	var h: float = TILE / 2.0
	var caja := PackedVector2Array([
		Vector2(-h, -h),
		Vector2(h, -h),
		Vector2(h, h),
		Vector2(-h, h)
	])

	for i in range(20):
		src.create_tile(Vector2i(i, 0))
		if i in TILES_BLOQUEADOS:
			var td := src.get_tile_data(Vector2i(i, 0), 0)
			td.add_collision_polygon(0)
			td.set_collision_polygon_points(0, 0, caja)

	tile_map_layer = TileMapLayer.new()
	tile_map_layer.name = "TileMapLayer"
	tile_map_layer.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	tile_map_layer.tile_set = tile_set
	add_child(tile_map_layer)

	var f := FileAccess.open("res://catedral_map.csv", FileAccess.READ)
	if not f:
		push_error("[CatedralMap] No se pudo abrir catedral_map.csv")
		return

	var y: int = 0
	while not f.eof_reached():
		var fila := f.get_csv_line()
		if fila.size() < 2:
			continue
		for x in range(fila.size()):
			tile_map_layer.set_cell(Vector2i(x, y), 0, Vector2i(int(fila[x]), 0))
		y += 1


func _setup_spawn_points() -> void:
	# Posición de inicio del jugador frente a la entrada principal (oeste)
	player_spawn_pos = Vector2(10 * TILE + 8, 35 * TILE + 8)

	# Ubicaciones históricas de los 7 ojos dentro de la Catedral
	eye_spawn_positions = [
		Vector2(84 * TILE + 8, 35 * TILE + 8),   # Ojo 1: Altar Mayor y Presbiterio
		Vector2(57 * TILE + 8, 40 * TILE + 8),   # Ojo 2: Tumba de Rubén Darío (Nave Central)
		Vector2(107 * TILE + 8, 35 * TILE + 8),  # Ojo 3: Claustro y Patio junto a la Fuente
		Vector2(108 * TILE + 8, 16 * TILE + 8),  # Ojo 4: Capilla del Sagrario / Pinacoteca
		Vector2(18 * TILE + 8, 16 * TILE + 8),   # Ojo 5: Torre Norte
		Vector2(18 * TILE + 8, 56 * TILE + 8),   # Ojo 6: Torre Sur
		Vector2(108 * TILE + 8, 60 * TILE + 8),  # Ojo 7: Bautisterio / Capilla Sur
	]

	# Rutas de patrulla para el Padre sin Cabeza (nave central, nave norte, nave sur)
	var route_1: Array[Vector2] = [
		Vector2(25 * TILE, 36 * TILE),
		Vector2(55 * TILE, 36 * TILE),
		Vector2(76 * TILE, 36 * TILE),
		Vector2(55 * TILE, 36 * TILE)
	]

	var route_2: Array[Vector2] = [
		Vector2(30 * TILE, 20 * TILE),
		Vector2(55 * TILE, 20 * TILE),
		Vector2(76 * TILE, 20 * TILE),
		Vector2(55 * TILE, 20 * TILE)
	]

	var route_3: Array[Vector2] = [
		Vector2(30 * TILE, 52 * TILE),
		Vector2(55 * TILE, 52 * TILE),
		Vector2(76 * TILE, 52 * TILE),
		Vector2(55 * TILE, 52 * TILE)
	]

	shadow_patrol_routes = [route_1, route_2, route_3]
