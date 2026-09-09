extends Node

func _ready():
	print("--- INICIO TEST CHARACTER ---")
	
	# Crear datos de prueba manualmente (simulando un recurso .tres)
	var weapon = WeaponData.new()
	weapon.id = "test_sword"
	weapon.weapon_name = "Espada de Test"
	
	var char_class = CharacterClassData.new()
	char_class.class_id = "warrior"
	char_class.display_name = "Guerrero"
	char_class.max_hp = 12
	char_class.movement_range = 4
	char_class.actions_per_turn = 2
	
	# Asignacion correcta de Array tipado
	var weapons_array: Array[WeaponData] = []
	weapons_array.append(weapon)
	char_class.starting_weapons = weapons_array
	
	var char_data = CharacterInstanceData.new()
	char_data.character_id = "player_1"
	char_data.character_name = "Heroe de Prueba"
	char_data.class_data = char_class
	char_data.current_hp = 12
	char_data.grid_position = Vector2i(0, 0)
	
	# Crear el controlador
	var controller = CharacterController.new()
	controller.character_data = char_data
	add_child(controller)
	
	# Conectar senales para ver que pasa
	controller.position_changed.connect(_on_position_changed)
	controller.actions_updated.connect(_on_actions_updated)
	controller.action_performed.connect(_on_action_performed)
	
	# Iniciar turno
	controller.start_turn()
	
	# Prueba 1: Mover a la derecha (deberia funcionar)
	print("Intentando mover derecha...")
	controller.try_move(Vector2i(1, 0))
	
	# Prueba 2: Mover abajo (deberia funcionar)
	print("Intentando mover abajo...")
	controller.try_move(Vector2i(0, 1))
	
	# Prueba 3: Mover de nuevo (NO deberia funcionar, sin acciones)
	print("Intentando mover sin acciones...")
	controller.try_move(Vector2i(1, 0))
	
	# Prueba 4: Verificar posicion final
	print("Posicion final en grid: ", char_data.grid_position)
	print("Posicion final en mundo: ", controller.get_world_position())
	
	print("--- FIN TEST CHARACTER ---")

func _on_position_changed(new_pos: Vector2i):
	print("  [SIGNAL] Posicion cambiada a: ", new_pos)

func _on_actions_updated(remaining: int):
	print("  [SIGNAL] Acciones restantes: ", remaining)

func _on_action_performed(action_type: String, result: bool):
	print("  [SIGNAL] Accion '", action_type, "' resultado: ", result)
