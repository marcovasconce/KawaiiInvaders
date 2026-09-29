extends Node2D

@export var modo_boss := false

const LARGURA := 254.0
const ALTURA := 256.0
const ESTRELAS := [
	Vector2(11, 16), Vector2(37, 35), Vector2(71, 12), Vector2(109, 29),
	Vector2(151, 13), Vector2(192, 39), Vector2(230, 17), Vector2(246, 54),
	Vector2(17, 76), Vector2(54, 91), Vector2(96, 73), Vector2(136, 88),
	Vector2(174, 69), Vector2(215, 97), Vector2(239, 122), Vector2(27, 133),
	Vector2(75, 119), Vector2(161, 131), Vector2(204, 152), Vector2(14, 177),
	Vector2(62, 169), Vector2(118, 158), Vector2(182, 184), Vector2(236, 191),
]

var tempo := 0.0
var modo_makoto := false
var mistura_makoto := 0.0

func ativar_modo_makoto() -> void:
	modo_makoto = true
	var transicao := create_tween()
	transicao.tween_property(self, "mistura_makoto", 1.0, 0.85).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	queue_redraw()

func _process(delta: float) -> void:
	tempo += delta
	queue_redraw()

func _draw() -> void:
	if modo_boss:
		_desenhar_arena_boss()
	else:
		_desenhar_invasao(
			Color("211335").lerp(Color("0c1d37"), mistura_makoto),
			Color("392257").lerp(Color("123458"), mistura_makoto),
			Color("80569f").lerp(Color("326998"), mistura_makoto)
		)
	_desenhar_estrelas()
	_desenhar_horizonte()

func _desenhar_invasao(ceu: Color, nebulosa: Color, detalhe: Color) -> void:
	draw_rect(Rect2(0, 0, LARGURA, ALTURA), ceu)
	# Nuvens quadriculadas dão profundidade sem competir com os projéteis.
	var deriva := sin(tempo * 0.18) * 3.0
	for i in 5:
		var largura := 48.0 + i * 10.0
		var x := -20.0 + i * 7.0 + deriva
		draw_rect(Rect2(x, 89 + i * 9, largura, 8), nebulosa.darkened(i * 0.08))
		draw_rect(Rect2(192 - i * 6 - deriva, 117 + i * 8, largura, 7), nebulosa)
	var lua := Vector2(209, 76)
	draw_circle(lua, 29, detalhe.darkened(0.54))
	draw_circle(lua + Vector2(-3, -3), 24, detalhe)
	draw_circle(lua + Vector2(-10, -11), 5, detalhe.lightened(0.25))
	draw_circle(lua + Vector2(8, 4), 4, detalhe.darkened(0.26))
	draw_arc(lua, 36, 0.2, 2.8, 35, detalhe.lightened(0.15), 1.0)
	draw_rect(Rect2(0, 153, LARGURA, 2), detalhe.darkened(0.45))

func _desenhar_arena_boss() -> void:
	draw_rect(Rect2(0, 0, LARGURA, ALTURA), Color("0a1020"))
	draw_rect(Rect2(0, 37, LARGURA, 102), Color("111a31"))
	draw_rect(Rect2(0, 139, LARGURA, 117), Color("0d182b"))
	var centro := Vector2(127, 103)
	draw_circle(centro, 58, Color(0.12, 0.35, 0.55, 0.12))
	draw_arc(centro, 62, 0, TAU, 80, Color(0.16, 0.47, 0.68, 0.25), 1.0)
	draw_arc(centro, 76, 0, TAU, 80, Color(0.12, 0.35, 0.56, 0.15), 1.0)
	# Pilares laterais e luzes dão identidade própria à arena.
	for x in [5.0, 238.0]:
		draw_rect(Rect2(x, 43, 11, 166), Color("172944"))
		draw_rect(Rect2(x + 3, 52, 5, 146), Color("234265"))
		for y in [65.0, 110.0, 155.0]:
			draw_rect(Rect2(x + 2, y, 7, 2), Color("3a87a3"))
	for y in [151.0, 177.0, 203.0]:
		draw_rect(Rect2(24, y, 206, 1), Color(0.19, 0.46, 0.6, 0.16))

func _desenhar_estrelas() -> void:
	var base := Color("a9d4ed") if modo_boss else Color("d8a9ec").lerp(Color("a9d4ed"), mistura_makoto)
	for i in ESTRELAS.size():
		var p: Vector2 = ESTRELAS[i]
		var brilho := 0.4 + 0.6 * (0.5 + 0.5 * sin(tempo * 1.8 + i * 1.9))
		var cor := Color(base.r, base.g, base.b, brilho * 0.65)
		draw_rect(Rect2(p, Vector2.ONE), cor)
		if i % 7 == 0:
			draw_rect(Rect2(p + Vector2(-2, 0), Vector2(5, 1)), cor)
			draw_rect(Rect2(p + Vector2(0, -2), Vector2(1, 5)), cor)

func _desenhar_horizonte() -> void:
	var cor := Color("143451") if modo_boss else Color("4c2c68").lerp(Color("143451"), mistura_makoto)
	for i in 22:
		var x := float(i * 12)
		var altura := 13.0 + float((i * 17 + 5) % 5) * 5.0
		draw_rect(Rect2(x, 208 - altura, 10, altura), cor)
		if i % 3 == 0:
			draw_rect(Rect2(x + 4, 198 - altura, 2, 3), cor.lightened(0.18))
	draw_rect(Rect2(0, 208, LARGURA, 48), cor.darkened(0.38))
	for i in 9:
		var x := float(i * 32)
		draw_rect(Rect2(x, 218, 17, 2), cor.lightened(0.2))
