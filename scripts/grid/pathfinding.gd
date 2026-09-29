extends Node
## Pathfinding: Autoload que calcula rutas en el grid usando A*.
## Usado por: IA de enemigos (Persona 3), movimiento inteligente, validaciones.

# --- Senales ---
signal path_found(start: Vector2i, end: Vector2i, path: Array[Vector2i])
signal no_path_found(start: Vector2i, end: Vector2i)

# --- Nodos internos para A* ---
class AStarNode:
	var position: Vector2i
	var parent: AStarNode = null
	var g_cost: float = 0.0  # Costo desde el inicio
	var h_cost: float = 0.0  # Heuristica (estimacion al destino)
	var f_cost: float = 0.0  # g + h
	
	func _init(pos: Vector2i):
		position = pos
	
	func get_f_cost() -> float:
		return g_cost + h_cost

# --- API PUBLICA ---

## Encuentra la ruta mas corta entre dos posiciones del grid.
## Retorna un Array de Vector2i (incluye start y end).
## Si no hay ruta, retorna un Array vacio.
func find_path(start: Vector2i, end: Vector2i) -> Array[Vector2i]:
	# Validaciones basicas
	if not GridManager.is_valid_position(start):
		push_warning("[Pathfinding] Posicion de inicio invalida: ", start)
		return []
	
	if not GridManager.is_valid_position(end):
		push_warning("[Pathfinding] Posicion de destino invalida: ", end)
		return []
	
	if start == end:
		return [start]
	
	# Si el destino no es caminable, no hay ruta
	if not GridManager.is_walkable(end):
		# Intentar encontrar la casilla caminable mas cercana al destino
		# (util para moverse "hacia" un enemigo sin pisarlo)
		pass
	
	# A* Algorithm
	var open_set: Array[AStarNode] = []
	var closed_set: Dictionary = {}  # Vector2i -> AStarNode
	
	var start_node = AStarNode.new(start)
	var end_node = AStarNode.new(end)
	
	open_set.append(start_node)
	
	while not open_set.is_empty():
		# Encontrar el nodo con menor F cost
		var current_node = _get_lowest_f_cost(open_set)
		open_set.erase(current_node)
		closed_set[current_node.position] = current_node
		
		# Llegamos al destino
		if current_node.position == end:
			var path = _reconstruct_path(current_node)
			emit_signal("path_found", start, end, path)
			return path
		
		# Expandir vecinos
		for neighbor_pos in _get_neighbors(current_node.position):
			if closed_set.has(neighbor_pos):
				continue
			
			if not GridManager.is_walkable(neighbor_pos):
				continue
			
			var g_cost_to_neighbor = current_node.g_cost + 1.0
			var existing_node = _find_in_open_set(open_set, neighbor_pos)
			
			if existing_node == null:
				var neighbor_node = AStarNode.new(neighbor_pos)
				neighbor_node.parent = current_node
				neighbor_node.g_cost = g_cost_to_neighbor
				neighbor_node.h_cost = _heuristic(neighbor_pos, end)
				open_set.append(neighbor_node)
			elif g_cost_to_neighbor < existing_node.g_cost:
				existing_node.parent = current_node
				existing_node.g_cost = g_cost_to_neighbor
	
	# No se encontro ruta
	emit_signal("no_path_found", start, end)
	return []

## Encuentra la ruta pero sin incluir la posicion de inicio.
## Util para movimientos secuenciales.
func find_path_without_start(start: Vector2i, end: Vector2i) -> Array[Vector2i]:
	var path = find_path(start, end)
	if path.size() > 1:
		path.remove_at(0)
	return path

## Encuentra la casilla caminable mas cercana a un destino no caminable.
## Util para acercarse a enemigos (que ocupan su casilla).
func find_path_to_adjacent(start: Vector2i, target: Vector2i) -> Array[Vector2i]:
	# Si el target es caminable, buscar ruta normal
	if GridManager.is_walkable(target):
		return find_path(start, target)
	
	# Si no, buscar la casilla adyacente caminable mas cercana
	var best_neighbor = Vector2i.ZERO
	var best_distance = INF
	
	for neighbor in _get_neighbors(target):
		if GridManager.is_valid_position(neighbor) and GridManager.is_walkable(neighbor):
			var dist = _manhattan_distance(start, neighbor)
			if dist < best_distance:
				best_distance = dist
				best_neighbor = neighbor
	
	if best_distance < INF:
		return find_path(start, best_neighbor)
	
	return []

## Calcula la distancia de la ruta (numero de pasos)
func get_path_length(path: Array[Vector2i]) -> int:
	if path.size() <= 1:
		return 0
	return path.size() - 1

# --- LOGICA INTERNA ---

func _get_neighbors(pos: Vector2i) -> Array[Vector2i]:
	# Movimiento en 4 direcciones (sin diagonal)
	return [
		pos + Vector2i(1, 0),   # Derecha
		pos + Vector2i(-1, 0),  # Izquierda
		pos + Vector2i(0, 1),   # Abajo
		pos + Vector2i(0, -1)   # Arriba
	]

func _heuristic(a: Vector2i, b: Vector2i) -> float:
	# Distancia Manhattan (adecuada para grid sin diagonal)
	return float(_manhattan_distance(a, b))

func _manhattan_distance(a: Vector2i, b: Vector2i) -> int:
	return abs(a.x - b.x) + abs(a.y - b.y)

func _get_lowest_f_cost(nodes: Array[AStarNode]) -> AStarNode:
	var lowest = nodes[0]
	for node in nodes:
		if node.get_f_cost() < lowest.get_f_cost():
			lowest = node
	return lowest

func _find_in_open_set(open_set: Array[AStarNode], pos: Vector2i) -> AStarNode:
	for node in open_set:
		if node.position == pos:
			return node
	return null
## Calcula todas las casillas alcanzables desde start con max_steps pasos.
## Usa BFS (flood-fill). Respeta paredes y casillas ocupadas.
## Util para mostrar el rango de movimiento en la UI.
func get_reachable_cells(start: Vector2i, max_steps: int) -> Array[Vector2i]:
	var reachable: Array[Vector2i] = []
	var visited: Dictionary = {}
	var queue: Array[Vector2i] = []
	var steps_map: Dictionary = {}
	
	visited[start] = true
	steps_map[start] = 0
	queue.append(start)
	
	while not queue.is_empty():
		var pos = queue.pop_front()
		var steps = steps_map[pos]
		
		if steps > 0:
			reachable.append(pos)
		
		if steps >= max_steps:
			continue
		
		for neighbor in _get_neighbors(pos):
			if visited.has(neighbor):
				continue
			if not GridManager.is_valid_position(neighbor):
				continue
			if not GridManager.is_walkable(neighbor):
				continue
			visited[neighbor] = true
			steps_map[neighbor] = steps + 1
			queue.append(neighbor)
	
	return reachable
	
func _reconstruct_path(end_node: AStarNode) -> Array[Vector2i]:
	var path: Array[Vector2i] = []
	var current = end_node
	
	while current != null:
		path.append(current.position)
		current = current.parent


	path.reverse()
	

	return path
