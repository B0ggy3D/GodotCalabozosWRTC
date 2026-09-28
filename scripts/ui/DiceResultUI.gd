extends CanvasLayer

@onready var overlay: ColorRect = $Overlay
@onready var dice_title: Label = $Overlay/DicePanel/VBoxContainer/DiceTitle
@onready var dice_value: Label = $Overlay/DicePanel/VBoxContainer/DiceValue
@onready var result_text: Label = $Overlay/DicePanel/VBoxContainer/ResultText

var is_showing: bool = false

signal _mock_dice_roll(result: DiceRollResult)

func _ready():
	overlay.visible = false
	_mock_dice_roll.connect(_on_dice_rolled)
	_test_mock_data()

func _on_dice_rolled(result: DiceRollResult):
	is_showing = true
	overlay.visible = true
	
	dice_title.text = "%s ataca a %s" % [result.attacker_name, result.target_name]
	dice_value.text = str(result.roll_value)
	
	if result.is_miss:
		result_text.text = "¡FALLO!"
		result_text.modulate = Color.RED
	elif result.is_critical:
		result_text.text = "¡CRÍTICO! (%d daño)" % result.final_damage
		result_text.modulate = Color.GOLD
	else:
		result_text.text = "¡ÉXITO! (%d daño)" % result.final_damage
		result_text.modulate = Color.GREEN

func hide_result():
	is_showing = false
	overlay.visible = false

func _input(event):
	if is_showing and event is InputEventMouseButton and event.pressed:
		hide_result()

func _test_mock_data():
	await get_tree().create_timer(1.0).timeout
	
	var mock = DiceRollResult.new()
	mock.attacker_name = "Guerrero"
	mock.target_name = "Goblin"
	
	# Prueba 1: CRÍTICO
	mock.roll_value = 20
	mock.is_critical = true
	mock.is_miss = false
	mock.final_damage = 12
	mock.remaining_actions = 1
	_mock_dice_roll.emit(mock)
	await get_tree().create_timer(3.0).timeout
	hide_result()
	
	# Prueba 2: ÉXITO
	mock.roll_value = 14
	mock.is_critical = false
	mock.is_miss = false
	mock.final_damage = 6
	_mock_dice_roll.emit(mock)
	await get_tree().create_timer(3.0).timeout
	hide_result()
	
	# Prueba 3: FALLO
	mock.roll_value = 3
	mock.is_critical = false
	mock.is_miss = true
	mock.final_damage = 0
	_mock_dice_roll.emit(mock)
