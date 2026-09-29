extends Node

const CENA_BOSS = preload("res://cenas/boss_arena.tscn")

var pontos = 0
@onready var label_pontos = $VBoxContainer/LabelPontos
var boss_iniciado := false

func iniciar_boss(pular_para_fase_dois := false, pular_para_fase_tres := false, pular_para_fase_quatro := false) -> void:
	if boss_iniciado:
		return
	boss_iniciado = true
	$VBoxContainer.hide()
	$jogador.na_arena_boss = true
	# So o Tung e sua interface entram; personagem, chão e fundo permanecem.
	var encontro = CENA_BOSS.instantiate()
	encontro.embutida = true
	encontro.pular_intro = pular_para_fase_dois or pular_para_fase_tres or pular_para_fase_quatro
	encontro.pular_fase_tres = pular_para_fase_tres
	encontro.pular_fase_quatro = pular_para_fase_quatro
	for caminho in ["FundoEspacial", "chao", "jogador", "CanvasLayer/DicasMakoto", "CanvasLayer/FlashBranco"]:
		var duplicado = encontro.get_node_or_null(caminho)
		if duplicado:
			duplicado.free()
	add_child(encontro)
	$grupoAliens.queue_free()

var shake_forca := 0.0
var shake_inicio_ms := 0
var shake_fim_ms := 0
var canvas_transform_original := Transform2D.IDENTITY

func _ready() -> void:
	# O processamento so fica ativo durante um screen shake.
	set_process(false)
	if get_tree().has_meta("iniciar_tung_god_direto"):
		get_tree().remove_meta("iniciar_tung_god_direto")
		$jogador.transformar_em_makoto(false)
		iniciar_boss(false,false,true)
	elif get_tree().has_meta("reiniciar_boss_na_fase"):
		get_tree().remove_meta("reiniciar_boss_na_fase")
		$jogador.transformar_em_makoto(false)
		iniciar_boss()
	if get_tree().has_meta("debug_pular_fase_dois"):
		get_tree().remove_meta("debug_pular_fase_dois")
		call_deferred("iniciar_boss_debug_fase_dois")
	if get_tree().has_meta("debug_pular_fase_tres"):
		get_tree().remove_meta("debug_pular_fase_tres")
		call_deferred("iniciar_boss_debug_fase_tres")

func iniciar_boss_debug_fase_dois() -> void:
	if boss_iniciado:
		var arena_existente = get_node_or_null("BossArena")
		if arena_existente and arena_existente.has_method("pular_para_fase_dois_debug"):
			arena_existente.pular_para_fase_dois_debug()
		return
	$jogador.transformar_em_makoto(false)
	iniciar_boss(true)

func iniciar_boss_debug_fase_tres() -> void:
	if boss_iniciado:
		var arena_existente = get_node_or_null("BossArena")
		if arena_existente and arena_existente.has_method("pular_para_fase_tres_debug"):
			arena_existente.pular_para_fase_tres_debug()
		return
	$jogador.transformar_em_makoto(false)
	iniciar_boss(false, true)

func _process(_delta: float) -> void:
	var agora := Time.get_ticks_msec()
	if agora >= shake_fim_ms:
		get_viewport().canvas_transform = canvas_transform_original
		set_process(false)
		return

	var duracao_total: int = maxi(shake_fim_ms - shake_inicio_ms, 1)
	var progresso := float(agora - shake_inicio_ms) / float(duracao_total)
	var intensidade := shake_forca * (1.0 - progresso) * (1.0 - progresso)
	var deslocamento := Vector2(
		randf_range(-intensidade, intensidade),
		randf_range(-intensidade, intensidade)
	)
	var transform_sacudido := canvas_transform_original
	transform_sacudido.origin += deslocamento
	get_viewport().canvas_transform = transform_sacudido

func tremer_tela(forca: float = 5.0, duracao: float = 0.16) -> void:
	canvas_transform_original = get_viewport().canvas_transform
	shake_forca = forca
	shake_inicio_ms = Time.get_ticks_msec()
	shake_fim_ms = shake_inicio_ms + int(duracao * 1000.0)
	set_process(true)

func Somar_pontos_alien(_alien):
	pontos += 2
	label_pontos.text = str(pontos)

func somar_bonus():
	pontos += 500
	label_pontos.text = str(pontos)


func _on_area_game_over_area_entered(area: Area2D) -> void:
	pass # Replace with function body.
