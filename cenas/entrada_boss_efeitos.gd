extends Node2D

var ativo := false
var progresso := 0.0
var impacto := -1.0
var onda_pouso := -1.0
var tempo := 0.0

func _process(delta: float) -> void:
	if not ativo:
		return
	tempo += delta
	queue_redraw()

func _draw() -> void:
	if not ativo:
		return
	var pressao := clampf(progresso, 0.0, 1.0)
	var escuridao := 0.28 + pressao * 0.43
	if impacto >= 0.0:
		escuridao *= 1.0 - clampf(impacto, 0.0, 1.0)
	draw_rect(Rect2(0, 0, 254, 256), Color(0.005, 0.008, 0.025, escuridao))
	for i in 7:
		var x := float(12 + i * 39)
		var y := fposmod(tempo * (35.0 + i * 7.0) + i * 43.0, 256.0)
		var alpha := (0.12 + pressao * 0.35) * (0.6 if i % 2 == 0 else 1.0)
		draw_rect(Rect2(x, y, 2, 12 + i % 3 * 5), Color(0.33, 0.72, 1.0, alpha))
	var boss = get_parent().get_node_or_null("Boss")
	if boss and boss.visible and boss.position.y > -15.0:
		var centro: Vector2 = boss.position + Vector2(0, -4)
		var pulso := 2.0 * sin(tempo * 8.0)
		draw_arc(centro, 35.0 + pulso, 0, TAU, 48, Color(0.34, 0.7, 1.0, pressao * 0.5), 1.0)
		draw_arc(centro, 47.0 - pulso, 0, TAU, 48, Color(0.73, 0.9, 1.0, pressao * 0.3), 1.0)
	if impacto >= 0.0:
		var expansao := clampf(impacto, 0.0, 1.0)
		var centro_impacto := Vector2(127, 68)
		draw_arc(centro_impacto, 18.0 + expansao * 100.0, 0, TAU, 72,
			Color(0.75, 0.93, 1.0, (1.0 - expansao) * 0.8), 2.0)
		draw_rect(Rect2(0, 0, 254, 256), Color(0.65, 0.87, 1.0, (1.0 - expansao) * 0.28))
	if onda_pouso >= 0.0:
		var onda := clampf(onda_pouso, 0.0, 1.0)
		var centro_pouso := Vector2(127, 68)
		draw_arc(centro_pouso, 12.0 + onda * 105.0, 0, TAU, 72,
			Color(0.82, 0.96, 1.0, (1.0 - onda) * 0.9), 2.0)
		draw_arc(centro_pouso, 8.0 + onda * 65.0, 0, TAU, 56,
			Color(0.3, 0.72, 1.0, (1.0 - onda) * 0.6), 1.0)
		for i in 9:
			var angulo := float(i) * TAU / 9.0
			var ponto := centro_pouso + Vector2.from_angle(angulo) * (16.0 + onda * 75.0)
			draw_rect(Rect2(ponto, Vector2(2, 2)), Color(0.7, 0.93, 1.0, 1.0 - onda))
