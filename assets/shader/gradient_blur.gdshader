shader_type canvas_item;

uniform sampler2D SCREEN_TEXTURE : hint_screen_texture, filter_linear_mipmap;
uniform float max_blur = 1.5;

// control where blur fades
uniform float start = 0.0;  // left side
uniform float end = 0.6;    // where blur ends

void fragment() {
    vec2 uv = SCREEN_UV;

    // gradient factor (0 = full blur, 1 = no blur)
    float t = smoothstep(start, end, uv.x);

    // calculate blur based on position
    float blur = mix(max_blur, 0.0, t);

    vec4 col = textureLod(SCREEN_TEXTURE, uv, blur);

    COLOR = col;
}