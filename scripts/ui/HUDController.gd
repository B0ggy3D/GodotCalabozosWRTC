extends Control

# 1. REFERENCIAS A LOS NODOS (con verificacion null)
@onready var turn_indicator: Label = $TopBar/HBoxContainer/TurnIndicator if has_node("TopBar/HBoxContainer/TurnIndicator") else null
@onready var actions_indicator: Label = $TopBar/HBoxContainer/ActionsIndicator if has_node("TopBar/HBoxContainer/ActionsIndicator") else null
@onready var character_name: Label = $CharacterStats/VBoxContainer/CharacterName if has_node("CharacterStats/VBoxContainer/CharacterName") else null
@onready var hp_bar: ProgressBar = $CharacterStats/VBoxContainer/HPBar if has_node("CharacterStats/VBoxContainer/HPBar") else null
@onready var hp_text: Label = $CharacterStats/VBoxContainer/HPText if has_node("CharacterStats/VBoxContainer/HPText") else null
@onready var armor_text: Label = $CharacterStats/VBoxContainer/ArmorText if has_node("CharacterStats/VBoxContainer/ArmorText") else null

# 2. ESTADO INTERNO DE LA UI
var current_actions: int = 2
var max_actions: int = 2

func _ready():
	# Hacer que todo el HUD ignore el mouse para que los clics
	# lleguen al tablero (GameBoardVisual)
	_make_ignore_mouse(self)
	
	# Verificar que los nodos se cargaron correctamente
	if turn_indicator == null:
		push_warning("[HUDController] No se encontro TurnIndicator")
	if actions_indicator == null:
		push_warning("[HUDController] No se encontro ActionsIndicator")
	if character_name == null:
		push_warning("[HUDController] No se encontro CharacterName")
	
	# Inicializar con valores por defecto
	update_actions(2, 2)
	update_turn_info("Jugador 1", true)
	update_character_stats("Guerrero", 15, 15, 2)

## Recorre el arbol y hace que todos los Control ignoren el mouse.
## Esto permite que los clics pasen "a traves" del HUD y lleguen
## al tablero de juego (GameBoardVisual).
func _make_ignore_mouse(node: Node):
	if node is Control:
		node.mouse_filter = Control.MOUSE_FILTER_IGNORE
	for child in node.get_children():
		_make_ignore_mouse(child)

# 3. METODOS DE ACTUALIZACION (API publica)

func update_actions(current: int, max: int):
	current_actions = current
	max_actions = max
	
	if actions_indicator:
		actions_indicator.text = "Acciones: %d/%d" % [current, max]
		if current == 0:
			actions_indicator.modulate = Color.RED
		else:
			actions_indicator.modulate = Color.WHITE

func update_character_stats(name: String, current_hp: int, max_hp: int, armor: int):
	if character_name:
		character_name.text = name
	if hp_bar:
		hp_bar.max_value = max_hp
		hp_bar.value = current_hp
	if hp_text:
		hp_text.text = "%d / %d" % [current_hp, max_hp]
	if armor_text:
		armor_text.text = "Armadura: %d" % armor

func update_turn_info(player_name: String, is_player_turn: bool):
	if turn_indicator:
		turn_indicator.text = "Turno: %s" % player_name
		turn_indicator.modulate = Color.GREEN if is_player_turn else Color.GRAY

# 4. BLOQUE DE PRUEBAS (Simulacion con teclas)
func _input(event):
	if event is InputEventKey and event.pressed:
		if !Engine.is_editor_hint():
			if event.keycode == KEY_T:
				print("UI: Simulando cambio de turno...")
				update_turn_info("Jugador 2 (Oponente)", false)
			elif event.keycode == KEY_A:
				print("UI: Simulando gasto de accion...")
				update_actions(max(0, current_actions - 1), max_actions)
			elif event.keycode == KEY_R:
				print("UI: Simulando reinicio de turno...")
				update_actions(2, 2)
				update_turn_info("Jugador 1 (Tu)", true)
			elif event.keycode == KEY_D:
				print("UI: Simulando cambio de estadisticas...")
				update_character_stats("Guerrero", 65, 100, 2)
