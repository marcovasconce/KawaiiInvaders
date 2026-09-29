extends Node

func _ready() -> void:
	var menu = preload("res://cenas/tela_inicial.tscn").instantiate()
	add_child(menu)
	await get_tree().process_frame
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png("res://.godot/menu_preview.png")
	print("CAPTURA SALVA: res://.godot/menu_preview.png")
	get_tree().quit()
