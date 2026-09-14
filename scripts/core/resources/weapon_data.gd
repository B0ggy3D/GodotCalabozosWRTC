class_name WeaponData
extends Resource

## Identificador único para referencias en código o red (ej. "basic_sword")
@export var id: String = ""

@export_group("Propiedades Básicas")
@export var weapon_name: String = ""
@export var description: String = ""
@export var icon: Texture2D = null # Se usará placeholder por ahora

@export_group("Estadísticas de Combate")
## Cantidad de dados a lanzar (ej. 1 para 1d6)
@export var dice_count: int = 1
## Caras del dado (ej. 6 para 1d6, 8 para 1d8)
@export var dice_sides: int = 6
## Modificador fijo al daño (ej. +2 por fuerza)
@export var damage_bonus: int = 0
## Alcance en casillas del grid (1 = adyacente, 2 = una casilla de distancia, etc.)
@export var attack_range: int = 1
## Multiplicador de daño en caso de crítico (ej. 1.5 o 2.0)
@export var critical_multiplier: float = 2.0
