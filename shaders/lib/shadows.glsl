#ifndef LARKMERE_SHADOWS
#define LARKMERE_SHADOWS

#include "/lib/sky.glsl"

uniform sampler2D shadowtex0;

// Fixed disk, wider than a 3x3 box so the penumbra stays soft.
const vec2 SHADOW_DISK[8] = vec2[](
    vec2(-0.72, 0.18),
    vec2(-0.28, 0.70),
    vec2(0.22, 0.62),
    vec2(0.74, 0.20),
    vec2(0.55, -0.42),
    vec2(0.05, -0.78),
    vec2(-0.48, -0.52),
    vec2(-0.18, -0.12)
);

float sampleShadow(vec3 playerPos, vec3 worldNormal) {
    if (!hasSkylight) {
        return 1.0;
    }

    vec3 lightDir = safeNormalize(mat3(gbufferModelViewInverse) * shadowLightPosition);
    float facing = clamp(dot(worldNormal, lightDir), 0.0, 1.0);
    vec3 shifted = playerPos + worldNormal * mix(0.08, 0.16, 1.0 - facing);

    vec4 clip = shadowProjection * shadowModelView * vec4(shifted, 1.0);
    clip.xy = distortShadow(clip.xy);
    vec3 uv = clip.xyz * 0.5 + 0.5;

    if (any(lessThan(uv.xy, vec2(0.0))) || any(greaterThan(uv.xy, vec2(1.0)))) {
        return 1.0;
    }

    float bias = max(0.0016 * (1.0 - facing), 0.00045);
    float texel = SHADOW_SOFTNESS / float(shadowMapResolution);

    float lit = 0.0;
    for (int i = 0; i < 8; i++) {
        float closest = texture(shadowtex0, uv.xy + SHADOW_DISK[i] * texel).r;
        lit += closest < uv.z - bias ? 0.0 : 1.0;
    }
    lit /= 8.0;

    float edge = max(abs(uv.x - 0.5), abs(uv.y - 0.5));
    lit = mix(1.0, lit, smoothstep(0.50, 0.22, edge));

    // Grazing light at the horizon otherwise acne-streaks across flats.
    float grazing = smoothstep(0.0, 0.07, shadowLightElevation());
    return mix(1.0, lit, grazing);
}

#endif
