#version 330 compatibility

uniform sampler2D gtexture;

in vec2 texcoord;
in vec4 tint;

/* RENDERTARGETS: 0 */
layout(location = 0) out vec4 outColor;

void main() {
    vec4 glint = texture(gtexture, texcoord) * tint;
    outColor = vec4(glint.rgb, glint.a * 0.65);
}
