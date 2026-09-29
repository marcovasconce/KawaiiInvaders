extends Area2D

var velocidadeTiro = 200
# Velocidade do giro (quanto maior o número, mais rápido ele gira)
var velocidadeGiro = 10.0 
var tiro_makoto := false
var tempo_vida := 0.0
var consumido := false
var dano_impacto := 1
var dano_postura := 2
var tiro_carregado := false
var tempo_animacao_carga := 0.0
var intervalo_particula := 0.0
var tiro_misericordia := false
var atravessou_alvo := false
var emitir_particulas_carga := true
var forcar_mira_boss := false

func _process(delta):
	if consumido:
		return
	if tiro_carregado:
		tempo_animacao_carga += delta
		intervalo_particula -= delta
		if emitir_particulas_carga and intervalo_particula <= 0.0:
			intervalo_particula = 0.035
			_emitir_particula_aura()
		var aura_carga := get_node_or_null("AuraMakoto") as Polygon2D
		if aura_carga:
			aura_carga.scale = Vector2.ONE * (1.65 + 0.15 * sin(tempo_animacao_carga * 14.0))
	tempo_vida += delta
	if tempo_vida > 5.0 or global_position.y < -40.0 or global_position.x < -40.0 or global_position.x > 294.0:
		consumido = true
		get_parent().queue_free()
		return
	var boss := get_tree().get_first_node_in_group("boss") as Node2D if tiro_makoto else null
	if atravessou_alvo:
		position.y -= velocidadeTiro * delta
	elif is_instance_valid(boss) and boss.ativo and not boss.morrendo and (forcar_mira_boss or not boss.has_method("mira_bloqueada") or not boss.mira_bloqueada()):
		var direcao := global_position.direction_to(boss.global_position)
		global_rotation = direcao.angle() + PI / 2.0
		global_position = global_position.move_toward(boss.global_position, velocidadeTiro * delta)
	else:
		position.y -= velocidadeTiro * delta
		if tiro_makoto:
			rotation = 0.0
	
	# Faz o sprite girar continuamente
	if not tiro_makoto:
		rotation += velocidadeGiro * delta

func configurar_como_makoto() -> void:
	tiro_makoto = true
	velocidadeTiro = 280
	velocidadeGiro = 0.0
	$Sprite2D.visible = false

	var aura := Polygon2D.new()
	aura.name = "AuraMakoto"
	aura.polygon = PackedVector2Array([
		Vector2(0, -8),
		Vector2(3, 1),
		Vector2(0, 7),
		Vector2(-3, 1)
	])
	aura.color = Color(0.05, 0.45, 1.0, 0.75)
	aura.position = Vector2(0, -3.5)
	add_child(aura)

	var nucleo := Polygon2D.new()
	nucleo.name = "NucleoMakoto"
	nucleo.polygon = PackedVector2Array([
		Vector2(0, -6),
		Vector2(1.4, 1),
		Vector2(0, 5),
		Vector2(-1.4, 1)
	])
	nucleo.color = Color(0.75, 0.95, 1.0, 1.0)
	nucleo.position = Vector2(0, -3.5)
	add_child(nucleo)

func configurar_como_carregado(dano: int, postura: int) -> void:
	if not tiro_makoto:
		return
	tiro_carregado = true
	dano_impacto = maxi(dano, 2)
	dano_postura = maxi(postura, 0)
	velocidadeTiro = 340
	$CollisionShape2D.scale *= 1.5
	$AuraMakoto.color = Color(0.1, 0.55, 1.0, 0.8)
	$AuraMakoto.scale = Vector2.ONE * 1.65
	$NucleoMakoto.color = Color(0.85, 1.0, 1.0)
	$NucleoMakoto.scale = Vector2.ONE * 1.5
	for lado in [-1.0, 1.0]:
		var faisca := Polygon2D.new()
		faisca.polygon = PackedVector2Array([Vector2(0, -3), Vector2(2, 0), Vector2(0, 3), Vector2(-2, 0)])
		faisca.position = Vector2(lado * 6.0, -3.5)
		faisca.color = Color(0.4, 0.9, 1.0, 0.85)
		add_child(faisca)

func configurar_misericordia() -> void:
	tiro_misericordia = true
	dano_impacto = maxi(dano_impacto, 30)
	dano_postura = maxi(dano_postura, 30)
	velocidadeTiro = 430
	$CollisionShape2D.scale *= 1.45
	$AuraMakoto.color = Color(0.78,0.98,1.0,0.92)
	$AuraMakoto.scale = Vector2(3.2,2.0)
	$NucleoMakoto.color = Color.WHITE
	$NucleoMakoto.scale = Vector2(2.2,1.8)
	emitir_particulas_carga = false

func desativar_particulas_carga() -> void:
	emitir_particulas_carga = false

func configurar_mira_misericordia() -> void:
	forcar_mira_boss = true

func _emitir_particula_aura() -> void:
	if not is_inside_tree():
		return
	var particula := Polygon2D.new()
	particula.polygon = PackedVector2Array([
		Vector2(0, -2.5), Vector2(1.8, 0), Vector2(0, 2.5), Vector2(-1.8, 0)
	])
	particula.color = [Color(0.2, 0.65, 1.0, 0.9), Color(0.65, 0.95, 1.0, 0.95), Color(0.25, 0.25, 1.0, 0.85)].pick_random()
	get_tree().current_scene.add_child(particula)
	particula.global_position = global_position + Vector2(randf_range(-6.0, 6.0), randf_range(-6.0, 5.0))
	particula.rotation = randf_range(0.0, TAU)
	var deriva := Vector2(randf_range(-10.0, 10.0), randf_range(8.0, 20.0))
	var tween := particula.create_tween().set_parallel(true)
	tween.tween_property(particula, "global_position", particula.global_position + deriva, 0.32)
	tween.tween_property(particula, "modulate:a", 0.0, 0.32)
	tween.tween_property(particula, "scale", Vector2.ONE * 0.2, 0.32)
	tween.chain().tween_callback(particula.queue_free)

func configurar_dano_debug(novo_dano: int) -> void:
	dano_impacto = maxi(novo_dano, 1)
	modulate = Color(1.8, 0.55, 1.8, 1.0)

func _on_body_entered(body):
	if consumido:
		return
	# O projétil nasce perto do Makoto; nunca deve ser consumido ao tocar o
	# próprio jogador, mesmo se uma animação aproximar sprite e hitbox.
	if body.is_in_group("tanque"):
		return
	consumido = true
	if body.has_method("receber_ataque"):
		body.receber_ataque(dano_impacto, dano_postura)
	elif body.has_method("explosion"):
		body.explosion()

	if tiro_misericordia and body.is_in_group("boss"):
		# O golpe continua pela tela depois de atravessar o chefe.
		consumido = false
		atravessou_alvo = true
		set_deferred("monitoring", false)
	else:
		get_parent().queue_free()
