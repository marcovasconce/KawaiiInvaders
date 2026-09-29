extends Control

const TRANSICAO_OPCAO = preload("res://cenas/transicao_opcao.gd")
const AUDIO_UTIL = preload("res://cenas/audio_util.gd")
const MUSICA_DERROTA = preload("res://assets]/Assets Space Invades/sfx/MenuDerrota.mp3")
const MUSICA_VITORIA = preload("res://assets]/Assets Space Invades/sfx/MakotoGanhando.mp3")
const PROGRESSO = preload("res://cenas/progresso.gd")

@export var vitoria := true

var tempo := 0.0
var posicao_arte := Vector2.ZERO
var reiniciar_na_arena_boss := true

@onready var arte: Sprite2D = $ArteMakoto

func _ready() -> void:
	AUDIO_UTIL.tocar(self, MUSICA_VITORIA if vitoria else MUSICA_DERROTA, not vitoria, -5.0)
	posicao_arte = arte.position
	if not vitoria and get_tree().has_meta("morte_makoto_na_arena_boss"):
		reiniciar_na_arena_boss = bool(get_tree().get_meta("morte_makoto_na_arena_boss"))
		$TungVulto.visible = reiniciar_na_arena_boss
	var botao_deus := get_node_or_null("DesafiarTungGod") as Button
	if is_instance_valid(botao_deus):
		botao_deus.visible = not vitoria and PROGRESSO.tung_god_desbloqueado()
	_animar_entrada()

func _animar_entrada() -> void:
	var cartao: Control = $Cartao
	var titulo: Label = $Titulo
	var subtitulo: Label = $Subtitulo
	var mensagem: Label = $Mensagem
	var botao_jogar: Button = $JogarNovamente
	var botao_menu: Button = $Menu
	var botao_deus := get_node_or_null("DesafiarTungGod") as Button
	var vulto: Sprite2D = $TungDerrotado if vitoria else $TungVulto
	var destino_arte := arte.position.x
	var destino_vulto := vulto.position.x
	var destino_titulo := titulo.position.x
	var destino_subtitulo := subtitulo.position.x
	var destino_mensagem := mensagem.position.x
	cartao.modulate.a = 0.0
	titulo.position.x -= 150.0
	subtitulo.position.x -= 175.0
	mensagem.position.x -= 120.0
	arte.position.x += 150.0
	arte.modulate.a = 0.0
	vulto.position.x += 85.0
	vulto.modulate.a = 0.0
	botao_jogar.modulate.a = 0.0
	botao_menu.modulate.a = 0.0
	botao_jogar.disabled = true
	botao_menu.disabled = true
	if is_instance_valid(botao_deus):
		botao_deus.modulate.a = 0.0
		botao_deus.disabled = true
	var entrada := create_tween().set_parallel(true)
	entrada.tween_property(cartao, "modulate:a", 1.0, 0.42)
	entrada.tween_property(titulo, "position:x", destino_titulo, 0.55).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	entrada.tween_property(subtitulo, "position:x", destino_subtitulo, 0.65).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT).set_delay(0.08)
	entrada.tween_property(mensagem, "position:x", destino_mensagem, 0.58).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT).set_delay(0.22)
	entrada.tween_property(arte, "position:x", destino_arte, 0.72).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	entrada.tween_property(arte, "modulate:a", 1.0, 0.5)
	entrada.tween_property(vulto, "position:x", destino_vulto, 0.68).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT).set_delay(0.1)
	entrada.tween_property(vulto, "modulate:a", 1.0, 0.5).set_delay(0.1)
	entrada.tween_property(botao_jogar, "modulate:a", 1.0, 0.4).set_delay(0.42)
	entrada.tween_property(botao_menu, "modulate:a", 1.0, 0.4).set_delay(0.52)
	if is_instance_valid(botao_deus) and botao_deus.visible:
		entrada.tween_property(botao_deus, "modulate:a", 1.0, 0.45).set_delay(0.34)
	await entrada.finished
	botao_jogar.disabled = false
	botao_menu.disabled = false
	if is_instance_valid(botao_deus) and botao_deus.visible:
		botao_deus.disabled = false
		botao_deus.grab_focus()
	else:
		botao_jogar.grab_focus()

func _process(delta: float) -> void:
	tempo += delta
	arte.position.y = posicao_arte.y + sin(tempo * (2.4 if vitoria else 1.2)) * (2.0 if vitoria else 0.6)
	queue_redraw()

func _draw() -> void:
	var fundo := Color(0.015, 0.035, 0.11) if vitoria else Color(0.06, 0.015, 0.045)
	var brilho := Color(0.18, 0.75, 1.0) if vitoria else Color(0.85, 0.13, 0.27)
	draw_rect(Rect2(0, 0, 254, 256), fundo)
	for i in range(29):
		var x := fmod(13.0 + i * 83.0, 254.0)
		var y := fmod(11.0 + i * 47.0, 256.0)
		var alpha := 0.12 + 0.14 * (0.5 + 0.5 * sin(tempo * 2.0 + i))
		draw_circle(Vector2(x, y), 1.0, Color(brilho.r, brilho.g, brilho.b, alpha))
	var pulso := 0.5 + 0.5 * sin(tempo * 2.6)
	if vitoria:
		draw_arc(Vector2(127, 118), 49.0 + pulso * 3.0, 0, TAU, 48, Color(0.25, 0.8, 1.0, 0.4), 2.0)
		draw_arc(Vector2(127, 118), 41.0, 0, TAU, 48, Color(0.2, 0.5, 1, 0.25), 1.0)
	else:
		draw_arc(Vector2(127, 122), 48.0, 0.25, PI * 1.05, 24, Color(0.9, 0.15, 0.25, 0.3 + pulso * 0.2), 2.0)
		draw_arc(Vector2(127, 122), 48.0, PI * 1.18, TAU - 0.3, 24, Color(0.9, 0.15, 0.25, 0.3 + pulso * 0.2), 2.0)
	draw_line(Vector2(14, 180), Vector2(240, 180), Color(brilho.r, brilho.g, brilho.b, 0.35), 1.0)

func _on_jogar_novamente_pressed() -> void:
	$JogarNovamente.disabled = true
	$Menu.disabled = true
	if not vitoria and reiniciar_na_arena_boss:
		get_tree().set_meta("reiniciar_boss_na_fase", true)
	_iniciar_transicao("res://cenas/main.tscn", "NOVO COMBATE")

func _on_menu_pressed() -> void:
	$JogarNovamente.disabled = true
	$Menu.disabled = true
	_iniciar_transicao("res://cenas/tela_inicial.tscn", "VOLTAR AO MENU")

func _on_desafiar_tung_god_pressed() -> void:
	var botao_deus := get_node_or_null("DesafiarTungGod") as Button
	if is_instance_valid(botao_deus): botao_deus.disabled = true
	$JogarNovamente.disabled = true
	$Menu.disabled = true
	get_tree().set_meta("iniciar_tung_god_direto", true)
	_iniciar_transicao("res://cenas/main.tscn", "JULGAMENTO DIVINO")

func _iniciar_transicao(destino: String, rotulo: String) -> void:
	var transicao = TRANSICAO_OPCAO.new()
	get_tree().root.add_child(transicao)
	transicao.iniciar(destino, rotulo, Color("35bce9") if vitoria else Color("df4f78"))
