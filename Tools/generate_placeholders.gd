@tool
extends EditorScript

func _run():
	var placeholder_dir = "res://assets/placeholders/"
	DirAccess.make_dir_recursive_absolute(placeholder_dir)
	
	var placeholders = {
		"player_placeholder.png": Color(0.2, 0.5, 0.9), 
		"enemy_placeholder.png": Color(0.9, 0.3, 0.3),  
		"wall_placeholder.png": Color(1.0, 1.0, 1.0, 1.0),   
		"floor_placeholder.png": Color(0.2, 0.2, 0.2),  
		"weapon_placeholder.png": Color(0.9, 0.8, 0.2), 
		"potion_placeholder.png": Color(0.2, 0.9, 0.5),
		"walk_placeholder.png": Color(1.0, 0.5, 0.0)   # NUEVO: naranja para rango
	}
	
	for file_name in placeholders:
		var color = placeholders[file_name]
		var image = Image.create(32, 32, false, Image.FORMAT_RGBA8)
		image.fill(color)
		
		# Borde de 1px para que se note la cuadrícula
		for i in range(32):
			image.set_pixel(i, 0, Color.BLACK)
			image.set_pixel(i, 31, Color.BLACK)
			image.set_pixel(0, i, Color.BLACK)
			image.set_pixel(31, i, Color.BLACK)
			
		image.save_png(placeholder_dir + file_name)
		
	print("Placeholders generados en: ", placeholder_dir)
