extends Area2D

@export var comprimento := 310.0
@export var largura := 12.0
@export var tempo_seguindo := 0.7
@export var tempo_travado := 0.45
@export var tempo_ativo := 0.25
@export var seguir_eixo_x := false
@export var seguir_eixo_y := false
@export var velocidade_rotacao := 0.0
@export var ignora_dash := false
var tempo := 0.0
var disparando := false
var consumiu_player := false

func _ready() -> void:
	add_to_group("perigos_boss")
	var forma := RectangleShape2D.new()
	forma.size = Vector2(comprimento, largura)
	$CollisionShape2D.shape = forma
	$CollisionShape2D.disabled = true
	queue_redraw()

func _physics_process(delta: float) -> void:
	tempo += delta
	var player := get_tree().get_first_node_in_group("tanque") as Node2D
	if tempo < tempo_seguindo and is_instance_valid(player):
		if seguir_eixo_x:
			global_position.x = move_toward(global_position.x, player.global_position.x, 155.0 * delta)
		if seguir_eixo_y:
			global_position.y = move_toward(global_position.y, player.global_position.y, 125.0 * delta)
	rotation += velocidade_rotacao * delta
	var inicio_disparo := tempo_seguindo + tempo_travado
	if not disparando and tempo >= inicio_disparo:
		disparando = true
		$CollisionShape2D.set_deferred("disabled", false)
	if disparando:
		for body in get_overlapping_bodies():
			if consumiu_player or not body.is_in_group("tanque"):
				continue
			consumiu_player = true
			if ignora_dash and body.has_method("destruir_sem_iframe"):
				body.destruir_sem_iframe()
			elif not body.has_method("esta_invulneravel") or not body.esta_invulneravel():
				body.destruir()
	if tempo >= inicio_disparo + tempo_ativo:
		queue_free()
	queue_redraw()

func _draw() -> void:
	var metade := comprimento * 0.5
	var ret := Rect2(-metade, -largura*0.5, comprimento, largura)
	if disparando:
		draw_rect(ret, Color(1.0,0.82,0.22,0.9))
		draw_rect(Rect2(-metade,-largura*0.16,comprimento,largura*0.32), Color(1,1,0.92,1))
		return
	var travado := tempo >= tempo_seguindo
	var pulso := 0.5 + 0.5*sin(tempo*(24.0 if travado else 12.0))
	var cor := Color(1.0,0.38,0.12,0.55+pulso*0.3) if travado else Color(1.0,0.86,0.25,0.25+pulso*0.25)
	draw_rect(ret, Color(cor.r,cor.g,cor.b,0.06+pulso*0.08))
	draw_rect(ret, cor, false, 1.5 if travado else 1.0)
	for x in range(int(-metade), int(metade), 18):
		draw_line(Vector2(x,-largura*0.5),Vector2(x+8,largura*0.5),Color(cor.r,cor.g,cor.b,cor.a*0.55),1)
