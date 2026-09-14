extends Node

func _ready():
	print("--- INICIO TEST TURN MANAGER ---")
	
	# Conectar senales
	TurnManager.turn_started.connect(_on_turn_started)
	TurnManager.turn_ended.connect(_on_turn_ended)
	TurnManager.round_started.connect(_on_round_started)
	
	# Simular 2 jugadores (como si vinieran de la red)
	var players: Array[String] = ["player_1", "player_2"]
	TurnManager.setup_turn_order(players)
	
	# Iniciar la partida
	TurnManager.start_game()
	
	# Simular que player_1 termina su turno
	print("player_1 termina su turno...")
	TurnManager.end_current_turn()
	
	# Verificar de quien es el turno ahora
	print("Es turno de player_1?: ", TurnManager.is_player_turn("player_1"))
	print("Es turno de player_2?: ", TurnManager.is_player_turn("player_2"))
	
	# Simular que player_2 termina su turno
	print("player_2 termina su turno...")
	TurnManager.end_current_turn()
	
	print("--- FIN TEST TURN MANAGER ---")

func _on_turn_started(player_id: String):
	print("  [SIGNAL] Turno iniciado para: ", player_id)

func _on_turn_ended(player_id: String):
	print("  [SIGNAL] Turno terminado para: ", player_id)

func _on_round_started(round_number: int):
	print("  [SIGNAL] Ronda ", round_number, " iniciada")
