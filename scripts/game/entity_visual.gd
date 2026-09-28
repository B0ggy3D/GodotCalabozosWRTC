extends Node2D
## EntityVisual: Representacion visual de un personaje o enemigo en el tablero.
## Se posiciona segun la coordenada de grid y puede animar movimientos.
##
## RESPONSABILIDADES:
## - Mostrar el sprite del personaje/enemigo
## - Animar movimientos entre casillas (tween)
## - Mostrar indicador de seleccion
##
## NO RESPONSABLE DE:
## - Logica de movimiento (eso lo hace CharacterController)
## - Combate, turnos, ni red

## Texturas de placeholder
@export var player_texture: Texture2D = null
@export var enemy_texture: Texture2D = null

## Referencia a los datos del personaje (solo lectura para nombre/HP)
var character_data: CharacterInstanceData = null

## Componentes visuales
var sprite: Sprite2D = null
var selection_indicator: Sprite2D = null
var name_label: Label = null

## Estado visual
var is_selected: bool = false
var cell_size: int = 64

func _ready():
	cell_size = GridManager.cell_size
	
	# Cargar texturas
	if player_texture == null:
		player_texture = load("res://assets/placeholders/player_placeholder.png")
	if enemy_texture == null:
		enemy_texture = load("res://assets/placeholders/enemy_placeholder.png")
	
	_create_visual_components()

func _create_visual_components():
	# Sprite principal
	sprite = Sprite2D.new()
	var scale_factor = float(cell_size) / 32.0
	sprite.scale = Vector2(scale_factor, scale_factor)
	add_child(sprite)
	
	# Indicador de seleccion (un marco alrededor)
	selection_indicator = Sprite2D.new()
	selection_indicator.scale = Vector2(scale_factor * 1.15, scale_factor * 1.15)
	selection_indicator.modulate = Color(1.0, 1.0, 0.0, 0.6)
	selection_indicator.visible = false
	# Usar la textura de suelo como base del indicador
	selection_indicator.texture = load("res://assets/placeholders/floor_placeholder.png")
	add_child(selection_indicator)
	# Mover detras del sprite principal
	move_child(selection_indicator, 0)
	
	# Etiqueta de nombre
	name_label = Label.new()
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_label.position = Vector2(-40, -cell_size / 2 - 20)
	name_label.add_theme_font_size_override("font_size", 10)
	add_child(name_label)

## Configura la entidad con datos de personaje
func setup(data: CharacterInstanceData, is_enemy: bool = false):
	character_data = data
	
	# Elegir textura
	if is_enemy:
		sprite.texture = enemy_texture
	else:
		sprite.texture = player_texture
	
	# Nombre
	if name_label:
		name_label.text = data.character_name
	
	# Posicionar segun el grid
	_snap_to_grid()

## Posiciona inmediatamente en la casilla correcta (sin animacion)
func _snap_to_grid():
	if character_data:
		position = GridManager.grid_to_world(character_data.grid_position)

## Anima el movimiento hacia una nueva posicion de grid
func animate_move_to(target_grid_pos: Vector2i, duration: float = 0.3):
	var target_world_pos = GridManager.grid_to_world(target_grid_pos)
	
	var tween = create_tween()
	tween.tween_property(self, "position", target_world_pos, duration)
	tween.set_ease(Tween.EASE_OUT)
	tween.set_trans(Tween.TRANS_CUBIC)
	
	return tween

## Anima el movimiento a lo largo de una ruta completa
func animate_path(path: Array[Vector2i], step_duration: float = 0.15):
	if path.size() < 2:
		return null
	
	var tween = create_tween()
	
	# Animar paso a paso (sin incluir la posicion inicial)
	for i in range(1, path.size()):
		var world_pos = GridManager.grid_to_world(path[i])
		tween.tween_property(self, "position", world_pos, step_duration)
	
	tween.set_ease(Tween.EASE_OUT)
	tween.set_trans(Tween.TRANS_LINEAR)
	
	return tween

## Selecciona/deselecciona visualmente
func set_selected(selected: bool):
	is_selected = selected
	if selection_indicator:
		selection_indicator.visible = selected

## Actualiza la apariencia segun el estado (ej: muerto, danado)
func update_visual_state():
	if character_data == null:
		return
	
	# Parpadear en rojo si tiene poca vida
	if character_data.current_hp <= 0:
		modulate = Color(0.3, 0.3, 0.3, 0.5)
	elif character_data.class_data and character_data.current_hp <= character_data.class_data.max_hp * 0.3:
		sprite.modulate = Color(1.0, 0.6, 0.6)
	else:
		sprite.modulate = Color.WHITE

## Muestra un efecto de dano (parpadeo rojo)
func play_damage_effect():
	var tween = create_tween()
	sprite.modulate = Color.RED
	tween.tween_property(sprite, "modulate", Color.WHITE, 0.3)

## Muestra un efecto de curacion (parpadeo verde)
func play_heal_effect():
	var tween = create_tween()
	sprite.modulate = Color.GREEN
	tween.tween_property(sprite, "modulate", Color.WHITE, 0.3)
