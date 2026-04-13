shader_type canvas_item;

uniform sampler2D SCREEN_TEXTURE : hint_screen_texture, filter_linear_mipmap;
uniform float blur_amount : hint_range(0.0, 5.0) = 0.0;

void fragment() {
    vec2 uv = SCREEN_UV;
    vec4 col = textureLod(SCREEN_TEXTURE, uv, blur_amount);
    COLOR = col;
}