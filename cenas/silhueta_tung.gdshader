shader_type canvas_item;

uniform vec4 cor_sombra : source_color = vec4(0.14, 0.18, 0.27, 1.0);

void fragment() {
	float alpha = texture(TEXTURE, UV).a;
	COLOR = vec4(cor_sombra.rgb, alpha * cor_sombra.a);
}
