extends Node
## CombatSystem: Orquesta el flujo completo de un ataque.
## Flujo: Solicitud -> Validacion -> Tirada -> Dano -> Resultado
## En multijugador, el HOST ejecuta este sistema y transmite el resultado.

# --- Senales ---
signal combat_resolved(combat_result: Dictionary)
signal damage_applied(target_id: String, damage: int, remaining_hp: int)
signal entity_died(entity_id: String)
signal healing_applied(target_id: String, healing: int, remaining_hp: int)

# --- Referencias a otros sistemas ---
# (Se asume que GridManager, TurnManager y DiceSystem son Autoloads)

# --- API PUBLICA: ATAQUES BASICOS ---

## Solicita un ataque de un atacante a un objetivo.
## attacker_data: CharacterInstanceData del atacante
## target_data: CharacterInstanceData del objetivo
## Retorna un Dictionary con el resultado completo del combate
func resolve_attack(attacker_data: CharacterInstanceData, target_data: CharacterInstanceData) -> Dictionary:
	var result: Dictionary = {
		"success": false,
		"attacker_id": attacker_data.character_id,
		"target_id": target_data.character_id,
		"validation_error": "",
		"dice_result": {},
		"damage_dealt": 0,
		"target_remaining_hp": target_data.current_hp,
		"target_died": false
	}
	
	# Paso 1: Validar rango
	var range_check = _validate_range(attacker_data, target_data)
	if not range_check.valid:
		result.validation_error = range_check.reason
		emit_signal("combat_resolved", result)
		return result
	
	# Paso 2: Obtener arma del atacante
	var weapon = attacker_data.equipped_weapon
	if weapon == null:
		weapon = _create_unarmed_attack()
	
	# Paso 3: Tirada de dados (autoritativa - solo el host deberia llamar esto)
	var dice_result = DiceSystem.roll_attack(weapon.damage_bonus, 0.0)
	result.dice_result = dice_result
	
	# Paso 4: Si es fallo, no hay dano
	if dice_result.is_miss:
		result.success = true
		result.damage_dealt = 0
		emit_signal("combat_resolved", result)
		return result
	
	# Paso 5: Calcular dano
	var base_damage = _calculate_base_damage(weapon)
	var final_damage = DiceSystem.calculate_damage(base_damage, dice_result, weapon.critical_multiplier)
	
	# Paso 6: Aplicar dano al objetivo
	target_data.current_hp -= final_damage
	if target_data.current_hp < 0:
		target_data.current_hp = 0
	
	# Paso 7: Construir resultado final
	result.success = true
	result.damage_dealt = final_damage
	result.target_remaining_hp = target_data.current_hp
	result.target_died = target_data.current_hp <= 0
	
	# Paso 8: Emitir senales
	emit_signal("damage_applied", target_data.character_id, final_damage, target_data.current_hp)
	
	if result.target_died:
		emit_signal("entity_died", target_data.character_id)
	
	emit_signal("combat_resolved", result)
	
	return result

## Verifica si un atacante puede atacar a un objetivo (sin ejecutar el ataque)
func can_attack(attacker_data: CharacterInstanceData, target_data: CharacterInstanceData) -> bool:
	var range_check = _validate_range(attacker_data, target_data)
	return range_check.valid

# --- API PUBLICA: HABILIDADES ---

## Resuelve el uso de una habilidad.
## Similar a resolve_attack pero con soporte para AoE, curacion, etc.
func resolve_ability(user_data: CharacterInstanceData, ability: AbilityData, target_data: CharacterInstanceData) -> Dictionary:
	var result: Dictionary = {
		"success": false,
		"user_id": user_data.character_id,
		"ability_id": ability.id,
		"target_id": target_data.character_id if target_data else "",
		"validation_error": "",
		"dice_result": {},
		"damage_dealt": 0,
		"healing_done": 0,
		"target_remaining_hp": target_data.current_hp if target_data else 0,
		"target_died": false,
		"affected_targets": []
	}
	
	# Paso 1: Validar rango
	if target_data != null:
		var distance = _manhattan_distance(user_data.grid_position, target_data.grid_position)
		if distance > ability.range_tiles:
			result.validation_error = "Objetivo fuera de rango (distancia: %d, rango: %d)" % [distance, ability.range_tiles]
			emit_signal("combat_resolved", result)
			return result
	
	# Paso 2: Validar tipo de objetivo
	if not _validate_target_type(ability, user_data, target_data):
		result.validation_error = "Tipo de objetivo invalido para esta habilidad"
		emit_signal("combat_resolved", result)
		return result
	
	# Paso 3: Tirada de dados (autoritativa)
	var dice_result = DiceSystem.roll_dice(ability.dice_count, ability.dice_sides, ability.modifier)
	result.dice_result = dice_result
	
	# Paso 4: Resolver segun tipo de habilidad
	match ability.ability_type:
		AbilityData.AbilityType.SPELL_HEAL:
			result = _resolve_heal(result, user_data, target_data, ability, dice_result)
		
		AbilityData.AbilityType.SPELL_DAMAGE, AbilityData.AbilityType.RANGED_ATTACK, AbilityData.AbilityType.MELEE_ATTACK:
			result = _resolve_damage_ability(result, user_data, target_data, ability, dice_result)
		
		AbilityData.AbilityType.SPELL_BUFF, AbilityData.AbilityType.SPELL_DEBUFF:
			result.success = true
			result.damage_dealt = 0
		
		_:
			result.success = true
	
	emit_signal("combat_resolved", result)
	return result

## Verifica si un usuario puede usar una habilidad
func can_use_ability(user_data: CharacterInstanceData, ability: AbilityData) -> bool:
	if user_data.current_actions < ability.action_cost:
		return false
	
	# Verificar cooldown (se manejara con un sistema de estado futuro)
	return true

# --- VALIDACIONES ---

func _validate_range(attacker: CharacterInstanceData, target: CharacterInstanceData) -> Dictionary:
	var result = {"valid": false, "reason": ""}
	
	if not GridManager.is_valid_position(attacker.grid_position):
		result.reason = "Atacante fuera del tablero"
		return result
	
	if not GridManager.is_valid_position(target.grid_position):
		result.reason = "Objetivo fuera del tablero"
		return result
	
	var distance = _manhattan_distance(attacker.grid_position, target.grid_position)
	
	var weapon_range = 1
	if attacker.equipped_weapon:
		weapon_range = attacker.equipped_weapon.attack_range
	
	if distance > weapon_range:
		result.reason = "Objetivo fuera de rango (distancia: %d, rango: %d)" % [distance, weapon_range]
		return result
	
	# TODO: Aqui se agregara la validacion de Line of Sight (Persona 3)
	# if not VisionSystem.has_line_of_sight(attacker.grid_position, target.grid_position):
	#     result.reason = "Sin linea de vision"
	#     return result
	
	result.valid = true
	return result

func _validate_target_type(ability: AbilityData, user: CharacterInstanceData, target: CharacterInstanceData) -> bool:
	if target == null:
		return ability.target_type == AbilityData.TargetType.SELF
	
	match ability.target_type:
		AbilityData.TargetType.SELF:
			return target.character_id == user.character_id
		AbilityData.TargetType.SINGLE_ENEMY, AbilityData.TargetType.SINGLE_ALLY:
			return true
		_:
			return true
	
	return true

# --- LOGICA INTERNA: ATAQUES BASICOS ---

func _manhattan_distance(a: Vector2i, b: Vector2i) -> int:
	return abs(a.x - b.x) + abs(a.y - b.y)

func _calculate_base_damage(weapon: WeaponData) -> int:
	var damage_result = DiceSystem.roll_dice(weapon.dice_count, weapon.dice_sides, 0)
	return damage_result.total

func _create_unarmed_attack() -> WeaponData:
	var unarmed = WeaponData.new()
	unarmed.id = "unarmed"
	unarmed.weapon_name = "Ataque Desarmado"
	unarmed.dice_count = 1
	unarmed.dice_sides = 4
	unarmed.damage_bonus = 0
	unarmed.attack_range = 1
	unarmed.critical_multiplier = 2.0
	return unarmed

# --- LOGICA INTERNA: HABILIDADES ---

func _resolve_damage_ability(result: Dictionary, user: CharacterInstanceData, target: CharacterInstanceData, ability: AbilityData, dice_result: Dictionary) -> Dictionary:
	if target == null:
		result.success = false
		result.validation_error = "Sin objetivo"
		return result
	
	# Verificar si es fallo (solo para ataques que requieren roll de ataque)
	if ability.attack_bonus > 0:
		var attack_roll = DiceSystem.roll_attack(ability.attack_bonus, 0.0)
		if attack_roll.is_miss:
			result.success = true
			result.damage_dealt = 0
			return result
	
	# Calcular dano
	var base_damage = dice_result.total
	var final_damage = DiceSystem.calculate_damage(base_damage, dice_result, ability.critical_multiplier)
	
	# Aplicar dano
	target.current_hp -= final_damage
	if target.current_hp < 0:
		target.current_hp = 0
	
	result.success = true
	result.damage_dealt = final_damage
	result.target_remaining_hp = target.current_hp
	result.target_died = target.current_hp <= 0
	
	emit_signal("damage_applied", target.character_id, final_damage, target.current_hp)
	
	if result.target_died:
		emit_signal("entity_died", target.character_id)
	
	return result

func _resolve_heal(result: Dictionary, user: CharacterInstanceData, target: CharacterInstanceData, ability: AbilityData, dice_result: Dictionary) -> Dictionary:
	if target == null:
		target = user
	
	var heal_amount = dice_result.total
	
	# No curar mas alla del maximo
	var max_hp = target.class_data.max_hp if target.class_data else target.current_hp
	var actual_heal = min(heal_amount, max_hp - target.current_hp)
	
	target.current_hp += actual_heal
	
	result.success = true
	result.healing_done = actual_heal
	result.target_remaining_hp = target.current_hp
	
	emit_signal("healing_applied", target.character_id, actual_heal, target.current_hp)
	
	return result
