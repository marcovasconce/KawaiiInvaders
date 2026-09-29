extends PanelContainer

@export var tempo_visivel := 5.0
@export var velocidade_pulso := 4.0
@export var escala_minima := 0.96
@export var escala_maxima := 1.04

var ativo := false
var tempo_decorrido := 0.0

func _ready() -> void:
	visible = false
	set_process(false)
	pivot_offset = size / 2.0

func mostrar() -> void:
	ativo = true
	tempo_decorrido = 0.0
	visible = true
	modulate.a = 1.0
	scale = Vector2.ONE
	pivot_offset = size / 2.0
	set_process(true)

func _process(delta: float) -> void:
	if not ativo:
		return
	tempo_decorrido += delta
	var pulso := (sin(tempo_decorrido * velocidade_pulso) + 1.0) * 0.5
	var escala_atual := lerpf(escala_minima, escala_maxima, pulso)
	scale = Vector2.ONE * escala_atual
	if tempo_decorrido >= tempo_visivel:
		var progresso_saida := (tempo_decorrido - tempo_visivel) / 0.5
		modulate.a = 1.0 - clampf(progresso_saida, 0.0, 1.0)
		if progresso_saida >= 1.0:
			ativo = false
			visible = false
			set_process(false)
