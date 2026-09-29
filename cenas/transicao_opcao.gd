extends CanvasLayer

static var em_andamento := false

func iniciar(destino: String, _rotulo: String, cor_acento: Color) -> void:
	if em_andamento:
		queue_free()
		return
	em_andamento = true
	layer = 200
	# Deixa o recurso pronto antes de fechar a tela. Assim a troca não precisa
	# carregar arquivos durante o instante em que a máscara está parada.
	var cena_carregada := ResourceLoader.load(destino, "PackedScene", ResourceLoader.CACHE_MODE_REUSE) as PackedScene
	if not cena_carregada:
		em_andamento = false
		queue_free()
		return
	await get_tree().create_timer(0.48).timeout
	if not is_inside_tree():
		em_andamento = false
		return
	var tamanho_tela: Vector2 = get_viewport().get_visible_rect().size
	var margem: float = maxf(tamanho_tela.x, tamanho_tela.y) * 0.75
	var posicao_fechada: float = tamanho_tela.x + margem * 2.0
	var posicao_saida: float = tamanho_tela.x * 2.0 + margem * 4.0
	var fundo := Polygon2D.new()
	# A máscara ultrapassa bastante todos os lados. Mesmo durante o frame exato
	# da troca não sobra nenhum pixel da cena anterior ou da próxima exposto.
	fundo.polygon = PackedVector2Array([
		Vector2(-tamanho_tela.x - margem * 2.0, -margem),
		Vector2(-margem, -margem),
		Vector2(margem, tamanho_tela.y + margem),
		Vector2(-tamanho_tela.x - margem * 3.0, tamanho_tela.y + margem)
	])
	fundo.color = Color("07162d")
	add_child(fundo)
	var corte := Polygon2D.new()
	corte.polygon = PackedVector2Array([
		Vector2(-margem - 50.0, -margem), Vector2(-margem, -margem),
		Vector2(margem, tamanho_tela.y + margem), Vector2(margem - 50.0, tamanho_tela.y + margem)
	])
	corte.color = cor_acento
	add_child(corte)
	var corte_fino := Polygon2D.new()
	corte_fino.polygon = PackedVector2Array([
		Vector2(-margem + 10.0, -margem), Vector2(-margem + 22.0, -margem),
		Vector2(margem + 22.0, tamanho_tela.y + margem), Vector2(margem + 10.0, tamanho_tela.y + margem)
	])
	corte_fino.color = Color.WHITE
	add_child(corte_fino)
	fundo.position.x = -margem
	corte.position.x = -margem
	corte_fino.position.x = -margem
	var entrada := create_tween().set_parallel(true)
	entrada.tween_property(fundo, "position:x", posicao_fechada, 0.68).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	entrada.tween_property(corte, "position:x", posicao_fechada, 0.72).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	entrada.tween_property(corte_fino, "position:x", posicao_fechada, 0.76).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	await entrada.finished
	var erro := get_tree().change_scene_to_packed(cena_carregada)
	if erro != OK:
		em_andamento = false
		queue_free()
		return
	# Abre no instante exato em que a árvore confirma a nova cena, sem timer ou
	# frame vazio entre o fechamento e a saída da máscara.
	await get_tree().scene_changed
	var saida := create_tween().set_parallel(true)
	saida.tween_property(fundo, "position:x", posicao_saida, 0.68).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	saida.tween_property(corte, "position:x", posicao_saida, 0.64).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	saida.tween_property(corte_fino, "position:x", posicao_saida, 0.6).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	await saida.finished
	em_andamento = false
	queue_free()
