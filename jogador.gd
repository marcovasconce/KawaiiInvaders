extends CharacterBody2D

@export var disparo = preload("res://cenas/disparo.tscn")
@export_category("Rajada do Makoto")
@export_range(1, 8, 1) var tiros_por_rajada := 2
@export_range(0.02, 0.5, 0.01) var intervalo_entre_tiros := 0.12
@export_category("Carga do Makoto")
@export_range(2, 100, 1) var dano_tiro_carregado := 24
@export_range(0, 100, 1) var postura_tiro_carregado := 22
@export_category("Cinematic Misericordia")
@export_range(0.1, 3.0, 0.05) var velocidade_giro_misericordia_inicial := 0.35
@export_range(0.5, 8.0, 0.1) var aceleracao_giro_misericordia := 3.2
@export_range(3.0, 15.0, 0.25) var velocidade_giro_misericordia_maxima := 8.5
@export_range(1.0, 5.0, 0.1) var duracao_giro_misericordia := 2.6
@export_category("Debug")
@export_range(1, 9999, 1) var dano_tiro_debug := 100
@export_category("Dash do Makoto")
@export_range(150.0, 800.0, 10.0) var velocidade_dash := 460.0
@export_range(0.05, 0.4, 0.01) var duracao_dash := 0.18
@export_range(0.1, 2.0, 0.05) var recarga_dash := 0.55
@export_range(0.0, 0.15, 0.01) var protecao_apos_dash := 0.06
@export_category("Estado inicial")
@export var iniciar_como_makoto := false
@export var mostrar_dicas_ao_transformar := true
@export_category("Transicao para Makoto")
@export_range(0.3, 1.5, 0.05) var duracao_transicao := 0.75
const SPRITE_MAKOTO = preload("res://assets]/Assets Space Invades/Sprites/hframesmakoto_clean.png")
const SPRITE_MORTE_MAKOTO = preload("res://assets]/Assets Space Invades/Sprites/makoto_morte.png")
const TRANSICAO_RESULTADO = preload("res://cenas/transicao_resultado.gd")
const AUDIO_UTIL = preload("res://cenas/audio_util.gd")
const SFX_TIRO_KITTY = preload("res://assets]/Assets Space Invades/sfx/TiroHelloKitty.mp3")
const SFX_TIRO_MAKOTO = preload("res://assets]/Assets Space Invades/sfx/MakotoTiro.mp3")
const SFX_TIRO_CARREGADO = preload("res://assets]/Assets Space Invades/sfx/TiroCarregado.mp3")
const SFX_PARRY = preload("res://assets]/Assets Space Invades/sfx/Parry.mp3")
const SFX_DASH = preload("res://assets]/Assets Space Invades/sfx/Dash.mp3")
const SFX_EXPLOSAO = preload("res://assets]/Assets Space Invades/sfx/explosion.wav")
@onready var ptoDisparo = $alvaro
@onready var timer_disparo = $timerDisparo
@onready var anim = $AnimationPlayer
@onready var sprite = $goatedInvader

# REFERÊNCIA DO FLASH (Ajuste o caminho se sua árvore de nós for diferente)
@onready var flash_branco = get_node("../CanvasLayer/FlashBranco") 

const SPEED = 100.0
static var tiro_debug_ativo := false
static var modo_pro_ativo := false
var pode_disprar = true

# VARIÁVEIS DO PARRY
var esta_no_parry = false
@export_category("Parry")
@export_range(0.1, 0.5, 0.01) var tempo_janela_parry := 0.28
var makoto_ativado := false
var makoto_animando_acao := false
var makoto_animacao_id := 0
var tempo_animacao_makoto := 0.0
var direcao_olhando := 1.0
var em_dash := false
var dash_disponivel := true
var direcao_dash := 1.0
var invulneravel := false
var morrendo := false
var auto_parry_rajada_id := -1
var dash_recarga_restante := 0.0
var efeito_parry_ativo := false
var na_arena_boss := false
var tiro_carregado_pronto := false
var tempo_brilho_carga := 0.0
var tempo_transicao := -1.0
var em_transformacao := false
var parries_bem_sucedidos := 0
var escudo_refletivo_restante := 0.0
@export_range(1.0, 10.0, 0.25) var duracao_escudo_refletivo := 4.5
var cargas_misericordia := 0
@export_range(1, 4, 1) var cargas_para_misericordia := 2
var em_misericordia := false

func _ready() -> void:
	na_arena_boss = get_parent().has_node("Boss")
	if iniciar_como_makoto:
		call_deferred("transformar_em_makoto", false)

func _process(delta: float) -> void:
	if escudo_refletivo_restante > 0.0:
		escudo_refletivo_restante = maxf(escudo_refletivo_restante-delta,0.0)
		queue_redraw()
	if tempo_transicao >= 0.0:
		tempo_transicao += delta
		if tempo_transicao >= duracao_transicao:
			tempo_transicao = -1.0
		queue_redraw()
	if tiro_carregado_pronto and not morrendo:
		tempo_brilho_carga += delta
		queue_redraw()

func _draw() -> void:
	if tempo_transicao >= 0.0:
		var progresso := clampf(tempo_transicao / duracao_transicao, 0.0, 1.0)
		var centro := Vector2(0, -10)
		var raio := lerpf(8.0, 38.0, progresso)
		draw_circle(centro, 18.0 + progresso * 12.0, Color(0.16, 0.58, 1.0, (1.0 - progresso) * 0.25))
		draw_arc(centro, raio, 0.0, TAU, 40, Color(0.47, 0.86, 1.0, 1.0 - progresso), 2.0)
		draw_arc(centro, raio * 0.72, 0.0, TAU, 40, Color(0.85, 0.95, 1.0, (1.0 - progresso) * 0.7), 1.0)
		for i in 8:
			var angulo := float(i) * TAU / 8.0 + tempo_transicao * 2.5
			var ponta := centro + Vector2.from_angle(angulo) * (11.0 + progresso * 28.0)
			draw_rect(Rect2(ponta, Vector2(2, 2)), Color(0.6, 0.91, 1.0, 1.0 - progresso))
	if escudo_refletivo_restante > 0.0 and not morrendo:
		var pulso_escudo := 0.5+0.5*sin(Time.get_ticks_msec()*0.012)
		draw_circle(Vector2(0,-9),24.0+pulso_escudo*2.0,Color(0.45,0.85,1.0,0.08))
		draw_arc(Vector2(0,-9),24.0+pulso_escudo*2.0,0,TAU,40,Color(0.75,0.95,1.0,0.65),1.5)
		for i in range(6):
			var a := tempo_brilho_carga*2.0+i*TAU/6.0
			draw_circle(Vector2(0,-9)+Vector2.from_angle(a)*25.0,1.4,Color(1.0,0.84,0.3,0.85))
	if cargas_misericordia > 0 and not tiro_carregado_pronto and not morrendo:
		var proporcao := float(cargas_misericordia)/float(maxi(cargas_para_misericordia,1))
		draw_arc(Vector2(0,-9),20.5,-PI/2.0,-PI/2.0+TAU*proporcao,30,Color(0.35,0.85,1.0,0.9),2.0)
	if em_misericordia and not morrendo:
		var pulso_misericordia := 0.5+0.5*sin(Time.get_ticks_msec()*0.018)
		draw_circle(Vector2(0,-9),30.0+pulso_misericordia*4.0,Color(0.3,0.8,1.0,0.13))
		draw_arc(Vector2(0,-9),31.0+pulso_misericordia*3.0,0,TAU,48,Color(0.8,0.98,1.0,0.9),2.0)
	if not tiro_carregado_pronto or morrendo:
		return
	var pulso := 0.5 + 0.5 * sin(tempo_brilho_carga * 9.0)
	var centro := Vector2(0, -10)
	draw_circle(centro, 18.0 + pulso * 2.0, Color(0.05, 0.45, 1.0, 0.12 + pulso * 0.06))
	draw_arc(centro, 18.0 + pulso * 2.0, 0, TAU, 28, Color(0.28, 0.78, 1.0, 0.35 + pulso * 0.2), 1.0)
	for indice in range(3):
		var angulo := tempo_brilho_carga * 2.5 + indice * TAU / 3.0
		draw_circle(centro + Vector2.from_angle(angulo) * (21.0 + pulso * 2.0), 1.5, Color(0.8, 0.98, 1.0, 0.8))

func _physics_process(delta):
	if morrendo:
		return
	if Input.is_action_just_pressed("debug_modo_pro"):
		alternar_modo_pro()
	if em_transformacao:
		velocity.x = 0.0
		move_and_slide()
		return
	if Input.is_action_just_pressed("debug_tiro_forte"):
		alternar_tiro_debug()
	if em_misericordia:
		velocity = Vector2.ZERO
		move_and_slide()
		return
	dash_recarga_restante = maxf(dash_recarga_restante - delta, 0.0)
	# Captura a direção do movimento
	var direction = Input.get_axis("ui_left", "ui_right")
	if not is_zero_approx(direction):
		direcao_olhando = signf(direction)

	if Input.is_action_just_pressed("dash") and makoto_ativado and dash_disponivel:
		iniciar_dash(direction)
	
	# Controle de movimento (so se move se nao estiver destruido)
	if em_dash:
		velocity.x = direcao_dash * velocidade_dash
	elif direction > 0:
		velocity.x = direction * SPEED
	elif direction < 0:
		velocity.x = direction * SPEED
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)

	# O Makoto usa a grade nova; a Hello Kitty mantem as animacoes originais.
	if makoto_ativado:
		anim.stop()          
		if not makoto_animando_acao:
			tempo_animacao_makoto += delta
			atualizar_animacao_makoto(direction)
	elif direction > 0:
		anim.play("walk_direita")
	elif direction < 0:
		anim.play("walk_esquerda")
	else:
		anim.stop()
		sprite.frame = 0

	# Sistema de tiro
	if Input.is_action_pressed("shoot") and pode_disprar and not em_dash:
		pode_disprar = false
		timer_disparo.start()
		if makoto_ativado:
			tocar_animacao_makoto(18, 0.07)
			disparar_rajada_makoto()
		else:
			criar_disparo(false)
		
	# SISTEMA DE PARRY (C)
	if Input.is_action_just_pressed("parry") and not esta_no_parry and not em_dash:
		ativar_parry()
		
	move_and_slide()
	if na_arena_boss:
		global_position.x = clampf(global_position.x, 16.0, 238.0)

func ativar_parry():
	esta_no_parry = true
	if makoto_ativado:
		tocar_animacao_makoto(24, 0.06)
		sprite.modulate = Color(0.25, 0.75, 1.5, 1.0)
	else:
		sprite.modulate = Color.PALE_VIOLET_RED
	
	# Espera os frames da janela de parry acabarem
	await get_tree().create_timer(tempo_janela_parry).timeout
	
	esta_no_parry = false
	sprite.modulate = Color.WHITE # Volta ao normal

# FUNÇÃO DO FLASH VISUAL IRADO
func aplicar_impacto_visual():
	if efeito_parry_ativo or morrendo:
		return
	efeito_parry_ativo = true
	parries_bem_sucedidos += 1
	AUDIO_UTIL.tocar(self, SFX_PARRY, false, -1.0)
	if flash_branco:
		flash_branco.visible = true
		# Efeito de desaceleração do tempo (Freeze Frame/Hitstop) por 0.05s para dar peso físico ao parry!
		Engine.time_scale = 0.1 
		await get_tree().create_timer(0.05, true, false, true).timeout
		Engine.time_scale = 1.0
		flash_branco.visible = false

	# O shake vem depois do flash para os dois efeitos ficarem bem visiveis.
	var cena_principal = get_parent()
	if cena_principal.has_method("tremer_tela"):
		cena_principal.tremer_tela(8.0, 0.20)

	transformar_em_makoto()
	# Um parry bem-sucedido também devolve mobilidade e prepara um contra-ataque.
	# Isso cria uma recompensa jogável além do dano do projétil refletido.
	if makoto_ativado:
		dash_disponivel = true
		dash_recarga_restante = 0.0
		var chefe := get_tree().get_first_node_in_group("boss")
		if is_instance_valid(chefe) and chefe.has_method("ativar_misericordia"):
			registrar_carga_misericordia()
		# Fora da fase divina, mantém a regra original do quarto parry.
		elif parries_bem_sucedidos % 4 == 0:
			tiro_carregado_pronto = true
			tempo_brilho_carga = 0.0
			queue_redraw()
	efeito_parry_ativo = false

func registrar_carga_misericordia(quantidade := 1) -> void:
	if morrendo or not makoto_ativado:
		return
	var chefe := get_tree().get_first_node_in_group("boss")
	if not is_instance_valid(chefe) or not chefe.has_method("ativar_misericordia"):
		return
	cargas_misericordia = mini(cargas_misericordia+quantidade,cargas_para_misericordia)
	# Um pulso azul menor confirma cada metade da carga.
	tempo_brilho_carga = 0.0
	queue_redraw()
	if cargas_misericordia < cargas_para_misericordia:
		return
	cargas_misericordia = 0
	chefe.ativar_misericordia()

func executar_misericordia() -> void:
	if em_misericordia or morrendo:
		return
	em_misericordia = true
	invulneravel = true
	tiro_carregado_pronto = false
	velocity = Vector2.ZERO
	var posicao_chao := global_position
	Engine.time_scale = 0.32
	queue_redraw()
	# Sobe em tempo real para a câmera lenta não transformar a preparação em
	# uma espera longa demais.
	var flutuar := create_tween().set_ignore_time_scale(true)
	flutuar.tween_property(self,"global_position:y",clampf(posicao_chao.y-28.0,150.0,172.0),0.65).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	await flutuar.finished
	if not is_inside_tree() or morrendo:
		Engine.time_scale = 1.0
		return
	var coroa := Node2D.new()
	coroa.position = Vector2(0,-9)
	add_child(coroa)
	var quantidade_tiros := 10
	for i in range(quantidade_tiros):
		var tiro_visual := Polygon2D.new()
		tiro_visual.polygon = PackedVector2Array([Vector2(0,-7),Vector2(3,0),Vector2(0,7),Vector2(-3,0)])
		tiro_visual.color = Color(0.55,0.92,1.0,0.95)
		tiro_visual.position = Vector2.from_angle(float(i)*TAU/quantidade_tiros)*34.0
		tiro_visual.rotation = float(i)*TAU/quantidade_tiros+PI/2.0
		tiro_visual.modulate.a = 0.0
		tiro_visual.scale = Vector2.ZERO
		coroa.add_child(tiro_visual)
		var nucleo := Polygon2D.new()
		nucleo.polygon = PackedVector2Array([Vector2(0,-4),Vector2(1.4,0),Vector2(0,4),Vector2(-1.4,0)])
		nucleo.color = Color.WHITE
		tiro_visual.add_child(nucleo)
		var surgir := tiro_visual.create_tween().set_ignore_time_scale(true).set_parallel(true)
		surgir.tween_property(tiro_visual,"modulate:a",1.0,0.28).set_delay(i*0.055)
		surgir.tween_property(tiro_visual,"scale",Vector2.ONE,0.34).set_delay(i*0.055).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	# Primeiro aparecem um a um. A coroa começa quase parada e acelera em
	# três marchas perceptíveis antes de comprimir toda a energia no centro.
	await get_tree().create_timer(0.82,true,false,true).timeout
	# Velocidade angular contínua: soma aceleração a cada frame até o limite,
	# sem trocar de tween e sem micro-pausas entre "marchas".
	var velocidade_giro := velocidade_giro_misericordia_inicial
	var tempo_girando := 0.0
	var ultimo_tick := Time.get_ticks_usec()
	while tempo_girando < duracao_giro_misericordia and is_instance_valid(coroa):
		await get_tree().process_frame
		var tick_atual := Time.get_ticks_usec()
		var delta_real := float(tick_atual-ultimo_tick)/1000000.0
		ultimo_tick = tick_atual
		tempo_girando += delta_real
		velocidade_giro = minf(velocidade_giro+aceleracao_giro_misericordia*delta_real,velocidade_giro_misericordia_maxima)
		coroa.rotation += velocidade_giro*delta_real
	var juntar := create_tween().set_ignore_time_scale(true).set_parallel(true)
	for filho in coroa.get_children():
		if filho is Node2D:
			var tiro_node := filho as Node2D
			juntar.tween_property(tiro_node,"position",tiro_node.position.normalized()*9.0,0.32).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
			juntar.tween_property(tiro_node,"scale",Vector2.ONE*1.5,0.32)
	await juntar.finished
	# Todos se tornam projéteis reais no mesmo frame: uma única rajada, não
	# uma fila. O primeiro carrega o impacto integral da Misericórdia.
	var origens: Array[Vector2] = []
	for filho in coroa.get_children():
		if filho is Node2D:
			origens.append((filho as Node2D).global_position)
	coroa.queue_free()
	var cena_principal := get_parent()
	if cena_principal.has_method("tremer_tela"):
		cena_principal.tremer_tela(14.0,0.48)
	if flash_branco:
		flash_branco.visible = true
		flash_branco.modulate.a = 0.72
		var flash_rajada := create_tween().set_ignore_time_scale(true)
		flash_rajada.tween_property(flash_branco,"modulate:a",0.0,0.22)
		flash_rajada.tween_callback(func():
			flash_branco.visible = false
			flash_branco.modulate.a = 1.0
		)
	for i in range(origens.size()):
		_criar_tiro_chuva_misericordia(origens[i],i==0)
	await get_tree().create_timer(1.0,true,false,true).timeout
	Engine.time_scale = 1.0
	if is_inside_tree() and not morrendo:
		var descer := create_tween().set_ignore_time_scale(true)
		descer.tween_property(self,"global_position",posicao_chao,0.55).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		await descer.finished
		invulneravel = false
		em_misericordia = false
		queue_redraw()
	var chefe := get_tree().get_first_node_in_group("boss")
	if is_instance_valid(chefe) and chefe.has_method("finalizar_cinematic_misericordia"):
		chefe.finalizar_cinematic_misericordia()

func _criar_tiro_chuva_misericordia(origem: Vector2, principal: bool) -> void:
	var novo_disparo = disparo.instantiate()
	get_parent().add_child(novo_disparo)
	novo_disparo.global_position = origem
	var area_disparo = novo_disparo.get_node_or_null("Area2D")
	if not area_disparo:
		return
	area_disparo.configurar_como_makoto()
	area_disparo.configurar_como_carregado(dano_tiro_carregado if principal else 8,postura_tiro_carregado if principal else 12)
	area_disparo.desativar_particulas_carga()
	area_disparo.configurar_mira_misericordia()
	if principal:
		area_disparo.configurar_misericordia()

func transformar_em_makoto(com_efeito: bool = true) -> void:
	if makoto_ativado:
		return
	var eco_kitty: Sprite2D = null
	if com_efeito:
		eco_kitty = Sprite2D.new()
		eco_kitty.texture = sprite.texture
		eco_kitty.hframes = sprite.hframes
		eco_kitty.vframes = sprite.vframes
		eco_kitty.frame = sprite.frame
		eco_kitty.position = sprite.position
		eco_kitty.scale = sprite.scale
		eco_kitty.texture_filter = sprite.texture_filter
		add_child(eco_kitty)
		eco_kitty.z_index = 1

	makoto_ativado = true
	anim.stop()
	sprite.texture = SPRITE_MAKOTO
	sprite.hframes = 6
	sprite.vframes = 5
	sprite.frame = 24
	sprite.position = Vector2(0, -10)
	sprite.scale = Vector2(0.16, 0.16)
	sprite.modulate = Color.WHITE
	_configurar_hitbox_makoto()
	tocar_animacao_makoto(24, 0.06)
	ativar_cenario_makoto()
	if com_efeito:
		em_transformacao = true
		invulneravel = true
		tempo_transicao = 0.0
		sprite.modulate = Color(0.55, 0.85, 1.0, 0.0)
		var transicao := create_tween().set_parallel(true)
		transicao.tween_property(sprite, "modulate", Color.WHITE, duracao_transicao).set_trans(Tween.TRANS_SINE)
		transicao.tween_property(eco_kitty, "modulate", Color(0.65, 0.85, 1.0, 0.0), duracao_transicao)
		transicao.tween_property(eco_kitty, "scale", eco_kitty.scale * 1.3, duracao_transicao)
		transicao.finished.connect(func() -> void:
			if is_instance_valid(eco_kitty):
				eco_kitty.queue_free()
			em_transformacao = false
			invulneravel = false
		)
	if mostrar_dicas_ao_transformar:
		mostrar_dicas_makoto()

func _configurar_hitbox_makoto() -> void:
	var colisao := $CollisionShape2D as CollisionShape2D
	var formato := CapsuleShape2D.new()
	# O corpo ocupa aproximadamente 13x28 px; espada, braços abertos e áreas
	# transparentes dos quadros não devem aumentar a zona vulnerável.
	formato.radius = 6.5
	formato.height = 28.0
	colisao.shape = formato
	colisao.scale = Vector2.ONE
	colisao.position = Vector2(0, -7)
	# A cápsula do Makoto chega até y=-21. O tiro precisa nascer acima dela
	# para não detectar o próprio jogador e ser consumido no primeiro frame.
	ptoDisparo.position = Vector2(0, -29)

func criar_disparo(eh_makoto: bool) -> void:
	var disparo_carregado := eh_makoto and tiro_carregado_pronto
	var novo_disparo = disparo.instantiate()
	get_parent().add_child(novo_disparo)
	novo_disparo.global_position = ptoDisparo.global_position

	var area_disparo = novo_disparo.get_node_or_null("Area2D")
	if area_disparo:
		if eh_makoto:
			area_disparo.configurar_como_makoto()
			if tiro_carregado_pronto:
				area_disparo.configurar_como_carregado(dano_tiro_carregado, postura_tiro_carregado)
				var chefe := get_tree().get_first_node_in_group("boss")
				if is_instance_valid(chefe) and chefe.has_method("misericordia_disponivel") and chefe.misericordia_disponivel():
					area_disparo.configurar_misericordia()
				tiro_carregado_pronto = false
				queue_redraw()
		if tiro_debug_ativo:
			area_disparo.configurar_dano_debug(dano_tiro_debug)

	var audio_tiro := $AudioStreamPlayer2D as AudioStreamPlayer2D
	# O carregado mantém o impacto do tiro normal e acrescenta sua camada por cima.
	audio_tiro.stream = SFX_TIRO_MAKOTO if eh_makoto else SFX_TIRO_KITTY
	audio_tiro.play()
	if disparo_carregado:
		AUDIO_UTIL.tocar(self, SFX_TIRO_CARREGADO, false, 2.0)

func absorver_energia_dash() -> bool:
	if not makoto_ativado or not em_dash or morrendo or tiro_carregado_pronto:
		return false
	tiro_carregado_pronto = true
	tempo_brilho_carga = 0.0
	queue_redraw()
	return true

func alternar_tiro_debug() -> void:
	tiro_debug_ativo = not tiro_debug_ativo
	print("Tiro debug: ", "ATIVADO" if tiro_debug_ativo else "DESATIVADO")

func alternar_modo_pro() -> void:
	modo_pro_ativo = not modo_pro_ativo
	print("Modo Pro (auto-parry): ", "ATIVADO" if modo_pro_ativo else "DESATIVADO")

func deve_auto_parry_projetil() -> bool:
	return modo_pro_ativo and not morrendo

func disparar_rajada_makoto() -> void:
	for indice_tiro in range(tiros_por_rajada):
		if morrendo:
			return
		criar_disparo(true)
		if indice_tiro < tiros_por_rajada - 1:
			await get_tree().create_timer(intervalo_entre_tiros).timeout

func ativar_cenario_makoto() -> void:
	var cena_principal = get_parent()
	var fundo = cena_principal.get_node_or_null("FundoEspacial")
	if fundo and fundo.has_method("ativar_modo_makoto"):
		fundo.ativar_modo_makoto()
	var bases = cena_principal.get_node_or_null("bases")
	if bases:
		bases.queue_free()

	var chao = cena_principal.get_node_or_null("chao")
	if chao and chao.has_method("ativar_modo_makoto"):
		chao.ativar_modo_makoto()

func iniciar_dash(direction_input: float) -> void:
	if morrendo or not dash_disponivel:
		return
	dash_disponivel = false
	dash_recarga_restante = duracao_dash + recarga_dash
	em_dash = true
	invulneravel = true
	direcao_dash = direcao_olhando if is_zero_approx(direction_input) else signf(direction_input)
	direcao_olhando = direcao_dash
	AUDIO_UTIL.tocar(self, SFX_DASH, false, -2.0)

	makoto_animacao_id += 1
	makoto_animando_acao = true
	sprite.frame = 15 if direcao_dash > 0 else 9
	criar_vento_dash(direcao_dash)

	await get_tree().create_timer(duracao_dash).timeout
	em_dash = false
	makoto_animando_acao = false
	tempo_animacao_makoto = 0.0
	velocity.x = 0.0

	await get_tree().create_timer(maxf(protecao_apos_dash, 0.001)).timeout
	invulneravel = false
	await get_tree().create_timer(maxf(recarga_dash - protecao_apos_dash, 0.001)).timeout
	dash_disponivel = true

func criar_vento_dash(sentido: float) -> void:
	var efeito := Node2D.new()
	get_parent().add_child(efeito)
	efeito.global_position = global_position

	var cores := [
		Color(0.1, 0.55, 1.0, 0.8),
		Color(0.3, 0.8, 1.0, 0.65),
		Color(0.75, 0.95, 1.0, 0.5)
	]
	var alturas := [-8.0, 0.0, 8.0]
	var comprimentos := [34.0, 42.0, 28.0]

	for indice in range(3):
		var vento := Polygon2D.new()
		var altura: float = alturas[indice]
		var comprimento: float = comprimentos[indice]
		vento.polygon = PackedVector2Array([
			Vector2(-sentido * 3.0, altura - 2.0),
			Vector2(-sentido * comprimento, altura),
			Vector2(-sentido * 5.0, altura + 2.0)
		])
		vento.color = cores[indice]
		efeito.add_child(vento)

	var tween := efeito.create_tween()
	tween.set_parallel(true)
	tween.tween_property(efeito, "modulate:a", 0.0, duracao_dash * 1.8)
	tween.tween_property(efeito, "scale", Vector2(1.35, 0.65), duracao_dash * 1.8)
	tween.chain().tween_callback(efeito.queue_free)

func mostrar_dicas_makoto() -> void:
	var dica = get_parent().get_node_or_null("CanvasLayer/DicasMakoto")
	if dica and dica.has_method("mostrar"):
		dica.mostrar()

func ativar_ritmo_fase_tres() -> void:
	# A fase final é deliberadamente contida: um disparo por toque e uma pausa
	# longa impedem que a cena triste vire uma rajada de dano sem respiração.
	tiros_por_rajada = 1
	intervalo_entre_tiros = 0.0
	timer_disparo.wait_time = 1.15
	pode_disprar = true

func ativar_ritmo_fase_quatro() -> void:
	# O julgamento devolve a fluidez do Makoto, mas preserva a rajada curta.
	tiros_por_rajada = 2
	intervalo_entre_tiros = 0.12
	timer_disparo.wait_time = 0.34
	pode_disprar = true

func esta_invulneravel() -> bool:
	return invulneravel or em_dash

func ativar_escudo_refletivo() -> void:
	escudo_refletivo_restante = duracao_escudo_refletivo
	tempo_brilho_carga = 0.0
	queue_redraw()

func escudo_refletivo_ativo() -> bool:
	return escudo_refletivo_restante > 0.0 and not morrendo

func registrar_auto_parry_rajada(id_rajada: int) -> void:
	auto_parry_rajada_id = id_rajada

func pode_auto_parry_rajada(id_rajada: int) -> bool:
	return not morrendo and id_rajada >= 0 and auto_parry_rajada_id == id_rajada

func atualizar_animacao_makoto(direction: float) -> void:
	var frame_inicial := 0
	var intervalo := 0.18

	if direction < 0:
		frame_inicial = 6
		intervalo = 0.10
	elif direction > 0:
		frame_inicial = 12
		intervalo = 0.10

	sprite.frame = frame_inicial + int(tempo_animacao_makoto / intervalo) % 6

func tocar_animacao_makoto(frame_inicial: int, intervalo: float) -> void:
	makoto_animacao_id += 1
	var esta_animacao_id := makoto_animacao_id
	makoto_animando_acao = true

	for frame_acao in range(frame_inicial, frame_inicial + 6):
		if esta_animacao_id != makoto_animacao_id or not makoto_ativado:
			return
		sprite.frame = frame_acao
		await get_tree().create_timer(intervalo).timeout

	if esta_animacao_id == makoto_animacao_id:
		makoto_animando_acao = false
		tempo_animacao_makoto = 0.0

func _on_timer_disparo_timeout():
	pode_disprar = true
	
func destruir():
	if esta_invulneravel() or morrendo:
		return
	_iniciar_morte()

func destruir_sem_iframe() -> void:
	if morrendo:
		return
	_iniciar_morte()

func _iniciar_morte() -> void:
	morrendo = true
	AUDIO_UTIL.tocar(get_parent(), SFX_EXPLOSAO, false, -1.0)
	print("dano tomou")
	set_physics_process(false)
	makoto_animacao_id += 1
	makoto_animando_acao = false
	anim.stop()
	$CollisionShape2D.set_deferred("disabled", true)
	if makoto_ativado:
		animar_morte_makoto()
	else:
		anim.play("destruicao")

func animar_morte_makoto() -> void:
	sprite.modulate = Color.WHITE
	sprite.texture = SPRITE_MORTE_MAKOTO
	sprite.hframes = 4
	sprite.vframes = 1
	sprite.scale = Vector2(0.065, 0.065)
	sprite.position = Vector2(0, -11)
	for frame_morte in range(4):
		sprite.frame = frame_morte
		await get_tree().create_timer(0.16).timeout
	if is_inside_tree():
		eliminado()

func eliminado():
	if !self.is_queued_for_deletion():
		if makoto_ativado:
			get_tree().set_meta("morte_makoto_na_arena_boss", na_arena_boss)
		var tela := "res://cenas/derrota_makoto.tscn" if makoto_ativado else "res://cenas/game_over.tscn"
		var transicao = TRANSICAO_RESULTADO.new()
		get_tree().root.add_child(transicao)
		transicao.iniciar(tela, false, makoto_ativado)

func _exit_tree() -> void:
	if efeito_parry_ativo or em_misericordia:
		Engine.time_scale = 1.0
