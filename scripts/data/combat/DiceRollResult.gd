class_name DiceRollResult
extends Resource

# --- Identificación ---
@export var attacker_name: String = ""
@export var target_name: String = ""

# --- Resultado de la tirada ---
@export var roll_value: int = 1  # Número que salió en el dado (1-20)
@export var is_critical: bool = false  # ¿Fue un 20 natural?
@export var is_miss: bool = false  # ¿Fue un fallo (1-5)?

# --- Consecuencias ---
@export var final_damage: int = 0  # Daño calculado tras aplicar armadura, etc.
@export var remaining_target_hp: int = 0  # HP del objetivo tras el daño

# --- Estado del turno (para que la UI actualice contadores) ---
@export var remaining_actions: int = 0  # Acciones que le quedan al atacante
@export var turn_ended: bool = false  # ¿Se acabó el turno tras esta acción?
