extends Area2D

var speed = 200
var foi_refletido = false
var direcao_refletida := Vector2.UP

func _process(delta):
	# O missil sempre viaja em linha reta: para baixo ou, apos o parry, para cima.
	if foi_refletido:
		position += direcao_refletida * (speed * 2.5) * delta
	else:
		position += Vector2.DOWN * speed * delta

func _on_body_entered(body):
	# SE ADENTRAR O PLAYER
	if body.is_in_group("tanque"):
		if not foi_refletido and body.has_method("deve_auto_parry_projetil") and body.deve_auto_parry_projetil():
			realizar_parry(body)
			return
		if body.has_method("esta_invulneravel") and body.esta_invulneravel():
			queue_free()
			return
		if body.esta_no_parry and not foi_refletido:
			# PARRY COM SUCESSO!
			realizar_parry(body)
		elif not foi_refletido:
			# Player falhou e tomou o dano normal
			body.destruir()
			queue_free()
			
	# SE ADENTRAR OS BLOCOS DE DEFESA
	elif body.is_in_group("blocos"):
		if not foi_refletido: # Tiros refletidos passam por dentro das suas próprias defesas
			body.destruir()
			queue_free()
			
	# SE ESTIVER REFLETIDO E COLISEU COM UM ALIEN
	elif foi_refletido and body.has_method("explosion"):
		explodir_em_area()

func realizar_parry(player):
	foi_refletido = true
	var boss := get_tree().get_first_node_in_group("boss") as Node2D
	if is_instance_valid(boss):
		direcao_refletida = global_position.direction_to(boss.global_position)
	else:
		direcao_refletida = Vector2.UP
	
	# Aciona a piscada de tela branca e o congelamento de frames do player
	player.aplicar_impacto_visual()
	
	# Opcional: Mudar a cor do míssil para indicar que ele virou uma bomba de energia dourada
	self.modulate = Color.YELLOW

func explodir_em_area():
	print("EXPLOSÃO EM ÁREA!")
	
	# 1. Paramos o processamento visual e físico do míssil para ele não continuar andando
	set_process(false)
	if has_node("CollisionShape2D"):
		$CollisionShape2D.set_deferred("disabled", true)
	visible = false # Esconde o sprite do míssil antigo
	
	# 2. Criamos a área física da explosão
	var area_explosao = Area2D.new()
	var colisao_explosao = CollisionShape2D.new()
	var formato_circulo = CircleShape2D.new()
	
	formato_circulo.radius = 80.0 # Raio de alcance em pixels
	colisao_explosao.shape = formato_circulo
	area_explosao.add_child(colisao_explosao)
	
	# Configurações cruciais para a Godot ler a física dinamicamente
	area_explosao.monitoring = true
	area_explosao.monitorable = false
	
	get_parent().add_child(area_explosao)
	area_explosao.global_position = self.global_position
	
	# 3. CORREÇÃO: Força o motor de física a atualizar a posição da nova área
	await get_tree().physics_frame
	await get_tree().physics_frame # Esperamos 2 frames para a física sincronizar perfeitamente!
	
	# 4. Coleta quem está dentro do raio e aplica a destruição
	var alvos = area_explosao.get_overlapping_bodies()
	print("Alvos encontrados na explosão: ", alvos.size()) # Mostra quantos ele pegou no terminal
	
	for corpo in alvos:
		if corpo.has_method("receber_ataque") and is_instance_valid(corpo):
			corpo.receber_ataque(3, 25)
		elif corpo.has_method("explosion") and is_instance_valid(corpo):
			corpo.explosion()
			
	# 5. Remove tudo da memória com segurança
	area_explosao.queue_free()
	queue_free()
