extends Node

func _ready():
	print("--- INICIO TEST DICE SYSTEM ---")
	
	# Conectar senal
	DiceSystem.dice_rolled.connect(_on_dice_rolled)
	
	# Usar semilla fija para resultados reproducibles en el test
	DiceSystem.set_seed(42)
	
	# Prueba 1: Tirada basica d20
	print("\n[TEST 1] Tirada basica d20:")
	var result1 = DiceSystem.roll_dice(1, 20, 0)
	_print_roll_result(result1)
	
	# Prueba 2: Tirada con modificador positivo
	print("\n[TEST 2] Tirada d20 con bonus +5:")
	var result2 = DiceSystem.roll_dice(1, 20, 5)
	_print_roll_result(result2)
	
	# Prueba 3: Tirada de ataque
	print("\n[TEST 3] Tirada de ataque con bonus +3:")
	var result3 = DiceSystem.roll_attack(3, 0.0)
	_print_roll_result(result3)
	
	# Prueba 4: Multiples tiradas para ver distribucion
	print("\n[TEST 4] 10 tiradas d20:")
	for i in range(10):
		var r = DiceSystem.roll_dice(1, 20, 0)
		print("  Tirada ", i+1, ": ", r.total, " -> ", DiceSystem.result_to_string(r.result_type))
	
	# Prueba 5: Calculo de dano
	print("\n[TEST 5] Calculo de dano:")
	var attack_result = DiceSystem.roll_dice(1, 20, 10)  # Bonus alto para asegurar hit
	var damage = DiceSystem.calculate_damage(8, attack_result, 2.0)
	print("  Resultado: ", DiceSystem.result_to_string(attack_result.result_type))
	print("  Dano causado: ", damage)
	
	# Limpiar semilla
	DiceSystem.clear_seed()
	
	print("\n--- FIN TEST DICE SYSTEM ---")

func _print_roll_result(result: Dictionary):
	print("  Dados: ", result.rolls)
	print("  Modificador: ", result.modifier)
	print("  Total: ", result.total)
	print("  Resultado: ", DiceSystem.result_to_string(result.result_type))

func _on_dice_rolled(result: Dictionary):
	# Esta senal se usara para que la UI muestre la animacion del dado
	pass
