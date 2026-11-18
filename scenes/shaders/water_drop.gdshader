shader_type canvas_item;
render_mode unshaded;

void fragment() {
	float y = UV.y - 0.5 + sin(UV.x * 10.0 - TIME * 9.0) * 0.05;
	float radius = length(vec2((UV.x - 0.7) * 1.6, y));
	float wake = abs(y) - 0.31 * smoothstep(0.05, 0.7, UV.x);
	float distance_to_drop = min(radius - 0.35, max(wake, UV.x - 0.7));
	float alpha = (1.0 - smoothstep(-0.015, 0.045, distance_to_drop)) * smoothstep(0.01, 0.10, UV.x);
	float glint = 1.0 - smoothstep(0.05, 0.15, length(vec2((UV.x - 0.73) * 1.6, y + 0.13)));
	COLOR = vec4(mix(COLOR.rgb, vec3(0.9, 0.99, 1.0), glint), alpha * COLOR.a);
}
