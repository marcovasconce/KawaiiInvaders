extends Node


var puntos = 0
onready var textPuntos = $VBoxContainer/LabelPuntos

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass

func sumar_puntos_alien(a):
	puntos += 100
	textPuntos.text = str(puntos)
