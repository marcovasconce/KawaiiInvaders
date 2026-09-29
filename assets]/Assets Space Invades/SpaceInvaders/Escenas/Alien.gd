extends KinematicBody2D

var Misil = preload("res://Escenas/Misil.tscn")
onready var timer_movimiento = $TimerMovimiento
onready var animation_player = $AnimationPlayer
onready var spawn_point = $SpawnPoint

var origen = 0
var rango = 20
var paso = 7
var direccion = 1

signal alien_eliminado

func _ready():
	timer_movimiento.start()
	origen = self.position.x


func _on_TimerMovimiento_timeout():
	self.position.x += paso*direccion
	if self.position.x >= rango+origen or self.position.x < origen-rango:
		direccion *= -1
		

func explotar():
	animation_player.play("destruido")

func eliminar():
	emit_signal("alien_eliminado",self)
	get_parent().remove_child(self)
	queue_free()

func disparar():
	var misil = Misil.instance()
	misil.global_position = spawn_point.global_position
	get_parent().add_child(misil)
	 
