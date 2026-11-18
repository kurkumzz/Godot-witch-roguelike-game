shader_type canvas_item;
render_mode unshaded;

void fragment() {
	vec2 p = UV - vec2(0.55, 0.5);
	float outline = abs(p.x) / 0.43 + abs(p.y) / 0.39;
	float glint = 1.0 - smoothstep(0.0, 0.14, abs(UV.x - fract(TIME * 1.4)));
	float facet = 0.36 * step(p.y, 0.0) + 0.45 * glint;
	COLOR = vec4(mix(COLOR.rgb * 0.76, vec3(1.0), facet), (1.0 - smoothstep(0.9, 1.05, outline)) * COLOR.a);
}
