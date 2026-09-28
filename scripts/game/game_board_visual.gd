extends Node2D
## GameBoardVisual: Dibuja el tablero de juego usando los placeholders.
## Lee el estado del GridManager (Autoload de Persona 1) y crea
## un Sprite2D por cada casilla del tablero.
##
## RESPONSABILIDADES:
## - Renderizar suelo y paredes
## - Capturar clics del mouse y traducirlos a coordenadas de grid
## - Emitir senales cuando el jugador hace clic en una casilla
##
## NO RESPONSABLE DE:
## - Validar movimientos (eso lo hace GridManager/CharacterController)
## - Dibujar personajes (eso lo hace EntityVisual)
## - Logica de combate, turnos, ni red

## Emitida cuando el jugador hace clic en una casilla del tablero
signal cell_clicked(grid_pos: Vector2i)

## Texturas de placeholders (asignadas desde el editor o por codigo)
@export var floor_texture: Texture2D = null
@export var wall_texture: Texture2D = null

## Tamano de cada casilla en pixeles (debe coincidir con GridManager.cell_size)
var cell_size: int = 64

## Diccionario de sprites de casillas: Vector2i -> Sprite2D
var cell_sprites: Dictionary = {}

func _ready():
	# Cargar texturas si no fueron asignadas en el editor
	if floor_texture == null:
		floor_texture = load("res://assets/placeholders/floor_placeholder.png")
	if wall_texture == null:
		wall_texture = load("res://assets/placeholders/wall_placeholder.png")
	
	# Obtener el tamano de casilla del GridManager
	cell_size = GridManager.cell_size
	
	# Esperar a que el grid este inicializado
	if GridManager.cells.is_empty():
		GridManager.grid_initialized.connect(_build_board)
	else:
		_build_board()

func _build_board():
	# Limpiar sprites anteriores
	for child in get_children():
		child.queue_free()
	cell_sprites.clear()
	
	# Crear un sprite por cada casilla del grid
	for grid_pos in GridManager.cells:
		var cell: GridCell = GridManager.cells[grid_pos]
		var sprite = Sprite2D.new()
		
		# Elegir textura segun el tipo de casilla
		if cell.is_walkable:
			sprite.texture = floor_texture
		else:
			sprite.texture = wall_texture
		
		# Posicionar en el centro de la casilla
		sprite.position = GridManager.grid_to_world(grid_pos)
		
		# Escalar el placeholder (32x32) al tamano de la casilla (64x64)
		var scale_factor = float(cell_size) / 32.0
		sprite.scale = Vector2(scale_factor, scale_factor)
		
		# Guardar referencia
		cell_sprites[grid_pos] = sprite
		add_child(sprite)
	
	print("[GameBoardVisual] Tablero visual de %d casillas creado." % cell_sprites.size())

func _unhandled_input(event):
	## Capturar clics del mouse para seleccionar casillas
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		var world_pos = get_global_mouse_position()
		var grid_pos = GridManager.world_to_grid(world_pos)
		
		if GridManager.is_valid_position(grid_pos):
			emit_signal("cell_clicked", grid_pos)

## Actualiza la textura de una casilla (ej: cuando se convierte en pared)
func update_cell(grid_pos: Vector2i, is_walkable: bool):
	if cell_sprites.has(grid_pos):
		var sprite: Sprite2D = cell_sprites[grid_pos]
		sprite.texture = floor_texture if is_walkable else wall_texture

## Resalta una casilla (util para mostrar movimientos validos)
func highlight_cell(grid_pos: Vector2i, color: Color = Color(0.3, 0.8, 0.3, 0.4)):
	if cell_sprites.has(grid_pos):
		cell_sprites[grid_pos].modulate = color

## Quita el resaltado de todas las casillas
func clear_highlights():
	for grid_pos in cell_sprites:
		cell_sprites[grid_pos].modulate = Color.WHITE
