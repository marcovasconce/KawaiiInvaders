extends Node2D

const TEXTURA_NUVENS = preload("res://assets]/Assets Space Invades/Sprites/nuvens_tung_god_hframes.png")

var abertura := 0.0
var combate := false
var tempo := 0.0
var nuvens: Array[Sprite2D] = []

func _ready() -> void:
	for i in range(4):
		var nuvem := Sprite2D.new()
		nuvem.texture = TEXTURA_NUVENS
		nuvem.hframes = 4
		nuvem.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		nuvem.scale = Vector2.ONE*(0.25 if i<2 else 0.16)
		nuvem.modulate = Color(0.82,0.86,1.0,0.78 if i<2 else 0.55)
		nuvem.z_index = -1
		add_child(nuvem)
		nuvens.append(nuvem)

func _process(delta: float) -> void:
	tempo += delta
	var quadro := int(tempo/0.24)%4
	for i in range(nuvens.size()):
		var nuvem := nuvens[i]
		nuvem.frame = (quadro+i)%4
		var lado := -1.0 if i%2==0 else 1.0
		var distancia := (35.0 if i<2 else 18.0)+(72.0 if i<2 else 105.0)*abertura
		nuvem.position = Vector2(127.0+lado*distancia,20.0+floori(i/2.0)*24.0+sin(tempo*0.8+i)*2.0)
		nuvem.flip_h = lado>0
	queue_redraw()

func _draw() -> void:
	var centro := Vector2(127, 72)
	if abertura > 0.0:
		var largura := lerpf(8.0, 96.0, abertura)
		var alpha := 0.16 + abertura * 0.34
		draw_colored_polygon(PackedVector2Array([Vector2(127-largura*0.18,-10),Vector2(127+largura*0.18,-10),Vector2(127+largura,256),Vector2(127-largura,256)]), Color(1.0,0.94,0.62,alpha))
		for i in range(22):
			var s := fmod(float(i) * 31.7 + tempo * (13.0 + i % 4), 270.0)
			var x := 127.0 + sin(i * 2.31) * largura * 0.85
			draw_circle(Vector2(x,s-8), 0.8 + i%3*0.45, Color(1,0.93,0.55,0.35+0.35*sin(tempo*3+i)))
	if combate:
		draw_arc(centro, 112.0 + sin(tempo)*2.0, PI, TAU, 48, Color(1,0.82,0.3,0.12), 2.0)
