extends Area2D

@export var tempo_aviso := 1.0
@export var tempo_ativo := 0.22
@export var letal := true
var regioes: Array[Rect2] = []
var tempo := 0.0

func _ready() -> void:
	add_to_group("perigos_boss")
	for regiao in regioes:
		if regiao.size.x <= 0:
			continue
		var forma := RectangleShape2D.new()
		forma.size = regiao.size
		var colisao := CollisionShape2D.new()
		colisao.shape = forma
		colisao.position = regiao.get_center()
		add_child(colisao)

func _physics_process(delta: float) -> void:
	if is_queued_for_deletion():
		return
	tempo += delta
	queue_redraw()
	if tempo >= tempo_aviso + tempo_ativo:
		queue_free()
		return
	if letal and tempo >= tempo_aviso:
		for body in get_overlapping_bodies():
			if body.is_in_group("tanque") and body.has_method("destruir_sem_iframe"):
				body.destruir_sem_iframe()

func _draw() -> void:
	var disparando := tempo >= tempo_aviso and letal
	var pulso := 0.5 + 0.5 * sin(tempo * 22)
	for regiao in regioes:
		if regiao.size.x <= 0:
			continue
		if disparando:
			draw_rect(regiao, Color(1, 0.08, 0.12, 0.65))
			for x in range(int(regiao.position.x) + 3, int(regiao.end.x), 9):
				draw_line(Vector2(x, regiao.position.y), Vector2(x, regiao.end.y), Color(1, 0.85, 0.75, 0.9), 3)
		else:
			draw_rect(regiao, Color(1, 0.1, 0.18, 0.08 + pulso * 0.10))
			draw_rect(regiao, Color(1, 0.2, 0.15, 0.65), false, 1)
			for y in range(int(regiao.position.y) + 5, int(regiao.end.y), 14):
				draw_line(Vector2(regiao.position.x, y), Vector2(regiao.end.x, y), Color(1, 0.3, 0.2, 0.16), 1)
