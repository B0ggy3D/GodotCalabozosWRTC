extends Node

func _ready():
	print("--- INICIO TEST ABILITIES ---")
	
	# Conectar senales
	CombatSystem.damage_applied.connect(func(tid, dmg, hp): print("  [COMBAT] Dano a ", tid, ": ", dmg))
	CombatSystem.entity_died.connect(func(eid): print("  [COMBAT] *** ", eid, " MURIO ***"))
	
	# Semilla fija
	DiceSystem.set_seed(42)
	
	# Crear usuario (mago)
	var user = _create_character("player_1", "Mago", Vector2i(0, 0), 10)
	
	# Crear objetivo (enemigo)
	var enemy = _create_character("enemy_1", "Goblin", Vector2i(2, 0), 8)
	
	# Registrar en grid
	GridManager.set_occupant(user.grid_position, user.character_id)
	GridManager.set_occupant(enemy.grid_position, enemy.character_id)
	
	# Crear habilidades de prueba
	print("\n[TEST 1] Bola de Fuego (dano a distancia):")
	var fireball = _create_fireball()
	var result1 = CombatSystem.resolve_ability(user, fireball, enemy)
	_print_ability_result(result1)
	
	print("\n[TEST 2] Curacion:")
	var heal_spell = _create_heal()
	user.current_hp = 5  # Dano previo
	print("  HP antes de curar: ", user.current_hp)
	var result2 = CombatSystem.resolve_ability(user, heal_spell, user)
	_print_ability_result(result2)
	print("  HP despues de curar: ", user.current_hp)
	
	print("\n[TEST 3] Ataque fuera de rango:")
	enemy.grid_position = Vector2i(9, 9)
	GridManager.clear_occupant(Vector2i(2, 0))
	GridManager.set_occupant(Vector2i(9, 9), enemy.character_id)
	var result3 = CombatSystem.resolve_ability(user, fireball, enemy)
	_print_ability_result(result3)
	
	print("\n[TEST 4] Verificar can_use_ability:")
	user.current_actions = 2
	print("  Puede usar fireball (costo 1): ", CombatSystem.can_use_ability(user, fireball))
	user.current_actions = 0
	print("  Puede usar fireball sin acciones: ", CombatSystem.can_use_ability(user, fireball))
	
	# Limpiar
	DiceSystem.clear_seed()
	
	print("\n--- FIN TEST ABILITIES ---")

func _create_fireball() -> AbilityData:
	var ability = AbilityData.new()
	ability.id = "fireball"
	ability.ability_name = "Bola de Fuego"
	ability.description = "Lanza una bola de fuego al objetivo"
	ability.ability_type = AbilityData.AbilityType.SPELL_DAMAGE
	ability.target_type = AbilityData.TargetType.SINGLE_ENEMY
	ability.action_cost = 1
	ability.range_tiles = 5
	ability.dice_count = 3
	ability.dice_sides = 6
	ability.modifier = 2
	ability.critical_multiplier = 2.0
	ability.attack_bonus = 3
	ability.status_chance = 0.2
	ability.status_effect_id = "burning"
	ability.status_duration = 2
	return ability

func _create_heal() -> AbilityData:
	var ability = AbilityData.new()
	ability.id = "heal"
	ability.ability_name = "Curacion Menor"
	ability.description = "Restaura vida al objetivo"
	ability.ability_type = AbilityData.AbilityType.SPELL_HEAL
	ability.target_type = AbilityData.TargetType.SINGLE_ALLY
	ability.action_cost = 1
	ability.range_tiles = 3
	ability.dice_count = 2
	ability.dice_sides = 6
	ability.modifier = 1
	return ability

func _create_character(char_id: String, char_name: String, pos: Vector2i, hp: int) -> CharacterInstanceData:
	var class_data = CharacterClassData.new()
	class_data.class_id = char_id + "_class"
	class_data.display_name = char_name
	class_data.max_hp = hp
	class_data.actions_per_turn = 2
	
	var char_data = CharacterInstanceData.new()
	char_data.character_id = char_id
	char_data.character_name = char_name
	char_data.class_data = class_data
	char_data.current_hp = hp
	char_data.grid_position = pos
	
	return char_data

func _print_ability_result(result: Dictionary):
	if not result.success:
		print("  ERROR: ", result.validation_error)
		return
	
	print("  Habilidad: ", result.ability_id)
	print("  Usuario: ", result.user_id)
	print("  Objetivo: ", result.target_id)
	
	if result.dice_result.has("total"):
		print("  Tirada: ", result.dice_result.total)
	
	if result.damage_dealt > 0:
		print("  Dano: ", result.damage_dealt)
		print("  HP restante: ", result.target_remaining_hp)
	
	if result.healing_done > 0:
		print("  Curacion: ", result.healing_done)
	
	if result.target_died:
		print("  *** OBJETIVO ELIMINADO ***")
