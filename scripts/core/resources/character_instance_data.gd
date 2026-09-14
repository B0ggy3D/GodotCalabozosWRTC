class_name CharacterInstanceData
extends Resource

@export var character_id: String = "" # Ej: "player_1_char"
@export var owner_player_id: String = "" # ID de red del jugador que lo controla
@export var character_name: String = "Héroe"

## La clase define las estadísticas base
@export var class_data: CharacterClassData = null

## Estado dinámico (se modifica durante la partida)
@export var current_hp: int = 10
@export var current_actions: int = 2
@export var grid_position: Vector2i = Vector2i(0, 0) # Posición lógica en el tablero

## Inventario y equipo actual
@export var equipped_weapon: WeaponData = null
# (El inventario completo se manejará en un sistema separado más adelante)
