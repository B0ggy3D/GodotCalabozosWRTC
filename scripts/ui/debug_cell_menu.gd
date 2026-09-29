extends Control
## Menu contextual de debug autocontenido.
## Se abre con clic derecho sobre una casilla del tablero.
## Permite modificar el contenido de la celda.

signal option_selected(option: String, grid_pos: Vector2i)

var current_cell: Vector2i = Vector2i.ZERO
var is_open: bool = false

var panel: PanelContainer
var buttons: Dictionary = {}

func _ready():
	visible = false
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	
	# Construir panel y botones por codigo
	panel = PanelContainer.new()
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(panel)
	
	var vbox = VBoxContainer.new()
	vbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_child(vbox)
	
	buttons["add_enemy"] = _make_button(vbox, "Añadir Enemigo")
	buttons["add_ally"] = _make_button(vbox, "Añadir Aliado")
	buttons["toggle_wall"] = _make_button(vbox, "Poner/Quitar Pared")
	buttons["remove_entity"] = _make_button(vbox, "Quitar Entidad")
	buttons["close"] = _make_button(vbox, "Cerrar")
	
	buttons["add_enemy"].pressed.connect(func(): _emit("add_enemy"))
	buttons["add_ally"].pressed.connect(func(): _emit("add_ally"))
	buttons["toggle_wall"].pressed.connect(func(): _emit("toggle_wall"))
	buttons["remove_entity"].pressed.connect(func(): _emit("remove_entity"))
	buttons["close"].pressed.connect(close)

func _make_button(parent: Node, text: String) -> Button:
	var b = Button.new()
	b.text = text
	b.mouse_filter = Control.MOUSE_FILTER_STOP
	b.custom_minimum_size = Vector2(180, 40)
	parent.add_child(b)
	return b

func open_at(grid_pos: Vector2i, screen_pos: Vector2):
	current_cell = grid_pos
	is_open = true
	visible = true
	position = screen_pos
	
	var cell = GridManager.get_cell(grid_pos)
	if cell:
		buttons["toggle_wall"].text = "Quitar Pared" if not cell.is_walkable else "Poner Pared"
		var occupied = cell.is_occupied()
		buttons["remove_entity"].disabled = not occupied
		buttons["add_enemy"].disabled = occupied
		buttons["add_ally"].disabled = occupied

func close():
	is_open = false
	visible = false

func _emit(option: String):
	emit_signal("option_selected", option, current_cell)
	close()

func _unhandled_input(event):
	if is_open and event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		close()
		get_viewport().set_input_as_handled()
	elif is_open and event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
		close()
		get_viewport().set_input_as_handled()
