extends Node

func _ready() -> void:
	var transicao = preload("res://cenas/transicao_resultado.gd").new()
	get_tree().root.add_child(transicao)
	transicao.iniciar("res://cenas/vitoria_makoto.tscn", true, true)
	await get_tree().create_timer(0.34).timeout
	await _capturar("transicao_resultado_corte")
	await get_tree().create_timer(0.58).timeout
	await _capturar("transicao_resultado_abertura")
	await get_tree().create_timer(0.75).timeout
	await _capturar("transicao_resultado_pronto")
	var derrota_kitty = preload("res://cenas/transicao_resultado.gd").new()
	get_tree().root.add_child(derrota_kitty)
	derrota_kitty.iniciar("res://cenas/game_over.tscn", false, false)
	await get_tree().create_timer(0.91).timeout
	await _capturar("transicao_kitty_derrota_corte")
	await get_tree().create_timer(1.0).timeout
	await _capturar("transicao_kitty_derrota_final")
	get_tree().quit()

func _capturar(nome: String) -> void:
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png("res://.godot/" + nome + ".png")
