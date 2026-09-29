extends Node2D
## GameBoardVisual: Dibuja el tablero usando placeholders.
## REGLA ESTRICTA: pared = blanco, suelo = gris. Siempre sincronizado con GridManager.

signal cell_clicked(grid_pos: Vector2i)

@export var floor_texture: Texture2D = null
@export var wall_texture: Texture2D = null
@export var walk_texture: Texture2D = null

var cell_size: int = 64
var cell_sprites: Dictionary = {}
var highlight_sprites: Dictionary = {}
var attack_sprites: Dictionary = {}

func _ready():
	if floor_texture == null:
		floor_texture = load("res://assets/placeholders/floor_placeholder.png")
	if wall_texture == null:
		wall_texture = load("res://assets/placeholders/wall_placeholder.png")
	if walk_texture == null:
		walk_texture = load("res://assets/placeholders/walk_placeholder.png")
	
	cell_size = GridManager.cell_size
	
	if GridManager.cells.is_empty():
		GridManager.grid_initialized.connect(_build_board)
	else:
		_build_board()
	
	# Garantizar sincronizacion estricta pared/suelo
	sync_all_cells()

func _build_board():
	for child in get_children():
		child.queue_free()
	cell_sprites.clear()
	highlight_sprites.clear()
	attack_sprites.clear()
	
	for grid_pos in GridManager.cells:
		var cell: GridCell = GridManager.cells[grid_pos]
		var sprite = Sprite2D.new()
		sprite.texture = floor_texture if cell.is_walkable else wall_texture
		sprite.position = GridManager.grid_to_world(grid_pos)
		var sf = float(cell_size) / 32.0
		sprite.scale = Vector2(sf, sf)
		cell_sprites[grid_pos] = sprite
		add_child(sprite)
	
	print("[GameBoardVisual] Tablero visual de %d casillas creado." % cell_sprites.size())

## Fuerza que cada sprite coincida con is_walkable de su celda.
## Elimina cualquier "pared falsa" o desincronizacion visual.
func sync_all_cells():
	for grid_pos in GridManager.cells:
		var cell: GridCell = GridManager.cells[grid_pos]
		if cell_sprites.has(grid_pos):
			cell_sprites[grid_pos].texture = floor_texture if cell.is_walkable else wall_texture

func _unhandled_input(event):
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		var world_pos = get_global_mouse_position()
		var grid_pos = GridManager.world_to_grid(world_pos)
		if GridManager.is_valid_position(grid_pos):
			emit_signal("cell_clicked", grid_pos)

func update_cell(grid_pos: Vector2i, is_walkable: bool):
	if cell_sprites.has(grid_pos):
		cell_sprites[grid_pos].texture = floor_texture if is_walkable else wall_texture

# --- Highlight de MOVIMIENTO (naranja) ---
func show_movement_range(cells: Array[Vector2i]):
	clear_highlights()
	for grid_pos in cells:
		var sprite = Sprite2D.new()
		sprite.texture = walk_texture
		sprite.position = GridManager.grid_to_world(grid_pos)
		var sf = float(cell_size) / 32.0
		sprite.scale = Vector2(sf, sf)
		sprite.modulate = Color(1, 1, 1, 0.45)
		highlight_sprites[grid_pos] = sprite
		add_child(sprite)

func clear_highlights():
	for g in highlight_sprites:
		highlight_sprites[g].queue_free()
	highlight_sprites.clear()

# --- Highlight de ATAQUE (rojo tenue, se pinta SOBRE enemigos) ---
func show_attack_range(cells: Array[Vector2i]):
	clear_attack_highlights()
	for grid_pos in cells:
		var sprite = Sprite2D.new()
		sprite.texture = walk_texture
		sprite.position = GridManager.grid_to_world(grid_pos)
		var sf = float(cell_size) / 32.0
		sprite.scale = Vector2(sf, sf)
		sprite.modulate = Color(1.0, 0.2, 0.2, 0.35)
		attack_sprites[grid_pos] = sprite
		add_child(sprite)

func clear_attack_highlights():
	for g in attack_sprites:
		attack_sprites[g].queue_free()
	attack_sprites.clear()
