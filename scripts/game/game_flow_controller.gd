extends Node
## GameFlowController: Orquesta el flujo del juego local (input -> validacion -> ejecucion -> UI).
## MODO HOT-SEAT: un humano controla todos los personajes por turnos.
## El modo DEBUG vive en game_debug.gd.

const DiceRollResult = preload("res://scripts/data/combat/DiceRollResult.gd")

@onready var game_board: Node2D = $"../GameBoardVisual"
@onready var hud_root: Control = null
@onready var dice_ui: CanvasLayer = null

var hotseat_mode: bool = true
const MOVE_AREA_SIZE: int = 5

var entity_visuals: Dictionary = {}
var selected_character_id: String = ""
var local_player_id: String = "net_player_1"
var character_controllers: Dictionary = {}
var game_debug: Node = null
var end_turn_button: Button = null
var debug_mode_active: bool = false

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
	_setup_debug()

func _setup_debug():
	game_debug = Node.new()
	game_debug.set_script(load("res://scripts/game/game_debug.gd"))
	add_child(game_debug)
	game_debug.setup(self, game_board)

func _find_ui_nodes():
	for node in get_tree().get_root().get_children():
		_search_for_hud(node)
		_search_for_dice_ui(node)
		_search_for_end_turn_button(node)

func _search_for_hud(node: Node):
	if node.has_method("update_actions"):
		hud_root = node
		return
	for child in node.get_children():
		_search_for_hud(child)

func _search_for_dice_ui(node: Node):
	if node.has_method("hide_result") and node.has_signal("_mock_dice_roll"):
		dice_ui = node
		return
	for child in node.get_children():
		_search_for_dice_ui(child)

# =========================================================================
# SETUP
# =========================================================================

func setup_game():
	for entity_id in GameState.all_entities:
		var data = GameState.all_entities[entity_id]
		spawn_entity_runtime(data, _is_enemy(data))
	print("[GameFlowController] Partida configurada con %d entidades." % entity_visuals.size())

func spawn_entity_runtime(data: CharacterInstanceData, is_enemy: bool):
	_create_entity_visual(data, is_enemy)
	var controller = CharacterController.new()
	controller.character_data = data
	add_child(controller)
	character_controllers[data.character_id] = controller
	controller.position_changed.connect(_on_character_moved.bind(data.character_id))
	controller.actions_updated.connect(_on_actions_updated.bind(data.character_id))
	controller.path_started.connect(_on_path_started.bind(data.character_id))
	return controller

func despawn_entity_runtime(entity_id: String):
	if character_controllers.has(entity_id):
		character_controllers[entity_id].queue_free()
		character_controllers.erase(entity_id)

func _create_entity_visual(data: CharacterInstanceData, is_enemy: bool):
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
# INPUT
# =========================================================================

func _on_cell_clicked(grid_pos: Vector2i):
	# MODO DEBUG ACTIVO (celular): tocar una casilla abre el menu
	if debug_mode_active and game_debug and game_debug.has_method("open_at"):
		var screen_pos = get_viewport().get_mouse_position()
		game_debug.open_at(grid_pos, screen_pos)
		return
	
	if not TurnManager.is_player_turn(local_player_id):
		return
	var cell = GridManager.get_cell(grid_pos)
	if cell == null:
		return
	if cell.is_occupied():
		_try_attack(cell.occupant_id)
	else:
		_try_move(grid_pos)

func _try_move(target_pos: Vector2i):
	var player_char = GameState.get_player_character(local_player_id)
	if player_char == null:
		return
	
	var cell = GridManager.get_cell(target_pos)
	var logic_walkable = GridManager.is_walkable(target_pos)
	
	print("=== DIAGNOSTICO MOVIMIENTO ===")
	print("  Destino clickeado: ", target_pos)
	print("  cell existe: ", cell != null)
	if cell != null:
		print("  cell.is_walkable (propiedad): ", cell.is_walkable)
		print("  cell.is_occupied(): ", cell.is_occupied())
	print("  GridManager.is_walkable(): ", logic_walkable)
	print("===============================")
	
	# ESTRICTO: nunca mover a casilla no caminable
	if not logic_walkable:
		print("[GameFlowController] Rechazado: casilla no caminable ", target_pos)
		return
	
	var controller = character_controllers.get(player_char.character_id)
	if controller == null:
		return
	
	var area = _get_movement_area(player_char.grid_position)
	print("  Destino en area de movimiento: ", area.has(target_pos))
	
	if not area.has(target_pos):
		print("[GameFlowController] Destino fuera del area de movimiento")
		return
	
	controller.move_to(target_pos)

func _try_attack(target_id: String):
	var player_char = GameState.get_player_character(local_player_id)
	if player_char == null:
		return
	if player_char.current_actions <= 0:
		print("[GameFlowController] No tienes acciones para atacar")
		return
	var target_data = GameState.get_entity(target_id)
	if target_data == null:
		return
	if target_data.character_id == player_char.character_id:
		return
	if CombatSystem.can_attack(player_char, target_data):
		CombatSystem.resolve_attack(player_char, target_data)
		var controller = character_controllers.get(player_char.character_id)
		if controller:
			controller.consume_action()
	else:
		print("[GameFlowController] Fuera de rango de ataque")

# =========================================================================
# TURNOS
# =========================================================================

func _on_turn_started(player_id: String):
	var player_char = GameState.get_player_character(player_id)
	var player_name = "Jugador"
	if player_char:
		player_name = player_char.character_name
	if hotseat_mode:
		local_player_id = player_id
	var is_local = (player_id == local_player_id)
	_update_turn_info_safe(player_name, is_local)
	if is_local and player_char:
		var controller = character_controllers.get(player_char.character_id)
		if controller:
			controller.start_turn()
		_update_hud_character_stats()
		var max_act = player_char.class_data.actions_per_turn if player_char.class_data else 2
		_update_actions_safe(controller.remaining_actions if controller else max_act, max_act)
	_deselect_all()
	_refresh_movement_highlight()
	_refresh_attack_highlight()

func _on_turn_ended(player_id: String):
	_update_turn_info_safe("Espera...", false)
	if game_board:
		game_board.clear_highlights()
		game_board.clear_attack_highlights()

func _on_round_started(round_number: int):
	print("[GameFlowController] === RONDA ", round_number, " ===")

func _unhandled_input(event):
	if event is InputEventKey and event.pressed:
		if event.keycode == KEY_ENTER or event.keycode == KEY_SPACE:
			if TurnManager.is_player_turn(local_player_id):
				TurnManager.end_current_turn()

# =========================================================================
# UI
# =========================================================================

func _on_actions_updated(remaining: int, character_id: String):
	if character_id == _get_local_character_id():
		var player_char = GameState.get_player_character(local_player_id)
		var max_actions = 2
		if player_char and player_char.class_data:
			max_actions = player_char.class_data.actions_per_turn
		_update_actions_safe(remaining, max_actions)
		_refresh_movement_highlight()
		_refresh_attack_highlight()

func _on_character_moved(new_pos: Vector2i, character_id: String):
	if entity_visuals.has(character_id):
		entity_visuals[character_id].position = GridManager.grid_to_world(new_pos)

func _on_path_started(path: Array[Vector2i], character_id: String):
	if entity_visuals.has(character_id):
		entity_visuals[character_id].animate_path(path)

func _on_combat_resolved(result: Dictionary):
	if not result.success:
		return
	if dice_ui and result.dice_result.has("total"):
		dice_ui._mock_dice_roll.emit(_convert_to_dice_roll_result(result))
	if result.target_died and result.target_id != "":
		GameState.remove_entity(result.target_id)

func _on_damage_applied(target_id: String, damage: int, remaining_hp: int):
	if entity_visuals.has(target_id):
		entity_visuals[target_id].play_damage_effect()
	if target_id == _get_local_character_id():
		_update_hud_character_stats()

func _on_entity_died(entity_id: String):
	if entity_visuals.has(entity_id):
		entity_visuals[entity_id].update_visual_state()

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

# =========================================================================
# HIGHLIGHTS (movimiento naranja + ataque rojo)
# =========================================================================

func _refresh_movement_highlight():
	if game_board == null:
		return
	var player_char = GameState.get_player_character(local_player_id)
	if player_char == null:
		game_board.clear_highlights()
		return
	var controller = character_controllers.get(player_char.character_id)
	if controller == null or controller.remaining_actions <= 0:
		game_board.clear_highlights()
		return
	game_board.show_movement_range(_get_movement_area(player_char.grid_position))

func _refresh_attack_highlight():
	if game_board == null or not game_board.has_method("show_attack_range"):
		return
	var player_char = GameState.get_player_character(local_player_id)
	if player_char == null:
		game_board.clear_attack_highlights()
		return
	var controller = character_controllers.get(player_char.character_id)
	if controller == null or controller.remaining_actions <= 0:
		game_board.clear_attack_highlights()
		return
	var atk = _get_attack_range_of_local()
	var origin = player_char.grid_position
	var cells: Array[Vector2i] = []
	for x in range(origin.x - atk, origin.x + atk + 1):
		for y in range(origin.y - atk, origin.y + atk + 1):
			var pos = Vector2i(x, y)
			if pos == origin:
				continue
			if GridManager.is_valid_position(pos):
				cells.append(pos)
	game_board.show_attack_range(cells)

func _get_movement_area(origin: Vector2i) -> Array[Vector2i]:
	var area: Array[Vector2i] = []
	var half: int = MOVE_AREA_SIZE / 2
	var reachable = Pathfinding.get_reachable_cells(origin, _get_movement_range_of_local())
	var reachable_set: Dictionary = {}
	for c in reachable:
		reachable_set[c] = true
	for x in range(origin.x - half, origin.x - half + MOVE_AREA_SIZE):
		for y in range(origin.y - half, origin.y - half + MOVE_AREA_SIZE):
			var pos = Vector2i(x, y)
			if pos == origin:
				continue
			if not GridManager.is_valid_position(pos):
				continue
			if not GridManager.is_walkable(pos):
				continue
			if not reachable_set.has(pos):
				continue
			area.append(pos)
	return area

func _get_movement_range_of_local() -> int:
	var pc = GameState.get_player_character(local_player_id)
	if pc and pc.class_data:
		return pc.class_data.movement_range
	return 4

func _get_attack_range_of_local() -> int:
	var pc = GameState.get_player_character(local_player_id)
	if pc and pc.equipped_weapon:
		return pc.equipped_weapon.attack_range
	return 1

# =========================================================================
# UI SEGURA + ARMA
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

## Actualiza el panel de estadisticas del personaje activo
func _update_hud_character_stats():
	var pc = GameState.get_player_character(local_player_id)
	if pc == null:
		return
	var max_hp = pc.class_data.max_hp if pc.class_data else pc.current_hp
	var armor = pc.class_data.base_armor if pc.class_data else 0
	if hud_root and hud_root.has_method("update_character_stats") and hud_root.is_node_ready():
		hud_root.update_character_stats(pc.character_name, pc.current_hp, max_hp, armor)
		_update_hud_weapon()
	else:
		call_deferred("_retry_update_stats", pc.character_name, pc.current_hp, max_hp, armor)

func _retry_update_stats(char_name: String, hp: int, max_hp: int, armor: int):
	if hud_root and hud_root.has_method("update_character_stats"):
		hud_root.update_character_stats(char_name, hp, max_hp, armor)
		_update_hud_weapon()

## NUEVO: Actualiza el indicador de arma del HUD con el arma del personaje activo
func _update_hud_weapon():
	var pc = GameState.get_player_character(local_player_id)
	if pc == null:
		return
	if hud_root and hud_root.has_method("update_weapon_info"):
		if pc.equipped_weapon:
			hud_root.update_weapon_info(pc.equipped_weapon.weapon_name, pc.equipped_weapon.attack_range)
		else:
			hud_root.update_weapon_info("", 1)

## NUEVO: Refresca HUD y highlights (llamado por el modo debug al equipar armas)
func refresh_highlights_and_hud():
	_update_hud_character_stats()
	_update_hud_weapon()
	_refresh_movement_highlight()
	_refresh_attack_highlight()

## Busca el boton "Fin de Turno" en la escena y lo conecta
func _search_for_end_turn_button(node: Node):
	if node.name == "EndTurnButton" and node is Button:
		end_turn_button = node
		end_turn_button.pressed.connect(_on_end_turn_button_pressed)
		print("[GameFlowController] Boton Fin de Turno conectado")
		return
	for child in node.get_children():
		_search_for_end_turn_button(child)

func _on_end_turn_button_pressed():
	if TurnManager.is_player_turn(local_player_id):
		print("[GameFlowController] Terminando turno desde boton...")
		TurnManager.end_current_turn()

# =========================================================================
# UTILIDADES
# =========================================================================

func _convert_to_dice_roll_result(combat_result: Dictionary) -> Resource:
	var d = DiceRollResult.new()
	var attacker = GameState.get_entity(combat_result.attacker_id)
	var target = GameState.get_entity(combat_result.target_id)
	d.attacker_name = attacker.character_name if attacker else combat_result.attacker_id
	d.target_name = target.character_name if target else combat_result.target_id
	if combat_result.dice_result.has("total"):
		d.roll_value = combat_result.dice_result.total
	if combat_result.dice_result.has("result_type"):
		d.is_critical = combat_result.dice_result.is_critical
		d.is_miss = combat_result.dice_result.is_miss
	d.final_damage = combat_result.damage_dealt
	d.remaining_target_hp = combat_result.target_remaining_hp
	var pc = GameState.get_player_character(local_player_id)
	if pc:
		d.remaining_actions = pc.current_actions
	return d

func _get_local_character_id() -> String:
	var pc = GameState.get_player_character(local_player_id)
	return pc.character_id if pc else ""

func _deselect_all():
	for entity_id in entity_visuals:
		entity_visuals[entity_id].set_selected(false)
	selected_character_id = ""
