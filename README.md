# RPG Táctico de Calabozos 2D Multijugador

**Motor:** Godot Engine 4.7.2
**Arquitectura:** Data-driven, modular, WebRTC P2P (Host-Client).

## Cómo ejecutar
1. Clonar el repositorio.
2. Abrir el `project.godot` con Godot 4.7.2.
3. Ejecutar la escena principal (pendiente de definir en Fase 1).

## Arquitectura de Carpetas
- `scripts/`: Lógica GDScript pura.
- `resources/`: Instancias `.tres` de datos (armas, clases, enemigos).
- `scenes/`: Nodos y escenas `.tscn`.
- `autoload/`: Singletons globales (Network, Turn, Game).

## Convenciones
- Snake_case para archivos y variables (`player_controller.gd`).
- PascalCase para clases y nodos (`CharacterBase`, `GridManager`).
- Todo dato de juego (daño, vida, rango) debe estar en un `Resource`, nunca hardcodeado.
