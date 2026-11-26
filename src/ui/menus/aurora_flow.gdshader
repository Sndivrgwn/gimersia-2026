shader_type canvas_item;

uniform float wave_speed : hint_range(0.05, 3.0) = 0.45;
uniform float wave_freq : hint_range(1.0, 12.0) = 4.5;
uniform float wave_amp_x : hint_range(0.0, 0.08) = 0.018;
uniform float wave_amp_y : hint_range(0.0, 0.08) = 0.022;
uniform float shimmer_speed : hint_range(0.05, 3.0) = 0.7;
uniform float shimmer_strength : hint_range(0.0, 0.6) = 0.25;
uniform float phase_offset : hint_range(0.0, 6.283) = 0.0;

varying vec4 v_modulate;

void vertex() {
	v_modulate = COLOR;
}

void fragment() {
	float t = TIME * wave_speed + phase_offset;
	float ripple_x = sin(UV.y * wave_freq + t) * wave_amp_x + sin(UV.x * (wave_freq * 0.6) - t * 0.7) * (wave_amp_x * 0.5);
	float ripple_y = cos(UV.x * wave_freq + t * 0.85) * wave_amp_y;
	vec2 warped_uv = clamp(UV + vec2(ripple_x, ripple_y), vec2(0.001), vec2(0.999));

	vec4 tex = texture(TEXTURE, warped_uv);

	// Soft traveling aurora shimmer along the curtain
	float shimmer = 1.0 - shimmer_strength * 0.5 + sin(UV.x * 5.0 - TIME * shimmer_speed + phase_offset) * (shimmer_strength * 0.5);

	// Feather edges smoothly so UV displacement never clips
	float edge_x = smoothstep(0.0, 0.08, UV.x) * smoothstep(1.0, 0.92, UV.x);
	float edge_y = smoothstep(0.0, 0.08, UV.y) * smoothstep(1.0, 0.92, UV.y);

	COLOR = vec4(tex.rgb * shimmer, tex.a * edge_x * edge_y) * v_modulate;
}
