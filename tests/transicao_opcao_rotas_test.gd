extends Node

const TRANSICAO = preload("res://cenas/transicao_opcao.gd")

func _ready() -> void:
	var controlador := Node.new()
	controlador.set_script(preload("res://tests/transicao_opcao_rotas_runner.gd"))
	get_tree().root.add_child.call_deferred(controlador)

