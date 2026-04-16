shader_type canvas_item;

uniform vec4 shadow_color : source_color = vec4(0.0, 0.0, 0.0, 0.95);
uniform float edge_width = 0.1;
uniform float pixel_size = 1.0;
uniform float noise_speed = 0.6;
uniform float noise_strength = 0.18;
uniform float softness = 0.08;

float hash(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453123);
}

void fragment() {
	vec2 uv = UV;
	uv.x = 1.0 - uv.x;

	float edge_coord = uv.x;

	vec2 pixel_uv = floor(uv * vec2(200.0 / pixel_size, 120.0 / pixel_size));
	float n = hash(pixel_uv + floor(TIME * noise_speed * 10.0));

	float animated_edge = edge_width + (n - 0.5) * noise_strength;

	float base_mask = smoothstep(animated_edge, animated_edge + softness, edge_coord);

	float glitch_band = 1.0 - smoothstep(0.0, animated_edge, edge_coord);
	float pixel_break = step(0.45, n) * glitch_band;

	float alpha = max(base_mask, pixel_break * 0.75);

	COLOR = vec4(shadow_color.rgb, shadow_color.a * alpha);
}