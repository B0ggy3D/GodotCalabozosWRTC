class_name CharacterController
extends Node

## Componente de control de personaje.
## Maneja la logica de movimiento y acciones por turno.
## NO maneja combate, inventario, ni IA.

# --- Senales para desacoplar de la capa visual y de red ---
signal action_performed(action_type: String, result: bool)
signal position_changed(new_grid_pos: Vector2i)
signal actions_updated(remaining_actions: int)

# --- Datos del personaje ---
@export var character_data: CharacterInstanceData = null

# --- Estado de turno ---
var remaining_actions: int = 0

func _ready():
	if character_data == null:
		push_warning("CharacterController: No se asigno CharacterInstanceData.")
		return
	
	# Inicializar acciones desde los datos de la clase
	_reset_actions()

# --- API PUBLICA ---

## Intenta mover al personaje en una direccion (ej. Vector2i(1,0) para derecha)
## Retorna true si el movimiento fue exitoso
func try_move(direction: Vector2i) -> bool:
	if character_data == null:
		push_warning("CharacterController: Sin datos de personaje.")
		return false
	
	if remaining_actions <= 0:
		action_performed.emit("move", false)
		return false
	
	var target_pos = character_data.grid_position + direction
	
	# Validar con el GridManager
	if not GridManager.is_walkable(target_pos):
		action_performed.emit("move", false)
		return false
	
	# Ejecutar el movimiento
	_execute_move(target_pos)
	return true

## Intenta mover a una posicion absoluta del grid
func try_move_to(target_pos: Vector2i) -> bool:
	if character_data == null:
		return false
	
	if remaining_actions <= 0:
		action_performed.emit("move", false)
		return false
	
	if not GridManager.is_walkable(target_pos):
		action_performed.emit("move", false)
		return false
	
	_execute_move(target_pos)
	return true

## Consume una accion sin moverse (para futuros usos: atacar, usar item, etc.)
func consume_action() -> bool:
	if remaining_actions <= 0:
		return false
	
	remaining_actions -= 1
	character_data.current_actions = remaining_actions
	actions_updated.emit(remaining_actions)
	return true

## Obtiene la posicion mundial (Vector2) para la capa visual
func get_world_position() -> Vector2:
	return GridManager.grid_to_world(character_data.grid_position)

## Resetea las acciones al inicio del turno
func start_turn():
	_reset_actions()

# --- LOGICA INTERNA ---

func _execute_move(target_pos: Vector2i):
	# Liberar la casilla anterior
	GridManager.clear_occupant(character_data.grid_position)
	
	# Actualizar posicion logica
	character_data.grid_position = target_pos
	
	# Ocupar la nueva casilla
	GridManager.set_occupant(target_pos, character_data.character_id)
	
	# Consumir accion
	remaining_actions -= 1
	character_data.current_actions = remaining_actions
	
	# Notificar al mundo
	position_changed.emit(target_pos)
	actions_updated.emit(remaining_actions)
	action_performed.emit("move", true)

func _reset_actions():
	if character_data and character_data.class_data:
		remaining_actions = character_data.class_data.actions_per_turn
	else:
		remaining_actions = 2  # Fallback por defecto
	
	if character_data:
		character_data.current_actions = remaining_actions
	
	actions_updated.emit(remaining_actions)
