shader_type canvas_item;

render_mode unshaded;

uniform vec4 glow_color : source_color = vec4(0.35, 0.9, 1.0, 1.0);
uniform vec4 shine_color : source_color = vec4(1.0, 0.45, 1.0, 1.0);

uniform float glow_strength : hint_range(0.0, 2.0, 0.01) = 0.45;
uniform float pulse_speed : hint_range(0.0, 10.0, 0.01) = 2.0;

uniform float shine_strength : hint_range(0.0, 2.0, 0.01) = 0.75;
uniform float shine_speed : hint_range(0.0, 5.0, 0.01) = 0.65;
uniform float shine_width : hint_range(0.01, 0.5, 0.01) = 0.12;

uniform float edge_glow_strength : hint_range(0.0, 2.0, 0.01) = 0.35;

void fragment() {
	vec4 tex = texture(TEXTURE, UV);

	if (tex.a <= 0.01) {
		COLOR = tex;
	} else {
		float pulse = sin(TIME * pulse_speed) * 0.5 + 0.5;

		vec3 final_color = tex.rgb;

		// แสงวูบวาบทั้งตัว
		final_color += glow_color.rgb * glow_strength * pulse;

		// เส้นแสงเฉียงวิ่งผ่าน
		float diagonal = UV.x + UV.y;
		float shine_pos = fract(TIME * shine_speed);

		float shine_line_1 = 1.0 - smoothstep(0.0, shine_width, abs(diagonal - shine_pos));
		float shine_line_2 = 1.0 - smoothstep(0.0, shine_width, abs(diagonal - (shine_pos + 1.0)));

		float shine_line = max(shine_line_1, shine_line_2);

		final_color += shine_color.rgb * shine_line * shine_strength;

		// ขอบสว่างนิด ๆ
		float edge = smoothstep(0.05, 0.5, tex.a);
		final_color += glow_color.rgb * edge_glow_strength * pulse * edge;

		COLOR = vec4(final_color, tex.a);
	}
}