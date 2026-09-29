extends Control

## Senal emitida cuando el jugador presiona el boton de fin de turno
signal end_turn_requested

@onready var end_turn_button: Button = $EndTurnButton

func _ready():
	# Hacer que este Control ignore el mouse (como el HUD)
	# pero los botones hijos SI capturen el clic
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	
	if end_turn_button:
		end_turn_button.pressed.connect(_on_end_turn_pressed)
		# El boton SI debe capturar el clic
		end_turn_button.mouse_filter = Control.MOUSE_FILTER_STOP

func _on_end_turn_pressed():
	emit_signal("end_turn_requested")
	print("[TouchControls] Boton Fin de Turno presionado")
