shader_type canvas_item;

uniform float radius_px = 0.0;
uniform float softness_px = 24.0;
uniform vec2 center = vec2(640.0, 360.0);
uniform vec4 color : source_color = vec4(0.0, 0.0, 0.0, 1.0);

void fragment() {
	float dist = distance(FRAGCOORD.xy, center);
	float soft = max(softness_px, 0.0001);
	float alpha = smoothstep(radius_px - soft, radius_px, dist);
	COLOR = vec4(color.rgb, color.a * alpha);
}
