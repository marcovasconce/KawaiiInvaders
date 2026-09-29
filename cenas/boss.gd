extends CharacterBody2D

signal vida_alterada(atual: int, maxima: int)
signal postura_alterada(atual: int, maxima: int)
signal ataque_anunciado(texto: String, duracao: float)
signal fase_dois_iniciada(duracao: float)
signal fase_tres_iniciada(duracao: float)
signal derrotado

@export_category("Vida e postura")
@export var vida_maxima := 300
@export var postura_maxima := 100
@export var duracao_stun := 4.0
@export_range(1.0, 8.0, 0.5) var multiplicador_dano_stun := 3.0
@export_range(0.2, 1.0, 0.05) var multiplicador_dano_fase_dois := 0.5
@export_category("Ataques normais")
@export var velocidade_perseguicao := 85.0
@export var intervalo_entre_ataques := 0.78
@export var preparacao_arremesso := 0.34
@export var pausa_apos_arremesso := 0.38
@export var intervalo_entre_tiros_da_rajada := 0.22
@export var tiros_na_rajada := 3
@export var velocidade_animacao := 0.17
@export_category("Berserker")
@export_range(0.05, 0.5, 0.01) var fracao_dano_para_furia := 0.10
@export var multiplicador_velocidade_furia := 1.65
@export var multiplicador_cadencia_furia := 0.65
@export var duracao_grito := 1.3
@export_category("Segunda fase")
@export_range(0.1, 0.9, 0.05) var vida_inicio_fase_dois := 0.5
@export var tempo_aviso_global := 0.62
@export var tempo_aviso_laser := 1.0
@export var largura_passagem_segura := 40.0
@export_range(1, 8, 1) var ondas_espiral := 4
@export_range(0.25, 1.5, 0.05) var intervalo_ondas_espiral := 0.65
@export var velocidade_espiral := 115.0
@export_category("Terceira fase")
@export var vida_fase_tres := 60
@export var velocidade_fase_tres := 14.0
@export var multiplicador_cadencia_fase_tres := 3.5
@export_category("Anti-camping")
@export var tempo_parado_antes_bastao := 1.5
@export var recarga_bastao_subterraneo := 2.6
@export var aviso_bastao_subterraneo := 1.0

enum Animacao { ANDAR, ARREMESSAR, STUN, GRITO, CONJURAR, MORTE }
const CENA_TIRO = preload("res://cenas/boss_tiro.tscn")
const CENA_CRISTAL_CHUVA = preload("res://cenas/boss_chuva_tiro.tscn")
const CENA_PERIGO = preload("res://cenas/boss_perigo.tscn")
const CENA_BASTAO_SUBTERRANEO = preload("res://cenas/bastao_subterraneo.tscn")
const TEXTURA_BASTAO_GRANDE = preload("res://assets]/Assets Space Invades/Sprites/bastao_espinhos_tung.png")
const TEXTURA_TUNG_CANSADO = preload("res://assets]/Assets Space Invades/Sprites/tung_fase3_cansado.png")
# Centro visível medido em cada célula 256x256 da spritesheet.
# Corrige a arte deslocada sem mover colisão, mira ou ponto de disparo.
const DESLOCAMENTO_QUADROS := [
	30.0, 21.0, 15.5, 0.5,
	14.0, 9.0, -1.0, 1.5,
	16.0, 13.5, 5.5, 9.5,
	17.5, 13.5, 3.0, -7.0,
	18.0, 9.0, -2.0, -5.5,
	8.5, 8.5, 0.5, -3.0,
]
var vida_atual := 300
var postura_atual := 0
var ativo := false
var morrendo := false
var stunnado := false
var atacando := false
var em_furia := false
var em_transicao := false
var fase := 1
var dano_desde_stun := 0
var proximo_ataque_em_rajada := true
var geracao_ataque := 0
var identificador_rajada := 0
var indice_padrao := 0
var ultimo_ataque_escolhido := -1
var animacao := Animacao.ANDAR
var tempo_animacao := 0.0
var tempo_aura := 0.0
var flash_dano := 0.0
var ultima_posicao_player_x := NAN
var tempo_player_parado := 0.0
var recarga_bastao_restante := 0.0
var passagem_segura_ativa := false
var centro_passagem_segura := 127.0
var transicao_fase_dois := false

@onready var spawn_point: Marker2D = $SpawnPoint
@onready var timer_disparo: Timer = $TimerDisparo
@onready var sprite: Sprite2D = $Sprite2D

func _ready() -> void:
	vida_atual = vida_maxima
	visible = false
	set_physics_process(false)
	timer_disparo.one_shot = true
	sprite.scale = Vector2.ONE * 72.0 / (float(sprite.texture.get_width()) / 4.0)
	_centralizar_sprite()
	vida_alterada.emit(vida_atual, vida_maxima)
	postura_alterada.emit(postura_atual, postura_maxima)

func preparar_entrada() -> void:
	visible = true
	global_position.y = -55.0

func ativar_combate() -> void:
	ativo = true
	set_physics_process(true)
	timer_disparo.start(intervalo_entre_ataques)
	vida_alterada.emit(vida_atual, vida_maxima)
	postura_alterada.emit(postura_atual, postura_maxima)

func _process(delta: float) -> void:
	if not visible:
		return
	tempo_animacao += delta
	tempo_aura += delta
	flash_dano = maxf(flash_dano - delta, 0.0)
	_atualizar_anti_camping(delta)
	if fase == 3:
		sprite.frame = int(tempo_animacao / 0.52) % 4
		sprite.position.x = 0.0
		# Durante a morte, o tween é o único responsável pela opacidade. Sem
		# isso, este processo restaurava alpha=1 e causava a piscada final.
		if morrendo:
			queue_redraw()
			return
		if flash_dano > 0.0:
			sprite.modulate = Color(1.7, 1.7, 1.7)
		else:
			sprite.modulate = Color(0.82, 0.86, 0.95, 1.0)
		queue_redraw()
		return
	var ritmo := velocidade_animacao
	if em_furia and animacao == Animacao.ANDAR:
		ritmo *= 0.7
	var quadro := int(tempo_animacao / maxf(ritmo, 0.03))
	if animacao in [Animacao.ARREMESSAR, Animacao.MORTE]:
		quadro = mini(quadro, 3)
	else:
		quadro %= 4
	if animacao == Animacao.ANDAR and absf(velocity.x) < 1.0:
		quadro = 0
	sprite.frame = mini(int(animacao) * 4 + quadro, sprite.hframes * sprite.vframes - 1)
	_centralizar_sprite()
	if flash_dano > 0.0:
		sprite.modulate = Color(1.8, 1.8, 1.8)
	elif stunnado:
		sprite.modulate = Color(0.55, 0.85, 1.25)
	elif em_furia:
		sprite.modulate = Color(1.3, 0.6, 0.5)
	else:
		sprite.modulate = Color.WHITE
	queue_redraw()

func _centralizar_sprite() -> void:
	var sinal := 1.0 if sprite.flip_h else -1.0
	sprite.position.x = sinal * roundf(DESLOCAMENTO_QUADROS[sprite.frame] * sprite.scale.x)

func _draw() -> void:
	if not em_furia or morrendo:
		return
	var pulso := 0.5 + 0.5 * sin(tempo_aura * 9.0)
	draw_circle(Vector2(0, -4), 34.0 + pulso * 3.0, Color(1, 0.05, 0.08, 0.09))
	for i in range(12):
		var x := -31.0 + i * 5.6
		var altura := 14.0 + 14.0 * (0.5 + 0.5 * sin(tempo_aura * 11.0 + i * 2.1))
		var pontos := PackedVector2Array([
			Vector2(x - 4, 27), Vector2(x + 4, 27),
			Vector2(x + sin(tempo_aura * 7 + i) * 5, 12 - altura)
		])
		draw_colored_polygon(pontos, Color(1.0, 0.08 + pulso * 0.12, 0.04, 0.38))
	if em_transicao:
		var raio := 25.0 + fmod(tempo_aura * 75.0, 45.0)
		draw_arc(Vector2.ZERO, raio, 0, TAU, 48, Color(1, 0.3, 0.15, 0.7), 2.0)
	if transicao_fase_dois:
		var pulso_fase := 0.5 + 0.5 * sin(tempo_aura * 16.0)
		for anel in range(4):
			var raio_fase := 31.0 + anel * 9.0 + pulso_fase * 5.0
			draw_arc(Vector2(0, -3), raio_fase, 0, TAU, 48, Color(1.0, 0.05 + anel * 0.04, 0.12, 0.62 - anel * 0.1), 2.0)
		for i in range(18):
			var angulo := float(i) * TAU / 18.0 + tempo_aura * (2.0 if i % 2 == 0 else -1.5)
			var origem := Vector2(0, -3) + Vector2.from_angle(angulo) * (32.0 + pulso_fase * 4.0)
			var ponta := origem + Vector2.from_angle(angulo) * (13.0 + pulso_fase * 10.0)
			draw_line(origem, ponta, Color(1.0, 0.12, 0.08, 0.72), 2.0)

func _physics_process(_delta: float) -> void:
	if not ativo or morrendo:
		return
	var jogador := get_tree().get_first_node_in_group("tanque") as Node2D
	if not is_instance_valid(jogador) or jogador.morrendo:
		ativo = false
		_interromper()
		_limpar_perigos()
		return
	if stunnado or atacando or em_transicao:
		return
	var alvo_x := clampf(jogador.global_position.x, 35.0, 219.0)
	var velocidade := velocidade_fase_tres if fase == 3 else velocidade_perseguicao * (multiplicador_velocidade_furia if em_furia else 1.0)
	velocity.x = signf(alvo_x - global_position.x) * velocidade
	if absf(alvo_x - global_position.x) < 2.0:
		velocity.x = 0.0
	elif absf(velocity.x) > 1.0:
		sprite.flip_h = velocity.x < 0.0
	move_and_slide()

func _atualizar_anti_camping(delta: float) -> void:
	recarga_bastao_restante = maxf(recarga_bastao_restante - delta, 0.0)
	if not ativo or morrendo or stunnado or em_transicao or fase == 3:
		tempo_player_parado = 0.0
		ultima_posicao_player_x = NAN
		return
	var jogador := get_tree().get_first_node_in_group("tanque") as Node2D
	if not is_instance_valid(jogador) or jogador.morrendo:
		return
	if passagem_segura_ativa and absf(jogador.global_position.x - centro_passagem_segura) <= largura_passagem_segura * 0.5:
		# Esperar dentro da solução correta de um ataque não é camping.
		tempo_player_parado = 0.0
		ultima_posicao_player_x = jogador.global_position.x
		return
	if is_nan(ultima_posicao_player_x) or absf(jogador.global_position.x - ultima_posicao_player_x) > 4.0:
		tempo_player_parado = 0.0
		ultima_posicao_player_x = jogador.global_position.x
		return
	tempo_player_parado += delta
	if tempo_player_parado >= tempo_parado_antes_bastao and recarga_bastao_restante <= 0.0:
		_invocar_bastao_subterraneo(jogador.global_position.x)
		tempo_player_parado = 0.0
		ultima_posicao_player_x = jogador.global_position.x
		recarga_bastao_restante = recarga_bastao_subterraneo

func _invocar_bastao_subterraneo(alvo_x: float) -> void:
	var bastao = CENA_BASTAO_SUBTERRANEO.instantiate()
	bastao.tempo_aviso = aviso_bastao_subterraneo
	get_parent().add_child(bastao)
	bastao.global_position = Vector2(clampf(alvo_x, 12.0, 242.0), 220.0)

func _animar(nova: Animacao) -> void:
	animacao = nova
	tempo_animacao = 0.0

func _cadencia() -> float:
	if fase == 3:
		return multiplicador_cadencia_fase_tres
	return multiplicador_cadencia_furia if em_furia else 1.0

func _valido(token: int) -> bool:
	return is_inside_tree() and ativo and not morrendo and not stunnado and token == geracao_ataque

func _interromper() -> void:
	geracao_ataque += 1
	timer_disparo.stop()
	velocity = Vector2.ZERO
	atacando = false
	em_transicao = false
	passagem_segura_ativa = false

func _limpar_perigos() -> void:
	for perigo in get_tree().get_nodes_in_group("perigos_boss"):
		if is_instance_valid(perigo):
			perigo.set_physics_process(false)
			perigo.set_process(false)
			perigo.queue_free()

func _on_timer_disparo_timeout() -> void:
	if not ativo or morrendo or stunnado or atacando or em_transicao:
		return
	var jogador := get_tree().get_first_node_in_group("tanque") as Node2D
	if not is_instance_valid(jogador) or jogador.morrendo:
		return
	# Sorteia a ordem dos golpes. Na fase 2, todos os especiais entram no
	# mesmo baralho dos ataques normais, sem repetir o golpe anterior.
	var opcoes: Array[int] = [0, 1] # tiro unico e rajada na primeira fase
	if fase == 2:
		# Na segunda fase o tiro simples vira o bastão subterrâneo e a rajada
		# tripla sai do baralho para não sobrecarregar os ataques globais.
		opcoes = [0, 2, 3, 4] # bastão, chuva, espiral e lasers
	elif fase == 3:
		opcoes = [0]
	if opcoes.size() > 1:
		opcoes.erase(ultimo_ataque_escolhido)
	var ataque_escolhido: int = opcoes.pick_random()
	ultimo_ataque_escolhido = ataque_escolhido
	if ataque_escolhido >= 2:
		_executar_global(ataque_escolhido - 2)
		return
	if absf(jogador.global_position.x - global_position.x) > 18.0:
		timer_disparo.start(0.2)
		return
	indice_padrao += 1
	var quantidade := maxi(tiros_na_rajada, 1) if ataque_escolhido == 1 else 1
	identificador_rajada += 1
	_executar_ataque(quantidade)

func _criar_tiro(origem: Vector2, direcao: Vector2, velocidade: float, rajada := false, ataque_com_brecha := false, atravessa_dash := false) -> void:
	var tiro = (CENA_CRISTAL_CHUVA if ataque_com_brecha else CENA_TIRO).instantiate()
	tiro.id_rajada = identificador_rajada if rajada else -1
	tiro.rajada_tripla = rajada
	tiro.direcao = direcao.normalized()
	tiro.velocidade = velocidade * (1.18 if em_furia else 1.0)
	tiro.ignora_dash = atravessa_dash
	if fase == 2 and not ataque_com_brecha and tiro.has_method("configurar_bastao_grande"):
		tiro.configurar_bastao_grande(TEXTURA_BASTAO_GRANDE)
	get_parent().add_child(tiro)
	# Bastões grandes começam à frente da mão para não nascerem sobrepostos ao
	# corpo do Tung e parecerem ter sido apagados no mesmo frame.
	tiro.global_position = origem + tiro.direcao * tiro.deslocamento_spawn

func _executar_ataque(quantidade: int) -> void:
	atacando = true
	velocity = Vector2.ZERO
	_animar(Animacao.ARREMESSAR)
	var token := geracao_ataque
	await get_tree().create_timer(maxf(preparacao_arremesso * _cadencia(), 0.35)).timeout
	if not _valido(token):
		return
	for indice in range(quantidade):
		var jogador := get_tree().get_first_node_in_group("tanque") as Node2D
		if not is_instance_valid(jogador):
			return
		# Mira onde o jogador está neste instante, mas trava a trajetória ao sair.
		var direcao_travada := spawn_point.global_position.direction_to(jogador.global_position)
		_criar_tiro(spawn_point.global_position, direcao_travada, 190.0, quantidade > 1)
		if indice < quantidade - 1:
			await get_tree().create_timer(maxf(intervalo_entre_tiros_da_rajada * _cadencia(), 0.2)).timeout
			if not _valido(token):
				return
	await _recuperar(token)

func _recuperar(token: int) -> void:
	await get_tree().create_timer(maxf(pausa_apos_arremesso * _cadencia(), 0.4)).timeout
	if not _valido(token):
		return
	atacando = false
	_animar(Animacao.ANDAR)
	timer_disparo.start(maxf(intervalo_entre_ataques * _cadencia(), 0.55))

func _criar_aviso(regioes: Array[Rect2], letal: bool, duracao: float, aviso_personalizado := -1.0) -> void:
	var perigo = CENA_PERIGO.instantiate()
	perigo.regioes = regioes
	perigo.letal = letal
	perigo.tempo_aviso = maxf(aviso_personalizado if aviso_personalizado >= 0.0 else tempo_aviso_global, 0.5)
	perigo.tempo_ativo = duracao
	get_parent().add_child(perigo)

func _regioes_fora_passagem(centro: float) -> Array[Rect2]:
	var metade := largura_passagem_segura * 0.5
	return [Rect2(0, 80, maxf(centro - metade, 0), 134),
		Rect2(centro + metade, 80, maxf(254 - centro - metade, 0), 134)]

func _executar_global(padrao: int) -> void:
	atacando = true
	velocity = Vector2.ZERO
	_animar(Animacao.CONJURAR)
	var token := geracao_ataque
	var jogador := get_tree().get_first_node_in_group("tanque") as Node2D
	var deslocamento: float = [-54.0, 54.0].pick_random()
	var centro_seguro := clampf(jogador.global_position.x + deslocamento, 44.0, 210.0)
	match padrao:
		0:
			passagem_segura_ativa = true
			centro_passagem_segura = centro_seguro
			ataque_anunciado.emit("CHUVA DE CRISTAIS | ACHE A BRECHA", tempo_aviso_global)
			_criar_aviso(_regioes_fora_passagem(centro_seguro), false, 1.8)
			await get_tree().create_timer(maxf(tempo_aviso_global, 0.5)).timeout
			if not _valido(token):
				return
			for onda in range(4):
				for coluna in range(14):
					var x := 10.0 + coluna * 18.0
					if absf(x - centro_seguro) > largura_passagem_segura * 0.5:
						_criar_tiro(Vector2(x, 80), Vector2.DOWN, 205.0, false, true, true)
				await get_tree().create_timer(0.32).timeout
				if not _valido(token):
					return
		1:
			passagem_segura_ativa = false
			ataque_anunciado.emit("ESPIRAL | DESVIE OU DASH", tempo_aviso_global)
			await get_tree().create_timer(maxf(tempo_aviso_global, 0.8)).timeout
			if not _valido(token):
				return
			for onda in range(ondas_espiral):
				var inicio_brecha := (onda + 1) % 5
				for raio in range(6):
					# Dois setores contiguos sempre ficam vazios, e a abertura gira a cada onda.
					if raio == inicio_brecha or raio == inicio_brecha + 1:
						continue
					var angulo := deg_to_rad(33.0 + raio * 23.0 + sin(onda * 1.15) * 10.0)
					_criar_tiro(spawn_point.global_position, Vector2.from_angle(angulo), velocidade_espiral, false, true, false)
				await get_tree().create_timer(intervalo_ondas_espiral).timeout
				if not _valido(token):
					return
		2:
			passagem_segura_ativa = true
			centro_passagem_segura = centro_seguro
			ataque_anunciado.emit("RUPTURA | SAIA DO VERMELHO", tempo_aviso_laser)
			_criar_aviso(_regioes_fora_passagem(centro_seguro), true, 0.22, tempo_aviso_laser)
			await get_tree().create_timer(tempo_aviso_laser + 0.26).timeout
			if not _valido(token):
				return
			centro_seguro = clampf(centro_seguro + (52.0 if centro_seguro < 127 else -52.0), 44, 210)
			centro_passagem_segura = centro_seguro
			ataque_anunciado.emit("RUPTURA | MUDE DE PASSAGEM", tempo_aviso_laser)
			_criar_aviso(_regioes_fora_passagem(centro_seguro), true, 0.22, tempo_aviso_laser)
			await get_tree().create_timer(tempo_aviso_laser + 0.26).timeout
			if not _valido(token):
				return
	passagem_segura_ativa = false
	await _recuperar(token)

func receber_ataque(dano: int, postura: int) -> void:
	if morrendo or not ativo or em_transicao:
		return
	var armadura_fase := multiplicador_dano_fase_dois if fase == 2 and not stunnado else 1.0
	var dano_final := maxi(roundi(dano * armadura_fase * (multiplicador_dano_stun if stunnado else 1.0)), 0)
	# A fase triste dura exatamente uma execução da música. Durante ela, ataques
	# ainda dão feedback, mas não podem encerrar Tung antes da última nota.
	vida_atual = maxi(vida_atual - dano_final, 1 if fase == 3 else 0)
	if not stunnado:
		dano_desde_stun += dano_final
		postura_atual = mini(postura_atual + postura, postura_maxima)
		postura_alterada.emit(postura_atual, postura_maxima)
	flash_dano = 0.07
	vida_alterada.emit(vida_atual, vida_maxima)
	if vida_atual <= 0:
		if fase == 1:
			# Dano excessivo nunca pula a segunda fase.
			vida_atual = maxi(roundi(vida_maxima * vida_inicio_fase_dois), 1)
			vida_alterada.emit(vida_atual, vida_maxima)
			_verificar_transicao()
		elif fase == 2:
			_entrar_fase_tres()
		else:
			_morrer()
	elif postura_atual >= postura_maxima and not stunnado:
		aplicar_stun()
	elif not stunnado:
		_verificar_transicao()

func _verificar_transicao() -> bool:
	if fase == 1 and vida_atual <= roundi(vida_maxima * vida_inicio_fase_dois):
		fase = 2
		indice_padrao = 0
		fase_dois_iniciada.emit(2.8)
		_entrar_furia(true)
		return true
	if not em_furia and dano_desde_stun >= maxi(roundi(vida_maxima * fracao_dano_para_furia), 1):
		_entrar_furia()
		return true
	return false

func _entrar_furia(eh_fase_dois := false) -> void:
	_interromper()
	_limpar_perigos()
	em_furia = true
	em_transicao = true
	transicao_fase_dois = eh_fase_dois
	atacando = true
	_animar(Animacao.GRITO)
	var duracao_transicao := 2.8 if eh_fase_dois else duracao_grito
	if get_parent().has_method("tremer_tela"):
		get_parent().tremer_tela(9.0 if eh_fase_dois else 4.0, duracao_transicao)
	var token := geracao_ataque
	await get_tree().create_timer(maxf(duracao_transicao, 0.1)).timeout
	if not _valido(token):
		return
	em_transicao = false
	transicao_fase_dois = false
	atacando = false
	_animar(Animacao.ANDAR)
	timer_disparo.start(0.7)

func _entrar_fase_tres() -> void:
	_interromper()
	_limpar_perigos()
	fase = 3
	em_furia = false
	stunnado = false
	postura_atual = 0
	dano_desde_stun = 0
	vida_atual = vida_fase_tres
	em_transicao = true
	atacando = true
	fase_tres_iniciada.emit(1.9)
	vida_alterada.emit(vida_atual, vida_maxima)
	postura_alterada.emit(postura_atual, postura_maxima)
	var apagar := create_tween()
	apagar.tween_property(sprite, "modulate:a", 0.0, 0.5).set_trans(Tween.TRANS_SINE)
	await apagar.finished
	if not is_inside_tree() or morrendo:
		return
	sprite.texture = TEXTURA_TUNG_CANSADO
	sprite.hframes = 4
	sprite.vframes = 1
	sprite.frame = 0
	sprite.position = Vector2(0, -5)
	sprite.scale = Vector2.ONE * (72.0 / (float(TEXTURA_TUNG_CANSADO.get_width()) / 4.0))
	sprite.modulate = Color(0.82, 0.86, 0.95, 0.0)
	var surgir := create_tween()
	surgir.tween_property(sprite, "modulate", Color(0.82, 0.86, 0.95, 1.0), 1.0).set_trans(Tween.TRANS_SINE)
	await surgir.finished
	await get_tree().create_timer(0.4).timeout
	em_transicao = false
	atacando = false
	_animar(Animacao.ANDAR)
	timer_disparo.start(3.8)

func explosion() -> void:
	receber_ataque(1, 2)

func ativar_fase_dois_debug() -> void:
	if morrendo:
		return
	_interromper()
	fase = 2
	vida_atual = maxi(roundi(vida_maxima * vida_inicio_fase_dois), 1)
	postura_atual = 0
	em_furia = true
	em_transicao = false
	atacando = false
	_animar(Animacao.ANDAR)
	vida_alterada.emit(vida_atual, vida_maxima)
	postura_alterada.emit(postura_atual, postura_maxima)
	timer_disparo.start(0.35)

func ativar_fase_tres_debug() -> void:
	if morrendo or fase == 3:
		return
	_entrar_fase_tres()

func finalizar_fase_tres_pela_musica() -> void:
	if fase != 3 or morrendo:
		return
	vida_atual = 0
	vida_alterada.emit(vida_atual, vida_maxima)
	_morrer()

func aplicar_stun() -> void:
	_interromper()
	_limpar_perigos()
	stunnado = true
	em_furia = false
	dano_desde_stun = 0
	_animar(Animacao.STUN)
	var token := geracao_ataque
	await get_tree().create_timer(maxf(duracao_stun, 0.1)).timeout
	if morrendo or not ativo or token != geracao_ataque:
		return
	postura_atual = 0
	postura_alterada.emit(postura_atual, postura_maxima)
	stunnado = false
	dano_desde_stun = 0
	_animar(Animacao.ANDAR)
	if not _verificar_transicao():
		timer_disparo.start(intervalo_entre_ataques)

func _morrer() -> void:
	if fase == 3:
		_morrer_fase_tres()
		return
	morrendo = true
	ativo = false
	_interromper()
	_limpar_perigos()
	em_furia = false
	stunnado = false
	$CollisionShape2D.set_deferred("disabled", true)
	_animar(Animacao.MORTE)
	await get_tree().create_timer(1.0).timeout
	derrotado.emit()
	queue_free()

func _morrer_fase_tres() -> void:
	if morrendo:
		return
	morrendo = true
	ativo = false
	_interromper()
	_limpar_perigos()
	$CollisionShape2D.set_deferred("disabled", true)
	velocity = Vector2.ZERO
	var desaparecer := create_tween()
	desaparecer.tween_property(sprite, "modulate", Color(1.0, 1.0, 1.0, 0.0), 2.2).set_trans(Tween.TRANS_SINE)
	for lote in range(8):
		_criar_particulas_brancas(7)
		await get_tree().create_timer(0.22).timeout
	await get_tree().create_timer(0.55).timeout
	derrotado.emit()
	queue_free()

func _criar_particulas_brancas(quantidade: int) -> void:
	for i in range(quantidade):
		var particula := Polygon2D.new()
		var tamanho := randf_range(1.0, 2.8)
		particula.polygon = PackedVector2Array([
			Vector2(-tamanho, -tamanho), Vector2(tamanho, -tamanho),
			Vector2(tamanho, tamanho), Vector2(-tamanho, tamanho)
		])
		particula.color = Color(0.88, 0.94, 1.0, randf_range(0.65, 1.0))
		get_parent().add_child(particula)
		particula.global_position = global_position + Vector2(randf_range(-25.0, 25.0), randf_range(-32.0, 28.0))
		var destino := particula.global_position + Vector2(randf_range(-18.0, 18.0), randf_range(-38.0, -12.0))
		var tween := particula.create_tween().set_parallel(true)
		tween.tween_property(particula, "global_position", destino, randf_range(1.4, 2.4)).set_trans(Tween.TRANS_SINE)
		tween.tween_property(particula, "modulate:a", 0.0, randf_range(1.4, 2.4))
		tween.tween_property(particula, "rotation", randf_range(-PI, PI), 2.0)
		tween.chain().tween_callback(particula.queue_free)
