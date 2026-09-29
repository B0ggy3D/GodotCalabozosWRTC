extends Control

@onready var turn_indicator: Label = $TopBar/HBoxContainer/TurnIndicator if has_node("TopBar/HBoxContainer/TurnIndicator") else null
@onready var actions_indicator: Label = $TopBar/HBoxContainer/ActionsIndicator if has_node("TopBar/HBoxContainer/ActionsIndicator") else null
@onready var character_name: Label = $CharacterStats/VBoxContainer/CharacterName if has_node("CharacterStats/VBoxContainer/CharacterName") else null
@onready var hp_bar: ProgressBar = $CharacterStats/VBoxContainer/HPBar if has_node("CharacterStats/VBoxContainer/HPBar") else null
@onready var hp_text: Label = $CharacterStats/VBoxContainer/HPText if has_node("CharacterStats/VBoxContainer/HPText") else null
@onready var armor_text: Label = $CharacterStats/VBoxContainer/ArmorText if has_node("CharacterStats/VBoxContainer/ArmorText") else null

# --- Indicador de arma (creado por codigo) ---
var weapon_icon: TextureRect = null
var weapon_text: Label = null

var current_actions: int = 2
var max_actions: int = 2

func _ready():
	_make_ignore_mouse(self)
	
	if turn_indicator == null:
		push_warning("[HUDController] No se encontro TurnIndicator")
	if actions_indicator == null:
		push_warning("[HUDController] No se encontro ActionsIndicator")
	if character_name == null:
		push_warning("[HUDController] No se encontro CharacterName")
	
	_create_weapon_indicator()
	
	update_actions(2, 2)
	update_turn_info("Jugador 1", true)
	update_character_stats("Guerrero", 15, 15, 2)
	update_weapon_info("", 1)

func _make_ignore_mouse(node: Node):
	if node is Control:
		node.mouse_filter = Control.MOUSE_FILTER_IGNORE
	for child in node.get_children():
		_make_ignore_mouse(child)

## Crea el indicador de arma (icono amarillo + texto) dentro del panel de stats
func _create_weapon_indicator():
	var vbox = get_node_or_null("CharacterStats/VBoxContainer")
	if vbox == null:
		push_warning("[HUDController] No se encontro VBoxContainer para el arma")
		return
	
	var hbox = HBoxContainer.new()
	hbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vbox.add_child(hbox)
	
	weapon_icon = TextureRect.new()
	weapon_icon.texture = load("res://assets/placeholders/weapon_placeholder.png")
	weapon_icon.custom_minimum_size = Vector2(24, 24)
	weapon_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	weapon_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	weapon_icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hbox.add_child(weapon_icon)
	
	weapon_text = Label.new()
	weapon_text.text = "Desarmado (rango 1)"
	weapon_text.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hbox.add_child(weapon_text)

# --- METODOS DE ACTUALIZACION ---

func update_actions(current: int, max: int):
	current_actions = current
	max_actions = max
	if actions_indicator:
		actions_indicator.text = "Acciones: %d/%d" % [current, max]
		actions_indicator.modulate = Color.RED if current == 0 else Color.WHITE

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

## Actualiza el indicador de arma equipada
func update_weapon_info(weapon_name: String, weapon_range: int):
	if weapon_text:
		if weapon_name == "":
			weapon_text.text = "Desarmado (rango 1)"
		else:
			weapon_text.text = "%s (rango %d)" % [weapon_name, weapon_range]

# --- BLOQUE DE PRUEBAS ---
func _input(event):
	if event is InputEventKey and event.pressed:
		if !Engine.is_editor_hint():
			if event.keycode == KEY_T:
				update_turn_info("Jugador 2 (Oponente)", false)
			elif event.keycode == KEY_A:
				update_actions(max(0, current_actions - 1), max_actions)
			elif event.keycode == KEY_R:
				update_actions(2, 2)
				update_turn_info("Jugador 1 (Tu)", true)
			elif event.keycode == KEY_D:
				update_character_stats("Guerrero", 65, 100, 2)
