#ifndef LARKMERE_FOG
#define LARKMERE_FOG

#include "/lib/sky.glsl"

// Pewter aerial perspective. The first 24 blocks stay clear.
// Farther air desaturates, then fades toward a capped mist color.
vec3 applyAerial(vec3 color, vec3 playerPos, vec3 viewPos, float skyLight) {
    float dist = length(viewPos);
    vec3 dir = safeNormalize(viewPos);
    bool overworldAir = isEyeInWater == 0 && hasSkylight;

    float nearStart = 24.0;
    float hazeDist = overworldAir ? max(dist - nearStart, 0.0) : dist;

    float density = 0.0072 * FOG_DENSITY;
    density *= 1.0 + rainStrength * 1.25;
    density *= 1.0 + (hasSkylight ? goldenFactor() : 0.0) * 0.28;
    density *= mix(1.0, 1.20, thunderStrength);

    if (isEyeInWater == 1) {
        density *= 8.0;
    } else if (isEyeInWater == 2) {
        density *= 12.0;
    } else if (isEyeInWater == 3) {
        density *= 6.5;
    } else if (!hasSkylight) {
        density *= 2.4;
    } else {
        density *= mix(0.10, 1.0, smoothstep(0.05, 0.35, skyLight));
    }

    float aerial = 1.0 - exp(-hazeDist * density);

    if (overworldAir) {
        vec3 up = safeNormalize(upPosition);
        float below = max(-dot(viewPos, up), 0.0);
        float valley = (1.0 - exp(-below / 26.0)) * smoothstep(nearStart, nearStart + 40.0, dist);
        valley *= mix(0.65, 1.0, goldenFactor());
        valley *= mix(1.0, 0.75, rainStrength);
        aerial += valley * 0.20 * FOG_DENSITY;
    }

    float cap = overworldAir ? mix(0.76, 0.86, rainStrength) : 0.94;
    aerial = clamp(aerial, 0.0, cap);

    float luma = dot(color, vec3(0.2126, 0.7152, 0.0722));
    color = mix(color, vec3(luma), clamp(aerial * 0.38, 0.0, 0.38));

    vec3 fogCol = valleyMistColor(dir);
    if (isEyeInWater == 1) {
        fogCol = vec3(0.020, 0.085, 0.095);
    } else if (isEyeInWater == 2) {
        fogCol = vec3(0.42, 0.10, 0.015);
    } else if (isEyeInWater == 3) {
        fogCol = vec3(0.45, 0.50, 0.54);
    }

    return mix(color, fogCol, aerial);
}

#endif
