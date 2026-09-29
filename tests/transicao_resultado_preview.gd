extends Node

func _ready() -> void:
	add_child(preload("res://cenas/main.tscn").instantiate())
	await get_tree().process_frame
	get_tree().root.add_child(preload("res://tests/transicao_resultado_monitor.gd").new())
