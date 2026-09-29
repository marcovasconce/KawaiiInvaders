extends CharacterBody2D

signal vida_alterada(atual: int, maxima: int)
signal postura_alterada(atual: int, maxima: int)
signal ataque_anunciado(texto: String, duracao: float)
signal derrotado

const PROJETIL = preload("res://cenas/tung_god_proj.tscn")
const PERIGO = preload("res://cenas/boss_perigo.tscn")
const RAIO = preload("res://cenas/tung_god_raio.tscn")
const CLONE = preload("res://cenas/tung_god_clone.tscn")

@export var julgamento_maximo := 100
@export var intervalo_ataques := 1.15
var julgamento := 100
var ativo := false
var morrendo := false
var atacando := false
var golpe_final := false
var tempo := 0.0
var ultimo_ataque := -1
var geracao := 0
var misericordia_pronta := false
var falso_milagre_ativo := false
var impactos_comuns := 0
var premio_clone_concedido := false
var em_cinematic_misericordia := false
@onready var sprite: Sprite2D = $Sprite2D
@onready var spawn: Marker2D = $SpawnPoint
@onready var timer: Timer = $TimerAtaque

func _ready() -> void:
	add_to_group("boss")
	julgamento = julgamento_maximo
	vida_alterada.emit(julgamento, julgamento_maximo)
	postura_alterada.emit(0, julgamento_maximo)

func aparecer() -> void:
	visible = true
	global_position = Vector2(127, -75)
	sprite.modulate.a = 0.0
	var entrada := create_tween().set_parallel(true)
	entrada.tween_property(self, "global_position:y", 66.0, 2.15).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	entrada.tween_property(sprite, "modulate:a", 1.0, 1.1)
	entrada.tween_property(self, "scale", Vector2.ONE, 2.15).from(Vector2.ONE*1.35).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	await entrada.finished
	ativo = true
	timer.start(0.8)

func _process(delta: float) -> void:
	tempo += delta
	if not visible:
		return
	if not atacando and not morrendo:
		sprite.frame = int(tempo / 0.22) % 4
		position.y += sin(tempo * 2.0) * delta * 2.0
	queue_redraw()

func _draw() -> void:
	if not visible:
		return
	var pulso := 0.5 + sin(tempo*3.0)*0.5
	for i in range(3):
		draw_arc(Vector2(0,-7), 35.0+i*8.0+pulso*2.0, 0, TAU, 48, Color(1,0.82,0.24,0.18-i*0.035), 1.5)
	for i in range(8):
		var a := tempo*(0.45 if i%2==0 else -0.35)+i*TAU/8.0
		draw_circle(Vector2.from_angle(a)*Vector2(48,32)+Vector2(0,-6), 1.3, Color(1,0.92,0.55,0.65))

func _on_timer_ataque_timeout() -> void:
	if not ativo or atacando or morrendo:
		return
	var opcoes := [0,1,2,3,4,5,6]
	opcoes.erase(ultimo_ataque)
	var escolhido: int = opcoes.pick_random()
	ultimo_ataque = escolhido
	_executar_ataque(escolhido)

func _valido(token: int) -> bool:
	return is_inside_tree() and ativo and not morrendo and token == geracao

func _executar_ataque(id: int) -> void:
	atacando = true
	var token := geracao
	sprite.frame = 4
	match id:
		0: await _lancas(token)
		1: await _asas(token)
		2: await _olhar(token)
		3: await _cruz(token)
		4: await _falso_milagre(token)
		5: await _veredito(token, false)
		6: await _ascensao(token)
	if not _valido(token): return
	atacando = false
	timer.start(intervalo_ataques)

func _proj(tipo: int, origem: Vector2, direcao: Vector2, velocidade: float, parry := false, atravessa_dash := false):
	var p = PROJETIL.instantiate()
	get_parent().add_child(p)
	p.global_position = origem
	p.configurar(tipo, direcao, velocidade, parry, atravessa_dash)
	return p

func _raio(posicao: Vector2, rotacao: float, seguir_x: bool, seguir_y: bool, seguir: float, travado: float, ativo_por: float, largura: float = 12.0, giro: float = 0.0):
	var raio = RAIO.instantiate()
	raio.global_position = posicao
	raio.rotation = rotacao
	raio.seguir_eixo_x = seguir_x
	raio.seguir_eixo_y = seguir_y
	raio.tempo_seguindo = seguir
	raio.tempo_travado = travado
	raio.tempo_ativo = ativo_por
	raio.largura = largura
	raio.velocidade_rotacao = giro
	get_parent().add_child(raio)
	return raio

func _aviso(regioes: Array[Rect2], duracao: float, ativo_por := 0.22) -> void:
	var p = PERIGO.instantiate()
	p.regioes = regioes
	p.tempo_aviso = duracao
	p.tempo_ativo = ativo_por
	p.letal = true
	get_parent().add_child(p)

func _lancas(token: int) -> void:
	ataque_anunciado.emit("LANCAS | CORRA ATE A MARCA TRAVAR", 1.0)
	for onda in range(4):
		var player := get_tree().get_first_node_in_group("tanque") as Node2D
		if not is_instance_valid(player): return
		# A marca persegue por 0.55 s, fica laranja ao travar e só então cai.
		_raio(Vector2(player.global_position.x,137), PI/2.0, true, false, 0.55, 0.42, 0.18, 10.0)
		await get_tree().create_timer(0.72).timeout
		if not _valido(token): return
		# A próxima marca já começa antes da anterior disparar, criando pressão
		# contínua sem esconder o instante em que cada posição foi travada.
		await get_tree().create_timer(0.22).timeout

func _asas(token: int) -> void:
	ataque_anunciado.emit("ASAS CELESTIAIS | DESVIE ENTRE AS PENAS", 1.0)
	sprite.frame = 6
	await get_tree().create_timer(1.0).timeout
	for onda in range(4):
		var player := get_tree().get_first_node_in_group("tanque") as Node2D
		var centro_angulo := spawn.global_position.direction_to(player.global_position).angle()
		# Três aberturas separadas atravessam o leque. Elas deslizam a cada
		# onda, oferecendo rotas diferentes sem formar uma linha reta segura.
		var brechas := [1+(onda%2),4+(onda%2),7-(onda%2)]
		for i in range(9):
			if i in brechas: continue
			var deslocamento := deg_to_rad(-52.0+i*13.0)
			_proj(0, spawn.global_position, Vector2.from_angle(centro_angulo+deslocamento), 118)
		await get_tree().create_timer(0.58).timeout
		if not _valido(token): return

func _olhar(token: int) -> void:
	var player := get_tree().get_first_node_in_group("tanque") as Node2D
	if not is_instance_valid(player): return
	ataque_anunciado.emit("OLHAR DIVINO | ESPERE A MIRA TRAVAR", 1.15)
	# O raio segue suavemente por 0.8 s, trava por 0.5 s e dispara. Dash cedo
	# demais não resolve: o jogador precisa ler a mudança dourado -> laranja.
	_raio(Vector2(player.global_position.x,137), PI/2.0, true, false, 0.8, 0.5, 0.32, 18.0)
	sprite.frame = 5
	await get_tree().create_timer(1.67).timeout
	if not _valido(token): return

func _cruz(token: int) -> void:
	ataque_anunciado.emit("CRUZ CELESTIAL | MUDE DE QUADRANTE", 1.0)
	var player := get_tree().get_first_node_in_group("tanque") as Node2D
	var centro := Vector2(clampf(player.global_position.x,65,189),clampf(player.global_position.y,125,195))
	_raio(centro, 0.0, false, false, 0.0, 1.05, 0.65, 13.0, 0.34)
	_raio(centro, PI/2.0, false, false, 0.0, 1.05, 0.65, 13.0, 0.34)
	# Penas atravessam os quadrantes enquanto a cruz gira.
	await get_tree().create_timer(0.58).timeout
	for lado in [-1.0,1.0]:
		for i in range(4):
			var origem := Vector2(5 if lado>0 else 249, 105+i*30)
			_proj(0,origem,Vector2(-lado,0.28*(i-1.5)).normalized(),145)
	await get_tree().create_timer(1.18).timeout
	if not _valido(token): return

func _falso_milagre(token: int) -> void:
	ataque_anunciado.emit("FALSO MILAGRE\nENCONTRE OS OLHOS AZUIS!", 1.35)
	sprite.frame = 7
	await get_tree().create_timer(1.15).timeout
	if not _valido(token): return
	falso_milagre_ativo = true
	premio_clone_concedido = false
	var posicoes := [35.0,81.0,127.0,173.0,219.0]
	var indice_real := randi_range(0,posicoes.size()-1)
	var posicao_original := global_position
	global_position = Vector2(posicoes[indice_real],72)
	var clones: Array[Node] = []
	for indice in range(posicoes.size()):
		if indice == indice_real: continue
		var clone = CLONE.instantiate()
		var clone_sprite := clone.get_node("Sprite2D") as Sprite2D
		clone_sprite.texture = sprite.texture
		clone_sprite.hframes = 4; clone_sprite.vframes = 3; clone_sprite.frame = 7
		clone_sprite.position = sprite.position; clone_sprite.scale = sprite.scale
		clone_sprite.modulate = Color(1.25,0.82,0.2,0.62)
		get_parent().add_child(clone)
		clone.global_position = Vector2(posicoes[indice],72)
		clones.append(clone)
	await get_tree().create_timer(0.75).timeout
	for x in posicoes:
		var player := get_tree().get_first_node_in_group("tanque") as Node2D
		for espalhamento in [-0.16,0.0,0.16]:
			_proj(0, Vector2(x,82), Vector2(x,82).direction_to(player.global_position).rotated(espalhamento), 158)
	await get_tree().create_timer(1.35).timeout
	falso_milagre_ativo = false
	for clone in clones:
		if is_instance_valid(clone): clone.queue_free()
	global_position = posicao_original
	if not _valido(token): return

func mira_bloqueada() -> bool:
	return falso_milagre_ativo

func _veredito(token: int, final := false) -> void:
	ataque_anunciado.emit("ULTIMO JULGAMENTO | PARRY!" if final else "VEREDITO | DEVOLVA COM PARRY", 1.15)
	sprite.frame = 10 if final else 7
	await get_tree().create_timer(1.05).timeout
	if not _valido(token): return
	var player := get_tree().get_first_node_in_group("tanque") as Node2D
	var orbe = _proj(1, spawn.global_position, spawn.global_position.direction_to(player.global_position), 92 if final else 108, true)
	orbe.teleguiado = true
	orbe.velocidade_curva = 1.25 if final else 0.95
	await get_tree().create_timer(1.65).timeout

func _ascensao(token: int) -> void:
	ataque_anunciado.emit("ASCENSAO | SOBREVIVA AO MERGULHO", 1.0)
	var antiga := global_position
	var subir := create_tween(); subir.tween_property(self,"global_position:y",-55.0,0.55)
	await subir.finished
	for onda in range(4):
		var alvo_player := get_tree().get_first_node_in_group("tanque") as Node2D
		var centro_alvo := alvo_player.global_position.x
		for coluna in range(11):
			var px := 7.0+coluna*24.0
			# Uma brecha estreita acompanha aproximadamente o jogador a cada onda.
			if absf(px-centro_alvo)<19.0: continue
			_proj(0,Vector2(px,-5),Vector2.DOWN,188)
		await get_tree().create_timer(0.32).timeout
		if not _valido(token): return
	var player := get_tree().get_first_node_in_group("tanque") as Node2D
	var x := clampf(player.global_position.x,30,224)
	# O mergulho é letal, mas a coluna vermelha permanece tempo suficiente
	# para leitura + deslocamento completo, mesmo após uma onda apertada.
	_aviso([Rect2(x-25,55,50,175)],1.25,0.22)
	await get_tree().create_timer(1.25).timeout
	global_position = Vector2(x,42)
	get_parent().tremer_tela(12,0.35)
	await get_tree().create_timer(0.3).timeout
	global_position = antiga

func receber_ataque(dano: int, postura: int) -> void:
	if morrendo or not ativo: return
	if falso_milagre_ativo:
		var player := get_tree().get_first_node_in_group("tanque")
		if is_instance_valid(player) and player.has_method("ativar_escudo_refletivo"):
			player.ativar_escudo_refletivo()
		if not premio_clone_concedido and is_instance_valid(player) and player.has_method("registrar_carga_misericordia"):
			premio_clone_concedido = true
			player.registrar_carga_misericordia()
	var perda := 0
	var golpe_misericordia := misericordia_pronta and dano >= 20
	if golpe_misericordia:
		perda = 34
		misericordia_pronta = false
		_quebrar_asas_misericordia()
	elif postura >= 40: perda = 18
	elif dano >= 8:
		perda = 3
	else:
		# Rajadas comuns só desgastam um ponto a cada oito impactos. A luta é
		# vencida pelo domínio do parry/Misericórdia, não segurando Z no chefe.
		impactos_comuns += 1
		if impactos_comuns >= 8:
			impactos_comuns = 0
			perda = 1
	julgamento = maxi(julgamento-perda, 0)
	vida_alterada.emit(julgamento, julgamento_maximo)
	postura_alterada.emit(julgamento_maximo-julgamento, julgamento_maximo)
	var flash := create_tween(); flash.tween_property(sprite,"modulate",Color(1.8,1.8,1.8),0.06); flash.tween_property(sprite,"modulate",Color.WHITE,0.12)
	if julgamento <= 0 and golpe_misericordia:
		_morrer()
	elif golpe_final and postura >= 40:
		julgamento = 0
		vida_alterada.emit(0, julgamento_maximo)
		_morrer()
	elif julgamento <= 14 and not golpe_final:
		_iniciar_ultimo_julgamento()

func ativar_misericordia() -> void:
	if morrendo or not ativo or em_cinematic_misericordia:
		return
	misericordia_pronta = true
	em_cinematic_misericordia = true
	geracao += 1
	timer.stop()
	atacando = true
	for perigo in get_tree().get_nodes_in_group("perigos_boss"):
		if is_instance_valid(perigo): perigo.queue_free()
	var player := get_tree().get_first_node_in_group("tanque")
	if is_instance_valid(player) and player.has_method("executar_misericordia"):
		player.executar_misericordia()

func misericordia_disponivel() -> bool:
	return misericordia_pronta

func finalizar_cinematic_misericordia() -> void:
	em_cinematic_misericordia = false
	if morrendo or not ativo or golpe_final:
		return
	atacando = false
	timer.start(1.0)

func _quebrar_asas_misericordia() -> void:
	# A chuva agora pertence ao Makoto; o Tung apenas sofre um impacto visual,
	# sem penas surgindo do nada ao redor do corpo.
	var escala_final := sprite.scale*0.96
	var impacto := create_tween().set_parallel(true)
	impacto.tween_property(sprite,"modulate",Color(0.7,0.88,1.0),0.22)
	impacto.tween_property(sprite,"scale",escala_final,0.22).set_trans(Tween.TRANS_BACK)

func _iniciar_ultimo_julgamento() -> void:
	golpe_final = true
	geracao += 1
	timer.stop()
	atacando = true
	for perigo in get_tree().get_nodes_in_group("perigos_boss"):
		if is_instance_valid(perigo): perigo.queue_free()
	await get_tree().create_timer(0.7).timeout
	var token := geracao
	# Se o jogador desviar, a sentença retorna até o parry final acontecer.
	while _valido(token) and golpe_final:
		await _veredito(token, true)
		if not _valido(token): return
		await get_tree().create_timer(0.8).timeout

func _morrer() -> void:
	if morrendo: return
	morrendo = true; ativo = false; geracao += 1; timer.stop()
	$CollisionShape2D.set_deferred("disabled",true)
	for perigo in get_tree().get_nodes_in_group("perigos_boss"):
		if is_instance_valid(perigo): perigo.queue_free()
	sprite.frame = 11
	velocity = Vector2.ZERO
	if get_parent().has_method("tremer_tela"):
		get_parent().tremer_tela(8.0,0.55)
	var feixe := Polygon2D.new()
	feixe.z_index = -2
	feixe.polygon = PackedVector2Array([Vector2(105,-20),Vector2(149,-20),Vector2(194,270),Vector2(60,270)])
	feixe.color = Color(1.0,0.92,0.5,0.0)
	get_parent().add_child(feixe)
	var abrir_feixe := create_tween()
	abrir_feixe.tween_property(feixe,"color:a",0.42,0.65).set_trans(Tween.TRANS_SINE)
	await abrir_feixe.finished
	var posicao_inicial := global_position
	var subir := create_tween().set_parallel(true)
	subir.tween_property(self,"global_position:y",-78.0,3.2).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	subir.tween_property(sprite,"scale",sprite.scale*1.18,3.2).set_trans(Tween.TRANS_SINE)
	subir.tween_property(sprite,"modulate",Color(1.65,1.55,1.15,1.0),2.25).set_trans(Tween.TRANS_SINE)
	for lote in range(11):
		_criar_particulas_ascensao(5,posicao_inicial.lerp(Vector2(posicao_inicial.x,-55),float(lote)/10.0))
		await get_tree().create_timer(0.24).timeout
	await subir.finished
	var clarão := create_tween().set_parallel(true)
	clarão.tween_property(sprite,"modulate:a",0.0,0.7)
	clarão.tween_property(feixe,"color:a",0.0,0.9)
	await clarão.finished
	feixe.queue_free()
	derrotado.emit(); queue_free()

func _criar_particulas_ascensao(quantidade: int, centro: Vector2) -> void:
	for i in range(quantidade):
		var particula := Polygon2D.new()
		var tamanho := randf_range(1.0,2.6)
		particula.polygon = PackedVector2Array([Vector2(0,-tamanho),Vector2(tamanho,0),Vector2(0,tamanho),Vector2(-tamanho,0)])
		particula.color = [Color("fff7cf"),Color("ffd966"),Color("dff8ff")].pick_random()
		get_parent().add_child(particula)
		particula.global_position = centro+Vector2(randf_range(-42,42),randf_range(-28,28))
		var voo := particula.create_tween().set_parallel(true)
		voo.tween_property(particula,"global_position",particula.global_position+Vector2(randf_range(-18,18),randf_range(-60,-24)),1.25)
		voo.tween_property(particula,"modulate:a",0.0,1.25)
		voo.tween_property(particula,"scale",Vector2.ONE*0.2,1.25)
		voo.chain().tween_callback(particula.queue_free)

func explosion() -> void:
	receber_ataque(1,2)
