shader_type spatial;
render_mode unshaded, blend_mix, depth_draw_never, cull_disabled;

uniform vec4 mark_color : source_color = vec4(1.0, 0.15, 0.2, 0.6);
uniform vec2 card_size = vec2(1.47, 1.961);

void fragment() {
	vec2 edge = (vec2(0.5) - abs(UV - vec2(0.5))) * card_size;
	float distance_to_border = abs(min(edge.x, edge.y) - 0.11);
	float glow = exp(-pow(distance_to_border / 0.045, 2.0));
	ALBEDO = mark_color.rgb;
	EMISSION = mark_color.rgb * glow * 1.5;
	ALPHA = mark_color.a * glow;
}
