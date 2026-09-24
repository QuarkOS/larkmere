#version 330 compatibility
#include "/lib/settings.glsl"

uniform sampler2D gtexture;

in vec2 texcoord;
in vec4 tint;

/* RENDERTARGETS: 0,2 */
layout(location = 0) out vec4 outColor;
layout(location = 1) out vec4 outData;

void main() {
    vec4 beam = texture(gtexture, texcoord) * tint;
    if (beam.a < 0.08) {
        discard;
    }
    outColor = vec4(beam.rgb * beam.a, 1.0);
    outData = vec4(1.0, 1.0, MAT_EMISSIVE, 1.0);
}
