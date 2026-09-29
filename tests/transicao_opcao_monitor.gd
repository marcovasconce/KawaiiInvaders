extends Node

func _ready() -> void:
	await get_tree().create_timer(0.28).timeout
	await _capturar("transicao_opcao_entrada")
	await get_tree().create_timer(0.5).timeout
	await _capturar("transicao_opcao_troca")
	await get_tree().create_timer(0.65).timeout
	await _capturar("transicao_opcao_final")
	get_tree().quit()

func _capturar(nome: String) -> void:
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png("res://.godot/" + nome + ".png")
