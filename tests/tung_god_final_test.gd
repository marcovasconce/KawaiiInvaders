extends Node

func _ready() -> void:
	await get_tree().create_timer(8.0).timeout
	var chefe := get_tree().get_first_node_in_group("boss")
	if is_instance_valid(chefe) and chefe.has_method("_morrer"):
		chefe._morrer()
