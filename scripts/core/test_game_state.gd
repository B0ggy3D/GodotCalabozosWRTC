extends Node

func _ready():
	print("--- INICIO TEST GAME STATE ---")
	
	# Conectar senales
	GameState.player_joined.connect(_on_player_joined)
	GameState.enemy_spawned.connect(_on_enemy_spawned)
	GameState.entity_removed.connect(_on_entity_removed)
	
	# Prueba 1: Inicializar partida
	print("\n[TEST 1] Inicializar partida:")
	GameState.initialize_game("dungeon_01", 42)
	
	# Prueba 2: Registrar jugadores
	print("\n[TEST 2] Registrar jugadores:")
	var player1_char = _create_test_character("player_1", "Guerrero", Vector2i(1, 1))
	var player2_char = _create_test_character("player_2", "Mago", Vector2i(3, 3))
	
	GameState.register_player("network_id_1", player1_char)
	GameState.register_player("network_id_2", player2_char)
	
	# Prueba 3: Registrar enemigo
	print("\n[TEST 3] Registrar enemigo:")
	var enemy_char = _create_test_character("enemy_1", "Goblin", Vector2i(5, 5))
	GameState.register_enemy("enemy_1", enemy_char)
	
	# Prueba 4: Verificar snapshot
	print("\n[TEST 4] Snapshot del estado:")
	var snapshot = GameState.get_state_snapshot()
	print("  Fase: ", snapshot.phase)
	print("  Mapa: ", snapshot.map_id)
	print("  Entidades registradas: ", snapshot.entities.size())
	for entity_id in snapshot.entities:
		var e = snapshot.entities[entity_id]
		print("    - ", entity_id, " en posicion ", e.grid_position)
	
	# Prueba 5: Iniciar partida
	print("\n[TEST 5] Iniciar partida:")
	GameState.start_game()
	print("  Turno actual: ", TurnManager.get_current_player_id())
	
	# Prueba 6: Eliminar entidad
	print("\n[TEST 6] Eliminar enemigo:")
	GameState.remove_entity("enemy_1")
	print("  Entidades restantes: ", GameState.all_entities.size())
	
	print("\n--- FIN TEST GAME STATE ---")

func _create_test_character(char_id: String, char_name: String, pos: Vector2i) -> CharacterInstanceData:
	var char_data = CharacterInstanceData.new()
	char_data.character_id = char_id
	char_data.character_name = char_name
	char_data.current_hp = 10
	char_data.grid_position = pos
	
	var class_data = CharacterClassData.new()
	class_data.class_id = "test_class"
	class_data.display_name = char_name
	class_data.actions_per_turn = 2
	char_data.class_data = class_data
	
	return char_data

func _on_player_joined(player_id: String, character_data: CharacterInstanceData):
	print("  [SIGNAL] Jugador unido: ", player_id, " como ", character_data.character_name)

func _on_enemy_spawned(enemy_id: String, enemy_data: CharacterInstanceData):
	print("  [SIGNAL] Enemigo aparecio: ", enemy_id, " como ", enemy_data.character_name)

func _on_entity_removed(entity_id: String):
	print("  [SIGNAL] Entidad eliminada: ", entity_id)
