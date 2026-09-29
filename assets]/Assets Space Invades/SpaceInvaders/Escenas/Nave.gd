extends KinematicBody2D

var laser = preload("res://Escenas/Laser.tscn")

onready var ptoLaser = $PuntoAparicionLaser
onready var timer_disparo = $TimerDisparo
onready var animacion = $AnimationPlayer

var direccion = Vector2()
var velocidad = 100
var puedo_disparar = true

func _physics_process(delta):
	direccion.x = 0
	if Input.is_action_pressed("ui_right"):
		direccion.x += velocidad
	if Input.is_action_pressed("ui_left"):
		direccion.x -= velocidad
		
	if Input.is_action_just_pressed("disparar") and puedo_disparar == true:
		var l = laser.instance()
		l.global_position = ptoLaser.global_position
		get_parent().add_child(l)
		puedo_disparar = false
		timer_disparo.start()
		
	move_and_slide(direccion)
		
	

func _on_TimerDisparo_timeout():
	puedo_disparar = true

func destruir():
	animacion.play("disparado")

func eliminar():
	get_tree().change_scene("res://Escenas/GameOver.tscn")
	#if !self.is_queued_for_deletion():
	#	get_parent().remove_child(self)
	#	queue_free()
