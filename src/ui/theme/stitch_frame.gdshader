shader_type canvas_item;

// Jahitan putus-putus digambar saat runtime, bukan dibawa dari tekstur panel.
// Panjang dash tetap dalam piksel, jadi tidak ikut melar saat kartu ditarik
// tinggi (tekstur 9-slice akan meregangkan jahitannya).

uniform vec2 frame_size = vec2(520.0, 300.0);
uniform float inset : hint_range(0.0, 64.0) = 12.0;
uniform float corner_radius : hint_range(0.0, 128.0) = 24.0;
uniform float thickness : hint_range(0.5, 6.0) = 1.6;
uniform float dash_length : hint_range(1.0, 40.0) = 4.0;
uniform float gap_length : hint_range(1.0, 40.0) = 3.0;
uniform vec4 stitch_color : source_color = vec4(0.741, 0.698, 0.647, 1.0);

float sd_rounded_box(vec2 p, vec2 half_box, float radius) {
	vec2 q = abs(p) - half_box + vec2(radius);
	return length(max(q, vec2(0.0))) + min(max(q.x, q.y), 0.0) - radius;
}

// Jarak menyusur tepi, dipakai sebagai fase dash supaya rapi di semua sisi.
float edge_distance(vec2 p, vec2 half_box, float radius) {
	vec2 q = abs(p);
	if (q.x > half_box.x - radius && q.y > half_box.y - radius) {
		vec2 v = q - (half_box - vec2(radius));
		return atan(v.y, v.x) * radius;
	}
	if (q.y > half_box.y - radius) {
		return p.x;
	}
	return p.y;
}

void fragment() {
	vec2 half_size = frame_size * 0.5;
	vec2 p = (UV - vec2(0.5)) * frame_size;
	float radius = max(corner_radius - inset, 0.0);
	vec2 half_box = max(half_size - vec2(inset), vec2(0.0));
	float d = sd_rounded_box(p, half_box, radius);
	float half_thickness = thickness * 0.5;
	float band = 1.0 - smoothstep(half_thickness, half_thickness + 1.0, abs(d));
	float period = max(dash_length + gap_length, 1.0);
	float phase = mod(edge_distance(p, half_box, radius), period);
	float dash = 1.0 - step(dash_length, phase);
	COLOR = vec4(stitch_color.rgb, stitch_color.a * band * dash);
}
