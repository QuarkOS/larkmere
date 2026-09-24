#version 330 compatibility

uniform sampler2D colortex3;

in vec2 texcoord;

/* RENDERTARGETS: 4 */
layout(location = 0) out vec4 outColor;

void main() {
    vec2 texel = vec2(1.7, 0.0) / vec2(textureSize(colortex3, 0));
    vec3 c = texture(colortex3, texcoord).rgb * 0.266;
    c += (texture(colortex3, texcoord + texel).rgb + texture(colortex3, texcoord - texel).rgb) * 0.214;
    c += (texture(colortex3, texcoord + texel * 2.0).rgb + texture(colortex3, texcoord - texel * 2.0).rgb) * 0.118;
    c += (texture(colortex3, texcoord + texel * 3.5).rgb + texture(colortex3, texcoord - texel * 3.5).rgb) * 0.035;
    outColor = vec4(c, 1.0);
}
