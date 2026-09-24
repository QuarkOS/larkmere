#version 330 compatibility
#include "/lib/fog.glsl"

uniform sampler2D gtexture;

in vec2 texcoord;
in vec4 tint;
in vec3 viewPos;
in vec3 playerPos;

/* RENDERTARGETS: 0 */
layout(location = 0) out vec4 outColor;

void main() {
    vec4 flake = texture(gtexture, texcoord) * tint;
    if (flake.a < 0.02) {
        discard;
    }

    vec3 tinted = srgbToLinear(flake.rgb);
    tinted *= mix(vec3(0.70, 0.76, 0.84), vec3(0.90, 0.93, 0.96), 1.0 - rainStrength);
    tinted = applyAerial(tinted, playerPos, viewPos, 1.0);
    float alpha = flake.a * mix(0.72, 0.42, rainStrength);
    outColor = vec4(tinted, alpha);
}
