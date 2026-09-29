extends Node

func _ready() -> void:
	for nome in ["vitoria_makoto", "derrota_makoto", "vitoria_hello_kitty", "game_over"]:
		var resultado = load("res://cenas/" + nome + ".tscn").instantiate()
		add_child(resultado)
		await get_tree().create_timer(0.3).timeout
		await _capturar(nome + "_entrada")
		await get_tree().create_timer(0.7).timeout
		await _capturar(nome + "_final")
		resultado.queue_free()
		await get_tree().process_frame
	get_tree().quit()

func _capturar(nome: String) -> void:
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png("res://.godot/" + nome + ".png")
