#ifndef LARKMERE_FOG
#define LARKMERE_FOG

#include "/lib/sky.glsl"

// Distance haze plus a pool of mist in the air below the camera.
vec3 applyAerial(vec3 color, vec3 playerPos, vec3 viewPos, float skyLight) {
    float dist = length(viewPos);
    vec3 dir = safeNormalize(viewPos);
    float elev = sunElevation();
    float dawn = exp(-pow((elev - 0.02) / 0.14, 2.0));

    float density = 0.0115 * FOG_DENSITY;
    density *= 1.0 + rainStrength * 1.70 + dawn * 0.70;
    density *= mix(1.0, 1.35, thunderStrength * 0.5);

    if (isEyeInWater == 1) {
        density *= 9.0;
    } else if (isEyeInWater == 2) {
        density *= 14.0;
    } else if (isEyeInWater == 3) {
        density *= 7.0;
    } else if (hasSkylight) {
        // Underground stays clearer. The mouth of a cave fades as sky light returns.
        density *= mix(0.12, 1.0, smoothstep(0.04, 0.32, skyLight));
    }

    float aerial = 1.0 - exp(-dist * density);

    if (isEyeInWater == 0 && hasSkylight) {
        float below = max(-dot(viewPos, safeNormalize(upPosition)), 0.0);
        float valley = (1.0 - exp(-below / 20.0)) * (1.0 - exp(-dist / 34.0));
        valley *= mix(0.55, 1.0, dawn);
        valley *= 1.0 - rainStrength * 0.25;
        aerial = clamp(aerial + valley * 0.42 * FOG_DENSITY, 0.0, 1.0);
    }

    vec3 fogCol = atmosphereColor(dir);
    fogCol = mix(fogCol, vec3(0.58, 0.61, 0.63), 0.16);

    if (isEyeInWater == 1) {
        fogCol = vec3(0.04, 0.14, 0.16);
    } else if (isEyeInWater == 2) {
        fogCol = vec3(0.55, 0.16, 0.03);
    } else if (isEyeInWater == 3) {
        fogCol = vec3(0.55, 0.62, 0.66);
    }

    return mix(color, fogCol, clamp(aerial, 0.0, 1.0));
}

#endif
