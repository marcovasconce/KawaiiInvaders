extends StaticBody2D

var golpes = 0

onready var animacion = $AnimationPlayer

# Called when the node enters the scene tree for the first time.
func _ready():
	comprobar_golpes()


func destruir():
	golpes += 1
	comprobar_golpes()

func comprobar_golpes():
	if golpes == 0:
		animacion.play("normal")
	elif golpes == 1:
		animacion.play("dañado")
	elif golpes == 2:
		
		queue_free()
