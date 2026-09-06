extends Node

func _ready():
	# El GridManager (Autoload) ya esta listo antes de que este nodo arranque
	# Asi que podemos probar directamente
	print("--- INICIO TEST GRID ---")
	
	# Prueba 1: Conversion de coordenadas
	var world_pos = Vector2(150, 200)
	var grid_pos = GridManager.world_to_grid(world_pos)
	print("Mundo: ", world_pos, " -> Grid: ", grid_pos)
	
	# Prueba 2: Centro visual de una casilla
	var center = GridManager.grid_to_world(Vector2i(2, 3))
	print("Centro de casilla (2,3): ", center)
	
	# Prueba 3: Validacion de movimiento
	print("(0,0) es caminable?: ", GridManager.is_walkable(Vector2i(0, 0)))
	
	# Prueba 4: Ocupar casilla
	GridManager.set_occupant(Vector2i(0, 0), "player_1")
	print("(0,0) sigue siendo caminable?: ", GridManager.is_walkable(Vector2i(0, 0)))
	
	# Prueba 5: Posicion invalida (fuera del tablero)
	print("(99,99) es valida?: ", GridManager.is_valid_position(Vector2i(99, 99)))
	
	print("--- FIN TEST GRID ---")
