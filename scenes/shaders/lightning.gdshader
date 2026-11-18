shader_type canvas_item;
render_mode unshaded;

void fragment() {
	float phase = floor(TIME * 12.0) * 0.18;
	float zigzag = (abs(fract(UV.x * 2.3 + phase) * 2.0 - 1.0) - 0.5) * 0.46;
	float distance_to_arc = abs(UV.y - 0.5 - zigzag);
	float core = 1.0 - smoothstep(0.05, 0.12, distance_to_arc);
	float halo = 1.0 - smoothstep(0.08, 0.29, distance_to_arc);
	float ends = smoothstep(0.0, 0.14, UV.x) * (1.0 - smoothstep(0.86, 1.0, UV.x));
	COLOR = vec4(mix(COLOR.rgb, vec3(1.0), core), max(core, halo * 0.48) * ends * COLOR.a);
}
