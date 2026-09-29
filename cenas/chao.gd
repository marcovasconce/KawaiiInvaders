extends Node

var Bloco = preload("res://cenas/bloco.tscn")

func _ready():
	var bloco = Bloco.instantiate()
	var largura_da_tela = 768
	var altura_da_tela = 210
	var n_blocos = largura_da_tela/1
	#print(get_viewport().size.x)
	for i in range(n_blocos):
		bloco = Bloco.instantiate()
		bloco.global_position = Vector2(2+i*4, altura_da_tela)
		add_child(bloco)

func ativar_modo_makoto() -> void:
	for bloco in get_children():
		if bloco is CanvasItem:
			bloco.modulate = Color(0.1, 0.45, 1.0, 1.0)
