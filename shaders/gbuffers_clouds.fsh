#version 330 compatibility
#include "/lib/fog.glsl"

uniform sampler2D gtexture;

in vec2 texcoord;
in vec4 tint;
in vec3 viewPos;
in vec3 playerPos;
in vec3 worldNormal;

/* RENDERTARGETS: 0,2 */
layout(location = 0) out vec4 outColor;
layout(location = 1) out vec4 outData;

void main() {
    vec4 cloud = texture(gtexture, texcoord) * tint;
    if (cloud.a < 0.20) {
        discard;
    }

    vec3 alb = srgbToLinear(cloud.rgb);
    vec3 n = safeNormalize(worldNormal);
    vec3 lightDir = safeNormalize(mat3(gbufferModelViewInverse) * shadowLightPosition);
    float wrap = clamp(dot(n, lightDir) * 0.62 + 0.38, 0.0, 1.0);

    vec3 lit = alb * sunDiscColor() * wrap * sunIntensity() * 0.72;
    lit += alb * skyFillColor() * 0.55;
    lit += alb * moonDiscColor() * moonIntensity() * 1.40;
    lit = mix(lit, lit * vec3(0.62, 0.66, 0.72), rainStrength);
    lit *= mix(1.0, 0.55, thunderStrength);
    lit = applyAerial(lit, playerPos, viewPos, 1.0);

    outColor = vec4(lit, 1.0);
    outData = vec4(0.0, 1.0, MAT_CLOUD, 1.0);
}
