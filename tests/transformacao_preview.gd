extends Node

func _ready() -> void:
	var fase = preload("res://cenas/main.tscn").instantiate()
	add_child(fase)
	await get_tree().process_frame
	var jogador = fase.get_node("jogador")
	jogador.mostrar_dicas_ao_transformar = false
	jogador.transformar_em_makoto()
	await get_tree().create_timer(0.3).timeout
	await _capturar("transformacao_meio")
	await get_tree().create_timer(0.7).timeout
	await _capturar("transformacao_final")
	get_tree().quit()

func _capturar(nome: String) -> void:
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png("res://.godot/" + nome + ".png")
