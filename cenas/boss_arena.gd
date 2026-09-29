extends Node

const SILHUETA_TUNG = preload("res://cenas/silhueta_tung.gdshader")
const TRANSICAO_RESULTADO = preload("res://cenas/transicao_resultado.gd")
const AUDIO_UTIL = preload("res://cenas/audio_util.gd")
const SFX_CHEGADA = preload("res://assets]/Assets Space Invades/sfx/TungChegando.mp3")
const SFX_AVISO = preload("res://assets]/Assets Space Invades/sfx/BarulhoAviso.mp3")
const MUSICA_BATALHA = preload("res://assets]/Assets Space Invades/sfx/BatalhaTung.mp3")
const MUSICA_SEGUNDA_FASE = preload("res://assets]/Assets Space Invades/sfx/SegundaFaseTung.mp3")
const MUSICA_FASE_TRES = preload("res://assets]/Assets Space Invades/sfx/Fase3Tung.mp3")
const MUSICA_TUNG_GOD = preload("res://assets]/Assets Space Invades/sfx/TungGodEntrando.mp3")
const CENA_TUNG_GOD = preload("res://cenas/tung_god.tscn")
const EFEITOS_TUNG_GOD = preload("res://cenas/tung_god_efeitos.gd")
const PROGRESSO = preload("res://cenas/progresso.gd")

@export var espera_antes_aviso := 0.7
@export var duracao_entrada_boss := 4.6
@export var forca_maxima_tremor := 10.0
@export var embutida := false
@export var pular_intro := false
@export var pular_fase_tres := false
@export var pular_fase_quatro := false
@export_category("Mensagem final")
@export_multiline var texto_vitoria_triste := "Voce vence."
@export_multiline var texto_custo_triste := "Mas a que custo?..."
@export_range(0.01, 0.25, 0.01) var intervalo_digitacao := 0.075
@export_range(0.0, 3.0, 0.1) var pausa_entre_frases := 0.7
@export_range(0.5, 6.0, 0.1) var tempo_final_visivel := 2.4

@onready var boss = $Boss
@onready var aviso_ui: Control = $CanvasLayer/AvisoBoss
@onready var aviso: Label = $CanvasLayer/AvisoBoss/Margem/Aviso
@onready var interface_boss: Control = $CanvasLayer/InterfaceBoss
@onready var barra_vida: ProgressBar = $CanvasLayer/InterfaceBoss/BarraVida
@onready var barra_postura: ProgressBar = $CanvasLayer/InterfaceBoss/BarraPostura
@onready var aviso_ataque: Label = $CanvasLayer/InterfaceBoss/AvisoAtaque
@onready var dash_label: Label = $CanvasLayer/InterfaceBoss/DashLabel
@onready var barra_dash: ProgressBar = $CanvasLayer/InterfaceBoss/BarraDash
@onready var jogador = get_parent().get_node("jogador") if embutida else $jogador
@onready var entrada_efeitos: Node2D = $EntradaEfeitos
@onready var final_triste: Control = $CanvasLayer/FinalTriste
@onready var frase_vitoria: Label = $CanvasLayer/FinalTriste/FraseVitoria
@onready var frase_custo: Label = $CanvasLayer/FinalTriste/FraseCusto

var tremor_ativo := false
var tremor_inicio_ms := 0
var tremor_fim_ms := 0
var canvas_original := Transform2D.IDENTITY
var tempo_aviso_ataque := 0.0
var tremor_forca := 10.0
var tremor_impacto := false
var musica_batalha: AudioStreamPlayer
var musica_fase_tres: AudioStreamPlayer
var audio_chegada: AudioStreamPlayer
var musica_segunda_fase_ativa := false
var musica_tung_god: AudioStreamPlayer
var fase_quatro_ativa := false
var efeitos_tung_god: Node2D

func _ready() -> void:
	aviso_ui.visible = false
	interface_boss.visible = false
	final_triste.visible = false
	boss.vida_alterada.connect(_on_boss_vida_alterada)
	boss.postura_alterada.connect(_on_boss_postura_alterada)
	boss.derrotado.connect(_on_boss_derrotado)
	boss.ataque_anunciado.connect(_on_ataque_anunciado)
	boss.fase_dois_iniciada.connect(_on_fase_dois_iniciada)
	boss.fase_tres_iniciada.connect(_on_fase_tres_iniciada)
	if pular_fase_quatro:
		call_deferred("pular_para_fase_quatro_debug")
	elif pular_intro:
		call_deferred("pular_para_fase_tres_debug" if pular_fase_tres else "pular_para_fase_dois_debug")
	else:
		comecar_introducao()

func pular_para_fase_quatro_debug() -> void:
	parar_tremor()
	aviso_ui.visible = false
	entrada_efeitos.ativo = false
	entrada_efeitos.visible = false
	if is_instance_valid(boss):
		boss.queue_free()
	await _iniciar_fase_quatro()

func pular_para_fase_dois_debug() -> void:
	parar_tremor()
	aviso_ui.visible = false
	entrada_efeitos.ativo = false
	entrada_efeitos.visible = false
	boss.visible = true
	boss.global_position.y = 68.0
	boss.scale = Vector2.ONE
	boss.sprite.material = null
	interface_boss.visible = true
	if not boss.ativo:
		boss.ativar_combate()
	boss.ativar_fase_dois_debug()
	_iniciar_musica_segunda_fase()

func pular_para_fase_tres_debug() -> void:
	parar_tremor()
	aviso_ui.visible = false
	entrada_efeitos.ativo = false
	entrada_efeitos.visible = false
	boss.visible = true
	boss.global_position.y = 68.0
	boss.scale = Vector2.ONE
	boss.sprite.material = null
	interface_boss.visible = true
	if not boss.ativo:
		boss.ativar_combate()
	boss.ativar_fase_tres_debug()

func _process(delta: float) -> void:
	tempo_aviso_ataque = maxf(tempo_aviso_ataque - delta, 0.0)
	aviso_ataque.visible = tempo_aviso_ataque > 0.0
	if is_instance_valid(jogador):
		var total: float = jogador.duracao_dash + jogador.recarga_dash
		barra_dash.value = 100.0 * (1.0 - jogador.dash_recarga_restante / total)
		dash_label.text = "X: DASH PRONTO" if jogador.dash_disponivel else "DASH RECARREGANDO..."
		dash_label.modulate = Color(0.4, 0.85, 1) if jogador.dash_disponivel else Color(0.55, 0.55, 0.65)
	if not tremor_ativo:
		return

	var agora := Time.get_ticks_msec()
	if agora >= tremor_fim_ms:
		parar_tremor()
		return

	var duracao_ms: int = maxi(tremor_fim_ms - tremor_inicio_ms, 1)
	var progresso := float(agora - tremor_inicio_ms) / float(duracao_ms)
	var intensidade := tremor_forca * (1.0 - progresso) if tremor_impacto else lerpf(0.3, tremor_forca, progresso * progresso)
	var deslocamento := Vector2(
		randf_range(-intensidade, intensidade),
		randf_range(-intensidade, intensidade)
	)
	var transform_sacudido := canvas_original
	transform_sacudido.origin += deslocamento
	get_viewport().canvas_transform = transform_sacudido

func comecar_introducao() -> void:
	audio_chegada = AUDIO_UTIL.tocar(self, SFX_CHEGADA, false, -2.0)
	await get_tree().create_timer(espera_antes_aviso).timeout
	if not is_inside_tree():
		return
	aviso_ui.visible = true
	aviso_ui.modulate.a = 1.0
	aviso_ui.pivot_offset = aviso_ui.size * 0.5
	aviso_ui.scale = Vector2.ONE * 0.88
	create_tween().tween_property(aviso_ui, "scale", Vector2.ONE, 0.35).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	entrada_efeitos.ativo = true
	entrada_efeitos.progresso = 0.0
	entrada_efeitos.impacto = -1.0
	entrada_efeitos.onda_pouso = -1.0
	boss.preparar_entrada()
	var material_sombra := ShaderMaterial.new()
	material_sombra.shader = SILHUETA_TUNG
	boss.sprite.material = material_sombra
	boss.scale = Vector2.ONE * 0.72
	var entrada := create_tween()
	entrada.set_parallel(true)
	entrada.tween_property(boss, "global_position:y", 68.0, duracao_entrada_boss).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
	entrada.tween_property(boss, "scale", Vector2.ONE, duracao_entrada_boss).set_trans(Tween.TRANS_SINE)
	entrada.tween_property(entrada_efeitos, "progresso", 1.0, duracao_entrada_boss)
	iniciar_tremor_crescente(duracao_entrada_boss)
	await entrada.finished
	parar_tremor()
	# Segura a silhueta por um instante antes de revelar o rosto.
	boss.scale = Vector2(1.12, 0.84)
	var sumir_aviso := create_tween()
	sumir_aviso.tween_property(aviso_ui, "modulate:a", 0.0, 0.3)
	await get_tree().create_timer(0.36).timeout
	aviso_ui.visible = false
	# Revela o Tung no salto; o escuro se abre enquanto ele sobe.
	entrada_efeitos.impacto = 0.0
	boss.sprite.material = null
	create_tween().tween_property(entrada_efeitos, "impacto", 1.0, 0.8)
	var salto := create_tween()
	salto.tween_property(boss, "global_position:y", 42.0, 0.38).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	salto.tween_property(boss, "global_position:y", 68.0, 0.52).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
	var forma := create_tween()
	forma.tween_property(boss, "scale", Vector2(0.92, 1.14), 0.28).set_trans(Tween.TRANS_BACK)
	forma.tween_property(boss, "scale", Vector2.ONE, 0.62).set_trans(Tween.TRANS_SINE)
	await salto.finished
	# A onda e o tremor acontecem no pouso, nao durante o salto.
	boss.scale = Vector2(1.18, 0.82)
	create_tween().tween_property(boss, "scale", Vector2.ONE, 0.3).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	entrada_efeitos.onda_pouso = 0.0
	create_tween().tween_property(entrada_efeitos, "onda_pouso", 1.0, 0.4)
	tremer_tela(14.0, 0.35)
	await get_tree().create_timer(0.42).timeout
	parar_tremor()
	entrada_efeitos.ativo = false
	entrada_efeitos.queue_redraw()
	interface_boss.visible = true
	boss.ativar_combate()
	_iniciar_musica_batalha()

func _iniciar_musica_batalha() -> void:
	if is_instance_valid(audio_chegada):
		audio_chegada.stop()
		audio_chegada.queue_free()
	if not is_instance_valid(musica_batalha):
		musica_batalha = AUDIO_UTIL.tocar(self, MUSICA_BATALHA, true, -6.0)

func iniciar_tremor_crescente(duracao: float) -> void:
	parar_tremor()
	tremor_impacto = false
	tremor_forca = forca_maxima_tremor
	canvas_original = get_viewport().canvas_transform
	tremor_inicio_ms = Time.get_ticks_msec()
	tremor_fim_ms = tremor_inicio_ms + int(duracao * 1000.0)
	tremor_ativo = true

func tremer_tela(forca: float, duracao: float) -> void:
	iniciar_tremor_crescente(duracao)
	tremor_forca = forca
	tremor_impacto = true

func _on_ataque_anunciado(texto: String, duracao: float) -> void:
	# Player próprio: o aviso nunca corta chegada, música ou outro efeito.
	AUDIO_UTIL.tocar(self, SFX_AVISO, false, -1.0)
	aviso_ataque.text = texto
	tempo_aviso_ataque = duracao
	aviso_ataque.visible = true
	var clone_aviso := texto.begins_with("FALSO MILAGRE")
	aviso_ataque.add_theme_font_size_override("font_size", 12 if clone_aviso else 6)
	aviso_ataque.modulate = Color(1.0,0.9,0.35) if clone_aviso else Color.WHITE
	aviso_ataque.position = Vector2(5,88) if clone_aviso else Vector2(5,108)
	aviso_ataque.size = Vector2(244,52) if clone_aviso else Vector2(244,20)
	if clone_aviso:
		aviso_ataque.pivot_offset = aviso_ataque.size*0.5
		aviso_ataque.scale = Vector2.ONE*0.72
		var impacto_aviso := create_tween()
		impacto_aviso.tween_property(aviso_ataque,"scale",Vector2.ONE*1.08,0.18).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		impacto_aviso.tween_property(aviso_ataque,"scale",Vector2.ONE,0.16)
	else:
		aviso_ataque.scale = Vector2.ONE

func _on_fase_dois_iniciada(duracao: float) -> void:
	_iniciar_musica_segunda_fase()
	var camada := CanvasLayer.new()
	camada.layer = 80
	add_child(camada)
	var escuro := ColorRect.new()
	escuro.position = Vector2.ZERO
	escuro.size = Vector2(254, 256)
	escuro.color = Color(0.03, 0.0, 0.05, 0.0)
	escuro.mouse_filter = Control.MOUSE_FILTER_IGNORE
	camada.add_child(escuro)
	var barra_cima := ColorRect.new()
	barra_cima.position = Vector2(0, -30)
	barra_cima.size = Vector2(254, 28)
	barra_cima.color = Color("05020d")
	camada.add_child(barra_cima)
	var barra_baixo := ColorRect.new()
	barra_baixo.position = Vector2(0, 258)
	barra_baixo.size = Vector2(254, 28)
	barra_baixo.color = Color("05020d")
	camada.add_child(barra_baixo)
	if is_instance_valid(jogador) and not jogador.morrendo:
		jogador.set_physics_process(false)
		jogador.invulneravel = true
	var entrada := create_tween().set_parallel(true)
	entrada.tween_property(escuro, "color:a", 0.68, 0.35)
	entrada.tween_property(barra_cima, "position:y", 0.0, 0.3).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	entrada.tween_property(barra_baixo, "position:y", 228.0, 0.3).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	var pulso_boss := create_tween().set_loops(4)
	pulso_boss.tween_property(boss, "scale", Vector2.ONE * 1.18, 0.25).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	pulso_boss.tween_property(boss, "scale", Vector2.ONE, 0.35).set_trans(Tween.TRANS_SINE)
	await get_tree().create_timer(maxf(duracao - 0.45, 0.4)).timeout
	var saida := create_tween().set_parallel(true)
	saida.tween_property(escuro, "color:a", 0.0, 0.4)
	saida.tween_property(barra_cima, "position:y", -30.0, 0.4)
	saida.tween_property(barra_baixo, "position:y", 258.0, 0.4)
	await saida.finished
	boss.scale = Vector2.ONE
	if is_instance_valid(jogador) and not jogador.morrendo:
		jogador.invulneravel = false
		jogador.set_physics_process(true)
	camada.queue_free()

func _iniciar_musica_segunda_fase() -> void:
	if musica_segunda_fase_ativa:
		return
	musica_segunda_fase_ativa = true
	if is_instance_valid(musica_batalha):
		var fade_anterior := create_tween()
		fade_anterior.tween_property(musica_batalha, "volume_db", -35.0, 0.5)
		fade_anterior.tween_callback(musica_batalha.stop)
		fade_anterior.tween_callback(musica_batalha.queue_free)
	musica_batalha = AUDIO_UTIL.tocar(self, MUSICA_SEGUNDA_FASE, true, -28.0)
	if is_instance_valid(musica_batalha):
		create_tween().tween_property(musica_batalha, "volume_db", -6.0, 0.8).set_trans(Tween.TRANS_SINE)

func _on_fase_tres_iniciada(duracao: float) -> void:
	if is_instance_valid(musica_batalha):
		var fade_musica := create_tween()
		fade_musica.tween_property(musica_batalha, "volume_db", -35.0, 0.45)
		fade_musica.tween_callback(musica_batalha.stop)
		fade_musica.tween_callback(musica_batalha.queue_free)
	# A terceira fase termina junto com a primeira e única execução da faixa.
	musica_fase_tres = AUDIO_UTIL.tocar(self, MUSICA_FASE_TRES, false, -28.0)
	if is_instance_valid(musica_fase_tres):
		musica_fase_tres.finished.connect(_on_musica_fase_tres_finalizada, CONNECT_ONE_SHOT)
	create_tween().tween_property(musica_fase_tres, "volume_db", -1.0, 0.85).set_trans(Tween.TRANS_SINE)
	barra_postura.modulate = Color(0.55, 0.62, 0.72, 0.55)
	if is_instance_valid(jogador) and not jogador.morrendo:
		jogador.ativar_ritmo_fase_tres()
		jogador.set_physics_process(false)
		jogador.invulneravel = true
	var camada := CanvasLayer.new()
	camada.layer = 79
	add_child(camada)
	var veu := ColorRect.new()
	veu.position = Vector2.ZERO
	veu.size = Vector2(254, 256)
	veu.color = Color(0.05, 0.08, 0.16, 0.0)
	veu.mouse_filter = Control.MOUSE_FILTER_IGNORE
	camada.add_child(veu)
	var entrada := create_tween()
	entrada.tween_property(veu, "color:a", 0.48, 0.55).set_trans(Tween.TRANS_SINE)
	await get_tree().create_timer(maxf(duracao - 0.55, 0.2)).timeout
	var saida := create_tween()
	saida.tween_property(veu, "color:a", 0.0, 0.5).set_trans(Tween.TRANS_SINE)
	await saida.finished
	if is_instance_valid(jogador) and not jogador.morrendo:
		jogador.invulneravel = false
		jogador.set_physics_process(true)
	camada.queue_free()

func _on_musica_fase_tres_finalizada() -> void:
	if is_instance_valid(boss) and boss.has_method("finalizar_fase_tres_pela_musica"):
		boss.finalizar_fase_tres_pela_musica()

func parar_tremor() -> void:
	if tremor_ativo:
		get_viewport().canvas_transform = canvas_original
	tremor_ativo = false
	tremor_impacto = false

func _on_boss_vida_alterada(atual: int, maxima: int) -> void:
	barra_vida.max_value = maxima
	barra_vida.value = atual

func _on_boss_postura_alterada(atual: int, maxima: int) -> void:
	barra_postura.max_value = maxima
	barra_postura.value = atual

func _on_boss_derrotado() -> void:
	if fase_quatro_ativa:
		_finalizar_fase_quatro()
		return
	interface_boss.visible = false
	aviso_ui.visible = false
	final_triste.visible = true
	# O desbloqueio só acontece quando a cutscene do falso final realmente
	# começa, e não simplesmente no frame em que a vida do Tung chega a zero.
	PROGRESSO.desbloquear_tung_god()
	final_triste.modulate.a = 0.0
	frase_vitoria.text = ""
	frase_custo.text = ""
	var aparecer := create_tween()
	aparecer.tween_property(final_triste, "modulate:a", 1.0, 0.65).set_trans(Tween.TRANS_SINE)
	await aparecer.finished
	await _digitar_texto(frase_vitoria, texto_vitoria_triste)
	await get_tree().create_timer(pausa_entre_frases).timeout
	await _digitar_texto(frase_custo, texto_custo_triste)
	await get_tree().create_timer(0.9).timeout
	await _iniciar_fase_quatro()

func _iniciar_fase_quatro() -> void:
	if fase_quatro_ativa:
		return
	fase_quatro_ativa = true
	if is_instance_valid(musica_fase_tres):
		musica_fase_tres.stop()
	musica_tung_god = AUDIO_UTIL.tocar(self, MUSICA_TUNG_GOD, true, -18.0)
	if is_instance_valid(musica_tung_god):
		create_tween().tween_property(musica_tung_god, "volume_db", -2.0, 1.0)
	if is_instance_valid(jogador) and not jogador.morrendo:
		jogador.set_physics_process(false)
		jogador.invulneravel = true
	final_triste.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var sumir_texto := create_tween()
	sumir_texto.tween_property(final_triste, "modulate:a", 0.0, 0.75).set_trans(Tween.TRANS_SINE)
	efeitos_tung_god = EFEITOS_TUNG_GOD.new()
	efeitos_tung_god.z_index = 12
	add_child(efeitos_tung_god)
	var ceu := create_tween()
	ceu.tween_property(efeitos_tung_god, "abertura", 1.0, 5.0).set_trans(Tween.TRANS_QUINT).set_ease(Tween.EASE_IN_OUT)
	# O coral ganha cinco segundos sozinho antes de qualquer parte do chefe
	# entrar na tela. A luz e as nuvens preparam a revelacao nesse intervalo.
	await get_tree().create_timer(5.0).timeout
	if not is_inside_tree():
		return
	final_triste.visible = false
	var novo_boss = CENA_TUNG_GOD.instantiate()
	add_child(novo_boss)
	boss = novo_boss
	boss.vida_alterada.connect(_on_boss_vida_alterada)
	boss.postura_alterada.connect(_on_boss_postura_alterada)
	boss.derrotado.connect(_on_boss_derrotado)
	boss.ataque_anunciado.connect(_on_ataque_anunciado)
	barra_vida.get_node("MarcoSegundaFase").visible = false
	barra_postura.visible = false
	$CanvasLayer/InterfaceBoss/NomePostura.text = "JULGAMENTO DIVINO"
	$CanvasLayer/InterfaceBoss/NomePostura.visible = true
	$CanvasLayer/InterfaceBoss/NomePostura.position = Vector2(72, 24)
	$CanvasLayer/InterfaceBoss/NomePostura.modulate = Color("ffe17a")
	var estilo_dourado := StyleBoxFlat.new()
	estilo_dourado.bg_color = Color("f1c84b")
	estilo_dourado.corner_radius_top_left = 2
	estilo_dourado.corner_radius_top_right = 2
	estilo_dourado.corner_radius_bottom_left = 2
	estilo_dourado.corner_radius_bottom_right = 2
	barra_vida.add_theme_stylebox_override("fill", estilo_dourado)
	interface_boss.visible = true
	efeitos_tung_god.combate = true
	await boss.aparecer()
	# O feixe pertence somente à revelação. Quando o combate começa, a luz e
	# as nuvens se dissolvem juntas para devolver toda a leitura à arena.
	if is_instance_valid(efeitos_tung_god):
		var fechar_ceu := create_tween()
		fechar_ceu.tween_property(efeitos_tung_god, "modulate:a", 0.0, 0.9).set_trans(Tween.TRANS_SINE)
		fechar_ceu.tween_callback(efeitos_tung_god.queue_free)
	if is_instance_valid(jogador) and not jogador.morrendo:
		jogador.ativar_ritmo_fase_quatro()
		jogador.invulneravel = false
		jogador.set_physics_process(true)

func _finalizar_fase_quatro() -> void:
	interface_boss.visible = false
	if is_instance_valid(musica_tung_god):
		var fade := create_tween()
		fade.tween_property(musica_tung_god, "volume_db", -35.0, 1.2)
		fade.tween_callback(musica_tung_god.stop)
	if is_instance_valid(efeitos_tung_god):
		create_tween().tween_property(efeitos_tung_god, "modulate:a", 0.0, 1.4)
	await get_tree().create_timer(1.8).timeout
	var transicao = TRANSICAO_RESULTADO.new()
	get_tree().root.add_child(transicao)
	transicao.iniciar("res://cenas/vitoria_makoto.tscn", true, true)

func _digitar_texto(label: Label, texto: String) -> void:
	label.text = ""
	for indice in range(1, texto.length() + 1):
		if not is_inside_tree():
			return
		label.text = texto.left(indice)
		await get_tree().create_timer(intervalo_digitacao).timeout
