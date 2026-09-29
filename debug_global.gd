extends Node

func _unhandled_input(event: InputEvent) -> void:
	if not event.is_action_pressed("debug_fase_dois") or event.is_echo():
		return
	get_viewport().set_input_as_handled()
	var cena := get_tree().current_scene
	if is_instance_valid(cena) and cena.has_method("iniciar_boss_debug_fase_tres"):
		cena.iniciar_boss_debug_fase_tres()
		return
	get_tree().set_meta("debug_pular_fase_tres", true)
	get_tree().change_scene_to_file("res://cenas/main.tscn")
