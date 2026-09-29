extends Node2D

@export var tempo_aviso := 1.0
var tempo := 0.0
var ativado := false

@onready var haste: Node2D = $Haste
@onready var colisao: CollisionShape2D = $Haste/Area2D/CollisionShape2D

func _ready() -> void:
	add_to_group("perigos_boss")
	colisao.disabled = true
	haste.position.y = 72.0
	_iniciar()

func _process(delta: float) -> void:
	tempo += delta
	queue_redraw()

func _draw() -> void:
	if ativado:
		return
	var pulso := 0.5 + 0.5 * sin(tempo * 24.0)
	var pontos := PackedVector2Array()
	for i in range(32):
		var angulo := TAU * float(i) / 32.0
		pontos.append(Vector2(cos(angulo) * (17.0 + pulso * 3.0), sin(angulo) * 4.5))
	draw_colored_polygon(pontos, Color(1.0, 0.05, 0.18, 0.18 + pulso * 0.22))
	draw_arc(Vector2.ZERO, 15.0 + pulso * 2.0, PI, TAU, 24, Color(1.0, 0.18, 0.3, 0.9), 2.0)
	for x in [-10.0, 0.0, 10.0]:
		draw_line(Vector2(x - 3.0, 3.0), Vector2(x + 3.0, -3.0), Color(1.0, 0.35, 0.25, 0.8), 1.0)

func _iniciar() -> void:
	await get_tree().create_timer(tempo_aviso).timeout
	if not is_inside_tree():
		return
	ativado = true
	queue_redraw()
	colisao.set_deferred("disabled", false)
	var subida := create_tween()
	subida.tween_property(haste, "position:y", -25.0, 0.14).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	await subida.finished
	await get_tree().create_timer(0.22).timeout
	colisao.set_deferred("disabled", true)
	var descida := create_tween()
	descida.tween_property(haste, "position:y", 72.0, 0.18).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	await descida.finished
	queue_free()

func _on_area_2d_body_entered(body: Node) -> void:
	if body.is_in_group("tanque") and body.has_method("destruir_sem_iframe"):
		body.destruir_sem_iframe()
