extends Node
## Test de integracion: Pathfinding + CharacterController

func _ready():
	print("--- INICIO TEST PATHFINDING MOVEMENT ---")
	
	# Crear personaje de prueba
	var char_data = _create_character("test_char", "Explorador", Vector2i(0, 0), 10)
	
	# Crear controller
	var controller = CharacterController.new()
	controller.character_data = char_data
	add_child(controller)
	
	# Conectar senales
	controller.position_changed.connect(_on_position_changed)
	controller.actions_updated.connect(_on_actions_updated)
	controller.path_started.connect(_on_path_started)
	controller.path_completed.connect(_on_path_completed)
	controller.move_blocked.connect(_on_move_blocked)
	
	# Iniciar turno
	controller.start_turn()
	
	# Prueba 1: Mover con ruta larga (no puede llegar en 1 accion)
	print("\n[TEST 1] Mover de (0,0) a (5,5):")
	var target1 = Vector2i(5, 5)
	print("  Puede llegar en 1 accion?: ", controller.can_reach(target1))
	print("  (Esperado: false, porque la distancia es 10 y solo mueve 5)")
	var path1 = controller.calculate_path_to(target1)
	print("  Ruta completa: ", path1.size(), " casillas (", path1.size() - 1, " pasos)")
	controller.move_to(target1)
	print("  Posicion final: ", char_data.grid_position)
	print("  (Deberia estar a mitad de camino hacia el destino)")
	print("  Acciones restantes: ", controller.remaining_actions)
	
	# Prueba 2: Usar la segunda accion para seguir moviendose
	print("\n[TEST 2] Usar segunda accion:")
	controller.move_to(Vector2i(5, 5))
	print("  Posicion final: ", char_data.grid_position)
	print("  Acciones restantes: ", controller.remaining_actions)
	
	# Prueba 3: Intentar mover sin acciones (ahora si, 0 acciones)
	print("\n[TEST 3] Intentar mover sin acciones (0 restantes):")
	controller.move_to(Vector2i(0, 0))
	print("  Posicion (no deberia cambiar): ", char_data.grid_position)
	
		# Prueba 4: Nuevo turno, muro bloqueante real
	print("\n[TEST 4] Mover con muro bloqueante:")
	controller.start_turn()
	
	# Posicion actual (despues del test 3): (5,5)
	# Destino: (0,5) - al otro lado del tablero
	
	# Crear un muro vertical completo que bloquee el paso
	for y in range(GridManager.grid_height):
		var wall_cell = GridManager.get_cell(Vector2i(2, y))
		if wall_cell:
			wall_cell.is_walkable = false
	
	var target4 = Vector2i(0, 5)
	print("  Posicion actual: ", char_data.grid_position)
	print("  Destino: ", target4)
	print("  Hay un muro vertical completo en x=2")
	print("  Puede llegar en 1 accion?: ", controller.can_reach(target4))
	print("  (Esperado: false, porque el muro bloquea completamente)")
	
	var blocked_path = controller.calculate_path_to(target4)
	print("  Ruta encontrada?: ", blocked_path.size(), " casillas")
	
	controller.move_to(target4)
	print("  Posicion final: ", char_data.grid_position)
	print("  (No deberia haberse movido)")
	
	# Limpiar el muro
	for y in range(GridManager.grid_height):
		var wall_cell = GridManager.get_cell(Vector2i(2, y))
		if wall_cell:
			wall_cell.is_walkable = true
	# Prueba 5: Mover hacia un "enemigo" cercano
	print("\n[TEST 5] Mover hacia enemigo cercano (adyacente):")
	controller.start_turn()
	GridManager.set_occupant(Vector2i(3, 0), "enemy_test")
	
	var enemy_pos = Vector2i(3, 0)
	print("  Enemigo en: ", enemy_pos)
	print("  Personaje en: ", char_data.grid_position)
	controller.move_to_adjacent(enemy_pos)
	print("  Posicion final: ", char_data.grid_position)
	var distance = abs(char_data.grid_position.x - enemy_pos.x) + abs(char_data.grid_position.y - enemy_pos.y)
	print("  Distancia al enemigo: ", distance)
	print("  (Deberia ser 1, es decir, adyacente)")
	
	# Limpiar
	GridManager.clear_occupant(Vector2i(3, 0))
	GridManager.get_cell(Vector2i(3, 2)).is_walkable = true
	GridManager.get_cell(Vector2i(3, 3)).is_walkable = true
	GridManager.get_cell(Vector2i(3, 4)).is_walkable = true
	
	print("\n--- FIN TEST PATHFINDING MOVEMENT ---")

func _create_character(char_id: String, char_name: String, pos: Vector2i, hp: int) -> CharacterInstanceData:
	var class_data = CharacterClassData.new()
	class_data.class_id = "test_class"
	class_data.display_name = char_name
	class_data.max_hp = hp
	class_data.movement_range = 5  # Puede mover 5 casillas por accion
	class_data.actions_per_turn = 2
	
	var char_data = CharacterInstanceData.new()
	char_data.character_id = char_id
	char_data.character_name = char_name
	char_data.class_data = class_data
	char_data.current_hp = hp
	char_data.grid_position = pos
	
	return char_data

# --- Senales ---
func _on_position_changed(new_pos: Vector2i):
	print("  [SIGNAL] Posicion cambiada a: ", new_pos)

func _on_actions_updated(remaining: int):
	print("  [SIGNAL] Acciones restantes: ", remaining)

func _on_path_started(path: Array[Vector2i]):
	print("  [SIGNAL] Ruta iniciada (", path.size(), " casillas)")

func _on_path_completed(final_pos: Vector2i):
	print("  [SIGNAL] Ruta completada. Posicion final: ", final_pos)

func _on_move_blocked(reason: String):
	print("  [SIGNAL] Movimiento bloqueado: ", reason)
