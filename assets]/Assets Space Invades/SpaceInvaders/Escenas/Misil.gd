extends Area2D

var speed = 150

func _process(delta):
	position.y += speed*delta



func _on_Misil_body_entered(body):
	if body.is_in_group("nave") or body.is_in_group("bloques"):
		body.destruir()
		queue_free()


