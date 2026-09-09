extends Node
## CombatSystem: Orquesta el flujo completo de un ataque.
## Flujo: Solicitud -> Validacion -> Tirada -> Dano -> Resultado
## En multijugador, el HOST ejecuta este sistema y transmite el resultado.

# --- Senales ---
signal combat_resolved(combat_result: Dictionary)
signal damage_applied(target_id: String, damage: int, remaining_hp: int)
signal entity_died(entity_id: String)

# --- Referencias a otros sistemas ---
# (Se asume que GridManager, TurnManager y DiceSystem son Autoloads)

# --- API PUBLICA ---

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
		# Si no tiene arma, usar ataque desarmado basico
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

# --- VALIDACIONES ---

func _validate_range(attacker: CharacterInstanceData, target: CharacterInstanceData) -> Dictionary:
	var result = {"valid": false, "reason": ""}
	
	# Verificar que ambos existan en el grid
	if not GridManager.is_valid_position(attacker.grid_position):
		result.reason = "Atacante fuera del tablero"
		return result
	
	if not GridManager.is_valid_position(target.grid_position):
		result.reason = "Objetivo fuera del tablero"
		return result
	
	# Calcular distancia Manhattan (adecuada para grid sin diagonal)
	var distance = _manhattan_distance(attacker.grid_position, target.grid_position)
	
	# Obtener rango del arma
	var weapon_range = 1  # Default: melee
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

# --- UTILIDADES ---

func _manhattan_distance(a: Vector2i, b: Vector2i) -> int:
	return abs(a.x - b.x) + abs(a.y - b.y)

func _calculate_base_damage(weapon: WeaponData) -> int:
	# Tira los dados de dano del arma
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
