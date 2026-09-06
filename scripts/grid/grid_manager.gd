extends Node
## GridManager: Autoload responsable de la lógica matemática del tablero.
## No usa class_name porque es un Singleton (Autoload).

## Señal emitida cuando el tablero está listo para usarse
signal grid_initialized

@export_group("Configuración del Tablero")
## Tamaño en píxeles de cada casilla (para traducción visual futura)
@export var cell_size: int = 64
@export var grid_width: int = 10
@export var grid_height: int = 10

## Diccionario que mapea Vector2i -> GridCell
var cells: Dictionary = {}

func _ready():
	initialize_grid()

func initialize_grid():
	cells.clear()
	for x in range(grid_width):
		for y in range(grid_height):
			var pos = Vector2i(x, y)
			# GridCell sí tiene class_name, por lo que podemos instanciarlo con .new()
			var cell = GridCell.new(pos)
			cells[pos] = cell
			
	print("[GridManager] Tablero lógico de %dx%d inicializado." % [grid_width, grid_height])
	emit_signal("grid_initialized")

# --- CONVERSIÓN DE COORDENADAS ---

## Convierte una posición de píxeles (Vector2) a casilla lógica (Vector2i)
func world_to_grid(world_pos: Vector2) -> Vector2i:
	return Vector2i(floori(world_pos.x / cell_size), floori(world_pos.y / cell_size))

## Convierte una casilla lógica (Vector2i) al centro visual en píxeles (Vector2)
func grid_to_world(grid_pos: Vector2i) -> Vector2:
	var half_cell = cell_size / 2.0
	return Vector2(grid_pos.x * cell_size + half_cell, grid_pos.y * cell_size + half_cell)

# --- VALIDACIONES Y CONSULTAS ---

func is_valid_position(pos: Vector2i) -> bool:
	return cells.has(pos)

func get_cell(pos: Vector2i) -> GridCell:
	if is_valid_position(pos):
		return cells[pos]
	return null

func is_walkable(pos: Vector2i) -> bool:
	var cell = get_cell(pos)
	if cell == null: return false
	return cell.is_walkable and not cell.is_occupied()

# --- GESTIÓN DE OCUPANTES ---

func set_occupant(pos: Vector2i, entity_id: String) -> void:
	var cell = get_cell(pos)
	if cell:
		cell.occupant_id = entity_id

func clear_occupant(pos: Vector2i) -> void:
	var cell = get_cell(pos)
	if cell:
		cell.occupant_id = ""
