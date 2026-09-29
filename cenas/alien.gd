extends CharacterBody2D

var missil = preload("res://cenas/missil.tscn")
const AUDIO_UTIL = preload("res://cenas/audio_util.gd")
const SFX_MOVIMENTO = preload("res://assets]/Assets Space Invades/sfx/fastinvader1.wav")
const SFX_DERROTADO = preload("res://assets]/Assets Space Invades/sfx/invaderkilled.wav")
static var ultimo_som_movimento_ms := 0
@onready var spawnPoint = $spawnPoint
@onready var timer = $timerMovimento

# Referências dos sprites e colisão
@onready var sprite_kuromi = $Kuromi      
@onready var sprite_explosao = $explosao  
@onready var collision = $CollisionShape2D      

const SPEED = 300.0

var origin = 0
var distancia  = 30
var passo = 7
var direction = 1
var descerPasso = 15

# RESOLVIDO: O sinal agora avisa que vai passar o alien que foi destruído
signal alien_eliminado(alien)

func _ready():
	timer.start()
	origin = self.position.x
	
	# Garante que o jogo comece com a Kuromi visível e a explosão escondida
	sprite_kuromi.visible = true
	sprite_explosao.visible = false

func _on_timer_movimento_timeout():
	var agora := Time.get_ticks_msec()
	if agora - ultimo_som_movimento_ms >= 180:
		ultimo_som_movimento_ms = agora
		AUDIO_UTIL.tocar(get_parent(), SFX_MOVIMENTO, false, -12.0)
	self.position.x = clampf(self.position.x + direction * passo, 9.0, 245.0)
	if self.position.x >= origin + distancia or self.position.x <= origin - distancia:
		direction *= -1

func explosion():
	AUDIO_UTIL.tocar(get_parent(), SFX_DERROTADO, false, -3.0)
	# 1. Desativa a colisão e para o movimento imediatamente
	collision.set_deferred("disabled", true)
	timer.stop()
	
	# 2. Esconde a Kuromi e mostra a explosão
	sprite_kuromi.visible = false
	sprite_explosao.visible = true
	
	# 3. Espera o tempo da animação/efeito da explosão
	await get_tree().create_timer(0.4).timeout
	
	# 4. Deleta o inimigo e avisa o jogo
	elimination()

func elimination(): 
	# RESOLVIDO: Envia o próprio alien (self) para satisfazer o método do 'grupo_aliens.gd'
	alien_eliminado.emit(self)
	
	# RESOLVIDO: O queue_free sozinho já remove do pai e limpa a memória com segurança
	queue_free()

func disparar():
	var Missil = missil.instantiate()
	get_parent().add_child(Missil)
	Missil.global_position = spawnPoint.global_position
	
