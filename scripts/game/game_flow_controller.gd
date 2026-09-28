extends Node
## GameFlowController: Orquesta el flujo completo del juego local.
## Conecta: Input del jugador -> Validacion -> Ejecucion -> UI
##
## MODO HOT-SEAT (prototipo):
## Cuando hotseat_mode = true, el jugador humano controla a TODOS los
## personajes por turnos (como un juego de mesa). Esto permite probar
## el flujo completo sin necesidad de red ni IA.
## En multijugador real, hotseat_mode = false y local_player_id es fijo.

## Preload del Resource de Persona 4 (evita errores de clase global)
const DiceRollResult = preload("res://scripts/data/combat/DiceRollResult.gd")

# --- Referencias a nodos de la escena ---
@onready var game_board: Node2D = $"../GameBoardVisual"
@onready var hud_root: Control = null
@onready var dice_ui: CanvasLayer = null

# --- Modo de juego ---
## true = un humano controla todos los personajes por turnos (prototipo)
## false = multijugador real (cada cliente controla solo el suyo)
var hotseat_mode: bool = true

# --- Estado del juego local ---
var entity_visuals: Dictionary = {}
var selected_character_id: String = ""
var local_player_id: String = "net_player_1"

# --- Referencias a controladores de personajes ---
var character_controllers: Dictionary = {}

func _ready():
	_find_ui_nodes()
	
	if game_board:
		game_board.cell_clicked.connect(_on_cell_clicked)
	
	TurnManager.turn_started.connect(_on_turn_started)
	TurnManager.turn_ended.connect(_on_turn_ended)
	TurnManager.round_started.connect(_on_round_started)
	
	CombatSystem.combat_resolved.connect(_on_combat_resolved)
	CombatSystem.damage_applied.connect(_on_damage_applied)
	CombatSystem.entity_died.connect(_on_entity_died)
	
	DiceSystem.dice_rolled.connect(_on_dice_rolled)
	
	GameState.player_joined.connect(_on_player_joined)
	GameState.enemy_spawned.connect(_on_enemy_spawned)
	GameState.entity_removed.connect(_on_entity_removed)
	
	print("[GameFlowController] Controlador de flujo inicializado. Hot-seat: ", hotseat_mode)

func _find_ui_nodes():
	for node in get_tree().get_root().get_children():
		_search_for_hud(node)
		_search_for_dice_ui(node)

func _search_for_hud(node: Node):
	if node.has_method("update_actions"):
		hud_root = node
		print("[GameFlowController] HUD encontrado: ", node.name)
		return
	for child in node.get_children():
		_search_for_hud(child)

func _search_for_dice_ui(node: Node):
	if node.has_method("hide_result") and node.has_signal("_mock_dice_roll"):
		dice_ui = node
		print("[GameFlowController] DiceResultUI encontrado: ", node.name)
		return
	for child in node.get_children():
		_search_for_dice_ui(child)

# =========================================================================
# SETUP DE LA PARTIDA
# =========================================================================

func setup_game():
	for entity_id in GameState.all_entities:
		var data = GameState.all_entities[entity_id]
		var is_enemy = _is_enemy(data)
		_create_entity_visual(data, is_enemy)
	
	for entity_id in GameState.all_entities:
		var data = GameState.all_entities[entity_id]
		var controller = CharacterController.new()
		controller.character_data = data
		add_child(controller)
		character_controllers[data.character_id] = controller
		
		controller.position_changed.connect(_on_character_moved.bind(data.character_id))
		controller.actions_updated.connect(_on_actions_updated.bind(data.character_id))
		controller.path_started.connect(_on_path_started.bind(data.character_id))
	
	print("[GameFlowController] Partida configurada con %d entidades." % entity_visuals.size())

func _create_entity_visual(data: CharacterInstanceData, is_enemy: bool):
	# Evitar duplicados: si ya existe un visual para esta entidad, no crear otro
	if entity_visuals.has(data.character_id):
		return
	
	var visual = Node2D.new()
	visual.set_script(load("res://scripts/game/entity_visual.gd"))
	add_child(visual)
	visual.setup(data, is_enemy)
	entity_visuals[data.character_id] = visual

func _is_enemy(data: CharacterInstanceData) -> bool:
	for enemy_id in GameState.enemies:
		if GameState.enemies[enemy_id].character_id == data.character_id:
			return true
	return false

# =========================================================================
# INPUT DEL JUGADOR
# =========================================================================

func _on_cell_clicked(grid_pos: Vector2i):
	## El jugador hizo clic en una casilla del tablero.
	print("[GameFlowController] Clic en casilla: ", grid_pos)
	
	# Verificar si es el turno del jugador local
	if not TurnManager.is_player_turn(local_player_id):
		print("[GameFlowController] No es tu turno (actual: ", TurnManager.get_current_player_id(), ")")
		return
	
	var cell = GridManager.get_cell(grid_pos)
	if cell == null:
		return
	
	if cell.is_occupied():
		var target_id = cell.occupant_id
		print("[GameFlowController] Casilla ocupada por: ", target_id)
		_try_attack(target_id)
	else:
		_try_move(grid_pos)

func _try_move(target_pos: Vector2i):
	var player_char = GameState.get_player_character(local_player_id)
	if player_char == null:
		print("[GameFlowController] ERROR: no hay personaje para ", local_player_id)
		return
	
	var controller = character_controllers.get(player_char.character_id)
	if controller == null:
		print("[GameFlowController] ERROR: no hay controller para ", player_char.character_id)
		return
	
	print("[GameFlowController] Intentando mover ", player_char.character_name, " a ", target_pos)
	var success = controller.move_to(target_pos)
	
	if not success:
		print("[GameFlowController] No se pudo mover a ", target_pos)

func _try_attack(target_id: String):
	var player_char = GameState.get_player_character(local_player_id)
	if player_char == null:
		return
	
	var target_data = GameState.get_entity(target_id)
	if target_data == null:
		return
	
	# No atacarse a si mismo ni a aliados en hot-seat
	if target_data.character_id == player_char.character_id:
		print("[GameFlowController] No puedes atacarte a ti mismo.")
		return
	
	if CombatSystem.can_attack(player_char, target_data):
		print("[GameFlowController] Atacando a ", target_data.character_name)
		CombatSystem.resolve_attack(player_char, target_data)
		
		var controller = character_controllers.get(player_char.character_id)
		if controller:
			controller.consume_action()
	else:
		print("[GameFlowController] No puedes atacar a ", target_data.character_name, " (fuera de rango)")

# =========================================================================
# MANEJO DE TURNOS
# =========================================================================

func _on_turn_started(player_id: String):
	var player_char = GameState.get_player_character(player_id)
	var player_name = "Jugador"
	if player_char:
		player_name = player_char.character_name
	
	# MODO HOT-SEAT: el humano controla al personaje del turno actual
	if hotseat_mode:
		local_player_id = player_id
	
	var is_local = (player_id == local_player_id)
	
	_update_turn_info_safe(player_name, is_local)
	
	if is_local and player_char:
		var controller = character_controllers.get(player_char.character_id)
		if controller:
			controller.start_turn()
		
		# Actualizar panel de stats del personaje activo
		_update_hud_character_stats()
		_update_actions_safe(controller.remaining_actions if controller else 2, player_char.class_data.actions_per_turn if player_char.class_data else 2)
	
	_deselect_all()
	
	print("[GameFlowController] Turno de: ", player_name, " (local: ", is_local, ")")

func _on_turn_ended(player_id: String):
	_update_turn_info_safe("Espera...", false)

func _on_round_started(round_number: int):
	print("[GameFlowController] === RONDA ", round_number, " ===")

func _unhandled_input(event):
	if event is InputEventKey and event.pressed:
		if event.keycode == KEY_ENTER or event.keycode == KEY_SPACE:
			if TurnManager.is_player_turn(local_player_id):
				print("[GameFlowController] Terminando turno...")
				TurnManager.end_current_turn()

# =========================================================================
# ACTUALIZACION DE UI
# =========================================================================

func _on_actions_updated(remaining: int, character_id: String):
	if character_id == _get_local_character_id():
		var player_char = GameState.get_player_character(local_player_id)
		var max_actions = 2
		if player_char and player_char.class_data:
			max_actions = player_char.class_data.actions_per_turn
		
		_update_actions_safe(remaining, max_actions)

func _on_character_moved(new_pos: Vector2i, character_id: String):
	if entity_visuals.has(character_id):
		entity_visuals[character_id].position = GridManager.grid_to_world(new_pos)

func _on_path_started(path: Array[Vector2i], character_id: String):
	if entity_visuals.has(character_id):
		entity_visuals[character_id].animate_path(path)

func _on_combat_resolved(result: Dictionary):
	if not result.success:
		if result.validation_error != "":
			print("[GameFlowController] Combate fallido: ", result.validation_error)
		return
	
	# Mostrar popup del dado
	if dice_ui and result.dice_result.has("total"):
		var dice_result = _convert_to_dice_roll_result(result)
		dice_ui._mock_dice_roll.emit(dice_result)
	
	# Eliminar entidad muerta del GameState y del tablero
	if result.target_died and result.target_id != "":
		print("[GameFlowController] Eliminando entidad muerta: ", result.target_id)
		GameState.remove_entity(result.target_id)

func _on_damage_applied(target_id: String, damage: int, remaining_hp: int):
	if entity_visuals.has(target_id):
		entity_visuals[target_id].play_damage_effect()
	
	if target_id == _get_local_character_id():
		_update_hud_character_stats()

func _on_entity_died(entity_id: String):
	if entity_visuals.has(entity_id):
		entity_visuals[entity_id].update_visual_state()
	print("[GameFlowController] Entidad murio: ", entity_id)

func _on_dice_rolled(result: Dictionary):
	pass

func _on_player_joined(player_id: String, data: CharacterInstanceData):
	_create_entity_visual(data, false)

func _on_enemy_spawned(enemy_id: String, data: CharacterInstanceData):
	_create_entity_visual(data, true)

func _on_entity_removed(entity_id: String):
	if entity_visuals.has(entity_id):
		entity_visuals[entity_id].queue_free()
		entity_visuals.erase(entity_id)
	print("[GameFlowController] Visual eliminado: ", entity_id)

# =========================================================================
# ACTUALIZACION DE UI SEGURA
# =========================================================================

func _update_turn_info_safe(player_name: String, is_local: bool):
	if hud_root and hud_root.has_method("update_turn_info") and hud_root.is_node_ready():
		hud_root.update_turn_info(player_name, is_local)
	else:
		call_deferred("_retry_update_turn_info", player_name, is_local)

func _retry_update_turn_info(player_name: String, is_local: bool):
	if hud_root and hud_root.has_method("update_turn_info"):
		hud_root.update_turn_info(player_name, is_local)

func _update_actions_safe(remaining: int, max_actions: int):
	if hud_root and hud_root.has_method("update_actions") and hud_root.is_node_ready():
		hud_root.update_actions(remaining, max_actions)
	else:
		call_deferred("_retry_update_actions", remaining, max_actions)

func _retry_update_actions(remaining: int, max_actions: int):
	if hud_root and hud_root.has_method("update_actions"):
		hud_root.update_actions(remaining, max_actions)

# =========================================================================
# UTILIDADES
# =========================================================================

func _convert_to_dice_roll_result(combat_result: Dictionary) -> Resource:
	var dice_result = DiceRollResult.new()
	
	var attacker = GameState.get_entity(combat_result.attacker_id)
	var target = GameState.get_entity(combat_result.target_id)
	dice_result.attacker_name = attacker.character_name if attacker else combat_result.attacker_id
	dice_result.target_name = target.character_name if target else combat_result.target_id
	
	if combat_result.dice_result.has("total"):
		dice_result.roll_value = combat_result.dice_result.total
	
	if combat_result.dice_result.has("result_type"):
		dice_result.is_critical = combat_result.dice_result.is_critical
		dice_result.is_miss = combat_result.dice_result.is_miss
	
	dice_result.final_damage = combat_result.damage_dealt
	dice_result.remaining_target_hp = combat_result.target_remaining_hp
	
	var player_char = GameState.get_player_character(local_player_id)
	if player_char:
		dice_result.remaining_actions = player_char.current_actions
	
	return dice_result

func _update_hud_character_stats():
	var player_char = GameState.get_player_character(local_player_id)
	if player_char == null:
		return
	
	var max_hp = player_char.class_data.max_hp if player_char.class_data else player_char.current_hp
	var armor = player_char.class_data.base_armor if player_char.class_data else 0
	
	if hud_root and hud_root.has_method("update_character_stats") and hud_root.is_node_ready():
		hud_root.update_character_stats(
			player_char.character_name,
			player_char.current_hp,
			max_hp,
			armor
		)
	else:
		call_deferred("_retry_update_stats", player_char.character_name, player_char.current_hp, max_hp, armor)

func _retry_update_stats(char_name: String, hp: int, max_hp: int, armor: int):
	if hud_root and hud_root.has_method("update_character_stats"):
		hud_root.update_character_stats(char_name, hp, max_hp, armor)

func _get_local_character_id() -> String:
	var player_char = GameState.get_player_character(local_player_id)
	if player_char:
		return player_char.character_id
	return ""

func _deselect_all():
	for entity_id in entity_visuals:
		entity_visuals[entity_id].set_selected(false)
	selected_character_id = ""
