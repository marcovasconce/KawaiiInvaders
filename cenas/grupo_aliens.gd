extends Node

var Alien = preload("res://cenas/alien.tscn")
var Bonus = preload("res://cenas/bonus.tscn")
const TRANSICAO_RESULTADO = preload("res://cenas/transicao_resultado.gd")
@onready var timerDisparo = $TimerDisparo
var listaAliens = []
var vitoria_iniciada := false
const TOLERANCIA_MIRA := 12.0
const BOSS_HABILITADO := true

func _ready():	
	$TimerBonus.wait_time = randf_range(3.0, 20.0)
	$TimerBonus.start()
	for j in range(1):
		listaAliens.append([])
		for i in range(5):
			var alien = Alien.instantiate()
			
			# CORRIGIDO: Agora usa 'j' para criar as filas uma abaixo da outra e aumentou o espaço
			alien.global_position = Vector2(20 + 20 * i, 50 + 20 * j)
			
			self.add_child(alien)
			listaAliens[j].append(alien)
			
			# CORRIGIDO: Sintaxe oficial e limpa do Godot 4 para conectar sinais
			alien.alien_eliminado.connect(self.eliminar_alien)
			alien.alien_eliminado.connect(get_parent().Somar_pontos_alien)

func eliminar_alien(a):
	print("alien eliminado")
	for fila in listaAliens:
		if a in fila:
			fila.erase(a) 
			break

	if not vitoria_iniciada and _quantidade_aliens_vivos() == 0:
		vitoria_iniciada = true
		$TimerDescida.stop()
		$TimerDisparo.stop()
		$TimerBonus.stop()
		call_deferred("_mostrar_final")

func _quantidade_aliens_vivos() -> int:
	var total := 0
	for fila in listaAliens:
		total += fila.size()
	return total

func _mostrar_final() -> void:
	var jogador = get_tree().get_first_node_in_group("tanque")
	if not is_instance_valid(jogador) or jogador.morrendo:
		return
	while is_instance_valid(jogador) and jogador.efeito_parry_ativo:
		await get_tree().process_frame
	if not is_instance_valid(jogador) or jogador.morrendo:
		return
	if BOSS_HABILITADO and jogador.makoto_ativado:
		# Nao corta a transformacao ao meio.
		while is_instance_valid(jogador) and jogador.em_transformacao:
			await get_tree().process_frame
		if not is_instance_valid(jogador) or jogador.morrendo:
			return
		get_parent().iniciar_boss()
	else:
		var transicao = TRANSICAO_RESULTADO.new()
		get_tree().root.add_child(transicao)
		transicao.iniciar("res://cenas/vitoria_hello_kitty.tscn", true, false)

func _on_timer_descida_timeout():
	print("descendo")
	for fila in listaAliens:
		for a in fila:
			if is_instance_valid(a):
				# Mantém o corpo e o sprite inteiros dentro da área visível.
				a.position.y = minf(a.position.y + 10.0, 244.0)

func _on_timer_disparo_timeout():
	var jogador: Node2D = get_tree().get_first_node_in_group("tanque") as Node2D
	if not is_instance_valid(jogador):
		return

	# Somente aliens praticamente na mesma coluna do jogador podem atirar.
	var aliens_alinhados = []
	
	for fila in listaAliens:
		for a in fila:
			if is_instance_valid(a) and !a.is_queued_for_deletion():
				var esta_vivo: bool = !"esta_morto" in a or a.esta_morto == false
				var esta_acima: bool = a.global_position.y < jogador.global_position.y
				var esta_alinhado: bool = absf(a.global_position.x - jogador.global_position.x) <= TOLERANCIA_MIRA
				if esta_vivo and esta_acima and esta_alinhado:
					aliens_alinhados.append(a)
	
	# Se houver mais de uma fileira, atira o alien alinhado mais proximo do jogador.
	if aliens_alinhados.size() > 0:
		var alien_atirador = aliens_alinhados[0]
		for alien in aliens_alinhados:
			if alien.global_position.y > alien_atirador.global_position.y:
				alien_atirador = alien
		alien_atirador.disparar()
				
	# Define o proximo intervalo de tempo aleatorio para a tentativa de tiro.
	timerDisparo.wait_time = randf_range(0.5, 2.0) # Ajuste esses números para mudar a dificuldade



func _on_timer_bonus_timeout():
	var bonus = Bonus.instantiate()
	self.add_child(bonus)
	bonus.connect("bonus_eliminado", Callable(get_parent(), "somar_bonus"))
