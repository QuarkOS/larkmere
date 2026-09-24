#ifndef LARKMERE_WIND
#define LARKMERE_WIND

#include "/lib/common.glsl"

// Whole-block sway. Amplitude stays small so roots do not skate.
vec3 applyWind(vec3 player, float id) {
    bool leaves = abs(id - ID_LEAVES) < 0.5;
    bool plants = abs(id - ID_PLANTS) < 0.5;
    if (!(leaves || plants)) {
        return player;
    }

    vec3 world = player + cameraPosition;
    float t = frameTimeCounter;
    float gust = sin(world.x * 0.17 + t * 1.05) * sin(world.z * 0.15 + t * 0.73);
    float rustle = sin(world.x * 1.55 + world.z * 1.20 + t * 2.15);
    float amp = leaves ? 0.070 : 0.040;
    amp *= 1.0 + rainStrength * 0.80;

    player.x += (gust * 0.70 + rustle * 0.30) * amp;
    player.z += (gust * 0.40 - rustle * 0.25) * amp;
    return player;
}

#endif
