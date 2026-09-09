extends Node

func _ready():
	print("--- INICIO TEST COMBAT ---")
	
	# Conectar senales
	CombatSystem.combat_resolved.connect(_on_combat_resolved)
	CombatSystem.damage_applied.connect(_on_damage_applied)
	CombatSystem.entity_died.connect(_on_entity_died)
	
	# Semilla fija para resultados reproducibles
	DiceSystem.set_seed(123)
	
	# Crear atacante
	var weapon = WeaponData.new()
	weapon.id = "test_sword"
	weapon.weapon_name = "Espada Larga"
	weapon.dice_count = 1
	weapon.dice_sides = 8
	weapon.damage_bonus = 2
	weapon.attack_range = 1
	weapon.critical_multiplier = 2.0
	
	var attacker_class = CharacterClassData.new()
	attacker_class.class_id = "warrior"
	attacker_class.display_name = "Guerrero"
	attacker_class.actions_per_turn = 2
	
	var attacker = CharacterInstanceData.new()
	attacker.character_id = "player_1"
	attacker.character_name = "Guerrero Heroico"
	attacker.class_data = attacker_class
	attacker.current_hp = 12
	attacker.grid_position = Vector2i(1, 1)
	attacker.equipped_weapon = weapon
	
	# Crear objetivo (enemigo adyacente)
	var target_class = CharacterClassData.new()
	target_class.class_id = "goblin"
	target_class.display_name = "Goblin"
	
	var target = CharacterInstanceData.new()
	target.character_id = "enemy_1"
	target.character_name = "Goblin Salvaje"
	target.class_data = target_class
	target.current_hp = 7
	target.grid_position = Vector2i(2, 1)  # Adyacente al atacante
	
	# Registrar posiciones en el grid
	GridManager.set_occupant(attacker.grid_position, attacker.character_id)
	GridManager.set_occupant(target.grid_position, target.character_id)
	
	# Prueba 1: Ataque valido (adyacente)
	print("\n[TEST 1] Ataque a enemigo adyacente:")
	var result1 = CombatSystem.resolve_attack(attacker, target)
	_print_combat_result(result1)
	
	# Prueba 2: Ataque fuera de rango
	print("\n[TEST 2] Ataque fuera de rango:")
	target.grid_position = Vector2i(5, 5)  # Mover lejos
	GridManager.clear_occupant(Vector2i(2, 1))
	GridManager.set_occupant(Vector2i(5, 5), target.character_id)
	
	var result2 = CombatSystem.resolve_attack(attacker, target)
	_print_combat_result(result2)
	
	# Prueba 3: Ataque hasta matar (garantizado)
	print("\n[TEST 3] Ataque para matar (garantizado):")
	target.grid_position = Vector2i(2, 1)  # Volver a poner cerca
	GridManager.clear_occupant(Vector2i(5, 5))
	GridManager.set_occupant(Vector2i(2, 1), target.character_id)
	target.current_hp = 1  # Solo 1 HP, cualquier hit lo mata
	
	# Darle un bonus enorme al arma para garantizar un hit
	attacker.equipped_weapon.damage_bonus = 20
	
	var result3 = CombatSystem.resolve_attack(attacker, target)
	_print_combat_result(result3)
	
	# Limpiar
	DiceSystem.clear_seed()
	
	print("\n--- FIN TEST COMBAT ---")

func _print_combat_result(result: Dictionary):
	if not result.success:
		print("  ERROR: ", result.validation_error)
		return
	
	print("  Atacante: ", result.attacker_id)
	print("  Objetivo: ", result.target_id)
	
	if result.dice_result.has("total"):
		print("  Tirada: ", result.dice_result.total)
		print("  Resultado dado: ", DiceSystem.result_to_string(result.dice_result.result_type))
	
	print("  Dano causado: ", result.damage_dealt)
	print("  HP restante del objetivo: ", result.target_remaining_hp)
	
	if result.target_died:
		print("  *** EL OBJETIVO HA MUERTO ***")

func _on_combat_resolved(result: Dictionary):
	pass  # La UI usara esta senal para mostrar animaciones

func _on_damage_applied(target_id: String, damage: int, remaining_hp: int):
	print("  [SIGNAL] Dano aplicado a ", target_id, ": ", damage, " (HP restante: ", remaining_hp, ")")

func _on_entity_died(entity_id: String):
	print("  [SIGNAL] *** ", entity_id, " ha muerto ***")
