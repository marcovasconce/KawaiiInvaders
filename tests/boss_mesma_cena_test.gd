extends Node

func _ready() -> void:
	var fase = preload("res://cenas/main.tscn").instantiate()
	add_child(fase)
	await get_tree().process_frame
	fase.get_node("jogador").transformar_em_makoto(false)
	fase.get_node("grupoAliens")._mostrar_final()
	await get_tree().process_frame
	var encontro = fase.get_node("BossArena")
	assert(encontro.jogador == fase.get_node("jogador"))
	assert(fase.get_node("FundoEspacial").get_parent() == fase)
	assert(not encontro.has_node("FundoEspacial"))
	assert(not encontro.has_node("jogador"))
	assert(fase.get_node("jogador").na_arena_boss)
	await get_tree().create_timer(3.2).timeout
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png("res://.godot/boss_entrada_dramatica.png")
	await get_tree().create_timer(2.75).timeout
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png("res://.godot/boss_impacto_preview.png")
	await get_tree().create_timer(1.2).timeout
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png("res://.godot/boss_mesma_cena_preview.png")
	assert(encontro.boss.ativo)
	assert(not encontro.tremor_ativo)
	assert(not encontro.entrada_efeitos.ativo)
	fase.queue_free()
	await get_tree().process_frame
	get_tree().set_meta("reiniciar_boss_na_fase", true)
	var reinicio = preload("res://cenas/main.tscn").instantiate()
	add_child(reinicio)
	assert(reinicio.has_node("BossArena"))
	assert(reinicio.get_node("BossArena").jogador == reinicio.get_node("jogador"))
	assert(not get_tree().has_meta("reiniciar_boss_na_fase"))
	print("BOSS NA MESMA CENA: OK")
	get_tree().quit()
