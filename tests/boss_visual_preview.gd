extends Node

# Execute esta cena pelo editor para gerar capturas dos estados do combate.
func _ready() -> void:
	var arena = preload("res://cenas/boss_arena.tscn").instantiate()
	arena.espera_antes_aviso = 0.0
	arena.duracao_entrada_boss = 0.1
	add_child(arena)
	await get_tree().create_timer(0.6).timeout
	var boss = arena.get_node("Boss")
	var jogador = arena.get_node("jogador")
	boss.timer_disparo.stop()
	boss.set_physics_process(false)
	jogador.set_physics_process(false)
	jogador.invulneravel = true
	arena.get_node("CanvasLayer/DicasMakoto").hide()
	boss.position = Vector2(127, 68)
	DirAccess.make_dir_recursive_absolute("res://.godot/boss_preview")
	boss.velocity.x = 65.0
	await _capturar("normal")
	jogador.em_dash = true
	jogador.absorver_energia_dash()
	jogador.em_dash = false
	await _capturar("makoto_com_carga")
	jogador.criar_disparo(true)
	var tiro_carregado = arena.get_children()[-1]
	tiro_carregado.get_node("Area2D").set_process(false)
	tiro_carregado.position = Vector2(175, 145)
	await _capturar("tiro_carregado")
	tiro_carregado.queue_free()
	boss.velocity = Vector2.ZERO
	boss.em_furia = true
	boss.em_transicao = true
	boss._animar(boss.Animacao.GRITO)
	await get_tree().create_timer(0.4).timeout
	await _capturar("berserker")
	boss.fase = 2
	boss.em_transicao = false
	boss._animar(boss.Animacao.CONJURAR)
	arena._on_ataque_anunciado("RUPTURA | SAIA DO VERMELHO", 5.0)
	boss._criar_aviso(boss._regioes_fora_passagem(127.0), true, 0.22)
	await get_tree().create_timer(0.3).timeout
	await _capturar("fase_dois_aviso")
	for perigo in get_tree().get_nodes_in_group("perigos_boss"):
		perigo.set_physics_process(false)
		perigo.tempo = perigo.tempo_aviso + 0.05
		perigo.queue_redraw()
	await _capturar("fase_dois_ruptura")
	boss._limpar_perigos()
	boss.em_furia = false
	boss.stunnado = true
	boss._animar(boss.Animacao.STUN)
	arena.tempo_aviso_ataque = 0.0
	await _capturar("stun")
	boss.stunnado = false
	boss._animar(boss.Animacao.CONJURAR)
	boss._criar_tiro(Vector2(90, 135), Vector2.DOWN, 0.0, false, true)
	boss._criar_tiro(Vector2(165, 135), Vector2.DOWN, 0.0)
	await _capturar("cristal_e_bastao")
	arena.queue_free()
	await get_tree().process_frame
	for tipo in ["vitoria", "derrota"]:
		var resultado = load("res://cenas/%s_makoto.tscn" % tipo).instantiate()
		add_child(resultado)
		await get_tree().process_frame
		await _capturar(tipo + "_makoto")
		resultado.queue_free()
		await get_tree().process_frame
	print("CAPTURAS SALVAS: res://.godot/boss_preview")
	get_tree().quit()

func _capturar(nome: String) -> void:
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png("res://.godot/boss_preview/" + nome + ".png")
