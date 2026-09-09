extends Node
## DiceSystem: Autoload para resolver tiradas de dados.
## En multijugador, SOLO EL HOST ejecuta las tiradas.
## Los clientes reciben el resultado ya resuelto.

# --- Senales ---
signal dice_rolled(result: Dictionary)

# --- Resultados posibles ---
enum RollResult {
	MISS,       # Fallo
	HIT,        # Exito
	CRITICAL    # Critico
}

# --- Configuracion por defecto (estilo D&D d20) ---
@export var default_dice_sides: int = 20
@export var miss_threshold: int = 5        # 1-5 = fallo
@export var hit_threshold: int = 19        # 6-19 = exito
@export var critical_threshold: int = 20   # 20 = critico

# --- Semilla para reproducibilidad (util para debugging y testing) ---
var rng: RandomNumberGenerator = RandomNumberGenerator.new()
var use_fixed_seed: bool = false
var fixed_seed: int = 0

func _ready():
	if use_fixed_seed:
		rng.seed = fixed_seed
	else:
		rng.randomize()

# --- API PUBLICA ---

## Configura una semilla fija (para testing o debugging)
func set_seed(seed_value: int):
	use_fixed_seed = true
	fixed_seed = seed_value
	rng.seed = seed_value
	print("[DiceSystem] Semilla fija: ", seed_value)

## Desactiva la semilla fija (usa aleatoriedad real)
func clear_seed():
	use_fixed_seed = false
	rng.randomize()

## Tirada basica: lanza N dados de X caras y suma modificadores
## Retorna un Dictionary con todos los detalles del resultado
func roll_dice(dice_count: int = 1, dice_sides: int = 20, modifier: int = 0) -> Dictionary:
	var rolls: Array[int] = []
	var total: int = 0
	
	for i in range(dice_count):
		var roll = rng.randi_range(1, dice_sides)
		rolls.append(roll)
		total += roll
	
	total += modifier
	
	var result = {
		"rolls": rolls,
		"modifier": modifier,
		"total": total,
		"result_type": _evaluate_result(total),
		"is_miss": false,
		"is_hit": false,
		"is_critical": false
	}
	
	# Marcar flags de resultado
	match result.result_type:
		RollResult.MISS:
			result.is_miss = true
		RollResult.HIT:
			result.is_hit = true
		RollResult.CRITICAL:
			result.is_critical = true
	
	emit_signal("dice_rolled", result)
	return result

## Tirada de ataque con bonus y probabilidad de critico modificada
## attack_bonus: modificador al resultado del dado
## critical_chance: probabilidad extra de critico (0.0 a 1.0)
func roll_attack(attack_bonus: int = 0, critical_chance: float = 0.0) -> Dictionary:
	var base_roll = roll_dice(1, default_dice_sides, attack_bonus)
	
	# Verificar critico por probabilidad adicional
	if not base_roll.is_critical and critical_chance > 0.0:
		var crit_roll = rng.randf()
		if crit_roll <= critical_chance:
			base_roll.result_type = RollResult.CRITICAL
			base_roll.is_critical = true
			base_roll.is_hit = false
			base_roll.is_miss = false
	
	return base_roll

## Calcula el dano final basado en el resultado de la tirada
func calculate_damage(base_damage: int, dice_result: Dictionary, critical_multiplier: float = 2.0) -> int:
	if dice_result.is_miss:
		return 0
	
	var final_damage = base_damage
	
	if dice_result.is_critical:
		final_damage = int(base_damage * critical_multiplier)
	
	return max(0, final_damage)

# --- LOGICA INTERNA ---

func _evaluate_result(total: int) -> RollResult:
	if total <= miss_threshold:
		return RollResult.MISS
	elif total >= critical_threshold:
		return RollResult.CRITICAL
	else:
		return RollResult.HIT

## Utilidad: convierte el enum a texto legible
func result_to_string(result_type: RollResult) -> String:
	match result_type:
		RollResult.MISS: return "FALLO"
		RollResult.HIT: return "EXITO"
		RollResult.CRITICAL: return "CRITICO"
	return "DESCONOCIDO"
