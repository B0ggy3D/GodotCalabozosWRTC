class_name AbilityData
extends Resource

## Recurso base para habilidades y hechizos.
## Data-driven: se modifica sin tocar codigo.

# --- Tipos de habilidad ---
enum AbilityType {
	MELEE_ATTACK,      # Ataque cuerpo a cuerpo
	RANGED_ATTACK,     # Ataque a distancia
	SPELL_DAMAGE,      # Hechizo de dano
	SPELL_HEAL,        # Hechizo de curacion
	SPELL_BUFF,        # Hechizo de buff
	SPELL_DEBUFF,      # Hechizo de debuff
	SPECIAL            # Habilidad especial unica
}

# --- Tipos de objetivo ---
enum TargetType {
	SINGLE_ENEMY,      # Un solo enemigo
	SINGLE_ALLY,       # Un solo aliado
	SELF,              # A si mismo
	AOE_ENEMIES,       # Area de efecto (enemigos)
	AOE_ALLIES,        # Area de efecto (aliados)
	ALL_ENEMIES,       # Todos los enemigos
	ALL_ALLIES         # Todos los aliados
}

@export_group("Identidad")
@export var id: String = ""
@export var ability_name: String = ""
@export var description: String = ""
@export var icon: Texture2D = null

@export_group("Clasificacion")
@export var ability_type: AbilityType = AbilityType.MELEE_ATTACK
@export var target_type: TargetType = TargetType.SINGLE_ENEMY

@export_group("Costos y Limitaciones")
## Costo en acciones por turno (1 = usa una accion, 2 = usa el turno completo)
@export var action_cost: int = 1
## Rango en casillas del grid
@export var range_tiles: int = 1
## Radio de area de efecto (0 = solo objetivo, 1 = 3x3, 2 = 5x5)
@export var aoe_radius: int = 0
## Usos por combate (0 = ilimitado)
@export var uses_per_combat: int = 0
## Enfriamiento en turnos (0 = sin cooldown)
@export var cooldown_turns: int = 0

@export_group("Dano / Curacion")
## Dados de dano/curacion (ej: 2d6)
@export var dice_count: int = 1
@export var dice_sides: int = 6
## Modificador fijo
@export var modifier: int = 0
## Multiplicador en critico
@export var critical_multiplier: float = 2.0
## Bonus al roll de ataque (para superar defensa)
@export var attack_bonus: int = 0

@export_group("Efectos Secundarios")
## Probabilidad de aplicar un status effect (0.0 a 1.0)
@export var status_chance: float = 0.0
## Tipo de status a aplicar (placeholder por ahora)
@export var status_effect_id: String = ""
## Duracion del status en turnos
@export var status_duration: int = 0

@export_group("Requisitos")
## Nivel minimo para usar la habilidad
@export var required_level: int = 1
## Clases que pueden usar esta habilidad (vacio = todas)
@export var allowed_classes: Array[String] = []
