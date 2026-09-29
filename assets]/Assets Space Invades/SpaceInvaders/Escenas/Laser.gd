extends Area2D

var velocidad = 200


func _process(delta):
	position.y -= velocidad*delta






func _on_Laser_body_entered(body):
	if body.is_in_group("aliens"):
		body.explotar()
		get_parent().remove_child(self)
		queue_free()
	
	elif body.is_in_group("bloques"):
		body.destruir()
		if !is_queued_for_deletion():
			get_parent().remove_child(self)
			queue_free()
	
