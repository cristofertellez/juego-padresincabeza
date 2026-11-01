---
name: godot-padresincabeza
description: >-
  Guía y asistencia de desarrollo especializada para el proyecto Godot 4 "juego-padresincabeza"
  (Búsqueda de Ojos / Leyenda del Padre sin Cabeza). Usar esta skill al crear, editar o refactorizar
  scripts .gd, escenas .tscn, shaders .gdshader y componentes del juego.
---

# Skill: Desarrollo Godot 4 - "Búsqueda de Ojos" (Padre sin Cabeza)

Esta skill proporciona flujos de trabajo, directrices de arquitectura y patrones de código para el desarrollo del proyecto **juego-padresincabeza** en **Godot Engine 4.7+**.

---

## 1. Contexto del Proyecto y Arquitectura

- **Motor**: Godot 4.7 (Render: Forward Plus / Compatibilidad 2D).
- **Resolución base**: Viewport `640x360` escalado a `1280x720` con `canvas_items` y filtro `nearest` (`default_texture_filter=0`) con pixel snapping activado (`snap_2d_transforms_to_pixel`).
- **Género**: Terror y exploración 2D top-down inspirado en la leyenda colonial de la Catedral de León.
- **Mecánicas clave**:
  - Jugador con candil (`PointLight2D`) y linterna auxiliar por ratón (`MouseLight`).
  - Ambiente de oscuridad total controlado por `CanvasModulate` (`#05050b`).
  - Recolección de 7 reliquias oculares (`EyeItem`).
  - Enemigos espectrales (`ShadowEnemy`) que acechan al jugador evitando fuentes de luz directas.
  - Generador de mazmorra/catedral (`DungeonBuilder`) y decoraciones procedurales.
  - Pantalla de inicio con fondo de video interactivo (`VideoStreamPlayer`) y menú accesible por ratón/teclado/gamepad.

---

## 2. Convenciones y Estándares de GDScript (Godot 4)

### 2.1 Tipado Estático Obligatorio
Todos los scripts nuevos y refactorizados deben usar tipado estático estricto:
```gdscript
# Correcto
var collected_eyes: int = 0
var active_enemies: Array[ShadowEnemy] = []
func take_damage(amount: int) -> bool:
    ...
```

### 2.2 Nombres y Estilo
- **Archivos de script**: `snake_case.gd` (ej. `sound_manager.gd`, `church_prop.gd`).
- **Clases globales**: Usar `class_name PascalCase` al inicio del archivo (ej. `class_name Player`, `class_name EyeItem`).
- **Nodos en escena**: `PascalCase` (ej. `AnimatedSprite2D`, `CollisionShape2D`, `PointLight2D`).
- **Constantes**: `UPPER_SNAKE_CASE` (ej. `TOTAL_EYES: int = 7`).
- **Variables y funciones**: `snake_case` (ej. `is_invulnerable`, `_spawn_player()`).
- **Funciones privadas/internas**: Prefijadas con guión bajo `_` (ej. `_setup_lights()`).

### 2.3 Manejo Moderno de Señales (Godot 4)
Nunca usar la sintaxis de Godot 3 basada en strings (`connect("body_entered", self, "_on_...")`).
Usar siempre el objeto Callable de Godot 4:
```gdscript
# Declaración
signal health_changed(current_health: int, max_health: int)
signal eye_collected(collected: int, total: int)

# Conexión
body_entered.connect(_on_body_entered)
button.pressed.connect(_on_button_pressed)

# Conexión con parámetros vinculados (bind)
btn.mouse_entered.connect(_on_button_mouse_entered.bind(index))

# Emisión
health_changed.emit(current_health, max_health)
```

### 2.4 Acceso Seguro a Nodos (@onready)
- Especificar el tipo concreto del nodo en `@onready`.
- Validar existencia si el nodo es opcional o instanciado dinámicamente.
```gdscript
@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var light: PointLight2D = $PointLight2D
@onready var collision_shape: CollisionShape2D = $CollisionShape2D
```

### 2.5 Ciclo de Vida y Físicas
- **Físicas y movimiento**: Usar estrictamente `_physics_process(delta: float)`.
- En Godot 4, `move_and_slide()` no recibe parámetros (la velocidad debe asignarse a `velocity` previamente):
```gdscript
func _physics_process(delta: float) -> void:
    velocity = input_direction * speed
    move_and_slide()
```
- **Liberación de memoria**: Utilizar siempre `queue_free()`, jamás eliminar nodos en el mismo frame si tienen señales activas.
- **Asegurar orden de carga**: Usar `await get_tree().process_frame` cuando se necesite sincronizar nodos instanciados dinámicamente.

---

## 3. Reglas para Escenas y Nodos (`.tscn`)

1. **Y-Sorting en Top-Down**:
   - El nodo raíz del mapa o del nivel debe tener `y_sort_enabled = true`.
   - El jugador (`Player`), enemigos (`ShadowEnemy`), candelabros y props deben tener `y_sort_enabled = true` para que la profundidad visual se renderice correctamente en función del eje Y.

2. **Capas de Colisión (Collision Layers & Masks)**:
   - Mantener consistencia en la matriz de capas físicas de 2D:
     - Capa 1: Entorno / Paredes de la catedral.
     - Capa 2: Jugador.
     - Capa 3: Enemigos / Sombras.
     - Capa 4: Coleccionables / Ojos (`Area2D`).
     - Capa 5: Luz y detección de rango.

3. **Iluminación 2D y Atmósfera**:
   - Mantener el `CanvasModulate` en tonos oscuros azulados/morados (`#05050b`).
   - Las luces de candil y velas deben usar luz cálida colonial (`#ffe5ad` o `#fff0cc`).
   - Usar `TextureGenerator.get_light_halo(...)` o texturas con gradientes suaves para evitar artefactos circulares rígidos.

4. **Compatibilidad con Shaders**:
   - Los shaders deben colocarse en `shaders/*.gdshader`.
   - Usar `shader_type canvas_item;` y declarar `uniform` con valores por defecto documentados.

---

## 4. Ejecución y Herramientas del Entorno

El binario de Godot 4 se encuentra en la raíz del espacio de trabajo:
- Ejecutable de consola: `..\Godot_v4.7.2-stable_win64.exe\Godot_v4.7.2-stable_win64_console.exe`

Para probar la carga del proyecto o ejecutar scripts de verificación:
```powershell
& "..\Godot_v4.7.2-stable_win64.exe\Godot_v4.7.2-stable_win64_console.exe" --path "." <argumentos>
```

---

## 5. Procedimientos de Asistencia y Desarrollo

Cuando se solicite agregar una nueva función o arreglar un script:
1. **Inspección de Dependencias**: Verificar si el script interactúa con `GameManager` (`main.gd`), `Player` (`player.gd`) o `SoundManager` (`sound_manager.gd`).
2. **Respeto a la Estética**: Mantener la coherencia pixel art 640x360 y la ambientación colonial/oscura.
3. **Validación de Tipos y Null Safety**: Validar referencias nulas antes de invocar métodos de nodos (`if light: light.energy = ...`).
4. **No romper UIDs**: Si se modifica un `.tscn` o `.gd`, respetar los archivos `.uid` correspondientes creados por Godot 4.
