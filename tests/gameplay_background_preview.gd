extends Node

func _ready() -> void:
	var fase = preload("res://cenas/main.tscn").instantiate()
	add_child(fase)
	await _capturar("fase_aliens")
	fase.get_node("FundoEspacial").ativar_modo_makoto()
	await _capturar("fase_makoto")
	fase.queue_free()
	await get_tree().process_frame
	var arena = preload("res://cenas/boss_arena.tscn").instantiate()
	arena.espera_antes_aviso = 99.0
	add_child(arena)
	await _capturar("arena_tung")
	get_tree().quit()

func _capturar(nome: String) -> void:
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png("res://.godot/" + nome + "_preview.png")
