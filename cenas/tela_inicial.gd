extends Control

const TRANSICAO_OPCAO = preload("res://cenas/transicao_opcao.gd")
const AUDIO_UTIL = preload("res://cenas/audio_util.gd")
const MUSICA_MENU = preload("res://assets]/Assets Space Invades/sfx/MenuInicial.mp3")

@onready var botao_jogar: Button = $BotaoJogar
@onready var astronauta: TextureRect = $Astronauta

var tempo := 0.0

const ESTRELAS := [
	Vector2(16, 19), Vector2(43, 55), Vector2(211, 32), Vector2(239, 64),
	Vector2(22, 104), Vector2(234, 115), Vector2(12, 172), Vector2(40, 201),
	Vector2(220, 186), Vector2(239, 223), Vector2(18, 236), Vector2(204, 72),
]
const ESTRELAS_DISTANTES := [
	Vector2(9, 43), Vector2(30, 76), Vector2(69, 14), Vector2(184, 10),
	Vector2(225, 49), Vector2(246, 88), Vector2(7, 133), Vector2(45, 115),
	Vector2(212, 103), Vector2(242, 145), Vector2(13, 190), Vector2(51, 174),
	Vector2(209, 204), Vector2(245, 197), Vector2(31, 223), Vector2(183, 237),
]

func _ready() -> void:
	AUDIO_UTIL.tocar(self, MUSICA_MENU, true, -5.0)
	botao_jogar.grab_focus()

func _process(delta: float) -> void:
	tempo += delta
	astronauta.position.y = 69.0 + sin(tempo * 1.8) * 2.0
	queue_redraw()

func _draw() -> void:
	var centro := Vector2(size.x * 0.5, 141.0)
	draw_rect(Rect2(Vector2.ZERO, size), Color("120d29"))
	draw_rect(Rect2(0, 0, size.x, 85), Color("201139"))
	draw_rect(Rect2(0, 85, size.x, 99), Color("1a1238"))
	draw_rect(Rect2(0, 184, size.x, size.y - 184), Color("170e30"))
	_desenhar_nebulosa()
	_desenhar_planetas()
	for i in ESTRELAS_DISTANTES.size():
		var p: Vector2 = ESTRELAS_DISTANTES[i]
		var deslocamento := fposmod(tempo * (1.0 + float(i % 3)) + p.y, size.y)
		draw_rect(Rect2(p.x, deslocamento, 1, 1), Color(0.65, 0.49, 0.87, 0.48))
	draw_circle(centro, 80.0, Color(0.35, 0.17, 0.55, 0.22))
	draw_circle(centro, 63.0, Color(0.59, 0.32, 0.85, 0.12))
	draw_arc(centro, 83.0, 0.0, TAU, 80, Color(0.68, 0.43, 0.9, 0.28), 1.0)
	for i in ESTRELAS.size():
		var p: Vector2 = ESTRELAS[i]
		var brilho := 0.5 + 0.5 * sin(tempo * 2.0 + i * 1.7)
		var cor := Color(0.58 + brilho * 0.28, 0.38 + brilho * 0.27, 0.9, 0.55 + brilho * 0.45)
		draw_rect(Rect2(p - Vector2.ONE, Vector2(3, 3)), cor)
		if i % 3 == 0:
			draw_rect(Rect2(p + Vector2(-1, -4), Vector2(3, 9)), cor)
			draw_rect(Rect2(p + Vector2(-4, -1), Vector2(9, 3)), cor)
	draw_rect(Rect2(8, 8, size.x - 16, size.y - 16), Color(0.66, 0.39, 0.85, 0.26), false, 1.0)

func _desenhar_nebulosa() -> void:
	var deriva := sin(tempo * 0.25) * 3.0
	var nuvens := [
		Rect2(-20 + deriva, 68, 54, 14), Rect2(-8 + deriva, 58, 42, 10),
		Rect2(4 + deriva, 81, 48, 12), Rect2(16 + deriva, 96, 35, 8),
		Rect2(211 - deriva, 85, 60, 14), Rect2(224 - deriva, 71, 39, 13),
		Rect2(199 - deriva, 102, 48, 10), Rect2(-9 - deriva, 192, 63, 12),
		Rect2(206 + deriva, 214, 55, 9),
	]
	for i in nuvens.size():
		var cor := Color(0.48, 0.29, 0.72, 0.16 if i % 2 == 0 else 0.11)
		draw_rect(nuvens[i], cor)

func _desenhar_planetas() -> void:
	# Pequenos planetas laterais deixam o centro livre para a astronauta.
	var p_esquerdo := Vector2(18, 145 + sin(tempo * 0.5) * 1.5)
	draw_circle(p_esquerdo, 20, Color("54327e"))
	draw_circle(p_esquerdo + Vector2(-3, -3), 16, Color("a16ed1"))
	draw_circle(p_esquerdo + Vector2(-8, -7), 4, Color("c59ce9"))
	draw_circle(p_esquerdo + Vector2(4, 4), 3, Color("70489b"))
	draw_arc(p_esquerdo, 26, 0.2, PI - 0.15, 28, Color("c493e9"), 2)
	var p_direito := Vector2(239, 174 + sin(tempo * 0.42 + 2.0) * 2.0)
	draw_circle(p_direito, 16, Color("6b429d"))
	draw_circle(p_direito + Vector2(-2, -2), 12, Color("d289d7"))
	draw_circle(p_direito + Vector2(-5, -5), 3, Color("f0b9ec"))
	draw_arc(p_direito, 22, PI + 0.3, TAU - 0.2, 24, Color("ad70d7"), 2)

func _on_botao_jogar_pressed() -> void:
	botao_jogar.disabled = true
	var transicao = TRANSICAO_OPCAO.new()
	get_tree().root.add_child(transicao)
	transicao.iniciar("res://cenas/main.tscn", "INICIAR MISSAO", Color("a869eb"))
