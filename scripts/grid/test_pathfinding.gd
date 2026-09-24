extends Node

func _ready():
	print("--- INICIO TEST PATHFINDING ---")
	
	# Conectar senales
	Pathfinding.path_found.connect(func(s, e, p): print("  [SIGNAL] Ruta encontrada: ", p.size(), " pasos"))
	Pathfinding.no_path_found.connect(func(s, e): print("  [SIGNAL] Sin ruta de ", s, " a ", e))
	
	# Prueba 1: Ruta simple en grid abierto
	print("\n[TEST 1] Ruta simple (0,0) -> (5,5):")
	var path1 = Pathfinding.find_path(Vector2i(0, 0), Vector2i(5, 5))
	print("  Pasos: ", Pathfinding.get_path_length(path1))
	print("  Ruta: ", path1)
	
	# Prueba 2: Ruta con obstaculos
	print("\n[TEST 2] Ruta con obstaculos:")
	# Bloquear algunas casillas simulando paredes
	GridManager.get_cell(Vector2i(2, 0)).is_walkable = false
	GridManager.get_cell(Vector2i(2, 1)).is_walkable = false
	GridManager.get_cell(Vector2i(2, 2)).is_walkable = false
	
	var path2 = Pathfinding.find_path(Vector2i(0, 0), Vector2i(4, 0))
	if path2.is_empty():
		print("  No se encontro ruta (esperado si el muro bloquea todo)")
	else:
		print("  Ruta encontrada rodeando el muro: ", path2)
		print("  Pasos: ", Pathfinding.get_path_length(path2))
	
	# Prueba 3: Ruta a casilla adyacente a un enemigo
	print("\n[TEST 3] Ruta hacia enemigo (casilla ocupada):")
	# Limpiar obstaculos anteriores
	GridManager.get_cell(Vector2i(2, 0)).is_walkable = true
	GridManager.get_cell(Vector2i(2, 1)).is_walkable = true
	GridManager.get_cell(Vector2i(2, 2)).is_walkable = true
	
	# Simular un enemigo en (5, 3)
	GridManager.set_occupant(Vector2i(5, 3), "enemy_test")
	
	var path3 = Pathfinding.find_path_to_adjacent(Vector2i(0, 0), Vector2i(5, 3))
	if path3.is_empty():
		print("  No se encontro ruta adyacente")
	else:
		print("  Ruta hacia casilla adyacente al enemigo: ", path3)
		print("  Casilla final: ", path3[-1])
		print("  Pasos: ", Pathfinding.get_path_length(path3))
	
	# Prueba 4: Sin ruta posible (rodeado)
	print("\n[TEST 4] Sin ruta posible:")
	# Rodear una casilla completamente
	var surround_pos = Vector2i(7, 7)
	for neighbor in [
		surround_pos + Vector2i(1, 0),
		surround_pos + Vector2i(-1, 0),
		surround_pos + Vector2i(0, 1),
		surround_pos + Vector2i(0, -1)
	]:
		if GridManager.is_valid_position(neighbor):
			GridManager.get_cell(neighbor).is_walkable = false
	
	var path4 = Pathfinding.find_path(Vector2i(0, 0), surround_pos)
	if path4.is_empty():
		print("  Correctamente no se encontro ruta")
	else:
		print("  ERROR: Se encontro ruta inesperada")
	
	# Limpiar
	GridManager.clear_occupant(Vector2i(5, 3))
	
	print("\n--- FIN TEST PATHFINDING ---")
