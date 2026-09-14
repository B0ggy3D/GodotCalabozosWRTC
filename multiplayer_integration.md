# Integración Multiplayer — Guía para Persona 2

## Autoloads disponibles para usar

### GameState (fuente de verdad)
- `GameState.get_state_snapshot() -> Dictionary` — Genera snapshot para enviar a clientes
- `GameState.apply_state_snapshot(snapshot: Dictionary)` — Aplica snapshot (solo clientes)
- `GameState.register_player(player_id, character_data)` — Registrar jugador
- `GameState.get_player_character(player_id) -> CharacterInstanceData` — Obtener personaje

### TurnManager (autoridad del host)
- `TurnManager.setup_turn_order(player_ids: Array[String])` — Configurar orden
- `TurnManager.start_game()` — Iniciar turnos
- `TurnManager.end_current_turn()` — Terminar turno actual
- `TurnManager.get_current_player_id() -> String` — Quién tiene el turno

### CombatSystem (solo el HOST ejecuta)
- `CombatSystem.resolve_attack(attacker, target) -> Dictionary` — Resolver ataque
- `CombatSystem.can_attack(attacker, target) -> bool` — Validar si puede atacar

### DiceSystem (solo el HOST tira)
- `DiceSystem.roll_attack(bonus, crit_chance) -> Dictionary` — Tirada de ataque
- `DiceSystem.set_seed(value)` / `DiceSystem.clear_seed()` — Control de semilla

## Flujo de red esperado

### Host (autoridad):
1. Recibe solicitud de acción del cliente (ej: "quiero moverme")
2. Valida con `GridManager.is_walkable()`
3. Ejecuta la acción (mueve, ataca, etc.)
4. Actualiza `GameState`
5. Genera `GameState.get_state_snapshot()`
6. Envía snapshot a todos los clientes

### Cliente:
1. Envía solicitud al host (ej: "quiero moverme a X")
2. Espera respuesta del host
3. Recibe snapshot
4. Aplica `GameState.apply_state_snapshot(snapshot)`
5. Actualiza UI/visual basado en señales

## Datos a sincronizar
El snapshot contiene:
- `phase`: Estado del juego (LOBBY, PLAYING, ENDED)
- `map_id`: Mapa actual
- `current_round`: Ronda actual
- `current_player_id`: Quién tiene el turno
- `entities`: Dictionary con todos los personajes y su estado

## Señales a escuchar para UI
- `GameState.player_joined` — Un jugador se conectó
- `GameState.entity_removed` — Alguien murió o salió
- `CombatSystem.damage_applied` — Se aplicó daño
- `CombatSystem.entity_died` — Alguien murió
- `TurnManager.turn_started` — Cambió el turno
