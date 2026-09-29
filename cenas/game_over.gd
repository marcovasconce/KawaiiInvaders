extends Node2D

const TRANSICAO_OPCAO = preload("res://cenas/transicao_opcao.gd")
const AUDIO_UTIL = preload("res://cenas/audio_util.gd")
const MUSICA_DERROTA = preload("res://assets]/Assets Space Invades/sfx/MenuDerrota.mp3")
const MUSICA_VITORIA_KITTY = preload("res://assets]/Assets Space Invades/sfx/VitoriaHelloKitty.mp3")

@onready var arte: Sprite2D = $ArteKitty

var tempo := 0.0
var arte_y := 0.0
var vitoria := false

func _ready() -> void:
	vitoria = name == "VitoriaHelloKitty"
	AUDIO_UTIL.tocar(self, MUSICA_VITORIA_KITTY if vitoria else MUSICA_DERROTA, not vitoria, -5.0)
	arte_y = arte.position.y
	var titulo: Control = $Painel if vitoria else $Label
	var detalhe: Control = $DicaSecreta if vitoria else $Label2
	var botao: Button = $Button
	var destino_titulo := titulo.position.x
	var destino_detalhe := detalhe.position.x
	var destino_arte := arte.position.x
	titulo.position.x -= 240.0
	detalhe.position.x += 240.0
	arte.position.x += 130.0
	arte.modulate.a = 0.0
	botao.modulate.a = 0.0
	botao.disabled = true
	var entrada := create_tween().set_parallel(true)
	entrada.tween_property(titulo, "position:x", destino_titulo, 0.6).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	entrada.tween_property(detalhe, "position:x", destino_detalhe, 0.67).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT).set_delay(0.12)
	entrada.tween_property(arte, "position:x", destino_arte, 0.7).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	entrada.tween_property(arte, "modulate:a", 1.0, 0.5)
	entrada.tween_property(botao, "modulate:a", 1.0, 0.42).set_delay(0.4)
	await entrada.finished
	botao.disabled = false
	botao.grab_focus()

func _process(delta: float) -> void:
	tempo += delta
	arte.position.y = arte_y + sin(tempo * 2.2) * 1.5
	queue_redraw()

func _draw() -> void:
	var base := Color("2b153e") if vitoria else Color("2a1028")
	var acento := Color("d875c9") if vitoria else Color("c84e75")
	draw_rect(Rect2(0, 0, 254, 256), base)
	draw_colored_polygon(PackedVector2Array([Vector2(0, 0), Vector2(92, 0), Vector2(178, 256), Vector2(76, 256)]), acento.darkened(0.48))
	draw_colored_polygon(PackedVector2Array([Vector2(215, 0), Vector2(254, 0), Vector2(254, 256), Vector2(169, 256)]), acento.darkened(0.62))
	for i in 14:
		var x := fmod(19.0 + i * 67.0, 254.0)
		var y := fmod(16.0 + i * 47.0, 256.0)
		var brilho := 0.25 + 0.25 * (0.5 + 0.5 * sin(tempo * 2.0 + i))
		draw_rect(Rect2(x, y, 2, 2), Color(acento.r, acento.g, acento.b, brilho))
	draw_rect(Rect2(12, 14, 230, 228), Color(acento.r, acento.g, acento.b, 0.3), false, 1.0)


func _on_button_pressed():
	$Button.disabled = true
	var transicao = TRANSICAO_OPCAO.new()
	get_tree().root.add_child(transicao)
	transicao.iniciar("res://cenas/main.tscn", "TENTAR NOVAMENTE", Color("dd5c91") if not vitoria else Color("df7bd0"))
