extends CanvasLayer

const FONTE = preload("res://assets]/Assets Space Invades/fonts/atari-classic-font/AtariClassic-gry3.ttf")
const SPRITE_MAKOTO = preload("res://assets]/Assets Space Invades/Sprites/hframesmakoto_clean.png")
const SPRITE_MAKOTO_MORTE = preload("res://assets]/Assets Space Invades/Sprites/makoto_morte.png")
const SPRITE_KITTY = preload("res://assets]/Assets Space Invades/Sprites/rpg_maker_xp_sprite___hello_kitty__red__by_kittykun123_dajyaga-fullview-removebg-preview.png")
const SPRITE_KITTY_DERROTADA = preload("res://assets]/Assets Space Invades/Sprites/hello_kitty_derrotada.png")

static var em_andamento := false

func iniciar(destino: String, vitoria: bool, makoto: bool) -> void:
	if em_andamento:
		queue_free()
		return
	em_andamento = true
	layer = 100
	await RenderingServer.frame_post_draw
	if not is_inside_tree():
		em_andamento = false
		return
	var captura := TextureRect.new()
	captura.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	captura.texture = ImageTexture.create_from_image(get_viewport().get_texture().get_image())
	captura.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	captura.stretch_mode = TextureRect.STRETCH_SCALE
	captura.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(captura)

	var cor_base := Color("081b38") if vitoria else Color("300e28")
	var cor_acento := Color("1eaee7") if vitoria else Color("e35176")
	if not makoto:
		cor_base = Color("39184e") if vitoria else Color("371427")
		cor_acento = Color("e87ac8") if vitoria else Color("e75784")
	var faixa := Polygon2D.new()
	faixa.polygon = PackedVector2Array([Vector2(-90, -8), Vector2(330, -8), Vector2(420, 264), Vector2(0, 264)])
	faixa.color = cor_base
	faixa.position.x = -440.0
	add_child(faixa)
	var listras := Polygon2D.new()
	listras.polygon = PackedVector2Array([Vector2(190, -8), Vector2(238, -8), Vector2(328, 264), Vector2(280, 264)])
	listras.color = cor_acento
	listras.position.x = -440.0
	add_child(listras)

	var arte := Sprite2D.new()
	arte.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	arte.position = Vector2(340, 133)
	if makoto:
		arte.texture = SPRITE_MAKOTO if vitoria else SPRITE_MAKOTO_MORTE
		arte.hframes = 6 if vitoria else 4
		arte.vframes = 5 if vitoria else 1
		arte.frame = 26 if vitoria else 3
		arte.scale = Vector2.ONE * (0.55 if vitoria else 0.18)
	else:
		if vitoria:
			arte.texture = SPRITE_KITTY
			arte.hframes = 4
			arte.vframes = 4
			arte.frame = 5
			arte.scale = Vector2.ONE * 1.6
		else:
			arte.texture = SPRITE_KITTY_DERROTADA
			arte.scale = Vector2.ONE * 0.18
	add_child(arte)

	var titulo := Label.new()
	titulo.position = Vector2(-190, 74)
	titulo.size = Vector2(200, 74)
	titulo.text = ("VITORIA" if vitoria else "DERROTA") + ("\nMAKOTO" if makoto else "\nKITTY")
	titulo.add_theme_font_override("font", FONTE)
	titulo.add_theme_font_size_override("font_size", 17)
	titulo.add_theme_color_override("font_color", Color.WHITE)
	titulo.add_theme_color_override("font_outline_color", cor_base)
	titulo.add_theme_constant_override("outline_size", 3)
	add_child(titulo)

	var entrada := create_tween().set_parallel(true)
	entrada.tween_property(faixa, "position:x", 0.0, 0.48).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	entrada.tween_property(listras, "position:x", 0.0, 0.53).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	entrada.tween_property(arte, "position:x", 185.0, 0.58).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	entrada.tween_property(titulo, "position:x", 17.0, 0.54).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	await entrada.finished
	await get_tree().create_timer(0.18).timeout
	var erro := get_tree().change_scene_to_file(destino)
	if erro != OK:
		em_andamento = false
		queue_free()
		return
	await get_tree().process_frame
	captura.hide()
	var saida := create_tween().set_parallel(true)
	saida.tween_property(faixa, "position:x", 440.0, 0.62).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
	saida.tween_property(listras, "position:x", 440.0, 0.56).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
	saida.tween_property(arte, "position:x", 625.0, 0.59).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
	saida.tween_property(titulo, "position:x", 457.0, 0.6).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
	await saida.finished
	em_andamento = false
	queue_free()
