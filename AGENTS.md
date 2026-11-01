# Reglas y Asistencia de Desarrollo - Godot 4 (Búsqueda de Ojos / Padre sin Cabeza)

Este documento define las reglas de codificación, estándares de arquitectura y directrices de asistencia para cualquier modificación en los scripts (`.gd`), escenas (`.tscn`), shaders (`.gdshader`) y recursos del proyecto `juego-padresincabeza`.

---

## 1. Reglas Estrictas para Scripts GDScript (`.gd`)

1. **Tipado Estático Obligatorio**:
   - Todo parámetro de función, valor de retorno y variable debe declarar su tipo estático de forma explícita.
   - Ejemplo:
     ```gdscript
     var health: int = 3
     var items: Array[EyeItem] = []
     func apply_damage(amount: int) -> void:
     ```
   - Evitar `Variant` a menos que sea estrictamente indispensable.

2. **Convenciones de Nomenclatura**:
   - **Archivos**: `snake_case.gd`
   - **Clases**: Declarar `class_name PascalCase` al inicio del script.
   - **Nodos en escena**: `PascalCase` (`AnimatedSprite2D`, `CollisionShape2D`, `PointLight2D`).
   - **Variables y Funciones**: `snake_case` (ej. `move_speed`, `_update_hud()`).
   - **Funciones privadas / internas**: Siempre con prefijo `_` (ej. `_on_body_entered()`).
   - **Constantes**: `UPPER_SNAKE_CASE` (ej. `TOTAL_EYES = 7`).

3. **Sintaxis Moderna Godot 4**:
   - **Señales**: Usar siempre sintaxis de `Callable`:
     - Conectar: `signal_name.connect(callable)`
     - Desconectar: `signal_name.disconnect(callable)`
     - Emitir: `signal_name.emit(args)`
     - Vincular argumentos: `signal_name.connect(_callback.bind(arg))`
     - **PROHIBIDO**: Usar la sintaxis antigua de cadenas de Godot 3 (`connect("signal", self, "method")`).
   - **Movimiento de CharacterBody2D**:
     - Asignar `velocity = dir * speed`.
     - Invocar `move_and_slide()` sin pasar argumentos ni multiplicar por `delta`.
   - **Temporizadores y Esperas**:
     - Preferir `await get_tree().create_timer(duration).timeout` o `await get_tree().process_frame`.

4. **Acceso Seguro a Nodos e Inyección**:
   - En `@onready`, siempre tipar la variable (`@onready var light: PointLight2D = $PointLight2D`).
   - Validar referencias antes de acceder a propiedades o métodos si el nodo puede no estar presente en todas las variantes de la escena (`if sprite: sprite.play()`).
   - Limpieza de nodos siempre con `queue_free()`.

---

## 2. Reglas para Escenas (`.tscn`) y Nodos

1. **Top-Down Y-Sorting**:
   - Todas las entidades que se muevan o proyecten altura (Jugador, Sombras, Candelabros, Columnas) deben tener `y_sort_enabled = true`.
   - El nodo contenedor en la escena principal también debe tener `y_sort_enabled = true`.

2. **Matriz de Capas de Colisión (Collision Layers)**:
   - Capa 1: Entorno / Muros de la catedral.
   - Capa 2: Jugador (`Player`).
   - Capa 3: Sombras / Enemigos (`ShadowEnemy`).
   - Capa 4: Reliquias oculares (`EyeItem`).
   - No habilitar máscaras innecesarias para optimizar el motor de físicas.

3. **Iluminación y Arte Pixelado**:
   - Mantener resolución base `640x360` y filtrado `Nearest` para preservar la estética pixel art limpia.
   - Todo objeto emisor de luz debe usar luces cálidas (`#ffe5ad` candil, `#fff0cc` linterna).
   - El ambiente general se modula con `CanvasModulate` oscuro (`#05050b`).

4. **Integridad de Recursos y UIDs**:
   - Godot 4 asocia archivos `.uid` a cada archivo de script y escena.
   - Al crear o modificar archivos, no corromper ni eliminar los archivos `.uid` existentes.

---

## 3. Asistencia al Desarrollador

- Antes de proponer cambios, verificar compatibilidad con `GameManager` (`scripts/main.gd`), `Player` (`scripts/player.gd`) y el sistema de sonido `SoundManager` (`scripts/sound_manager.gd`).
- Mantener los comentarios en español claros y concisos, documentando intenciones narrativas y mecánicas del juego.
