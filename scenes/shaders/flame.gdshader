shader_type canvas_item;
render_mode unshaded;

void fragment() {
	vec2 p = floor(UV * vec2(24.0, 14.0)) + 0.5;
	float beat = floor(TIME * 14.0) * 0.68;
	float head = length((p - vec2(16.8, 7.0)) * vec2(0.9, 1.0)) - 4.8;
	float width = clamp((p.x - 1.0) * 0.29, 0.0, 4.3);
	float curl = sin(0.42 * p.x - beat) * (1.0 - p.x / 24.0);
	float tongue = max(abs(p.y - 7.5 - curl * 2.8) - width, p.x - 17.0);
	float upper = max(abs(p.y - 4.5 + curl * 1.8) - width * 0.45, abs(p.x - 9.0) - 6.5);
	float edge = min(head, min(tongue, upper));
	vec3 ember = mix(COLOR.rgb * 0.68, vec3(1.0, 0.45, 0.12), step(edge, -0.9));
	float core = length((p - vec2(17.1, 7.3)) * vec2(0.76, 1.0));
	ember = mix(ember, vec3(1.0, 0.73, 0.23), step(core, 3.0));
	ember = mix(ember, vec3(1.0, 0.97, 0.74), step(core, 1.8));
	COLOR = vec4(ember, step(edge, 0.0) * COLOR.a);
}
