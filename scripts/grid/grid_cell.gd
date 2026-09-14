class_name GridCell
extends RefCounted

## Posición lógica en el tablero (ej. X=5, Y=3)
var position: Vector2i = Vector2i.ZERO

## Propiedades lógicas de la casilla
var is_walkable: bool = true
var blocks_vision: bool = false

## ID del jugador/enemidad que ocupa esta casilla. 
## Vacío ("") significa que está libre.
var occupant_id: String = ""

func _init(p_position: Vector2i = Vector2i.ZERO):
	position = p_position

func is_occupied() -> bool:
	return not occupant_id.is_empty()
