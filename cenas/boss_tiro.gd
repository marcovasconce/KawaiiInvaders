extends Area2D

@export var velocidade := 190.0
@export var velocidade_rotacao := 12.0
var refletido := false
var direcao := Vector2.DOWN
var id_rajada := -1
var rajada_tripla := false
var tempo_vida := 0.0
var consumido := false
@export var permite_parry := true
var ignora_dash := false
var deslocamento_spawn := 0.0

func configurar_bastao_grande(textura: Texture2D) -> void:
	var sprite := $Sprite2D as Sprite2D
	var colisao := $CollisionShape2D as CollisionShape2D
	sprite.texture = textura
	sprite.scale = Vector2(0.034, 0.034)
	velocidade_rotacao = 8.0
	velocidade = 105.0
	deslocamento_spawn = 24.0
	if colisao.shape is RectangleShape2D:
		var formato := colisao.shape.duplicate() as RectangleShape2D
		formato.size = Vector2(14.0, 34.0)
		colisao.shape = formato

func _ready() -> void:
	add_to_group("perigos_boss")

func _physics_process(delta: float) -> void:
	if consumido or is_queued_for_deletion():
		return
	tempo_vida += delta
	if tempo_vida > 7.0 or global_position.y > 275 or global_position.y < -80 or global_position.x < -80 or global_position.x > 334:
		queue_free()
		return
	if rajada_tripla and not refletido:
		var jogador := get_tree().get_first_node_in_group("tanque")
		if is_instance_valid(jogador) and jogador.has_method("pode_auto_parry_rajada") and jogador.pode_auto_parry_rajada(id_rajada):
			refletir_para_boss(jogador, false)
	if refletido:
		var boss := get_tree().get_first_node_in_group("boss") as Node2D
		if is_instance_valid(boss) and not boss.morrendo:
			direcao = global_position.direction_to(boss.global_position)
	position += direcao * velocidade * delta
	if permite_parry:
		rotation += velocidade_rotacao * delta
	else:
		rotation = direcao.angle() - PI / 2.0

func _on_body_entered(body: Node) -> void:
	if consumido or is_queued_for_deletion():
		return
	if body.is_in_group("tanque"):
		if permite_parry and not refletido and body.has_method("deve_auto_parry_projetil") and body.deve_auto_parry_projetil():
			if rajada_tripla and body.has_method("registrar_auto_parry_rajada"):
				body.registrar_auto_parry_rajada(id_rajada)
			refletir_para_boss(body)
			return
		if body.has_method("esta_invulneravel") and body.esta_invulneravel():
			if ignora_dash and body.has_method("destruir_sem_iframe"):
				body.destruir_sem_iframe()
				queue_free()
				return
			if not permite_parry and body.has_method("absorver_energia_dash"):
				body.absorver_energia_dash()
			queue_free()
			return
		if permite_parry and body.esta_no_parry and not refletido:
			if rajada_tripla and body.has_method("registrar_auto_parry_rajada"):
				body.registrar_auto_parry_rajada(id_rajada)
			refletir_para_boss(body)
		elif not refletido:
			body.destruir()
			queue_free()
	elif body.is_in_group("blocos"):
		body.destruir()
		queue_free()
	elif refletido and body.has_method("receber_ataque"):
		consumido = true
		body.receber_ataque(6, 40)
		queue_free()

func refletir_para_boss(player: Node, mostrar_impacto := true) -> void:
	if refletido:
		return
	refletido = true
	velocidade *= 2.2
	modulate = Color(0.3, 0.85, 1.8, 1.0)
	var boss := get_tree().get_first_node_in_group("boss") as Node2D
	if is_instance_valid(boss):
		direcao = global_position.direction_to(boss.global_position)
	else:
		direcao = Vector2.UP
	if mostrar_impacto:
		player.aplicar_impacto_visual()
