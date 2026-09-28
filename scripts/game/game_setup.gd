extends Node2D
## GameSetup: Configura una partida de prueba con datos locales.
## Simula lo que haria el NetworkManager al conectar jugadores.

@onready var flow_controller = $GameFlowController

func _ready():
	print("========================================")
	print("  INICIANDO PARTIDA LOCAL (SIN RED)")
	print("========================================")
	
	# Paso 1: Inicializar el GameState
	GameState.initialize_game("dungeon_demo_01", 0)
	
	# Paso 2: Crear jugador 1 (Guerrero)
	var weapon = WeaponData.new()
	weapon.id = "iron_sword"
	weapon.weapon_name = "Espada de Hierro"
	weapon.dice_count = 1
	weapon.dice_sides = 8
	weapon.damage_bonus = 2
	weapon.attack_range = 1
	weapon.critical_multiplier = 2.0
	
	var warrior_class = CharacterClassData.new()
	warrior_class.class_id = "warrior"
	warrior_class.display_name = "Guerrero"
	warrior_class.max_hp = 15
	warrior_class.base_armor = 2
	warrior_class.movement_range = 4
	warrior_class.actions_per_turn = 2
	
	var player1 = CharacterInstanceData.new()
	player1.character_id = "p1"
	player1.owner_player_id = "net_player_1"
	player1.character_name = "Guerrero"
	player1.class_data = warrior_class
	player1.current_hp = 15
	player1.current_actions = 2
	player1.grid_position = Vector2i(2, 4)
	player1.equipped_weapon = weapon
	
	GameState.register_player("net_player_1", player1)
	
	# Paso 3: Crear jugador 2 (Mago) - controlado por otro jugador o IA simple
	var mage_class = CharacterClassData.new()
	mage_class.class_id = "mage"
	mage_class.display_name = "Mago"
	mage_class.max_hp = 10
	mage_class.base_armor = 0
	mage_class.movement_range = 3
	mage_class.actions_per_turn = 2
	
	var player2 = CharacterInstanceData.new()
	player2.character_id = "p2"
	player2.owner_player_id = "net_player_2"
	player2.character_name = "Mago"
	player2.class_data = mage_class
	player2.current_hp = 10
	player2.current_actions = 2
	player2.grid_position = Vector2i(7, 4)
	
	GameState.register_player("net_player_2", player2)
	
	# Paso 4: Crear enemigo (Goblin)
	var goblin_class = CharacterClassData.new()
	goblin_class.class_id = "goblin"
	goblin_class.display_name = "Goblin"
	goblin_class.max_hp = 8
	goblin_class.base_armor = 1
	goblin_class.movement_range = 3
	goblin_class.actions_per_turn = 1
	
	var goblin = CharacterInstanceData.new()
	goblin.character_id = "goblin_1"
	goblin.character_name = "Goblin"
	goblin.class_data = goblin_class
	goblin.current_hp = 8
	goblin.current_actions = 1
	goblin.grid_position = Vector2i(5, 4)
	
	GameState.register_enemy("goblin_1", goblin)
	
	# Paso 5: Crear algunas paredes en el mapa
	_create_walls()
	
	# Paso 5.5: Reconstruir el tablero visual para reflejar las paredes
	var board = get_node_or_null("GameBoardVisual")
	if board and board.has_method("rebuild_board"):
		board.rebuild_board()
	
	# Paso 6: Configurar el controlador de flujo (crea sprites y conecta UI)
	flow_controller.setup_game()
	
	# Paso 7: Iniciar la partida
	GameState.start_game()
	
	# Paso 8: Esperar un frame para asegurar que el HUD este listo,
	# y luego actualizar todos los paneles con datos reales
	await get_tree().process_frame
	flow_controller._update_hud_character_stats()
	flow_controller._update_turn_info_safe("Guerrero", true)
	flow_controller._update_actions_safe(2, 2)
	
	print("========================================")
	print("  PARTIDA LISTA")
	print("  Controles:")
	print("  - Clic en casilla vacia = Mover")
	print("  - Clic en enemigo = Atacar")
	print("  - Enter/Espacio = Terminar turno")
	print("========================================")

func _create_walls():
	## Crea un pequeno dungeon con paredes
	var wall_positions = [
		# Paredes horizontales superiores
		Vector2i(0, 0), Vector2i(1, 0), Vector2i(2, 0), Vector2i(3, 0),
		Vector2i(4, 0), Vector2i(5, 0), Vector2i(6, 0), Vector2i(7, 0),
		Vector2i(8, 0), Vector2i(9, 0),
		# Paredes horizontales inferiores
		Vector2i(0, 9), Vector2i(1, 9), Vector2i(2, 9), Vector2i(3, 9),
		Vector2i(4, 9), Vector2i(5, 9), Vector2i(6, 9), Vector2i(7, 9),
		Vector2i(8, 9), Vector2i(9, 9),
		# Paredes verticales izquierdas
		Vector2i(0, 1), Vector2i(0, 2), Vector2i(0, 3), Vector2i(0, 4),
		Vector2i(0, 5), Vector2i(0, 6), Vector2i(0, 7), Vector2i(0, 8),
		# Paredes verticales derechas
		Vector2i(9, 1), Vector2i(9, 2), Vector2i(9, 3), Vector2i(9, 4),
		Vector2i(9, 5), Vector2i(9, 6), Vector2i(9, 7), Vector2i(9, 8),
		# Paredes internas (obstaculos)
		Vector2i(4, 2), Vector2i(4, 3),
		Vector2i(6, 6), Vector2i(6, 7),
	]
	
	for pos in wall_positions:
		var cell = GridManager.get_cell(pos)
		if cell:
			cell.is_walkable = false
			cell.blocks_vision = true
	
	print("[GameSetup] %d paredes creadas." % wall_positions.size())
