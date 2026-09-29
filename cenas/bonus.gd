extends CharacterBody2D

@onready var spriteMelody = $Sprite2D   
@onready var sprite_explosao = $explosao  
@onready var collision = $CollisionShape2D      

signal bonus_eliminado

var velocidade = 50
var esta_morto = false

func _ready():
	spriteMelody.visible = true
	sprite_explosao.visible = false

func _process(delta):
	if not esta_morto:
		position.x -= velocidade * delta

func explosion():
	if esta_morto:
		return
	esta_morto = true
	
	collision.set_deferred("disabled", true)
	
	spriteMelody.visible = false
	sprite_explosao.visible = true
	
	await get_tree().create_timer(0.4).timeout
	
	elimination()

func elimination(): 
	bonus_eliminado.emit()
	
	queue_free()
