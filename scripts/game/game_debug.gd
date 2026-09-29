extends Node
## GameDebug: Modo debug autocontenido (menu contextual, spawn, paredes, armas).

signal option_selected(option: String, grid_pos: Vector2i)

var flow = null
var board = null
var debug_menu: Control = null
var debug_layer: CanvasLayer = null
var debug_enabled: bool = true
var is_open: bool = false
var current_cell: Vector2i = Vector2i.ZERO

var panel: PanelContainer
var buttons: Dictionary = {}

func setup(p_flow, p_board):
	flow = p_flow
	board = p_board
	if debug_enabled:
		_create_menu()

func _ready():
	option_selected.connect(_on_debug_option)

func _create_menu():
	debug_layer = CanvasLayer.new()
	debug_layer.layer = 10
	add_child(debug_layer)
	
	debug_menu = Control.new()
	debug_menu.mouse_filter = Control.MOUSE_FILTER_IGNORE
	debug_layer.add_child(debug_menu)
	
	panel = PanelContainer.new()
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	debug_menu.add_child(panel)
	
	var vbox = VBoxContainer.new()
	vbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vbox.add_theme_constant_override("separation", 6)
	panel.add_child(vbox)
	
	# Acciones de celda
	buttons["add_enemy"] = _make_button(vbox, "Añadir Enemigo")
	buttons["add_ally"] = _make_button(vbox, "Añadir Aliado")
	buttons["toggle_wall"] = _make_button(vbox, "Poner/Quitar Pared")
	buttons["remove_entity"] = _make_button(vbox, "Quitar Entidad")
	
	# Separador visual
	var sep = HSeparator.new()
	vbox.add_child(sep)
	
	# Acciones de arma (solo si hay entidad en la celda)
	buttons["equip_unarmed"] = _make_button(vbox, "Arma: Desarmado (r1)")
	buttons["equip_sword"] = _make_button(vbox, "Arma: Espada (r1)")
	buttons["equip_spear"] = _make_button(vbox, "Arma: Lanza (r2)")
	buttons["equip_staff"] = _make_button(vbox, "Arma: Bastón (r3)")
	
	var sep2 = HSeparator.new()
	vbox.add_child(sep2)
	buttons["close"] = _make_button(vbox, "Cerrar")
	
	buttons["add_enemy"].pressed.connect(func(): _emit("add_enemy"))
	buttons["add_ally"].pressed.connect(func(): _emit("add_ally"))
	buttons["toggle_wall"].pressed.connect(func(): _emit("toggle_wall"))
	buttons["remove_entity"].pressed.connect(func(): _emit("remove_entity"))
	buttons["equip_unarmed"].pressed.connect(func(): _emit("equip_unarmed"))
	buttons["equip_sword"].pressed.connect(func(): _emit("equip_sword"))
	buttons["equip_spear"].pressed.connect(func(): _emit("equip_spear"))
	buttons["equip_staff"].pressed.connect(func(): _emit("equip_staff"))
	buttons["close"].pressed.connect(_close_menu)
	
	debug_menu.visible = false
	print("[GameDebug] Menu debug listo.")

func _make_button(parent: Node, text: String) -> Button:
	var b = Button.new()
	b.text = text
	b.mouse_filter = Control.MOUSE_FILTER_STOP
	b.custom_minimum_size = Vector2(200, 36)
	b.add_theme_font_size_override("font_size", 13)
	parent.add_child(b)
	return b

func open_at(grid_pos: Vector2i, screen_pos: Vector2):
	current_cell = grid_pos
	is_open = true
	debug_menu.visible = true
	
	var offset = Vector2(10, 10)
	var max_pos = get_viewport().get_visible_rect().size - Vector2(220, 420)
	debug_menu.position = screen_pos + offset
	if debug_menu.position.x > max_pos.x:
		debug_menu.position.x = max_pos.x
	if debug_menu.position.y > max_pos.y:
		debug_menu.position.y = max_pos.y
	
	var cell = GridManager.get_cell(grid_pos)
	if cell:
		var occupied = cell.is_occupied()
		buttons["toggle_wall"].text = "Quitar Pared" if not cell.is_walkable else "Poner Pared"
		buttons["remove_entity"].disabled = not occupied
		buttons["add_enemy"].disabled = occupied or not cell.is_walkable
		buttons["add_ally"].disabled = occupied or not cell.is_walkable
		# Las armas solo se pueden equipar si hay una entidad
		buttons["equip_unarmed"].disabled = not occupied
		buttons["equip_sword"].disabled = not occupied
		buttons["equip_spear"].disabled = not occupied
		buttons["equip_staff"].disabled = not occupied

func _close_menu():
	is_open = false
	debug_menu.visible = false

func _emit(option: String):
	emit_signal("option_selected", option, current_cell)
	_close_menu()

func _unhandled_input(event):
	if not debug_enabled:
		return
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_RIGHT:
		if board:
			var world_pos = board.get_global_mouse_position()
			var grid_pos = GridManager.world_to_grid(world_pos)
			if GridManager.is_valid_position(grid_pos):
				open_at(grid_pos, event.position)
				get_viewport().set_input_as_handled()
				return
	if is_open:
		if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
			_close_menu()
			get_viewport().set_input_as_handled()
		elif event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
			_close_menu()
			get_viewport().set_input_as_handled()

# =========================================================================
# ACCIONES
# =========================================================================

func _on_debug_option(option: String, grid_pos: Vector2i):
	match option:
		"add_enemy": _add_entity(grid_pos, true)
		"add_ally": _add_entity(grid_pos, false)
		"toggle_wall": _toggle_wall(grid_pos)
		"remove_entity": _remove_entity(grid_pos)
		"equip_unarmed": _equip_weapon(grid_pos, null)
		"equip_sword": _equip_weapon(grid_pos, _make_weapon("sword", "Espada", 1, 1, 8, 2))
		"equip_spear": _equip_weapon(grid_pos, _make_weapon("spear", "Lanza", 2, 1, 10, 1))
		"equip_staff": _equip_weapon(grid_pos, _make_weapon("staff", "Bastón", 3, 1, 6, 1))

func _make_weapon(id: String, wname: String, wrange: int, dcount: int, dsides: int, bonus: int) -> WeaponData:
	var w = WeaponData.new()
	w.id = id
	w.weapon_name = wname
	w.attack_range = wrange
	w.dice_count = dcount
	w.dice_sides = dsides
	w.damage_bonus = bonus
	w.critical_multiplier = 2.0
	return w

func _equip_weapon(grid_pos: Vector2i, weapon: WeaponData):
	var cell = GridManager.get_cell(grid_pos)
	if cell == null or not cell.is_occupied():
		return
	var entity_id = cell.occupant_id
	var data = GameState.get_entity(entity_id)
	if data == null:
		return
	data.equipped_weapon = weapon
	var wname = weapon.weapon_name if weapon else "Desarmado"
	print("[GameDebug] ", data.character_name, " equipado con: ", wname)
	# Refrescar HUD y highlights de ataque
	if flow and flow.has_method("refresh_highlights_and_hud"):
		flow.refresh_highlights_and_hud()

func _add_entity(grid_pos: Vector2i, is_enemy: bool):
	var cell = GridManager.get_cell(grid_pos)
	if cell == null or cell.is_occupied() or not cell.is_walkable:
		return
	var id = ("dbg_enemy_" if is_enemy else "dbg_ally_") + str(Time.get_ticks_msec())
	var data = CharacterInstanceData.new()
	data.character_id = id
	data.character_name = "Goblin Debug" if is_enemy else "Aliado Debug"
	var cls = CharacterClassData.new()
	cls.class_id = "debug"
	cls.display_name = data.character_name
	cls.max_hp = 8
	cls.actions_per_turn = 1 if is_enemy else 2
	cls.movement_range = 3
	data.class_data = cls
	data.current_hp = cls.max_hp
	data.grid_position = grid_pos
	GameState.register_enemy(id, data)
	flow.spawn_entity_runtime(data, is_enemy)

func _toggle_wall(grid_pos: Vector2i):
	var cell = GridManager.get_cell(grid_pos)
	if cell == null:
		return
	if cell.is_occupied():
		return
	cell.is_walkable = not cell.is_walkable
	cell.blocks_vision = not cell.is_walkable
	if board:
		board.update_cell(grid_pos, cell.is_walkable)

func _remove_entity(grid_pos: Vector2i):
	var cell = GridManager.get_cell(grid_pos)
	if cell == null or not cell.is_occupied():
		return
	var entity_id = cell.occupant_id
	GameState.remove_entity(entity_id)
	flow.despawn_entity_runtime(entity_id)
