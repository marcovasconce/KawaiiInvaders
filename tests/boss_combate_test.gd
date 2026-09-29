extends SceneTree

var falhas := 0

func _initialize() -> void:
	call_deferred("_executar")

func verificar(condicao: bool, mensagem: String) -> void:
	if condicao:
		print("OK: " + mensagem)
	else:
		falhas += 1
		push_error("FALHOU: " + mensagem)

func _executar() -> void:
	var arena = load("res://cenas/boss_arena.tscn").instantiate()
	arena.espera_antes_aviso = 9999.0
	# O cenario de teste nao precisa das centenas de blocos do chao.
	arena.get_node("chao").free()
	root.add_child(arena)
	await process_frame
	var boss = arena.get_node("Boss")
	var jogador = arena.get_node("jogador")
	jogador.invulneravel = true
	jogador.set_physics_process(false)
	boss.visible = true
	boss.position = Vector2(127, 48)
	boss.duracao_grito = 0.1
	boss.duracao_stun = 0.25
	boss.ativar_combate()
	boss.set_physics_process(false)
	boss.timer_disparo.stop()
	boss.receber_ataque(29, 0)
	verificar(not boss.em_furia, "29 de dano ainda nao ativam berserker")
	boss.receber_ataque(1, 0)
	verificar(boss.em_furia and boss.em_transicao, "30 de dano ativam grito e berserker")
	boss.receber_ataque(20, 100)
	verificar(boss.vida_atual == 270 and not boss.stunnado, "transicao do grito nao pode ser interrompida por dano")
	await create_timer(0.18).timeout
	boss.timer_disparo.stop()
	verificar(not boss.em_transicao and boss.em_furia, "berserker persiste depois do grito")
	verificar(boss._cadencia() < 1.0 and boss.multiplicador_velocidade_furia > 1.0, "furia acelera cadencia e perseguicao")
	boss.receber_ataque(1, 100)
	verificar(boss.stunnado and not boss.em_furia, "quebrar postura encerra berserker")
	boss.receber_ataque(2, 0)
	verificar(boss.vida_atual == 263, "golpe de 2 causa 6 no stun")
	await create_timer(0.35).timeout
	boss.timer_disparo.stop()
	verificar(not boss.stunnado and boss.postura_atual == 0 and not boss.em_furia, "recuperacao limpa postura e nao reativa furia imediatamente")
	boss.receber_ataque(113, 0)
	verificar(boss.fase == 2 and boss.em_transicao, "50% de vida inicia segunda fase")
	await create_timer(0.18).timeout
	boss.timer_disparo.stop()
	for padrao in range(3):
		boss._executar_global(padrao)
		await create_timer(1.12).timeout
		verificar(get_nodes_in_group("perigos_boss").size() > 0, "padrao global %d gera perigos depois do aviso" % padrao)
		if padrao < 2:
			var cristais := 0
			var todos_sem_parry := true
			for perigo_ativo in get_nodes_in_group("perigos_boss"):
				if perigo_ativo.has_method("refletir_para_boss"):
					cristais += 1
					todos_sem_parry = todos_sem_parry and not perigo_ativo.permite_parry
			verificar(cristais > 0 and todos_sem_parry, "padrao %d usa cristais impossiveis de aparar" % padrao)
			if padrao == 1:
				verificar(cristais == 4, "espiral solta quatro projeteis na primeira onda")
		boss.aplicar_stun()
		await process_frame
		verificar(get_nodes_in_group("perigos_boss").is_empty(), "stun limpa os perigos do padrao %d" % padrao)
		await create_timer(0.6).timeout
		boss.timer_disparo.stop()
		verificar(get_nodes_in_group("perigos_boss").is_empty(), "sequencia cancelada %d nao volta a disparar" % padrao)
	# Deixa cada padrao terminar para verificar tambem a recuperacao.
	boss.intervalo_entre_ataques = 100.0
	for padrao in range(3):
		boss._executar_global(padrao)
		await create_timer(5.0).timeout
		boss.timer_disparo.stop()
		verificar(not boss.atacando, "padrao %d termina e devolve controle ao boss" % padrao)
		boss._limpar_perigos()
		await process_frame
	# O parry do primeiro ainda cobre os outros projeteis da mesma rajada.
	jogador.invulneravel = false
	jogador.esta_no_parry = true
	jogador.flash_branco = null
	var tiros: Array[Node] = []
	for i in range(3):
		var tiro = load("res://cenas/boss_tiro.tscn").instantiate()
		tiro.id_rajada = 1000
		tiro.rajada_tripla = true
		tiro.velocidade = 0.0
		arena.add_child(tiro)
		tiro.position = Vector2(20 + i * 20, 110)
		tiros.append(tiro)
	tiros[0]._on_body_entered(jogador)
	jogador.esta_no_parry = false
	await physics_frame
	await physics_frame
	verificar(tiros[0].refletido and tiros[1].refletido and tiros[2].refletido, "auto-parry reflete a rajada inteira")
	jogador.invulneravel = true
	boss._limpar_perigos()
	await process_frame
	# O contato de um cristal durante o dash prepara exatamente o proximo tiro.
	var cristal = load("res://cenas/boss_chuva_tiro.tscn").instantiate()
	cristal.velocidade = 0.0
	arena.add_child(cristal)
	cristal.position = Vector2(20, 110)
	jogador.em_dash = true
	cristal._on_body_entered(jogador)
	verificar(jogador.tiro_carregado_pronto and not jogador.morrendo, "dash atraves do cristal carrega o Makoto")
	jogador.em_dash = false
	await process_frame
	jogador.criar_disparo(true)
	var tiro_carregado = arena.get_children()[-1].get_node("Area2D")
	verificar(tiro_carregado.tiro_carregado and tiro_carregado.dano_impacto == jogador.dano_tiro_carregado, "primeiro tiro vira disparo carregado")
	verificar(not jogador.tiro_carregado_pronto, "carga e consumida no primeiro tiro")
	var vida_antes_carga: int = boss.vida_atual
	tiro_carregado._on_body_entered(boss)
	verificar(boss.vida_atual == vida_antes_carga - jogador.dano_tiro_carregado, "tiro carregado causa dano extra ao boss")
	await process_frame
	jogador.criar_disparo(true)
	var tiro_seguinte = arena.get_children()[-1].get_node("Area2D")
	verificar(tiro_seguinte.dano_impacto == 1 and not tiro_seguinte.tiro_carregado, "tiro seguinte volta ao normal")
	verificar(not jogador.absorver_energia_dash(), "sem dash nao recarrega")
	tiro_seguinte.get_parent().queue_free()
	await process_frame
	# Morte cancela ataques e reproduz a animacao antes de emitir vitoria.
	boss.receber_ataque(9999, 0)
	verificar(boss.morrendo and not boss.ativo, "morte interrompe combate")
	await create_timer(1.12).timeout
	verificar(not is_instance_valid(boss), "boss conclui animacao de derrota")
	# Area real: aviso nao mata; durante dash nao mata; depois dos i-frames mata.
	jogador.invulneravel = false
	jogador.dash_disponivel = true
	jogador.iniciar_dash(1.0)
	var perigo = load("res://cenas/boss_perigo.tscn").instantiate()
	perigo.regioes = [Rect2(80, 160, 100, 45)] as Array[Rect2]
	perigo.tempo_aviso = 0.06
	perigo.tempo_ativo = 0.5
	arena.add_child(perigo)
	await create_timer(0.035).timeout
	verificar(not jogador.morrendo, "aviso de coluna nao causa dano")
	await create_timer(0.09).timeout
	verificar(jogador.esta_invulneravel() and not jogador.morrendo, "dash protege contra coluna ativa")
	await create_timer(0.20).timeout
	verificar(jogador.morrendo, "coluna volta a causar dano depois dos i-frames")
	arena.queue_free()
	await process_frame
	await process_frame
	print("RESULTADO: %d falhas" % falhas)
	quit(1 if falhas > 0 else 0)
