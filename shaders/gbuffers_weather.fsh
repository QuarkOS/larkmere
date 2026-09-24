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

    vec3 tinted = flake.rgb * mix(vec3(0.78, 0.82, 0.88), vec3(0.92, 0.94, 0.96), 1.0 - rainStrength);
    tinted = applyAerial(tinted, playerPos, viewPos, 1.0);
    float alpha = flake.a * mix(0.70, 0.45, rainStrength);
    outColor = vec4(tinted, alpha);
}
