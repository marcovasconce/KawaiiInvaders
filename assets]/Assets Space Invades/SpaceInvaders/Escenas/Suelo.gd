extends Node


var Bloque = preload("res://Escenas/Bloque.tscn")


# Called when the node enters the scene tree for the first time.
func _ready():
	var bloque 
	var ancho_pantalla = 224
	var alto_pantalla = 256
	var n_bloques = ancho_pantalla/4
	
	for i in range(n_bloques):
		bloque = Bloque.instance()
		bloque.global_position = Vector2(2+i*4,alto_pantalla-2)
		add_child(bloque)

