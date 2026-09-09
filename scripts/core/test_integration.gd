extends Node
## Test de integracion: Simula un turno completo de juego
## combinando todos los sistemas de Persona 1.

func _ready():
	print("========================================")
	print("  TEST DE INTEGRACION COMPLETA")
	print("========================================")
	
	# Conectar senales para observar el flujo
	_connect_signals()
	
	# Paso 1: Inicializar partida
	print("\n--- PASO 1: Inicializar Partida ---")
	GameState.initialize_game("dungeon_test_01", 999)
	
	# Paso 2: Crear y registrar jugadores
	print("\n--- PASO 2: Registrar Jugadores ---")
	var player1 = _create_player("p1", "Guerrero", Vector2i(0, 1), 12)
	var player2 = _create_player("p2", "Mago", Vector2i(5, 1), 8)
	
	GameState.register_player("net_player_1", player1)
	GameState.register_player("net_player_2", player2)
	
	# Paso 3: Crear y registrar enemigo (a 3 casillas del jugador 1)
	print("\n--- PASO 3: Registrar Enemigo ---")
	var enemy = _create_enemy("goblin_1", "Goblin", Vector2i(3, 1), 6)
	GameState.register_enemy("goblin_1", enemy)
	
	# Paso 4: Iniciar partida
	print("\n--- PASO 4: Iniciar Partida ---")
	GameState.start_game()
	
	# Paso 5: Simular el turno del jugador 1
	print("\n--- PASO 5: Turno del Jugador 1 ---")
	_simulate_player_turn("net_player_1")
	
	# Paso 6: Verificar estado final
	print("\n--- PASO 6: Estado Final ---")
	_print_final_state()
	
	print("\n========================================")
	print("  TEST DE INTEGRACION COMPLETADO")
	print("========================================")

func _simulate_player_turn(player_id: String):
	var character = GameState.get_player_character(player_id)
	if character == null:
		print("  ERROR: Personaje no encontrado para ", player_id)
		return
	
	print("  Turno de: ", character.character_name)
	print("  Posicion actual: ", character.grid_position)
	print("  Acciones disponibles: ", character.class_data.actions_per_turn)
	
	# Crear un CharacterController para este personaje
	var controller = CharacterController.new()
	controller.character_data = character
	add_child(controller)
	controller.start_turn()
	
	# Accion 1: Mover hacia el enemigo (acercarse, no pisar)
	print("\n  [Accion 1] Mover hacia el enemigo...")
	var enemy_pos = GameState.get_entity("goblin_1").grid_position
	var move_dir = _get_direction_towards(character.grid_position, enemy_pos)
	var target_pos = character.grid_position + move_dir
	
	# Verificar si el destino esta ocupado (no moverse si el enemigo esta ahi)
	if GridManager.is_walkable(target_pos):
		var moved = controller.try_move(move_dir)
		print("    Movimiento exitoso: ", moved)
		print("    Nueva posicion: ", character.grid_position)
	else:
		print("    Destino ocupado, no es necesario moverse.")
	
	# Accion 2: Atacar al enemigo si esta en rango
	print("\n  [Accion 2] Atacar al enemigo...")
	var enemy_data = GameState.get_entity("goblin_1")
	
	if enemy_data == null:
		print("    Enemigo ya no existe.")
		TurnManager.end_current_turn()
		controller.queue_free()
		return
	
	var can_attack = CombatSystem.can_attack(character, enemy_data)
	
	if can_attack:
		print("    Enemigo en rango. Atacando...")
		var result = CombatSystem.resolve_attack(character, enemy_data)
		
		if result.success:
			print("    Tirada: ", result.dice_result.total)
			print("    Resultado: ", DiceSystem.result_to_string(result.dice_result.result_type))
			print("    Dano: ", result.damage_dealt)
			print("    HP enemigo: ", result.target_remaining_hp)
			
			if result.target_died:
				print("    *** ENEMIGO ELIMINADO ***")
				GameState.remove_entity("goblin_1")
		else:
			print("    Error: ", result.validation_error)
	else:
		print("    Enemigo fuera de rango. Distancia: ", _manhattan_distance(character.grid_position, enemy_data.grid_position))
	
	# Fin del turno
	print("\n  [Fin del Turno]")
	TurnManager.end_current_turn()
	
	# Limpiar controller temporal
	controller.queue_free()

func _get_direction_towards(from: Vector2i, to: Vector2i) -> Vector2i:
	var diff = to - from
	if abs(diff.x) >= abs(diff.y):
		return Vector2i(sign(diff.x), 0)
	else:
		return Vector2i(0, sign(diff.y))

func _manhattan_distance(a: Vector2i, b: Vector2i) -> int:
	return abs(a.x - b.x) + abs(a.y - b.y)

func _create_player(player_id: String, char_name: String, pos: Vector2i, hp: int) -> CharacterInstanceData:
	var weapon = WeaponData.new()
	weapon.id = "sword_basic"
	weapon.weapon_name = "Espada"
	weapon.dice_count = 1
	weapon.dice_sides = 8
	weapon.damage_bonus = 2
	weapon.attack_range = 1
	weapon.critical_multiplier = 2.0
	
	var class_data = CharacterClassData.new()
	class_data.class_id = player_id + "_class"
	class_data.display_name = char_name
	class_data.max_hp = hp
	class_data.actions_per_turn = 2
	
	var char_data = CharacterInstanceData.new()
	char_data.character_id = player_id
	char_data.character_name = char_name
	char_data.class_data = class_data
	char_data.current_hp = hp
	char_data.grid_position = pos
	char_data.equipped_weapon = weapon
	
	return char_data

func _create_enemy(enemy_id: String, char_name: String, pos: Vector2i, hp: int) -> CharacterInstanceData:
	var class_data = CharacterClassData.new()
	class_data.class_id = "enemy_class"
	class_data.display_name = char_name
	class_data.max_hp = hp
	
	var char_data = CharacterInstanceData.new()
	char_data.character_id = enemy_id
	char_data.character_name = char_name
	char_data.class_data = class_data
	char_data.current_hp = hp
	char_data.grid_position = pos
	
	return char_data

func _print_final_state():
	var snapshot = GameState.get_state_snapshot()
	print("  Fase actual: ", snapshot.phase)
	print("  Mapa: ", snapshot.map_id)
	print("  Ronda: ", snapshot.current_round)
	print("  Turno actual: ", snapshot.current_player_id)
	print("  Entidades vivas: ", snapshot.entities.size())
	for entity_id in snapshot.entities:
		var e = snapshot.entities[entity_id]
		print("    - ", e.character_name, " (HP: ", e.current_hp, ", Pos: ", e.grid_position, ")")

func _connect_signals():
	GameState.player_joined.connect(func(pid, data): print("  [GS] Jugador unido: ", pid))
	GameState.enemy_spawned.connect(func(eid, data): print("  [GS] Enemigo aparecio: ", eid))
	GameState.entity_removed.connect(func(eid): print("  [GS] Entidad eliminada: ", eid))
	
	CombatSystem.combat_resolved.connect(func(result): pass)
	CombatSystem.damage_applied.connect(func(tid, dmg, hp): print("  [COMBAT] Dano a ", tid, ": ", dmg))
	CombatSystem.entity_died.connect(func(eid): print("  [COMBAT] *** ", eid, " MURIO ***"))
	
	TurnManager.turn_started.connect(func(pid): print("  [TURN] Turno de: ", pid))
	TurnManager.round_started.connect(func(r): print("  [TURN] === RONDA ", r, " ==="))
