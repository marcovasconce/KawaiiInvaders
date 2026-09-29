extends StaticBody2D

const PROJETIL = preload("res://cenas/tung_god_proj.tscn")
var destruida := false

func receber_ataque(_dano: int, _postura: int) -> void:
	if destruida:
		return
	destruida = true
	call_deferred("_explodir_copia")

func _explodir_copia() -> void:
	if not is_inside_tree():
		return
	# Errar o verdadeiro transforma a cópia numa explosão radial reagível.
	for i in range(12):
		var pena = PROJETIL.instantiate()
		get_parent().add_child(pena)
		pena.global_position = global_position
		pena.configurar(0, Vector2.from_angle(float(i)*TAU/12.0), 125.0, false)
	var tween := create_tween().set_parallel(true)
	tween.tween_property(self,"scale",Vector2.ONE*1.45,0.16)
	tween.tween_property(self,"modulate:a",0.0,0.16)
	tween.chain().tween_callback(queue_free)

func explosion() -> void:
	receber_ataque(1,0)
