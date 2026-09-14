class_name CharacterClassData
extends Resource

## Identificador único para código y red (ej. "warrior", "wizard")
@export var class_id: String = ""

@export_group("Identidad")
## Nombre visible de la clase (ej. "Guerrero", "Mago")
@export var display_name: String = ""
@export var description: String = ""
@export var portrait: Texture2D = null

@export_group("Estadísticas Base")
@export var max_hp: int = 10
@export var base_armor: int = 0
## Casillas que puede moverse por acción de movimiento
@export var movement_range: int = 4
## Acciones disponibles por turno (ej. 2: mover + atacar)
@export var actions_per_turn: int = 2

@export_group("Equipamiento Inicial")
## Lista de armas con las que empieza esta clase
@export var starting_weapons: Array[WeaponData] = []
