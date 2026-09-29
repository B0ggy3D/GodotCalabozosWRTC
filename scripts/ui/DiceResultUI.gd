extends CanvasLayer

@onready var overlay: ColorRect = $Overlay if has_node("Overlay") else null
@onready var dice_title: Label = $Overlay/DicePanel/VBoxContainer/DiceTitle if has_node("Overlay/DicePanel/VBoxContainer/DiceTitle") else null
@onready var dice_value: Label = $Overlay/DicePanel/VBoxContainer/DiceValue if has_node("Overlay/DicePanel/VBoxContainer/DiceValue") else null
@onready var result_text: Label = $Overlay/DicePanel/VBoxContainer/ResultText if has_node("Overlay/DicePanel/VBoxContainer/ResultText") else null

var is_showing: bool = false
var hide_timer: Timer = null

signal _mock_dice_roll(result: DiceRollResult)

func _ready():
	if overlay:
		overlay.visible = false
	else:
		push_warning("[DiceResultUI] No se encontro Overlay")
	
	# Timer para auto-ocultar el popup despues de mostrar el resultado
	hide_timer = Timer.new()
	hide_timer.one_shot = true
	hide_timer.wait_time = 2.0
	hide_timer.timeout.connect(hide_result)
	add_child(hide_timer)
	
	_mock_dice_roll.connect(_on_dice_rolled)

func _on_dice_rolled(result: DiceRollResult):
	if not overlay or not dice_title or not dice_value or not result_text:
		return
	
	is_showing = true
	overlay.visible = true
	
	dice_title.text = "%s ataca a %s" % [result.attacker_name, result.target_name]
	dice_value.text = str(result.roll_value)
	
	if result.is_miss:
		result_text.text = "¡FALLO!"
		result_text.modulate = Color.RED
	elif result.is_critical:
		result_text.text = "¡CRITICO! (%d dano)" % result.final_damage
		result_text.modulate = Color.GOLD
	else:
		result_text.text = "¡EXITO! (%d dano)" % result.final_damage
		result_text.modulate = Color.GREEN
	
	# Auto-ocultar despues de 2 segundos
	hide_timer.start()

func hide_result():
	is_showing = false
	if overlay:
		overlay.visible = false
	if hide_timer:
		hide_timer.stop()

func _input(event):
	# Cierre manual con clic (ademas del auto-cierre por timer)
	if is_showing and event is InputEventMouseButton and event.pressed:
		hide_result()
