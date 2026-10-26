extern number strength;

vec4 effect(vec4 color, Image tex, vec2 uv, vec2 screen) {
    vec4 px = Texel(tex, uv) * color;

    float d = distance(uv, vec2(0.5));
    px.rgb *= 1.0 - smoothstep(0.4, 0.8, d) * strength; // vignette

    px.rgb *= 0.92 + 0.08 * mod(floor(screen.y), 2.0); // scanlines

    return px;
}
