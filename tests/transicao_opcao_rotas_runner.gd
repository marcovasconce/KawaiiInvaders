extends Node

const TRANSICAO = preload("res://cenas/transicao_opcao.gd")

func _ready() -> void:
	await get_tree().process_frame
	for rodada in range(4):
		await _testar("res://cenas/main.tscn", "JOGAR", Color("a869eb"))
		await _testar("res://cenas/tela_inicial.tscn", "MENU", Color("35bce9"))
	print("TRANSICOES DE OPCOES: OK")
	get_tree().quit()

func _testar(destino: String, rotulo: String, cor: Color) -> void:
	var transicao = TRANSICAO.new()
	get_tree().root.add_child(transicao)
	transicao.iniciar(destino, rotulo, cor)
	await get_tree().create_timer(2.35).timeout
	assert(get_tree().current_scene.scene_file_path == destino)
	assert(not TRANSICAO.em_andamento)
