extends Control

# 1. REFERENCIAS A LOS NODOS
# Usamos @onready para que se asignen cuando la escena está completamente cargada.
# El camino ($) es relativo al nodo que tiene este script (HUDRoot).
@onready var turn_indicator: Label = $TopBar/HBoxContainer/TurnIndicator
@onready var actions_indicator: Label = $TopBar/HBoxContainer/ActionsIndicator
@onready var character_name: Label = $CharacterStats/VBoxContainer/CharacterName
@onready var hp_bar: ProgressBar = $CharacterStats/VBoxContainer/HPBar
@onready var hp_text: Label = $CharacterStats/VBoxContainer/HPText
@onready var armor_text: Label = $CharacterStats/VBoxContainer/ArmorText

# 2. ESTADO INTERNO DE LA UI
# La UI guarda su propio estado visual temporalmente. 
# Esto es útil para animaciones o validaciones visuales antes de que llegue la red.
var current_actions: int = 2
var max_actions: int = 2

func _ready():
	# Aquí irán las conexiones de señales reales en el futuro.
	# Ejemplo: GameState.turn_changed.connect(_on_turn_changed)
	# Por ahora, lo dejamos vacío para que la escena no falle si no hay Gameplay aún.
	pass

# 3. MÉTODOS DE ACTUALIZACIÓN (La "API" de tu UI)
# Estos métodos son los únicos que el resto del equipo debe llamar.
# Observa cómo traducimos datos crudos (ints, strings) en cambios visuales.

func update_actions(current: int, max: int):
	current_actions = current
	max_actions = max
	actions_indicator.text = "Acciones: %d/%d" % [current, max]
	
	# Ejemplo de lógica PURAMENTE VISUAL: 
	# Si no hay acciones, ponemos el texto en rojo para dar feedback al jugador.
	if current == 0:
		actions_indicator.modulate = Color.RED
	else:
		actions_indicator.modulate = Color.WHITE

func update_character_stats(name: String, current_hp: int, max_hp: int, armor: int):
	character_name.text = name
	hp_bar.max_value = max_hp
	hp_bar.value = current_hp
	hp_text.text = "%d / %d" % [current_hp, max_hp]
	armor_text.text = "Armadura: %d" % armor

func update_turn_info(player_name: String, is_player_turn: bool):
	turn_indicator.text = "Turno: %s" % player_name
	# Feedback visual: verde si es tu turno, gris si es el del oponente/espera.
	turn_indicator.modulate = Color.GREEN if is_player_turn else Color.GRAY


# 4. BLOQUE DE PRUEBAS (Simulación)
# ESTO ES ORO PURO PARA TU FLUJO DE TRABAJO.
# Te permite probar y ajustar la UI SIN esperar a que la Persona 1 o 2 
# terminen el TurnManager o el NetworkManager.
func _input(event):
	if event is InputEventKey and event.pressed:
		# Evita que la consola de Godot capture la tecla si el editor tiene el foco
		if !Engine.is_editor_hint(): 
			if event.keycode == KEY_T:
				print("UI: Simulando cambio de turno...")
				update_turn_info("Jugador 2 (Oponente)", false)
			elif event.keycode == KEY_A:
				print("UI: Simulando gasto de acción...")
				update_actions(max(0, current_actions - 1), max_actions)
			elif event.keycode == KEY_R:
				print("UI: Simulando reinicio de turno...")
				update_actions(2, 2)
				update_turn_info("Jugador 1 (Tú)", true)
			elif event.keycode == KEY_D:
				print("UI: Simulando cambio de estadísticas (ej. recibir daño)...")
				update_character_stats("Guerrero", 65, 100, 2)
