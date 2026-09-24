#version 330 compatibility
#include "/lib/sky.glsl"

uniform sampler2D gtexture;

in vec2 texcoord;
in vec4 tint;
in vec3 worldNormal;

/* RENDERTARGETS: 0,2 */
layout(location = 0) out vec4 outColor;
layout(location = 1) out vec4 outData;

void main() {
    vec4 cloud = texture(gtexture, texcoord) * tint;
    if (cloud.a < 0.20) {
        discard;
    }

    vec3 n = safeNormalize(worldNormal);
    vec3 lightDir = safeNormalize(mat3(gbufferModelViewInverse) * shadowLightPosition);
    float wrap = clamp(dot(n, lightDir) * 0.55 + 0.45, 0.0, 1.0);
    vec3 lit = cloud.rgb * mix(skyFillColor(), sunDiscColor(), wrap * sunIntensity());
    lit += cloud.rgb * moonDiscColor() * moonIntensity() * 0.65;
    lit *= mix(vec3(1.0), vec3(0.70, 0.74, 0.78), rainStrength);
    lit *= mix(1.0, 0.50, thunderStrength);

    outColor = vec4(lit, 1.0);
    // Sky light 1 so aerial fog still reaches the cloud deck.
    outData = vec4(0.0, 1.0, MAT_CLOUD, 1.0);
}
