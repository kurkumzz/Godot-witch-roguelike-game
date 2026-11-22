shader_type canvas_item;
render_mode unshaded;

void fragment() {
	vec2 p = floor(UV * vec2(24.0, 14.0)) + 0.5;
	float half_height = min((p.x - 1.0) * 0.78, (23.7 - p.x) * 0.34);
	float ridge = 7.3 - 0.08 * (p.x - 9.0);
	float edge = abs(p.y - 7.0) - half_height;
	vec3 ice = COLOR.rgb * vec3(0.35, 0.57, 0.81);
	if (edge <= -0.65) {
		ice = mix(COLOR.rgb * 0.78, vec3(0.84, 1.0, 1.0), step(p.y, ridge));
		if (p.x < 8.7) {
			ice *= vec3(0.61, 0.79, 0.92);
		}
		if (abs(ridge - p.y) < 0.55) {
			ice = vec3(0.97, 1.0, 1.0);
		}
	}
	COLOR = vec4(ice, step(edge, 0.0) * COLOR.a);
}
