#version 330 compatibility

uniform sampler2D gtexture;

in vec2 texcoord;
in vec4 tint;

/* RENDERTARGETS: 0 */
layout(location = 0) out vec4 outColor;

void main() {
    vec4 crack = texture(gtexture, texcoord) * tint;
    if (crack.a < 0.02) {
        discard;
    }
    outColor = vec4(crack.rgb, crack.a);
}
