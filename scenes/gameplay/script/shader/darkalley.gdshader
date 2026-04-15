shader_type canvas_item;

uniform vec4 shadow_color : source_color = vec4(0.0, 0.0, 0.0, 0.95);
uniform float edge_width = 0.1;
uniform float pixel_size = 1.0;
uniform float noise_speed = 0.6;
uniform float noise_strength = 0.18;
uniform float softness = 0.08;
uniform bool left_edge = true;

float hash(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453123);
}

void fragment() {
	vec2 uv = UV;

	// เลือกว่าจะให้ด้านซ้ายหรือขวาแตก
	float edge_coord = left_edge ? uv.x : (1.0 - uv.x);

	// ทำให้ noise เป็นบล็อกพิกเซล
	vec2 pixel_uv = floor(uv * vec2(200.0 / pixel_size, 120.0 / pixel_size));
	float n = hash(pixel_uv + floor(TIME * noise_speed * 10.0));

	// ทำให้ขอบมันสั่นและแตก
	float animated_edge = edge_width + (n - 0.5) * noise_strength;

	// gradient หลักจากขอบไปด้านใน
	float base_mask = smoothstep(animated_edge, animated_edge + softness, edge_coord);

	// เพิ่มความเป็น pixel แตก ๆ ตรงขอบ
	float glitch_band = 1.0 - smoothstep(0.0, animated_edge, edge_coord);
	float pixel_break = step(0.45, n) * glitch_band;

	// เอามาผสมกัน
	float alpha = max(base_mask, pixel_break * 0.75);

	COLOR = vec4(shadow_color.rgb, shadow_color.a * alpha);
}