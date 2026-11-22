shader_type canvas_item;
render_mode unshaded;

void fragment() {
	vec2 p = floor(UV * vec2(24.0, 14.0)) + 0.5;
	float wave = sin(p.x * 0.43 - floor(TIME * 11.0) * 0.65);
	float head = length((p - vec2(16.4, 7.0)) * vec2(0.9, 1.0)) - 5.1;
	float wake_y = 6.5 + wave * 1.9;
	float tail = max(abs(p.y - wake_y) - (p.x - 5.3) * 0.30, p.x - 16.0);
	float bead = length(p - vec2(2.9, 6.3 + wave)) - 1.6;
	float edge = min(bead, min(head, tail));
	vec3 ink = mix(COLOR.rgb * vec3(0.52, 0.6, 0.85), COLOR.rgb, step(edge, -1.0));
	float underside = step(8.2, p.y) * step(head, -1.0);
	ink = mix(ink, vec3(0.18, 0.85, 0.9), underside * 0.82);
	float glint = length((p - vec2(16.5, 4.4)) * vec2(0.62, 1.0));
	ink = mix(ink, vec3(0.89, 1.0, 1.0), step(glint, 1.2));
	COLOR = vec4(ink, step(edge, 0.0) * COLOR.a);
}
