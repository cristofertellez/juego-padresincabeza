# Mapa pixel art: Catedral de León (Nicaragua) para Godot

## Qué es
Mapa estilo Pokémon (tiles 16x16) de la Catedral de León, Nicaragua, de 140x88 tiles (2240x1408 px).
`vista_previa.png` muestra cómo se ve el resultado final.

## Archivos (copiar todos a la raíz `res://` del proyecto Godot)
- `tileset.png`: 20 tiles de 16x16 en una sola fila (ids 0 a 19).
- `catedral_map.csv`: matriz 140x88 con el id de tile de cada celda.
- `catedral.gd`: script que arma el TileSet y el TileMapLayer en tiempo de ejecución y lee el CSV. Ya incluye colisiones.
- `Catedral.tscn`: escena lista (Node2D con el script).
- `vista_previa.png`: solo referencia visual, no es necesario en el juego.

## Requisitos
Godot 4.3 o más nuevo (usa `TileMapLayer`).

## Tarea para el agente
1. Copiar `tileset.png`, `catedral_map.csv`, `catedral.gd` y `Catedral.tscn` a `res://`.
2. Si el proyecto ya tiene una escena principal, instanciar `Catedral.tscn` dentro de ella (o dejarla como escena nueva).
3. En la importación de `tileset.png` poner Filter = Nearest (o en Project Settings > Rendering > Textures > Default Texture Filter = Nearest) para que el pixel art no se vea borroso.
4. Agregar un `CharacterBody2D` (jugador) con `CollisionShape2D` y un `Camera2D` con zoom de 3 o 4.
5. Posición de inicio sugerida del jugador: frente a la puerta principal, cerca de la celda (5, 17) en coordenadas de tile del mapa original, que en este mapa duplicado equivale a la celda (10, 35) (multiplicar por 16 px para pasar a píxeles).

## Ids de tiles
0 pasto, 1 piso piedra, 2 muro, 3 pilar, 4 alfombra, 5 altar, 6 puerta, 7 césped, 8 piso claustro, 9 madera, 10 banca, 11 gradas, 12 vitral, 13 plaza, 14 piso capilla, 15 retablo dorado, 16 árbol, 17 fuente, 18 seto, 19 tumba.

Con colisión: 2, 3, 10, 12, 15, 16, 17, 18 (lista `TILES_BLOQUEADOS` en `catedral.gd`).

## Zonas principales (según el plano)
Puerta principal y torres Norte/Sur al oeste; nave central con Altar Mayor, Tumba de Rubén Darío y Coro cordobés; Cristo de Pedrarias y Tabernaculum Domini en los costados; al este la Pinacoteca de la Sala Capitular, el patio, el Bautisterio y la Capilla del Sagrario; Puerta del Príncipe al este.
