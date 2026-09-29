class_name CharacterController
extends Node
## =========================================================================
## CharacterController: Componente de control de personaje.
## =========================================================================
##
## RESPONSABLE DE:
## - Movimiento por el grid (casilla por casilla o rutas completas)
## - Gestión de acciones por turno
## - Validación de movimientos antes de ejecutarlos
##
## NO RESPONSABLE DE:
## - Combate (usar CombatSystem)
## - Inventario (usar sistema de Persona 4)
## - IA (usar comportamientos de Persona 3)
## - Networking (usar NetworkManager de Persona 2)
##
## =========================================================================
## GUIA PARA PERSONA 2 (WEBRTC / MULTIPLAYER):
## =========================================================================
##
## Para validar movimientos en red:
##
## 1. El CLIENTE envia una solicitud al HOST:
##    { "type": "move_request", "player_id": "net_p1", "target": Vector2i(5,3) }
##
## 2. El HOST recibe la solicitud y valida:
##    var controller = get_controller_for_player(player_id)
##    if controller.can_reach(target_pos):
##        var path = controller.get_path_to(target_pos)
##        controller.execute_move(path)  # Ejecuta y consume accion
##        # Enviar resultado a todos los clientes
##
## 3. El CLIENTE recibe la confirmacion y actualiza la posicion visual.
##
## IMPORTANTE: El cliente NUNCA debe llamar a try_move() o move_to()
## directamente. Solo el HOST ejecuta movimientos y transmite el resultado.
##
## Para sincronizar la posicion:
## - Usar character_data.grid_position como fuente de verdad
## - La posicion visual se calcula con GridManager.grid_to_world()
##
## =========================================================================
## GUIA PARA PERSONA 3 (IA / ENEMIGOS):
## =========================================================================
##
## Para mover un enemigo con IA:
##
## 1. Calcular el destino (ej: posicion del jugador mas cercano)
##    var target = get_nearest_player_position()
##
## 2. Usar el controller del enemigo:
##    var controller = enemy_node.get_node("CharacterController")
##    if controller.can_reach(target):
##        controller.move_to(target)
##    else:
##        # Moverse lo mas cerca posible
##        var path = controller.get_path_to_adjacent(target)
##        controller.execute_move(path)
##
## 3. Para persecucion (moverse hacia el jugador sin pisarlo):
##    var path = Pathfinding.find_path_to_adjacent(enemy_pos, player_pos)
##    controller.execute_move(path)
##
## La IA puede usar can_reach() para decidir si perseguir o atacar.
##
## =========================================================================
## GUIA PARA PERSONA 4 (UI / PRESENTACION):
## =========================================================================
##
## Para animar el movimiento:
## - Escuchar la senal "position_changed" para mover el sprite
## - Escuchar la senal "path_started" para mostrar la ruta
## - Escuchar la senal "actions_updated" para actualizar el HUD
##
## La posicion visual se obtiene con:
##    var world_pos = GridManager.grid_to_world(controller.character_data.grid_position)
##
## =========================================================================

# --- Senales para desacoplar de la capa visual y de red ---
## Emitida cuando el personaje cambia de posicion logica
signal position_changed(new_grid_pos: Vector2i)
## Emitida cuando las acciones restantes cambian
signal actions_updated(remaining_actions: int)
## Emitida cuando se realiza cualquier accion (exito o fallo)
signal action_performed(action_type: String, result: bool)
## Emitida cuando se inicia un movimiento por ruta (util para animaciones)
signal path_started(path: Array[Vector2i])
## Emitida cuando se completa un movimiento por ruta
signal path_completed(final_pos: Vector2i)
## Emitida cuando el personaje no puede moverse (sin acciones, bloqueado, etc.)
signal move_blocked(reason: String)

# --- Datos del personaje ---
## Recurso que contiene toda la informacion del personaje.
## Se asigna desde fuera (escena, GameState, o NetworkManager).
@export var character_data: CharacterInstanceData = null

# --- Estado de turno ---
## Acciones restantes en el turno actual.
## Se resetea con start_turn().
var remaining_actions: int = 0

## Ruta actual si esta en medio de un movimiento multi-casilla
var current_path: Array[Vector2i] = []
var is_moving: bool = false

# =========================================================================
# CICLO DE VIDA
# =========================================================================

func _ready():
	if character_data == null:
		push_warning("CharacterController: No se asigno CharacterInstanceData.")
		return
	
	_reset_actions()

# =========================================================================
# API PUBLICA: INICIO/FIN DE TURNO
# =========================================================================

## Inicia el turno del personaje.
## Resetee las acciones al valor definido por su clase.
##
## USO (Persona 2): El HOST llama esto cuando el TurnManager indica
## que es el turno de este personaje.
##
## USO (Persona 3): La IA no necesita llamar esto, el TurnManager lo hace.
func start_turn():
	_reset_actions()

## Termina el turno del personaje.
## Limpia cualquier movimiento en progreso.
func end_turn():
	current_path.clear()
	is_moving = false

# =========================================================================
# API PUBLICA: MOVIMIENTO BASICO (1 casilla)
# =========================================================================

## Intenta mover al personaje en una direccion (ej: Vector2i(1,0) = derecha).
## Consume 1 accion si tiene exito.
##
## USO (Persona 2): El HOST valida y ejecuta despues de recibir
## la solicitud del cliente.
##
## USO (Persona 4): Para input directo del jugador con teclado/mouse.
##
## @param direction: Direccion del movimiento (solo 4 direcciones).
## @return: true si el movimiento fue exitoso, false si no.
func try_move(direction: Vector2i) -> bool:
	if character_data == null:
		push_warning("CharacterController: Sin datos de personaje.")
		return false
	
	if remaining_actions <= 0:
		emit_signal("move_blocked", "No quedan acciones")
		emit_signal("action_performed", "move", false)
		return false
	
	var target_pos = character_data.grid_position + direction
	
	if not GridManager.is_walkable(target_pos):
		emit_signal("move_blocked", "Casilla no caminable u ocupada")
		emit_signal("action_performed", "move", false)
		return false
	
	_execute_single_move(target_pos)
	return true

## Intenta mover a una posicion absoluta del grid (1 casilla de distancia).
## El destino debe estar adyacente a la posicion actual.
##
## @param target_pos: Posicion destino en el grid.
## @return: true si el movimiento fue exitoso.
func try_move_to(target_pos: Vector2i) -> bool:
	if character_data == null:
		return false
	
	if remaining_actions <= 0:
		emit_signal("move_blocked", "No quedan acciones")
		emit_signal("action_performed", "move", false)
		return false
	
	# Verificar que sea adyacente
	var distance = _manhattan_distance(character_data.grid_position, target_pos)
	if distance != 1:
		emit_signal("move_blocked", "Destino no adyacente (usar move_to para rutas)")
		emit_signal("action_performed", "move", false)
		return false
	
	if not GridManager.is_walkable(target_pos):
		emit_signal("move_blocked", "Casilla no caminable u ocupada")
		emit_signal("action_performed", "move", false)
		return false
	
	_execute_single_move(target_pos)
	return true

# =========================================================================
# API PUBLICA: MOVIMIENTO POR RUTA (PATHFINDING)
# =========================================================================

## Mueve al personaje hacia un destino usando Pathfinding A*.
## Consume 1 accion de movimiento.
## El personaje se mueve hasta movement_range casillas por accion.
##
## USO (Persona 2): El HOST ejecuta esto despues de validar la solicitud.
##    var path = controller.get_path_to(target)
##    if controller.can_reach(target):
##        controller.move_to(target)
##
## USO (Persona 3): La IA usa esto para mover enemigos.
##    controller.move_to(player_position)
##
## @param target: Posicion destino en el grid.
## @return: true si el movimiento fue exitoso.
func move_to(target: Vector2i) -> bool:
	if character_data == null:
		push_warning("CharacterController: Sin datos de personaje.")
		return false
	
	if remaining_actions <= 0:
		emit_signal("move_blocked", "No quedan acciones")
		emit_signal("action_performed", "move", false)
		return false
	
	# Calcular ruta
	var path = Pathfinding.find_path(character_data.grid_position, target)
	
	if path.is_empty():
		emit_signal("move_blocked", "No se encontro ruta al destino")
		emit_signal("action_performed", "move", false)
		return false
	
	# Limitar la ruta al rango de movimiento
	var max_steps = _get_movement_range()
	var limited_path = _limit_path_length(path, max_steps)
	
	if limited_path.size() <= 1:
		emit_signal("move_blocked", "Destino inalcanzable con las acciones actuales")
		emit_signal("action_performed", "move", false)
		return false
	
	# Ejecutar el movimiento
	return execute_move(limited_path)

## Mueve al personaje hacia una posicion adyacente al objetivo.
## Util para acercarse a enemigos sin pisar su casilla.
## Consume 1 accion de movimiento.
##
## USO (Persona 3): Para IA de persecucion.
##    controller.move_to_adjacent(player_position)
##
## @param target: Posicion del objetivo (puede estar ocupada).
## @return: true si el movimiento fue exitoso.
func move_to_adjacent(target: Vector2i) -> bool:
	if character_data == null:
		return false
	
	if remaining_actions <= 0:
		emit_signal("move_blocked", "No quedan acciones")
		emit_signal("action_performed", "move", false)
		return false
	
	# Calcular ruta hacia casilla adyacente al objetivo
	var path = Pathfinding.find_path_to_adjacent(character_data.grid_position, target)
	
	if path.is_empty():
		emit_signal("move_blocked", "No se encontro ruta adyacente al objetivo")
		emit_signal("action_performed", "move", false)
		return false
	
	# Limitar al rango de movimiento
	var max_steps = _get_movement_range()
	var limited_path = _limit_path_length(path, max_steps)
	
	if limited_path.size() <= 1:
		emit_signal("move_blocked", "Ya esta adyacente o no puede acercarse mas")
		emit_signal("action_performed", "move", false)
		return false
	
	return execute_move(limited_path)

## Ejecuta un movimiento a lo largo de una ruta precalculada.
## Consume 1 accion.
##
## USO (Persona 2): Despues de validar la ruta, el HOST ejecuta:
##    var path = controller.get_path_to(target)
##    controller.execute_move(path)
##
## USO (Persona 3): La IA puede precalcular rutas y ejecutarlas.
##
## @param path: Array de Vector2i con la ruta (incluye posicion actual).
## @return: true si el movimiento fue exitoso.
func execute_move(path: Array[Vector2i]) -> bool:
	if character_data == null:
		return false
	
	if remaining_actions <= 0:
		emit_signal("move_blocked", "No quedan acciones")
		emit_signal("action_performed", "move", false)
		return false
	
	if path.size() < 2:
		emit_signal("move_blocked", "Ruta vacia o sin movimiento")
		emit_signal("action_performed", "move", false)
		return false
	
	# Validar que toda la ruta sea caminable
	for i in range(1, path.size()):
		if not GridManager.is_walkable(path[i]):
			emit_signal("move_blocked", "Ruta bloqueada en casilla %s" % str(path[i]))
			emit_signal("action_performed", "move", false)
			return false
	
	# Liberar la casilla actual
	GridManager.clear_occupant(character_data.grid_position)
	
	# Emitir senal de inicio de ruta (para animaciones)
	emit_signal("path_started", path)
	
	# Mover al final de la ruta
	var final_pos = path[-1]
	character_data.grid_position = final_pos
	
	# Ocupar la nueva casilla
	GridManager.set_occupant(final_pos, character_data.character_id)
	
	# Consumir accion
	remaining_actions -= 1
	character_data.current_actions = remaining_actions
	
	# Emitir senales
	emit_signal("position_changed", final_pos)
	emit_signal("actions_updated", remaining_actions)
	emit_signal("path_completed", final_pos)
	emit_signal("action_performed", "move", true)
	
	return true

# =========================================================================
# API PUBLICA: CONSULTAS Y VALIDACIONES
# =========================================================================

## Verifica si el personaje puede llegar a un destino con sus acciones actuales.
## NO ejecuta el movimiento, solo valida.
##
## USO (Persona 2): El HOST valida antes de ejecutar:
##    if controller.can_reach(target):
##        controller.move_to(target)
##        # Enviar confirmacion al cliente
##    else:
##        # Enviar rechazo al cliente
##
## USO (Persona 3): La IA decide si perseguir o hacer otra cosa.
##
## @param target: Posicion destino.
## @return: true si puede llegar con las acciones actuales.
func can_reach(target: Vector2i) -> bool:
	if character_data == null:
		return false
	
	if remaining_actions <= 0:
		return false
	
	var path = Pathfinding.find_path(character_data.grid_position, target)
	if path.is_empty():
		return false
	
	var steps_needed = Pathfinding.get_path_length(path)
	var max_steps = _get_movement_range()
	
	return steps_needed <= max_steps

## Obtiene la ruta hacia un destino sin ejecutar el movimiento.
## Util para validacion y para mostrar la ruta en la UI.
##
## USO (Persona 2): Para validar y transmitir la ruta al cliente.
## USO (Persona 4): Para mostrar la ruta en el HUD antes de mover.
##
## @param target: Posicion destino.
## @return: Array de Vector2i con la ruta, o Array vacio si no hay ruta.
func calculate_path_to(target: Vector2i) -> Array[Vector2i]:
	if character_data == null:
		return []
	
	return Pathfinding.find_path(character_data.grid_position, target)

## Obtiene la ruta hacia una casilla adyacente al objetivo.
## Util para acercarse a enemigos.
##
## @param target: Posicion del objetivo (puede estar ocupada).
## @return: Array de Vector2i con la ruta, o Array vacio.
func calculate_path_to_adjacent(target: Vector2i) -> Array[Vector2i]:
	if character_data == null:
		return []
	
	return Pathfinding.find_path_to_adjacent(character_data.grid_position, target)

## Obtiene la posicion mundial (Vector2) para la capa visual.
##
## USO (Persona 4): Para posicionar el sprite del personaje.
##    var world_pos = controller.get_world_position()
##    sprite.position = world_pos
##
## @return: Posicion en pixeles (centro de la casilla).
func get_world_position() -> Vector2:
	return GridManager.grid_to_world(character_data.grid_position)

## Obtiene el rango de movimiento actual del personaje.
## Puede ser modificado por buffs/debuffs en el futuro.
##
## @return: Numero de casillas que puede moverse por accion.
func _get_movement_range() -> int:
	if character_data and character_data.class_data:
		return character_data.class_data.movement_range
	return 4  # Default

# =========================================================================
# API PUBLICA: ACCIONES GENERICAS
# =========================================================================

## Consume una accion sin realizar movimiento.
## Util para futuras acciones: usar item, interactuar, etc.
##
## @return: true si se consumio la accion, false si no quedaban.
func consume_action() -> bool:
	if remaining_actions <= 0:
		return false
	
	remaining_actions -= 1
	character_data.current_actions = remaining_actions
	emit_signal("actions_updated", remaining_actions)
	return true

## Verifica si el personaje tiene acciones disponibles.
##
## @return: true si quedan acciones.
func has_actions_remaining() -> bool:
	return remaining_actions > 0

# =========================================================================
# LOGICA INTERNA
# =========================================================================

func _execute_single_move(target_pos: Vector2i):
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
	emit_signal("position_changed", target_pos)
	emit_signal("actions_updated", remaining_actions)
	emit_signal("action_performed", "move", true)

func _reset_actions():
	if character_data and character_data.class_data:
		remaining_actions = character_data.class_data.actions_per_turn
	else:
		remaining_actions = 2  # Fallback por defecto
	
	if character_data:
		character_data.current_actions = remaining_actions
	
	emit_signal("actions_updated", remaining_actions)

func _manhattan_distance(a: Vector2i, b: Vector2i) -> int:
	return abs(a.x - b.x) + abs(a.y - b.y)

func _limit_path_length(path: Array[Vector2i], max_steps: int) -> Array[Vector2i]:
	## Limita una ruta a un numero maximo de pasos.
	## La ruta incluye la posicion de inicio, asi que el limite es max_steps + 1.
	if path.size() <= max_steps + 1:
		return path
	
	var limited: Array[Vector2i] = []
	for i in range(max_steps + 1):
		limited.append(path[i])
	
	return limited
