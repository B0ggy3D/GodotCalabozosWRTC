extends Node
## GameState: Autoload que centraliza TODO el estado de la partida.
## Es la fuente de verdad para el host. Los clientes reciben snapshots de este estado.

# --- Senales ---
signal game_initialized(map_id: String)
signal player_joined(player_id: String, character_data: CharacterInstanceData)
signal player_left(player_id: String)
signal enemy_spawned(enemy_id: String, enemy_data: CharacterInstanceData)
signal entity_removed(entity_id: String)
signal game_state_changed(state: Dictionary)

# --- Estados del juego ---
enum GamePhase {
	LOBBY,          # Esperando jugadores
	STARTING,       # Inicializando partida
	PLAYING,        # Partida activa
	PAUSED,         # Pausa
	ENDED           # Partida terminada
}

# --- Configuracion ---
var current_phase: GamePhase = GamePhase.LOBBY
var map_id: String = ""
var random_seed: int = 0

# --- Datos de la partida ---
## Todos los personajes (jugadores y enemigos) por su ID
var all_entities: Dictionary = {}  # String -> CharacterInstanceData

## Solo jugadores humanos
var players: Dictionary = {}  # String (player_id) -> CharacterInstanceData

## Solo enemigos/NPCs
var enemies: Dictionary = {}  # String (enemy_id) -> CharacterInstanceData

## Orden de turnos (IDs de jugadores)
var turn_order: Array[String] = []

func _ready():
	pass

# --- API PUBLICA: GESTION DE PARTIDA ---

## Inicializa una nueva partida
func initialize_game(p_map_id: String, p_seed: int = 0):
	map_id = p_map_id
	random_seed = p_seed
	
	# Configurar la semilla del DiceSystem
	if p_seed > 0:
		DiceSystem.set_seed(p_seed)
	
	# Limpiar estado anterior
	_clear_state()
	
	current_phase = GamePhase.STARTING
	emit_signal("game_initialized", map_id)
	print("[GameState] Partida inicializada. Mapa: ", map_id, ", Semilla: ", p_seed)

## Inicia la partida (despues de que todos los jugadores estan listos)
func start_game():
	if players.is_empty():
		push_warning("[GameState] No hay jugadores para iniciar.")
		return
	
	current_phase = GamePhase.PLAYING
	
	# Configurar el orden de turnos (conversion de Array a Array[String])
	var keys_array: Array[String] = []
	for key in players.keys():
		keys_array.append(key)
	turn_order = keys_array
	
	TurnManager.setup_turn_order(turn_order)
	TurnManager.start_game()
	
	print("[GameState] Partida iniciada con ", players.size(), " jugadores.")

## Termina la partida
func end_game():
	current_phase = GamePhase.ENDED
	print("[GameState] Partida terminada.")

# --- API PUBLICA: GESTION DE ENTIDADES ---

## Registra un jugador y su personaje
func register_player(player_id: String, character_data: CharacterInstanceData):
	players[player_id] = character_data
	all_entities[character_data.character_id] = character_data
	
	# Registrar en el grid
	GridManager.set_occupant(character_data.grid_position, character_data.character_id)
	
	emit_signal("player_joined", player_id, character_data)
	print("[GameState] Jugador registrado: ", player_id, " -> ", character_data.character_name)

## Registra un enemigo/NPC
func register_enemy(enemy_id: String, enemy_data: CharacterInstanceData):
	enemies[enemy_id] = enemy_data
	all_entities[enemy_data.character_id] = enemy_data
	
	# Registrar en el grid
	GridManager.set_occupant(enemy_data.grid_position, enemy_data.character_id)
	
	emit_signal("enemy_spawned", enemy_id, enemy_data)
	print("[GameState] Enemigo registrado: ", enemy_id, " -> ", enemy_data.character_name)

## Elimina una entidad (muerte, salida del jugador, etc.)
func remove_entity(entity_id: String):
	if all_entities.has(entity_id):
		var entity = all_entities[entity_id]
		
		# Liberar casilla del grid
		GridManager.clear_occupant(entity.grid_position)
		
		# Eliminar de todos los diccionarios
		all_entities.erase(entity_id)
		
		# Buscar en jugadores o enemigos
		for player_id in players:
			if players[player_id].character_id == entity_id:
				players.erase(player_id)
				emit_signal("player_left", player_id)
				break
		
		for enemy_id in enemies:
			if enemies[enemy_id].character_id == entity_id:
				enemies.erase(enemy_id)
				break
		
		emit_signal("entity_removed", entity_id)

## Obtiene una entidad por su ID
func get_entity(entity_id: String) -> CharacterInstanceData:
	if all_entities.has(entity_id):
		return all_entities[entity_id]
	return null

## Obtiene el personaje de un jugador especifico
func get_player_character(player_id: String) -> CharacterInstanceData:
	if players.has(player_id):
		return players[player_id]
	return null

# --- API PUBLICA: SNAPSHOT PARA RED ---

## Genera un snapshot del estado actual para enviar a clientes
## La Persona 2 (WebRTC) usara esto para sincronizar
func get_state_snapshot() -> Dictionary:
	var snapshot: Dictionary = {
		"phase": current_phase,
		"map_id": map_id,
		"random_seed": random_seed,
		"current_round": TurnManager.current_round,
		"current_player_id": TurnManager.get_current_player_id(),
		"entities": {}
	}
	
	# Serializar entidades
	for entity_id in all_entities:
		var entity = all_entities[entity_id]
		snapshot.entities[entity_id] = {
			"character_id": entity.character_id,
			"character_name": entity.character_name,
			"current_hp": entity.current_hp,
			"grid_position": entity.grid_position,
			"current_actions": entity.current_actions
		}
	
	return snapshot

## Aplica un snapshot recibido del host (solo clientes)
func apply_state_snapshot(snapshot: Dictionary):
	# Esta funcion sera usada por los clientes para actualizar su estado local
	# basandose en lo que el host les envia
	current_phase = snapshot.phase
	map_id = snapshot.map_id
	
	for entity_id in snapshot.entities:
		var entity_data = snapshot.entities[entity_id]
		if all_entities.has(entity_id):
			all_entities[entity_id].current_hp = entity_data.current_hp
			all_entities[entity_id].grid_position = entity_data.grid_position
			all_entities[entity_id].current_actions = entity_data.current_actions
	
	emit_signal("game_state_changed", snapshot)

# --- LOGICA INTERNA ---

func _clear_state():
	all_entities.clear()
	players.clear()
	enemies.clear()
	turn_order.clear()
