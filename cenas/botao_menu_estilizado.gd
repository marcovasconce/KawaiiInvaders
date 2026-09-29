extends Button

const AUDIO_UTIL = preload("res://cenas/audio_util.gd")
const SFX_ESCOLHER = preload("res://assets]/Assets Space Invades/sfx/EscolherOpcao.mp3")

@export var cor_acento := Color("58c9ff")

var tempo := 0.0
var selecionado := false
var escala_base := Vector2.ONE
var deslocamento_seta := 0.0
var brilho_clique := 0.0

func _ready() -> void:
	pivot_offset = size * 0.5
	escala_base = scale
	focus_entered.connect(_ativar)
	focus_exited.connect(_desativar)
	mouse_entered.connect(_ativar)
	mouse_exited.connect(_desativar_mouse)
	pressed.connect(_animar_clique)
	queue_redraw()

func _process(delta: float) -> void:
	tempo += delta
	if selecionado and brilho_clique <= 0.01:
		var pulso := 1.0 + sin(tempo * 7.0) * 0.012
		scale = escala_base * pulso
		queue_redraw()

func _draw() -> void:
	if not selecionado:
		return
	var brilho := 0.72 + 0.28 * (0.5 + 0.5 * sin(tempo * 7.0))
	var cor := cor_acento.lerp(Color.WHITE, brilho_clique)
	cor.a = brilho
	draw_colored_polygon(PackedVector2Array([
		Vector2(-11 + deslocamento_seta, size.y * 0.5),
		Vector2(-4 + deslocamento_seta, size.y * 0.5 - 5),
		Vector2(-4 + deslocamento_seta, size.y * 0.5 + 5)
	]), cor)
	if brilho_clique > 0.05:
		draw_colored_polygon(PackedVector2Array([
			Vector2(-21 + deslocamento_seta * 0.5, size.y * 0.5),
			Vector2(-15 + deslocamento_seta * 0.5, size.y * 0.5 - 4),
			Vector2(-15 + deslocamento_seta * 0.5, size.y * 0.5 + 4)
		]), Color(cor_acento.r, cor_acento.g, cor_acento.b, brilho_clique))
	draw_line(Vector2(8, size.y - 3), Vector2(size.x - 8, size.y - 3), cor, 2.0)

func _ativar() -> void:
	selecionado = true
	var tween := create_tween().set_parallel(true)
	tween.tween_property(self, "rotation", deg_to_rad(-1.5), 0.1)
	tween.tween_property(self, "deslocamento_seta", 3.0, 0.12).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	queue_redraw()

func _desativar() -> void:
	selecionado = false
	create_tween().tween_property(self, "rotation", 0.0, 0.12)
	create_tween().tween_property(self, "deslocamento_seta", 0.0, 0.12)
	scale = escala_base
	queue_redraw()

func _desativar_mouse() -> void:
	if not has_focus():
		_desativar()

func _animar_clique() -> void:
	AUDIO_UTIL.tocar(self, SFX_ESCOLHER, false, -3.0)
	selecionado = true
	var inicio := deslocamento_seta
	var clique := create_tween().set_parallel(true)
	clique.tween_property(self, "deslocamento_seta", 34.0, 0.14).set_trans(Tween.TRANS_QUART).set_ease(Tween.EASE_IN)
	clique.tween_property(self, "brilho_clique", 1.0, 0.1)
	clique.tween_property(self, "scale", escala_base * 0.9, 0.13).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
	await clique.finished
	await get_tree().create_timer(0.08).timeout
	var retorno := create_tween().set_parallel(true)
	retorno.tween_property(self, "deslocamento_seta", inicio + 3.0, 0.17).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	retorno.tween_property(self, "brilho_clique", 0.0, 0.17)
	retorno.tween_property(self, "scale", escala_base, 0.17).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
