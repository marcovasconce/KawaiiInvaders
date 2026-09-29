extends Node

func _ready() -> void:
	var menu = preload("res://cenas/tela_inicial.tscn").instantiate()
	add_child(menu)
	await get_tree().process_frame
	get_tree().root.add_child(preload("res://tests/transicao_opcao_monitor.gd").new())
	menu._on_botao_jogar_pressed()
