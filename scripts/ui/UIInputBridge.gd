extends Node
class_name UIInputBridge

## El jugador hizo clic en una casilla del grid para moverse.
## Solo enviamos la coordenada objetivo. El GridManager validará si es posible.
signal request_move(target_grid_pos: Vector2i)

## El jugador seleccionó un enemigo y pulsó "Atacar".
## Enviamos el ID único del objetivo. El CombatResolver validará rango, LoS y tirará el dado.
signal request_attack(target_entity_id: int)

## El jugador pulsó el botón "Fin de Turno".
signal request_end_turn()

## El jugador hizo clic en un objeto de su inventario para usarlo.
signal request_use_item(item_instance_id: String)

## El jugador abrió/cerró el inventario.
signal request_toggle_inventory()

# ============================================================
# MÉTODOS AUXILIARES (Opcional, para limpiar la UI)
# ============================================================

## Llamado cuando el jugador hace clic en una casilla del grid.
func notify_move_request(grid_pos: Vector2i) -> void:
	request_move.emit(grid_pos)

## Llamado cuando el jugador ataca a un enemigo.
func notify_attack_request(entity_id: int) -> void:
	request_attack.emit(entity_id)

## Llamado cuando el jugador termina su turno.
func notify_end_turn_request() -> void:
	request_end_turn.emit()
