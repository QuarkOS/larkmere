#version 330 compatibility
#include "/lib/common.glsl"

uniform sampler2D gtexture;

in vec2 texcoord;
in vec4 tint;

/* RENDERTARGETS: 0,2 */
layout(location = 0) out vec4 outColor;
layout(location = 1) out vec4 outData;

void main() {
    vec4 color = texture(gtexture, texcoord) * tint;
    if (color.a < 0.01) {
        discard;
    }
    outColor = vec4(srgbToLinear(color.rgb), color.a);
    outData = vec4(0.0, 0.0, 0.0, 1.0);
}
