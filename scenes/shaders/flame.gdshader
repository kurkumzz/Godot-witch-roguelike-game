shader_type canvas_item;
render_mode unshaded;

void fragment() {
	// The hot core sits at the front. The tail narrows and flickers behind it.
	float wave = sin(15.0 * UV.x - TIME * 16.0);
	float height = UV.y - 0.5 + (1.0 - UV.x) * 0.16 * wave;
	float head = length(vec2((UV.x - 0.70) * 1.65, height));
	float tail_width = 0.35 * smoothstep(0.0, 0.7, UV.x);
	float tail = (1.0 - smoothstep(tail_width, tail_width + 0.06, abs(height)))
		* (1.0 - smoothstep(0.61, 0.73, UV.x)) * smoothstep(0.0, 0.13, UV.x);
	float glow = 1.0 - smoothstep(0.25, 0.38, head);
	COLOR = vec4(mix(COLOR.rgb, vec3(1.0, 0.94, 0.61), glow), max(tail, glow) * COLOR.a);
}
