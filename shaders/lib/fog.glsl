#ifndef LARKMERE_FOG
#define LARKMERE_FOG

#include "/lib/sky.glsl"

// Distance haze plus a thin pool of mist below the camera.
// Nearby ground stays clear. The far valley still fades.
vec3 applyAerial(vec3 color, vec3 playerPos, vec3 viewPos, float skyLight) {
    float dist = length(viewPos);
    vec3 dir = safeNormalize(viewPos);
    float elev = sunElevation();
    float dawn = exp(-pow((elev - 0.02) / 0.14, 2.0));

    float start = 28.0 / max(FOG_DENSITY, 0.35);
    float hazeDist = max(dist - start, 0.0);

    float density = 0.0032 * FOG_DENSITY;
    density *= 1.0 + rainStrength * 1.70 + dawn * 0.85;
    density *= mix(1.0, 1.35, thunderStrength * 0.5);

    if (isEyeInWater > 0) {
        hazeDist = dist;
        if (isEyeInWater == 1) {
            density *= 9.0;
        } else if (isEyeInWater == 2) {
            density *= 14.0;
        } else {
            density *= 7.0;
        }
    } else if (hasSkylight) {
        density *= mix(0.12, 1.0, smoothstep(0.04, 0.32, skyLight));
    }

    float aerial = 1.0 - exp(-hazeDist * density);

    if (isEyeInWater == 0 && hasSkylight) {
        float below = max(-dot(viewPos, safeNormalize(upPosition)), 0.0);
        float valley = (1.0 - exp(-below / 32.0)) * smoothstep(start, start + 48.0, dist);
        valley *= mix(0.70, 1.0, dawn);
        valley *= 1.0 - rainStrength * 0.20;
        aerial += valley * 0.16 * FOG_DENSITY;
    }

    float cap = isEyeInWater == 0 ? 0.82 : 0.96;
    aerial = clamp(aerial, 0.0, cap);

    vec3 fogCol = atmosphereBase(dir);
    fogCol *= 0.88;

    if (isEyeInWater == 1) {
        fogCol = vec3(0.04, 0.14, 0.16);
    } else if (isEyeInWater == 2) {
        fogCol = vec3(0.55, 0.16, 0.03);
    } else if (isEyeInWater == 3) {
        fogCol = vec3(0.55, 0.62, 0.66);
    }

    return mix(color, fogCol, aerial);
}

#endif
