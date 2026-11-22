shader_type canvas_item;

uniform float flash_amount : hint_range(0.0, 1.0) = 0.0;
uniform vec4 status_tint : source_color = vec4(1.0, 1.0, 1.0, 0.0);

void fragment() {
	float brightness = max(max(COLOR.r, COLOR.g), COLOR.b);
	COLOR.rgb = mix(COLOR.rgb, brightness * status_tint.rgb, status_tint.a);
	COLOR.rgb = mix(COLOR.rgb, vec3(1.0), flash_amount);
}
