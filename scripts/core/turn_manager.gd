extends Node
## TurnManager: Autoload que gestiona el flujo de turnos.
## En multijugador, el HOST es la autoridad absoluta de este sistema.

# --- Senales ---
signal turn_started(player_id: String)
signal turn_ended(player_id: String)
signal round_started(round_number: int)
signal turn_order_changed(new_order: Array[String])

# --- Estados del turno ---
enum TurnPhase {
	WAITING,        # Esperando jugadores o inicio de partida
	ROUND_START,    # Inicio de una nueva ronda
	TURN_ACTIVE,    # Un jugador tiene el turno activo
	TURN_ENDING,    # El jugador termino sus acciones
	ROUND_END       # Todos los jugadores terminaron
}

# --- Configuracion ---
@export var players_per_round: Array[String] = []

# --- Estado actual ---
var current_phase: TurnPhase = TurnPhase.WAITING
var current_round: int = 0
var current_player_index: int = 0
var current_player_id: String = ""

func _ready():
	# Por ahora no hacemos nada hasta que se registre un jugador
	pass

# --- API PUBLICA ---

## Registra el orden de jugadores (lo llama el Host/NetworkManager)
func setup_turn_order(player_ids: Array[String]):
	players_per_round = player_ids.duplicate()
	emit_signal("turn_order_changed", players_per_round)
	print("[TurnManager] Orden de turnos: ", players_per_round)

## Inicia la partida (primera ronda)
func start_game():
	if players_per_round.is_empty():
		push_warning("[TurnManager] No hay jugadores registrados.")
		return
	
	current_round = 0
	_start_new_round()

## El jugador actual termina su turno manualmente
func end_current_turn():
	if current_phase != TurnPhase.TURN_ACTIVE:
		return
	
	current_phase = TurnPhase.TURN_ENDING
	emit_signal("turn_ended", current_player_id)
	
	# Avanzar al siguiente jugador
	_advance_to_next_player()

## Obtiene el jugador actual
func get_current_player_id() -> String:
	return current_player_id

## Verifica si es el turno de un jugador especifico
func is_player_turn(player_id: String) -> bool:
	return current_player_id == player_id and current_phase == TurnPhase.TURN_ACTIVE

## Obtiene la fase actual
func get_phase() -> TurnPhase:
	return current_phase

# --- LOGICA INTERNA ---

func _start_new_round():
	current_round += 1
	current_player_index = 0
	current_phase = TurnPhase.ROUND_START
	
	emit_signal("round_started", current_round)
	print("[TurnManager] === RONDA ", current_round, " ===")
	
	# Iniciar el turno del primer jugador
	_start_player_turn()

func _start_player_turn():
	if players_per_round.is_empty():
		return
	
	current_phase = TurnPhase.TURN_ACTIVE
	current_player_id = players_per_round[current_player_index]
	
	print("[TurnManager] Turno de: ", current_player_id)
	emit_signal("turn_started", current_player_id)

func _advance_to_next_player():
	current_player_index += 1
	
	if current_player_index >= players_per_round.size():
		# Todos los jugadores terminaron, nueva ronda
		current_phase = TurnPhase.ROUND_END
		print("[TurnManager] Ronda completada.")
		_start_new_round()
	else:
		# Siguiente jugador
		_start_player_turn()
