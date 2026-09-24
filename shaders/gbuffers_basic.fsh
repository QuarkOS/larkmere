#version 330 compatibility
#include "/lib/settings.glsl"

in vec4 tint;

/* RENDERTARGETS: 0,2 */
layout(location = 0) out vec4 outColor;
layout(location = 1) out vec4 outData;

void main() {
    outColor = vec4(tint.rgb, 1.0);
    outData = vec4(0.0, 0.0, 0.0, 1.0);
}
