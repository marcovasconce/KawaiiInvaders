extends Node

var Alien = preload("res://Escenas/Alien.tscn")
var Bonus = preload("res://Escenas/Bonus.tscn")

onready var timer_disparo = $TimerDisparar


var lista_aliens = []

# Called when the node enters the scene tree for the first time.
func _ready():
	for j in range(4):
		lista_aliens.append([])
		for i in range(8):
			var alien = Alien.instance()
			alien.global_position = Vector2(40+20*i,48+16*j)
			self.add_child(alien)
			lista_aliens[j].append(alien)
			alien.connect("alien_eliminado",self,"eliminar_alien")
			alien.connect("alien_eliminado",get_parent(),"sumar_puntos_alien")
			
			
			
			

func eliminar_alien(a):
	for fila in lista_aliens:
		for i in range(len(fila)-1):
			if a == fila[i]:
				fila.remove(i)
		

func _on_TimerDescender_timeout():
	print("Bajando")
	for fila in lista_aliens:
		for a in fila:
			if is_instance_valid(a):
				a.position.y += 14
			


func _on_TimerDisparar_timeout():
	var lista_aliens_vivos = []
	for fila in lista_aliens:
		for a in fila:
			if is_instance_valid(a) and !a.is_queued_for_deletion():
				lista_aliens_vivos.append(a)
	
	if lista_aliens_vivos:
		var indice = int(floor(rand_range(0,len(lista_aliens_vivos)-1)))
		lista_aliens_vivos[indice].disparar()
		timer_disparo.wait_time = rand_range(2,5)
	
	



	
