extends Area2D

enum Tipo { PENA, ORBE, LANCA }

@export var tipo := Tipo.PENA
@export var velocidade := 135.0
@export var permite_parry := false
@export var ignora_dash := false
var direcao := Vector2.DOWN
var refletido := false
var consumido := false
var tempo := 0.0
var giro := 0.0
var teleguiado := false
var velocidade_curva := 1.55
var azul_misericordia := false
var refletido_por_escudo := false

func _ready() -> void:
	add_to_group("perigos_boss")
	queue_redraw()

func configurar(novo_tipo: Tipo, nova_direcao: Vector2, nova_velocidade: float, parry := false, atravessa_dash := false) -> void:
	tipo = novo_tipo
	direcao = nova_direcao.normalized()
	velocidade = nova_velocidade
	permite_parry = parry
	ignora_dash = atravessa_dash
	var forma := RectangleShape2D.new()
	match tipo:
		Tipo.PENA: forma.size = Vector2(5, 12)
		Tipo.ORBE: forma.size = Vector2(16, 16)
		Tipo.LANCA: forma.size = Vector2(7, 22)
	$CollisionShape2D.set_deferred("shape", forma)
	queue_redraw()

func _physics_process(delta: float) -> void:
	if consumido:
		return
	tempo += delta
	if refletido:
		var chefe := get_tree().get_first_node_in_group("boss") as Node2D
		if is_instance_valid(chefe):
			direcao = global_position.direction_to(chefe.global_position)
	elif teleguiado:
		var player := get_tree().get_first_node_in_group("tanque") as Node2D
		if is_instance_valid(player):
			var desejada := global_position.direction_to(player.global_position)
			direcao = direcao.rotated(clampf(direcao.angle_to(desejada), -velocidade_curva*delta, velocidade_curva*delta))
	position += direcao * velocidade * delta
	giro += delta * (5.0 if tipo == Tipo.PENA else 2.0)
	rotation = direcao.angle() + PI / 2.0 + sin(giro) * (0.12 if tipo == Tipo.PENA else 0.0)
	queue_redraw()
	if tempo > 9.0 or global_position.x < -70 or global_position.x > 324 or global_position.y < -90 or global_position.y > 320:
		queue_free()

func _draw() -> void:
	var dourado := Color("8be9ff") if azul_misericordia else Color("fff5c7")
	var detalhe := Color("45aaff") if azul_misericordia else Color("d6a936")
	match tipo:
		Tipo.PENA:
			draw_colored_polygon(PackedVector2Array([Vector2(0,-8),Vector2(3,-1),Vector2(1,7),Vector2(0,4),Vector2(-1,7),Vector2(-3,-1)]), dourado)
			draw_line(Vector2(0,-6), Vector2(0,6), detalhe, 1.0)
		Tipo.ORBE:
			var pulso := 1.0 + sin(tempo * 9.0) * 0.12
			draw_circle(Vector2.ZERO, 10.0 * pulso, Color(0.25,0.75,1.0,0.18))
			draw_circle(Vector2.ZERO, 6.0 * pulso, Color("67d8ff"))
			draw_circle(Vector2.ZERO, 3.0, Color.WHITE)
			draw_arc(Vector2.ZERO, 12.0, 0, TAU, 20, Color("ffd85a"), 1.4)
		Tipo.LANCA:
			draw_colored_polygon(PackedVector2Array([Vector2(0,-14),Vector2(4,-5),Vector2(2,11),Vector2(0,15),Vector2(-2,11),Vector2(-4,-5)]), dourado)
			draw_line(Vector2(0,-10), Vector2(0,12), detalhe, 2.0)

func ativar_misericordia_visual() -> void:
	azul_misericordia = true
	modulate = Color(0.65, 0.9, 1.35)
	queue_redraw()

func _on_body_entered(body: Node) -> void:
	if consumido:
		return
	if body.is_in_group("tanque") and not refletido:
		if permite_parry and body.has_method("deve_auto_parry_projetil") and body.deve_auto_parry_projetil():
			refletido = true
			velocidade *= 2.25
			var chefe_pro := get_tree().get_first_node_in_group("boss") as Node2D
			direcao = global_position.direction_to(chefe_pro.global_position) if is_instance_valid(chefe_pro) else Vector2.UP
			modulate = Color(0.45, 0.9, 1.6)
			body.aplicar_impacto_visual()
			return
		if tipo == Tipo.PENA and body.has_method("escudo_refletivo_ativo") and body.escudo_refletivo_ativo():
			refletido = true
			refletido_por_escudo = true
			velocidade *= 2.0
			var chefe_escudo := get_tree().get_first_node_in_group("boss") as Node2D
			direcao = global_position.direction_to(chefe_escudo.global_position) if is_instance_valid(chefe_escudo) else Vector2.UP
			ativar_misericordia_visual()
			return
		if permite_parry and body.esta_no_parry:
			refletido = true
			velocidade *= 2.25
			direcao = global_position.direction_to(get_tree().get_first_node_in_group("boss").global_position)
			modulate = Color(0.45, 0.9, 1.6)
			body.aplicar_impacto_visual()
			return
		if body.has_method("esta_invulneravel") and body.esta_invulneravel() and not ignora_dash:
			queue_free()
			return
		if ignora_dash and body.has_method("destruir_sem_iframe"):
			body.destruir_sem_iframe()
		else:
			body.destruir()
		queue_free()
	elif refletido and body.is_in_group("boss") and body.has_method("receber_ataque"):
		consumido = true
		body.receber_ataque(8, 30 if refletido_por_escudo else 60)
		queue_free()
