shader_type canvas_item;
render_mode unshaded;

float segment(vec2 p, vec2 start, vec2 end_pos) {
	vec2 span = end_pos - start;
	float t = clamp(dot(p - start, span) / dot(span, span), 0.0, 1.0);
	return length(p - start - span * t);
}

void fragment() {
	vec2 p = floor(UV * vec2(24.0, 14.0)) + 0.5;
	float flicker = sin(floor(TIME * 13.0) * 2.3) * 1.6;
	vec2 a = vec2(7.5, 3.1 + flicker);
	vec2 b = vec2(8.6, 9.5 + flicker);
	vec2 c = vec2(17.0, 4.0 - flicker);
	float bolt = min(segment(p, vec2(1.2, 8.6), a), segment(p, a, b));
	bolt = min(bolt, min(segment(p, b, c), segment(p, c, vec2(22.0, 5.4))));
	float fork = segment(p, vec2(12.0, 7.3), vec2(15.2, 11.5 - flicker));
	float d = min(bolt, fork + 0.48);
	vec3 gold = mix(COLOR.rgb * vec3(0.9, 0.64, 0.44), vec3(1.0, 1.0, 0.89), step(d, 0.72));
	COLOR = vec4(gold, step(d, 1.75) * COLOR.a);
}
